import 'package:flutter/material.dart';
import 'device_frame/mobile_device_frame.dart';

/// Scope to identify whether a widget is already inside a device frame
class _DeviceFrameScope extends InheritedWidget {
  const _DeviceFrameScope({required super.child});

  @override
  bool updateShouldNotify(_DeviceFrameScope oldWidget) => false;
}

/// Responsive wrapper that presents an authentic mobile smartphone frame
/// on desktop/wide screens, while rendering edge-to-edge natively on mobile devices.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  /// Breakpoint width above which the device frame is activated (default: 500)
  final double breakpointWidth;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.breakpointWidth = 500.0,
  });

  @override
  Widget build(BuildContext context) {
    // If this widget is nested inside another ResponsiveWrapper, pass child through
    final isAlreadyFramed =
        context.dependOnInheritedWidgetOfExactType<_DeviceFrameScope>() != null;
    if (isAlreadyFramed) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopOrTablet = constraints.maxWidth > breakpointWidth;

        // On mobile devices or narrow viewports, render standard full-screen
        if (!isDesktopOrTablet) {
          return child;
        }

        // On desktop/wide screens (e.g. GitHub Pages preview), wrap in iPhone device frame
        return _DeviceFrameScope(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.1),
                radius: 1.2,
                colors: [
                  Color(0xFF1E293B), // Soft ambient dark slate center
                  Color(0xFF090D16), // Deep midnight edge
                ],
              ),
            ),
            child: MobileDeviceFrame(
              child: child,
            ),
          ),
        );
      },
    );
  }
}

