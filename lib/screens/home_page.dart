// [IMPORT] Libraries
import 'package:flutter/material.dart';
import 'dart:math';

// [IMPORT] Screens
import 'package:soro/main.dart';
import 'package:soro/screens/cards.dart';
import 'package:soro/screens/quiz.dart';

// Trivia list
final List<String> triviaList = [
  "Did you know? Mitochondria are the powerhouse of the cell!",
  "Fun fact: Honey never spoils!",
  "Trivia: Bananas are berries, but strawberries aren't!",
  "Did you know? Octopuses have three hearts!",
  "Fun fact: Your stomach gets a new lining every 3–4 days.",
];

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // [METHOD] Get random trivia
  String getRandomTrivia() {
    final random = Random();
    return triviaList[random.nextInt(triviaList.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary_200,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // [COMPONENT] Header
          Container(
            width: double.infinity,
            height: 84,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary_500,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(60), // round bottom corners
              ),
            ),
            child: const Text(
              "Soro",
              style: TextStyle(
                color: AppColors.secondary_300,
                fontFamily: "TheFoxTail",
                fontSize: 62,
              ),
            ),
          ),

          // [SPACE]
          const SizedBox(height: 40),

          // [SECTION] Welcome/Greeting Message
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // [TEXT] Greeting
                Text(
                  "Good Morning Adrian!",
                  style: TextStyle(
                    fontFamily: "Baloo",
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text_800,
                  ),
                ),

                // [TEXT] Motivational line
                Text(
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

          // [SPACE]
          const SizedBox(height: 24),

          // [COMPONENT] Trivia w/ mascot
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // [BUBBLE] Trivia text
              Container(
                margin: const EdgeInsets.only(bottom: 8, left: 24, right: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  getRandomTrivia(), // return a random trivia string
                  style: const TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text_800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // [SPACE]
              const SizedBox(height: 8),

              // [MASCOT IMAGE] w/ right margin
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Image.asset(
                  'assets/images/soro-mascot.png',
                  width: 120,
                  height: 120,
                ),
              ),

              // [SPACE]
              const SizedBox(height: 24),

              // [COMPONENT] Quick Access Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // [BUTTON] Create Flashcards
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Cards()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary_600,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.edit, color: Colors.white, size: 28),
                              SizedBox(height: 6),
                              Text(
                                "Create",
                                style: TextStyle(
                                  fontFamily: "Nunito",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text_50,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // [BUTTON] Start Quiz
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Quiz()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary_500,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.psychology, color: Colors.white, size: 28),
                              SizedBox(height: 6),
                              Text(
                                "Quiz",
                                style: TextStyle(
                                  fontFamily: "Nunito",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text_50,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // [BUTTON] View Cards
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Cards()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary_700,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: const [
                              Icon(Icons.style, color: Colors.white, size: 28),
                              SizedBox(height: 6),
                              Text(
                                "Cards",
                                style: TextStyle(
                                  fontFamily: "Nunito",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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

              // [SPACE]
              const SizedBox(height: 32),

              // [SECTION] Progress Overview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [TEXT] Section title
                    Text(
                      "Your Progress",
                      style: TextStyle(
                        fontFamily: "Baloo",
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text_800,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // [CARD] Progress container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),

                      // [ROW] Stats
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          // [ITEM] Cards studied
                          Column(
                            children: [
                              Text(
                                "12",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary_600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Cards",
                                style: TextStyle(
                                  fontFamily: "Nunito",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text_600,
                                ),
                              ),
                            ],
                          ),

                          // [ITEM] Quiz accuracy
                          Column(
                            children: [
                              Text(
                                "85%",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary_600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Accuracy",
                                style: TextStyle(
                                  fontFamily: "Nunito",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text_600,
                                ),
                              ),
                            ],
                          ),

                          // [ITEM] Streak
                          Column(
                            children: [
                              Text(
                                "3🔥",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary_600,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Streak",
                                style: TextStyle(
                                  fontFamily: "Nunito",
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.text_600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}