import 'package:flutter/material.dart';
import 'dart:math';
import 'package:soro/main.dart';
import 'package:soro/database/database_helper.dart';

class CardsPlay extends StatefulWidget {
  const CardsPlay({super.key});

  @override
  State<CardsPlay> createState() => _CardsPlayState();
}

class _CardsPlayState extends State<CardsPlay>
    with SingleTickerProviderStateMixin {
  int currentNumber = 0;
  int correctCount = 0;
  int wrongCount = 0;
  bool isFlipped = false;

  String deckTitle = "Flashcard Deck";
  List<Map<String, dynamic>> cards = [];

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  bool _settingsLoaded = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _submitSession() async {
    final accuracy = cards.isNotEmpty
        ? ((correctCount / cards.length) * 100).toStringAsFixed(1)
        : '0';

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Study Session Complete!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Correct: $correctCount / ${cards.length}"),
            Text("Wrong: $wrongCount / ${cards.length}"),
            Text("Accuracy: $accuracy%"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text("✨ Cards reviewed: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("${cards.length}", style: const TextStyle(color: Colors.blue)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentNumber = 0;
                correctCount = 0;
                wrongCount = 0;
                isFlipped = false;
                _flipController.reset();
              });
            },
            child: const Text("Review Again"),
          ),

          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleBack();
            },
            child: const Text("Back to Cards"),
          ),
        ],
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.text_200.withOpacity(0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: isBack ? (Matrix4.identity()..rotateY(3.14159)) : Matrix4.identity(),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      top: 16,
                      right: 16,
                      child: SizedBox(
                        width: 96,
                        height: 96,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0, bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Card ${currentNumber + 1} of ${cards.length}",
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              color: AppColors.text_400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: Center(
                              child: Text(
                                isBack
                                    ? (currentCard['definition'] as String? ?? "")
                                    : (currentCard['term'] as String? ?? ""),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Baloo',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text_800,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Tap card to flip",
                            textAlign: TextAlign.center,
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastCard = currentNumber == cards.length - 1;

    return cards.isEmpty
        ? Scaffold(
            backgroundColor: AppColors.secondary_50,
            appBar: AppBar(
              title: const Text("Study Flashcards",
                  style: TextStyle(fontFamily: 'Baloo', fontWeight: FontWeight.w700)),
              backgroundColor: AppColors.primary_600,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: const Center(
              child: Text("No cards to study"),
            ),
          )
        : Scaffold(
            backgroundColor: AppColors.secondary_50,
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    color: AppColors.secondary_50,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: _confirmGoBack,
                          color: AppColors.primary_600,
                          splashRadius: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.text_200.withOpacity(0.25),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              deckTitle,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.text_800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildFlippableCard(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: currentNumber > 0 ? _previousCard : null,
                          icon: const Icon(Icons.arrow_back),
                          color: currentNumber > 0 ? AppColors.text_700 : AppColors.text_300,
                          iconSize: 24,
                          splashRadius: 24,
                        ),

                        GestureDetector(
                          onTap: _markWrong,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
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

                        GestureDetector(
                          onTap: _markCorrect,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200, width: 1.5),
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

                        IconButton(
                          onPressed: isLastCard ? _submitSession : _nextCard,
                          icon: Icon(isLastCard ? Icons.check : Icons.arrow_forward),
                          color: AppColors.primary_600,
                          iconSize: 24,
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}