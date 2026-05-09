// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

// [IMPORT] Screens
import 'package:soro/screens/quiz/quiz_settings.dart'; // [REUSE] QuestionItem model

class QuizEdit extends StatefulWidget {
  final Map<String, dynamic> quiz; // [PROP] Existing quiz to edit

  const QuizEdit({super.key, required this.quiz});

  @override
  State<QuizEdit> createState() => _QuizEditState();
}

class _QuizEditState extends State<QuizEdit> {
  // [STATES] Quiz settings
  final TextEditingController titleController = TextEditingController();
  final TextEditingController _hoursController = TextEditingController(text: '0');
  final TextEditingController _minutesController = TextEditingController(text: '10');
  final TextEditingController _secondsController = TextEditingController(text: '0');
  bool _timerEnabled = false;
  int _hours   = 0;
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
  void initState() {
    super.initState();
    final q = widget.quiz;

    // [PREFILL] Title
    titleController.text = q['title'] as String? ?? '';

    // [PREFILL] Timer — null or 0 means disabled
    final savedSecs = q['timeLimitSecs'] as int?;
    _timerEnabled = savedSecs != null && savedSecs > 0;
    final secs = savedSecs ?? 600;
    _hours   = secs ~/ 3600;
    _minutes = (secs % 3600) ~/ 60;
    _seconds = secs % 60;
    _hoursController.text = _hours.toString().padLeft(2, '0');
    _minutesController.text = _minutes.toString().padLeft(2, '0');
    _secondsController.text = _seconds.toString().padLeft(2, '0');

    // [PREFILL] Randomize Questions
    _randomizeQuestions = q['randomizeQuestions'] as bool? ?? false;

    // [PREFILL] Questions — rebuild QuestionItem list from saved maps
    final saved = (q['questions'] as List? ?? []).cast<Map<String, dynamic>>();
    questions = saved.map((e) {
      final type   = e['type'] as String? ?? 'Multiple Choice';
      final answer = e['answer'] as String? ?? '';
      return QuestionItem(
        id:             DateTime.now().millisecondsSinceEpoch ^ e.hashCode,
        type:           type,
        question:       e['question'] as String? ?? '',
        correctAnswer:  type == 'True or False' ? '' : answer,
        trueFalseAnswer: type == 'True or False'
            ? (e['trueFalseAnswer'] as bool? ?? (answer.toLowerCase() == 'true'))
            : true,
        choices:        (e['choices'] as List?)?.cast<String>() ?? [],
      );
    }).toList();
  }

  @override
  void dispose() {
    titleController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    super.dispose();
  }

  // [ADD] Add a new question
  void _addQuestion() {
    setState(() {
      questions.add(QuestionItem(
        id:             DateTime.now().millisecondsSinceEpoch,
        type:           questionTypes[0],
        question:       '',
        correctAnswer:  '',
        trueFalseAnswer: true,
      ));
    });
  }

