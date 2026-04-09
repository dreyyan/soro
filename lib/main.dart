// [IMPORT] Widgets
import 'package:flutter/material.dart';

// [IMPORT] Screens
import 'package:soro/screens/auth/login_page.dart';
import 'package:soro/screens/auth/signup_page.dart';
import 'package:soro/screens/onboarding.dart';
import 'package:soro/screens/home_page.dart';
import 'package:soro/screens/cards.dart';
import 'package:soro/screens/quiz.dart';
import 'package:soro/screens/quiz_settings.dart';
import 'package:soro/screens/quiz_start.dart';
import 'package:soro/screens/quest.dart';
import 'package:soro/screens/profile.dart';

// [IMPORT] Database
import './database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init();
  runApp(const MyApp());
}

// [CLASS] Main App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),

      // [ROUTES]
      initialRoute: '/login',
      routes: {
        '/login':         (_) => const LoginPage(),
        '/signup':        (_) => const SignupPage(),
        '/onboarding':    (_) => const OnboardingPage(),
        '/':              (_) => const HomeWithNav(),     // Home + bottom navbar
        '/cards':         (_) => const Cards(),
        '/quiz':          (_) => const Quiz(),
        '/quiz/settings': (_) => const QuizSettings(),
        '/quiz/start':    (_) => const QuizStart(),
        '/quest':         (_) => const Quest(),
        '/profile':       (_) => const Profile(),
      },
    );
  }
}

// [CLASS] Home w/ Bottom Navigation Bar
class HomeWithNav extends StatefulWidget {
  const HomeWithNav({super.key});

  @override
  State<HomeWithNav> createState() => _HomeWithNavState();
}

class _HomeWithNavState extends State<HomeWithNav> {
  int _selectedIndex = 0;

  // [SCREENS] Screens for each tab
  final List<Widget> _screens = [
    const HomePage(),
    const Cards(),
    const SizedBox.shrink(),
    const Quest(),
    const Profile(),
  ];

  // [FUNCTION] Change selected tab
  void _onTabSelected(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, '/quiz');
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      // [COMPONENT] Bottom Navigation Bar
      bottomNavigationBar: Stack(
        alignment: Alignment.center,
        children: [
          // [BAR BACKGROUND]
          Container(
            height: 70,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
          ),

          // [NAVIGATION ITEMS]
          BottomNavigationBar(
            currentIndex:
                _selectedIndex > 2 ? _selectedIndex - 1 : _selectedIndex,
            onTap: _onTabSelected,
            selectedItemColor: AppColors.primary_600,
            unselectedItemColor: AppColors.text_400,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.style),
                label: "Cards",
              ),
              BottomNavigationBarItem(
                icon: SizedBox.shrink(), // Placeholder for center "+" button
                label: "",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.star),
                label: "Quest",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),

          // [CENTER + BUTTON]
          Positioned(
            bottom: 10,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/quiz');
              },
              backgroundColor: AppColors.primary_600,
              elevation: 4,
              child: const Icon(
                Icons.add,
                size: 32,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// [CLASS] App Color Palette
class AppColors {
  static const Color primary_50  = Color(0xFFFFF3EE);
  static const Color primary_100 = Color(0xFFFFE4D9);
  static const Color primary_200 = Color(0xFFFFC7B3);
  static const Color primary_300 = Color(0xFFFFA98D);
  static const Color primary_400 = Color(0xFFFF8C67);
  static const Color primary_500 = Color(0xFFFF6B35);
  static const Color primary_600 = Color(0xFFE65F2F);
  static const Color primary_700 = Color(0xFFCC5529);
  static const Color primary_800 = Color(0xFFB34B23);
  static const Color primary_900 = Color(0xFF993F1D);
  static const Color primary_950 = Color(0xFF662914);

  static const Color secondary_50  = Color(0xFFFFFCF6);
  static const Color secondary_100 = Color(0xFFFFF9ED);
  static const Color secondary_200 = Color(0xFFFFF5E1);
  static const Color secondary_300 = Color(0xFFF2E8D3);
  static const Color secondary_400 = Color(0xFFE6DBC5);
  static const Color secondary_500 = Color(0xFFD9CEB7);
  static const Color secondary_600 = Color(0xFFBFB59F);
  static const Color secondary_700 = Color(0xFFA69C87);
  static const Color secondary_800 = Color(0xFF8C846F);
  static const Color secondary_900 = Color(0xFF736B57);
  static const Color secondary_950 = Color(0xFF4D4739);

  static const Color text_50  = Color(0xFFF4F5F7);
  static const Color text_100 = Color(0xFFE6E8EB);
  static const Color text_200 = Color(0xFFC9CDD3);
  static const Color text_300 = Color(0xFFACB2BB);
  static const Color text_400 = Color(0xFF8F97A3);
  static const Color text_500 = Color(0xFF5D6572);
  static const Color text_600 = Color(0xFF535A66);
  static const Color text_700 = Color(0xFF494F5A);
  static const Color text_800 = Color(0xFF3F444E);
  static const Color text_900 = Color(0xFF353942);
  static const Color text_950 = Color(0xFF23262C);

  static const Color green_50  = Color(0xFFF0FDF4);
  static const Color green_100 = Color(0xFFDCFCE7);
  static const Color green_200 = Color(0xFFBBF7D0);
  static const Color green_300 = Color(0xFF86EFAC);
  static const Color green_400 = Color(0xFF4ADE80);
  static const Color green_500 = Color(0xFF22C55E);
  static const Color green_600 = Color(0xFF16A34A);
  static const Color green_700 = Color(0xFF15803D);
  static const Color green_800 = Color(0xFF166534);
  static const Color green_900 = Color(0xFF14532D);
  static const Color green_950 = Color(0xFF0F3D22);
}