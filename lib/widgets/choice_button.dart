import 'package:flutter/material.dart';
import 'package:soro/main.dart';

class ChoiceButton extends StatelessWidget {
  // Attributes
  final String text;
  final VoidCallback onPressed;
  final bool selectedAnswer;
  final Color backgroundColor;

  // Constructor
  const ChoiceButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.selectedAnswer,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          splashFactory: InkRipple.splashFactory, // disable default ripple when button is pressed
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
              return backgroundColor.withValues(alpha: 0.8); // pressed effect
            }
            return backgroundColor;
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