import 'package:flutter/material.dart';
import 'package:sora/main.dart';

class ChoiceButton extends StatelessWidget {
  // Attributes
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;

  // Constructor
  const ChoiceButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          splashFactory: NoSplash.splashFactory, // disable default ripple when button is pressed
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: "Nunito",
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 0.5,
            )
          ),
          minimumSize: WidgetStatePropertyAll(Size(double.infinity, 50)),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primary_100;
            }
            return AppColors.secondary_50;
          }),
          foregroundColor: WidgetStatePropertyAll(AppColors.text_700),
          shape: WidgetStateProperty.resolveWith<OutlinedBorder>((states) =>
            RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: states.contains(WidgetState.pressed)
              ? AppColors.primary_300
              : AppColors.text_100,
              width: 2
            )
          ),)
        ),
        child: Text(text),
      ),
    );
  }
}