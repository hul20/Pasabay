import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Custom button with gradient or solid background
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double scaleFactor;
  final bool isGradient;
  final Color? backgroundColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.scaleFactor,
    this.isGradient = true,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52 * scaleFactor,
      decoration: BoxDecoration(
        gradient: isGradient ? AppGradients.primaryGradient : null,
        color: !isGradient
            ? (backgroundColor ?? AppConstants.primaryColor)
            : null,
        borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16 * scaleFactor,
            fontWeight: FontWeight.w600,
            color: textColor ?? Colors.white,
          ),
        ),
      ),
    );
  }
}
