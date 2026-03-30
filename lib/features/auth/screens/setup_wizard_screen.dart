import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/constants.dart';

class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  String _selectedLicenseType = 'B'; // Default to B
  final TextEditingController _schoolCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _schoolCodeController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save user preferences
      await prefs.setString(AppConstants.keyLicenseType, _selectedLicenseType);
      await prefs.setString(
        AppConstants.keyDrivingSchoolCode,
        _schoolCodeController.text.trim(),
      );
      await prefs.setBool(AppConstants.keyCompletedSetup, true);

      if (mounted) {
        // Navigate to Auth screen
        Navigator.pushReplacementNamed(context, AppConstants.routeAuth);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.setupErrorSaving}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              // Header
              Text(
                l10n.setupWelcome,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.setupSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 48),

              // License Type Selection
              Text(
                l10n.setupLicenseType,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLicenseType, 
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down),
                    style: Theme.of(context).textTheme.bodyLarge,
                    items: AppConstants.licenseTypes.map((String type) {
                      String label;
                      switch (type) {
                        case 'B':
                          label = l10n.licenseB;
                          break;
                        case 'A':
                          label = l10n.licenseA;
                          break;
                        case 'AM':
                          label = l10n.licenseAM;
                          break;
                        default:
                          label = 'License $type';
                      }
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedLicenseType = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Driving School Code (Optional)
              Text(
                l10n.setupSchoolCode,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.setupSchoolCodeHint,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _schoolCodeController,
                decoration: InputDecoration(
                  hintText: l10n.setupSchoolCodePlaceholder,
                  prefixIcon: Icon(Icons.school),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 48),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _completeSetup,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(l10n.setupContinue),
                ),
              ),
              const SizedBox(height: 16),

              // Info text
              Center(
                child: Text(
                  l10n.setupInfoText,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
