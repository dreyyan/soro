// [IMPORT] Libraries
import 'package:flutter/material.dart';
import 'dart:math';

// [IMPORT] Screens
import 'package:soro/main.dart';

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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // [COMPONENT] Header
          Container(
            width: double.infinity,
            height: 120,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary_600,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(60), // round bottom corners
              ),
            ),
            child: const Text(
              "Soro",
              style: TextStyle(
                color: AppColors.secondary_300,
                fontFamily: "TheFoxTail",
                fontSize: 80,
              ),
            ),
          ),

          // [SPACE]
          const SizedBox(height: 32),

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
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  getRandomTrivia(), // returns a random trivia string
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text_800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // [SPACE]
              const SizedBox(height: 8),

              // [MASCOT IMAGE] with right margin
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Image.asset(
                  'assets/images/soro-mascot.png',
                  width: 120,
                  height: 120,
                ),
              ),
            ],
          ),

          Expanded(
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/quiz/settings');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text("Quiz"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}