import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';
import 'package:soro/main.dart';
import 'package:soro/database/database_helper.dart';

class CardsPlay extends StatefulWidget {
  const CardsPlay({super.key});

  @override
  State<CardsPlay> createState() => _CardsPlayState();
}

class _CardsPlayState extends State<CardsPlay>
    with TickerProviderStateMixin {
  int currentNumber = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool isFlipped = false;
  List<int> _missedIndices = [];

  String deckTitle = "Flashcard Deck";
  List<Map<String, dynamic>> cards = [];

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  Ticker? _particleTicker;
  ValueNotifier<double>? _particleTime;
  List<_Particle>? _particles;

  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(14, (i) => _Particle(Random(i * 7)));
    _particleTime = ValueNotifier(0);
    _particleTicker = createTicker((elapsed) {
      _particleTime!.value = elapsed.inMilliseconds / 1000.0;
    });
    _particleTicker!.start();

    _flipController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
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
    _flipController.dispose();
    _particleTicker?.dispose();
    _particleTime?.dispose();
    super.dispose();
  }

  void _loadSettings() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      deckTitle = args['title'] ?? "Flashcard Deck";
      final cardsList = args['cards'] as List? ?? [];
      final randomizeOrder = args['randomizeOrder'] as bool? ?? false;
      final randomizeSides = args['randomizeSides'] as bool? ?? false;

      if (cardsList.isNotEmpty) {
        // [COPY] Work on a mutable copy so the original deck data is unchanged
        cards = cardsList.cast<Map<String, dynamic>>()
            .map((c) => Map<String, dynamic>.from(c))
            .toList();

        // [RANDOMIZE] Shuffle card order each play session
        if (randomizeOrder) cards.shuffle(Random());

        // [RANDOMIZE] Randomly flip front/back for each card each play session
        if (randomizeSides) {
          final rng = Random();
          for (final card in cards) {
            if (rng.nextBool()) {
              final temp = card['term'];
              card['term'] = card['definition'];
              card['definition'] = temp;
            }
          }
        }
      }
    }

    setState(() {});
  }

  Map<String, dynamic> get currentCard => cards[currentNumber];

  void _toggleFlip() {
    if (_flipController.isCompleted) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => isFlipped = !isFlipped);
  }

  void _handleBack() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _confirmGoBack() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Leave Study Session?",
          style: TextStyle(fontFamily: "Baloo", fontWeight: FontWeight.w700),
        ),
        content: const Text(
          "Your progress will not be saved. Are you sure?",
          style: TextStyle(fontFamily: "Nunito"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.text_600,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text("Cancel", style: TextStyle(fontFamily: "Nunito")),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleBack();
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

  // ─── STUDY COMPLETE DIALOG ──────────────────────────────────────────────────

  Future<void> _submitSession() async {
    if (!mounted) return;

    final accuracy = cards.isNotEmpty
        ? (correctCount / cards.length) * 100
        : 0.0;
    final skippedCount = cards.length - correctCount - wrongCount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StudyCompleteDialog(
        correctCount: correctCount,
        wrongCount: wrongCount,
        skippedCount: skippedCount,
        totalCards: cards.length,
        accuracy: accuracy,
        onReviewAll: () {
          Navigator.pop(context);
          setState(() {
            currentNumber = 0;
            correctCount = 0;
            wrongCount = 0;
            isFlipped = false;
            _missedIndices = [];
            _flipController.reset();
          });
        },
        onReviewMissed: () {
          final missed = _missedIndices
              .map((i) => Map<String, dynamic>.from(cards[i]))
              .toList();
          Navigator.pop(context);
          setState(() {
            cards = missed;
            currentNumber = 0;
            correctCount = 0;
            wrongCount = 0;
            isFlipped = false;
            _missedIndices = [];
            _flipController.reset();
          });
        },
        onBack: () {
          Navigator.pop(context);
          _handleBack();
        },
      ),
    );
  }

  void _markCorrect() {
    setState(() => correctCount++);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _nextCard();
    });
  }

  void _markWrong() {
    setState(() {
      wrongCount++;
      _missedIndices.add(currentNumber);
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _nextCard();
    });
  }

  void _nextCard() {
    if (currentNumber < cards.length - 1) {
      setState(() {
        currentNumber++;
        isFlipped = false;
        _flipController.reset();
      });
    } else {
      _submitSession();
    }
  }

  void _previousCard() {
    if (currentNumber > 0) {
      setState(() {
        currentNumber--;
        isFlipped = false;
        _flipController.reset();
      });
    }
  }

  // ─── WIDGETS ────────────────────────────────────────────────────────────────

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

  // [WIDGET] Top row: back button + deck title chip — mirrors quiz _buildHeader
  Widget _buildHeader() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // [BUTTON] Back with confirmation
          SizedBox(
            width: 48,
            child: ElevatedButton(
              onPressed: _confirmGoBack,
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                backgroundColor:
                    const WidgetStatePropertyAll(AppColors.secondary_50),
                foregroundColor:
                    const WidgetStatePropertyAll(AppColors.text_700),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side:
                        const BorderSide(color: AppColors.text_100, width: 2),
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

          // [TITLE] Deck name chip
          Expanded(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondary_50,
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
              child: Text(
                deckTitle,
                textAlign: TextAlign.left,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Baloo',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text_800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [WIDGET] Flippable card — clean NotebookLM-style, front/back differ only by bg
  Widget _buildFlippableCard() {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (ctx, child) {
          final angle = _flipAnimation.value * 3.14159;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle);

          final isBack = _flipAnimation.value > 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: transform,
            child: Container(
              height: 330,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                // [FRONT] Clean white / [BACK] Soft warm tint
                color: isBack ? AppColors.secondary_100 : Colors.white,
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
              child: Transform(
                alignment: Alignment.center,
                transform: isBack
                    ? (Matrix4.identity()..rotateY(3.14159))
                    : Matrix4.identity(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // [COUNTER] "Card X of Y" + progress bar
                      Text(
                        "Card ${currentNumber + 1} of ${cards.length}",
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: AppColors.text_400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // [TEXT] Card content — left-aligned, vertically centered
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            isBack
                                ? (currentCard['definition'] as String? ?? "")
                                : (currentCard['term'] as String? ?? ""),
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text_800,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),

                      // [HINT] Tap to flip
                      Text(
                        "Tap to flip",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: AppColors.text_300,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // [WIDGET] Bottom controls: prev / wrong / correct / next — styled like quiz input container
  Widget _buildBottomControls(bool isLastCard) {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // [PREV] Back arrow button
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: currentNumber > 0 ? _previousCard : null,
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                backgroundColor: WidgetStatePropertyAll(
                  currentNumber > 0
                      ? AppColors.secondary_50
                      : AppColors.secondary_200,
                ),
                foregroundColor: WidgetStatePropertyAll(
                  currentNumber > 0
                      ? AppColors.text_700
                      : AppColors.text_300,
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                        color: AppColors.text_100, width: 2),
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  "<",
                  style: TextStyle(
                    fontFamily: "Nunito",
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),

          // [WRONG] Mark wrong
          GestureDetector(
            onTap: _markWrong,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.close, color: Colors.red.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$wrongCount',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // [CORRECT] Mark correct
          GestureDetector(
            onTap: _markCorrect,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: Colors.green.shade200, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.check, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '$correctCount',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // [NEXT / SUBMIT] Forward arrow or checkmark on last card
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: isLastCard ? _submitSession : _nextCard,
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                splashFactory: NoSplash.splashFactory,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                backgroundColor:
                    const WidgetStatePropertyAll(AppColors.secondary_50),
                foregroundColor:
                    const WidgetStatePropertyAll(AppColors.primary_600),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(
                        color: AppColors.text_100, width: 2),
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  isLastCard ? "✓" : ">",
                  style: const TextStyle(
                    fontFamily: "Nunito",
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLastCard = currentNumber == cards.length - 1;

    // [EMPTY] Fallback state
    if (cards.isEmpty) {
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
                  _buildHeader(),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "No cards to study",
                        style: TextStyle(
                          fontFamily: "Nunito",
                          color: AppColors.text_600,
                        ),
                      ),
                    ),
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
                // [HEADER] Back button + deck title
                _buildHeader(),

                const SizedBox(height: 20),

                // [CARD] Flippable flashcard — vertically centered in remaining space
                Expanded(
                  child: Center(
                    child: _buildFlippableCard(),
                  ),
                ),

                // [CONTROLS] Navigation + wrong / correct buttons
                _buildBottomControls(isLastCard),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── STUDY COMPLETE DIALOG ──────────────────────────────────────────────────

class _StudyCompleteDialog extends StatefulWidget {
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final int totalCards;
  final double accuracy;
  final VoidCallback onReviewAll;
  final VoidCallback onReviewMissed;
  final VoidCallback onBack;

  const _StudyCompleteDialog({
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    required this.totalCards,
    required this.accuracy,
    required this.onReviewAll,
    required this.onReviewMissed,
    required this.onBack,
  });

  @override
  State<_StudyCompleteDialog> createState() => _StudyCompleteDialogState();
}

class _StudyCompleteDialogState extends State<_StudyCompleteDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  bool _showingReviewChoice = false;

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
                          const Text(
                            'Session Complete',
                            style: TextStyle(
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
                              label: 'Got it',
                              value: widget.correctCount,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(height: 10),
                            _buildStatRow(
                              label: 'Missed it',
                              value: widget.wrongCount,
                              color: Colors.red.shade500,
                            ),
                            const SizedBox(height: 10),
                            _buildStatRow(
                              label: 'Skipped',
                              value: widget.skippedCount,
                              color: AppColors.text_400,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Buttons ────────────────────────────────────────
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _showingReviewChoice
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                setState(() => _showingReviewChoice = true),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.text_600,
                              side: const BorderSide(
                                  color: AppColors.text_100, width: 1.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 13),
                            ),
                            child: const Text(
                              'Review Again',
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 13),
                            ),
                            child: const Text(
                              'Back to Cards',
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
                        Text(
                          'Review which cards?',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text_400,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: widget.onReviewAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary_100,
                            foregroundColor: AppColors.text_700,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 13),
                          ),
                          child: const Text(
                            'All cards',
                            style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: widget.wrongCount > 0
                              ? widget.onReviewMissed
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary_600,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.secondary_200,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(
                                vertical: 13),
                          ),
                          child: Text(
                            widget.wrongCount > 0
                                ? 'Only missed (${widget.wrongCount})'
                                : 'No missed cards',
                            style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showingReviewChoice = false),
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