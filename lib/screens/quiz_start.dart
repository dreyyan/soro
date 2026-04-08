// [IMPORT] Libraries
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

// [IMPORT] Screens
import 'package:soro/main.dart';
import 'package:soro/screens/quiz_settings.dart';

// [IMPORT] Components
import 'package:soro/widgets/choice_button.dart';

// [IMPORT] Database
import '../database/database_helper.dart';

// [IMPORT] Classes
import '../models/question.dart';

class QuizStart extends StatefulWidget {
  const QuizStart({super.key});

  @override
  State<QuizStart> createState() => _QuizStartState();
}

class _QuizStartState extends State<QuizStart> {
  // [STATES] Quiz statistics
  int score = 0;
  int currentNumber = 0;
  String selectedAnswer = "";
  bool answerSubmitted = false;
  String quizTitle = "Quiz";

  // [STATES] Timer
  Timer? timer;
  int timeLeft = 120;

  // [DATABASE] Hive helper
  final dbHelper = DatabaseHelper();

  // [STATES] Quiz settings
  int numberOfQuestions = 5;
  String selectedMode = "Multiple Choice";
  String selectedGameMode = "Classic";

  String identificationMode = "Definition";
  bool isTermToDefinition = true; // direction per question

  // [STATES] Identification input
  final TextEditingController identificationController = TextEditingController();
  bool identificationSubmitted = false;
  bool identificationCorrect = false;

  // [STATES] Loaded questions
  List<Question> questions = [];
  Question get currentQuestion => questions[currentNumber];

  // [FUNCTION] Generate choices for Multiple Choice
  void _generateChoices() {
    final random = Random();
    final allAnswers = questions.map((q) => q.answer).toList();

    for (var question in questions) {
      // For True or False, always set fixed choices
      if (selectedMode == "True or False") {
        question.choices = ["True", "False"];
        continue;
      }

      final wrongAnswers = allAnswers
          .where((a) => a != question.answer)
          .toSet()
          .toList()
        ..shuffle(random);

      final distractors = wrongAnswers.take(3).toList();
      final fillers = [
        "None of the above",
        "All of the above",
        "Cannot be determined",
        "Not applicable",
      ];

      int fillerIndex = 0;
      while (distractors.length < 3 && fillerIndex < fillers.length) {
        final filler = fillers[fillerIndex];
        if (filler != question.answer && !distractors.contains(filler)) {
          distractors.add(filler);
        }
        fillerIndex++;
      }

      question.choices = [...distractors, question.answer]..shuffle(random);
    }
  }

