# Patente B Quiz App - AI Agent Instructions

## Project Overview
This is a Flutter app for Italian driving license (Patente B) exam preparation. The app simulates official exam conditions while providing intelligent learning analytics, theory study materials, and driving school integration.

**Multi-Language Support:** The app supports 3 languages - Italian (default), English, and Bangla (বাংলা). Language selection happens on first launch via an intuitive UI.

## Architecture & Structure

### App Phases (Development Roadmap)
1. **Onboarding** (3 screens): Splash → Auth (Google/Apple) → Setup Wizard (license type + optional school code)
2. **Dashboard** (1 screen): Circular progress "Exam Readiness" + 3 action cards (Exam Mode, Topic Mode, Review Errors) + gamification (streak, level)
3. **Quiz Core** (2 screens): Question interface with timer + Results/Review with error filtering
4. **Theory** (2 screens): 25 official chapters list + Reader view with embedded video
5. **Analytics** (1 screen): Line chart (30-day errors) + Topic heatmap (clickable to launch focused quizzes)
6. **Driving School** (2 screens): WhatsApp-style chat + Booking calendar

### Key Technical Requirements
- **State Management**: Quiz answers, timer, navigation between 30 questions (swipe support)
- **Localization**: Flutter's official i18n with ARB files (Italian, English, Bangla)
- **Image Handling**: Lazy loading for hundreds of high-res images; fullscreen zoom on tap
- **Real-time Calculations**: Exam readiness percentage, error tracking per topic
- **Dark Mode**: Essential (students study at night)
- **Haptic Feedback**: Button presses, especially primary actions

## Development Conventions

```
lib/
  features/
    auth/screens/   # Authentication screens (splash, setup_wizard, auth)
  screens/          # Feature screens (dashboard/, quiz/, theory/, stats/, school/)
  widgets/          # Reusable UI components (progress_ring.dart, answer_button.dart, quiz_timer.dart)
  models/           # Data models (question.dart, quiz_session.dart, user_profile.dart, topic.dart)
  services/         # Business logic (quiz_service.dart, auth_service.dart, analytics_service.dart)
  providers/        # State management (language_provider.dart, etc.)
  utils/            # Helpers (constants.dart, theme.dart, localization_helper.dart)
  l10n/             # Localization files (app_en.arb, app_it.arb, app_bn.arb)
  assets/
    images/         # Question images (organize by topic ID)
    videos/         # Optional local theory videos
``` videos/         # Optional local theory videos
```

### Quiz Interface Patterns
- **Two Modes**: Training (instant feedback with green/red flash) vs Exam (no feedback until end)
- **Timer**: CountdownTimer widget, 20:00 minutes, visible at top
- **Navigation**: PageView with physics for swipe left/right to skip questions
- **Answer State**: Store as `Map<int, bool>` where key = question index, value = user answer
- **Image Zoom**: Use `PhotoView` package or custom Hero animation for fullscreen

### UX/UI Specifications
- **Colors**: Primary = Exam Mode button color, Green = "Vero" (True), Red = "Falso" (False)
- **Typography**: Large, readable fonts (min 18sp for question text)
- **Buttons**: Minimum 56dp height for answer buttons (Vero/Falso)
- **Guest Mode**: Allow one quiz without login (store attempt count in shared_preferences)

### Theme & Color Palette
**IMPORTANT**: All screens MUST use the centralized theme from `lib/utils/theme.dart`. Never hardcode colors.

#### Primary Color Palette (Logo-Based)
```dart
// Primary Brand Colors
AppTheme.primaryBrandBlue  = #3498DB  // Trust / Education (main primary)
AppTheme.primaryBrandGreen = #6BCB80  // Aspirational / Growth

// Accent Colors
AppTheme.accentBlue  = #2196F3  // Vibrant / Knowledge
AppTheme.accentGreen = #4CAF50  // Fresh / Success

// Semantic Colors
AppTheme.successGreen = #4CAF50  // "Vero" button, correct answers
AppTheme.errorRed     = #F44336  // "Falso" button, incorrect answers

// Neutral Colors
AppTheme.darkGrey  = #333333  // Primary text (light mode), dark backgrounds
AppTheme.lightGrey = #F8F8F8  // Light backgrounds, secondary text
```

#### Using Theme in Code
```dart
// Access theme colors
final theme = Theme.of(context);
final primaryColor = theme.colorScheme.primary;  // Primary Blue

// Answer button colors (custom extension)
final answerColors = AnswerButtonColors.of(context);
final correctColor = answerColors.correctColor;  // Success Green
final incorrectColor = answerColors.incorrectColor;  // Error Red

