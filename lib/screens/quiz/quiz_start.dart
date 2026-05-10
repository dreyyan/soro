// [IMPORT] Libraries
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'dart:async';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Screens
import 'package:soro/screens/quiz/quiz_settings.dart';

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

class _QuizStartState extends State<QuizStart> with TickerProviderStateMixin {
  // [STATES] Quiz progress
  int score = 0;
  int currentNumber = 0;
  String selectedAnswer = "";
  bool answerSubmitted = false;
  String quizTitle = "Quiz";

  // [STATES] Timer
  Timer? timer;
  int? timeLeft;         // null = timer disabled
  int? _originalTimeLimit;

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
  bool randomizeQuestions = false;

  // [GETTER] Current question shorthand
  Question get currentQuestion => questions[currentNumber];

  // [FLAG] Prevent _loadSettings from running twice
  bool _settingsLoaded = false;

  // [PARTICLES] Animated background
  Ticker? _particleTicker;
  ValueNotifier<double>? _particleTime;
  List<_Particle>? _particles;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(14, (i) => _Particle(Random(i * 7)));
    _particleTime = ValueNotifier(0);
    _particleTicker = createTicker((elapsed) {
      _particleTime!.value = elapsed.inMilliseconds / 1000.0;
    });
    _particleTicker!.start();
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
    _particleTicker?.dispose();
    _particleTime?.dispose();
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
      randomizeQuestions = args['randomizeQuestions'] ?? false;

      final savedSecs = args['timeLimitSecs'] as int?;
      timeLeft           = (savedSecs != null && savedSecs > 0) ? savedSecs : null;
      _originalTimeLimit = timeLeft;