  // [REMOVE] Remove a question
  void _removeQuestion(int index) {
    setState(() => questions.removeAt(index));
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
  void _updateQuestion(int index,
      {String? type, String? question, String? answer, bool? trueFalseAnswer}) {
    setState(() {
      if (type != null)           questions[index].type            = type;
      if (question != null)       questions[index].question        = question;
      if (answer != null)         questions[index].correctAnswer   = answer;
      if (trueFalseAnswer != null) questions[index].trueFalseAnswer = trueFalseAnswer;
    });
  }

  // [SAVE] Overwrite the existing quiz (same id, same createdAt)
  Future<void> _saveQuiz() async {
    final title = titleController.text.trim();
    if (title.isEmpty) { _showError("Please enter a quiz title."); return; }
    if (questions.isEmpty) { _showError("Please add at least one question."); return; }

    // [VALIDATE] All questions must have content
    for (int i = 0; i < questions.length; i++) {
      if (questions[i].question.trim().isEmpty) {
        _showError("Question ${i + 1} is empty.");
        return;
      }
      if (questions[i].type != "True or False" &&
          questions[i].correctAnswer.trim().isEmpty) {
        _showError("Question ${i + 1} answer is empty.");
        return;
      }
    }

    // [CALCULATE] Total seconds from picker (null if timer is off)
    final totalSeconds = _timerEnabled
        ? _hours * 3600 + _minutes * 60 + _seconds
        : null;

    // [UPDATE] Keep original id and createdAt, overwrite everything else
    await DatabaseHelper().updateSavedQuiz({
      'id':               widget.quiz['id'],
      'title':            title,
      'description':      '',
      'createdAt':        widget.quiz['createdAt'],
      'questionCount':    questions.length,
      'mode':             questions.isNotEmpty ? questions[0].type : "Multiple Choice",
      'gameMode':         'Classic',
      'identificationMode': 'Definition',
      'deckTitle':        '—',
      'timeLimitSecs':    totalSeconds,
      'randomizeQuestions': _randomizeQuestions,
      'questions': questions.map((q) => {
        'question':       q.question,
        'answer':         q.type == 'True or False'
                            ? q.trueFalseAnswer.toString()
                            : q.correctAnswer,
        'type':           q.type,
        'trueFalseAnswer': q.trueFalseAnswer,
        'choices':        q.choices,
      }).toList(),
    });

    if (!mounted) return;
    Navigator.pop(context); // [NAVIGATE] Back to Quiz list
  }

  // [ERROR] Show error dialog
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

  // [WIDGET] Question type icon
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

  // [WIDGET] Enhanced time unit stepper with input field (up/down arrows + input + label)
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
          child: Icon(Icons.keyboard_arrow_up_rounded, size: 24, color: AppColors.primary_600),
        ),
        const SizedBox(height: 4),
        // [INPUT FIELD] Time value
        SizedBox(
          width: 50,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
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
                borderSide: const BorderSide(color: AppColors.primary_600, width: 1.5),
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
          child: Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: AppColors.primary_600),
        ),
        const SizedBox(height: 4),
        // [LABEL] Unit
        Text(
          label,
          style: const TextStyle(
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
    required ValueChanged<String> onChanged,
    String initialValue = '',
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
        maxLines: maxLines,
        minLines: minLines,
        controller: TextEditingController(text: initialValue)
          ..selection = TextSelection.collapsed(offset: initialValue.length),
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
      body: Column(
        children: [
          // [HEADER] Edit Quiz header
          Material(
            color: AppColors.secondary_50,
            elevation: 3,
            shadowColor: AppColors.secondary_500.withValues(alpha: 0.4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.primary_600),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Edit Quiz',
                    style: TextStyle(
                      fontFamily: 'Baloo',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary_600,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // [INPUT] Timer — toggle + h:m:s picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Timer",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text_700,
                        ),
                      ),
                      Switch(
                        value: _timerEnabled,
                        onChanged: (v) => setState(() => _timerEnabled = v),
                        activeColor: AppColors.primary_600,
                      ),
                    ],
                  ),
                  if (_timerEnabled) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary_100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.secondary_300),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTimeUnit(_hours,   "hr",  (v) => setState(() => _hours   = v), _hoursController, 23),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
                            child: Text(":", style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary_600)),
                          ),
                          _buildTimeUnit(_minutes, "min", (v) => setState(() => _minutes = v), _minutesController, 59),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
                            child: Text(":", style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary_600)),
                          ),
                          _buildTimeUnit(_seconds, "sec", (v) => setState(() => _seconds = v), _secondsController, 59),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // [INPUT] Randomize Questions — toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Randomize Questions",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text_700,
                        ),
                      ),
                      Switch(
                        value: _randomizeQuestions,
                        onChanged: (v) => setState(() => _randomizeQuestions = v),
                        activeColor: AppColors.primary_600,
                      ),
                    ],
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
                            'Tap + Add Item to create one',
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
                                    initialValue: q.question,
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
                                              activeColor: AppColors.primary_600,
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
                                              activeColor: AppColors.primary_600,
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
                                      initialValue: q.correctAnswer,
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
          // [FOOTER] Action Buttons - Add Items + Save Changes
SafeArea(
  top: false,
  child: Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    decoration: BoxDecoration(
      color: AppColors.secondary_50,
      border: Border(
        top: BorderSide(
          color: AppColors.secondary_200,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, -4),
        ),
      ],
    ),
    child: Row(
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
                fontWeight: FontWeight.w700
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.text_700,
              elevation: 0,
              side: BorderSide(
                color: AppColors.secondary_300,
              ),
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // [BUTTON] Save Quiz - Primary Solid Background
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveQuiz,
            icon: const Icon(Icons.save_rounded, size: 24),
            label: const Text(
              'Save Quiz',
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
              padding: const EdgeInsets.symmetric(vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),
        ],
      ),
    );
  }
}