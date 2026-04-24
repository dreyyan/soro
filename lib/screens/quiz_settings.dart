// [IMPORT] Libraries
import 'package:flutter/material.dart';
import 'dart:math';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

// [IMPORT] Models
import 'package:soro/models/question.dart';

class QuizSettings extends StatefulWidget {
  const QuizSettings({super.key});

  @override
  State<QuizSettings> createState() => _QuizSettingsState();
}

class _QuizSettingsState extends State<QuizSettings> {
  // [STATES] Quiz settings
  int numberOfQuestions = 5;
  String selectedMode = "Multiple Choice";
  String identificationAnswerMode = "Definition";
  String selectedGameMode = "Classic";
  List<Question> questions = [];

  // [CONTROLLER] Pasteable Q&A input
  final TextEditingController titleController = TextEditingController();
  final TextEditingController questionsController = TextEditingController();

  // [OPTIONS] Available quiz modes
  final List<String> modes = [
    "Multiple Choice",
    "Identification",
    "True or False",
  ];

  // [OPTIONS] Identification answer direction modes
  final List<String> identificationModes = [
    "Term",
    "Definition",
    "Both",
  ];

  // [OPTIONS] Game modes
  final List<String> gameModes = ["Classic", "Time Attack"];

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  @override
  void dispose() {
    titleController.dispose();
    questionsController.dispose();
    super.dispose();
  }

  // [LOAD] Fetch previously saved quiz settings from Hive
  Future<void> _loadSavedSettings() async {
    final saved = await DatabaseHelper().getQuizSettings();
    if (saved == null) return;
    setState(() {
      numberOfQuestions        = saved['numberOfQuestions']  ?? 5;
      selectedMode             = saved['mode']               ?? "Multiple Choice";
      identificationAnswerMode = saved['identificationMode'] ?? "Definition";
      selectedGameMode         = saved['gameMode']           ?? "Classic";
    });
  }

  // [SAVE] Persist current quiz settings to Hive
  Future<void> _saveSettings() async {
    await DatabaseHelper().saveQuizSettings({
      'numberOfQuestions':  numberOfQuestions,
      'mode':               selectedMode,
      'identificationMode': identificationAnswerMode,
      'gameMode':           selectedGameMode,
    });
  }

  // [PARSE] Convert pasted Q / -A text into Question objects
  void _parseQuestions() {
    questions.clear();
    final lines = questionsController.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (int i = 0; i < lines.length - 1; i++) {
      final currentLine = lines[i];
      final nextLine    = lines[i + 1];

      if (nextLine.startsWith('-')) {
        final q = currentLine;
        final a = nextLine.substring(1).trim();
        if (q.isNotEmpty && a.isNotEmpty) {
          questions.add(Question(q, a));
        }
        i++; // [SKIP] Jump over the answer line
      }
    }
  }

  // [ERROR] Show a simple error dialog
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // [CREATE] Validate, parse, save quiz to DB, then pop back to Quiz screen
  Future<void> _createQuiz() async {
    final title = titleController.text.trim();

    // [VALIDATION] Title required
    if (title.isEmpty) {
      _showError("Please enter a quiz title.");
      return;
    }

    _parseQuestions();

    // [VALIDATION] Ensure enough questions were provided
    if (questions.length < numberOfQuestions) {
      _showError(
        "You only provided ${questions.length} question${questions.length == 1 ? '' : 's'}. "
        "Please add at least $numberOfQuestions.",
      );
      return;
    }

    // [PROCESS] Shuffle and trim to the requested count
    if (questions.length > numberOfQuestions) {
      questions.shuffle(Random());
      questions = questions.take(numberOfQuestions).toList();
    }

    await _saveSettings();

    // [SAVE] Persist quiz to the user's saved quizzes list
    await DatabaseHelper().addSavedQuiz({
      'id':            DateTime.now().millisecondsSinceEpoch.toString(),
      'title':         title,
      'description':   '',
      'createdAt':     DateTime.now().toIso8601String(),
      'questionCount': questions.length,
      'mode':          selectedMode,
      'gameMode':      selectedGameMode,
      'identificationMode': identificationAnswerMode,
      'deckTitle':     '—',
      'timeLimitSecs': selectedGameMode == "Time Attack" ? 120 : null,
      'questions': questions
          .map((q) => {
                'question': q.question,
                'answer':   q.answer,
                'choices':  q.choices,
              })
          .toList(),
    });

    if (!mounted) return;

    // [NAVIGATE] Return to Quiz screen so the new quiz appears in the list
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create Quiz",
          style: TextStyle(fontFamily: 'Baloo', fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.primary_600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // [INPUT] Quiz title
            _buildLabel("Quiz Title"),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: "e.g. Biology Chapter 3",
                filled: true,
                fillColor: AppColors.secondary_100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // [INPUT] Number of questions
            _buildLabel("Number of Questions"),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: numberOfQuestions,
              isExpanded: true,
              items: [5, 10, 15, 20]
                  .map((n) => DropdownMenuItem(value: n, child: Text("$n")))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => numberOfQuestions = val);
              },
            ),
            const SizedBox(height: 24),

            // [INPUT] Quiz mode
            _buildLabel("Mode"),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedMode,
              isExpanded: true,
              items: modes
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedMode = val);
              },
            ),
            const SizedBox(height: 24),

            // [INPUT] Identification answer type (only when mode is Identification)
            if (selectedMode == "Identification") ...[
              _buildLabel("Answer Type"),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: identificationAnswerMode,
                isExpanded: true,
                items: identificationModes
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => identificationAnswerMode = val);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],

            // [INPUT] Game mode
            _buildLabel("Game Mode"),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedGameMode,
              isExpanded: true,
              items: gameModes
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedGameMode = val);
              },
            ),
            const SizedBox(height: 24),

            // [INPUT] Pasteable Q&A text field
            _buildLabel("Paste Questions (Q / -A format):"),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: questionsController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText:
                      "Mitochondria\n- powerhouse of the cell\nCell\n- basic unit of life",
                  hintStyle: TextStyle(
                  color: AppColors.text_400, 
                  ),// hint text color (gray)
                ),
              ),
            ),
            const SizedBox(height: 16),

            // [BUTTON] Create Quiz
            ElevatedButton(
              onPressed: _createQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary_600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
              child: const Text(
                "Create Quiz",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [WIDGET] Section label text
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Nunito',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.text_700,
      ),
    );
  }
}