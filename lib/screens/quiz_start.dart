// [IMPORT] Libraries
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Screens
import 'package:soro/screens/quiz_settings.dart';

// [IMPORT] Widgets
import 'package:soro/widgets/choice_button.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

// [IMPORT] Models
import 'package:soro/models/question.dart';

class QuizStart extends StatefulWidget {
  const QuizStart({super.key});

  @override
  State<QuizStart> createState() => _QuizStartState();
}

class _QuizStartState extends State<QuizStart> {
  // [STATES] Quiz progress
  int score = 0;
  int currentNumber = 0;
  String selectedAnswer = "";
  bool answerSubmitted = false;
  String quizTitle = "Quiz";

  // [STATES] Timer (Time Attack mode)
  Timer? timer;
  int timeLeft = 120;

  // [STATES] Quiz configuration
  int numberOfQuestions = 5;
  String selectedMode = "Multiple Choice";
  String selectedGameMode = "Classic";
  String identificationMode = "Definition";
  bool isTermToDefinition = true; // Direction randomized per question in "Both" mode

  // [STATES] Identification input
  final TextEditingController identificationController = TextEditingController();
  bool identificationSubmitted = false;
  bool identificationCorrect = false;

  // [STATES] Question data
  List<Question> questions = [];

  // [GETTER] Current question shorthand
  Question get currentQuestion => questions[currentNumber];

  // [FLAG] Prevent _loadSettings from running twice
  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
  }

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

  // [LOAD] Read quiz config and questions from route arguments
  void _loadSettings() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      numberOfQuestions = args['numberOfQuestions'] ?? 5;
      selectedMode      = args['mode']              ?? "Multiple Choice";
      identificationMode = args['identificationMode'] ?? "Definition";
      selectedGameMode  = args['gameMode']          ?? "Classic";

      final rawList = args['questions'] as List?;
      if (rawList != null && rawList.isNotEmpty) {
        questions = rawList.map((q) {
          final map = Map<String, dynamic>.from(q as Map);
          return Question(
            map['question'] as String,
            map['answer']   as String,
            List<String>.from(map['choices'] ?? []),
          );
        }).toList();
      }
    }

    setState(() {});

    if (questions.isNotEmpty) {
      _generateChoices();
      _setIdentificationDirection();
      if (selectedGameMode == "Time Attack") _startTimer();
    }
  }

  // [GENERATE] Build answer choices for Multiple Choice and True or False
  void _generateChoices() {
    final random = Random();
    final allAnswers = questions.map((q) => q.answer).toList();

    for (var question in questions) {
      // [TRUE OR FALSE] Fixed choices
      if (selectedMode == "True or False") {
        question.choices = ["True", "False"];
        continue;
      }

      // [MULTIPLE CHOICE] Pick 3 wrong answers + 1 correct, shuffle
      final wrongAnswers = allAnswers
          .where((a) => a != question.answer)
          .toSet()
          .toList()
        ..shuffle(random);

      final distractors = wrongAnswers.take(3).toList();

      // [FILLERS] Pad with generic fallbacks if not enough wrong answers
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

  // [DIRECTION] Set term→definition or definition→term for identification
  void _setIdentificationDirection() {
    if (identificationMode == "Definition") {
      isTermToDefinition = true;
    } else if (identificationMode == "Term") {
      isTermToDefinition = false;
    } else {
      // [BOTH] Randomize direction each question
      isTermToDefinition = Random().nextBool();
    }
  }

  // [TIMER] Start countdown for Time Attack mode
  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);
      } else {
        t.cancel();
        _submitQuiz();
      }
    });
  }

  // [HELPER] Returns true if the current question is the last one
  bool _isLastQuestion() => currentNumber == questions.length - 1;

  // [FORMAT] Convert seconds into MM:SS display string
  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  // [NAVIGATE] Return to QuizSettings
  void _handleBack() {
  // Pop twice to skip QuizSettings and return to quiz.dart
  if (Navigator.canPop(context)) Navigator.pop(context); // Pop QuizStart
  if (Navigator.canPop(context)) Navigator.pop(context); // Pop QuizSettings
}

  // [CONFIRM] Show dialog before returning to menu
