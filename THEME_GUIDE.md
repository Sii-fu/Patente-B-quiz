# Patente B Quiz - Theme Guide

## Overview
This document describes how to use the centralized theme system in the Patente B Quiz app. **All UI elements MUST follow this theme** to ensure consistency across the app.

## Color Palette

### Primary Brand Colors (Logo-Based)
```dart
AppTheme.primaryBrandBlue  // #3498DB - Trust / Education (main primary)
AppTheme.primaryBrandGreen // #6BCB80 - Aspirational / Growth
```

### Accent Colors
```dart
AppTheme.accentBlue  // #2196F3 - Vibrant / Knowledge
AppTheme.accentGreen // #4CAF50 - Fresh / Success
```

### Semantic Colors
```dart
AppTheme.successGreen // #4CAF50 - "Vero" button, correct answers
AppTheme.errorRed     // #F44336 - "Falso" button, incorrect answers
```

### Neutral Colors
```dart
AppTheme.darkGrey  // #333333 - Primary text (light mode), dark backgrounds
AppTheme.lightGrey // #F8F8F8 - Light backgrounds, secondary text
```

### Shorthand Aliases
```dart
AppTheme.primaryColor   // Alias for primaryBrandBlue
AppTheme.secondaryColor // Alias for primaryBrandGreen
AppTheme.successColor   // Alias for successGreen
AppTheme.errorColor     // Alias for errorRed
```

## Gradients

### Primary Gradient (Blue → Green)
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.primaryGradient,
    borderRadius: BorderRadius.circular(16),
  ),
  child: YourWidget(),
)
```

### Accent Gradient (Lighter Blue → Lighter Green)
```dart
Container(
  decoration: BoxDecoration(
    gradient: AppTheme.accentGradient,
    borderRadius: BorderRadius.circular(16),
  ),
  child: YourWidget(),
)
```

## Accessing Theme Colors

### Using Theme.of(context)
```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  
  return Container(
    color: colorScheme.primary,        // Primary Blue
    child: Text(
      'Hello',
      style: theme.textTheme.bodyLarge, // Auto-sized 18sp
    ),
  );
}
```

### Answer Button Colors (Custom Extension)
```dart
final answerColors = AnswerButtonColors.of(context);

ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: answerColors.correctColor,     // Success Green
    foregroundColor: answerColors.correctTextColor, // White
  ),
  child: Text('Vero'),
)

ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: answerColors.incorrectColor,     // Error Red
    foregroundColor: answerColors.incorrectTextColor, // White
  ),
  child: Text('Falso'),
)
```

## Typography

### Text Styles (From theme.textTheme)
```dart
// Headlines & Titles
theme.textTheme.displayLarge   // 32sp, bold - Main titles
theme.textTheme.displayMedium  // 28sp, bold - Section titles
theme.textTheme.displaySmall   // 24sp, bold - Card titles
theme.textTheme.headlineMedium // 20sp, w600 - Subtitles

// Body Text
theme.textTheme.bodyLarge      // 18sp - Question text (meets min requirement)
theme.textTheme.bodyMedium     // 16sp - Secondary text
theme.textTheme.labelLarge     // 14sp, w500 - Button labels
```

### Usage Example
```dart
Column(
  children: [
    Text(
      'Dashboard',
      style: theme.textTheme.displayMedium, // 28sp bold
    ),
    Text(
      'Question 1 of 30',
      style: theme.textTheme.bodyLarge, // 18sp (readable)
    ),
    Text(
      'Il semaforo rosso indica...',
      style: theme.textTheme.bodyLarge, // Question text
    ),
  ],
)
```

## Common UI Patterns

### Elevated Button (Primary Action)
```dart
ElevatedButton(
  onPressed: () {},
  child: Text('Start Quiz'),
)
// ✓ Auto-styled: Blue background, white text, 56dp height, rounded corners
```

### Outlined Button (Secondary Action)
```dart
OutlinedButton(
  onPressed: () {},
  child: Text('Skip'),
)
// ✓ Auto-styled: Blue border, blue text, 56dp height
```

### Text Button (Tertiary Action)
```dart
TextButton(
  onPressed: () {},
  child: Text('Learn More'),
)
// ✓ Auto-styled: Blue text, no background
```

### Cards
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: YourContent(),
  ),
)
// ✓ Auto-styled: 16dp rounded corners, elevation 2, proper shadows
```

