import 'package:flutter/material.dart';
import 'package:sora/main.dart';

// [IMPORT] Components
import 'package:sora/widgets/choice_button.dart';

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

  // [HELPER] Check if answer is correct (+1) or wrong (+0)
  void checkAnswer(String choice) {
    if (choice == currentQuestion.answer) { score++; }

    if (currentNumber < questions.length - 1) {
      currentNumber++; // proceed to the next number
      selectedAnswer = ""; // reset selected answer
    } else {
      // [MODAL] Quiz Finished
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("Quiz Finished!"),
          content: Text("Your score is $score/${questions.length}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  currentNumber = 0;
                  score = 0;
                  selectedAnswer = "";
                });
              },
              child: Text("Restart"),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quiz"),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [SECTION] Question + Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Question ${currentNumber + 1}"),
                Text("Score: $score"),
              ],
            ),

            SizedBox(height: 20),

            // [TEXT] Question
            Text(
              currentQuestion.question,
              style: TextStyle(
                fontFamily: "Baloo",
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
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

            // [PRIMARY BUTTON] Next / Submit
            
          ],
        ),
      ),
    );
  }
}