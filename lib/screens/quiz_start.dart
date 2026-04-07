// [IMPORT] Libraries
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

// [IMPORT] Screens
import 'package:soro/main.dart';
import 'home_page.dart';

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
  String quizTitle = "Science Quiz 1";

  // [STATES] Timer
  Timer? timer;
  int timeLeft = 120;

  // [DATABASE] Hive helper
  final dbHelper = DatabaseHelper();

  // [STATES] Quiz settings
  int numberOfQuestions = 5;
  String selectedMode = "Multiple Choice";
  String selectedGameMode = "Classic";

  // [STATES] Loaded questions
  List<Question> questions = [];
  Question get currentQuestion => questions[currentNumber];

  // [FUNCTION] Generate choices with distractors
  void _generateChoices() {
    final random = Random();
    final allAnswers = questions.map((q) => q.answer).toList();

    for (var question in questions) {
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

    // [DIALOG] Show finished quiz
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Time's up!"),
        content: Text("Your score is $score/${questions.length}"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentNumber = 0;
                score = 0;
                selectedAnswer = "";
                timeLeft = 60;
                startTimer();
              });
            },
            child: Text("Restart"),
          ),
        ],
      ),
    );
  }

  // [FUNCTION] Timer countdown
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

  // [GET] Load settings and questions from arguments
  void _loadSettings() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      numberOfQuestions = args['numberOfQuestions'] ?? 5;
      selectedMode = args['mode'] ?? "Multiple Choice";
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
      startTimer();
    }
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

  // [FUNCTION] Dispose timer
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // [HELPER] Check if last question
  bool isLastNumber() => currentNumber == questions.length - 1;

  // [FUNCTION] Navigate back to home
  void handleBack() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  // [HELPER] Format seconds to mm:ss
  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
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
            // [HEADER] Quiz title + timer + back button
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

                  // [QUIZ TITLE + TIMER]
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
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // [QUESTION SECTION] Progress + question text
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
                    currentQuestion.question,
                    style: TextStyle(fontFamily: "Baloo", fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            Spacer(),

            // [CHOICES SECTION] Answer buttons
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: currentQuestion.choices.map((choice) {
                  Color btnColor = AppColors.secondary_50;

                  if (answerSubmitted) {
                    if (choice == currentQuestion.answer) {
                      btnColor = AppColors.green_300;
                    } else if (choice == selectedAnswer && choice != currentQuestion.answer) {
                      btnColor = AppColors.primary_300;
                    } else {
                      btnColor = AppColors.secondary_50;
                    }
                  } else if (selectedAnswer == choice) {
                    btnColor = AppColors.secondary_200;
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: ChoiceButton(
                      text: choice,
                      backgroundColor: btnColor,
                      onPressed: answerSubmitted
                          ? () {}
                          : () {
                              setState(() {
                                selectedAnswer = choice;
                                answerSubmitted = true;
                                if (choice == currentQuestion.answer) score++;
                              });

                              Future.delayed(Duration(seconds: 1), () {
                                setState(() {
                                  answerSubmitted = false;
                                  selectedAnswer = "";
                                  if (!isLastNumber()) {
                                    currentNumber++;
                                  } else {
                                    submitQuiz();
                                  }
                                });
                              });
                            },
                      selectedAnswer: selectedAnswer == choice,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}