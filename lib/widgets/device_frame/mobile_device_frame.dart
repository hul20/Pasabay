import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Renders a realistic iPhone 16 Pro style device frame around [child].
class MobileDeviceFrame extends StatefulWidget {
  final Widget child;

  /// Logical screen width (standard iPhone 16 Pro width is 393)
  final double screenWidth;

  /// Logical screen height (standard iPhone 16 Pro height is 852)
  final double screenHeight;

  const MobileDeviceFrame({
    super.key,
    required this.child,
    this.screenWidth = 393.0,
    this.screenHeight = 852.0,
  });

  @override
  State<MobileDeviceFrame> createState() => _MobileDeviceFrameState();
}

class _MobileDeviceFrameState extends State<MobileDeviceFrame> {
  late Timer _clockTimer;
  String _currentTime = '9:41';

  @override
  void initState() {
    super.initState();
    _updateTime();
    // Update the status bar clock every minute
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final formatted = DateFormat('h:mm').format(now);
    if (mounted && formatted != _currentTime) {
      setState(() {
        _currentTime = formatted;
      });
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double bezelThickness = 12.0;
    const double outerCornerRadius = 52.0;
    const double screenCornerRadius = 42.0;

    final double frameWidth = widget.screenWidth + (bezelThickness * 2);
    final double frameHeight = widget.screenHeight + (bezelThickness * 2);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            // Extra width to accommodate side buttons (3.5px each side)
            width: frameWidth + 8,
            height: frameHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Physical side buttons
                _buildPhysicalButtons(frameWidth, frameHeight),

                // Main Phone Chassis
                Positioned(
                  left: 4,
                  top: 0,
                  width: frameWidth,
                  height: frameHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161618), // Deep Space Black titanium
                      borderRadius: BorderRadius.circular(outerCornerRadius),
                      border: Border.all(
                        color: const Color(0xFF3F3F46), // Titanium rim highlight
                        width: 3.5,
                      ),
                      boxShadow: [
                        // Primary ambient chassis shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 45,
                          spreadRadius: 4,
                          offset: const Offset(0, 22),
                        ),
                        // Subtle soft blue ambient glow (Pasabay brand accent)
                        BoxShadow(
                          color: const Color(0xFF00AAF3).withValues(alpha: 0.12),
                          blurRadius: 70,
                          spreadRadius: -5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(bezelThickness),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(screenCornerRadius),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // App Viewport with mobile MediaQuery
                          MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              size: Size(widget.screenWidth, widget.screenHeight),
                              padding: const EdgeInsets.only(top: 52, bottom: 34),
                              viewPadding: const EdgeInsets.only(top: 52, bottom: 34),
                              viewInsets: EdgeInsets.zero,
                              devicePixelRatio: 3.0,
                            ),
                            child: widget.child,
                          ),

                          // Top Status Bar (Dynamic Island & Status Icons)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 52,
                            child: IgnorePointer(
                              child: _buildStatusBar(),
                            ),
                          ),

