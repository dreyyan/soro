// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Screens
import 'package:soro/screens/quiz/quiz_settings.dart';

// [IMPORT] Widgets
import 'package:soro/widgets/quiz/quiz_card.dart';
import 'package:soro/widgets/quiz/quiz_detail_sheet.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

import 'package:soro/screens/quiz/quiz_edit.dart';

class Quiz extends StatefulWidget {
  const Quiz({super.key});

  @override
  State<Quiz> createState() => _QuizState();
}

class _QuizState extends State<Quiz> {
  // [STATES]
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  // [LOAD] Fetch saved quizzes for the logged-in user
  Future<void> _loadQuizzes() async {
    final quizzes = await DatabaseHelper().getSavedQuizzes();
    if (!mounted) return;

    // [RESOLVE] Override mode to "Mixed" if questions span multiple types
    for (final quiz in quizzes) {
      final questions =
          (quiz['questions'] as List? ?? []).cast<Map<String, dynamic>>();
      if (questions.isNotEmpty) {
        final types = questions
            .map((q) => q['type'] as String? ?? '')
            .toSet();
        if (types.length > 1) quiz['mode'] = 'Mixed';
      }
    }

    setState(() {
      _quizzes   = quizzes;
      _isLoading = false;
    });
  }

  // [SORT] Return a sorted copy of _quizzes based on _sortBy
  List<Map<String, dynamic>> get _sortedQuizzes {
    final copy = List<Map<String, dynamic>>.from(_quizzes);
    switch (_sortBy) {
      case 'oldest':
        copy.sort((a, b) =>
            (a['createdAt'] as String).compareTo(b['createdAt'] as String));
        break;
      case 'alpha':
        copy.sort((a, b) =>
            (a['title'] as String).compareTo(b['title'] as String));
        break;
      case 'newest':
      default:
        copy.sort((a, b) =>
            (b['createdAt'] as String).compareTo(a['createdAt'] as String));
    }
    return copy;
  }

  // [NAVIGATE] Go to QuizSettings to create a new quiz
  Future<void> _createQuiz() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuizSettings()),
    );
    await _loadQuizzes();
  }

  // [DELETE] Show confirmation dialog then remove the quiz
  Future<void> _deleteQuiz(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await DatabaseHelper().deleteSavedQuiz(id);
    await _loadQuizzes();
  }

  // [OPEN] Show the QuizDetailSheet bottom sheet for a given quiz
  void _openQuizDetail(Map<String, dynamic> quiz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuizDetailSheet(
        quiz: quiz,

        // [PLAY] Navigate to QuizStart with the saved questions
        onPlay: () {
          Navigator.pop(context);
          final questions =
              (quiz['questions'] as List? ?? []).cast<Map<String, dynamic>>();
          Navigator.pushNamed(
            context,
            '/quiz/start',
            arguments: {
              'numberOfQuestions':  quiz['questionCount'] ?? questions.length,
              'mode':               quiz['mode']          ?? 'Multiple Choice',
              'identificationMode': quiz['identificationMode'] ?? 'Definition',
              'gameMode':           quiz['gameMode']      ?? 'Classic',
              'timeLimitSecs':      quiz['timeLimitSecs'],
              'questions':          questions,
            },
          );
        },

        // [EDIT] Open QuizSettings then refresh the list on return
        onEdit: (quizData) async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QuizEdit(quiz: quizData)),
          );
          await _loadQuizzes();
      },

        // [DELETE] Close sheet then run the delete confirmation flow
        onDelete: () {
          Navigator.pop(context);
          _deleteQuiz(quiz['id'] as String, quiz['title'] as String);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = _sortedQuizzes;

    return Scaffold(
      backgroundColor: AppColors.secondary_200,
      body: SafeArea(
        child: Column(
          children: [
            // [COMPONENT] Header (Title + Count only)
            _buildHeader(),

            // [COMPONENT] Quiz List / Empty State
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : quizzes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: quizzes.length,
                          itemBuilder: (ctx, i) => QuizCard(
                            quiz: quizzes[i],
                            onTap: () => _openQuizDetail(quizzes[i]),
                            onDeleted: () => _deleteQuiz(
                              quizzes[i]['id'] as String,
                              quizzes[i]['title'] as String,
                            ),
                          ),
                        ),
            ),

            // [COMPONENT] Action Buttons (Sort + Create Quiz)
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  // [WIDGET] Top Header Row — Title + Quiz Count only
  Widget _buildHeader() {
    return Material(
      color: AppColors.primary_600,
      elevation: 3,
      shadowColor: AppColors.secondary_500.withValues(alpha: 0.4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Baloo',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text_50,
            ),
            children: [
              const TextSpan(text: 'My Quizzes '),
              TextSpan(
                text: '(${_quizzes.length})',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text_100,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // [WIDGET] Bottom Action Buttons — Sort + Create Quiz
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: AppColors.secondary_200,
      child: Row(
        children: [
          // [BUTTON] Sort Menu
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final selected = await showMenu<String>(
                  context: context,
                  position: const RelativeRect.fromLTRB(60, 528, 100, 100),
                  items: const [
                    PopupMenuItem(value: 'newest', child: Text('Newest first')),
                    PopupMenuItem(value: 'oldest', child: Text('Oldest first')),
                    PopupMenuItem(value: 'alpha',  child: Text('A → Z')),
                  ],
                );
                if (selected != null) setState(() => _sortBy = selected);
              },
              icon: const Icon(Icons.sort),
              label: const Text(
                'Sort',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary_50,
                foregroundColor: AppColors.text_700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // [BUTTON] Create Quiz
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _createQuiz,
              icon: const Icon(Icons.add),
              label: const Text(
                'Create Quiz',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary_600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 1,
                padding: const EdgeInsets.symmetric(vertical: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [WIDGET] Shown when no quizzes exist yet
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.quiz_outlined, size: 64, color: AppColors.text_200),
          const SizedBox(height: 12),
          const Text(
            'No quizzes yet',
            style: TextStyle(
              fontFamily: 'Baloo',
              fontSize: 18,
              color: AppColors.text_400,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap "Create Quiz" to get started',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.text_300,
            ),
          ),
        ],
      ),
    );
  }
}