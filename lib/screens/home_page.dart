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

    final user  = await db.getLoggedInUser();
    final stats = await db.getUserStats();

    if (!mounted) return;

    // Extract first name only for the greeting
    final fullName = (user?['fullName'] as String? ?? '').trim();
    final firstName = fullName.isNotEmpty
        ? fullName.split(' ').first
        : (user?['email'] as String? ?? 'there').split('@').first;

    setState(() {
      _firstName    = firstName;
      _cardsCreated = stats['cardsCreated'] as int;
      _accuracy     = stats['accuracy'] as int?;
      _streak       = stats['streakDays'] as int;
      _isLoading    = false;
    });
  }

  // [HELPER] Time-based greeting
  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  // [WIDGET] A single stat column inside the progress card
  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary_600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Nunito",
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.text_600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final accuracyLabel = _accuracy != null ? '$_accuracy%' : '—';
    final streakLabel   = _streak > 0 ? '$_streak🔥' : '0';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/home-page-bg.png"),
            fit: BoxFit.cover,
          ),
        ),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // [BAR] Top with Title
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.primary_500,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Soro",
                      style: TextStyle(
                        color: AppColors.secondary_50,
                        fontFamily: "TheFoxTail",
                        fontSize: 44,
                      ),
                    ),
                  ],
                ),
              ),
        
              const SizedBox(height: 24),
        
              // [SECTION] Greeting
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.secondary_50,
                  borderRadius: BorderRadius.circular(8),
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
                            style: const TextStyle(
                              fontFamily: "Baloo",
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text_800,
                            ),
                          ),

                    const SizedBox(height: 4),

                    const Text(
                      "Ready to study?",
                      style: TextStyle(
                        fontFamily: "Nunito",
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text_500,
                      ),
                    ),
                  ],
                ),
              ),
        
              const SizedBox(height: 16),

              // [SECTION] Level
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.secondary_100,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TODO [COMPONENT] Icon w/ Level Progress Bar
                    Container(
                      width: 72, height: 72,
                      color: AppColors.text_300,
                    ),

                    SizedBox(width: 16),

                    // [SECTION] Level Information
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Level 1",
                          style: TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text_500,
                          ),
                        ),
                        const Text(
                          "Novice",
                          style: TextStyle(
                            fontFamily: "Baloo",
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text_700,
                          ),
                        ),
                        const Text(
                          "5/500 XP",
                          style: TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.text_500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // [SECTION] Progress
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary_200,
                  borderRadius: BorderRadius.circular(8),
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
                    const Text(
                      "Your Progress",
                      style: TextStyle(
                        fontFamily: "Baloo",
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text_800,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // [STATS]
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.secondary_100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12), // shadow color
                            blurRadius: 8, // softness
                            offset: const Offset(0, 4), // vertical lift
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(
                                3,
                                (_) => Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.text_100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 52,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppColors.text_100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _statItem('$_cardsCreated', 'Cards'),
                                _statItem(accuracyLabel, 'Accuracy'),
                                _statItem(streakLabel, 'Streak'),
                              ],
                            ),
                    ),

                    // [HINT]
                    if (!_isLoading && _accuracy == null) ...[
                      const SizedBox(height: 10),
                      const Text(
                        "Take a quiz to track your accuracy!",
                        style: TextStyle(
                          fontFamily: "Nunito",
                          fontSize: 12,
                          color: AppColors.text_400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    SizedBox(height: 16),

                    // [COMPONENT] Streak w/ Calendar
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
                              child: const Column(
                                children: [
                                  Icon(Icons.psychology, color: Colors.white, size: 28),
                                  SizedBox(height: 6),
                                  Text(
                                    "Study Now",
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
                        fontFamily: "Nunito",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text_800,
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