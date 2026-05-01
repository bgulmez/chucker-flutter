import 'dart:collection';

import 'package:chucker_flutter/src/helpers/extensions.dart';
import 'package:chucker_flutter/src/helpers/shared_preferences_manager.dart';
import 'package:chucker_flutter/src/localization/localization.dart';
import 'package:chucker_flutter/src/models/log.dart';
import 'package:chucker_flutter/src/models/settings.dart';
import 'package:chucker_flutter/src/view/chucker_page.dart';
import 'package:chucker_flutter/src/view/helper/chucker_button.dart';
import 'package:chucker_flutter/src/view/helper/colors.dart';
import 'package:chucker_flutter/src/view/widgets/notification.dart' as notification;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///[ChuckerUiHelper] handles the UI part of `chucker_flutter`
class ChuckerUiHelper {
  static final List<OverlayEntry?> _overlayEntries = List.empty(growable: true);

  static final Queue<_NotificationData> _notificationQueue = Queue();
  static int _activeNotifications = 0;
  static const int _maxVisibleNotifications = 3;

  ///Only for testing
  static bool notificationShown = false;

  ///[settings] to modify ui behaviour of chucker screens and notification
  static Settings settings = Settings.defaultObject();

  ///[showNotification] shows the rest api [method] (GET, POST, PUT, etc),
  ///[statusCode] (200, 400, etc) response status and [path]
  static bool showNotification({
    required String method,
    required int statusCode,
    required String path,
    required DateTime requestTime,
  }) {
    notificationShown = false;

    if (!ChuckerUiHelper.settings.showNotification) return false;

    if (ChuckerFlutter.navigatorObserver.navigator == null) {
      debugPrint('ChuckerFlutter: NavigatorObserver is missing.');
      return false;
    }

    _notificationQueue.add(_NotificationData(
      method: method,
      statusCode: statusCode,
      path: path,
      requestTime: requestTime,
    ));

    _processQueue();
    return true;
  }

  static void _processQueue() {
    if (_activeNotifications >= _maxVisibleNotifications || _notificationQueue.isEmpty) {
      return;
    }

    final data = _notificationQueue.removeFirst();
    final overlay = ChuckerFlutter.navigatorObserver.navigator!.overlay;

    if (overlay == null) return;

    _activeNotifications++;

    late OverlayEntry entry;
    entry = _createOverlayEntry(data.method, data.statusCode, data.path, data.requestTime, onDismiss: () {
      entry.remove();
      _overlayEntries.remove(entry);
      _activeNotifications--;
      _processQueue();
    });

    _overlayEntries.add(entry);
    overlay.insert(entry);
    notificationShown = true;
  }

  static OverlayEntry _createOverlayEntry(
    String method,
    int statusCode,
    String path,
    DateTime requestTime, {
    required VoidCallback onDismiss,
  }) {
    return OverlayEntry(
      builder: (context) {
        return Align(
          alignment: settings.notificationAlignment,
          child: notification.Notification(
            statusCode: statusCode,
            method: method,
            path: path,
            removeNotification: onDismiss,
            requestTime: requestTime,
          ),
        );
      },
    );
  }

  static void _removeNotification() {
    for (final entry in _overlayEntries) {
      entry?.remove();
    }
    _overlayEntries.clear();
    _activeNotifications = 0;
    _notificationQueue.clear();
  }

  ///[showChuckerScreen] shows the screen containing the list of records
  static void showChuckerScreen() {
    SharedPreferencesManager.getInstance().getSettings();
    ChuckerFlutter.navigatorObserver.navigator!.push(
      MaterialPageRoute<void>(
        builder: (context) => MaterialApp(
          key: const Key('chucker_material_app'),
          debugShowCheckedModeBanner: false,
          localizationsDelegates: Localization.localizationsDelegates,
          supportedLocales: Localization.supportedLocales,
          locale: Localization.currentLocale,
          theme: ThemeData(
            useMaterial3: false,
            tabBarTheme: TabBarThemeData(
              labelColor: Colors.white,
              labelStyle: context.textTheme.bodyLarge,
            ),
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  surface: primaryColor,
                ),
          ),
          home: const ChuckerPage(),
        ),
      ),
    );
  }
}

class _NotificationData {
  final String method;
  final int statusCode;
  final String path;
  final DateTime requestTime;

  _NotificationData({
    required this.method,
    required this.statusCode,
    required this.path,
    required this.requestTime,
  });
}

class ChuckerFlutter {
  const ChuckerFlutter._();
  static final navigatorObserver = NavigatorObserver();
  static bool showOnRelease = false;
  static bool isDebugMode = kDebugMode;
  static bool showNotification = true;
  static final chuckerButton =
      (isDebugMode || ChuckerFlutter.showOnRelease) ? ChuckerButton.getInstance() : const SizedBox.shrink();

  static void showChuckerScreen() => ChuckerUiHelper.showChuckerScreen();

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
