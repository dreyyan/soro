import 'package:flutter/material.dart';
import 'package:sora/main.dart';

class PrimaryButton extends StatelessWidget {
  // Attributes
  final String text;
  final VoidCallback onPressed;
  final bool disabled;

  // Constructor
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
          splashFactory: NoSplash.splashFactory, // disable default ripple when button is pressed
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          textStyle: WidgetStatePropertyAll(
            TextStyle(
              fontFamily: "Nunito",
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: 0.5,
            )
          ),
          minimumSize: WidgetStatePropertyAll(Size(double.infinity, 50)),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primary_600;
            }
            return AppColors.primary_500;
          }),
          foregroundColor: WidgetStatePropertyAll(AppColors.text_50),
          shape: WidgetStateProperty.resolveWith<OutlinedBorder>((states) =>
            RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),)
        ),
        child: Text(text),
      ),
    );
  }
}