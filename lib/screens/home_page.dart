// [IMPORT] Libraries
import 'package:flutter/material.dart';
import 'dart:math';

// [IMPORT] App
import 'package:soro/main.dart';

// [IMPORT] Widgets
import 'package:soro/widgets/streak_calendar.dart';

// [IMPORT] Database
import 'package:soro/database/database_helper.dart';

// Trivia list
final List<String> triviaList = [
  "Did you know? Mitochondria are the powerhouse of the cell!",
  "Fun fact: Honey never spoils!",
  "Trivia: Bananas are berries, but strawberries aren't!",
  "Did you know? Octopuses have three hearts!",
  "Fun fact: Your stomach gets a new lining every 3–4 days.",
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // [STATE]
  String _firstName = "there"; // fallback until loaded
  int _cardsCreated = 0;
  int? _accuracy; // null means no quizzes taken yet
  int _streak = 0;
  bool _isLoading = true;

  // [PROGRESSION]
  String _rankTitle = "Novice";
  String _rankIcon = "🌱";
  int _totalExp = 0;
  int _totalCoins = 0;
  int _currentLevelExp = 0;
  int _nextLevelExp = 500;
  double _expProgress = 0.0;

  // Random trivia (picked once per build)
  final String _trivia = triviaList[Random().nextInt(triviaList.length)];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // [ACTION] Load user profile + stats from Hive
  Future<void> _loadData() async {
    final db = DatabaseHelper();

    final user    = await db.getLoggedInUser();
    final stats   = await db.getProgressionStats();
    final academic = await db.getAcademicStats();

    if (!mounted) return;

    // Extract first name only for the greeting
    final fullName  = (user?['fullName'] as String? ?? '').trim();
    final firstName = fullName.isNotEmpty
        ? fullName.split(' ').first
        : (user?['email'] as String? ?? 'there').split('@').first;

    // [RANK] Calculate rank from total EXP
    final rankInfo = DatabaseHelper.getRankFromExp(stats.totalExp);

    setState(() {
      _firstName    = firstName;
      _cardsCreated = academic['cardsCreated'] as int;
      _accuracy     = academic['accuracy'] as int?;
      _streak       = academic['streakDays'] as int;
      _isLoading    = false;

      // [PROGRESSION]
      _rankTitle       = rankInfo['title']    as String;
      _rankIcon        = rankInfo['icon']     as String;
      _totalExp        = stats.totalExp;
      _totalCoins      = stats.totalCoins;
      _currentLevelExp = rankInfo['minExp']   as int;
      _nextLevelExp    = rankInfo['nextExp']  as int? ?? _currentLevelExp;
      _expProgress     = rankInfo['progress'] as double;
    });
  }

  // [HELPER] Time-based greeting
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening,";
  }

  // [WIDGET] A single stat column inside the progress card
  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Baloo',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: 0,
            color: AppColors.primary_600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.5,
            letterSpacing: 0.5,
            color: AppColors.text_700,
          ).copyWith(
            color: AppColors.text_600,
          ),
        ),
      ],
    );
  }

  // [WIDGET] Rank icon with circular XP progress ring
  Widget _buildRankIcon() {
    // Ring turns amber when the rank is maxed out (progress == 1.0)
    final ringColor = _expProgress >= 1.0 ? Colors.amber : AppColors.primary_500;

    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // [RING] XP progress ring drawn around the icon
          CustomPaint(
            size: const Size(76, 76),
            painter: _XpRingPainter(
              progress: _expProgress,
              ringColor: ringColor,
              trackColor: AppColors.secondary_300,
            ),
          ),

          // [ICON] Rank tier emoji inside a rounded square
          Container(
            width: 56,
            height: 56,
            child: Center(
              child: Text(
                _rankIcon,
                style: const TextStyle(
                  fontFamily: 'Baloo',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: AppColors.text_900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accuracyLabel = _accuracy != null ? '$_accuracy%' : '—';

    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/home-page-bg.png"),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // [BAR] Top with Title
              const SizedBox(height: 24),

              // [SECTION] Greeting
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _isLoading
                        ? Container(
                            height: 30,
                            width: 200,
                            decoration: BoxDecoration(
                              color: AppColors.text_100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          )
                        : Text(
                            "${_greeting()} $_firstName!",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Baloo',
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              letterSpacing: 0,
                              color: AppColors.text_900,
                            ).copyWith(
                              color: Colors.white,
                            ),
                          ),

                    const SizedBox(height: 4),

                    Text(
                      "Ready to study?",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0.5,
                        color: AppColors.text_200,
                      ).copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // [SECTION] Progress Dashboard (Level + Stats + Streak)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary_200,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // [SECTION] Level
                    Row(
                      children: [
                        // [WIDGET] Rank icon + XP ring
                        _buildRankIcon(),

                        const SizedBox(width: 12),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Level ${(_totalExp ~/ 500) + 1}",
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                letterSpacing: 0.5,
                                color: AppColors.text_700,
                              ).copyWith(
                                color: AppColors.text_500,
                              ),
                            ),
                            Text(
                              _rankTitle,
                              style: const TextStyle(
                                fontFamily: 'Baloo',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                                letterSpacing: 0,
                                color: AppColors.text_900,
                              ),
                            ),
                            Text(
                              "$_totalExp / $_nextLevelExp XP",
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 1.5,
                                letterSpacing: 0.4,
                                color: AppColors.text_400,
                              ).copyWith(
                                color: AppColors.text_500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /*// [PROGRESS BAR] XP Progress
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Experience Progress",
                              style: TextStyle(
                                fontFamily: "Nunito",
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.text_600,
                              ),
                            ),
                            Text(
                              "${(_expProgress * 100).toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                                letterSpacing: 0.5,
                                color: AppColors.text_700,
                              ).copyWith(
                                color: AppColors.text_600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _expProgress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: AppColors.text_100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _expProgress >= 1.0 ? Colors.amber : AppColors.primary_500,
                            ),
                          ),
                        ),
                      ],
                    ), */

                    const SizedBox(height: 12),

                    // [COINS] Display total coins earned
                    /*Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            "🪙",
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Coins",
                                style: TextStyle(
                                  fontFamily: "Nunito",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text_600,
                                ),
                              ),
                              Text(
                                "$_totalCoins",
                                style: const TextStyle(
                                  fontFamily: "Baloo",
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ), */

                    const SizedBox(height: 16),

                    // [SECTION] Statistics
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary_100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _statItem('$_cardsCreated', 'Cards'),
                          _statItem(accuracyLabel, 'Accuracy'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // [COMPONENT] Streak Calendar
                    StreakCalendar(streak: _streak),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // [SECTION] Quick Access Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              homeNavKey.currentState?.onTabSelected(2);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.primary_500,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.psychology, color: Colors.white, size: 28),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Study Now",
                                    style: const TextStyle(
                                      fontFamily: 'Nunito',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      height: 1.5,
                                      letterSpacing: 0.5,
                                      color: AppColors.text_700,
                                    ).copyWith(
                                      color: AppColors.text_50,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              homeNavKey.currentState?.onTabSelected(1);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.text_50,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.style, color: AppColors.text_50, size: 28),
                                  SizedBox(height: 6),
                                  Text(
                                    "Create Deck",
                                    style: TextStyle(
                                      fontFamily: "Baloo",
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.text_50,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // [TRIVIA]
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      _trivia,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 0.25,
                        color: AppColors.text_300,
                      ).copyWith(
                        color: AppColors.text_800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // [MASCOT]
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Image.asset(
                      'assets/images/soro-mascot.png',
                      width: 120,
                      height: 120,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// [PAINTER] Circular XP progress ring drawn around the rank tier icon
// ─────────────────────────────────────────────────────────────────────────────
class _XpRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;

  const _XpRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center     = Offset(size.width / 2, size.height / 2);
    final radius     = (size.width / 2) - 3.5;
    const strokeWidth = 4.5;

    // [TRACK] Full grey background circle
    final trackPaint = Paint()
      ..color       = trackColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap   = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // [ARC] Filled progress arc, starts at the top (−90°)
    if (progress > 0) {
      final progressPaint = Paint()
        ..color       = ringColor
        ..style       = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap   = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,                            // top of circle
        2 * pi * progress.clamp(0.0, 1.0), // sweep angle
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_XpRingPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor;
}