// Gradients for premium UI
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.primaryGradient,  // Blue → Green
  ),
)

// Typography (auto-sized for readability)
Text('Question', style: theme.textTheme.bodyLarge);  // 18sp (min requirement)
```

#### Theme Guidelines
- ✅ Use `Theme.of(context).colorScheme.primary` for primary actions
- ✅ Use `AnswerButtonColors.of(context)` for Vero/Falso buttons
- ✅ Use `AppTheme.primaryGradient` for hero sections (splash, dashboard cards)
- ✅ Both light and dark themes fully configured with proper contrast
- ❌ Never hardcode color values like `Color(0xFF123456)` outside theme.dart
- ❌ Don't use generic colors (Colors.blue, Colors.green) - always use theme

### Critical Features ("Secret Sauce")
1. **Spy Words (Trucchi)**: Hint button in training mode highlights trigger words ("Mai", "Sempre", "Solo") with 90% False probability explanation
2. **Error-First Review**: Results screen defaults to "Show only errors" filter
3. **Smart Topic Routing**: Tapping red topics in analytics immediately launches focused quiz with only that topic's questions

## Commands & Workflows

### Setup
```bash
flutter pub get
flutter run  # Select device when prompted
```

### Adding Packages
```bash
flutter pub add <package_name>        # Runtime dependency
flutter pub add --dev <package_name>  # Dev dependency
```

### Common Packages (Add as needed)
- State: `provider`, `riverpod`, or `bloc`
- Navigation: `go_router`
- Auth: `firebase_auth`, `google_sign_in`, `sign_in_with_apple`
- Storage: `shared_preferences`, `sqflite` or `hive`
- Images: `cached_network_image`, `photo_view`
- Charts: `fl_chart`
- Video: `video_player` or `youtube_player_flutter`
- Haptics: `vibration` or `flutter_vibrate`

### Build & Test
```bash
flutter test                          # Run unit tests
flutter build apk --release          # Android APK
flutter build ios --release          # iOS (requires Mac)
```

## Data Model Examples

### Question Model
```dart
class Question {
  final String id;
  final String text;
  final String? imageUrl;
  final bool correctAnswer;  // true = Vero, false = Falso
  final String topicId;
  final List<String> spyWords;  // ["Mai", "Sempre"] for hint feature
}
```

### Quiz Session
```dart
class QuizSession {
  final String id;
  final QuizMode mode;  // enum: training, exam, topic
  final List<Question> questions;
  final Map<int, bool> userAnswers;
  final DateTime startTime;
  int get correctCount => // calculate
  int get errorCount => // calculate
  bool get passed => errorCount <= 4;  // Italian exam: max 4 errors in 30 questions
}
```

## Integration Points

### Authentication Flow
1. Check `SharedPreferences` for guest mode attempts (max 1)
2. If logged out & attempts used → Force auth screen
3. Social login → Store user token → Navigate to setup or dashboard
4. Guest mode → Generate anonymous session → Track as guest in analytics

### Question Database
- Store questions locally (SQLite/Hive) with periodic sync
- Structure: 25 topics × ~40 questions each = ~1000 total
- Index by `topicId` for filtered quizzes
- Cache images with `CachedNetworkImage`

### Analytics Calculation
```dartwww
// Exam Readiness Formula (example)
double calculateReadiness(List<QuizSession> recentSessions) {
  final last10Sessions = recentSessions.take(10);
  final avgCorrect = last10Sessions.map((s) => s.correctCount).average;
  return (avgCorrect / 30) * 100;  // Convert to percentage
}
```

## Common Mistakes to Avoid
- ❌ Don't load all 1000 questions at app start (use lazy loading)
- ❌ Don't forget to dispose timers/controllers to prevent memory leaks
- ❌ Don't skip haptic feedback on primary buttons (key UX differentiator)
- ❌ Don't allow exam mode navigation between questions (must be linear)
- ❌ Don't show correct answers during exam mode (breaks realism)

## Localization Best Practices

### Using Translations in Code
```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// In build method
final l10n = AppLocalizations.of(context)!;
Text(l10n.appTitle); // Uses current locale

