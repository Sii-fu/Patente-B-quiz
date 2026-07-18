import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../services/admin_repository.dart';

enum UserFilter { all, pending, verified }

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  UserFilter _currentFilter = UserFilter.all;
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _adminRepository.getAllUsers();
      if (!mounted) return;
      setState(() {
        _allUsers = users;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Helpers to read fields that may live under different keys ──────────────
  String _phoneOf(Map<String, dynamic> user) {
    final raw = user['phone'] ?? user['phone_number'] ?? user['mobile'] ?? '';
    return raw.toString();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  bool _matchesQuery(Map<String, dynamic> user, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase().trim();
    final name = (user['full_name'] ?? '').toString().toLowerCase();
    final username = (user['username'] ?? '').toString().toLowerCase();
    final email = (user['email'] ?? '').toString().toLowerCase();
    final phone = _phoneOf(user).toLowerCase();

    if (name.contains(q) || username.contains(q) || email.contains(q) || phone.contains(q)) {
      return true;
    }

    // Digit-insensitive phone match: "12345" matches "+39 123 45".
    final qDigits = _digitsOnly(q);
    if (qDigits.isNotEmpty) {
      final phoneDigits = _digitsOnly(phone);
      if (phoneDigits.isNotEmpty && phoneDigits.contains(qDigits)) return true;
    }
    return false;
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_allUsers);

    // Apply status filter
    switch (_currentFilter) {
      case UserFilter.pending:
        result = result.where((u) => u['is_verified'] != true).toList();
        break;
      case UserFilter.verified:
        result = result.where((u) => u['is_verified'] == true).toList();
        break;
      case UserFilter.all:
        break;
    }

    // Apply search filter (name / phone / username / email)
    final query = _searchController.text;
    if (query.trim().isNotEmpty) {
      result = result.where((u) => _matchesQuery(u, query)).toList();
    }

    setState(() {
      _filteredUsers = result;
    });
  }

  int get _totalCount => _allUsers.length;
  int get _pendingCount => _allUsers.where((u) => u['is_verified'] != true).length;
  int get _verifiedCount => _allUsers.where((u) => u['is_verified'] == true).length;

  Future<void> _toggleUserVerification(String userId, bool newValue) async {
    HapticFeedback.mediumImpact();

    final success = await _adminRepository.updateUserVerification(userId, newValue);

    if (!mounted) return;

    if (success) {
      // Update local state
      final index = _allUsers.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        setState(() {
          _allUsers[index]['is_verified'] = newValue;
          _applyFilters();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(newValue
              ? AppLocalizations.of(context)!.adminUserVerified
              : AppLocalizations.of(context)!.adminUserUnverified),
          backgroundColor: newValue ? Colors.green : Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(AppLocalizations.of(context)!.adminErrorUpdating),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text(l10n.adminUserManagement),
        actions: [
          IconButton(
            tooltip: l10n.retry,
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadUsers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _buildSearchField(l10n, theme),
          ),

          // ── Stat cards (also act as filters) ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildStatFilterCard(
                  label: l10n.adminFilterAll,
                  count: _totalCount,
                  icon: Icons.people_alt_rounded,
                  color: theme.colorScheme.primary,
                  filter: UserFilter.all,
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _buildStatFilterCard(
                  label: l10n.adminFilterPending,
                  count: _pendingCount,
                  icon: Icons.hourglass_bottom_rounded,
                  color: Colors.orange,
                  filter: UserFilter.pending,
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _buildStatFilterCard(
                  label: l10n.adminFilterVerified,
                  count: _verifiedCount,
                  icon: Icons.verified_user_rounded,
                  color: Colors.green,
                  filter: UserFilter.verified,
                  theme: theme,
                ),
              ],
            ),
          ),

          // ── Results count ─────────────────────────────────────────────
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Icon(Icons.format_list_bulleted_rounded,
                      size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 6),
                  Text(
                    '${_filteredUsers.length} / $_totalCount',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // ── User List ─────────────────────────────────────────────────
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(AppLocalizations l10n, ThemeData theme) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged: (_) => _applyFilters(),
      style: TextStyle(color: theme.colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: l10n.adminSearchUsers,
        prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                tooltip: l10n.settingsClose,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _searchController.clear();
                  _applyFilters();
                },
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildStatFilterCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
    required UserFilter filter,
    required ThemeData theme,
  }) {
    final isSelected = _currentFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _currentFilter = filter;
            _applyFilters();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 1.6,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isSelected ? color : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? color
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      final isSearching = _searchController.text.trim().isNotEmpty;
      return RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.22),
            Icon(
              isSearching ? Icons.search_off_rounded : Icons.people_outline,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.adminNoUsersFound,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          final user = _filteredUsers[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isVerified = user['is_verified'] == true;
    final fullName = (user['full_name'] ?? l10n.adminUnknownUser).toString();
    final username = (user['username'] ?? '').toString();
    final phone = _phoneOf(user);
    final xp = user['xp'] ?? 0;
    final level = user['current_level'] ?? 1;
    final isAdmin = (user['role'] ?? 'user').toString().toLowerCase() == 'admin';
    final createdAt = user['created_at'] != null ? DateTime.tryParse(user['created_at'].toString()) : null;
    final statusColor = isVerified ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: statusColor.withValues(alpha: 0.18),
                    child: Text(
                      (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 16, color: Colors.green),
                            ],
                            if (isAdmin) ...[
                              const SizedBox(width: 6),
                              _buildAdminBadge(theme),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (phone.isNotEmpty)
                          _buildSubInfo(Icons.phone_rounded, phone, theme)
                        else if (username.isNotEmpty)
                          _buildSubInfo(Icons.alternate_email_rounded, username, theme),
                      ],
                    ),
                  ),

                  // Verification Switch
                  Column(
                    children: [
                      Switch(
                        value: isVerified,
                        onChanged: (value) => _toggleUserVerification(user['id'], value),
                        activeColor: Colors.green,
                      ),
                      Text(
                        isVerified ? l10n.adminVerified : l10n.adminPending,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Divider(height: 20, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildUserStat(Icons.star_rounded, 'XP: $xp', Colors.amber, theme),
                  _buildUserStat(Icons.trending_up_rounded, '${l10n.profileLevel}: $level',
                      Colors.blue, theme),
                  if (createdAt != null)
                    _buildUserStat(
                      Icons.calendar_today_rounded,
                      '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                      theme.colorScheme.primary,
                      theme,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'ADMIN',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildSubInfo(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => _UserDetailsDialog(
        user: user,
        onToggleVerification: (userId, newValue) async {
          Navigator.pop(context);
          await _toggleUserVerification(userId, newValue);
        },
      ),
    );
  }

  Widget _buildUserStat(IconData icon, String text, Color color, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _UserDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final Function(String userId, bool newValue) onToggleVerification;

  const _UserDetailsDialog({
    required this.user,
    required this.onToggleVerification,
  });

  @override
  State<_UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends State<_UserDetailsDialog> {
  late bool _isVerified;

  @override
  void initState() {
    super.initState();
    _isVerified = widget.user['is_verified'] == true;
  }

  String _phone() {
    final raw =
        widget.user['phone'] ?? widget.user['phone_number'] ?? widget.user['mobile'] ?? '';
    final value = raw.toString();
    return value.isEmpty ? 'N/A' : value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final fullName = (widget.user['full_name'] ?? l10n.adminUnknownUser).toString();
    final username = (widget.user['username'] ?? 'N/A').toString();
    final email = (widget.user['email'] ?? 'N/A').toString();
    final role = (widget.user['role'] ?? 'user').toString();
    final xp = widget.user['xp'] ?? 0;
    final level = widget.user['current_level'] ?? 1;
    final dailyStreak = widget.user['daily_streak'] ?? 0;
    final totalQuizzes = widget.user['total_quizzes_taken'] ?? 0;
    final avgScore = widget.user['average_score'] ?? 0.0;
    final licenseType = widget.user['license_type'] ?? 'B';
    final createdAt = widget.user['created_at'] != null
        ? DateTime.tryParse(widget.user['created_at'].toString())
        : null;
    final updatedAt = widget.user['updated_at'] != null
        ? DateTime.tryParse(widget.user['updated_at'].toString())
        : null;
    final lastStudyDate = widget.user['last_study_date'] != null
        ? DateTime.tryParse(widget.user['last_study_date'].toString())
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor:
                        _isVerified ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                    child: Text(
                      (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: _isVerified ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                fullName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, size: 20, color: Colors.green),
                            ],
                          ],
                        ),
                        Text(
                          username,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification Toggle
                    Card(
                      color: _isVerified
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              _isVerified ? Icons.verified_user : Icons.pending,
                              color: _isVerified ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.adminVerificationStatus,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    _isVerified ? l10n.adminVerified : l10n.adminPending,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isVerified ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isVerified,
                              onChanged: (value) {
                                HapticFeedback.mediumImpact();
                                widget.onToggleVerification(widget.user['id'], value);
                                setState(() {
                                  _isVerified = value;
                                });
                              },
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Account Information
                    _buildSectionTitle(l10n.adminAccountInfo, Icons.account_circle),
                    const SizedBox(height: 12),
                    _buildInfoRow(l10n.profilePhone, _phone()),
                    _buildInfoRow(l10n.adminEmail, email),
                    _buildInfoRow(l10n.adminRole, role.toUpperCase()),
                    _buildInfoRow(l10n.adminLicenseType, licenseType.toString()),
                    if (createdAt != null)
                      _buildInfoRow(
                        l10n.adminJoinedDate,
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                      ),

                    const SizedBox(height: 20),

                    // Progress Stats
                    _buildSectionTitle(l10n.adminProgressStats, Icons.analytics),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            l10n.adminXP,
                            xp.toString(),
                            Icons.star,
                            Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            l10n.profileLevel,
                            level.toString(),
                            Icons.trending_up,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            l10n.adminDailyStreak,
                            '$dailyStreak ${l10n.adminDays}',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            l10n.adminTotalQuizzes,
                            totalQuizzes.toString(),
                            Icons.quiz,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      l10n.adminAverageScore,
                      '${(avgScore as num).toStringAsFixed(1)}%',
                    ),
                    if (lastStudyDate != null)
                      _buildInfoRow(
                        l10n.adminLastStudy,
                        '${lastStudyDate.day}/${lastStudyDate.month}/${lastStudyDate.year}',
                      ),

                    const SizedBox(height: 20),

                    // System Info
                    _buildSectionTitle(l10n.adminSystemInfo, Icons.info_outline),
                    const SizedBox(height: 12),
                    _buildInfoRow('User ID', (widget.user['id'] ?? 'N/A').toString(),
                        isMonospace: true),
                    if (updatedAt != null)
                      _buildInfoRow(
                        l10n.adminLastUpdated,
                        '${updatedAt.day}/${updatedAt.month}/${updatedAt.year} ${updatedAt.hour}:${updatedAt.minute}',
                      ),
                  ],
                ),
              ),
            ),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.settingsClose),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                fontFamily: isMonospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
