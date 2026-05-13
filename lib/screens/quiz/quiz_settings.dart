// [IMPORT] Libraries
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
//import 'dart:math';
// [IMPORT] App
import 'package:soro/main.dart';
// [IMPORT] Database
import 'package:soro/database/database_helper.dart';
// [IMPORT] Models
//import 'package:soro/models/question.dart';
// [IMPORT] PDF
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
// [IMPORT] Gemini
import 'package:google_generative_ai/google_generative_ai.dart';

// ---------------------------------------------------------------------------
// API KEY: imported from lib/config.dart (excluded from Git via .gitignore)
// ---------------------------------------------------------------------------
import 'package:soro/config.dart';
const String _geminiApiKey = geminiApiKey;

class QuizSettings extends StatefulWidget {
  const QuizSettings({super.key});
  @override
  State<QuizSettings> createState() => _QuizSettingsState();
}

class _QuizSettingsState extends State<QuizSettings> {
  // [STATES] Quiz settings
  final TextEditingController titleController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController(text: '00');
  final TextEditingController _minutesController = TextEditingController(text: '10');
  final TextEditingController _secondsController = TextEditingController(text: '00');
  bool _timerEnabled = false;
  int _hours = 0;
  int _minutes = 10;
  int _seconds = 0;
  bool _randomizeQuestions = false;

  List<QuestionItem> questions = [];

  // [OPTIONS] Question types
  final List<String> questionTypes = [
    "Multiple Choice",
    "Identification",
    "True or False",
  ];

  @override
  void dispose() {
    titleController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    for (final q in questions) {
      q.dispose();
    }
    super.dispose();
  }

  // [ADD] Add a new question
  void _addQuestion() {
    setState(() {
      questions.add(QuestionItem(
        id: DateTime.now().millisecondsSinceEpoch,
        type: questionTypes[0],
        question: '',
        correctAnswer: '',
        trueFalseAnswer: true,
      ));
    });
  }

  // [REMOVE] Remove a question
  void _removeQuestion(int index) {
    setState(() {
      questions[index].dispose();
      questions.removeAt(index);
    });
  }

