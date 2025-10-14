import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Gradient header component with back button, logo, title, and subtitle
class GradientHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final double scaleFactor;
  final VoidCallback? onBackPressed;

  const GradientHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.scaleFactor,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppConstants.headerBorderRadius),
          bottomRight: Radius.circular(AppConstants.headerBorderRadius),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 25 * scaleFactor,
            vertical: 20 * scaleFactor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and logo row
              Row(
                children: [
                  if (onBackPressed != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: onBackPressed,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (onBackPressed != null) SizedBox(width: 10 * scaleFactor),
                  Container(
                    width: 46 * scaleFactor,
                    height: 46 * scaleFactor,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(AppConstants.smallLogoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * scaleFactor),
                  Text(
                    'Pasabay',
                    style: TextStyle(
                      fontSize: 16 * scaleFactor,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 25 * scaleFactor),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 56 * scaleFactor,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              SizedBox(height: 8 * scaleFactor),
              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 18 * scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              SizedBox(height: 10 * scaleFactor),
            ],
          ),
        ),
      ),
    );
  }
}
