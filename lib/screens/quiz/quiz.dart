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
          if (quiz['randomizeQuestions'] == true) {
            questions.shuffle();
          }
          Navigator.pushNamed(
            context,
            '/quiz/start',
            arguments: {
              'title':              quiz['title'],
              'numberOfQuestions':  quiz['questionCount'] ?? questions.length,
              'mode':               quiz['mode']          ?? 'Multiple Choice',
              'identificationMode': quiz['identificationMode'] ?? 'Definition',
              'gameMode':           quiz['gameMode']      ?? 'Classic',
              'timeLimitSecs':      quiz['timeLimitSecs'],
              'randomizeQuestions': quiz['randomizeQuestions'] ?? false,
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

  // [SORT] Show custom sort bottom sheet
  Future<void> _showSortSheet() async {
    final options = [
      _SortOption(value: 'newest', label: 'Newest First', icon: Icons.arrow_downward_rounded),
      _SortOption(value: 'oldest', label: 'Oldest First', icon: Icons.arrow_upward_rounded),
      _SortOption(value: 'alpha',  label: 'A → Z',        icon: Icons.sort_by_alpha_rounded),
      _SortOption(value: 'reverse_alpha',  label: 'Z → A',        icon: Icons.sort_by_alpha_rounded),
    ];

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.secondary_50,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.text_200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet title
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 16),
                child: Text(
                  'Sort Quizzes',
                  style: TextStyle(
                    fontFamily: 'Baloo',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text_700,
                  ),
                ),
              ),

              // Options
              ...options.map((opt) {
                final isActive = _sortBy == opt.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: isActive
                        ? AppColors.primary_600
                        : AppColors.secondary_100,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(ctx, opt.value),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? AppColors.primary_600
                                : AppColors.secondary_300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              opt.icon,
                              size: 20,
                              color: isActive
                                  ? Colors.white
                                  : AppColors.text_500,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              opt.label,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isActive
                                    ? Colors.white
                                    : AppColors.text_700,
                              ),
                            ),
                            const Spacer(),
                            if (isActive)
                              const Icon(
                                Icons.check_circle_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selected != null) setState(() => _sortBy = selected);
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = _sortedQuizzes;

    return Scaffold(
      backgroundColor: AppColors.secondary_50,
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Baloo',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            children: [
              const TextSpan(text: 'My Quizzes '),
              TextSpan(
                text: '(${_quizzes.length})',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
      color: AppColors.secondary_50,
      child: Row(
        children: [
          // [BUTTON] Sort Menu
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showSortSheet,
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
                backgroundColor: AppColors.secondary_100,
                foregroundColor: AppColors.text_700,
                elevation: 1,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.secondary_300),
                ),
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
                elevation: 1,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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

// [MODEL] Sort option data
class _SortOption {
  final String value;
  final String label;
  final IconData icon;
  const _SortOption({required this.value, required this.label, required this.icon});
}