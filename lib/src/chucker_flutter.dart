import 'package:chucker_flutter/src/helpers/shared_preferences_manager.dart';
import 'package:chucker_flutter/src/models/log.dart';
import 'package:chucker_flutter/src/view/helper/chucker_button.dart';
import 'package:chucker_flutter/src/view/helper/chucker_ui_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// [ChuckerFlutter] is a helper class to initialize the library
class ChuckerFlutter {
  const ChuckerFlutter._();

  /// [navigatorObserver] observes the navigation of your app. It must be
  /// referenced in your MaterialApp widget
  static final navigatorObserver = NavigatorObserver();

  /// [showOnRelease] decides whether to allow Chucker Flutter working in release
  /// mode or not.
  /// By default its value is `false`
  static bool showOnRelease = false;

  /// [isDebugMode] A wrapper of Flutter's `kDebugMode` constant
  static bool isDebugMode = kDebugMode;

  /// [showNotification] decides whether to show in app notification or not
  /// By default its value is `true`
  static bool showNotification = true;

  /// [chuckerButton] can be placed anywhere in the UI to open Chucker Screen
  static final chuckerButton =
      (isDebugMode || ChuckerFlutter.showOnRelease) ? ChuckerButton.getInstance() : const SizedBox.shrink();

  /// [showChuckerScreen] navigates to the chucker home screen
  static void showChuckerScreen() => ChuckerUiHelper.showChuckerScreen();

  /// [configure] configuration overlay notification
  static void configure({
    bool showOnRelease = false,
    bool showNotification = true,
    Alignment? notificationAlignment,
    Offset? offsetEnd,
    Offset? offsetBegin,
  }) {
    ChuckerFlutter.showOnRelease = showOnRelease;
    ChuckerFlutter.showNotification = showNotification;

    ChuckerUiHelper.settings = ChuckerUiHelper.settings.copyWith(
      notificationAlignment: notificationAlignment,
      offsetBegin: offsetEnd,
      offsetEnd: offsetBegin,
    );
  }

  /// [info] logs information
  static void info(String message) {
    _log(message, LogLevel.info);
  }

  /// [debug] logs debug information
  static void debug(String message) {
    _log(message, LogLevel.debug);
  }

  /// [warning] logs warning information
  static void warning(String message) {
    _log(message, LogLevel.warning);
  }

  /// [error] logs error information
  static void error(String message) {
    _log(message, LogLevel.error);
  }

  static void _log(String message, LogLevel level) {
    if (!isDebugMode && !showOnRelease) return;

    final log = Log(
      message: message,
      level: level,
      time: DateTime.now(),
    );

    SharedPreferencesManager.getInstance().addLog(log);

    final color = _getLogColor(level);
    // ignore: avoid_print
    print('\x1B[${color}m[Chucker] ${level.name.toUpperCase()}: $message\x1B[0m');
  }

  static String _getLogColor(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return '32'; // Green
      case LogLevel.debug:
        return '34'; // Blue
      case LogLevel.warning:
        return '33'; // Yellow
      case LogLevel.error:
        return '31'; // Red
    }
  }
}
