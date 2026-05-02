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
  final TextEditingController titleController = TextEditingController();
  bool _timerEnabled = false;
  int _hours = 0;
  int _minutes = 10;
  int _seconds = 0;
  
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
      'questions': questions.map((q) => {
        'question': q.question,
        'answer': q.correctAnswer,
        'type': q.type,
        'trueFalseAnswer': q.trueFalseAnswer,
        'choices': q.choices,
      }).toList(),
    });
    if (!mounted) return;
    Navigator.pop(context);
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
        return Icon(Icons.help_outline, size: 18);
    }
  }

  // [WIDGET] Compact time unit stepper (up/down arrows + value + label)
  Widget _buildTimeUnit(int value, String label, ValueChanged<int> onChanged) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => onChanged(value + 1),
          child: Icon(Icons.keyboard_arrow_up_rounded, size: 22, color: AppColors.primary_600),
        ),
        const SizedBox(height: 2),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.text_700,
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () => onChanged(value - 1),
          child: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: AppColors.primary_600),
        ),
        const SizedBox(height: 2),
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
          fontSize: 14,
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create Quiz",
          style: TextStyle(
            fontFamily: 'Baloo',
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        backgroundColor: AppColors.primary_600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // [BODY] Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // [INPUT] Quiz Name
                  Text(
                    "Quiz Name",
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
                      decoration: InputDecoration(
                        hintText: "Enter quiz name",
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
                          _buildTimeUnit(_hours, "hr", (v) => setState(() => _hours = v.clamp(0, 23))),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
                            child: Text(":", style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary_600)),
                          ),
                          _buildTimeUnit(_minutes, "min", (v) => setState(() => _minutes = v.clamp(0, 59))),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, left: 8, right: 8),
                            child: Text(":", style: TextStyle(fontFamily: 'Nunito', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.primary_600)),
                          ),
                          _buildTimeUnit(_seconds, "sec", (v) => setState(() => _seconds = v.clamp(0, 59))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // [SECTION] Items
                  Text(
                    "Items",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 15,
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
                              fontSize: 13,
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
                                                  fontSize: 14,
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
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text_700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _buildTextField(
                                    hint: "Type question...",
                                    onChanged: (val) => _updateQuestion(index, question: val),
                                  ),
                                  const SizedBox(height: 14),

                                  // [INPUT] Correct Answer
                                  Text(
                                    "Correct Answer",
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 13,
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
                                                  fontSize: 14,
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
                                                  fontSize: 14,
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
                                  style: TextStyle(fontFamily: 'Nunito', fontSize: 13),
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
          // [BUTTON] Add Item
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            decoration: BoxDecoration(
              color: AppColors.secondary_50,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add, size: 24),
              label: const Text(
                "Add Item",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary_600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ),
          // [BUTTON] Save Quiz
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: ElevatedButton(
              onPressed: _saveQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary_600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Save Quiz",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
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
  QuestionItem({
    required this.id,
    required this.type,
    required this.question,
    required this.correctAnswer,
    this.trueFalseAnswer = true,
    this.choices = const [],
  });
}