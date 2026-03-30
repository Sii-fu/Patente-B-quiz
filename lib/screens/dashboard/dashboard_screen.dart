import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../l10n/app_localizations.dart';
import '../../utils/constants.dart';
import '../../utils/theme.dart';
import '../../models/profile.dart';
import 'exam_mode_screen.dart';
import 'topic_mode_screen.dart';
import 'review_errors_screen.dart';
import 'theory_chapters_screen.dart';
import 'all_quizzes_screen.dart';
import 'settings_screen.dart';
import 'video_materials_screen.dart';
import 'quick_practice_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../services/profile_stats_service.dart';
import '../theory/theory_card_list_screen.dart';
import 'custom_quiz_screen.dart';
import '../../features/quiz/quiz_screen.dart';
import 'vocabulary_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  // Dashboard stats - loaded from Supabase
  DashboardStats _stats = DashboardStats.empty;
  ProfileStatsService? _statsService;
  bool _isLoadingStats = true;
  
  // User verification status
  Profile? _userProfile;
  bool _isLoadingProfile = true;
  
  String? _userName;
  bool _isGuest = false;
  
  AnimationController? _animationController;
  Animation<double>? _progressAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadUserData();
    _initializeStatsService();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Initialize with 0, will animate to real value after stats load
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOut,
    ));
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoadingProfile = false;
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _userProfile = Profile.fromJson(response);
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }
  
  Future<void> _initializeStatsService() async {
    _statsService = ProfileStatsService();
    await _loadDashboardStats();
  }
  
  Future<void> _loadDashboardStats() async {
    if (_statsService == null) return;
    
    try {
      final stats = await _statsService!.getDashboardStats();
      
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
          
          // Update animation with real progress value
          _progressAnimation = Tween<double>(
            begin: 0.0,
            end: stats.progressPercentage,
          ).animate(CurvedAnimation(
            parent: _animationController!,
            curve: Curves.easeOut,
          ));
        });
        
        // Start the animation
        _animationController!.forward();
      }
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }
  
  /// Refresh stats - call this when returning from quiz or theory screens
  Future<void> refreshStats() async {
    await _loadDashboardStats();
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    
    setState(() {
      _isGuest = prefs.getBool(AppConstants.keyGuestMode) ?? false;
      _userName = user?.email?.split('@').first ?? 'Utente';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    
    // Show loading while checking profile
    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Show pending verification if user is not verified
    if (_userProfile != null && !_userProfile!.isVerified && !_isGuest) {
      return _buildPendingVerificationScreen(context, l10n, theme);
    }
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. Gradient Header Section
              Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Column(
                  children: [
                    // a. Welcome Row
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Profile Icon
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                  );
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Welcome Text
                              Text(
                                '${l10n.dashboardWelcome}, ${_userName ?? l10n.profileTitle}!',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Notification Bell
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // b. Central Performance Card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // 1. Left Section - Progress Ring
                            _buildProgressRing(),
                            
                            // Vertical Divider
                            Container(
                              width: 1,
                              height: 80,
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                            
                            // 2. Middle Section - Streak
                            _buildStatColumn(
                              value: _stats.streak.toString(),
                              label: l10n.dashboardStreak,
                            ),
                            
                            // Vertical Divider
                            Container(
                              width: 1,
                              height: 80,
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                            
                            // 3. Right Section - Chapters Completed
                            _buildStatColumn(
                              value: _stats.completedChapters.toString(),
                              label: l10n.dashboardChapters,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 2. Main Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: _buildMainActionButton(context, l10n),
                  ),
                ),
              ),
              
              // 3. Feature Cards Grid
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildFeatureGrid(context, l10n),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Progress Ring Widget
  Widget _buildProgressRing() {
    final theme = Theme.of(context);
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 10,
              color: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          // Progress Arc
          if (_progressAnimation != null)
            AnimatedBuilder(
              animation: _progressAnimation!,
              builder: (context, child) {
                return SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: _progressAnimation!.value,
                    strokeWidth: 10,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
          // Center Text
          if (_progressAnimation != null)
            AnimatedBuilder(
              animation: _progressAnimation!,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(_progressAnimation!.value * 100).round()}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.dashboardProgress,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
  
  // Stat Column Widget
  Widget _buildStatColumn({
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  // Main Action Button
  Widget _buildMainActionButton(BuildContext context, AppLocalizations l10n) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomQuizScreen(
                numberOfQuestions: 30,
                hasTimeLimit: false,
                timeLimit: 20,
                selectedTopicIds: [],
                immediateAnswerFeedback: true,
              ),
            ),
          );
        }, 
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.dashboardStartNewQuiz,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Feature Cards Grid
  Widget _buildFeatureGrid(BuildContext context, AppLocalizations l10n) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return GridView.count(
      crossAxisCount: isTablet ? 3 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isTablet ? 1.6 : 2,
      children: [
        _buildFeatureCard(
          context: context,
          icon: Icons.bolt,
          iconColor: Theme.of(context).colorScheme.primary,
          title: l10n.quickPracticeTitle,
          subtitle: l10n.dashboardPracticeByTopicDesc,
          tagText: '${(_stats.progressPercentage * 100).round()}%',
          tagColor: AppTheme.successGreen,
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TopicModeScreen()),
            ).then((_) => refreshStats());
          },
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.cancel_outlined,
          iconColor: Theme.of(context).colorScheme.error,
          title: l10n.dashboardReviewErrorsCard,
          subtitle: l10n.dashboardReviewErrorsCardDesc,
          tagText: '${_stats.totalErrors} ${l10n.dashboardErrorsCount}',
          tagColor: Theme.of(context).colorScheme.error,
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ReviewErrorsScreen()),
            ).then((_) => refreshStats());
          },
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.timer_outlined,
          iconColor: Theme.of(context).colorScheme.primary,
          title: l10n.dashboardExamSimulation,
          subtitle: l10n.dashboardExamSimulationDesc,
          tagText: '${_stats.totalQuizzesTaken} ${l10n.dashboardTestCount}',
          tagColor: AppTheme.successGreen,
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ExamModeScreen()),
            ).then((_) => refreshStats());
          },
        ),
        
        _buildFeatureCard(
          context: context,
          icon: Icons.book,
          iconColor: Theme.of(context).colorScheme.secondary,
          title: l10n.dashboardTheoryBook,
          subtitle: l10n.dashboardTheoryBookDesc,
          tagText: l10n.dashboardNew,
          tagColor: Theme.of(context).colorScheme.secondary,
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                // builder: (context) => const TheoryCardListScreen(),
                builder: (context) => const TheoryChaptersScreen(),
              ),
            );
          },
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.menu_book_rounded,
          iconColor: Theme.of(context).colorScheme.tertiary,
          title: l10n.vocabTitle,
          subtitle: l10n.vocabSearchHint,
          tagText: null,
          tagColor: null,
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VocabularyScreen()),
            );
          },
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.video_library,
          iconColor: Color(0xFFFF6B6B),
          title: l10n.dashboardVideoTutorials,
          subtitle: l10n.dashboardVideoTutorialsDesc,
          tagText: '72 ${l10n.dashboardVideoCount}',
          tagColor: Color(0xFFFF6B6B),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VideoMaterialsScreen()),
            );
          },
        ),
      ],
    );
  }
  
  // Feature Card Widget
  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String? tagText,
    required Color? tagColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title stacked vertically
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            height: 1.3,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.clip,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Pending Verification Screen
  Widget _buildPendingVerificationScreen(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.hourglass_empty,
                      size: 80,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Title
                  Text(
                    l10n.pendingVerificationTitle,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Message
                  Text(
                    l10n.pendingVerificationMessage,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Sub-message
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.pendingVerificationSubMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Refresh Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _loadUserProfile();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.pendingVerificationRefresh),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.surface,
                        foregroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Logout Button
                  TextButton.icon(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      await Supabase.instance.client.auth.signOut();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, AppConstants.routeAuth);
                      }
                    },
                    icon: Icon(
                      Icons.logout,
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    ),
                    label: Text(
                      l10n.profileLogout,
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
