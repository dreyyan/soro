import 'package:flutter/material.dart';

class QuizSettings extends StatefulWidget {
  const QuizSettings({super.key});

  @override
  State<QuizSettings> createState() => _QuizSettingsState();
}

class _QuizSettingsState extends State<QuizSettings> {
  // [STATES] Form values
  int numberOfQuestions = 5;
  String selectedMode = "Easy";

  // [OPTIONS] Modes
  final List<String> modes = ["Easy", "Medium", "Hard"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Quiz Settings"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // [INPUT] Number of questions
            Text(
              "Number of Questions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: numberOfQuestions,
              isExpanded: true,
              items: [5, 10, 15, 20]
                  .map((num) => DropdownMenuItem(
                        value: num,
                        child: Text("$num"),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    numberOfQuestions = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // [INPUT] Quiz mode
            Text(
              "Mode",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: selectedMode,
              isExpanded: true,
              items: modes
                  .map((mode) => DropdownMenuItem(
                        value: mode,
                        child: Text(mode),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedMode = value;
                  });
                }
              },
            ),
            const Spacer(),

            // [BUTTON] Start Quiz
            ElevatedButton(
              onPressed: () {
                // Pass the settings to the quiz start page via arguments
                Navigator.pushNamed(
                  context,
                  '/quiz/start',
                  arguments: {
                    "numberOfQuestions": numberOfQuestions,
                    "mode": selectedMode,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text("Start Quiz"),
            ),
          ],
        ),
      ),
    );
  }
}