                          // Bottom Home Indicator
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Center(
                                child: Container(
                                  width: 134,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds physical side buttons (Action, Volume Up/Down, Power, Camera Control)
  Widget _buildPhysicalButtons(double frameWidth, double frameHeight) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Left: Action Button
          Positioned(
            left: 0.5,
            top: 135,
            child: _buildSideButton(width: 3.5, height: 26),
          ),
          // Left: Volume Up
          Positioned(
            left: 0.5,
            top: 178,
            child: _buildSideButton(width: 3.5, height: 50),
          ),
          // Left: Volume Down
          Positioned(
            left: 0.5,
            top: 238,
            child: _buildSideButton(width: 3.5, height: 50),
          ),
          // Right: Power / Side Button
          Positioned(
            left: frameWidth + 4,
            top: 195,
            child: _buildSideButton(width: 3.5, height: 75),
          ),
          // Right: Camera Control Button (iPhone 16 Pro)
          Positioned(
            left: frameWidth + 4,
            top: 570,
            child: _buildSideButton(width: 3.2, height: 56, isRecessed: true),
          ),
        ],
      ),
    );
  }

  Widget _buildSideButton({
    required double width,
    required double height,
    bool isRecessed = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isRecessed ? const Color(0xFF27272A) : const Color(0xFF3F3F46),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 1.5,
          ),
        ],
      ),
    );
  }

  /// Builds the top status bar containing current time, Dynamic Island, and authentic iOS icons
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Clock on the left (San Francisco typography styling)
          SizedBox(
            width: 72,
            child: Text(
              _currentTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                shadows: [
                  Shadow(
                    color: Colors.black45,
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),

          // Dynamic Island in the center
          _buildDynamicIsland(),

          // Authentic iOS Status Icons on the right (Cellular, Wi-Fi, Battery)
          SizedBox(
            width: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Cellular Signal Bars (4 vertical rounded bars)
                const _IOSCellularSignal(color: Colors.white),
                const SizedBox(width: 5.0),

                // 2. Wi-Fi Icon (iOS 3-arc concentric style)
                CustomPaint(
                  size: const Size(15.5, 11.0),
                  painter: _IOSWifiPainter(color: Colors.white),
                ),
                const SizedBox(width: 5.5),

                // 3. Battery Capsule (iOS rounded shell, nub, and inner fill)
                CustomPaint(
                  size: const Size(27.0, 12.5),
                  painter: _IOSBatteryPainter(
                    batteryLevel: 1.0,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the iPhone Dynamic Island pill with authentic hardware sensors
  Widget _buildDynamicIsland() {
    return Container(
      width: 122,
      height: 35,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // TrueDepth Face ID dot projector / sensor (left sensor aperture)
          Positioned(
            left: 20,
            child: Container(
              width: 10.5,
              height: 10.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0B0F19),
                border: Border.all(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Front camera lens with optical antireflective coating (right sensor)
          Positioned(
            right: 18,
            child: Container(
              width: 11.5,
              height: 11.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF090D16),
                border: Border.all(
                  color: const Color(0xFF1E293B).withValues(alpha: 0.7),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00AAF3).withValues(alpha: 0.25),
                    blurRadius: 2.5,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 4.5,
                  height: 4.5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Accurate iOS-style 4-bar cellular signal indicator
class _IOSCellularSignal extends StatelessWidget {
  final Color color;

  const _IOSCellularSignal({this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    const barWidth = 3.0;
    const barSpacing = 2.0;
    const heights = [4.0, 6.5, 9.0, 11.5];

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (index) {
        return Container(
          margin: EdgeInsets.only(right: index < 3 ? barSpacing : 0),
          width: barWidth,
          height: heights[index],
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 2.5,
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Accurate iOS-style Wi-Fi icon drawn with concentric arcs and center dot
class _IOSWifiPainter extends CustomPainter {
  final Color color;

  _IOSWifiPainter({this.color = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height + 0.5);
    const sweepAngle = math.pi * 0.44;
    const startAngle = -math.pi / 2 - (sweepAngle / 2);

    // Bottom dot
    canvas.drawCircle(Offset(size.width / 2, size.height - 1.2), 1.2, dotPaint);

    // 3 concentric arcs (inner, middle, outer)
    final radii = [4.8, 8.2, 11.6];
    for (final r in radii) {
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(rect, startAngle, sweepAngle, false, shadowPaint);
      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IOSWifiPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Accurate iOS-style battery capsule with terminal nub and inner fill
class _IOSBatteryPainter extends CustomPainter {
  final double batteryLevel;
  final Color color;

  _IOSBatteryPainter({
    this.batteryLevel = 1.0,
    this.color = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Total widget size: width 27.0, height 12.5
    const bodyWidth = 24.5;
    const bodyHeight = 12.0;
    const cornerRadius = 4.2;

    // Outer shell border
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0.5, 0.5, bodyWidth, bodyHeight),
      const Radius.circular(cornerRadius),
    );

    // Subtle drop shadow for outer shell
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);
    canvas.drawRRect(bodyRect, shadowPaint);
    canvas.drawRRect(bodyRect, borderPaint);

    // Terminal nub (positive pole on right)
    final nubPaint = Paint()
      ..color = color.withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;

    const nubWidth = 1.5;
    const nubHeight = 4.5;
    final nubTop = (bodyHeight - nubHeight) / 2 + 0.5;

    final nubRRect = RRect.fromRectAndCorners(
      const Rect.fromLTWH(bodyWidth + 0.8, 0, nubWidth, nubHeight)
          .translate(0, nubTop),
      topRight: const Radius.circular(1.3),
      bottomRight: const Radius.circular(1.3),
    );
    canvas.drawRRect(nubRRect, nubPaint);

    // Inner battery fill
    if (batteryLevel > 0) {
      const padding = 2.0;
      final maxFillWidth = bodyWidth - (padding * 2);
      final fillWidth = maxFillWidth * batteryLevel.clamp(0.0, 1.0);

      final fillPaint = Paint()
        ..color = batteryLevel <= 0.20 ? const Color(0xFFFF453A) : color
        ..style = PaintingStyle.fill;

      final fillRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          0.5 + padding,
          0.5 + padding,
          fillWidth,
          bodyHeight - (padding * 2),
        ),
        const Radius.circular(2.4),
      );

      final fillShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawRRect(fillRRect, fillShadowPaint);
      canvas.drawRRect(fillRRect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _IOSBatteryPainter oldDelegate) =>
      oldDelegate.batteryLevel != batteryLevel || oldDelegate.color != color;
}