  // [REORDER] Reorder questions
  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = questions.removeAt(oldIndex);
      questions.insert(newIndex, item);
    });
  }

  // [UPDATE] Update question field
  void _updateQuestion(int index, {String? type, String? question, String? answer, bool? trueFalseAnswer}) {
    setState(() {
      if (type != null) questions[index].type = type;
      if (question != null) questions[index].question = question;
      if (answer != null) questions[index].correctAnswer = answer;
      if (trueFalseAnswer != null) questions[index].trueFalseAnswer = trueFalseAnswer;
    });
  }

  // [SAVE] Save quiz to database
  Future<void> _saveQuiz() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      _showError("Please enter a quiz title.");
      return;
    }
    if (questions.isEmpty) {
      _showError("Please add at least one question.");
      return;
    }
    // [VALIDATE] Check all questions have content
    for (int i = 0; i < questions.length; i++) {
      if (questions[i].question.trim().isEmpty) {
        _showError("Question ${i + 1} is empty.");
        return;
      }
      if (questions[i].type != "True or False" && questions[i].correctAnswer.trim().isEmpty) {
        _showError("Question ${i + 1} answer is empty.");
        return;
      }
    }

    // [CALCULATE] Total seconds from picker (null if timer is off)
    final totalSeconds = _timerEnabled
        ? _hours * 3600 + _minutes * 60 + _seconds
        : null;

    // [SAVE] Persist quiz to database
    await DatabaseHelper().addSavedQuiz({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'description': '',
      'createdAt': DateTime.now().toIso8601String(),
      'questionCount': questions.length,
      'mode': questions.isNotEmpty ? questions[0].type : "Multiple Choice",
      'gameMode': 'Classic',
      'identificationMode': 'Definition',
      'deckTitle': '—',
      'timeLimitSecs': totalSeconds,
      'randomizeQuestions': _randomizeQuestions,
      'questions': questions.map((q) => {
        'question': q.question,
        'answer': q.type == "True or False"
            ? (q.trueFalseAnswer ? "True" : "False")
            : q.correctAnswer,
        'type': q.type,
        'trueFalseAnswer': q.trueFalseAnswer,
        'choices': q.choices,
      }).toList(),
    });
    if (!mounted) return;
    Navigator.pop(context);
  }

  // -------------------------------------------------------------------------
  // [PDF IMPORT] Full flow: pick → extract → Gemini → add questions
  // -------------------------------------------------------------------------
  Future<void> _importFromPdf() async {
    // Guard: make sure API key was injected
    if (_geminiApiKey.isEmpty) {
      _showError(
        "Gemini API key is not set.\n\n"
        "Run the app with:\n"
        "flutter run --dart-define=GEMINI_API_KEY=your_key_here",
      );
      return;
    }

    // [STEP 1] Pick a PDF file (withData: true so bytes are available on mobile)
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    // [STEP 2] Extract text using Syncfusion
    String extractedText;
    try {
      final PdfDocument document = PdfDocument(
        inputBytes: result.files.single.bytes!,
      );
      extractedText = PdfTextExtractor(document).extractText();
      document.dispose();
    } catch (e) {
      _showError("Could not read the PDF file.\n$e");
      return;
    }

    if (extractedText.trim().isEmpty) {
      _showError(
        "No readable text found in this PDF.\n"
        "Scanned/image-only PDFs are not supported.",
      );
      return;
    }

    // [STEP 3] Show loading dialog while calling Gemini
    _showLoadingDialog();

    try {
      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: _geminiApiKey,
      );

      // Trim text to avoid exceeding Gemini token limits
      final trimmedText = extractedText.length > 12000
          ? extractedText.substring(0, 12000)
          : extractedText;

      final prompt = '''
You are a quiz generator. Based on the text below, generate as many quiz questions as possible.
Return ONLY a valid JSON array — no explanation, no markdown, no code fences.

Each item must follow one of these exact formats:

Multiple Choice:
{ "type": "Multiple Choice", "question": "...", "answer": "...", "choices": ["...", "...", "...", "..."] }

Identification:
{ "type": "Identification", "question": "...", "answer": "..." }

True or False:
{ "type": "True or False", "question": "...", "answer": "True" }
or
{ "type": "True or False", "question": "...", "answer": "False" }

Rules:
- Mix all three types naturally based on the content.
- For Multiple Choice, the correct answer must be one of the 4 choices.
- Keep questions clear and concise.
- Do not add any text outside the JSON array.

Text:
$trimmedText
''';

      final response = await model.generateContent([Content.text(prompt)]);
      final rawJson = response.text ?? '';

      if (!mounted) return;
      Navigator.pop(context); // dismiss loading dialog

      _parseAndAddQuestions(rawJson);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading dialog
      _showError("Gemini error: $e");
    }
  }

  // [PARSE] Parse Gemini JSON response and add to questions list
  void _parseAndAddQuestions(String rawJson) {
    try {
      // Strip markdown fences in case Gemini still wraps output
      final cleaned = rawJson
          .replaceAll(RegExp(r'```json|```'), '')
          .trim();

      final List<dynamic> parsed = jsonDecode(cleaned);

      if (parsed.isEmpty) {
        _showError("Gemini returned no questions. Try a different PDF.");
        return;
      }

      setState(() {
        for (final item in parsed) {
          final type = item['type'] ?? 'Multiple Choice';
          final question = item['question'] ?? '';
          final answer = item['answer'] ?? '';
          final choices = (item['choices'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];

          questions.add(QuestionItem(
            id: DateTime.now().millisecondsSinceEpoch + questions.length,
            type: type,
            question: question,
            correctAnswer: type == 'True or False' ? '' : answer,
            trueFalseAnswer: answer.toLowerCase() == 'true',
            choices: choices,
          ));
        }
      });

      // Show a quick success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${parsed.length} question(s) imported from PDF.",
              style: const TextStyle(fontFamily: 'Nunito'),
            ),
            backgroundColor: AppColors.primary_500,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _showError("Failed to parse Gemini response.\nRaw output:\n$rawJson");
    }
  }

  // [LOADING] Show loading dialog while waiting for Gemini
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.secondary_50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary_500),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Generating questions...",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text_700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [ERROR] Show error dialog
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

  // [WIDGET] Build question type icon
  Widget _getTypeIcon(String type) {
    switch (type) {
      case "Multiple Choice":
        return Icon(Icons.radio_button_checked, size: 18, color: AppColors.text_700);
      case "Identification":
        return Icon(Icons.text_fields, size: 18, color: AppColors.text_700);
      case "True or False":
        return Icon(Icons.thumb_up_outlined, size: 18, color: AppColors.text_700);
      default:
        return const Icon(Icons.help_outline, size: 18);
    }
  }

  // [WIDGET] Compact time unit stepper (up/down arrows + value + label)
  Widget _buildTimeUnit(int value, String label, ValueChanged<int> onChanged, TextEditingController controller, int max) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // [UP BUTTON] Increment by 1
        GestureDetector(
          onTap: () {
            int newValue = value + 1;
            if (newValue > max) newValue = 0;
            onChanged(newValue);
            controller.text = newValue.toString().padLeft(2, '0');
          },
          child: Icon(Icons.keyboard_arrow_up_rounded, size: 24, color: AppColors.primary_500),
        ),
        const SizedBox(height: 4),
        // [INPUT FIELD] Time value
        SizedBox(
          width: 50,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _RangeTextInputFormatter(max),
            ],
            maxLength: 2,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.text_700,
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.secondary_300, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.secondary_300, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppColors.primary_500, width: 1.5),
              ),
              counterText: '',
            ),
            onChanged: (val) {
              int? newValue = int.tryParse(val.isEmpty ? '0' : val);
              if (newValue != null) {
                newValue = newValue.clamp(0, max);
                onChanged(newValue);
              }
            },
          ),
        ),
        const SizedBox(height: 4),
        // [DOWN BUTTON] Decrement by 1
        GestureDetector(
          onTap: () {
            int newValue = value - 1;
            if (newValue < 0) newValue = max;
            onChanged(newValue);
            controller.text = newValue.toString().padLeft(2, '0');
          },
          child: Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: AppColors.primary_500),
        ),
        const SizedBox(height: 4),
        // [LABEL] Unit
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.text_400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // [WIDGET] Shared text input field used for Question and Answer
  Widget _buildTextField({
    required String hint,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    int minLines = 2,
    int? maxLines = 2,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary_300),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: minLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.text_400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 15,
          color: AppColors.text_700,
        ),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_50,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  // [BODY] Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // [INPUT] Quiz Title
                          Text(
                            "Quiz Title",
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text_700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary_100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: titleController,
                              textCapitalization: TextCapitalization.sentences,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 15,
                                color: AppColors.text_700,
                              ),
                              decoration: InputDecoration(
                                hintText: "Type quiz title...",
                                hintStyle: TextStyle(color: AppColors.text_400),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.secondary_300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.secondary_300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.secondary_300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // [SECTION] Options
                          Text(
                            "Options",
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text_700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.secondary_100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.secondary_300),
                            ),
                            child: Column(
                              children: [
                                // [TOGGLE] Timer
                                SwitchListTile(
                                  value: _timerEnabled,
                                  onChanged: (v) => setState(() => _timerEnabled = v),
                                  activeColor: AppColors.primary_500,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  title: const Text(
                                    "Timer",
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text_700,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "Set a time limit for your quiz",
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      color: AppColors.text_400,
                                    ),
                                  ),
                                ),

                                // [PICKER] h:m:s picker — shown when timer is enabled
                                if (_timerEnabled)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _buildTimeUnit(_hours, "hr", (v) => setState(() => _hours = v), _hoursController, 23),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
                                          child: Text(":", style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary_500)),
                                        ),
                                        _buildTimeUnit(_minutes, "min", (v) => setState(() => _minutes = v), _minutesController, 59),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
                                          child: Text(":", style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary_500)),
                                        ),
                                        _buildTimeUnit(_seconds, "sec", (v) => setState(() => _seconds = v), _secondsController, 59),
                                      ],
                                    ),
                                  ),

                                Divider(height: 1, color: AppColors.secondary_300),

                                // [TOGGLE] Randomize Questions
                                SwitchListTile(
                                  value: _randomizeQuestions,
                                  onChanged: (v) => setState(() => _randomizeQuestions = v),
                                  activeColor: AppColors.primary_500,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                                  title: const Text(
                                    "Randomize Questions",
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text_700,
                                    ),
                                  ),
                                  subtitle: const Text(
                                    "Shuffle questions each time you play",
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
                                      color: AppColors.text_400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // [SECTION] Items
                          Text(
                            "Items",
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text_700,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // [EMPTY STATE] Shown when no questions have been added yet
                          if (questions.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                              decoration: BoxDecoration(
                                color: AppColors.secondary_100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.secondary_300),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.quiz_outlined, size: 48, color: AppColors.text_200),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No items yet',
                                    style: TextStyle(
                                      fontFamily: 'Baloo',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.text_300,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap + Add Item or Import PDF to create questions',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 15,
                                      color: AppColors.text_300,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),

                          // [LIST] Questions — reorderable
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: questions.length,
                            onReorder: _reorderQuestions,
                            itemBuilder: (context, index) {
                              final q = questions[index];
                              return Container(
                                key: ValueKey(q.id),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary_100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppColors.secondary_300),
                                ),
                                child: Column(
                                  children: [
                                    // [HEADER] Question number + drag handle
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Text(
                                            "${index + 1}".padLeft(2, '0'),
                                            style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.text_700,
                                            ),
                                          ),
                                          const Spacer(),
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: Icon(
                                              Icons.drag_indicator,
                                              color: AppColors.text_400,
                                              size: 24,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // [DROPDOWN] Question type
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.secondary_300),
                                            ),
                                            child: DropdownButton<String>(
                                              value: q.type,
                                              isExpanded: true,
                                              underline: const SizedBox(),
                                              icon: Icon(Icons.arrow_drop_down, size: 20, color: AppColors.text_700),
                                              items: questionTypes.map((type) {
                                                return DropdownMenuItem(
                                                  value: type,
                                                  child: Row(
                                                    children: [
                                                      _getTypeIcon(type),
                                                      const SizedBox(width: 10),
                                                      Text(
                                                        type,
                                                        style: TextStyle(
                                                          fontFamily: 'Nunito',
                                                          fontSize: 15,
                                                          color: AppColors.text_700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                if (val != null) _updateQuestion(index, type: val);
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 14),

                                          // [INPUT] Question
                                          Text(
                                            "Question",
                                            style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.text_700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          _buildTextField(
                                            hint: "Type question...",
                                            controller: q.questionController,
                                            onChanged: (val) => _updateQuestion(index, question: val),
                                          ),
                                          const SizedBox(height: 14),

                                          // [INPUT] Correct Answer
                                          Text(
                                            "Correct Answer",
                                            style: TextStyle(
                                              fontFamily: 'Nunito',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.text_700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (q.type == "True or False")
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: AppColors.secondary_300),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: RadioListTile<bool>(
                                                      title: Text(
                                                        "True",
                                                        style: TextStyle(
                                                          fontFamily: 'Nunito',
                                                          fontSize: 15,
                                                          color: AppColors.text_700,
                                                        ),
                                                      ),
                                                      value: true,
                                                      groupValue: q.trueFalseAnswer,
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                                      visualDensity: VisualDensity.compact,
                                                      activeColor: AppColors.primary_500,
                                                      onChanged: (val) {
                                                        if (val != null) _updateQuestion(index, trueFalseAnswer: val);
                                                      },
                                                    ),
                                                  ),
                                                  Container(width: 1, height: 32, color: AppColors.secondary_200),
                                                  Expanded(
                                                    child: RadioListTile<bool>(
                                                      title: Text(
                                                        "False",
                                                        style: TextStyle(
                                                          fontFamily: 'Nunito',
                                                          fontSize: 15,
                                                          color: AppColors.text_700,
                                                        ),
                                                      ),
                                                      value: false,
                                                      groupValue: q.trueFalseAnswer,
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                                      visualDensity: VisualDensity.compact,
                                                      activeColor: AppColors.primary_500,
                                                      onChanged: (val) {
                                                        if (val != null) _updateQuestion(index, trueFalseAnswer: val);
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          else
                                            _buildTextField(
                                              hint: "Type correct answer...",
                                              controller: q.answerController,
                                              onChanged: (val) => _updateQuestion(index, answer: val),
                                              minLines: 1,
                                              maxLines: null,
                                            ),
                                        ],
                                      ),
                                    ),

                                    // [DELETE] Delete button
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: () => _removeQuestion(index),
                                        icon: const Icon(Icons.delete_outline, size: 18),
                                        label: const Text(
                                          "Delete",
                                          style: TextStyle(fontFamily: 'Nunito', fontSize: 15),
                                        ),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red[400],
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // [FOOTER] Action Buttons — Import PDF + Add Item + Save Quiz
                  SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        color: AppColors.secondary_50,
                        border: Border(
                          top: BorderSide(color: AppColors.secondary_200),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // [ROW 1] Import PDF — full width
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _importFromPdf,
                              icon: const Icon(Icons.picture_as_pdf_rounded),
                              label: const Text(
                                'Import PDF',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary_100,
                                side: BorderSide(color: AppColors.primary_300),
                                foregroundColor: AppColors.primary_500,
                                elevation: 1,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // [ROW 2] Add Item + Save Quiz
                          Row(
                            children: [
                              // [BUTTON] Add Item
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _addQuestion,
                                  icon: const Icon(Icons.playlist_add_rounded),
                                  label: const Text(
                                    'Add Item',
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
                                    side: BorderSide(color: AppColors.text_200),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // [BUTTON] Save Quiz
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _saveQuiz,
                                  icon: const Icon(Icons.save_rounded),
                                  label: const Text(
                                    'Save Quiz',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary_500,
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
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [WIDGET] Header — matches Quiz screen layout
  Widget _buildHeader() {
    return Material(
      color: AppColors.secondary_50,
      elevation: 1,
      shadowColor: AppColors.secondary_500.withValues(alpha: 0.4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.text_700),
              onPressed: () => Navigator.pop(context),
            ),
            const Text(
              'Create Quiz',
              style: TextStyle(
                fontFamily: 'Baloo',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text_700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// [MODEL] Question item class
class QuestionItem {
  final int id;
  String type;
  String question;
  String correctAnswer;
  bool trueFalseAnswer;
  List<String> choices;
  final TextEditingController questionController;
  final TextEditingController answerController;

  QuestionItem({
    required this.id,
    required this.type,
    required this.question,
    required this.correctAnswer,
    this.trueFalseAnswer = true,
    this.choices = const [],
  })  : questionController = TextEditingController(text: question),
        answerController = TextEditingController(text: correctAnswer);

  void dispose() {
    questionController.dispose();
    answerController.dispose();
  }
}

// [FORMATTER] Blocks typed values above a given max (used for timer fields)
class _RangeTextInputFormatter extends TextInputFormatter {
  final int max;
  _RangeTextInputFormatter(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final intVal = int.tryParse(newValue.text);
    if (intVal == null || intVal > max) return oldValue;
    return newValue;
  }
}