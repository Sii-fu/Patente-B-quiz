# Theory Card Module - Navigation Guide

## Overview
Three new screens have been implemented for browsing theory cards and taking related quizzes:

1. **TheoryCardListScreen** - Lists all theory cards (titles only)
2. **TheoryCardDetailScreen** - Shows full card content with image, text, and TTS
3. **TheoryCardQuizScreen** - Shows quiz questions filtered by subtopic

## File Locations
- `lib/screens/theory/theory_card_list_screen.dart`
- `lib/screens/theory/theory_card_detail_screen.dart`
- `lib/screens/theory/theory_card_quiz_screen.dart`

## Navigation Example

### From Dashboard or Any Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../screens/theory/theory_card_list_screen.dart';

// Inside your widget build method or onTap handler:
ElevatedButton(
  onPressed: () {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TheoryCardListScreen(),
      ),
    );
  },
  child: const Text('Browse Theory Cards'),
)
```

### Navigation Flow
```
TheoryCardListScreen (List of all cards)
    ↓ (Tap on a card)
TheoryCardDetailScreen (Full card with image, text, language toggle)
    ↓ (Tap "View Related Quizzes" button)
TheoryCardQuizScreen (Quiz questions for that subtopic)
    ↓ (Complete quiz)
Results Screen (Embedded in quiz screen)
```

## Features

### TheoryCardListScreen
- ✅ Displays all theory cards across all chapters
- ✅ Shows card titles in current language (IT/EN/BN)
- ✅ Groups cards by chapter
- ✅ Dark mode compatible
- ✅ Handles loading, error, and empty states
- ✅ Auto-syncs from Supabase if local DB is empty

### TheoryCardDetailScreen
- ✅ Displays full card content with image
- ✅ Language toggle (IT/EN/BN)
- ✅ Text-to-Speech (TTS) support with language detection
- ✅ Full-screen image zoom
- ✅ Chapter information display
- ✅ "View Quizzes" button (only shown if card has subtopic_id)
- ✅ Dark mode compatible

### TheoryCardQuizScreen
- ✅ Fetches questions by subtopic_id
- ✅ VERO/FALSO answer buttons with proper colors
- ✅ Progress indicator
- ✅ Results summary with pass/fail status
- ✅ Question review with correct/incorrect highlighting
- ✅ Image zoom for question images
- ✅ Dark mode compatible

## Database Schema Update

The `TheoryCard` model now includes `subtopicId`:

```dart
class TheoryCard {
  final int id;
  final int chapterId;
  final int? subtopicId;  // NEW FIELD
  final String? titleIt;
  // ... other fields
}
```

This links theory cards to quiz questions through the subtopics table.

## New Localization Keys

Added to `app_en.arb`, `app_it.arb`, and `app_bn.arb`:

```
theoryCardListTitle
theoryCardListEmpty
theoryCardListErrorLoading
theoryCardListRetry
theoryCardDetailTitle
theoryCardDetailChapter
theoryCardDetailViewQuizzes
theoryCardQuizTitle
theoryCardQuizResults
theoryCardQuizEmpty
theoryCardQuizErrorLoading
ttsInstallTitle
ttsLanguageNotInstalled
ttsInstallPrompt
ttsLater
ttsInstall
quizResultsPassed
quizResultsFailed
quizResultsCorrect
quizResultsErrors
quizResultsReviewTitle
quizQuestionNumber
quizCorrectAnswer
quizYourAnswer
quizResultsBackToTheory
```

## QuizService Update

New method added to fetch questions by subtopic:

```dart
Future<List<Question>> fetchQuestionsBySubtopic(int subtopicId, {int count = 30})
```

## Theme Compliance

All screens use:
- ✅ `Theme.of(context).colorScheme` for colors
- ✅ `AppTheme.successGreen` for correct/VERO
- ✅ `AppTheme.errorRed` for incorrect/FALSO
- ✅ Proper contrast in both light and dark modes
- ✅ `HapticFeedback` for all interactions

## Testing Checklist

- [ ] Navigate to TheoryCardListScreen
- [ ] Verify cards load correctly
- [ ] Tap a card to view details
- [ ] Test language toggle (IT/EN/BN)
- [ ] Test TTS functionality
- [ ] Test image zoom
- [ ] Tap "View Quizzes" button
- [ ] Complete a quiz
- [ ] Review results
- [ ] Test in dark mode
- [ ] Test with empty subtopic (no quizzes available)

## Notes

- Cards without `subtopicId` will NOT show the "View Quizzes" button
- Empty quiz results are handled gracefully
- TTS prompts user to install Italian voice if not available
- All images use `CachedNetworkImage` for performance
