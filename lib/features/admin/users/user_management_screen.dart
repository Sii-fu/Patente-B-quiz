import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/profile.dart';
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

    // Apply search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((u) {
        final name = (u['full_name'] ?? '').toString().toLowerCase();
        final email = (u['username'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    }

    setState(() {
      _filteredUsers = result;
    });
  }

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
          content: Text(newValue 
            ? AppLocalizations.of(context)!.adminUserVerified
            : AppLocalizations.of(context)!.adminUserUnverified
          ),
          backgroundColor: newValue ? Colors.green : Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      appBar: AppBar(
        title: Text(l10n.adminUserManagement),
      ),
      body: Column(
        children: [
          // Search Bar
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: TextField(
          //     controller: _searchController,
          //     decoration: InputDecoration(
          //       hintText: l10n.adminSearchUsers,
          //       prefixIcon: const Icon(Icons.search),
          //       suffixIcon: _searchController.text.isNotEmpty
          //           ? IconButton(
          //               icon: const Icon(Icons.clear),
          //               onPressed: () {
          //                 HapticFeedback.lightImpact();
          //                 _searchController.clear();
          //                 _applyFilters();
          //               },
          //             )
          //           : null,
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(12),
          //       ),
          //       filled: true,
          //       fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          //     ),
          //     onChanged: (_) => _applyFilters(),
          //   ),
          // ),
        
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(l10n.adminFilterAll, UserFilter.all, theme),
                const SizedBox(width: 8),
                _buildFilterChip(l10n.adminFilterPending, UserFilter.pending, theme),
                const SizedBox(width: 8),
                _buildFilterChip(l10n.adminFilterVerified, UserFilter.verified, theme),
              ],
            ),
          ),


          // Stats Row
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //   child: Row(
          //     children: [
          //       _buildStatCard(
          //         l10n.adminTotalUsers,
          //         _allUsers.length.toString(),
          //         Icons.people,
          //         theme.colorScheme.primary,
          //       ),
          //       const SizedBox(width: 8),
          //       _buildStatCard(
          //         l10n.adminFilterPending,
          //         _allUsers.where((u) => u['is_verified'] != true).length.toString(),
          //         Icons.hourglass_empty,
          //         Colors.orange,
          //       ),
          //       const SizedBox(width: 8),
          //       _buildStatCard(
          //         l10n.adminFilterVerified,
          //         _allUsers.where((u) => u['is_verified'] == true).length.toString(),
          //         Icons.verified_user,
          //         Colors.green,
          //       ),
          //     ],
          //   ),
          // ),

          const Divider(),

          // User List
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, UserFilter filter, ThemeData theme) {
    final isSelected = _currentFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.lightImpact();
        setState(() {
          _currentFilter = filter;
          _applyFilters();
        });
      },
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUsers,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.adminNoUsersFound,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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
    final fullName = user['full_name'] ?? l10n.adminUnknownUser;
    final username = user['username'] ?? '';
    final xp = user['xp'] ?? 0;
    final level = user['current_level'] ?? 1;
    final createdAt = user['created_at'] != null 
        ? DateTime.parse(user['created_at']) 
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: isVerified 
                      ? Colors.green.withOpacity(0.2) 
                      : Colors.orange.withOpacity(0.2),
                  child: Text(
                    (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isVerified ? Colors.green : Colors.orange,
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
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                          ],
                        ],
                      ),
                      if (username.isNotEmpty)
                        Text(
                          username,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Verification Switch
                Column(
                  children: [
                    Switch(
                      value: isVerified,
                      onChanged: (value) => _toggleUserVerification(
                        user['id'],
                        value,
                      ),
                      activeColor: Colors.green,
                    ),
                    Text(
                      isVerified ? l10n.adminVerified : l10n.adminPending,
                      style: TextStyle(
                        fontSize: 10,
                        color: isVerified ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 0),
            const Divider(),
            
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildUserStat(Icons.star, 'XP: $xp'),
                _buildUserStat(Icons.trending_up, '${l10n.profileLevel}: $level'),
                if (createdAt != null)
                  _buildUserStat(
                    Icons.calendar_today,
                    '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  ),
              ],
            ),
          ],
        ),
      ),
      ));
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

  Widget _buildUserStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    final fullName = widget.user['full_name'] ?? l10n.adminUnknownUser;
    final username = widget.user['username'] ?? 'N/A';
    final email = widget.user['email'] ?? 'N/A';
    final role = widget.user['role'] ?? 'user';
    final xp = widget.user['xp'] ?? 0;
    final level = widget.user['current_level'] ?? 1;
    final dailyStreak = widget.user['daily_streak'] ?? 0;
    final totalQuizzes = widget.user['total_quizzes_taken'] ?? 0;
    final avgScore = widget.user['average_score'] ?? 0.0;
    final licenseType = widget.user['license_type'] ?? 'B';
    final createdAt = widget.user['created_at'] != null 
        ? DateTime.parse(widget.user['created_at']) 
        : null;
    final updatedAt = widget.user['updated_at'] != null 
        ? DateTime.parse(widget.user['updated_at']) 
        : null;
    final lastStudyDate = widget.user['last_study_date'] != null 
        ? DateTime.parse(widget.user['last_study_date']) 
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                    backgroundColor: _isVerified 
                        ? Colors.green.withOpacity(0.3) 
                        : Colors.orange.withOpacity(0.3),
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
                              const Icon(
                                Icons.verified,
                                size: 20,
                                color: Colors.green,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          username,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
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
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.orange.withOpacity(0.1),
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
                    _buildInfoRow(l10n.adminEmail, email),
                    _buildInfoRow(l10n.adminRole, role.toUpperCase()),
                    _buildInfoRow(l10n.adminLicenseType, licenseType),
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
                      '${avgScore.toStringAsFixed(1)}%',
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
                    _buildInfoRow('User ID', widget.user['id'] ?? 'N/A', isMonospace: true),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
