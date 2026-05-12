import 'package:flutter/material.dart';
import '../main.dart';

class Header extends StatelessWidget {
  final String title;

  const Header({
    super.key,
    this.title = "Soro", // default header title
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          // [BAR] Top
          Container(
            height: 32,
            width: double.infinity,
            color: AppColors.primary_700,
          ),

          // [BAR] Middle
          Container(
            height: 32,
            width: double.infinity,
            color: AppColors.primary_500,
          ),

          // [BAR] Bottom with Title
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary_500,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(40),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.secondary_50,
                    fontFamily: "TheFoxTail",
                    fontSize: 64,
                  ),
                ),
                // [MASCOT IMAGE]
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Image.asset(
                    'assets/images/soro-mascot-head.png',
                    width: 80,
                    height: 80,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}