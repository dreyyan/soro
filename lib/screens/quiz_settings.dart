// [IMPORT] Libraries
import 'package:flutter/material.dart';
import 'dart:math';

// [IMPORT] Hive
import 'package:hive/hive.dart';

// [IMPORT] Classes
import '../models/question.dart';

class QuizSettings extends StatefulWidget {
  const QuizSettings({super.key});

  @override
  State<QuizSettings> createState() => _QuizSettingsState();
}

class _QuizSettingsState extends State<QuizSettings> {
  // [STATES] Quiz Settings
  int numberOfQuestions = 5;
  String selectedMode = "Multiple Choice";
  String identificationAnswerMode = "Definition";
  String selectedGameMode = "Classic";
  List<Question> questions = [];

  // [CONTROLLER] For pasting questions
  final TextEditingController questionsController = TextEditingController();

  // [OPTIONS] Quiz Modes
  final List<String> modes = ["Multiple Choice", "Identification", "True or False"];

  // [OPTIONS] Identification Modes
  final List<String> identificationModes = [
    "Term",
    "Definition",
    "Both",
  ];

  // [OPTIONS] Game Modes
  final List<String> gameModes = ["Classic", "Time Attack"];

  // [DATABASE] Hive box for quiz settings
  late Box settingsBox;

  @override
  void initState() {
    super.initState();
    _initHive(); // [INIT] Hive and load saved settings
  }

  // [INIT] Open Hive box
  void _initHive() async {
    settingsBox = await Hive.openBox('quiz_settings');
    _loadSavedSettings();
  }

  // [GET] Load saved quiz settings
  void _loadSavedSettings() {
    final saved = settingsBox.get('settings');
    if (saved != null) {
      final Map<String, dynamic> savedMap = Map<String, dynamic>.from(saved);
      setState(() {
        numberOfQuestions = savedMap['numberOfQuestions'] ?? 5;
        selectedMode = savedMap['mode'] ?? "Multiple Choice";
        identificationAnswerMode = savedMap['identificationMode'] ?? "Definition";
        selectedGameMode = savedMap['gameMode'] ?? "Classic";
      });
    }
  }

  // [POST] Save quiz settings
  Future<void> _saveSettings() async {
    await settingsBox.put('settings', {
      'numberOfQuestions': numberOfQuestions,
      'mode': selectedMode,
      'identificationMode': identificationAnswerMode,
      'gameMode': selectedGameMode,
    });
  }

  // [FUNCTION] Parse pasted Q&A text into Question objects
  void _parseQuestions() {
    questions.clear();
    final lines = questionsController.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (int i = 0; i < lines.length - 1; i++) {
      final currentLine = lines[i];
      final nextLine = lines[i + 1];

      if (nextLine.startsWith('-')) {
        final q = currentLine;
        final a = nextLine.substring(1).trim();
        if (q.isNotEmpty && a.isNotEmpty) {
          questions.add(Question(q, a));
        }
        i++; // Skip the answer line
      }
    }
  }

  // [FUNCTION] Show error dialog
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    questionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Quiz Settings"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // [INPUT] Number of questions
            Text(
              "Number of Questions",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: numberOfQuestions,
              isExpanded: true,
              items: [5, 10, 15, 20]
                  .map((num) => DropdownMenuItem(value: num, child: Text("$num")))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => numberOfQuestions = value);
              },
            ),
            const SizedBox(height: 24),

            // [INPUT] Quiz mode
            Text(
              "Mode",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedMode,
              isExpanded: true,
              items: modes
                  .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedMode = value);
              },
            ),
            const SizedBox(height: 24),

            // [INPUT] Identification answer mode
            if (selectedMode == "Identification") ...[
              Text(
                "Answer Type",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: identificationAnswerMode,
                isExpanded: true,
                items: identificationModes
                    .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => identificationAnswerMode = value);
                  }
                },
              ),
              const SizedBox(height: 24),
            ],

            // [INPUT] Game mode
            Text(
              "Game Mode",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedGameMode,
              isExpanded: true,
              items: gameModes
                  .map((mode) => DropdownMenuItem(value: mode, child: Text(mode)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedGameMode = value);
              },
            ),
            const SizedBox(height: 24),

            // [INPUT] Pasteable Q&A field
            Text(
              "Paste Questions (Q / -A format):",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: questionsController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Mitochondria\n- powerhouse of the cell\nCell\n- basic unit of life",
                ),
              ),
            ),
            const SizedBox(height: 16),

            // [BUTTON] Start Quiz
            ElevatedButton(
              onPressed: () async {
                _parseQuestions(); // Convert text to Question objects

                // [VALIDATION] Not enough questions
                if (questions.length < numberOfQuestions) {
                  _showError(
                    "You only provided ${questions.length} questions. Please add at least $numberOfQuestions.",
                  );
                  return;
                }

                // [PROCESS] If more questions, shuffle and take only needed amount
                if (questions.length > numberOfQuestions) {
                  questions.shuffle(Random());
                  questions = questions.take(numberOfQuestions).toList();
                }

                await _saveSettings(); // Save settings to Hive
                
                Navigator.pushNamed(
                  context,
                  '/quiz/start',
                  arguments: {
                    "numberOfQuestions": numberOfQuestions,
                    "mode": selectedMode,
                    "identificationMode": identificationAnswerMode,
                    "gameMode": selectedGameMode,
                    "questions": questions
                        .map((q) => {
                              "question": q.question,
                              "answer": q.answer,
                              "choices": q.choices,
                            })
                        .toList(),
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: const Text("Start Quiz"),
            ),
          ],
        ),
      ),
    );
  }
}