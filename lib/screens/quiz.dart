import 'package:flutter/material.dart';
import 'package:sora/main.dart';

// [IMPORT] Timer
import 'dart:async';

// [IMPORT] Components
import 'package:sora/widgets/choice_button.dart';
import 'package:sora/widgets/primary_button.dart';

class Quiz extends StatefulWidget {
  const Quiz({super.key});

  @override
  State<Quiz> createState() => _QuizState();
}

// [CLASSES]
class Question {
  String question;
  String answer;
  List<String> choices;

  // Constructor
  Question(this.question, this.answer, this.choices);
}

class _QuizState extends State<Quiz> {
  // [STATES] Statistics
  int score = 0;
  int currentNumber = 0;
  String selectedAnswer = "";
  String quizTitle = "Science Quiz 1";

  Timer? timer;
  int timeLeft = 30;

  // [STATES] Questions
  List<Question> questions = [
    Question(
      "What is the primary function of mitochondria in a cell?",
      "Energy Production",
      [
        "Protein Synthesis",
        "Energy Production",
        "Genetic Storage",
        "Waste Removal"
      ],
    ),
    Question(
      "What does DNA primarily store?",
      "Genetic Information",
      [
        "Energy",
        "Proteins",
        "Genetic Information",
        "Waste"
      ],
    ),
    Question(
      "Which organ is responsible for pumping blood?",
      "Heart",
      [
        "Lungs",
        "Brain",
        "Heart",
        "Liver"
      ],
    ),
  ];

  Question get currentQuestion => questions[currentNumber];

  // [FUNCTION] Calculate score and evaluation
  void submitQuiz() {
    timer?.cancel(); // stop timer

    // [DIALOG] Finished quiz
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
                timeLeft = 60; // reset timer
                startTimer(); // restart quiz
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
        setState(() {
          timeLeft--;
        });
      } else {
        t.cancel();
        submitQuiz();
      }
    });
  }

  // [FUNCTION] Start timer
  @override
  void initState() {
    super.initState();
    startTimer(); // start countdown when screen loads
  }

  // [FUNCTION] Dispose timer
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // [HELPER] Check if last number
  bool isLastNumber() { return currentNumber == questions.length - 1; }

  // [FUNCTION] Return back to menu
  void handleBack() {

  }

  // [FUNCTION] Submit quiz if last number, else, proceed to the next number
  void handleNext() {
    
  }

  // [HELPER] Format time as 'mm:ss'
  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  // [HELPER] Check if answer is correct (+1) or wrong (+0)
  void checkAnswer(String choice) {
    if (choice == currentQuestion.answer) { score++; }

    if (!isLastNumber()) {
      currentNumber++; // proceed to the next number
      selectedAnswer = ""; // reset selected answer
    } else {
      submitQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_300,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch, // make children fill the height
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // [BUTTON] Back
                  SizedBox(
                    width: 48, // fixed width for square button
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
                          style: TextStyle(
                            fontFamily: "Nunito",
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // [SPACE]
                  SizedBox(width: 16),

                  // [HEADER] Quiz title + timer
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

            // [SPACE]
            SizedBox(height: 20),

            // [SECTION] Choices
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16), // parent padding
              decoration: BoxDecoration(
                color: AppColors.secondary_100,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary_500, // shadow color
                    spreadRadius: 0, // how much the shadow spreads
                    blurRadius: 4,   // softness of the shadow
                    offset: Offset(0, 2), // horizontal & vertical offset
                  ),
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [COMPONENT] Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100), // make the progress bar fully rounded
                    child: LinearProgressIndicator(
                      value: (currentNumber + 1) / questions.length,
                      minHeight: 6,
                      backgroundColor: AppColors.text_200,
                      valueColor: AlwaysStoppedAnimation(AppColors.primary_600),
                    ),
                  ),
                  // [SPACE]
                  SizedBox(height: 8),
                  // [UI] Question Number
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        fontFamily: "Nunito",
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(text: "Question "),
                        TextSpan(
                          text: "${currentNumber + 1}",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: " of "),
                        TextSpan(
                          text: "${questions.length}",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),

                  // [SPACE]
                  SizedBox(height: 16),

                  // [UI] Question
                  Text(
                    currentQuestion.question,
                    style: TextStyle(
                      fontFamily: "Baloo",
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            ),

            // [SPACE]
            Spacer(),

            // [SECTION] Choices
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16), // parent padding
              decoration: BoxDecoration(
                color: AppColors.secondary_100,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary_500, // shadow color
                    spreadRadius: 0, // how much the shadow spreads
                    blurRadius: 4,   // softness of the shadow
                    offset: Offset(0, 2), // horizontal & vertical offset
                  ),
                ]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // full width
                children: currentQuestion.choices.map((choice) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 8), // spacing between buttons
                  child: ChoiceButton(
                    text: choice,
                    onPressed: () => setState(() { checkAnswer(choice); }),
                    backgroundColor: AppColors.secondary_50,
                  ),
                )).toList(),
              ),
            ),

            // [SPACE]
            SizedBox(height: 40),

            // [PRIMARY BUTTON] Next / Submit
            PrimaryButton(
              text: isLastNumber() ? "Submit" : "Next",
              onPressed: () => handleNext(),
            )
          ],
        ),
      ),
    );
  }
}