void _confirmGoBack() {
  showDialog(
    context: context,
    barrierDismissible: false, // Force explicit choice
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        "Leave Quiz?",
        style: TextStyle(fontFamily: "Baloo", fontWeight: FontWeight.w700),
      ),
      content: const Text(
        "Your progress will not be saved. Are you sure you want to return to the menu?",
        style: TextStyle(fontFamily: "Nunito"),
      ),
      actions: [
        // [CANCEL] Stay in quiz
        TextButton(
          onPressed: () => Navigator.pop(context), // Just close dialog
          style: TextButton.styleFrom(
            foregroundColor: AppColors.text_600,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text("Cancel", style: TextStyle(fontFamily: "Nunito")),
        ),
        
        // [CONFIRM] Go back to menu
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close confirmation dialog
            _handleBack();          // Then execute the double-pop navigation
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary_600,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text(
            "Yes, Leave", 
            style: TextStyle(fontFamily: "Nunito", fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

  // [SUBMIT] End the quiz and show the score dialog
  Future<void> _submitQuiz() async {
    timer?.cancel();

    // [RECORD] Save quiz result to stats and award EXP
    final rewards = await DatabaseHelper().recordQuizResult(score, questions.length);

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          selectedGameMode == "Time Attack" ? "Time's Up!" : "Quiz Complete!",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your score: $score / ${questions.length}"),
            Text("Accuracy: ${rewards['accuracy']}%"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text("⚡ XP Earned: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("+${rewards['expEarned']}", style: const TextStyle(color: Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text("🪙 Coins Earned: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("+${rewards['coinsEarned']}", style: const TextStyle(color: Colors.orange)),
                    ],
                  ),
                  if (rewards['leveledUp'] as bool) ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Text("🎉 Level Up!", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          // [RESTART] Reset and replay
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
              if (selectedGameMode == "Time Attack") _startTimer();
            },
            child: const Text("Restart"),
          ),

          // [BACK] Return to menu
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleBack();
            },
            child: const Text("Back to Menu"),
          ),
        ],
      ),
    );
  }

  // [ADVANCE] Move to the next question or finish the quiz
  void _nextQuestion() {
    if (!_isLastQuestion()) {
      setState(() {
        currentNumber++;
        selectedAnswer = "";
        answerSubmitted = false;
        identificationController.clear();
        identificationSubmitted = false;
        _setIdentificationDirection();
      });
    } else {
      _submitQuiz();
    }
  }

  // [ANSWER] Handle a Multiple Choice selection
  void _handleMultipleChoiceAnswer(String choice) {
    if (answerSubmitted) return;
    setState(() {
      selectedAnswer  = choice;
      answerSubmitted = true;
      if (choice == currentQuestion.answer) score++;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        answerSubmitted = false;
        selectedAnswer  = "";
      });
      _nextQuestion();
    });
  }

  // [ANSWER] Handle Identification text submission
  void _handleIdentificationSubmit() {
    if (identificationSubmitted) return;
    final input   = identificationController.text.trim().toLowerCase();
    final correct = isTermToDefinition
        ? currentQuestion.answer.trim().toLowerCase()
        : currentQuestion.question.trim().toLowerCase();
    final isCorrect = input == correct;

    setState(() {
      identificationSubmitted = true;
      identificationCorrect   = isCorrect;
      if (isCorrect) score++;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        identificationSubmitted = false;
        identificationCorrect   = false;
        identificationController.clear();
      });
      _nextQuestion();
    });
  }

  // [ANSWER] Handle True or False selection (reuses MC logic)
  void _handleTrueOrFalseAnswer(String choice) {
    _handleMultipleChoiceAnswer(choice);
  }

  // [BUILD]
  @override
  Widget build(BuildContext context) {
    // [EMPTY] Fallback if no questions were loaded
    if (questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No questions found."),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleBack,
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.secondary_300,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [HEADER] Back button + quiz title + timer
            _buildHeader(),

            const SizedBox(height: 20),

            // [QUESTION] Question card with progress bar
            _buildQuestionCard(),

            const Spacer(),

            // [INPUT] Answer input — changes based on selectedMode
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary_100,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
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

  // [WIDGET] Top row: back button + title chip + optional timer
  Widget _buildHeader() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // [BUTTON] Back to settings
          // [BUTTON] Back to menu (with confirmation)
    SizedBox(
      width: 48,
      child: ElevatedButton(
        onPressed: _confirmGoBack,  // ← NEW: shows "Are you sure?" first
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          backgroundColor: const WidgetStatePropertyAll(AppColors.secondary_50),
          foregroundColor: const WidgetStatePropertyAll(AppColors.text_700),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: AppColors.text_100, width: 2),
            ),
          ),
        ),
        child: const Center(
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

          const SizedBox(width: 16),

          // [TITLE + TIMER] Quiz name and optional countdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary_100,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
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
                  // [TEXT] Quiz title
                  Text(
                    quizTitle,
                    style: const TextStyle(
                      fontFamily: "Baloo",
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text_800,
                    ),
                  ),

                  // [TIMER] Only visible in Time Attack mode
                  if (selectedGameMode == "Time Attack") ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.timer,
                      color: timeLeft <= 10
                          ? AppColors.primary_600
                          : AppColors.text_700,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(timeLeft),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: timeLeft <= 10
                            ? AppColors.primary_600
                            : AppColors.text_800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [WIDGET] Question card with progress bar and question text
  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary_100,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
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
          // [PROGRESS BAR] Question progress
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: (currentNumber + 1) / questions.length,
              minHeight: 6,
              backgroundColor: AppColors.text_200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary_600),
            ),
          ),

          const SizedBox(height: 8),

          // [COUNTER] "Question X of Y"
          Text.rich(
            TextSpan(
              style: const TextStyle(
                color: AppColors.text_800,
                fontFamily: "Nunito",
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: "Question "),
                TextSpan(
                  text: "${currentNumber + 1}",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: " of "),
                TextSpan(
                  text: "${questions.length}",
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // [TEXT] The question itself
          Text(
            selectedMode == "True or False"
                ? "True or False: ${currentQuestion.question}"
                : selectedMode == "Identification"
                    ? (isTermToDefinition
                        ? currentQuestion.question  // Show term, answer is definition
                        : currentQuestion.answer)   // Show definition, answer is term
                    : currentQuestion.question,
            style: const TextStyle(
              color: AppColors.text_800,
              fontFamily: "Baloo",
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // [WIDGET] Dispatch to the correct input widget based on mode
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

  // [WIDGET] Multiple Choice answer buttons
  Widget _buildMultipleChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: currentQuestion.choices.map((choice) {
        // [COLOR] Highlight correct/wrong after submission
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ChoiceButton(
            text: choice,
            backgroundColor: btnColor,
            onPressed: answerSubmitted
                ? () {}
                : () => _handleMultipleChoiceAnswer(choice),
            selectedAnswer: selectedAnswer == choice,
          ),
        );
      }).toList(),
    );
  }

  // [WIDGET] Identification text input + submit button
  Widget _buildIdentification() {
    // [COLOR] Field turns green/red after submission
    Color fieldColor = AppColors.secondary_50;
    if (identificationSubmitted) {
      fieldColor = identificationCorrect
          ? AppColors.green_300
          : AppColors.primary_300;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // [LABEL] Prompt text
        Text(
          isTermToDefinition ? "Define the term:" : "Identify the term:",
          style: const TextStyle(
            fontFamily: "Nunito",
            fontSize: 12,
            color: AppColors.text_400,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        // [INPUT] Answer text field
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: fieldColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.text_200, width: 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: TextField(
            controller: identificationController,
            enabled: !identificationSubmitted,
            textCapitalization: TextCapitalization.sentences,
            style: const TextStyle(fontFamily: "Nunito", fontSize: 16),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "Type your answer here...",
              hintStyle: TextStyle(color: AppColors.text_400),
            ),
            onSubmitted: (_) => _handleIdentificationSubmit(),
          ),
        ),

        const SizedBox(height: 12),

        // [FEEDBACK] Correct / wrong feedback text
        if (identificationSubmitted)
          Text(
            identificationCorrect
                ? "✓ Correct!"
                : "✗ Correct answer: ${isTermToDefinition ? currentQuestion.answer : currentQuestion.question}",
            style: TextStyle(
              fontFamily: "Nunito",
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: identificationCorrect
                  ? AppColors.green_600
                  : AppColors.primary_600,
            ),
          ),

        const SizedBox(height: 8),

        // [BUTTON] Submit answer
        ElevatedButton(
          onPressed: identificationSubmitted ? null : _handleIdentificationSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary_500,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            "Submit",
            style: TextStyle(
              fontFamily: "Nunito",
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // [WIDGET] True or False side-by-side buttons
  Widget _buildTrueOrFalse() {
    return Row(
      children: ["True", "False"].map((choice) {
        // [COLOR] Highlight correct/wrong after submission
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
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: ChoiceButton(
              text: choice,
              backgroundColor: btnColor,
              onPressed: answerSubmitted
                  ? () {}
                  : () => _handleTrueOrFalseAnswer(choice),
              selectedAnswer: selectedAnswer == choice,
            ),
          ),
        );
      }).toList(),
    );
  }
}