  // [FUNCTION] Submit quiz and show score
  void submitQuiz() {
    timer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(selectedGameMode == "Time Attack" ? "Time's up!" : "Quiz Complete!"),
        content: Text("Your score is $score/${questions.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentNumber = 0;
                score = 0;
                selectedAnswer = "";
                identificationController.clear();
                identificationSubmitted = false;
                timeLeft = 120;
              });
              _generateChoices();
              if (selectedGameMode == "Time Attack") startTimer();
            },
            child: Text("Restart"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              handleBack();
            },
            child: Text("Back to Settings"),
          ),
        ],
      ),
    );
  }

  // [FUNCTION] Timer countdown (Time Attack only)
  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        t.cancel();
        submitQuiz();
      }
    });
  }

  // [FUNCTION] Advance to next question or finish
  void _nextQuestion() {
    if (!isLastNumber()) {
      setState(() {
        currentNumber++;
        selectedAnswer = "";
        answerSubmitted = false;
        identificationController.clear();
        identificationSubmitted = false;

        _setIdentificationDirection();
      });
    } else {
      submitQuiz();
    }
  }

  // [FUNCTION] Handle Multiple Choice answer
  void _handleMultipleChoiceAnswer(String choice) {
    if (answerSubmitted) return;
    setState(() {
      selectedAnswer = choice;
      answerSubmitted = true;
      if (choice == currentQuestion.answer) score++;
    });

    Future.delayed(Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        answerSubmitted = false;
        selectedAnswer = "";
      });
      _nextQuestion();
    });
  }

  // [GET] Load settings and questions from arguments
  void _loadSettings() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      numberOfQuestions = args['numberOfQuestions'] ?? 5;
      selectedMode = args['mode'] ?? "Multiple Choice";
      identificationMode = args['identificationMode'] ?? "Definition";
      selectedGameMode = args['gameMode'] ?? "Classic";

      final rawList = args['questions'] as List?;
      if (rawList != null && rawList.isNotEmpty) {
        questions = rawList.map((q) {
          final map = Map<String, dynamic>.from(q as Map);
          return Question(
            map['question'] as String,
            map['answer'] as String,
            List<String>.from(map['choices'] ?? []),
          );
        }).toList();
      }
    }

    setState(() {});

    if (questions.isNotEmpty) {
      _generateChoices();
      _setIdentificationDirection();
      if (selectedGameMode == "Time Attack") startTimer();
    }
  }

  // [FUNCTION] Determine identification direction
  void _setIdentificationDirection() {
    if (identificationMode == "Definition") {
      isTermToDefinition = true; // show term → answer definition
    } else if (identificationMode == "Term") {
      isTermToDefinition = false; // show definition → answer term
    } else {
      // [BOTH] Randomize
      isTermToDefinition = Random().nextBool();
    }
  }

  // [FUNCTION] Handle Identification answer submission
  void _handleIdentificationSubmit() {
    if (identificationSubmitted) return;
    final input = identificationController.text.trim().toLowerCase();
    // [ANSWER LOGIC] depends on mode
    final correct = isTermToDefinition
        ? currentQuestion.answer.trim().toLowerCase()
        : currentQuestion.question.trim().toLowerCase();
    final isCorrect = input == correct;

    setState(() {
      identificationSubmitted = true;
      identificationCorrect = isCorrect;
      if (isCorrect) score++;
    });

    Future.delayed(Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        identificationSubmitted = false;
        identificationCorrect = false;
        identificationController.clear();
      });
      _nextQuestion();
    });
  }

  // [FUNCTION] Handle True or False answer
  void _handleTrueOrFalseAnswer(String choice) {
    _handleMultipleChoiceAnswer(choice); // same logic
  }

  @override
  void initState() {
    super.initState();
  }

  bool _settingsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_settingsLoaded) {
      _settingsLoaded = true;
      _loadSettings();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    identificationController.dispose();
    super.dispose();
  }

  bool isLastNumber() => currentNumber == questions.length - 1;

  void handleBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => QuizSettings()),
    );
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  // [WIDGET] Multiple Choice choices
  Widget _buildMultipleChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: currentQuestion.choices.map((choice) {
        Color btnColor = AppColors.secondary_50;

        if (answerSubmitted) {
          if (choice == currentQuestion.answer) {
            btnColor = AppColors.green_300;
          } else if (choice == selectedAnswer) {
            btnColor = AppColors.primary_300;
          }
        } else if (selectedAnswer == choice) {
          btnColor = AppColors.secondary_200;
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: ChoiceButton(
            text: choice,
            backgroundColor: btnColor,
            onPressed: answerSubmitted ? () {} : () => _handleMultipleChoiceAnswer(choice),
            selectedAnswer: selectedAnswer == choice,
          ),
        );
      }).toList(),
    );
  }

  // [WIDGET] Identification input field
  Widget _buildIdentification() {
    Color fieldColor = AppColors.secondary_50;
    if (identificationSubmitted) {
      fieldColor = identificationCorrect ? AppColors.green_300 : AppColors.primary_300;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // [LABEL] Identification prompt
        Text(
          isTermToDefinition ? "Define the term:" : "Identify the term:",
          style: TextStyle(
            fontFamily: "Nunito",
            fontSize: 12,
            color: AppColors.text_400,
            fontWeight: FontWeight.w600,
          ),
        ),

        // [SPACE]
        SizedBox(height: 8),
        
        AnimatedContainer(
          duration: Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.text_200, width: 2),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: identificationController,
            enabled: !identificationSubmitted,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(fontFamily: "Nunito", fontSize: 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Type your answer here...",
              hintStyle: TextStyle(color: AppColors.text_400),
            ),
            onSubmitted: (_) => _handleIdentificationSubmit(),
          ),
        ),
        SizedBox(height: 12),
        if (identificationSubmitted)
          Text(
            identificationCorrect
                ? "✓ Correct!"
                : "✗ Correct answer: ${isTermToDefinition 
                ? currentQuestion.answer 
                : currentQuestion.question}",
            style: TextStyle(
              fontFamily: "Nunito",
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: identificationCorrect ? AppColors.green_600 : AppColors.primary_600,
            ),
          ),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: identificationSubmitted ? null : _handleIdentificationSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary_500,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            "Submit",
            style: TextStyle(fontFamily: "Nunito", fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    );
  }

  // [WIDGET] True or False choices
  Widget _buildTrueOrFalse() {
    return Row(
      children: ["True", "False"].map((choice) {
        Color btnColor = AppColors.secondary_50;

        if (answerSubmitted) {
          if (choice == currentQuestion.answer) {
            btnColor = AppColors.green_300;
          } else if (choice == selectedAnswer) {
            btnColor = AppColors.primary_300;
          }
        } else if (selectedAnswer == choice) {
          btnColor = AppColors.secondary_200;
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceButton(
              text: choice,
              backgroundColor: btnColor,
              onPressed: answerSubmitted ? () {} : () => _handleTrueOrFalseAnswer(choice),
              selectedAnswer: selectedAnswer == choice,
            ),
          ),
        );
      }).toList(),
    );
  }

  // [WIDGET] Input section based on mode
  Widget _buildInputSection() {
    switch (selectedMode) {
      case "Identification":
        return _buildIdentification();
      case "True or False":
        return _buildTrueOrFalse();
      case "Multiple Choice":
      default:
        return _buildMultipleChoice();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("No questions found."),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: handleBack,
                child: Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.secondary_300,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [HEADER] Back button + title + timer
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // [BUTTON] Back
                  SizedBox(
                    width: 48,
                    child: ElevatedButton(
                      onPressed: handleBack,
                      style: ButtonStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: WidgetStatePropertyAll(Colors.transparent),
                        backgroundColor: WidgetStatePropertyAll(AppColors.secondary_50),
                        foregroundColor: WidgetStatePropertyAll(AppColors.text_700),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.text_100, width: 2),
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "<",
                          style: TextStyle(fontFamily: "Nunito", fontWeight: FontWeight.w700, fontSize: 24),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: 16),

                  // [TITLE + TIMER]
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary_100,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary_500,
                            spreadRadius: 0,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            quizTitle,
                            style: TextStyle(
                              fontFamily: "Baloo",
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.text_800,
                            ),
                          ),

                          // [TIMER] Only shown in Time Attack mode
                          if (selectedGameMode == "Time Attack") ...[
                            SizedBox(width: 12),
                            Icon(
                              Icons.timer,
                              color: timeLeft <= 10 ? AppColors.primary_600 : AppColors.text_700,
                              size: 18,
                            ),
                            SizedBox(width: 4),
                            Text(
                              formatTime(timeLeft),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: timeLeft <= 10 ? AppColors.primary_600 : AppColors.text_800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // [QUESTION SECTION]
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary_100,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary_500,
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: (currentNumber + 1) / questions.length,
                      minHeight: 6,
                      backgroundColor: AppColors.text_200,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary_600),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(fontFamily: "Nunito", fontSize: 12, fontWeight: FontWeight.w500),
                      children: [
                        TextSpan(text: "Question "),
                        TextSpan(text: "${currentNumber + 1}", style: TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(text: " of "),
                        TextSpan(text: "${questions.length}", style: TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    selectedMode == "True or False"
                        ? "True or False: ${currentQuestion.question}"
                        : selectedMode == "Identification"
                            ? (isTermToDefinition
                                ? currentQuestion.question // show term
                                : currentQuestion.answer) // show definition
                            : currentQuestion.question,
                    style: TextStyle(fontFamily: "Baloo", fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            Spacer(),

            // [INPUT SECTION] Changes based on selectedMode
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary_100,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary_500,
                    spreadRadius: 0,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _buildInputSection(),
            ),
          ],
        ),
      ),
    );
  }
}