import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';

class QuizService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches 30 random questions from the database with subtopic information
  /// Handles cases where images or explanations might not be available
  Future<List<Question>> fetchRandomQuestions() async {
    try {
      // Call the stored procedure
      final response = await _supabase
          .rpc('func_get_official_exam_simulation')
          .select('*, subtopics(*)'); 

      print('🔍 Fetching official exam simulation questions from the database.');
      
      if (response == null || (response as List).isEmpty) {
        throw Exception('No questions found for the exam simulation.');
      }

      final List<Question> officialExamQuestions = (response as List)
          .map((json) => Question.fromJson(json))
          .toList();

      return officialExamQuestions;
    } catch (e) {
      print('Error fetching official exam: $e');
      throw Exception('Failed to fetch exam simulation: $e');
    }
  }

  /// Fetches questions for a specific topic
  Future<List<Question>> fetchQuestionsByTopic(int topicId, {int count = 30}) async {
    try {
      final response = await _supabase
          .from('questions')
          .select('*, subtopics!inner(*)')
          .eq('subtopics.topic_id', topicId)
          .limit(count * 2);

      if (response.isEmpty) {
        throw Exception('No questions found for this topic');
      }

      final List<Question> questions = (response as List)
          .map((json) => Question.fromJson(json))
          .toList();

      questions.shuffle();
      return questions.take(count).toList();
    } catch (e) {
      throw Exception('Failed to fetch topic questions: $e');
    }
  }

  /// Fetches questions for a specific subtopic (for theory card quizzes)
  Future<List<Question>> fetchQuestionsBySubtopic(int subtopicId, {int count = 30}) async {
    try {
      final response = await _supabase
          .from('questions')
          .select('*, subtopics(*)')
          .eq('subtopic_id', subtopicId)
          .limit(count * 2);

      if (response.isEmpty) {
        // If no questions found, return empty list instead of throwing
        print('⚠️ No questions found for subtopic $subtopicId');
        return [];
      }

      final List<Question> questions = (response as List)
          .map((json) => Question.fromJson(json))
          .toList();

      questions.shuffle();
      return questions.take(count).toList();
    } catch (e) {
      print('❌ Error fetching questions by subtopic: $e');
      throw Exception('Failed to fetch subtopic questions: $e');
    }
  }

  /// Saves quiz results to the database
  /// Creates a quiz session and saves individual answers
  Future<void> saveQuizResults({
    required List<Question> questions,
    required Map<int, bool> userAnswers,
    required QuizMode mode,
    required int durationSeconds,
    }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate results
      int errorsCount = 0;
      for (int i = 0; i < questions.length; i++) {
        final userAnswer = userAnswers[i];
        if (userAnswer == null || userAnswer != questions[i].isTrue) {
          errorsCount++;
        }
      }

      final isPassed = errorsCount <= 4; // Max 4 errors allowed

      // Create quiz session
      final sessionResponse = await _supabase
          .from('quiz_sessions')
          .insert({
            'user_id': userId,
            'mode': _modeToString(mode),
            'total_questions': questions.length,
            'errors_count': errorsCount,
            'is_passed': isPassed,
            'duration_seconds': durationSeconds,
          })
          .select()
          .single();

      final sessionId = sessionResponse['id'] as String;

      // Prepare batch insert for answers
      final List<Map<String, dynamic>> answersData = [];
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        final userAnswer = userAnswers[i];
        
        if (userAnswer != null) {
          final isCorrect = userAnswer == question.isTrue;
          answersData.add({
            'session_id': sessionId,
            'user_id': userId,
            'question_id': question.id,
            'selected_true': userAnswer,
            'is_correct': isCorrect,
          });
        } else {
          // Unanswered question - mark as incorrect
          answersData.add({
            'session_id': sessionId,
            'user_id': userId,
            'question_id': question.id,
            'selected_true': false, // Default value for unanswered
            'is_correct': false,
          });
        }
      }

      // Batch insert all answers
      if (answersData.isNotEmpty) {
        await _supabase.from('quiz_answers').insert(answersData);
      }
    } catch (e) {
      throw Exception('Failed to save quiz results: $e');
    }
  }

  /// Fetches user's incorrect answers for review
  Future<List<Question>> fetchIncorrectAnswers({int limit = 30}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get question IDs where user answered incorrectly
      final incorrectAnswers = await _supabase
          .from('quiz_answers')
          .select('question_id')
          .eq('user_id', userId)
          .eq('is_correct', false)
          .limit(limit * 2);

      if (incorrectAnswers.isEmpty) {
        return [];
      }

      // Extract unique question IDs
      final questionIds = (incorrectAnswers as List)
          .map((answer) => answer['question_id'] as int)
          .toSet()
          .toList();

      if (questionIds.isEmpty) {
        return [];
      }

      // Fetch the actual questions
      final questionsResponse = await _supabase
          .from('questions')
          .select('*, subtopics(*)')
          .filter('id', 'in', questionIds);

      final List<Question> questions = (questionsResponse as List)
          .map((json) => Question.fromJson(json))
          .toList();

      questions.shuffle();
      return questions.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch incorrect answers: $e');
    }
  }

  /// Fetches custom quiz questions based on selected parameters
  /// Uses true randomization by fetching from multiple random positions in the database
  /// Parameters:
  /// - numberOfQuestions: Number of questions to fetch
  /// - selectedTopicIds: List of topic IDs to filter by (empty = all topics)
  /// - difficultyLevel: Optional difficulty filter (1-3)
  /// - shuffleQuestions: Whether to randomize question order (default: true)
  Future<List<Question>> fetchCustomQuiz({
    required int numberOfQuestions,
    List<int>? selectedTopicIds, // These are now Theory Chapter IDs
    int? difficultyLevel,
  }) async {
    // Delegate to the official exam simulation if no filters are applied
    if (numberOfQuestions == 30 &&
        (selectedTopicIds == null || selectedTopicIds.isEmpty) &&
        difficultyLevel == null) {
      return fetchRandomQuestions();
    }

    try {
      // ====================================================
      // STEP 1: RESOLVE THEORY CHAPTERS TO SUBTOPICS
      // Path: theory_chapters -> theory_cards -> subtopic
      // ====================================================
      List<int>? allowedSubtopicIds;
      print('🔍 Fetching custom quiz with parameters: numberOfQuestions=$numberOfQuestions, selectedTheoryChapterIds=$selectedTopicIds, difficultyLevel=$difficultyLevel');

      if (selectedTopicIds != null && selectedTopicIds.isNotEmpty) {
        // Query theory_cards that belong to the selected theory chapters
        final theoryCardsResponse = await _supabase
            .from('theory_cards')
            .select('subtopic_id')
            .inFilter('chapter_id', selectedTopicIds)
            .not('subtopic_id', 'is', null); // Ensure we don't grab empty links

        // Use a Set to extract unique subtopic IDs 
        // (in case multiple theory cards share the same subtopic)
        final Set<int> uniqueSubtopicIds = {};
        for (var card in theoryCardsResponse as List) {
          if (card['subtopic_id'] != null) {
            uniqueSubtopicIds.add(card['subtopic_id'] as int);
          }
        }

        allowedSubtopicIds = uniqueSubtopicIds.toList();

        if (allowedSubtopicIds.isEmpty) {
          throw Exception('No content found for the selected theory chapters.');
        }
      }

      // ====================================================
      // STEP 2: FETCH CANDIDATE IDs (Lightweight Query)
      // ====================================================
      // We only fetch the 'id' column. This is very fast even for 10k+ rows.
      print('📊 Fetching candidate question IDs with filters: allowedSubtopicIds=$allowedSubtopicIds, difficultyLevel=$difficultyLevel');
      var idQuery = _supabase.from('questions').select('id');

      // Filter by Subtopics (if specific chapters were selected)
      if (allowedSubtopicIds != null) {
        idQuery = idQuery.inFilter('subtopic_id', allowedSubtopicIds);
      }

      // Filter by Difficulty
      if (difficultyLevel != null) {
        idQuery = idQuery.eq('difficulty_level', difficultyLevel);
      }

      final List<dynamic> idResponse = await idQuery;

      if (idResponse.isEmpty) {
        throw Exception('No questions available with these criteria.');
      }

      // Extract just the integers
      List<int> allCandidateIds = idResponse.map((row) => row['id'] as int).toList();

      print('🔢 Total candidate question IDs fetched: ${allCandidateIds.length}');

      // ====================================================
      // STEP 3: SHUFFLE & SELECT (True Randomness)
      // ====================================================
      // This ensures every single question has the exact same probability
      // of being selected.

      print('🎲 Shuffling candidate question IDs for true randomness.');
      allCandidateIds.shuffle();

      print('🎲 Total candidate questions after filtering: ${allCandidateIds.length}. Selecting $numberOfQuestions for the quiz.');
      
      // Take the first N questions (or fewer if we don't have enough)
      final countToFetch = allCandidateIds.length < numberOfQuestions
          ? allCandidateIds.length
          : numberOfQuestions;

      final targetIds = allCandidateIds.sublist(0, countToFetch);

      print('🎯 Selected question IDs for the quiz: $targetIds');

      // ====================================================
      // STEP 4: FETCH FULL DATA (Heavy Query)
      // ====================================================
      // Now we fetch the heavy data (text, images) for ONLY the winners.
      final fullDataResponse = await _supabase
          .from('questions')
          .select('*, subtopics(*)') // Get subtopic details too if needed
          .inFilter('id', targetIds);

      print('✅ Fetched full data for selected questions. Total fetched: ${(fullDataResponse as List).length}');

      // ====================================================
      // STEP 5: MAP TO OBJECTS
      // ====================================================
      // Note: The database might return these in ID order (e.g. 1, 5, 9),
      // so we shuffle one last time to randomize the display order.
      final List<Question> finalQuestions = (fullDataResponse as List)
          .map((json) => Question.fromJson(json))
          .toList();

      finalQuestions.shuffle();

      print('🔚 Returning final shuffled questions for the quiz.');
      return finalQuestions;

    } catch (e) {
      // Log error internally if needed
      throw Exception('Failed to generate quiz: $e');
    }
  }
  /// Saves custom quiz results to the database
  /// Similar to saveQuizResults but with additional validation for custom quizzes
  Future<void> saveCustomQuizResults({
    required List<Question> questions,
    required Map<int, bool> userAnswers,
    required int durationSeconds,
    List<int>? selectedTopicIds,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Calculate results
      int errorsCount = 0;
      
      for (int i = 0; i < questions.length; i++) {
        final userAnswer = userAnswers[i];
        if (userAnswer != null) {
          if (userAnswer != questions[i].isTrue) {
            errorsCount++;
          }
        } else {
          // Unanswered questions count as errors
          errorsCount++;
        }
      }

      // Calculate pass status based on Italian exam rules (max 4 errors out of 30)
      // For custom quizzes, scale proportionally
      final maxAllowedErrors = (questions.length * 4) ~/ 30;
      final isPassed = errorsCount <= maxAllowedErrors;

      // Create quiz session
      final sessionResponse = await _supabase
          .from('quiz_sessions')
          .insert({
            'user_id': userId,
            'mode': 'topic', // Custom quizzes use topic mode
            'total_questions': questions.length,
            'errors_count': errorsCount,
            'is_passed': isPassed,
            'duration_seconds': durationSeconds,
          })
          .select()
          .single();

      final sessionId = sessionResponse['id'] as String;

      // Prepare batch insert for answers
      final List<Map<String, dynamic>> answersData = [];
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        final userAnswer = userAnswers[i];
        
        final isCorrect = userAnswer != null && userAnswer == question.isTrue;
        
        answersData.add({
          'session_id': sessionId,
          'user_id': userId,
          'question_id': question.id,
          'selected_true': userAnswer ?? false, // Default to false if unanswered
          'is_correct': isCorrect,
        });
      }

      // Batch insert all answers
      if (answersData.isNotEmpty) {
        await _supabase.from('quiz_answers').insert(answersData);
      }
    } catch (e) {
      throw Exception('Failed to save custom quiz results: $e');
    }
  }

  /// Helper method to convert QuizMode enum to string
  String _modeToString(QuizMode mode) {
    switch (mode) {
      case QuizMode.simulation:
        return 'simulation';
      case QuizMode.topic:
        return 'topic';
      case QuizMode.reviewErrors:
        return 'review_errors';
    }
  }
}
