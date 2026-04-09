// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Screens
import 'package:soro/screens/quiz_settings.dart';

// [IMPORT] Widgets
import 'package:soro/widgets/quiz/quiz_card.dart';
import 'package:soro/widgets/quiz/quiz_detail_sheet.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

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
        onDelete: () {
          Navigator.pop(context);
          _deleteQuiz(quiz['id'] as String, quiz['title'] as String);
        },
        onPlay: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuizSettings()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizzes = _sortedQuizzes;

    return Scaffold(
      backgroundColor: AppColors.secondary_100,
      body: SafeArea(
        child: Column(
          children: [
            // [COMPONENT] Header
            _buildHeader(),

            // [COMPONENT] Quiz list or empty state
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
          ],
        ),
      ),
    );
  }

  // [WIDGET] Top header row — title, count, sort, add button
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // [TEXT] Title + quiz count
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Baloo',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text_800,
                ),
                children: [
                  const TextSpan(text: 'My Quizzes '),
                  TextSpan(
                    text: '(${_quizzes.length})',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text_400,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // [BUTTON] Sort menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: AppColors.text_500),
            tooltip: 'Sort by',
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'newest', child: Text('Newest first')),
              PopupMenuItem(value: 'oldest', child: Text('Oldest first')),
              PopupMenuItem(value: 'alpha',  child: Text('A → Z')),
            ],
          ),

          // [BUTTON] Create new quiz
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: AppColors.primary_600,
              size: 28,
            ),
            tooltip: 'Create Quiz',
            onPressed: _createQuiz,
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
            'Tap + to create your first quiz',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: AppColors.text_300,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _createQuiz,
            icon:  const Icon(Icons.add),
            label: const Text('Create Quiz'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary_600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}