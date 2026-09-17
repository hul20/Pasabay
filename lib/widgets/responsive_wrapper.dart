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
        final isDesktop = width > AppConstants.maxContainerWidth;
        final maxWidth = isDesktop ? AppConstants.maxContainerWidth : width;

        if (!isDesktop) {
          return child;
        }

        return Container(
          color: const Color(0xFF1E293B), // Modern dark slate background for wide screens
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: Container(
              width: maxWidth,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 30,
                    spreadRadius: 4,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
