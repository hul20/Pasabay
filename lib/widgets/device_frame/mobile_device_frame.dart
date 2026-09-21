import 'dart:async';
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
                              padding: const EdgeInsets.only(top: 48, bottom: 34),
                              viewPadding: const EdgeInsets.only(top: 48, bottom: 34),
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
                            height: 48,
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

  /// Builds the top status bar containing current time, Dynamic Island, and cellular/Wi-Fi/battery icons
  Widget _buildStatusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Clock on the left
          SizedBox(
            width: 60,
            child: Text(
              _currentTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // Dynamic Island in the center
          _buildDynamicIsland(),

          // Status Icons on the right
          const SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.signal_cellular_alt_rounded,
                  color: Colors.white,
                  size: 15,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.wifi_rounded,
                  color: Colors.white,
                  size: 15,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
                SizedBox(width: 5),
                Icon(
                  Icons.battery_full_rounded,
                  color: Colors.white,
                  size: 18,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the iPhone Dynamic Island pill
  Widget _buildDynamicIsland() {
    return Container(
      width: 118,
      height: 32,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 0.5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Subtle TrueDepth camera lens reflection
          Container(
            width: 11,
            height: 11,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F172A),
              border: Border.all(
                color: const Color(0xFF1E293B),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00AAF3).withValues(alpha: 0.3),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
