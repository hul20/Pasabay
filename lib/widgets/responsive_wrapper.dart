import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Responsive wrapper that constrains content to maximum width
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final maxWidth = width > AppConstants.maxContainerWidth
            ? AppConstants.maxContainerWidth
            : width;

        return Container(
          color: AppConstants.backgroundColor,
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
