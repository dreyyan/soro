// [IMPORT] Widgets
import 'package:flutter/material.dart';

// [IMPORT] Screens
import 'package:soro/screens/auth/login_page.dart';
import 'package:soro/screens/auth/signup_page.dart';
import 'package:soro/screens/hero_onboarding.dart';
import 'package:soro/screens/profile/profile_onboarding.dart';
import 'package:soro/screens/home_page.dart';
import 'package:soro/screens/cards/cards.dart';
import 'package:soro/screens/profile/change_password.dart';
import 'package:soro/screens/profile/edit_profile.dart';
import 'package:soro/screens/profile/settings.dart';
import 'package:soro/screens/quiz/quiz.dart';
import 'package:soro/screens/quiz/quiz_settings.dart';
import 'package:soro/screens/quiz/quiz_start.dart';
import 'package:soro/screens/quest.dart';
import 'package:soro/screens/profile/profile.dart';

// [IMPORT] Database
import './database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.init();
  runApp(const MyApp());
}

final GlobalKey<HomeWithNavState> homeNavKey = GlobalKey<HomeWithNavState>();

// [CLASS] App Entry Point - Decides initial screen based on first launch
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _isFirstLaunch;
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // [ACTION] Load onboarding + session state
  Future<void> _init() async {
    final db = DatabaseHelper();

    final firstLaunch = await db.isFirstLaunch();
    final loggedIn = await db.isLoggedIn();

    if (!mounted) return;

    setState(() {
      _isFirstLaunch = firstLaunch;
      _isLoggedIn = loggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    // [LOADING]
    if (_isFirstLaunch == null || _isLoggedIn == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // [1] FIRST TIME USER → HERO ONBOARDING
    if (_isFirstLaunch == true) {
      return const HeroOnboarding();
    }

    // [2] NOT LOGGED IN → LOGIN PAGE
    if (_isLoggedIn == false) {
      return const LoginPage();
    }

    // [3] LOGGED IN → HOME
    return HomeWithNav(key: homeNavKey);
  }
}

// [CLASS] Main App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // [THEME]
      theme: ThemeData(
        useMaterial3: true,
        // brightness: Brightness.dark,

        // // [COLORS] Base
        // primaryColor: AppColors.primary_500,
        // scaffoldBackgroundColor: AppColors.text_950,

        // colorScheme: ColorScheme.dark(
        //   primary: AppColors.primary_500,
        //   onPrimary: Colors.white,

        //   secondary: AppColors.secondary_400,
        //   onSecondary: Colors.black,

        //   surface: AppColors.text_900,
        //   onSurface: AppColors.text_100,

        //   error: Colors.redAccent,
        //   onError: Colors.white,
        // ),

        // [THEME] Dialogs
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.text_50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Baloo',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.4,
            letterSpacing: 0,
            color: AppColors.text_900,
          ),
          contentTextStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 1.5,
            letterSpacing: 0,
            color: AppColors.text_300,
          ),
        ),

        // [THEME] Bottom Sheets
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.text_900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
        ),

        // [THEME] Snackbars
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.text_800,
          contentTextStyle: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.4,
            letterSpacing: 0.25,
            color: AppColors.text_100,
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        // [THEME] Cards
        cardTheme: CardThemeData(
          color: AppColors.text_50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),

        // [THEME] Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary_500,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
          ),
        ),

        // [THEME] Input Fields
        // inputDecorationTheme: InputDecorationTheme(
        //   filled: true,
        //   fillColor: AppColors.text_900,
        //   hintStyle: const TextStyle(color: AppColors.text_400),
        //   labelStyle: const TextStyle(color: AppColors.text_300),
        //   border: OutlineInputBorder(
        //     borderRadius: BorderRadius.circular(12),
        //     borderSide: BorderSide.none,
        //   ),
        // ),
      ),

      // [ROUTES]
      home: const AppEntry(),
      routes: {
        '/login':                   (_) => const LoginPage(),
        '/signup':                  (_) => const SignupPage(),
        '/profile-onboarding':              (_) => const ProfileOnboarding(),
        '/hero-onboarding':              (_) => const HeroOnboarding(),
        '/cards':                   (_) => const Cards(),
        '/quiz':                    (_) => const Quiz(),
        '/quiz/settings':           (_) => const QuizSettings(),
        '/quiz/start':              (_) => const QuizStart(),
        '/quest':                   (_) => const Quest(),
        '/profile':                 (_) => const Profile(),
        '/profile/edit':            (_) => const EditProfile(),
        '/profile/change-password': (_) => const ChangePassword(),
        '/profile/settings':        (_) => const Settings(),
      },
    );
  }
}

// [CLASS] Home w/ Bottom Navigation Bar
class HomeWithNav extends StatefulWidget {
  const HomeWithNav({super.key});

  @override
  State<HomeWithNav> createState() => HomeWithNavState();
}

class HomeWithNavState extends State<HomeWithNav> {
  int _selectedIndex = 0;

  // [SCREENS] Bottom Navigation Bar
  final List<Widget> _screens = [
    const HomePage(), // 0
    const Cards(),    // 1
    const Quiz(),     // 2
    const Quest(),    // 3
    const Profile(),  // 4
  ];

  // [NAVIGATION] Handle tab change
  void onTabSelected(int index) {
    if (index < 0 || index >= _screens.length) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  // [SECTION] Home Scaffold
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],

      // [SECTION] Bottom Navigation Bar
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: InkRipple.splashFactory,
          splashColor: AppColors.primary_500.withOpacity(0.15),
          highlightColor: AppColors.primary_500.withOpacity(0.08),
          hoverColor: Colors.transparent,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: const BoxDecoration(
            color: AppColors.secondary_50,
            border: Border(
              top: BorderSide(
                color: AppColors.secondary_300,
                width: 1,
              ),
            ),
          ),

          // [SECTION] Bottom Navigation Bar
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: onTabSelected,

            // [STYLE] Background & elevation
            backgroundColor: Colors.transparent,
            elevation: 0,

            // [STYLE] Colors
            selectedItemColor: AppColors.primary_500,
            unselectedItemColor: AppColors.text_300,

            // [STYLE] Typography
            selectedLabelStyle: const TextStyle(
              fontFamily: 'Baloo',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.3,
              letterSpacing: 0,
              color: AppColors.primary_500,
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'Baloo',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.3,
              letterSpacing: 0,
              color: AppColors.text_300,
            ),

            // [CONFIG]
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,

            items: const [
              // [TAB] Home
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),

              // [TAB] Cards
              BottomNavigationBarItem(
                icon: Icon(Icons.style),
                label: "Cards",
              ),

              // [TAB] Quiz
              BottomNavigationBarItem(
                icon: Icon(Icons.quiz),
                label: "Quiz",
              ),

              // [TAB] Quest
              BottomNavigationBarItem(
                icon: Icon(Icons.star),
                label: "Quest",
              ),

              // [TAB] Profile
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        ),
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