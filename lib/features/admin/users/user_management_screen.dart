import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/date_format_helper.dart';
import '../services/admin_repository.dart';

enum UserFilter { all, pending, active, expired, revoked }

/// The four access states an account can be in, derived from `is_verified`
/// and `verified_until`:
///
/// * [pending]  — never approved (`is_verified == false`, no `verified_until`)
/// * [active]   — approved and inside the paid period (or lifetime)
/// * [expired]  — approved but the paid period has passed
/// * [revoked]  — approval withdrawn by an admin after having been granted
///                (`is_verified == false` but `verified_until` survives)
enum UserAccessStatus { pending, active, expired, revoked }

/// Derives the access state from the two DB columns. A revoked account keeps
/// its `verified_until`, which is what separates it from one that was never
/// approved in the first place.
UserAccessStatus accessStatusOf(bool isVerified, DateTime? verifiedUntil) {
  if (!isVerified) {
    return verifiedUntil == null
        ? UserAccessStatus.pending
        : UserAccessStatus.revoked;
  }
  if (verifiedUntil == null) return UserAccessStatus.active; // lifetime
  return verifiedUntil.isAfter(DateTime.now())
      ? UserAccessStatus.active
      : UserAccessStatus.expired;
}

/// Whole days from now until [date]; negative once it is in the past.
int daysUntil(DateTime date) {
  final now = DateTime.now();
  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfTarget = DateTime(date.year, date.month, date.day);
  return startOfTarget.difference(startOfToday).inDays;
}

/// Access expiring within this many days is highlighted amber so the admin
/// can chase a renewal before the student is locked out.
const int kAccessExpiringSoonDays = 14;