// Or use extension helper
import '../utils/localization_helper.dart';
Text(context.l10n.appTitle); // Cleaner syntax
```

### Adding New Translations
1. Add key to all 3 ARB files: `lib/l10n/app_{en,it,bn}.arb`
2. Run `flutter pub get` to regenerate
3. Use: `l10n.yourNewKey`

### Language Management
- Language selected on first launch via splash screen
- Persisted in SharedPreferences
- Managed by `LanguageProvider` (uses Provider package)
- Supported: English, Italian (default), Bangla

## When Implementing New Screens
1. Create screen file in `lib/screens/<phase_name>/`
2. Define route in navigation service/router
3. Extract reusable widgets to `lib/widgets/`
4. Use existing theme colors/typography from `utils/theme.dart`
5. **Add all text strings to l10n ARB files (never hardcode text)**
6. Test both light and dark mode
7. Test all 3 languages (en, it, bn)
8. Add haptic feedback to interactive elements
9. Ensure responsive layout (phone + tablet)

## Notes
- **Phase 1 Complete**: Onboarding & Auth module with full localization (3 languages)
- **Phase 2 Complete**: Dashboard with circular progress, 3 action cards (Exam Mode, Topic Mode, Review Errors), gamification metrics, and sample screens
- Prioritize Phase 3 for MVP (Quiz Core - question interface, timer, results)
- Italian exam rules: 30 questions, 20 minutes, max 4 errors to pass
- Target users: Students studying for Patente B (age 18+, mobile-first)
- Default language: Italian, with English and Bangla support
- All buttons use HapticFeedback.mediumImpact() for tactile response




DB schema:
-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.categories (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name_it text NOT NULL,
  name_en text,
  name_bn text,
  color_hex text,
  display_order integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name text,
  username text,
  avatar_url text,
  license_type text DEFAULT 'B'::text,
  is_verified boolean DEFAULT false,
  xp integer DEFAULT 0,
  current_level integer DEFAULT 1,
  daily_streak integer DEFAULT 0,
  last_study_date timestamp with time zone,
  total_quizzes_taken integer DEFAULT 0,
  average_score numeric DEFAULT 0.0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  role text DEFAULT 'user'::text,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.questions (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  subtopic_id bigint,
  text_it text NOT NULL,
  text_en text,
  text_bn text,
  image_url text,
  is_true boolean NOT NULL,
  explanation_it text,
  explanation_en text,
  explanation_bn text,
  difficulty_level integer DEFAULT 1,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT questions_pkey PRIMARY KEY (id),
  CONSTRAINT questions_subtopic_id_fkey FOREIGN KEY (subtopic_id) REFERENCES public.subtopics(id)
);
CREATE TABLE public.quiz_answers (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  session_id uuid NOT NULL,
  user_id uuid NOT NULL,
  question_id bigint NOT NULL,
  selected_true boolean NOT NULL,
  is_correct boolean NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT quiz_answers_pkey PRIMARY KEY (id),
  CONSTRAINT quiz_answers_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.quiz_sessions(id),
  CONSTRAINT quiz_answers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT quiz_answers_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(id)
);
CREATE TABLE public.quiz_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  mode USER-DEFINED NOT NULL,
  total_questions integer DEFAULT 30,
  errors_count integer,
  is_passed boolean,
  duration_seconds integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT quiz_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT quiz_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.subtopics (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  topic_id bigint,
  name_it text NOT NULL,
  name_en text,
  name_bn text,
  image_url text,
  display_order integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT subtopics_pkey PRIMARY KEY (id),
  CONSTRAINT subtopics_topic_id_fkey FOREIGN KEY (topic_id) REFERENCES public.topics(id)
);
CREATE TABLE public.theory_cards (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  chapter_id bigint,
  title_it text,
  title_en text,
  title_bn text,
  text_it text NOT NULL,
  text_en text,
  text_bn text,
  image_url text,
  display_order integer DEFAULT 1,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT theory_cards_pkey PRIMARY KEY (id),
  CONSTRAINT theory_cards_chapter_id_fkey FOREIGN KEY (chapter_id) REFERENCES public.theory_chapters(id)
);
CREATE TABLE public.theory_chapters (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  related_quiz_topic_id bigint,
  name_it text NOT NULL,
  name_en text,
  name_bn text,
  image_url text,
  display_order integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT theory_chapters_pkey PRIMARY KEY (id),
  CONSTRAINT theory_chapters_related_quiz_topic_id_fkey FOREIGN KEY (related_quiz_topic_id) REFERENCES public.topics(id)
);
CREATE TABLE public.topics (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  category_id bigint,
  name_it text NOT NULL,
  name_en text,
  name_bn text,
  image_url text,
  display_order integer,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT topics_pkey PRIMARY KEY (id),
  CONSTRAINT topics_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id)
);
CREATE TABLE public.video_categories (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  name_it text NOT NULL,
  name_en text,
  name_bn text,
  display_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT video_categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.videos (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  category_id bigint,
  title_it text NOT NULL,
  title_en text,
  title_bn text,
  youtube_url text NOT NULL,
  duration_minutes integer,
  thumbnail_url text,
  display_order integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT videos_pkey PRIMARY KEY (id),
  CONSTRAINT videos_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.video_categories(id)
);

Name of function
handle_new_user
Name will also be used for the function name in postgres
Schema

schema

public

Tables made in the table editor will be in 'public'
Arguments
Arguments can be referenced in the function body using either names or numbers.

No argument for this function
Definition
The language below should be written in plpgsql.

BEGIN
  INSERT INTO public.profiles (id, full_name, username, avatar_url)
  VALUES (
    new.id, 
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'phone',
    new.raw_user_meta_data->>'avatar_url'
  );
  RETURN new;
END;





Name of function
update_user_stats
Name will also be used for the function name in postgres
Schema

schema

public

Tables made in the table editor will be in 'public'
Arguments
Arguments can be referenced in the function body using either names or numbers.

No argument for this function
Definition
The language below should be written in plpgsql.

BEGIN
  IF NEW.is_passed = TRUE THEN
    UPDATE public.profiles SET xp = xp + 100, total_quizzes_taken = total_quizzes_taken + 1 WHERE id = NEW.user_id;
  ELSE
    UPDATE public.profiles SET xp = xp + 20, total_quizzes_taken = total_quizzes_taken + 1 WHERE id = NEW.user_id;
  END IF;
  RETURN NEW;
END;






Name of function
is_admin
Name will also be used for the function name in postgres
Schema

schema

public

Tables made in the table editor will be in 'public'
Arguments
Arguments can be referenced in the function body using either names or numbers.

No argument for this function
Definition
The language below should be written in plpgsql.

DECLARE
  current_role text;
BEGIN
  SELECT role INTO current_role FROM public.profiles WHERE id = auth.uid();
  RETURN current_role = 'admin';
END;




Name of function
verify_admin_pin
Name will also be used for the function name in postgres
Schema

schema

public

Tables made in the table editor will be in 'public'
Arguments
Arguments can be referenced in the function body using either names or numbers.

input_pin
text
Definition
DECLARE
  stored_username text;
  is_user_admin boolean;
BEGIN
  -- 1. Get current user's info
  SELECT username, (role = 'admin') 
  INTO stored_username, is_user_admin
  FROM public.profiles 
  WHERE id = auth.uid();

  -- 2. Logic: User must be admin AND input must match username
  IF is_user_admin = TRUE AND stored_username = input_pin THEN
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;



1. func_get_all_users_for_admin
Purpose: Gets a raw list of all people who have signed up.
Security: Only runs if your role is 'admin'.
Flutter Call:
code
Dart
final response = await supabase.rpc('func_get_all_users_for_admin');
// returns List<Map<String, dynamic>> (Profile objects)
2. func_admin_verify_user
Purpose: The "Switch" toggle. Approves or Bans a user.
Parameters:
target_user_id (String/UUID): The ID of the user you want to change.
verify_status (bool): true to approve, false to block/pending.
Flutter Call:
code
Dart
await supabase.rpc('func_admin_verify_user', params: {
  'target_user_id': 'some-user-uuid-123',
  'verify_status': true 
});
3. func_admin_upsert_question
Purpose: The "Save" button in your Quiz Editor.
Logic: If you pass null for p_id, it creates a new question. If you pass a number (e.g., 105), it updates that question.
Parameters:
p_id (int?): The Question ID (null for new).
p_subtopic_id (int): Which subtopic this belongs to.
p_text_it / _en / _bn (String): The question text in 3 languages.
p_image_url (String?): The filename (e.g., 'fig_910.png').
p_is_true (bool): The answer.
(Optional) p_explanation...: Why the answer is right/wrong.
Flutter Call:
code
Dart
await supabase.rpc('func_admin_upsert_question', params: {
  'p_id': null, // Creating new
  'p_subtopic_id': 5,
  'p_text_it': 'Il segnale...',
  'p_text_en': 'The signal...',
  'p_text_bn': 'সংকেত...',
  'p_image_url': 'fig_10.png',
  'p_is_true': true
});
4. func_admin_upsert_theory_card
Purpose: The "Save" button in your Theory Editor.
Logic: Same as above (Null ID = New, Value ID = Update).
Parameters:
p_id (int?): Card ID.
p_chapter_id (int): Which Lezione/Chapter (e.g., "Segnali di Pericolo").
p_title... (String): The bold header (e.g., "DOSSO").
p_text... (String): The main content paragraph.
p_image_url (String?): Optional image.
p_display_order (int): Order in the list (1st, 2nd, 3rd).





