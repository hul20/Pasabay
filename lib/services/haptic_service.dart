import 'package:flutter/services.dart';

/// Service for providing haptic feedback throughout the app
/// Makes the app feel more professional and responsive
class HapticService {
  /// Light haptic feedback - for selection changes, toggles
  static void lightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Medium haptic feedback - for button taps, confirmations
  static void mediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy haptic feedback - for important actions, errors
  static void heavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click - for picker selections, list item selections
  static void selectionClick() {
    HapticFeedback.selectionClick();
  }

  /// Vibrate - for notifications, alerts
  static void vibrate() {
    HapticFeedback.vibrate();
  }

  // Convenience methods for specific actions

  /// For button presses
  static void buttonTap() {
    HapticFeedback.mediumImpact();
  }

  /// For successful actions (request accepted, payment success, etc.)
  static void success() {
    HapticFeedback.mediumImpact();
  }

  /// For errors or warnings
  static void error() {
    HapticFeedback.heavyImpact();
  }

  /// For notifications received
  static void notification() {
    HapticFeedback.vibrate();
  }

  /// For tab/toggle changes
  static void tabChange() {
    HapticFeedback.selectionClick();
  }

  /// For map marker placement
  static void mapMarker() {
    HapticFeedback.lightImpact();
  }

  /// For pull to refresh
  static void refresh() {
    HapticFeedback.lightImpact();
  }

  /// For swipe actions
  static void swipe() {
    HapticFeedback.selectionClick();
  }

  /// For dialog/modal open
  static void modalOpen() {
    HapticFeedback.lightImpact();
  }

  /// For rating star selection
  static void ratingStar() {
    HapticFeedback.selectionClick();
  }
}
