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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _StudyCompleteDialog(
        correctCount: correctCount,
        wrongCount: wrongCount,
        totalCards: cards.length,
        accuracy: accuracy,
        onReviewAgain: () {
          Navigator.pop(context);
          setState(() {
            currentNumber = 0;
            correctCount = 0;
            wrongCount = 0;
            isFlipped = false;
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
    setState(() => wrongCount++);
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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

class _SessionTier {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final int stars;

  const _SessionTier({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.stars,
  });

  static _SessionTier fromAccuracy(double accuracy) {
    if (accuracy >= 90) {
      return const _SessionTier(
        emoji: '🏆',
        title: 'Perfect Score!',
        subtitle: 'You absolutely nailed it!',
        color: Color(0xFFF59E0B), // amber
        stars: 3,
      );
    } else if (accuracy >= 70) {
      return _SessionTier(
        emoji: '🌟',
        title: 'Great Job!',
        subtitle: "You're really getting it!",
        color: AppColors.primary_600,
        stars: 2,
      );
    } else if (accuracy >= 50) {
      return const _SessionTier(
        emoji: '👍',
        title: 'Good Work!',
        subtitle: 'Keep building on this!',
        color: Color(0xFF0D9488), // teal
        stars: 1,
      );
    }
    return const _SessionTier(
      emoji: '💪',
      title: 'Keep Practicing!',
      subtitle: 'Every session makes you stronger!',
      color: Color(0xFFF97316), // orange
      stars: 0,
    );
  }
}

class _StudyCompleteDialog extends StatefulWidget {
  final int correctCount;
  final int wrongCount;
  final int totalCards;
  final double accuracy;
  final VoidCallback onReviewAgain;
  final VoidCallback onBack;

  const _StudyCompleteDialog({
    required this.correctCount,
    required this.wrongCount,
    required this.totalCards,
    required this.accuracy,
    required this.onReviewAgain,
    required this.onBack,
  });

  @override
  State<_StudyCompleteDialog> createState() => _StudyCompleteDialogState();
}

class _StudyCompleteDialogState extends State<_StudyCompleteDialog>
    with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _confettiCtrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  late List<Animation<double>> _starScaleAnims;
  late List<Animation<double>> _starOpacityAnims;

  List<_ConfettiPiece>? _confetti;

  bool get _showConfetti => widget.accuracy >= 70;

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Dialog slide-up + fade in
    _slideAnim = Tween<double>(begin: 56, end: 0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
      ),
    );

    // Stars stagger — each bounces in with elastic overshoot
    _starScaleAnims = List.generate(3, (i) {
      final start = 0.38 + i * 0.14;
      final end = (start + 0.22).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _mainCtrl,
          curve: Interval(start, end, curve: Curves.elasticOut),
        ),
      );
    });

    _starOpacityAnims = List.generate(3, (i) {
      final start = 0.38 + i * 0.14;
      final end = (start + 0.10).clamp(0.0, 1.0);
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _mainCtrl,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });

    if (_showConfetti) {
      _confetti = List.generate(22, (i) => _ConfettiPiece(Random(i * 17)));
    }

    _mainCtrl.forward();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = _SessionTier.fromAccuracy(widget.accuracy);

    return AnimatedBuilder(
      animation: _mainCtrl,
      builder: (context, _) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Transform.translate(
            offset: Offset(0, _slideAnim.value),
            child: Opacity(
              opacity: _fadeAnim.value,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Main card ──────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Emoji + headline ─────────────────────────
                        Text(tier.emoji,
                            style: const TextStyle(fontSize: 52)),
                        const SizedBox(height: 6),
                        Text(
                          tier.title,
                          style: TextStyle(
                            fontFamily: 'Baloo',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: tier.color,
                          ),
                        ),
                        Text(
                          tier.subtitle,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: AppColors.text_400,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Stars ────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) {
                            final filled = i < tier.stars;
                            return Opacity(
                              opacity: _starOpacityAnims[i].value,
                              child: Transform.scale(
                                scale: _starScaleAnims[i].value,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5),
                                  child: Icon(
                                    filled
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 44,
                                    color: filled
                                        ? const Color(0xFFF59E0B)
                                        : AppColors.text_300,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),

                        const SizedBox(height: 22),

                        // ── Accuracy ring + stat rows ─────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Circular accuracy ring
                            SizedBox(
                              width: 92,
                              height: 92,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                    begin: 0,
                                    end: widget.accuracy / 100),
                                duration:
                                    const Duration(milliseconds: 1100),
                                curve: Curves.easeOutCubic,
                                builder: (_, value, __) => CustomPaint(
                                  painter: _AccuracyRingPainter(
                                      value, tier.color),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${(value * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontFamily: 'Baloo',
                                            fontSize: 18,
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

                            // Stat rows
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  _buildStatRow(
                                    icon: Icons.check_circle_rounded,
                                    label: 'Correct',
                                    value: widget.correctCount,
                                    color: Colors.green.shade600,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildStatRow(
                                    icon: Icons.cancel_rounded,
                                    label: 'Wrong',
                                    value: widget.wrongCount,
                                    color: Colors.red.shade500,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildStatRow(
                                    icon: Icons.style_rounded,
                                    label: 'Cards',
                                    value: widget.totalCards,
                                    color: AppColors.text_600,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        // ── Buttons ───────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: widget.onReviewAgain,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.text_600,
                                  side: const BorderSide(
                                      color: AppColors.text_100,
                                      width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                child: const Text(
                                  'Review Again',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
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
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                ),
                                child: const Text(
                                  'Back to Cards',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Confetti overlay (clipped to card) ─────────────
                  if (_showConfetti && _confetti != null)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedBuilder(
                            animation: _confettiCtrl,
                            builder: (_, __) => CustomPaint(
                              painter: _ConfettiPainter(
                                  _confettiCtrl.value, _confetti!),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, animated, __) => Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              color: AppColors.text_400,
            ),
          ),
          const Spacer(),
          Text(
            '${animated.round()}',
            style: TextStyle(
              fontFamily: 'Baloo',
              fontSize: 20,
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
  final double progress; // 0.0 – 1.0
  final Color color;

  _AccuracyRingPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 7;
    const strokeW = 8.0;
    const startAngle = -pi / 2;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFF3F4F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    if (progress > 0) {
      // Glow behind arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * pi * progress,
        false,
        Paint()
          ..color = color.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 6
          ..strokeCap = StrokeCap.round,
      );

      // Main arc
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

// ─── CONFETTI ───────────────────────────────────────────────────────────────

class _ConfettiPiece {
  final double x;
  final double speed;
  final double size;
  final double phase;
  final double wobble;
  final Color color;

  static const _colors = [
    Color(0xFFF59E0B), // amber
    Color(0xFFF472B6), // pink
    Color(0xFF60A5FA), // blue
    Color(0xFF34D399), // green
    Color(0xFFA78BFA), // purple
    Color(0xFFFB923C), // orange
  ];

  _ConfettiPiece(Random r)
      : x = r.nextDouble(),
        speed = 0.18 + r.nextDouble() * 0.38,
        size = 5 + r.nextDouble() * 7,
        phase = r.nextDouble(),
        wobble = 0.5 + r.nextDouble() * 1.5,
        color = _colors[r.nextInt(_colors.length)];
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<_ConfettiPiece> pieces;

  _ConfettiPainter(this.t, this.pieces);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final progress = (p.phase + p.speed * t) % 1.0;
      final y = progress * (size.height + 24) - 12;
      final x = p.x * size.width + sin((t * p.wobble + p.phase) * 2 * pi) * 18;
      final rotation = t * p.wobble * pi;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);

      final paint = Paint()..color = p.color.withOpacity(0.75);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero,
              width: p.size,
              height: p.size * 0.45),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
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