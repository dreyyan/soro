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
    return Container(
      width: double.infinity,
      height: 84,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primary_500,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(60),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.secondary_300,
          fontFamily: "TheFoxTail",
          fontSize: 62,
        ),
      ),
    );
  }
}