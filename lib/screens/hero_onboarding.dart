// [IMPORT] Libraries
import 'package:flutter/material.dart';

// [IMPORT] App
import 'package:soro/main.dart';
import 'package:soro/database/database_helper.dart';

class HeroOnboarding extends StatefulWidget {
  const HeroOnboarding({super.key});

  @override
  State<HeroOnboarding> createState() => _HeroOnboardingState();
}

class _HeroOnboardingState extends State<HeroOnboarding> {
  // [STATE]
  final PageController _controller = PageController();
  int _currentPage = 0;

  // [DATA] Onboarding Content
  final List<Map<String, String>> _pages = [
    {
      "title": "Hi, I’m Soro!",
      "subtitle": "Let’s make learning simple, fun, and addictive.",
      "button": "Next",
    },
    {
      "title": "Study smarter, not harder",
      "subtitle": "Create decks, take quizzes, and track your progress.",
      "button": "Next",
    },
    {
      "title": "Ready to level up?",
      "subtitle": "Build your first deck and start your learning streak.",
      "button": "Let's Go!",
    },
  ];

  // [ACTION] Next Page / Finish
  Future<void> _next() async {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      return;
    }

    final db = DatabaseHelper();
    await db.setOnboardingSeen();

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/login');
  }

  // [WIDGET] Styled Title (with highlights)
  Widget _buildTitle(int index) {
    final styles = [
      // Page 1 → Soro!
      const [
        TextSpan(text: "Hi, I’m "),
        TextSpan(
          text: "Soro!",
          style: TextStyle(color: AppColors.primary_500),
        ),
      ],

      // Page 2 → smarter, harder
      const [
        TextSpan(text: "Study "),
        TextSpan(
          text: "smarter",
          style: TextStyle(color: AppColors.primary_500),
        ),
        TextSpan(text: ", not "),
        TextSpan(
          text: "harder",
          style: TextStyle(color: AppColors.primary_500),
        ),
      ],

      // Page 3 → level up?
      const [
        TextSpan(text: "Ready to "),
        TextSpan(
          text: "level up?",
          style: TextStyle(color: AppColors.primary_500),
        ),
      ],
    ];

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(
          fontFamily: "Baloo",
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.text_800,
        ),
        children: styles[index],
      ),
    );
  }

  // [WIDGET] Circle Content (ALL INSIDE)
  Widget _buildCircleContent(int index) {
    final data = _pages[index];
    final screenWidth = MediaQuery.of(context).size.width;
    final size = screenWidth * 1.2;
    final imageSize = size * 0.38;

    return SizedBox(
      width: double.infinity,
      child: Center(
        child: OverflowBox(
          maxWidth: size,
          maxHeight: size,
          alignment: Alignment.center,
          child: Container(
            width: size,
            height: size,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: AppColors.secondary_50,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // [SECTION] Mascot
                Image.asset(
                  'assets/images/soro-mascot.png',
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 18),

                // [SECTION] Title (highlighted)
                _buildTitle(index),

                const SizedBox(height: 10),

                // [SECTION] Subtitle
                Text(
                  data["subtitle"]!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: "Nunito",
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text_600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // [WIDGET] Indicator Dots
  Widget _indicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.text_900
                : AppColors.text_300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _pages[_currentPage];

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.primary_500,

        child: Column(
          children: [
            // [SECTION] Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (_, index) {
                  return Center(child: _buildCircleContent(index));
                },
              ),
            ),

            // [SECTION] Indicator
            _indicator(),

            const SizedBox(height: 20),

            // [SECTION] Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.text_700,
                    foregroundColor: AppColors.text_50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _next,
                  child: Text(
                    current["button"]!,
                    style: const TextStyle(
                      fontFamily: "Baloo",
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