      final rawList = args['questions'] as List?;
      if (rawList != null && rawList.isNotEmpty) {
        questions = rawList.map((q) {
          final map = Map<String, dynamic>.from(q as Map);
          final type = map['type'] as String? ?? 'Multiple Choice';
          
          // [CONVERT] True/False answer from string to normalized label
          final rawAnswer = map['answer'] as String? ?? '';
          final normalizedAnswer = type == 'True or False'
              ? (rawAnswer.toLowerCase() == 'true' ? 'True' : 'False')
              : rawAnswer;
          final trueFalseAnswer = type == 'True or False'
              ? normalizedAnswer == 'True'
              : true;

          return Question(
            map['question'] as String,
            normalizedAnswer,
            List<String>.from(map['choices'] ?? []),
            type,
            trueFalseAnswer,
          );
        }).toList();
        
        // [SHUFFLE] Randomize question order if enabled
        if (randomizeQuestions) {
          questions.shuffle(Random());
        }
      }
    }

    setState(() {});

    if (questions.isNotEmpty) {
      _generateChoices();
      _setIdentificationDirection();
      if (timeLeft != null) _startTimer();
    }
  }

  // [GENERATE] Build answer choices for Multiple Choice and True or False
  void _generateChoices() {
    final random = Random();
    final allAnswers = questions.map((q) => q.answer).toList();

    for (var question in questions) {
      // [TRUE OR FALSE] Fixed choices
      if (question.type == "True or False") {
        question.choices = ["True", "False"];
        continue;
      }

      // [IDENTIFICATION] No choices needed
      if (question.type == "Identification") {
        question.choices = [];
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

  // [TIMER] Start countdown
  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if ((timeLeft ?? 0) > 0) {
        setState(() => timeLeft = timeLeft! - 1);
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

  // [NAVIGATE] Return to the quiz list page
  void _handleBack() {
    Navigator.popUntil(context, (route) => route.settings.name == '/quiz' || route.isFirst);
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
            "Leave", 
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

    final wrongCount = questions.length - score;
    final accuracy   = questions.isNotEmpty ? (score / questions.length) * 100 : 0.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _QuizCompleteDialog(
        correctCount:   score,
        wrongCount:     wrongCount,
        totalQuestions: questions.length,
        accuracy:       accuracy,
        rewards:        rewards,
        isTimeAttack:   selectedGameMode == "Time Attack",
        onRestart: () {
          Navigator.pop(context);
          setState(() {
            currentNumber          = 0;
            score                  = 0;
            selectedAnswer         = "";
            identificationController.clear();
            identificationSubmitted = false;
            timeLeft               = _originalTimeLimit;
          });
          _generateChoices();
          if (timeLeft != null) _startTimer();
        },
        onBack: () {
          Navigator.pop(context);
          _handleBack();
        },
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
        backgroundColor: AppColors.secondary_300,
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            Center(
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
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.secondary_300,
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          Padding(
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
        ],
      ),
    );
  }

  // [WIDGET] Animated particle background
  Widget _buildBackground() {
    final notifier = _particleTime;
    final parts = _particles;
    if (notifier == null || parts == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: notifier,
      builder: (_, __) => CustomPaint(
        painter: _ParticlePainter(notifier.value, parts),
        child: const SizedBox.expand(),
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

                  // [TIMER] Only shown when timer is enabled
                  if (timeLeft != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.timer,
                      color: timeLeft! <= 10
                          ? AppColors.primary_600
                          : AppColors.text_700,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(timeLeft!),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: timeLeft! <= 10
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
            currentQuestion.type == "True or False"
                ? currentQuestion.question
                : currentQuestion.type == "Identification"
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

  // [WIDGET] Dispatch to the correct input widget based on current question type
  Widget _buildInputSection() {
    switch (currentQuestion.type) {
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

  // [WIDGET] True or False vertical buttons (True on top, False below)
  Widget _buildTrueOrFalse() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: ChoiceButton(
            text: choice,
            backgroundColor: btnColor,
            onPressed: answerSubmitted
                ? () {}
                : () => _handleTrueOrFalseAnswer(choice),
            selectedAnswer: selectedAnswer == choice,
          ),
        );
      }).toList(),
    );
  }
}

// ─── QUIZ COMPLETE DIALOG ───────────────────────────────────────────────────

class _QuizCompleteDialog extends StatefulWidget {
  final int correctCount;
  final int wrongCount;
  final int totalQuestions;
  final double accuracy;
  final Map<String, dynamic> rewards;
  final bool isTimeAttack;
  final VoidCallback onRestart;
  final VoidCallback onBack;

  const _QuizCompleteDialog({
    required this.correctCount,
    required this.wrongCount,
    required this.totalQuestions,
    required this.accuracy,
    required this.rewards,
    required this.isTimeAttack,
    required this.onRestart,
    required this.onBack,
  });

  @override
  State<_QuizCompleteDialog> createState() => _QuizCompleteDialogState();
}

class _QuizCompleteDialogState extends State<_QuizCompleteDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  bool _showingReplayChoice = false;

  ({String emoji, String message, Color color}) get _tier {
    if (widget.accuracy >= 90) {
      return (emoji: '🏆', message: 'Perfect score!', color: const Color(0xFFF59E0B));
    } else if (widget.accuracy >= 70) {
      return (emoji: '🌟', message: 'Great job!', color: AppColors.primary_600);
    } else if (widget.accuracy >= 50) {
      return (emoji: '👍', message: 'Good work!', color: const Color(0xFF0D9488));
    }
    return (emoji: '💪', message: 'Keep practicing!', color: const Color(0xFFF97316));
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = _tier;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Transform.translate(
          offset: Offset(0, _slideAnim.value),
          child: Opacity(
            opacity: _fadeAnim.value,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────
                  Row(
                    children: [
                      Text(tier.emoji,
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isTimeAttack ? "Time's Up!" : 'Quiz Complete',
                            style: const TextStyle(
                              fontFamily: 'Baloo',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text_800,
                            ),
                          ),
                          Text(
                            tier.message,
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: tier.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ── Ring + Stats ───────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: widget.accuracy / 100),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, __) => CustomPaint(
                            painter: _AccuracyRingPainter(value, tier.color),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${(value * 100).toStringAsFixed(0)}%",
                                    style: TextStyle(
                                      fontFamily: 'Baloo',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: tier.color,
                                    ),
                                  ),
                                  const Text(
                                    'accuracy',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 10,
                                      color: AppColors.text_400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatRow(
                              label: 'Correct',
                              value: widget.correctCount,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(height: 10),
                            _buildStatRow(
                              label: 'Wrong',
                              value: widget.wrongCount,
                              color: Colors.red.shade500,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Rewards ────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('⚡ XP Earned: ',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    color: AppColors.text_700,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text(
                              '+${widget.rewards['expEarned']}',
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  color: Colors.blue,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('🪙 Coins Earned: ',
                                style: TextStyle(
                                    fontFamily: 'Nunito',
                                    color: AppColors.text_700,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                            Text(
                              '+${widget.rewards['coinsEarned']}',
                              style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  color: Colors.orange,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                        if (widget.rewards['leveledUp'] as bool) ...[
                          const SizedBox(height: 4),
                          const Text(
                            '🎉 Level Up!',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Buttons ────────────────────────────────────────
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _showingReplayChoice
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _showingReplayChoice = true),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text_600,
                              side: const BorderSide(
                                  color: AppColors.text_100, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text(
                              'Play Again',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onBack,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary_600,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                            ),
                            child: const Text(
                              'Back to Menu',
                              style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Play which questions?',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text_400,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: widget.onRestart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary_100,
                            foregroundColor: AppColors.text_700,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text(
                            'All questions',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showingReplayChoice = false),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.text_400,
                            padding: EdgeInsets.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                                fontFamily: 'Nunito', fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required int value,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, animated, __) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: AppColors.text_400,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            "${animated.round()}",
            style: TextStyle(
              fontFamily: 'Baloo',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ACCURACY RING PAINTER ──────────────────────────────────────────────────

class _AccuracyRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _AccuracyRingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 7;
    const strokeW = 8.0;
    const startAngle = -pi / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFF3F4F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * pi * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_AccuracyRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── PARTICLE BACKGROUND ────────────────────────────────────────────────────

class _Particle {
  final double originX, originY, radius, velX, velY;

  _Particle(Random r)
      : originX = r.nextDouble(),
        originY = r.nextDouble(),
        radius = 20 + r.nextDouble() * 40,
        velX = (r.nextDouble() - 0.5) * 0.04,
        velY = (r.nextDouble() - 0.5) * 0.04;
}

class _ParticlePainter extends CustomPainter {
  final double t;
  final List<_Particle> particles;

  _ParticlePainter(this.t, this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      // Wrap around screen edges using modulo — truly endless
      final x = ((p.originX + p.velX * t) % 1.0 + 1.0) % 1.0;
      final y = ((p.originY + p.velY * t) % 1.0 + 1.0) % 1.0;
      final paint = Paint()
        ..color = AppColors.primary_500.withOpacity(i.isEven ? 0.18 : 0.10)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}