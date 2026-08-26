import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Desh Bangla Patente'**
  String get appTitle;

  /// No description provided for @splashPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing for the exam'**
  String get splashPreparing;

  /// No description provided for @splashSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get splashSelectLanguage;

  /// No description provided for @splashContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get splashContinue;

  /// No description provided for @setupWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get setupWelcome;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure your profile to get started'**
  String get setupSubtitle;

  /// No description provided for @setupLicenseType.
  ///
  /// In en, this message translates to:
  /// **'License Type'**
  String get setupLicenseType;

  /// No description provided for @setupSchoolCode.
  ///
  /// In en, this message translates to:
  /// **'Driving School Code (Optional)'**
  String get setupSchoolCode;

  /// No description provided for @setupSchoolCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the code provided by your driving school'**
  String get setupSchoolCodeHint;

  /// No description provided for @setupSchoolCodePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'E.g.: ABC123'**
  String get setupSchoolCodePlaceholder;

  /// No description provided for @setupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get setupContinue;

  /// No description provided for @setupInfoText.
  ///
  /// In en, this message translates to:
  /// **'You can change these settings later'**
  String get setupInfoText;

  /// No description provided for @setupErrorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings'**
  String get setupErrorSaving;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get authWelcomeBack;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get authCreateAccount;

  /// No description provided for @authSubtitleLogin.
  ///
  /// In en, this message translates to:
  /// **'Login to continue your journey'**
  String get authSubtitleLogin;

  /// No description provided for @authSubtitleSignup.
  ///
  /// In en, this message translates to:
  /// **'Register to start studying'**
  String get authSubtitleSignup;

  /// No description provided for @authContinueFacebook.
  ///
  /// In en, this message translates to:
  /// **'Continue with Facebook'**
  String get authContinueFacebook;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'youremail@example.com'**
  String get authEmailHint;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'••••••••'**
  String get authPasswordHint;

  /// No description provided for @authLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLogin;

  /// No description provided for @authSignup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignup;

  /// No description provided for @authToggleSignup.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get authToggleSignup;

  /// No description provided for @authToggleLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get authToggleLogin;

  /// No description provided for @authGuestMode.
  ///
  /// In en, this message translates to:
  /// **'Continue as guest'**
  String get authGuestMode;

  /// No description provided for @authErrorEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authErrorEmail;

  /// No description provided for @authErrorEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get authErrorEmailInvalid;

  /// No description provided for @authErrorPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authErrorPassword;

  /// No description provided for @authErrorPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authErrorPasswordShort;

  /// No description provided for @authErrorFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook Sign-In error'**
  String get authErrorFacebook;

  /// No description provided for @authSignupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration complete! Check your email to verify your account.'**
  String get authSignupSuccess;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we will send you instructions to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordLink.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLink;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Instructions'**
  String get sendResetLink;

  /// No description provided for @resetEmailSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'We have sent reset instructions to your email.'**
  String get resetEmailSentSuccess;

  /// No description provided for @openEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Open Email App'**
  String get openEmailApp;

  /// No description provided for @enterOtpCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 8-digit code'**
  String get enterOtpCode;

  /// No description provided for @otpCodeHint.
  ///
  /// In en, this message translates to:
  /// **'8-digit code'**
  String get otpCodeHint;

  /// No description provided for @verifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// No description provided for @resendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get resendResetEmail;

  /// No description provided for @newPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set New Password'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully! Please log in with your new password.'**
  String get passwordResetSuccess;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupTitle;

  /// No description provided for @signupHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Join Us!'**
  String get signupHeaderTitle;

  /// No description provided for @signupHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account to start learning'**
  String get signupHeaderSubtitle;

  /// No description provided for @signupFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get signupFullName;

  /// No description provided for @signupFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get signupFullNameHint;

  /// No description provided for @signupPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get signupPhone;

  /// No description provided for @signupPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+39 123 456 7890'**
  String get signupPhoneHint;

  /// No description provided for @signupPhoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number'**
  String get signupPhoneHelper;

  /// No description provided for @signupLicenseType.
  ///
  /// In en, this message translates to:
  /// **'License Type'**
  String get signupLicenseType;

  /// No description provided for @signupPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Create a strong password'**
  String get signupPasswordHint;

  /// No description provided for @signupPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters with 1 number'**
  String get signupPasswordHelper;

  /// No description provided for @signupConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get signupConfirmPassword;

  /// No description provided for @signupConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get signupConfirmPasswordHint;

  /// No description provided for @signupButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupButton;

  /// No description provided for @signupAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get signupAlreadyHaveAccount;

  /// No description provided for @signupTermsNotice.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you agree to our Terms of Service and Privacy Policy'**
  String get signupTermsNotice;

  /// No description provided for @signupSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully! Check your email to verify.'**
  String get signupSuccessMessage;

  /// No description provided for @signupErrorGeneral.
  ///
  /// In en, this message translates to:
  /// **'Signup failed. Please try again.'**
  String get signupErrorGeneral;

  /// No description provided for @signupErrorEmailExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get signupErrorEmailExists;

  /// No description provided for @signupErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Please choose a stronger password.'**
  String get signupErrorWeakPassword;

  /// No description provided for @signupErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get signupErrorNetwork;

  /// No description provided for @signupErrorFullNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get signupErrorFullNameRequired;

  /// No description provided for @signupErrorFullNameShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get signupErrorFullNameShort;

  /// No description provided for @signupErrorPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get signupErrorPhoneRequired;

  /// No description provided for @signupErrorPhoneShort.
  ///
  /// In en, this message translates to:
  /// **'Phone number is too short'**
  String get signupErrorPhoneShort;

  /// No description provided for @signupErrorPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get signupErrorPhoneInvalid;

  /// No description provided for @signupErrorConfirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get signupErrorConfirmPasswordRequired;

  /// No description provided for @signupErrorPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get signupErrorPasswordsDoNotMatch;

  /// No description provided for @signupErrorPasswordNeedsNumber.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one number'**
  String get signupErrorPasswordNeedsNumber;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Driving License Quiz'**
  String get homeTitle;

  /// No description provided for @homeLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get homeLogout;

  /// No description provided for @homeGuestMode.
  ///
  /// In en, this message translates to:
  /// **'Home - Guest Mode'**
  String get homeGuestMode;

  /// No description provided for @homeRegisteredUser.
  ///
  /// In en, this message translates to:
  /// **'Home - Registered User'**
  String get homeRegisteredUser;

  /// No description provided for @homeLicense.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get homeLicense;

  /// No description provided for @homeSchool.
  ///
  /// In en, this message translates to:
  /// **'Driving School'**
  String get homeSchool;

  /// No description provided for @homeOnboardingComplete.
  ///
  /// In en, this message translates to:
  /// **'Onboarding completed successfully!'**
  String get homeOnboardingComplete;

  /// No description provided for @homeOnboardingInfo.
  ///
  /// In en, this message translates to:
  /// **'This is the Home placeholder screen. Quiz features will be implemented in the next phases.'**
  String get homeOnboardingInfo;

  /// No description provided for @homeGuestWarning.
  ///
  /// In en, this message translates to:
  /// **'You are using guest mode. Your progress will not be saved.'**
  String get homeGuestWarning;

  /// No description provided for @offlineDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download for Offline Use'**
  String get offlineDownloadTitle;

  /// No description provided for @offlineDownloadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download all questions and study offline'**
  String get offlineDownloadSubtitle;

  /// No description provided for @offlineDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading Content...'**
  String get offlineDownloading;

  /// No description provided for @offlineReady.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode Ready'**
  String get offlineReady;

  /// No description provided for @offlineDescription.
  ///
  /// In en, this message translates to:
  /// **'All content is available offline'**
  String get offlineDescription;

  /// No description provided for @offlineUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get offlineUpdate;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageItalian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// No description provided for @languageBangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBangla;

  /// No description provided for @licenseB.
  ///
  /// In en, this message translates to:
  /// **'License B'**
  String get licenseB;

  /// No description provided for @licenseA.
  ///
  /// In en, this message translates to:
  /// **'License A'**
  String get licenseA;

  /// No description provided for @licenseAM.
  ///
  /// In en, this message translates to:
  /// **'License AM'**
  String get licenseAM;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardReadiness.
  ///
  /// In en, this message translates to:
  /// **'Readiness'**
  String get dashboardReadiness;

  /// No description provided for @dashboardExamMode.
  ///
  /// In en, this message translates to:
  /// **'Exam Simulation'**
  String get dashboardExamMode;

  /// No description provided for @dashboardExamModeDesc.
  ///
  /// In en, this message translates to:
  /// **'30 questions in 20 minutes'**
  String get dashboardExamModeDesc;

  /// No description provided for @dashboardTopicMode.
  ///
  /// In en, this message translates to:
  /// **'Quiz by Topic'**
  String get dashboardTopicMode;

  /// No description provided for @dashboardTopicModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Study specific topics'**
  String get dashboardTopicModeDesc;

  /// No description provided for @dashboardReviewErrors.
  ///
  /// In en, this message translates to:
  /// **'Review Errors'**
  String get dashboardReviewErrors;

  /// No description provided for @dashboardReviewErrorsDesc.
  ///
  /// In en, this message translates to:
  /// **'Review your mistakes'**
  String get dashboardReviewErrorsDesc;

  /// No description provided for @dashboardDailyStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get dashboardDailyStreak;

  /// No description provided for @dashboardCurrentLevel.
  ///
  /// In en, this message translates to:
  /// **'Current Level'**
  String get dashboardCurrentLevel;

  /// No description provided for @dashboardLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get dashboardLevelBeginner;

  /// No description provided for @dashboardLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get dashboardLevelIntermediate;

  /// No description provided for @dashboardLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get dashboardLevelAdvanced;

  /// No description provided for @dashboardLevelExpert.
  ///
  /// In en, this message translates to:
  /// **'Expert'**
  String get dashboardLevelExpert;

  /// No description provided for @dashboardDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get dashboardDays;

  /// No description provided for @dashboardWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get dashboardWelcome;

  /// No description provided for @dashboardProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get dashboardProgress;

  /// No description provided for @dashboardStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get dashboardStreak;

  /// No description provided for @dashboardChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get dashboardChapters;

  /// No description provided for @dashboardStartNewQuiz.
  ///
  /// In en, this message translates to:
  /// **'START A NEW QUIZ'**
  String get dashboardStartNewQuiz;

  /// No description provided for @dashboardPracticeByTopic.
  ///
  /// In en, this message translates to:
  /// **'Practice by Topic'**
  String get dashboardPracticeByTopic;

  /// No description provided for @dashboardPracticeByTopicDesc.
  ///
  /// In en, this message translates to:
  /// **'Improve on individual topics'**
  String get dashboardPracticeByTopicDesc;

  /// No description provided for @dashboardReviewErrorsCard.
  ///
  /// In en, this message translates to:
  /// **'Review Errors'**
  String get dashboardReviewErrorsCard;

  /// No description provided for @dashboardReviewErrorsCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Review your mistakes'**
  String get dashboardReviewErrorsCardDesc;

  /// No description provided for @dashboardExamSimulation.
  ///
  /// In en, this message translates to:
  /// **'Exam Simulation'**
  String get dashboardExamSimulation;

  /// No description provided for @dashboardExamSimulationDesc.
  ///
  /// In en, this message translates to:
  /// **'30 questions in 20 minutes'**
  String get dashboardExamSimulationDesc;

  /// No description provided for @dashboardCompleteStatistics.
  ///
  /// In en, this message translates to:
  /// **'Complete Statistics'**
  String get dashboardCompleteStatistics;

  /// No description provided for @dashboardCompleteStatisticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Analyze your progress'**
  String get dashboardCompleteStatisticsDesc;

  /// No description provided for @dashboardErrorsCount.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get dashboardErrorsCount;

  /// No description provided for @dashboardTestCount.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get dashboardTestCount;

  /// No description provided for @dashboardTheoryBook.
  ///
  /// In en, this message translates to:
  /// **'Theory Book'**
  String get dashboardTheoryBook;

  /// No description provided for @dashboardTheoryBookDesc.
  ///
  /// In en, this message translates to:
  /// **'Access the complete theory book'**
  String get dashboardTheoryBookDesc;

  /// No description provided for @dashboardAllQuizzes.
  ///
  /// In en, this message translates to:
  /// **'All Quizzes'**
  String get dashboardAllQuizzes;

  /// No description provided for @dashboardAllQuizzesDesc.
  ///
  /// In en, this message translates to:
  /// **'Access all quizzes'**
  String get dashboardAllQuizzesDesc;

  /// No description provided for @dashboardSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get dashboardSettings;

  /// No description provided for @dashboardSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust your preferences'**
  String get dashboardSettingsDesc;

  /// No description provided for @dashboardVideoTutorials.
  ///
  /// In en, this message translates to:
  /// **'Video Tutorials'**
  String get dashboardVideoTutorials;

  /// No description provided for @dashboardVideoTutorialsDesc.
  ///
  /// In en, this message translates to:
  /// **'Watch guided lessons'**
  String get dashboardVideoTutorialsDesc;

  /// No description provided for @dashboardLiveClasses.
  ///
  /// In en, this message translates to:
  /// **'Live Classes'**
  String get dashboardLiveClasses;

  /// No description provided for @dashboardLiveClassesDesc.
  ///
  /// In en, this message translates to:
  /// **'Watch live class recordings'**
  String get dashboardLiveClassesDesc;

  /// No description provided for @dashboardVideoCount.
  ///
  /// In en, this message translates to:
  /// **'videos'**
  String get dashboardVideoCount;

  /// No description provided for @dashboardNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get dashboardNotifications;

  /// No description provided for @dashboardComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get dashboardComingSoon;

  /// No description provided for @dashboardNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get dashboardNew;

  /// No description provided for @quickPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Practice'**
  String get quickPracticeTitle;

  /// No description provided for @quickPracticeHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Practice'**
  String get quickPracticeHeaderTitle;

  /// No description provided for @quickPracticeHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a topic and start practicing instantly'**
  String get quickPracticeHeaderSubtitle;

  /// No description provided for @quickPracticeSelectTopic.
  ///
  /// In en, this message translates to:
  /// **'Select Topic'**
  String get quickPracticeSelectTopic;

  /// No description provided for @quickPracticeChooseTopic.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a topic'**
  String get quickPracticeChooseTopic;

  /// No description provided for @quickPracticeTapToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap to change'**
  String get quickPracticeTapToChange;

  /// No description provided for @quickPracticeNumberOfQuestions.
  ///
  /// In en, this message translates to:
  /// **'Number of Questions'**
  String get quickPracticeNumberOfQuestions;

  /// No description provided for @quickPracticeInfoText.
  ///
  /// In en, this message translates to:
  /// **'Questions are randomly selected from the chosen topic. Answers are shown immediately after each question.'**
  String get quickPracticeInfoText;

  /// No description provided for @quickPracticeStartButton.
  ///
  /// In en, this message translates to:
  /// **'START PRACTICE'**
  String get quickPracticeStartButton;

  /// No description provided for @quickPracticeSelectTopicError.
  ///
  /// In en, this message translates to:
  /// **'Please select a topic first'**
  String get quickPracticeSelectTopicError;

  /// No description provided for @videoTitle.
  ///
  /// In en, this message translates to:
  /// **'VIDEO TUTORIALS'**
  String get videoTitle;

  /// No description provided for @videoLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading video library...'**
  String get videoLoadingTitle;

  /// No description provided for @videoLoadingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Preparing video tutorials'**
  String get videoLoadingSubtitle;

  /// No description provided for @videoLoadingReady.
  ///
  /// In en, this message translates to:
  /// **'🎥 Get ready to watch!'**
  String get videoLoadingReady;

  /// No description provided for @videoHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn with Videos'**
  String get videoHeaderTitle;

  /// No description provided for @videoHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'72 video tutorials across 8 categories'**
  String get videoHeaderSubtitle;

  /// No description provided for @videoCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Categories'**
  String get videoCategoriesTitle;

  /// No description provided for @videoOpeningCategory.
  ///
  /// In en, this message translates to:
  /// **'Opening {categoryName} videos...'**
  String videoOpeningCategory(Object categoryName);

  /// No description provided for @examModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Exam Simulation'**
  String get examModeTitle;

  /// No description provided for @examModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Take a full practice exam under real exam conditions. 30 random questions, 20 minutes time limit. Maximum 4 errors allowed to pass.'**
  String get examModeDescription;

  /// No description provided for @examModeStart.
  ///
  /// In en, this message translates to:
  /// **'Start Exam'**
  String get examModeStart;

  /// No description provided for @examModeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get examModeComingSoon;

  /// No description provided for @topicModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz by Topic'**
  String get topicModeTitle;

  /// No description provided for @topicModeDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose a specific topic to study. Practice questions from the 25 official chapters of the Italian driving license exam.'**
  String get topicModeDescription;

  /// No description provided for @topicModeSelectTopic.
  ///
  /// In en, this message translates to:
  /// **'Select Topic'**
  String get topicModeSelectTopic;

  /// No description provided for @topicModeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get topicModeComingSoon;

  /// No description provided for @reviewErrorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Errors'**
  String get reviewErrorsTitle;

  /// No description provided for @reviewErrorsDescription.
  ///
  /// In en, this message translates to:
  /// **'Review all the questions you answered incorrectly. Focus on your weak areas and improve your score.'**
  String get reviewErrorsDescription;

  /// No description provided for @reviewErrorsStart.
  ///
  /// In en, this message translates to:
  /// **'Start Review'**
  String get reviewErrorsStart;

  /// No description provided for @reviewErrorsNoErrors.
  ///
  /// In en, this message translates to:
  /// **'No errors to review yet. Take a quiz first!'**
  String get reviewErrorsNoErrors;

  /// No description provided for @reviewErrorsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get reviewErrorsComingSoon;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get profileFullName;

  /// No description provided for @profileFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get profileFullNameHint;

  /// No description provided for @profilePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get profilePhone;

  /// No description provided for @profilePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get profilePhoneHint;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileLicenseType.
  ///
  /// In en, this message translates to:
  /// **'License Type'**
  String get profileLicenseType;

  /// No description provided for @profileDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get profileDarkMode;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get profileSaveButton;

  /// No description provided for @profileSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get profileSaving;

  /// No description provided for @profileSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileSaveSuccess;

  /// No description provided for @profileSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get profileSaveError;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get profileLoadError;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get profileLogoutConfirm;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @profileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get profileConfirm;

  /// No description provided for @profileAccountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get profileAccountInfo;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileStats.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get profileStats;

  /// No description provided for @profileTotalQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Total Quizzes'**
  String get profileTotalQuizzes;

  /// No description provided for @profileAverageScore.
  ///
  /// In en, this message translates to:
  /// **'Average Score'**
  String get profileAverageScore;

  /// No description provided for @profileXP.
  ///
  /// In en, this message translates to:
  /// **'Experience Points'**
  String get profileXP;

  /// No description provided for @profileLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get profileLevel;

  /// No description provided for @quizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizTitle;

  /// No description provided for @quizQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get quizQuestion;

  /// No description provided for @quizOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get quizOf;

  /// No description provided for @quizTrue.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get quizTrue;

  /// No description provided for @quizFalse.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get quizFalse;

  /// No description provided for @quizSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Quiz'**
  String get quizSubmit;

  /// No description provided for @quizTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get quizTimeRemaining;

  /// No description provided for @quizTimeUp.
  ///
  /// In en, this message translates to:
  /// **'Time\'s Up!'**
  String get quizTimeUp;

  /// No description provided for @quizSubmitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit?'**
  String get quizSubmitConfirm;

  /// No description provided for @quizSubmitMessage.
  ///
  /// In en, this message translates to:
  /// **'You have answered'**
  String get quizSubmitMessage;

  /// No description provided for @quizSubmitOutOf.
  ///
  /// In en, this message translates to:
  /// **'out of'**
  String get quizSubmitOutOf;

  /// No description provided for @quizSubmitQuestions.
  ///
  /// In en, this message translates to:
  /// **'questions'**
  String get quizSubmitQuestions;

  /// No description provided for @quizTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get quizTranslate;

  /// No description provided for @quizOriginal.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get quizOriginal;

  /// No description provided for @quizLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading questions...'**
  String get quizLoading;

  /// No description provided for @quizLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load questions'**
  String get quizLoadError;

  /// No description provided for @quizNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'No questions available'**
  String get quizNoQuestions;

  /// No description provided for @quizTapToZoom.
  ///
  /// In en, this message translates to:
  /// **'Tap to zoom'**
  String get quizTapToZoom;

  /// No description provided for @quizImageDialog.
  ///
  /// In en, this message translates to:
  /// **'Question Image'**
  String get quizImageDialog;

  /// No description provided for @quizClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get quizClose;

  /// No description provided for @quizAnswered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get quizAnswered;

  /// No description provided for @quizUnanswered.
  ///
  /// In en, this message translates to:
  /// **'Unanswered'**
  String get quizUnanswered;

  /// No description provided for @quizCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get quizCorrectAnswer;

  /// No description provided for @quizAnswerTrue.
  ///
  /// In en, this message translates to:
  /// **'VERO'**
  String get quizAnswerTrue;

  /// No description provided for @quizAnswerFalse.
  ///
  /// In en, this message translates to:
  /// **'FALSO'**
  String get quizAnswerFalse;

  /// No description provided for @quizAnswerCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get quizAnswerCorrect;

  /// No description provided for @quizAnswerIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get quizAnswerIncorrect;

  /// No description provided for @quizShowExplanation.
  ///
  /// In en, this message translates to:
  /// **'Show Explanation'**
  String get quizShowExplanation;

  /// No description provided for @quizHideExplanation.
  ///
  /// In en, this message translates to:
  /// **'Hide Explanation'**
  String get quizHideExplanation;

  /// No description provided for @quizContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get quizContinue;

  /// No description provided for @quizExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Quiz?'**
  String get quizExitTitle;

  /// No description provided for @quizExitMessage.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be lost if you exit now. Are you sure you want to go back?'**
  String get quizExitMessage;

  /// No description provided for @quizStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get quizStay;

  /// No description provided for @quizExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get quizExit;

  /// No description provided for @quizGoBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get quizGoBack;

  /// No description provided for @quizTranslations.
  ///
  /// In en, this message translates to:
  /// **'Translations'**
  String get quizTranslations;

  /// No description provided for @quizEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get quizEnglish;

  /// No description provided for @quizBangla.
  ///
  /// In en, this message translates to:
  /// **'বাংলা (Bangla)'**
  String get quizBangla;

  /// No description provided for @quizPlayingAudio.
  ///
  /// In en, this message translates to:
  /// **'Playing audio...'**
  String get quizPlayingAudio;

  /// No description provided for @quizAudioNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Audio not available'**
  String get quizAudioNotAvailable;

  /// No description provided for @quizQuestionImage.
  ///
  /// In en, this message translates to:
  /// **'Question Image'**
  String get quizQuestionImage;

  /// No description provided for @quizFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get quizFinish;

  /// No description provided for @resultTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz Results'**
  String get resultTitle;

  /// No description provided for @resultPromoted.
  ///
  /// In en, this message translates to:
  /// **'PROMOTED'**
  String get resultPromoted;

  /// No description provided for @resultRejected.
  ///
  /// In en, this message translates to:
  /// **'REJECTED'**
  String get resultRejected;

  /// No description provided for @resultPassed.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You passed!'**
  String get resultPassed;

  /// No description provided for @resultFailed.
  ///
  /// In en, this message translates to:
  /// **'You did not pass this time. Keep practicing!'**
  String get resultFailed;

  /// No description provided for @resultScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get resultScore;

  /// No description provided for @resultCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get resultCorrect;

  /// No description provided for @resultErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get resultErrors;

  /// No description provided for @resultTime.
  ///
  /// In en, this message translates to:
  /// **'Time Taken'**
  String get resultTime;

  /// No description provided for @resultMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get resultMinutes;

  /// No description provided for @resultSeconds.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get resultSeconds;

  /// No description provided for @resultShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show All Questions'**
  String get resultShowAll;

  /// No description provided for @resultShowErrors.
  ///
  /// In en, this message translates to:
  /// **'Show Errors Only'**
  String get resultShowErrors;

  /// No description provided for @resultYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your Answer'**
  String get resultYourAnswer;

  /// No description provided for @resultCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get resultCorrectAnswer;

  /// No description provided for @resultExplanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get resultExplanation;

  /// No description provided for @resultRetry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get resultRetry;

  /// No description provided for @resultBackToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get resultBackToDashboard;

  /// No description provided for @resultSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving results...'**
  String get resultSaving;

  /// No description provided for @resultSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save results'**
  String get resultSaveError;

  /// No description provided for @resultQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get resultQuestion;

  /// No description provided for @resultNoExplanation.
  ///
  /// In en, this message translates to:
  /// **'No explanation available'**
  String get resultNoExplanation;

  /// No description provided for @resultExcellent.
  ///
  /// In en, this message translates to:
  /// **'EXCELLENT!'**
  String get resultExcellent;

  /// No description provided for @resultGreat.
  ///
  /// In en, this message translates to:
  /// **'GREAT!'**
  String get resultGreat;

  /// No description provided for @resultGood.
  ///
  /// In en, this message translates to:
  /// **'GOOD!'**
  String get resultGood;

  /// No description provided for @resultSufficient.
  ///
  /// In en, this message translates to:
  /// **'SUFFICIENT'**
  String get resultSufficient;

  /// No description provided for @resultNeedsImprovement.
  ///
  /// In en, this message translates to:
  /// **'NEEDS IMPROVEMENT'**
  String get resultNeedsImprovement;

  /// No description provided for @resultSummary.
  ///
  /// In en, this message translates to:
  /// **'Total and Absent Summary'**
  String get resultSummary;

  /// No description provided for @resultCorrectAnswers.
  ///
  /// In en, this message translates to:
  /// **'Correct Answers'**
  String get resultCorrectAnswers;

  /// No description provided for @resultTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Total Time'**
  String get resultTotalTime;

  /// No description provided for @resultReviewQuiz.
  ///
  /// In en, this message translates to:
  /// **'REVIEW QUIZ'**
  String get resultReviewQuiz;

  /// No description provided for @resultNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get resultNew;

  /// No description provided for @resultExit.
  ///
  /// In en, this message translates to:
  /// **'EXIT'**
  String get resultExit;

  /// No description provided for @resultHome.
  ///
  /// In en, this message translates to:
  /// **'HOME'**
  String get resultHome;

  /// No description provided for @resultNewQuiz.
  ///
  /// In en, this message translates to:
  /// **'NEW QUIZ'**
  String get resultNewQuiz;

  /// No description provided for @resultReview.
  ///
  /// In en, this message translates to:
  /// **'Review Quiz'**
  String get resultReview;

  /// No description provided for @customQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom Quiz'**
  String get customQuizTitle;

  /// No description provided for @customQuizCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer!'**
  String get customQuizCorrectAnswer;

  /// No description provided for @customQuizIncorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Incorrect Answer'**
  String get customQuizIncorrectAnswer;

  /// No description provided for @customQuizShowExplanation.
  ///
  /// In en, this message translates to:
  /// **'Show Explanation'**
  String get customQuizShowExplanation;

  /// No description provided for @customQuizHideExplanation.
  ///
  /// In en, this message translates to:
  /// **'Hide Explanation'**
  String get customQuizHideExplanation;

  /// No description provided for @customQuizNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get customQuizNextQuestion;

  /// No description provided for @customQuizContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get customQuizContinue;

  /// No description provided for @customQuizNoExplanation.
  ///
  /// In en, this message translates to:
  /// **'No explanation available for this question'**
  String get customQuizNoExplanation;

  /// No description provided for @allQuizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'All Quizzes'**
  String get allQuizzesTitle;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a category to explore topics'**
  String get categoriesSubtitle;

  /// No description provided for @topicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topicsTitle;

  /// No description provided for @topicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a topic to view quizzes'**
  String get topicsSubtitle;

  /// No description provided for @quizzesTitle.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzesTitle;

  /// No description provided for @quizzesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All questions for this topic'**
  String get quizzesSubtitle;

  /// No description provided for @totalQuestions.
  ///
  /// In en, this message translates to:
  /// **'Total Questions'**
  String get totalQuestions;

  /// No description provided for @noQuestionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No questions available'**
  String get noQuestionsAvailable;

  /// No description provided for @answer.
  ///
  /// In en, this message translates to:
  /// **'Answer'**
  String get answer;

  /// No description provided for @showAnswer.
  ///
  /// In en, this message translates to:
  /// **'Show Answer'**
  String get showAnswer;

  /// No description provided for @hideAnswer.
  ///
  /// In en, this message translates to:
  /// **'Hide Answer'**
  String get hideAnswer;

  /// No description provided for @translateQuestion.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get translateQuestion;

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read Aloud'**
  String get readAloud;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get errorLoading;

  /// No description provided for @noTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'No time limit'**
  String get noTimeLimit;

  /// No description provided for @feedbackType.
  ///
  /// In en, this message translates to:
  /// **'Feedback Type'**
  String get feedbackType;

  /// No description provided for @feedbackAtEnd.
  ///
  /// In en, this message translates to:
  /// **'At end of quiz'**
  String get feedbackAtEnd;

  /// No description provided for @searchQuestions.
  ///
  /// In en, this message translates to:
  /// **'Search questions...'**
  String get searchQuestions;

  /// No description provided for @filterByAnswer.
  ///
  /// In en, this message translates to:
  /// **'Filter by Answer'**
  String get filterByAnswer;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterTrue.
  ///
  /// In en, this message translates to:
  /// **'True Only'**
  String get filterTrue;

  /// No description provided for @filterFalse.
  ///
  /// In en, this message translates to:
  /// **'False Only'**
  String get filterFalse;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noResultsForSearch.
  ///
  /// In en, this message translates to:
  /// **'No questions found for your search'**
  String get noResultsForSearch;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @explanation.
  ///
  /// In en, this message translates to:
  /// **'Explanation'**
  String get explanation;

  /// No description provided for @questionImage.
  ///
  /// In en, this message translates to:
  /// **'Question Image'**
  String get questionImage;

  /// No description provided for @examModeQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Driving License Quiz B -\nComplete Theory'**
  String get examModeQuizTitle;

  /// No description provided for @examModeReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'Ready to test yourself?'**
  String get examModeReadyMessage;

  /// No description provided for @examModeQuestions.
  ///
  /// In en, this message translates to:
  /// **'30 Questions'**
  String get examModeQuestions;

  /// No description provided for @examModeTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'20 Minutes'**
  String get examModeTimeLimit;

  /// No description provided for @examModeAllTopics.
  ///
  /// In en, this message translates to:
  /// **'All Topics'**
  String get examModeAllTopics;

  /// No description provided for @examModeMinCorrect.
  ///
  /// In en, this message translates to:
  /// **'Min. 27 Correct Answers'**
  String get examModeMinCorrect;

  /// No description provided for @examModeSimulation.
  ///
  /// In en, this message translates to:
  /// **'Official exam simulation.'**
  String get examModeSimulation;

  /// No description provided for @examModeStartButton.
  ///
  /// In en, this message translates to:
  /// **'START QUIZ'**
  String get examModeStartButton;

  /// No description provided for @topicModeSelectTopics.
  ///
  /// In en, this message translates to:
  /// **'Select Topics'**
  String get topicModeSelectTopics;

  /// No description provided for @topicModeSelectAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get topicModeSelectAll;

  /// No description provided for @topicModeDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get topicModeDone;

  /// No description provided for @topicModeNumberOfQuestions.
  ///
  /// In en, this message translates to:
  /// **'Number of Questions'**
  String get topicModeNumberOfQuestions;

  /// No description provided for @topicModeQuestions.
  ///
  /// In en, this message translates to:
  /// **'questions'**
  String get topicModeQuestions;

  /// No description provided for @topicModeCustomNumber.
  ///
  /// In en, this message translates to:
  /// **'Custom number'**
  String get topicModeCustomNumber;

  /// No description provided for @topicModeQuizConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Quiz Configuration'**
  String get topicModeQuizConfiguration;

  /// No description provided for @topicModeConfigureQuiz.
  ///
  /// In en, this message translates to:
  /// **'Configure your custom quiz'**
  String get topicModeConfigureQuiz;

  /// No description provided for @topicModeTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get topicModeTopics;

  /// No description provided for @topicModeAllTopics.
  ///
  /// In en, this message translates to:
  /// **'All topics'**
  String get topicModeAllTopics;

  /// No description provided for @topicModeSelectedTopics.
  ///
  /// In en, this message translates to:
  /// **'topics selected'**
  String get topicModeSelectedTopics;

  /// No description provided for @topicModeTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time Limit'**
  String get topicModeTimeLimit;

  /// No description provided for @topicModeMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get topicModeMinutes;

  /// No description provided for @topicModeImmediateFeedback.
  ///
  /// In en, this message translates to:
  /// **'Immediate Feedback'**
  String get topicModeImmediateFeedback;

  /// No description provided for @topicModeImmediateFeedbackDesc.
  ///
  /// In en, this message translates to:
  /// **'See correct/incorrect answer after each question'**
  String get topicModeImmediateFeedbackDesc;

  /// No description provided for @reviewErrorsSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get reviewErrorsSession;

  /// No description provided for @reviewErrorsSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get reviewErrorsSessions;

  /// No description provided for @reviewErrorsTotalCorrect.
  ///
  /// In en, this message translates to:
  /// **'Total Correct'**
  String get reviewErrorsTotalCorrect;

  /// No description provided for @reviewErrorsTotalErrors.
  ///
  /// In en, this message translates to:
  /// **'Total Errors'**
  String get reviewErrorsTotalErrors;

  /// No description provided for @reviewErrorsSessionNumber.
  ///
  /// In en, this message translates to:
  /// **'Session #'**
  String get reviewErrorsSessionNumber;

  /// No description provided for @reviewErrorsErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get reviewErrorsErrors;

  /// No description provided for @reviewErrorsViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get reviewErrorsViewDetails;

  /// No description provided for @resultReviewShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show All'**
  String get resultReviewShowAll;

  /// No description provided for @resultReviewShowErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors Only'**
  String get resultReviewShowErrors;

  /// No description provided for @resultReviewQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get resultReviewQuestion;

  /// No description provided for @resultReviewCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get resultReviewCorrect;

  /// No description provided for @resultReviewIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get resultReviewIncorrect;

  /// No description provided for @resultReviewYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your Answer'**
  String get resultReviewYourAnswer;

  /// No description provided for @resultReviewCorrectAnswer.
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get resultReviewCorrectAnswer;

  /// No description provided for @resultReviewTryAgain.
  ///
  /// In en, this message translates to:
  /// **'TRY AGAIN'**
  String get resultReviewTryAgain;

  /// No description provided for @resultReviewBackToHome.
  ///
  /// In en, this message translates to:
  /// **'BACK TO HOME'**
  String get resultReviewBackToHome;

  /// No description provided for @videoLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Library'**
  String get videoLibraryTitle;

  /// No description provided for @videoLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading videos...'**
  String get videoLoading;

  /// No description provided for @videoRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get videoRefresh;

  /// No description provided for @videoErrorOffline.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get videoErrorOffline;

  /// No description provided for @videoErrorOfflineDesc.
  ///
  /// In en, this message translates to:
  /// **'Videos require an internet connection. Please check your connection and try again.'**
  String get videoErrorOfflineDesc;

  /// No description provided for @videoErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Failed to Load Videos'**
  String get videoErrorLoading;

  /// No description provided for @videoErrorLoadingDesc.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while loading the video library. Please try again.'**
  String get videoErrorLoadingDesc;

  /// No description provided for @videoRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get videoRetry;

  /// No description provided for @videoEmpty.
  ///
  /// In en, this message translates to:
  /// **'No videos available yet'**
  String get videoEmpty;

  /// No description provided for @videoPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Player'**
  String get videoPlayerTitle;

  /// No description provided for @videoInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid video URL'**
  String get videoInvalidUrl;

  /// No description provided for @videoTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Tips'**
  String get videoTipsTitle;

  /// No description provided for @videoTipFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Tap the fullscreen button to watch in landscape mode'**
  String get videoTipFullscreen;

  /// No description provided for @videoTipSpeed.
  ///
  /// In en, this message translates to:
  /// **'Adjust playback speed using the speed button'**
  String get videoTipSpeed;

  /// No description provided for @videoTipCaptions.
  ///
  /// In en, this message translates to:
  /// **'Italian captions are available for most videos'**
  String get videoTipCaptions;

  /// No description provided for @liveClassesTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Classes'**
  String get liveClassesTitle;

  /// No description provided for @liveClassesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No live classes available yet'**
  String get liveClassesEmpty;

  /// No description provided for @liveClassesDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Class Date'**
  String get liveClassesDateLabel;

  /// No description provided for @profileOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode - Profile data may be outdated. Dark mode and language changes work normally.'**
  String get profileOfflineMode;

  /// No description provided for @profileOfflineError.
  ///
  /// In en, this message translates to:
  /// **'Cannot save profile changes while offline. Changes to dark mode and language are saved locally.'**
  String get profileOfflineError;

  /// No description provided for @profileOfflineSettingsNote.
  ///
  /// In en, this message translates to:
  /// **'Dark mode and language changes work offline and are saved on your device.'**
  String get profileOfflineSettingsNote;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsDarkModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Switch between light and dark theme'**
  String get settingsDarkModeDesc;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get settingsNotificationsEnable;

  /// No description provided for @settingsNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive reminders and study updates'**
  String get settingsNotificationsDesc;

  /// No description provided for @settingsQuizSettings.
  ///
  /// In en, this message translates to:
  /// **'Quiz Settings'**
  String get settingsQuizSettings;

  /// No description provided for @settingsSoundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get settingsSoundEffects;

  /// No description provided for @settingsSoundEffectsDesc.
  ///
  /// In en, this message translates to:
  /// **'Play sounds for correct/incorrect answers'**
  String get settingsSoundEffectsDesc;

  /// No description provided for @settingsVibration.
  ///
  /// In en, this message translates to:
  /// **'Vibration'**
  String get settingsVibration;

  /// No description provided for @settingsVibrationDesc.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback on button press'**
  String get settingsVibrationDesc;

  /// No description provided for @settingsDataStorage.
  ///
  /// In en, this message translates to:
  /// **'Data & Storage'**
  String get settingsDataStorage;

  /// No description provided for @settingsClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get settingsClearCache;

  /// No description provided for @settingsClearCacheDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove cached data to free up space'**
  String get settingsClearCacheDesc;

  /// No description provided for @settingsClearCacheTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache?'**
  String get settingsClearCacheTitle;

  /// No description provided for @settingsClearCacheMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove all cached data. Your progress will not be affected.'**
  String get settingsClearCacheMessage;

  /// No description provided for @settingsCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared successfully'**
  String get settingsCacheCleared;

  /// No description provided for @settingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSupport;

  /// No description provided for @settingsHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get settingsHelpCenter;

  /// No description provided for @settingsHelpCenterDesc.
  ///
  /// In en, this message translates to:
  /// **'Get help and FAQs'**
  String get settingsHelpCenterDesc;

  /// No description provided for @settingsReportBug.
  ///
  /// In en, this message translates to:
  /// **'Report a Bug'**
  String get settingsReportBug;

  /// No description provided for @settingsReportBugDesc.
  ///
  /// In en, this message translates to:
  /// **'Let us know about issues'**
  String get settingsReportBugDesc;

  /// No description provided for @settingsRateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get settingsRateApp;

  /// No description provided for @settingsRateAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Share your experience'**
  String get settingsRateAppDesc;

  /// No description provided for @settingsRateAppSoon.
  ///
  /// In en, this message translates to:
  /// **'App Store rating coming soon!'**
  String get settingsRateAppSoon;

  /// No description provided for @settingsShareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get settingsShareApp;

  /// No description provided for @settingsShareAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Invite friends to study together'**
  String get settingsShareAppDesc;

  /// No description provided for @settingsLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settingsLegal;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacyPolicyContent.
  ///
  /// In en, this message translates to:
  /// **'Your privacy is important to us.\n\nData Collection:\nWe collect minimal personal information necessary to provide our services, including your email, name, and quiz progress.\n\nData Usage:\nYour data is used solely to provide and improve the app experience. We do not sell your data to third parties.\n\nData Storage:\nAll data is securely stored using industry-standard encryption and security practices.\n\nYour Rights:\nYou have the right to access, modify, or delete your personal data at any time by contacting us.\n\nContact:\nFor privacy-related inquiries, contact us at privacy@deshbanglapatente.com'**
  String get settingsPrivacyPolicyContent;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsTermsOfServiceContent.
  ///
  /// In en, this message translates to:
  /// **'By using Desh Bangla Patente, you agree to these terms.\n\nAcceptable Use:\nUse the app only for personal study purposes. Do not attempt to cheat or misuse the platform.\n\nAccount Responsibility:\nYou are responsible for maintaining the security of your account credentials.\n\nContent Accuracy:\nWhile we strive for accuracy, quiz questions are for practice only. Always refer to official sources for the actual exam.\n\nService Availability:\nWe aim to provide uninterrupted service but cannot guarantee 100% uptime.\n\nChanges to Terms:\nWe may update these terms. Continued use constitutes acceptance of changes.\n\nContact:\nFor questions, contact us at support@deshbanglapatente.com'**
  String get settingsTermsOfServiceContent;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsAboutContent.
  ///
  /// In en, this message translates to:
  /// **'Desh Bangla Patente helps you prepare for the Italian driving license exam (Patente B) with practice quizzes, video tutorials, and progress tracking.\n\nDeveloped with ❤️ for the Bangladeshi community in Italy.'**
  String get settingsAboutContent;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Disclaimer'**
  String get settingsDisclaimerTitle;

  /// No description provided for @settingsDisclaimerContent.
  ///
  /// In en, this message translates to:
  /// **'This app is not a government entity. Quizzes are based on public information from mit.gov.it.'**
  String get settingsDisclaimerContent;

  /// No description provided for @settingsClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get settingsClose;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @settingsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get settingsConfirm;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @noInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Internet Connection'**
  String get noInternetTitle;

  /// No description provided for @noInternetDescription.
  ///
  /// In en, this message translates to:
  /// **'This app requires an internet connection to work. Please check your connection and try again.'**
  String get noInternetDescription;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get retry;

  /// No description provided for @adminSecurityCheck.
  ///
  /// In en, this message translates to:
  /// **'Admin Security Check'**
  String get adminSecurityCheck;

  /// No description provided for @adminEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your 6-digit PIN'**
  String get adminEnterPin;

  /// No description provided for @adminInvalidPin.
  ///
  /// In en, this message translates to:
  /// **'Invalid PIN. Please try again.'**
  String get adminInvalidPin;

  /// No description provided for @adminUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsers;

  /// No description provided for @adminQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get adminQuizzes;

  /// No description provided for @adminTheory.
  ///
  /// In en, this message translates to:
  /// **'Theory'**
  String get adminTheory;

  /// No description provided for @adminProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get adminProfile;

  /// No description provided for @adminRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get adminRole;

  /// No description provided for @adminMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get adminMemberSince;

  /// No description provided for @adminQuickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Statistics'**
  String get adminQuickStats;

  /// No description provided for @adminUserManagement.
  ///
  /// In en, this message translates to:
  /// **'User Management'**
  String get adminUserManagement;

  /// No description provided for @adminSearchUsers.
  ///
  /// In en, this message translates to:
  /// **'Search users...'**
  String get adminSearchUsers;

  /// No description provided for @adminFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// No description provided for @adminFilterPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminFilterPending;

  /// No description provided for @adminFilterVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get adminFilterVerified;

  /// No description provided for @adminTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get adminTotalUsers;

  /// No description provided for @adminNoUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get adminNoUsersFound;

  /// No description provided for @adminUnknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get adminUnknownUser;

  /// No description provided for @adminVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get adminVerified;

  /// No description provided for @adminPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get adminPending;

  /// No description provided for @adminUserVerified.
  ///
  /// In en, this message translates to:
  /// **'User verified successfully'**
  String get adminUserVerified;

  /// No description provided for @adminUserUnverified.
  ///
  /// In en, this message translates to:
  /// **'User verification removed'**
  String get adminUserUnverified;

  /// No description provided for @adminErrorUpdating.
  ///
  /// In en, this message translates to:
  /// **'Error updating user'**
  String get adminErrorUpdating;

  /// No description provided for @adminQuizManagement.
  ///
  /// In en, this message translates to:
  /// **'Quiz Management'**
  String get adminQuizManagement;

  /// No description provided for @adminAddQuestion.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get adminAddQuestion;

  /// No description provided for @adminEditQuestion.
  ///
  /// In en, this message translates to:
  /// **'Edit Question'**
  String get adminEditQuestion;

  /// No description provided for @adminDeleteQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete Question'**
  String get adminDeleteQuestion;

  /// No description provided for @adminDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item? This action cannot be undone.'**
  String get adminDeleteConfirm;

  /// No description provided for @adminQuestionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Question deleted successfully'**
  String get adminQuestionDeleted;

  /// No description provided for @adminQuestionSaved.
  ///
  /// In en, this message translates to:
  /// **'Question saved successfully'**
  String get adminQuestionSaved;

  /// No description provided for @adminErrorSaving.
  ///
  /// In en, this message translates to:
  /// **'Error saving changes'**
  String get adminErrorSaving;

  /// No description provided for @adminSubtopic.
  ///
  /// In en, this message translates to:
  /// **'Subtopic'**
  String get adminSubtopic;

  /// No description provided for @adminSelectSubtopic.
  ///
  /// In en, this message translates to:
  /// **'Select a subtopic'**
  String get adminSelectSubtopic;

  /// No description provided for @adminQuestionTextIt.
  ///
  /// In en, this message translates to:
  /// **'Question Text (Italian)'**
  String get adminQuestionTextIt;

  /// No description provided for @adminQuestionTextEn.
  ///
  /// In en, this message translates to:
  /// **'Question Text (English)'**
  String get adminQuestionTextEn;

  /// No description provided for @adminQuestionTextBn.
  ///
  /// In en, this message translates to:
  /// **'Question Text (Bangla)'**
  String get adminQuestionTextBn;

  /// No description provided for @adminEnterQuestionIt.
  ///
  /// In en, this message translates to:
  /// **'Enter question in Italian...'**
  String get adminEnterQuestionIt;

  /// No description provided for @adminEnterQuestionEn.
  ///
  /// In en, this message translates to:
  /// **'Enter question in English (optional)...'**
  String get adminEnterQuestionEn;

  /// No description provided for @adminEnterQuestionBn.
  ///
  /// In en, this message translates to:
  /// **'Enter question in Bangla (optional)...'**
  String get adminEnterQuestionBn;

  /// No description provided for @adminFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get adminFieldRequired;

  /// No description provided for @adminQuestionImage.
  ///
  /// In en, this message translates to:
  /// **'Question Image'**
  String get adminQuestionImage;

  /// No description provided for @adminUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get adminUploadImage;

  /// No description provided for @adminChangeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get adminChangeImage;

  /// No description provided for @adminExplanations.
  ///
  /// In en, this message translates to:
  /// **'Explanations (Optional)'**
  String get adminExplanations;

  /// No description provided for @adminTheoryManagement.
  ///
  /// In en, this message translates to:
  /// **'Theory Management'**
  String get adminTheoryManagement;

  /// No description provided for @adminAddTheoryCard.
  ///
  /// In en, this message translates to:
  /// **'Add Theory Card'**
  String get adminAddTheoryCard;

  /// No description provided for @adminEditTheoryCard.
  ///
  /// In en, this message translates to:
  /// **'Edit Theory Card'**
  String get adminEditTheoryCard;

  /// No description provided for @adminDeleteTheoryCard.
  ///
  /// In en, this message translates to:
  /// **'Delete Theory Card'**
  String get adminDeleteTheoryCard;

  /// No description provided for @adminTheoryCards.
  ///
  /// In en, this message translates to:
  /// **'Theory Cards'**
  String get adminTheoryCards;

  /// No description provided for @adminNoTheoryCards.
  ///
  /// In en, this message translates to:
  /// **'No theory cards found'**
  String get adminNoTheoryCards;

  /// No description provided for @adminTheoryCardDeleted.
  ///
  /// In en, this message translates to:
  /// **'Theory card deleted successfully'**
  String get adminTheoryCardDeleted;

  /// No description provided for @adminTheoryCardSaved.
  ///
  /// In en, this message translates to:
  /// **'Theory card saved successfully'**
  String get adminTheoryCardSaved;

  /// No description provided for @adminSearchTheory.
  ///
  /// In en, this message translates to:
  /// **'Search theory cards...'**
  String get adminSearchTheory;

  /// No description provided for @adminChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get adminChapter;

  /// No description provided for @adminSelectChapter.
  ///
  /// In en, this message translates to:
  /// **'Select a chapter'**
  String get adminSelectChapter;

  /// No description provided for @adminDisplayOrder.
  ///
  /// In en, this message translates to:
  /// **'Display Order'**
  String get adminDisplayOrder;

  /// No description provided for @adminTitleIt.
  ///
  /// In en, this message translates to:
  /// **'Title (Italian)'**
  String get adminTitleIt;

  /// No description provided for @adminTitleEn.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get adminTitleEn;

  /// No description provided for @adminTitleBn.
  ///
  /// In en, this message translates to:
  /// **'Title (Bangla)'**
  String get adminTitleBn;

  /// No description provided for @adminTextIt.
  ///
  /// In en, this message translates to:
  /// **'Content (Italian)'**
  String get adminTextIt;

  /// No description provided for @adminTextEn.
  ///
  /// In en, this message translates to:
  /// **'Content (English)'**
  String get adminTextEn;

  /// No description provided for @adminTextBn.
  ///
  /// In en, this message translates to:
  /// **'Content (Bangla)'**
  String get adminTextBn;

  /// No description provided for @adminEnterTitleIt.
  ///
  /// In en, this message translates to:
  /// **'Enter title in Italian...'**
  String get adminEnterTitleIt;

  /// No description provided for @adminEnterTextIt.
  ///
  /// In en, this message translates to:
  /// **'Enter content in Italian...'**
  String get adminEnterTextIt;

  /// No description provided for @adminEnglishContent.
  ///
  /// In en, this message translates to:
  /// **'English Content'**
  String get adminEnglishContent;

  /// No description provided for @adminBanglaContent.
  ///
  /// In en, this message translates to:
  /// **'Bangla Content'**
  String get adminBanglaContent;

  /// No description provided for @adminCardImage.
  ///
  /// In en, this message translates to:
  /// **'Card Image'**
  String get adminCardImage;

  /// No description provided for @pendingVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification Pending'**
  String get pendingVerificationTitle;

  /// No description provided for @pendingVerificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account is awaiting admin approval.'**
  String get pendingVerificationMessage;

  /// No description provided for @pendingVerificationSubMessage.
  ///
  /// In en, this message translates to:
  /// **'An administrator will review your account shortly. You will get full access once verified.'**
  String get pendingVerificationSubMessage;

  /// No description provided for @pendingVerificationRefresh.
  ///
  /// In en, this message translates to:
  /// **'Check Status'**
  String get pendingVerificationRefresh;

  /// No description provided for @adminSearchFilters.
  ///
  /// In en, this message translates to:
  /// **'Search & Filters'**
  String get adminSearchFilters;

  /// No description provided for @adminEnterKeyword.
  ///
  /// In en, this message translates to:
  /// **'Enter keyword...'**
  String get adminEnterKeyword;

  /// No description provided for @adminFilterByTopic.
  ///
  /// In en, this message translates to:
  /// **'Filter by Topic'**
  String get adminFilterByTopic;

  /// No description provided for @adminFilterBySubtopic.
  ///
  /// In en, this message translates to:
  /// **'Filter by Subtopic'**
  String get adminFilterBySubtopic;

  /// No description provided for @adminFilterByChapter.
  ///
  /// In en, this message translates to:
  /// **'Filter by Chapter'**
  String get adminFilterByChapter;

  /// No description provided for @adminClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get adminClearFilters;

  /// No description provided for @adminApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get adminApplyFilters;

  /// No description provided for @adminVerificationStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification Status'**
  String get adminVerificationStatus;

  /// No description provided for @adminAccountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get adminAccountInfo;

  /// No description provided for @adminEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get adminEmail;

  /// No description provided for @adminLicenseType.
  ///
  /// In en, this message translates to:
  /// **'License Type'**
  String get adminLicenseType;

  /// No description provided for @adminJoinedDate.
  ///
  /// In en, this message translates to:
  /// **'Joined Date'**
  String get adminJoinedDate;

  /// No description provided for @adminProgressStats.
  ///
  /// In en, this message translates to:
  /// **'Progress Statistics'**
  String get adminProgressStats;

  /// No description provided for @adminXP.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get adminXP;

  /// No description provided for @adminDailyStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily Streak'**
  String get adminDailyStreak;

  /// No description provided for @adminDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get adminDays;

  /// No description provided for @adminTotalQuizzes.
  ///
  /// In en, this message translates to:
  /// **'Total Quizzes'**
  String get adminTotalQuizzes;

  /// No description provided for @adminAverageScore.
  ///
  /// In en, this message translates to:
  /// **'Average Score'**
  String get adminAverageScore;

  /// No description provided for @adminLastStudy.
  ///
  /// In en, this message translates to:
  /// **'Last Study Date'**
  String get adminLastStudy;

  /// No description provided for @adminSystemInfo.
  ///
  /// In en, this message translates to:
  /// **'System Information'**
  String get adminSystemInfo;

  /// No description provided for @adminLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get adminLastUpdated;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboardTitle;

  /// No description provided for @adminDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage all app content'**
  String get adminDashboardSubtitle;

  /// No description provided for @adminUserManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage users and verification'**
  String get adminUserManagementDesc;

  /// No description provided for @adminQuizManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage categories, topics and questions'**
  String get adminQuizManagementDesc;

  /// No description provided for @adminTheoryManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage theory chapters and cards'**
  String get adminTheoryManagementDesc;

  /// No description provided for @adminVideoManagementDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage video categories and videos'**
  String get adminVideoManagementDesc;

  /// No description provided for @adminVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get adminVideos;

  /// No description provided for @adminQuizCategories.
  ///
  /// In en, this message translates to:
  /// **'Quiz Categories'**
  String get adminQuizCategories;

  /// No description provided for @adminTheoryChapters.
  ///
  /// In en, this message translates to:
  /// **'Theory Chapters'**
  String get adminTheoryChapters;

  /// No description provided for @adminVideoCategories.
  ///
  /// In en, this message translates to:
  /// **'Video Categories'**
  String get adminVideoCategories;

  /// No description provided for @adminAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get adminAddCategory;

  /// No description provided for @adminEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get adminEditCategory;

  /// No description provided for @adminDeleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get adminDeleteCategory;

  /// No description provided for @adminAddTopic.
  ///
  /// In en, this message translates to:
  /// **'Add Topic'**
  String get adminAddTopic;

  /// No description provided for @adminEditTopic.
  ///
  /// In en, this message translates to:
  /// **'Edit Topic'**
  String get adminEditTopic;

  /// No description provided for @adminDeleteTopic.
  ///
  /// In en, this message translates to:
  /// **'Delete Topic'**
  String get adminDeleteTopic;

  /// No description provided for @adminAddSubtopic.
  ///
  /// In en, this message translates to:
  /// **'Add Subtopic'**
  String get adminAddSubtopic;

  /// No description provided for @adminEditSubtopic.
  ///
  /// In en, this message translates to:
  /// **'Edit Subtopic'**
  String get adminEditSubtopic;

  /// No description provided for @adminDeleteSubtopic.
  ///
  /// In en, this message translates to:
  /// **'Delete Subtopic'**
  String get adminDeleteSubtopic;

  /// No description provided for @adminAddChapter.
  ///
  /// In en, this message translates to:
  /// **'Add Chapter'**
  String get adminAddChapter;

  /// No description provided for @adminEditChapter.
  ///
  /// In en, this message translates to:
  /// **'Edit Chapter'**
  String get adminEditChapter;

  /// No description provided for @adminDeleteChapter.
  ///
  /// In en, this message translates to:
  /// **'Delete Chapter'**
  String get adminDeleteChapter;

  /// No description provided for @adminAddVideoCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get adminAddVideoCategory;

  /// No description provided for @adminEditVideoCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get adminEditVideoCategory;

  /// No description provided for @adminDeleteVideoCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get adminDeleteVideoCategory;

  /// No description provided for @adminAddVideo.
  ///
  /// In en, this message translates to:
  /// **'Add Video'**
  String get adminAddVideo;

  /// No description provided for @adminEditVideo.
  ///
  /// In en, this message translates to:
  /// **'Edit Video'**
  String get adminEditVideo;

  /// No description provided for @adminDeleteVideo.
  ///
  /// In en, this message translates to:
  /// **'Delete Video'**
  String get adminDeleteVideo;

  /// No description provided for @adminNameIt.
  ///
  /// In en, this message translates to:
  /// **'Name (Italian)'**
  String get adminNameIt;

  /// No description provided for @adminNameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get adminNameEn;

  /// No description provided for @adminNameBn.
  ///
  /// In en, this message translates to:
  /// **'Name (Bangla)'**
  String get adminNameBn;

  /// No description provided for @adminColorHex.
  ///
  /// In en, this message translates to:
  /// **'Color (Hex)'**
  String get adminColorHex;

  /// No description provided for @adminImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get adminImageUrl;

  /// No description provided for @adminNoCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories found'**
  String get adminNoCategories;

  /// No description provided for @adminNoTopics.
  ///
  /// In en, this message translates to:
  /// **'No topics found'**
  String get adminNoTopics;

  /// No description provided for @adminNoSubtopics.
  ///
  /// In en, this message translates to:
  /// **'No subtopics found'**
  String get adminNoSubtopics;

  /// No description provided for @adminNoChapters.
  ///
  /// In en, this message translates to:
  /// **'No chapters found'**
  String get adminNoChapters;

  /// No description provided for @adminNoVideoCategories.
  ///
  /// In en, this message translates to:
  /// **'No video categories found'**
  String get adminNoVideoCategories;

  /// No description provided for @adminNoVideos.
  ///
  /// In en, this message translates to:
  /// **'No videos found'**
  String get adminNoVideos;

  /// No description provided for @adminSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get adminSavedSuccessfully;

  /// No description provided for @adminDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Deleted successfully'**
  String get adminDeletedSuccessfully;

  /// No description provided for @adminEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminEdit;

  /// No description provided for @adminDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get adminDelete;

  /// No description provided for @adminTopics.
  ///
  /// In en, this message translates to:
  /// **'Topics'**
  String get adminTopics;

  /// No description provided for @adminSubtopics.
  ///
  /// In en, this message translates to:
  /// **'Subtopics'**
  String get adminSubtopics;

  /// No description provided for @adminQuestions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get adminQuestions;

  /// No description provided for @adminCards.
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get adminCards;

  /// No description provided for @adminSearchQuestions.
  ///
  /// In en, this message translates to:
  /// **'Search questions...'**
  String get adminSearchQuestions;

  /// No description provided for @adminSearchVideos.
  ///
  /// In en, this message translates to:
  /// **'Search videos...'**
  String get adminSearchVideos;

  /// No description provided for @adminNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get adminNameRequired;

  /// No description provided for @adminTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get adminTitleRequired;

  /// No description provided for @adminYoutubeUrl.
  ///
  /// In en, this message translates to:
  /// **'YouTube URL'**
  String get adminYoutubeUrl;

  /// No description provided for @adminYoutubeUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'YouTube URL is required'**
  String get adminYoutubeUrlRequired;

  /// No description provided for @adminDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get adminDurationMinutes;

  /// No description provided for @adminThumbnailUrl.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail URL'**
  String get adminThumbnailUrl;

  /// No description provided for @adminThumbnailHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use YouTube thumbnail'**
  String get adminThumbnailHelper;

  /// No description provided for @adminVideoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Video deleted successfully'**
  String get adminVideoDeleted;

  /// No description provided for @adminVideoManagement.
  ///
  /// In en, this message translates to:
  /// **'Video Management'**
  String get adminVideoManagement;

  /// No description provided for @adminFilterLiveOnly.
  ///
  /// In en, this message translates to:
  /// **'Live Classes Only'**
  String get adminFilterLiveOnly;

  /// No description provided for @adminFilterChapterOnly.
  ///
  /// In en, this message translates to:
  /// **'Chapter Classes Only'**
  String get adminFilterChapterOnly;

  /// No description provided for @adminSortByDate.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get adminSortByDate;

  /// No description provided for @adminSortByChapter.
  ///
  /// In en, this message translates to:
  /// **'Sort by Chapter'**
  String get adminSortByChapter;

  /// No description provided for @adminTagLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get adminTagLive;

  /// No description provided for @adminTagChapter.
  ///
  /// In en, this message translates to:
  /// **'CHAPTER {number}'**
  String adminTagChapter(int number);

  /// No description provided for @adminLiveClass.
  ///
  /// In en, this message translates to:
  /// **'Live Class'**
  String get adminLiveClass;

  /// No description provided for @adminChapterClass.
  ///
  /// In en, this message translates to:
  /// **'Chapter Class'**
  String get adminChapterClass;

  /// No description provided for @adminUploadTypeQuestion.
  ///
  /// In en, this message translates to:
  /// **'What type of video would you like to upload?'**
  String get adminUploadTypeQuestion;

  /// No description provided for @adminUploadRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular Class Video'**
  String get adminUploadRegular;

  /// No description provided for @adminUploadLive.
  ///
  /// In en, this message translates to:
  /// **'Live Class Recording'**
  String get adminUploadLive;

  /// No description provided for @adminClassType.
  ///
  /// In en, this message translates to:
  /// **'Class Type'**
  String get adminClassType;

  /// No description provided for @adminNormalClass.
  ///
  /// In en, this message translates to:
  /// **'Normal Class'**
  String get adminNormalClass;

  /// No description provided for @adminClassDate.
  ///
  /// In en, this message translates to:
  /// **'Class Date'**
  String get adminClassDate;

  /// No description provided for @adminTheoryChapter.
  ///
  /// In en, this message translates to:
  /// **'Theory Chapter'**
  String get adminTheoryChapter;

  /// No description provided for @adminSelectChapterRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a theory chapter'**
  String get adminSelectChapterRequired;

  /// No description provided for @adminDeleteCategoryWarning.
  ///
  /// In en, this message translates to:
  /// **'This category has {count} items. Deleting it will also delete all items. Continue?'**
  String adminDeleteCategoryWarning(int count);

  /// No description provided for @theoryCardListTitle.
  ///
  /// In en, this message translates to:
  /// **'Theory Cards'**
  String get theoryCardListTitle;

  /// No description provided for @theoryCardListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No theory cards available'**
  String get theoryCardListEmpty;

  /// No description provided for @theoryCardListErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading theory cards'**
  String get theoryCardListErrorLoading;

  /// No description provided for @theoryCardListRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get theoryCardListRetry;

  /// No description provided for @theoryCardDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Theory Card'**
  String get theoryCardDetailTitle;

  /// No description provided for @theoryCardDetailChapter.
  ///
  /// In en, this message translates to:
  /// **'Chapter'**
  String get theoryCardDetailChapter;

  /// No description provided for @theoryCardDetailViewQuizzes.
  ///
  /// In en, this message translates to:
  /// **'View Related Quizzes'**
  String get theoryCardDetailViewQuizzes;

  /// No description provided for @theoryCardQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get theoryCardQuizTitle;

  /// No description provided for @theoryCardQuizResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get theoryCardQuizResults;

  /// No description provided for @theoryCardQuizEmpty.
  ///
  /// In en, this message translates to:
  /// **'No quiz questions available for this theory card'**
  String get theoryCardQuizEmpty;

  /// No description provided for @theoryCardQuizErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading quiz questions'**
  String get theoryCardQuizErrorLoading;

  /// No description provided for @ttsInstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Install Text-to-Speech'**
  String get ttsInstallTitle;

  /// No description provided for @ttsLanguageNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Language not installed:'**
  String get ttsLanguageNotInstalled;

  /// No description provided for @ttsInstallPrompt.
  ///
  /// In en, this message translates to:
  /// **'Would you like to install text-to-speech now?'**
  String get ttsInstallPrompt;

  /// No description provided for @ttsLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get ttsLater;

  /// No description provided for @ttsInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get ttsInstall;

  /// No description provided for @quizResultsPassed.
  ///
  /// In en, this message translates to:
  /// **'Passed!'**
  String get quizResultsPassed;

  /// No description provided for @quizResultsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get quizResultsFailed;

  /// No description provided for @quizResultsCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get quizResultsCorrect;

  /// No description provided for @quizResultsErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get quizResultsErrors;

  /// No description provided for @quizResultsReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Questions'**
  String get quizResultsReviewTitle;

  /// No description provided for @quizQuestionNumber.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get quizQuestionNumber;

  /// No description provided for @quizYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Your Answer'**
  String get quizYourAnswer;

  /// No description provided for @quizResultsBackToTheory.
  ///
  /// In en, this message translates to:
  /// **'Back to Theory'**
  String get quizResultsBackToTheory;

  /// No description provided for @vocabTitle.
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get vocabTitle;

  /// No description provided for @vocabWords.
  ///
  /// In en, this message translates to:
  /// **'words'**
  String get vocabWords;

  /// No description provided for @vocabSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search words...'**
  String get vocabSearchHint;

  /// No description provided for @vocabAllWords.
  ///
  /// In en, this message translates to:
  /// **'All Words'**
  String get vocabAllWords;

  /// No description provided for @vocabStarred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get vocabStarred;

  /// No description provided for @vocabNoResults.
  ///
  /// In en, this message translates to:
  /// **'No words found'**
  String get vocabNoResults;

  /// No description provided for @vocabNoStarred.
  ///
  /// In en, this message translates to:
  /// **'No starred words yet.\nTap ★ on any word to save it.'**
  String get vocabNoStarred;

  /// No description provided for @vocabSeeQuestions.
  ///
  /// In en, this message translates to:
  /// **'See Exam Questions'**
  String get vocabSeeQuestions;

  /// No description provided for @vocabLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading dictionary...'**
  String get vocabLoading;

  /// No description provided for @vocabError.
  ///
  /// In en, this message translates to:
  /// **'Error loading dictionary'**
  String get vocabError;

  /// No description provided for @vocabRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get vocabRetry;

  /// No description provided for @glossaryViewDictionary.
  ///
  /// In en, this message translates to:
  /// **'View in Dictionary'**
  String get glossaryViewDictionary;

  /// No description provided for @wordQuestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Questions containing'**
  String get wordQuestionsTitle;

  /// No description provided for @wordQuestionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No exam questions found for this word'**
  String get wordQuestionsEmpty;

  /// No description provided for @wordQuestionsLoading.
  ///
  /// In en, this message translates to:
  /// **'Searching questions...'**
  String get wordQuestionsLoading;

  /// No description provided for @wordQuestionsFound.
  ///
  /// In en, this message translates to:
  /// **'questions found'**
  String get wordQuestionsFound;

  /// No description provided for @homeworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get homeworkTitle;

  /// No description provided for @homeworkActiveNow.
  ///
  /// In en, this message translates to:
  /// **'Active Now'**
  String get homeworkActiveNow;

  /// No description provided for @homeworkUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get homeworkUpcoming;

  /// No description provided for @homeworkCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get homeworkCompleted;

  /// No description provided for @homeworkStart.
  ///
  /// In en, this message translates to:
  /// **'Start Homework'**
  String get homeworkStart;

  /// No description provided for @homeworkViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get homeworkViewDetails;

  /// No description provided for @homeworkViewResult.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get homeworkViewResult;

  /// No description provided for @homeworkLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get homeworkLeaderboard;

  /// No description provided for @homeworkRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get homeworkRetry;

  /// No description provided for @homeworkTimeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time remaining'**
  String get homeworkTimeRemaining;

  /// No description provided for @homeworkStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in'**
  String get homeworkStartsIn;

  /// No description provided for @homeworkSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get homeworkSubmitted;

  /// No description provided for @homeworkStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get homeworkStatus;

  /// No description provided for @homeworkQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get homeworkQuestionCount;

  /// No description provided for @homeworkTimeLimit.
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get homeworkTimeLimit;

  /// No description provided for @homeworkStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get homeworkStartDate;

  /// No description provided for @homeworkEndDate.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get homeworkEndDate;

  /// No description provided for @homeworkRetryAllowed.
  ///
  /// In en, this message translates to:
  /// **'Retry allowed'**
  String get homeworkRetryAllowed;

  /// No description provided for @homeworkYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get homeworkYes;

  /// No description provided for @homeworkNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get homeworkNo;

  /// No description provided for @homeworkNoItems.
  ///
  /// In en, this message translates to:
  /// **'No homework available.'**
  String get homeworkNoItems;

  /// No description provided for @homeworkStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Homework'**
  String get homeworkStartLabel;

  /// No description provided for @homeworkStartWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Start'**
  String get homeworkStartWarningTitle;

  /// No description provided for @homeworkStartWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This homework can only be attempted once. Are you sure you want to start?'**
  String get homeworkStartWarningMessage;

  /// No description provided for @homeworkFailedToStart.
  ///
  /// In en, this message translates to:
  /// **'Failed to start homework'**
  String get homeworkFailedToStart;

  /// No description provided for @homeworkBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to Homework'**
  String get homeworkBackToList;

  /// No description provided for @homeworkReviewAnswers.
  ///
  /// In en, this message translates to:
  /// **'Review Answers'**
  String get homeworkReviewAnswers;

  /// No description provided for @homeworkRank.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get homeworkRank;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
