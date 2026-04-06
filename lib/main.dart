// [IMPORT] Widgets
import 'package:flutter/material.dart';

// [IMPORT] Screens
import 'package:soro/screens/quiz.dart';
import 'package:soro/screens/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // [CONFIGURATION] Themes & routes
    return MaterialApp(
      debugShowCheckedModeBanner: false, // hide 'default' banner
      theme: ThemeData(),

      // [ROUTES]
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/quiz': (_) => const Quiz()
      }
    );
  }
}

class AppColors {
  static const Color primary_50 = Color(0xFFFFF3EE);
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

  static const Color secondary_50 = Color(0xFFFFFCF6);
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

  static const Color text_50 = Color(0xFFF4F5F7);
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

  static const Color green_50 = Color(0xFFF0FDF4);
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