/// Shared presentation for an access state, so the cards, the details dialog
/// and the filter chips never drift apart.
///
/// The shade is picked per brightness: the mid-tone Material colours are
/// tuned for light surfaces and lose contrast on dark ones (blue-grey and
/// amber especially), so dark mode gets the lighter shades.
Color accessStatusColor(
  BuildContext context,
  UserAccessStatus status, {
  bool expiringSoon = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  switch (status) {
    case UserAccessStatus.pending:
      return isDark ? Colors.orange.shade300 : Colors.orange.shade800;
    case UserAccessStatus.active:
      if (expiringSoon) {
        return isDark ? Colors.amber.shade300 : Colors.amber.shade800;
      }
      return isDark ? Colors.green.shade300 : Colors.green.shade700;
    case UserAccessStatus.expired:
      return isDark ? Colors.red.shade300 : Colors.red.shade700;
    case UserAccessStatus.revoked:
      return isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade600;
  }
}

/// Tinted fill for the same status. A flat 10% alpha disappears against a
/// dark surface, so the tint is stronger there.
Color accessStatusFill(
  BuildContext context,
  UserAccessStatus status, {
  bool expiringSoon = false,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return accessStatusColor(
    context,
    status,
    expiringSoon: expiringSoon,
  ).withValues(alpha: isDark ? 0.22 : 0.12);
}

IconData accessStatusIcon(UserAccessStatus status) {
  switch (status) {
    case UserAccessStatus.pending:
      return Icons.hourglass_bottom_rounded;
    case UserAccessStatus.active:
      return Icons.verified;
    case UserAccessStatus.expired:
      return Icons.event_busy_rounded;
    case UserAccessStatus.revoked:
      return Icons.block_rounded;
  }
}

String accessStatusLabel(UserAccessStatus status, AppLocalizations l10n) {
  switch (status) {
    case UserAccessStatus.pending:
      return l10n.adminPending;
    case UserAccessStatus.active:
      return l10n.adminVerified;
    case UserAccessStatus.expired:
      return l10n.adminAccessExpired;
    case UserAccessStatus.revoked:
      return l10n.adminFilterRevoked;
  }
}

/// Result of the course-duration picker. Wrapping the nullable month count in
/// an object lets "Unlimited / Lifetime" (months == null) be told apart from
/// the admin dismissing the dialog (a null [_DurationChoice]).
class _DurationChoice {
  final int? months;
  const _DurationChoice(this.months);
}

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

    if (name.contains(q) ||
        username.contains(q) ||
        email.contains(q) ||
        phone.contains(q)) {
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
        result = _withStatus(result, UserAccessStatus.pending);
        break;
      case UserFilter.active:
        result = _withStatus(result, UserAccessStatus.active);
        break;
      case UserFilter.expired:
        result = _withStatus(result, UserAccessStatus.expired);
        break;
      case UserFilter.revoked:
        result = _withStatus(result, UserAccessStatus.revoked);
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

  List<Map<String, dynamic>> _withStatus(
    List<Map<String, dynamic>> users,
    UserAccessStatus status,
  ) => users.where((u) => _statusOf(u) == status).toList();

  int _countOf(UserAccessStatus status) =>
      _allUsers.where((u) => _statusOf(u) == status).length;

  int get _totalCount => _allUsers.length;
  int get _pendingCount => _countOf(UserAccessStatus.pending);
  int get _activeCount => _countOf(UserAccessStatus.active);
  int get _expiredCount => _countOf(UserAccessStatus.expired);
  int get _revokedCount => _countOf(UserAccessStatus.revoked);

  /// Reads `verified_until` off a raw user map. Returns null for lifetime
  /// access, or when the admin RPC does not select the column.
  DateTime? _verifiedUntilOf(Map<String, dynamic> user) {
    final raw = user['verified_until'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  /// Single source of truth for a user's access state — used by the cards,
  /// the details dialog, the filters and the counters alike.
  UserAccessStatus _statusOf(Map<String, dynamic> user) =>
      accessStatusOf(user['is_verified'] == true, _verifiedUntilOf(user));

  /// Asks the admin how long the student's course access should last.
  ///
  /// [currentUntil] is the student's existing expiry, if any. It is shown at
  /// the top of the dialog and used to preview the resulting date on each
  /// option — mirroring the RPC, which anchors at
  /// `GREATEST(now(), verified_until)` so extending never eats unused time.
  /// Returns null if the dialog was dismissed.
  Future<_DurationChoice?> _showDurationPicker(
    String userName,
    DateTime? currentUntil,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return showDialog<_DurationChoice>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.adminSelectCourseDuration),
              const SizedBox(height: 4),
              Text(
                userName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          // Four tiles with date subtitles overflow a landscape phone.
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (currentUntil != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                      child: Text(
                        currentUntil.isAfter(DateTime.now())
                            ? '${l10n.adminCurrentlyExpires}: '
                                  '${formatExpiryDate(dialogContext, currentUntil)}'
                            : '${l10n.adminAlreadyExpired} — '
                                  '${formatExpiryDate(dialogContext, currentUntil)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: currentUntil.isAfter(DateTime.now())
                              ? theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                )
                              : Colors.red,
                        ),
                      ),
                    ),
                  _buildDurationTile(
                    dialogContext,
                    l10n.adminDuration3Months,
                    3,
                    currentUntil,
                  ),
                  _buildDurationTile(
                    dialogContext,
                    l10n.adminDuration6Months,
                    6,
                    currentUntil,
                  ),
                  _buildDurationTile(
                    dialogContext,
                    l10n.adminDuration1Year,
                    12,
                    currentUntil,
                  ),
                  _buildDurationTile(
                    dialogContext,
                    l10n.adminDurationUnlimited,
                    null,
                    currentUntil,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.profileCancel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDurationTile(
    BuildContext dialogContext,
    String label,
    int? months,
    DateTime? currentUntil,
  ) {
    final theme = Theme.of(dialogContext);
    final l10n = AppLocalizations.of(dialogContext)!;
    final isLifetime = months == null;
    final preview = isLifetime
        ? null
        : addMonths(_extensionAnchor(currentUntil), months);

    return ListTile(
      leading: Icon(
        isLifetime
            ? Icons.all_inclusive_rounded
            : Icons.event_available_rounded,
        color: isLifetime ? Colors.blue : theme.colorScheme.primary,
      ),
      title: Text(label),
      subtitle: preview == null
          ? null
          : Text(
              '${l10n.adminNewExpiry}: '
              '${formatExpiryDate(dialogContext, preview)}',
              style: theme.textTheme.bodySmall,
            ),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(dialogContext, _DurationChoice(months));
      },
    );
  }

  /// Where an extension starts counting from: the later of now and the
  /// student's current expiry, matching `GREATEST(now(), verified_until)`
  /// in `func_admin_verify_user`.
  DateTime _extensionAnchor(DateTime? currentUntil) {
    final now = DateTime.now();
    if (currentUntil == null || !currentUntil.isAfter(now)) return now;
    return currentUntil;
  }

  /// Grants or extends access for a duration chosen by the admin. Used by the
  /// verification switch and by the Extend Access button.
  Future<void> _setAccessDuration(Map<String, dynamic> user) async {
    HapticFeedback.mediumImpact();

    final l10n = AppLocalizations.of(context)!;
    final userName = (user['full_name'] ?? l10n.adminUnknownUser).toString();
    final currentUntil = _verifiedUntilOf(user);

    final choice = await _showDurationPicker(userName, currentUntil);
    if (choice == null || !mounted) return; // admin cancelled

    await _applyVerification(
      user['id'].toString(),
      true,
      durationMonths: choice.months,
      currentUntil: currentUntil,
    );
  }

  /// Confirms before cutting a student off — a mis-tapped switch would
  /// otherwise lock out a paying student instantly.
  Future<bool> _confirmRevoke(String userName) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.block_rounded, color: Colors.red, size: 32),
        title: Text(l10n.adminRevokeConfirmTitle),
        content: Text(l10n.adminRevokeConfirmMessage(userName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.adminRevoke),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  Future<void> _toggleUserVerification(String userId, bool newValue) async {
    final index = _allUsers.indexWhere((u) => u['id'] == userId);
    if (index == -1) return;
    final user = _allUsers[index];

    if (newValue) {
      // Verifying requires picking a course duration first.
      await _setAccessDuration(user);
      return;
    }

    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    final userName = (user['full_name'] ?? l10n.adminUnknownUser).toString();
    if (!await _confirmRevoke(userName)) return;
    if (!mounted) return;

    await _applyVerification(userId, false);
  }

  Future<void> _applyVerification(
    String userId,
    bool newValue, {
    int? durationMonths,
    DateTime? currentUntil,
  }) async {
    final success = await _adminRepository.updateUserVerification(
      userId,
      newValue,
      durationMonths: durationMonths,
    );

    if (!mounted) return;

    if (success) {
      // Update local state. The DB is the source of truth for verified_until;
      // this only previews it until the next _loadUsers(). Revoking leaves
      // verified_until intact — that is what marks the account as revoked
      // rather than never-approved.
      final index = _allUsers.indexWhere((u) => u['id'] == userId);
      if (index != -1) {
        setState(() {
          _allUsers[index]['is_verified'] = newValue;
          if (newValue) {
            _allUsers[index]['verified_until'] = durationMonths == null
                ? null // lifetime
                : addMonths(
                    _extensionAnchor(currentUntil),
                    durationMonths,
                  ).toIso8601String();
          }
          _applyFilters();
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            newValue
                ? AppLocalizations.of(context)!.adminUserVerified
                : AppLocalizations.of(context)!.adminUserUnverified,
          ),
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
          // Five states never fit side by side on a phone, so the row scrolls
          // horizontally. A SingleChildScrollView (not a horizontal ListView)
          // keeps the height driven by the chips themselves — a ListView
          // imposes a tight cross-axis height, which stretches the pills and
          // breaks as soon as the text scale grows.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                  color: accessStatusColor(context, UserAccessStatus.pending),
                  filter: UserFilter.pending,
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _buildStatFilterCard(
                  label: l10n.adminFilterActive,
                  count: _activeCount,
                  icon: Icons.verified_user_rounded,
                  color: accessStatusColor(context, UserAccessStatus.active),
                  filter: UserFilter.active,
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _buildStatFilterCard(
                  label: l10n.adminFilterExpired,
                  count: _expiredCount,
                  icon: Icons.event_busy_rounded,
                  color: accessStatusColor(context, UserAccessStatus.expired),
                  filter: UserFilter.expired,
                  theme: theme,
                ),
                const SizedBox(width: 10),
                _buildStatFilterCard(
                  label: l10n.adminFilterRevoked,
                  count: _revokedCount,
                  icon: Icons.block_rounded,
                  color: accessStatusColor(context, UserAccessStatus.revoked),
                  filter: UserFilter.revoked,
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
                  Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
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
          Expanded(child: _buildUserList()),
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
        prefixIcon: Icon(
          Icons.search_rounded,
          color: theme.colorScheme.primary,
        ),
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
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.4,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
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

    // The chip sizes to its own content, but a long translation at a large
    // accessibility text scale would otherwise push it arbitrarily wide, so
    // cap it and let the label ellipsize. The cap grows with the text scale
    // so bigger type still gets more room rather than being cut off sooner.
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final maxChipWidth = 190.0 * textScale.clamp(1.0, 1.6);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
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
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.16)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.35,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                count.toString(),
                maxLines: 1,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isSelected ? color : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 5),
              // Flexible, not Expanded: the chip shrink-wraps its label until
              // it hits maxChipWidth, and only then does the text ellipsize.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? color
                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
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
    final isAdmin =
        (user['role'] ?? 'user').toString().toLowerCase() == 'admin';
    final createdAt = user['created_at'] != null
        ? DateTime.tryParse(user['created_at'].toString())
        : null;
    final status = _statusOf(user);
    final verifiedUntil = _verifiedUntilOf(user);
    // Green normally, amber when a renewal is due soon, red once expired,
    // grey-blue for a revoked account.
    final expiringSoon =
        status == UserAccessStatus.active &&
        verifiedUntil != null &&
        daysUntil(verifiedUntil) <= kAccessExpiringSoonDays;
    final statusColor = accessStatusColor(
      context,
      status,
      expiringSoon: expiringSoon,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
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
                            if (status != UserAccessStatus.pending) ...[
                              const SizedBox(width: 4),
                              Icon(
                                accessStatusIcon(status),
                                size: 16,
                                color: statusColor,
                              ),
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
                          _buildSubInfo(
                            Icons.alternate_email_rounded,
                            username,
                            theme,
                          ),
                        if (status != UserAccessStatus.pending) ...[
                          const SizedBox(height: 2),
                          _buildAccessInfo(status, verifiedUntil, theme, l10n),
                        ],
                      ],
                    ),
                  ),

                  // Verification Switch
                  Column(
                    children: [
                      Switch(
                        value: isVerified,
                        onChanged: (value) =>
                            _toggleUserVerification(user['id'], value),
                        activeColor: Colors.green,
                      ),
                      Text(
                        accessStatusLabel(status, l10n),
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Extend for anyone who already has a history; plain
                      // "Set Access" for a never-approved account.
                      if (status != UserAccessStatus.pending)
                        TextButton.icon(
                          onPressed: () => _setAccessDuration(user),
                          icon: const Icon(
                            Icons.event_repeat_rounded,
                            size: 14,
                          ),
                          label: Text(
                            status == UserAccessStatus.active
                                ? l10n.adminExtendAccess
                                : l10n.adminSetAccess,
                            style: const TextStyle(fontSize: 11),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              Divider(
                height: 20,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildUserStat(
                    Icons.star_rounded,
                    'XP: $xp',
                    Colors.amber,
                    theme,
                  ),
                  _buildUserStat(
                    Icons.trending_up_rounded,
                    '${l10n.profileLevel}: $level',
                    Colors.blue,
                    theme,
                  ),
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
        Icon(
          icon,
          size: 13,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
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

  /// One-line access summary for a verified user: lifetime, an expiry date,
  /// or "Expired" in red once the course period has passed.
  Widget _buildAccessInfo(
    UserAccessStatus status,
    DateTime? until,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    // Revoked: show when the access they had was set to end, if known.
    if (status == UserAccessStatus.revoked) {
      final label = until == null
          ? l10n.adminAccessRevoked
          : '${l10n.adminAccessRevoked} — ${formatExpiryDate(context, until)}';
      return _buildAccessLine(
        Icons.block_rounded,
        label,
        accessStatusColor(context, UserAccessStatus.revoked),
        theme,
        emphasised: true,
      );
    }

    // Lifetime access.
    if (until == null) {
      return _buildSubInfo(
        Icons.all_inclusive_rounded,
        l10n.adminAccessLifetime,
        theme,
      );
    }

    final date = formatExpiryDate(context, until);

    if (status == UserAccessStatus.expired) {
      return _buildAccessLine(
        Icons.event_busy_rounded,
        '${l10n.adminAccessExpired}: $date',
        accessStatusColor(context, UserAccessStatus.expired),
        theme,
        emphasised: true,
      );
    }

    // Active — append the remaining time so renewals can be chased early.
    final days = daysUntil(until);
    final remaining = days <= 0
        ? l10n.adminExpiresToday
        : l10n.adminDaysLeft(days);
    final label = '${l10n.adminAccessExpires}: $date · $remaining';

    if (days <= kAccessExpiringSoonDays) {
      return _buildAccessLine(
        Icons.event_repeat_rounded,
        label,
        accessStatusColor(context, UserAccessStatus.active, expiringSoon: true),
        theme,
        emphasised: true,
      );
    }

    return _buildSubInfo(Icons.event_available_rounded, label, theme);
  }

  /// A [_buildSubInfo]-shaped line that can carry its own colour, for the
  /// states that need to stand out from the muted default.
  Widget _buildAccessLine(
    IconData icon,
    String label,
    Color color,
    ThemeData theme, {
    bool emphasised = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: emphasised ? FontWeight.w600 : FontWeight.normal,
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
        onSetAccess: (u) async {
          Navigator.pop(context);
          await _setAccessDuration(u);
        },
      ),
    );
  }

  Widget _buildUserStat(
    IconData icon,
    String text,
    Color color,
    ThemeData theme,
  ) {
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
  final Function(Map<String, dynamic> user) onSetAccess;

  const _UserDetailsDialog({
    required this.user,
    required this.onToggleVerification,
    required this.onSetAccess,
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
        widget.user['phone'] ??
        widget.user['phone_number'] ??
        widget.user['mobile'] ??
        '';
    final value = raw.toString();
    return value.isEmpty ? 'N/A' : value;
  }

  DateTime? get _verifiedUntil {
    final raw = widget.user['verified_until'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  UserAccessStatus get _status => accessStatusOf(_isVerified, _verifiedUntil);

  bool get _isAccessExpired => _status == UserAccessStatus.expired;

  String _accessLabel(BuildContext context, AppLocalizations l10n) {
    final until = _verifiedUntil;

    if (_status == UserAccessStatus.revoked) {
      return until == null
          ? l10n.adminAccessRevoked
          : '${l10n.adminAccessRevoked} — ${formatExpiryDate(context, until)}';
    }
    if (until == null) return l10n.adminAccessLifetime;

    final date = formatExpiryDate(context, until);
    if (_isAccessExpired) return '${l10n.adminAccessExpired}: $date';

    final days = daysUntil(until);
    final remaining = days <= 0
        ? l10n.adminExpiresToday
        : l10n.adminDaysLeft(days);
    return '${l10n.adminAccessExpires}: $date · $remaining';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statusColor = accessStatusColor(context, _status);
    // Everything in the header sits on primaryContainer, so it must be
    // painted with onPrimaryContainer — not onSurface.
    final onHeader = theme.colorScheme.onPrimaryContainer;

    final fullName = (widget.user['full_name'] ?? l10n.adminUnknownUser)
        .toString();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Opaque fill: a translucent status tint over the coloured
                  // header blended into mud.
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.surface,
                    child: Text(
                      (fullName.isNotEmpty ? fullName[0] : '?').toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: statusColor,
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: onHeader,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_status != UserAccessStatus.pending) ...[
                              const SizedBox(width: 6),
                              // Status badge: an opaque pill so the status
                              // colour is not diluted by the header tint.
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      accessStatusIcon(_status),
                                      size: 13,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      accessStatusLabel(_status, l10n),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          username,
                          style: TextStyle(
                            color: onHeader.withValues(alpha: 0.75),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: onHeader,
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
                      elevation: 0,
                      color: accessStatusFill(context, _status),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: statusColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  accessStatusIcon(_status),
                                  color: statusColor,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.adminVerificationStatus,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        accessStatusLabel(_status, l10n),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: statusColor,
                                        ),
                                      ),
                                      if (_status != UserAccessStatus.pending)
                                        Text(
                                          _accessLabel(context, l10n),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isVerified,
                                  onChanged: (value) {
                                    HapticFeedback.mediumImpact();
                                    // setState first: the callback pops this
                                    // dialog.
                                    setState(() {
                                      _isVerified = value;
                                    });
                                    widget.onToggleVerification(
                                      widget.user['id'],
                                      value,
                                    );
                                  },
                                  activeColor: Colors.green,
                                ),
                              ],
                            ),
                            // Change the course period without having to
                            // toggle the switch off and on again.
                            if (_status != UserAccessStatus.pending) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      widget.onSetAccess(widget.user),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: statusColor,
                                    side: BorderSide(
                                      color: statusColor.withValues(alpha: 0.6),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.event_repeat_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _status == UserAccessStatus.active
                                        ? l10n.adminExtendAccess
                                        : l10n.adminSetAccess,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Account Information
                    _buildSectionTitle(
                      l10n.adminAccountInfo,
                      Icons.account_circle,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(l10n.profilePhone, _phone()),
                    _buildInfoRow(l10n.adminEmail, email),
                    _buildInfoRow(l10n.adminRole, role.toUpperCase()),
                    _buildInfoRow(
                      l10n.adminLicenseType,
                      licenseType.toString(),
                    ),
                    if (createdAt != null)
                      _buildInfoRow(
                        l10n.adminJoinedDate,
                        '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                      ),

                    const SizedBox(height: 20),

                    // Progress Stats
                    _buildSectionTitle(
                      l10n.adminProgressStats,
                      Icons.analytics,
                    ),
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
                    _buildSectionTitle(
                      l10n.adminSystemInfo,
                      Icons.info_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      'User ID',
                      (widget.user['id'] ?? 'N/A').toString(),
                      isMonospace: true,
                    ),
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
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

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
