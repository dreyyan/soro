// [IMPORT] Libraries
import 'package:flutter/material.dart';
import 'dart:math';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

// [IMPORT] Models
import 'package:soro/models/question.dart';

class QuizEdit extends StatefulWidget {
  final Map<String, dynamic> quiz; // [PROP] Existing quiz to edit

  const QuizEdit({super.key, required this.quiz});

  @override
  State<QuizEdit> createState() => _QuizEditState();
}

class _QuizEditState extends State<QuizEdit> {
  // [STATES] Pre-filled from existing quiz
  late int numberOfQuestions;
  late String selectedMode;
  late String identificationAnswerMode;
  late String selectedGameMode;
  late int timeLimitSeconds;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController questionsController = TextEditingController();
  List<Question> questions = [];

  final List<String> modes = ["Multiple Choice", "Identification", "True or False"];
  final List<String> identificationModes = ["Term", "Definition", "Both"];
  final List<String> gameModes = ["Classic", "Time Attack"];

  @override
  void initState() {
    super.initState();
    final q = widget.quiz;

    // [PREFILL] Load existing quiz values
    titleController.text       = q['title']             as String? ?? '';
    numberOfQuestions          = q['questionCount']      as int?    ?? 5;
    selectedMode               = q['mode']               as String? ?? 'Multiple Choice';
    identificationAnswerMode   = q['identificationMode'] as String? ?? 'Definition';
    selectedGameMode           = q['gameMode']           as String? ?? 'Classic';
    timeLimitSeconds           = q['timeLimitSecs']      as int?    ?? 120;

    // [PREFILL] Rebuild Q/-A text from saved questions
    final saved = (q['questions'] as List? ?? []).cast<Map<String, dynamic>>();
    questionsController.text = saved
        .map((e) => '${e['question']}\n-${e['answer']}')
        .join('\n');
  }

  @override
  void dispose() {
    titleController.dispose();
    questionsController.dispose();
    super.dispose();
  }

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
        if (q.isNotEmpty && a.isNotEmpty) questions.add(Question(q, a));
        i++;
      }
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("OK")),
        ],
      ),
    );
  }

  // [SAVE] Overwrite the existing quiz (same id, same createdAt)
  Future<void> _saveQuiz() async {
    final title = titleController.text.trim();
    if (title.isEmpty) { _showError("Please enter a quiz title."); return; }

    _parseQuestions();

    if (questions.length < numberOfQuestions) {
      _showError(
        "You only provided ${questions.length} question${questions.length == 1 ? '' : 's'}. "
        "Please add at least $numberOfQuestions.",
      );
      return;
    }

    if (questions.length > numberOfQuestions) {
      questions.shuffle(Random());
      questions = questions.take(numberOfQuestions).toList();
    }

    // [UPDATE] Keep original id and createdAt, overwrite everything else
    await DatabaseHelper().updateSavedQuiz({
      'id':                widget.quiz['id'],
      'title':             title,
      'description':       '',
      'createdAt':         widget.quiz['createdAt'],
      'questionCount':     questions.length,
      'mode':              selectedMode,
      'gameMode':          selectedGameMode,
      'identificationMode': identificationAnswerMode,
      'deckTitle':         '—',
      'timeLimitSecs':     selectedGameMode == "Time Attack" ? timeLimitSeconds : null,
      'questions': questions
          .map((q) => {'question': q.question, 'answer': q.answer, 'choices': q.choices})
          .toList(),
    });

    if (!mounted) return;
    Navigator.pop(context); // [NAVIGATE] Back to Quiz list
  }

  String _formatDuration(int seconds) {
    if (seconds >= 60 && seconds % 60 == 0) return "${seconds ~/ 60} min";
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  Widget _buildTimePreset(int seconds, String label) {
    final isSelected = timeLimitSeconds == seconds;
    return ChoiceChip(
      label: Text(label, style: TextStyle(
        fontFamily: 'Nunito', fontSize: 12,
        color: isSelected ? Colors.white : AppColors.text_700,
      )),
      selected: isSelected,
      onSelected: (_) => setState(() => timeLimitSeconds = seconds),
      selectedColor: AppColors.primary_600,
      backgroundColor: AppColors.secondary_50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.primary_600 : AppColors.text_200),
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Nunito', fontSize: 16,
      fontWeight: FontWeight.w600, color: AppColors.text_700,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_50,
      appBar: AppBar(
        title: const Text("Edit Quiz",
            style: TextStyle(fontFamily: 'Baloo', fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary_600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            _buildLabel("Number of Questions"),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: numberOfQuestions,
              isExpanded: true,
              items: [5, 10, 15, 20]
                  .map((n) => DropdownMenuItem(value: n, child: Text("$n")))
                  .toList(),
              onChanged: (val) { if (val != null) setState(() => numberOfQuestions = val); },
            ),
            const SizedBox(height: 24),

            _buildLabel("Mode"),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedMode,
              isExpanded: true,
              items: modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) { if (val != null) setState(() => selectedMode = val); },
            ),
            const SizedBox(height: 24),

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
                  if (val != null) setState(() => identificationAnswerMode = val);
                },
              ),
              const SizedBox(height: 24),
            ],

            _buildLabel("Game Mode"),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedGameMode,
              isExpanded: true,
              items: gameModes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (val) { if (val != null) setState(() => selectedGameMode = val); },
            ),
            const SizedBox(height: 24),

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
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: timeLimitSeconds.toDouble(),
                            min: 30, max: 600, divisions: 19,
                            label: _formatDuration(timeLimitSeconds),
                            onChanged: (val) => setState(() => timeLimitSeconds = val.round()),
                            activeColor: AppColors.primary_600,
                            inactiveColor: AppColors.text_200,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary_100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_formatDuration(timeLimitSeconds),
                            style: const TextStyle(
                              fontFamily: 'Nunito', fontWeight: FontWeight.w700,
                              color: AppColors.primary_700, fontSize: 14,
                            )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      _buildTimePreset(60, "1 min"),
                      _buildTimePreset(120, "2 min"),
                      _buildTimePreset(180, "3 min"),
                      _buildTimePreset(300, "5 min"),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildLabel("Paste Questions (Q / -A format):"),
            const SizedBox(height: 8),
            TextField(
              controller: questionsController,
              keyboardType: TextInputType.multiline,
              minLines: 6,
              maxLines: null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Powerhouse of the Cell\n- Mitochondria\nBasic Unit of Life\n- Cell",
                hintStyle: TextStyle(color: AppColors.text_400),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saveQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary_600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
              ),
              child: const Text("Save Changes",
                style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}