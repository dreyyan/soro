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
  int numberOfQuestions = 0;
  String selectedMode = "Multiple Choice";
  String identificationAnswerMode = "Definition";
  String selectedGameMode = "Classic";
  int timeLimitSeconds = 120;
  List<Question> questions = [];

  // [CONTROLLER] Pasteable Q&A input
  final TextEditingController titleController = TextEditingController();
  final TextEditingController questionsController = TextEditingController();
  final TextEditingController numberOfQuestionsController = TextEditingController();

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
    numberOfQuestionsController.dispose();
    super.dispose();
  }

  // [LOAD] Fetch previously saved quiz settings from Hive
  Future<void> _loadSavedSettings() async {
    final saved = await DatabaseHelper().getQuizSettings();
    if (saved == null) return;
    setState(() {
      numberOfQuestions        = 0;
      selectedMode             = saved['mode']               ?? "Multiple Choice";
      identificationAnswerMode = saved['identificationMode'] ?? "Definition";
      selectedGameMode         = saved['gameMode']           ?? "Classic";
      timeLimitSeconds         = saved['timeLimitSeconds']   ?? 120;
    });
  }

  // [SAVE] Persist current quiz settings to Hive
  Future<void> _saveSettings() async {
    await DatabaseHelper().saveQuizSettings({
      'numberOfQuestions':  numberOfQuestions,
      'mode':               selectedMode,
      'identificationMode': identificationAnswerMode,
      'gameMode':           selectedGameMode,
      'timeLimitSeconds':   selectedGameMode == "Time Attack" ? timeLimitSeconds : null,
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
      'timeLimitSecs': selectedGameMode == "Time Attack" ? timeLimitSeconds : null,
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

  // [HELPER] Format seconds into readable time string
String _formatDuration(int seconds) {
  if (seconds >= 60 && seconds % 60 == 0) {
    return "${seconds ~/ 60} min";
  }
  final mins = (seconds ~/ 60).toString().padLeft(2, '0');
  final secs = (seconds % 60).toString().padLeft(2, '0');
  return "$mins:$secs";
}

// [WIDGET] Quick-select time preset button
Widget _buildTimePreset(int seconds, String label) {
  final isSelected = timeLimitSeconds == seconds;
  return ChoiceChip(
    label: Text(
      label,
      style: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 12,
        color: isSelected ? Colors.white : AppColors.text_700,
      ),
    ),
    selected: isSelected,
    onSelected: (_) {
      setState(() => timeLimitSeconds = seconds);
    },
    selectedColor: AppColors.primary_600,
    backgroundColor: AppColors.secondary_50,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: isSelected ? AppColors.primary_600 : AppColors.text_200,
      ),
    ),
  );
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.secondary_50,
    appBar: AppBar(
      title: const Text(
        "Create Quiz",
        style: TextStyle(fontFamily: 'Baloo', fontWeight: FontWeight.w700),
      ),
      backgroundColor: AppColors.primary_600,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    // [FIX] Use SingleChildScrollView to prevent overflow and compression
    body: SingleChildScrollView(
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
              hintStyle: TextStyle(color: AppColors.text_400),
              filled: true,
              fillColor: AppColors.secondary_100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.secondary_100,
    borderRadius: BorderRadius.circular(12),
  ),
  child: Row(
    children: [
      // [INPUT] Editable number field
      Expanded(
        child: TextField(
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter number of Questions',
            hintStyle: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              color: AppColors.text_300,
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.text_700,
          ),
          controller: numberOfQuestionsController,
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null && parsed >= 1) {
              setState(() => numberOfQuestions = parsed);
            }
          },
        ),
      ),
      // [ARROWS] Up / Down
      Column(
        children: [
          GestureDetector(
  onTap: () {
  setState(() {
    numberOfQuestions++;
    numberOfQuestionsController.text = '$numberOfQuestions';
  });
},
            child: const Icon(Icons.arrow_drop_up, size: 28, color: AppColors.primary_600),
          ),
          GestureDetector(
  onTap: () {
    if (numberOfQuestions > 1) {
      setState(() => numberOfQuestions--);
      numberOfQuestionsController.text = '$numberOfQuestions';
    }
  },
            child: const Icon(Icons.arrow_drop_down, size: 28, color: AppColors.primary_600),
          ),
        ],
      ),
    ],
  ),
),

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

          // [INPUT] Identification answer type
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

// [INPUT] Time Limit (only for Time Attack mode)
          if (selectedGameMode == "Time Attack") ...[
            _buildLabel("Time Limit"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary_100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.text_200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [SLIDER] 30s to 600s (10 minutes)
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: timeLimitSeconds.toDouble(),
                          min: 30,
                          max: 600,
                          divisions: 19,
                          label: _formatDuration(timeLimitSeconds),
                          onChanged: (val) {
                            setState(() => timeLimitSeconds = val.round());
                          },
                          activeColor: AppColors.primary_600,
                          inactiveColor: AppColors.text_200,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // [DISPLAY] Current time value
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary_100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDuration(timeLimitSeconds),
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary_700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // [PRESETS] Quick-select buttons
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTimePreset(60, "1 min"),
                      _buildTimePreset(120, "2 min"),
                      _buildTimePreset(180, "3 min"),
                      _buildTimePreset(300, "5 min"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // [INPUT] Pasteable Q&A text field
          _buildLabel("Paste Questions (Q / -A format):"),
          const SizedBox(height: 8),
          // [FIX] Removed Expanded. Added minLines and maxLines instead.
          TextField(
            controller: questionsController,
            keyboardType: TextInputType.multiline,
            minLines: 6, // Set a base height
            maxLines: null, // Allow it to grow downward
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText:
                  "Powerhouse of the Cell\n- Mitochondria\nBasic Unit of Life\n- Cell",
              hintStyle: TextStyle(
                color: AppColors.text_400,
              ),
            ),
          ),
          const SizedBox(height: 32),

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
          // Extra space at bottom to ensure the button isn't cramped
          //const SizedBox(height: 24),
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