### Text Fields
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'Enter school code',
    labelText: 'School Code',
  ),
)
// ✓ Auto-styled: Rounded borders, blue focus, red error states
```

## Quiz-Specific Components

### Answer Buttons (Vero/Falso)
```dart
// Training Mode - With instant feedback
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: isCorrect 
      ? AnswerButtonColors.of(context).correctColor   // Green
      : AnswerButtonColors.of(context).incorrectColor, // Red
    minimumSize: Size(double.infinity, 56), // Full width, 56dp height
  ),
  onPressed: () {
    HapticFeedback.mediumImpact(); // Required haptic feedback
  },
  child: Text('Vero'),
)

// Exam Mode - Neutral until results
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AnswerButtonColors.of(context).neutralColor, // Grey
    foregroundColor: AnswerButtonColors.of(context).neutralTextColor,
    minimumSize: Size(double.infinity, 56),
  ),
  onPressed: () {
    HapticFeedback.mediumImpact(); // Required haptic feedback
  },
  child: Text('Falso'),
)
```

### Hero Sections with Gradient
```dart
Container(
  height: 200,
  decoration: BoxDecoration(
    gradient: AppTheme.primaryGradient,
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(32),
      bottomRight: Radius.circular(32),
    ),
  ),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        'Exam Readiness',
        style: theme.textTheme.displayMedium.copyWith(
          color: Colors.white,
        ),
      ),
      Text(
        '85%',
        style: theme.textTheme.displayLarge.copyWith(
          color: Colors.white,
          fontSize: 48,
        ),
      ),
    ],
  ),
)
```

### Progress Indicators
```dart
// Use primary color for progress
CircularProgressIndicator(
  value: 0.85,
  backgroundColor: Colors.grey[300],
  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary), // Blue
)

LinearProgressIndicator(
  value: 0.60,
  backgroundColor: Colors.grey[300],
  valueColor: AlwaysStoppedAnimation(AppTheme.primaryBrandGreen), // Green
)
```

## Dark Mode

The app automatically switches between light and dark themes based on system settings. All colors are properly configured for both modes.

```dart
// No extra code needed - Theme.of(context) handles it automatically
final isDarkMode = Theme.of(context).brightness == Brightness.dark;
```

## Best Practices

### ✅ DO
- Use `Theme.of(context)` for all colors
- Use `theme.textTheme.*` for all text styles
- Use `AnswerButtonColors.of(context)` for quiz buttons
- Use gradients for hero sections and premium features
- Add `HapticFeedback.mediumImpact()` to all interactive buttons
- Test in both light and dark modes

### ❌ DON'T
- Hardcode colors: `Color(0xFF123456)`
- Use generic colors: `Colors.blue`, `Colors.green`
- Hardcode font sizes: `fontSize: 18`
- Skip haptic feedback on buttons
- Forget to test dark mode

## Examples by Screen

### Dashboard
```dart
Scaffold(
  backgroundColor: theme.scaffoldBackgroundColor, // Auto light/dark
  body: Column(
    children: [
      // Hero section with gradient
      Container(
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: CircularProgressWidget(),
      ),
      // Action cards
      Card(
        child: ListTile(
          title: Text('Exam Mode', style: theme.textTheme.headlineMedium),
          trailing: Icon(Icons.arrow_forward, color: theme.colorScheme.primary),
        ),
      ),
    ],
  ),
)
```

### Quiz Screen
```dart
Scaffold(
  appBar: AppBar(
    title: Text('Question 5/30'),
    actions: [
      // Timer widget
      Text('18:45', style: theme.textTheme.headlineMedium),
    ],
  ),
  body: Column(
    children: [
      // Question text
      Text(
        question.text,
        style: theme.textTheme.bodyLarge, // 18sp minimum
      ),
      // Answer buttons
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AnswerButtonColors.of(context).correctColor,
        ),
        onPressed: () => HapticFeedback.mediumImpact(),
        child: Text('Vero'),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AnswerButtonColors.of(context).incorrectColor,
        ),
        onPressed: () => HapticFeedback.mediumImpact(),
        child: Text('Falso'),
      ),
    ],
  ),
)
```

## Quick Reference Cheatsheet

| Use Case | Code |
|----------|------|
| Primary action button | `ElevatedButton(...)` (auto-styled) |
| "Vero" button | `backgroundColor: AnswerButtonColors.of(context).correctColor` |
| "Falso" button | `backgroundColor: AnswerButtonColors.of(context).incorrectColor` |
| Question text | `style: theme.textTheme.bodyLarge` |
| Title text | `style: theme.textTheme.displayMedium` |
| Hero gradient | `gradient: AppTheme.primaryGradient` |
| Primary color | `theme.colorScheme.primary` |
| Success color | `AppTheme.successGreen` |
| Error color | `AppTheme.errorRed` |
| Haptic feedback | `HapticFeedback.mediumImpact()` |

---

**Last Updated**: December 2025
**Theme File**: `lib/utils/theme.dart`
