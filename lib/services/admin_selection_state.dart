/// Remembers the last chapter/theory-card (subtopic) the admin tapped into
/// while browsing theory content, so `AddQuizScreen` can auto-select the
/// same category even if it wasn't opened with explicit ids.
class AdminSelectionState {
  AdminSelectionState._();

  static int? lastChapterId;
  static int? lastSubtopicId;

  static void rememberChapter(int chapterId) {
    lastChapterId = chapterId;
  }

  static void rememberSubtopic(int chapterId, int subtopicId) {
    lastChapterId = chapterId;
    lastSubtopicId = subtopicId;
  }
}
