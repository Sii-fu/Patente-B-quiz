import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/theme.dart';
import '../services/admin_repository.dart';
import '../dashboard/admin_dashboard_screen.dart';

class AdminPinScreen extends StatefulWidget {
  const AdminPinScreen({super.key});

  @override
  State<AdminPinScreen> createState() => _AdminPinScreenState();
}

class _AdminPinScreenState extends State<AdminPinScreen>
    with SingleTickerProviderStateMixin {
  final AdminRepository _adminRepository = AdminRepository();
  String _pin = '';
  bool _isVerifying = false;
  bool _hasError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _shakeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _shakeController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_pin.length >= 6 || _isVerifying) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _pin += number;
      _hasError = false;
    });

    if (_pin.length == 6) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_pin.isEmpty || _isVerifying) return;
    
    HapticFeedback.lightImpact();
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _hasError = false;
    });
  }

  Future<void> _verifyPin() async {
    debugPrint('🔐 Starting PIN verification...');
    setState(() {
      _isVerifying = true;
    });

    try {
      debugPrint('🔐 Calling verifyAdminPin RPC...');
      final isValid = await _adminRepository.verifyAdminPin(_pin).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('🔐 PIN verification timeout!');
          return false;
        },
      );

      debugPrint('🔐 PIN verification result: $isValid');
      if (!mounted) return;

      if (isValid) {
        debugPrint('🔐 PIN valid, navigating to dashboard...');
        HapticFeedback.heavyImpact();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) {
            debugPrint('🔐 Building AdminDashboardScreen...');
            return const AdminDashboardScreen();
          }),
        );
        debugPrint('🔐 Navigation complete!');
      } else {
        debugPrint('🔐 PIN invalid');
        HapticFeedback.vibrate();
        _shakeController.forward();
        setState(() {
          _pin = '';
          _hasError = true;
          _isVerifying = false;
        });
      }
    } catch (e) {
      debugPrint('🔐 PIN verification error: $e');
      if (!mounted) return;
      
      HapticFeedback.vibrate();
      _shakeController.forward();
      setState(() {
        _pin = '';
        _hasError = true;
        _isVerifying = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().split('\n').first}'),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),
              
              // Lock Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                l10n.adminSecurityCheck,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 6),
              
              Text(
                l10n.adminEnterPin,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // PIN Display
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _hasError ? _shakeAnimation.value * ((_shakeAnimation.value.toInt() % 2 == 0) ? 1 : -1) : 0,
                      0,
                    ),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = index < _pin.length;
                    return Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled
                            ? (_hasError ? Colors.red : theme.colorScheme.onPrimary)
                            : Colors.transparent,
                        border: Border.all(
                          color: _hasError
                              ? Colors.red
                              : theme.colorScheme.onPrimary.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              
              if (_hasError) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.adminInvalidPin,
                  style: TextStyle(
                    color: Colors.red.shade300,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              
              if (_isVerifying) ...[
                const SizedBox(height: 16),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Numeric Keypad
              _buildKeypad(theme),
              
              const SizedBox(height: 24),
              
              // Logout button
              TextButton.icon(
                onPressed: _logout,
                icon: Icon(
                  Icons.logout,
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  size: 20,
                ),
                label: Text(
                  l10n.profileLogout,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildKeypadRow(['1', '2', '3'], theme),
          const SizedBox(height: 12),
          _buildKeypadRow(['4', '5', '6'], theme),
          const SizedBox(height: 12),
          _buildKeypadRow(['7', '8', '9'], theme),
          const SizedBox(height: 12),
          _buildKeypadRow(['', '0', 'backspace'], theme),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 64);
        }
        
        if (key == 'backspace') {
          return _buildKeypadButton(
            child: Icon(
              Icons.backspace_outlined,
              color: theme.colorScheme.onPrimary,
              size: 22,
            ),
            onPressed: _onBackspacePressed,
            theme: theme,
          );
        }
        
        return _buildKeypadButton(
          child: Text(
            key,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          onPressed: () => _onNumberPressed(key),
          theme: theme,
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required Widget child,
    required VoidCallback onPressed,
    required ThemeData theme,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isVerifying ? null : onPressed,
        borderRadius: BorderRadius.circular(32),
        splashColor: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }
}
