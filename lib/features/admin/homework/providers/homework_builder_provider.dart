import 'package:flutter/foundation.dart';

import '../../../../models/homework_set.dart';
import '../../../../models/question.dart';
import '../../../../repositories/homework_repository.dart';

class HomeworkFormSettings {
  const HomeworkFormSettings({
    required this.title,
    required this.description,
    required this.timeLimitMinutes,
    required this.startsAt,
    required this.endsAt,
    required this.shuffleQuestions,
    required this.retryAllowed,
  });

  final String title;
  final String? description;
  final int timeLimitMinutes;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool shuffleQuestions;
  final bool retryAllowed;
}

class HomeworkBuilderProvider extends ChangeNotifier {
  HomeworkBuilderProvider({
    required HomeworkRepository repository,
    HomeworkSet? editingHomework,
  })  : _repository = repository,
        _editingHomework = editingHomework;

  final HomeworkRepository _repository;
  final HomeworkSet? _editingHomework;

  bool _isInitializing = false;
  bool _isSaving = false;

  int _targetCount = 30;
  List<Question> _selectedQuestions = <Question>[];
  Set<int> _selectedIds = <int>{};
  Set<int> _autoFilledIds = <int>{};

  String _title = '';
  String? _description;
  int _timeLimitMinutes = 20;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _shuffleQuestions = true;
  bool _retryAllowed = true;

  bool get isInitializing => _isInitializing;
  bool get isSaving => _isSaving;
  bool get isEditing => _editingHomework != null;
  HomeworkSet? get editingHomework => _editingHomework;

  int get targetCount => _targetCount;
  int get selectedCount => _selectedQuestions.length;
  bool get reachedTarget => _selectedQuestions.length >= _targetCount;

  List<Question> get selectedQuestions =>
      List<Question>.unmodifiable(_selectedQuestions);
  Set<int> get selectedQuestionIds => Set<int>.from(_selectedIds);
  bool isAutoFilledQuestion(int questionId) => _autoFilledIds.contains(questionId);
  int get autoFilledCount => _autoFilledIds.length;
  int get manualSelectedCount => selectedCount - autoFilledCount;

  String get title => _title;
  String? get description => _description;
  int get timeLimitMinutes => _timeLimitMinutes;
  DateTime? get startsAt => _startsAt;
  DateTime? get endsAt => _endsAt;
  bool get shuffleQuestions => _shuffleQuestions;
  bool get retryAllowed => _retryAllowed;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    if (_editingHomework != null) {
      final existing = await _repository.getHomeworkQuestions(_editingHomework.id);
      _selectedQuestions = List<Question>.from(existing);
      _selectedIds = existing.map((q) => q.id).toSet();
      _autoFilledIds.clear();
      _targetCount = (_editingHomework.questionCount ?? existing.length)
          .clamp(1, 10000)
          .toInt();
      if (_targetCount < existing.length) {
        _targetCount = existing.length;
      }
      _title = _editingHomework.title;
      _description = _editingHomework.description;
      _timeLimitMinutes = _editingHomework.timeLimitMinutes;
      _startsAt = _editingHomework.startsAt;
      _endsAt = _editingHomework.endsAt;
      _shuffleQuestions = _editingHomework.shuffleQuestions;
      _retryAllowed = _editingHomework.retryAllowed;
    }

    _isInitializing = false;
    notifyListeners();
  }

  void setTargetCount(int value) {
    if (value <= 0) return;
    _targetCount = value;
    notifyListeners();
  }

  void toggleQuestion(Question question) {
    if (_selectedIds.contains(question.id)) {
      _selectedIds.remove(question.id);
      _autoFilledIds.remove(question.id);
      _selectedQuestions.removeWhere((q) => q.id == question.id);
    } else {
      if (reachedTarget) return;
      _selectedIds.add(question.id);
      final firstAutoIndex = _selectedQuestions.indexWhere(
        (q) => _autoFilledIds.contains(q.id),
      );
      if (firstAutoIndex == -1) {
        _selectedQuestions.add(question);
      } else {
        _selectedQuestions.insert(firstAutoIndex, question);
      }
    }
    notifyListeners();
  }

  bool isQuestionSelected(int questionId) => _selectedIds.contains(questionId);

  void removeSelectedQuestion(int questionId) {
    if (!_selectedIds.contains(questionId)) return;
    _selectedIds.remove(questionId);
    _autoFilledIds.remove(questionId);
    _selectedQuestions.removeWhere((q) => q.id == questionId);
    notifyListeners();
  }

  void clearAllSelected() {
    _selectedIds.clear();
    _autoFilledIds.clear();
    _selectedQuestions = <Question>[];
    notifyListeners();
  }

  void reorderSelected(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _selectedQuestions.length) return;
    if (newIndex < 0 || newIndex > _selectedQuestions.length) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _selectedQuestions.removeAt(oldIndex);
    final movedIsAuto = _autoFilledIds.contains(item.id);

    if (_autoFilledIds.isNotEmpty) {
      final firstAutoIndex = _selectedQuestions.indexWhere(
        (q) => _autoFilledIds.contains(q.id),
      );
      if (firstAutoIndex != -1) {
        if (movedIsAuto && newIndex < firstAutoIndex) {
          newIndex = firstAutoIndex;
        } else if (!movedIsAuto && newIndex > firstAutoIndex) {
          newIndex = firstAutoIndex;
        }
      }
    }

    _selectedQuestions.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> autoFillRemaining() async {
    final randoms = await _repository.getRandomQuestionsToFill(
      selectedQuestionIds: _selectedIds.toList(),
      targetCount: _targetCount,
    );
    if (randoms.isEmpty) return;
    for (final q in randoms) {
      if (_selectedIds.add(q.id)) {
        _autoFilledIds.add(q.id);
        _selectedQuestions.add(q);
      }
    }
    notifyListeners();
  }

  void applySettings(HomeworkFormSettings settings) {
    _title = settings.title;
    _description = settings.description;
    _timeLimitMinutes = settings.timeLimitMinutes;
    _startsAt = settings.startsAt;
    _endsAt = settings.endsAt;
    _shuffleQuestions = settings.shuffleQuestions;
    _retryAllowed = settings.retryAllowed;
    notifyListeners();
  }

  Future<void> saveHomework({required bool publish}) async {
    if (_selectedQuestions.isEmpty) {
      throw Exception('Please select at least one quiz.');
    }
    if (_title.trim().isEmpty) {
      throw Exception('Homework title is required.');
    }
    if (_startsAt != null && _endsAt != null && _endsAt!.isBefore(_startsAt!)) {
      throw Exception('End date/time must be after start date/time.');
    }

    _isSaving = true;
    notifyListeners();

    try {
      if (_editingHomework == null) {
        await _repository.createHomework(
          title: _title.trim(),
          description: _description,
          timeLimitMinutes: _timeLimitMinutes,
          startsAt: _startsAt,
          endsAt: _endsAt,
          shuffleQuestions: _shuffleQuestions,
          retryAllowed: _retryAllowed,
          isDraft: !publish,
          questionIds: _selectedQuestions.map((q) => q.id).toList(),
        );
      } else {
        await _repository.updateHomework(
          homeworkSetId: _editingHomework.id,
          title: _title.trim(),
          description: _description,
          timeLimitMinutes: _timeLimitMinutes,
          startsAt: _startsAt,
          endsAt: _endsAt,
          shuffleQuestions: _shuffleQuestions,
          retryAllowed: _retryAllowed,
          isDraft: !publish,
          questionIds: _selectedQuestions.map((q) => q.id).toList(),
        );
      }
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
