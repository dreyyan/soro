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
  int timeLimitMinutes = 10;
  List<QuestionItem> questions = [];
  
  // [OPTIONS] Time limit options
  final List<int> timeOptions = [5, 10, 15, 20, 30, 45, 60];
  
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
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
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
      'timeLimitSecs': timeLimitMinutes * 60,
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
        return Icon(Icons.radio_button_checked, size: 20, color: AppColors.primary_600);
      case "Identification":
        return Icon(Icons.format_list_bulleted, size: 20, color: AppColors.primary_600);
      case "True or False":
        return Icon(Icons.thumb_up_outlined, size: 20, color: AppColors.primary_600);
      default:
        return Icon(Icons.help_outline, size: 20);
    }
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
                      fontSize: 14,
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

                  // [INPUT] Timer
                  Text(
                    "Timer",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text_700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.secondary_100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<int>(
                      value: timeLimitMinutes,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down, color: AppColors.primary_600),
                      items: timeOptions.map((minutes) {
                        return DropdownMenuItem(
                          value: minutes,
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 20, color: AppColors.text_500),
                              const SizedBox(width: 12),
                              Text(
                                "$minutes minute${minutes == 1 ? '' : 's'}",
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 16,
                                  color: AppColors.text_700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => timeLimitMinutes = val);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // [SECTION] Items
                  Row(
                    children: [
                      Text(
                        "Items",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text_700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // [LIST] Questions
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
                            // [HEADER] Question number and drag handle
                            Container(
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
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.secondary_300),
                                    ),
                                    child: DropdownButton<String>(
                                      value: q.type,
                                      isExpanded: true,
                                      underline: const SizedBox(),
                                      icon: Icon(Icons.arrow_drop_down, size: 20, color: AppColors.text_500),
                                      items: questionTypes.map((type) {
                                        return DropdownMenuItem(
                                          value: type,
                                          child: Row(
                                            children: [
                                              _getTypeIcon(type),
                                              const SizedBox(width: 12),
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
                                        if (val != null) {
                                          _updateQuestion(index, type: val);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),

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
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(0),
                                      border: Border.all(color: AppColors.secondary_300),
                                    ),
                                    child: TextField(
                                      maxLines: 2,
                                      decoration: InputDecoration(
                                        hintText: "Type question...",
                                        hintStyle: TextStyle(color: AppColors.text_400),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      onChanged: (val) => _updateQuestion(index, question: val),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

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
                                  RadioGroup<bool>(
                                    onChanged: (val) {
                                      if (val != null) {
                                        _updateQuestion(index, trueFalseAnswer: val);
                                      }
                                    },
                                    // Add a key to preserve selection state across rebuilds
                                    key: ValueKey(q.trueFalseAnswer),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: RadioListTile<bool>(
                                            title: const Text("True"),
                                            value: true,
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                        Expanded(
                                          child: RadioListTile<bool>(
                                            title: const Text("False"),
                                            value: false,
                                            contentPadding: EdgeInsets.zero,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  else
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(0),
                                        border: Border.all(color: AppColors.secondary_300),
                                      ),
                                      child: TextField(
                                        decoration: InputDecoration(
                                          hintText: "Type correct answer...",
                                          hintStyle: TextStyle(color: AppColors.text_400),
                                          border: InputBorder.none,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        ),
                                        onChanged: (val) => _updateQuestion(index, answer: val),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
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
                                  label: const Text("Delete"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red[400],
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

          // [BUTTON] Add Question
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
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
                "Add Question",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
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

          // [BUTTON] Save Quiz (floating above Add Question)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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