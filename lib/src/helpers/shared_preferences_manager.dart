import 'dart:async';
import 'dart:convert';

import 'package:chucker_flutter/src/localization/localization.dart';
import 'package:chucker_flutter/src/models/api_response.dart';
import 'package:chucker_flutter/src/models/log.dart';
import 'package:chucker_flutter/src/models/settings.dart';
import 'package:chucker_flutter/src/view/helper/chucker_ui_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

///[SharedPreferencesManager] handles storage of chucker data on user's disk
class SharedPreferencesManager {
  SharedPreferencesManager._(bool initData) {
    if (initData) {
      getSettings();
    }
  }

  static SharedPreferencesManager? _sharedPreferencesManager;

  ///[getInstance] returns the singleton object of [SharedPreferencesManager]
  static SharedPreferencesManager getInstance({bool initData = true}) {
    return _sharedPreferencesManager ??= SharedPreferencesManager._(initData);
  }

  static const String _kApiResponses = 'api_responses';
  static const String _kLogs = 'chucker_logs';
  static const String _kSettings = 'chucker_settings';

  static final List<ApiResponse> _apiResponsesCache = [];
  static final List<ApiResponse> _tempBuffer = [];
  static bool _cacheInitialized = false;
  static bool _isInitializing = false;

  static final List<Log> _logsCache = [];
  static bool _logsCacheInitialized = false;

  Timer? _debounceTimer;
  Timer? _logDebounceTimer;

  ///[addApiResponse] sets an API response to local disk
  Future<void> addApiResponse(ApiResponse apiResponse) async {
    if (ChuckerUiHelper.settings.apiThresholds == 0) return;

    if (!_cacheInitialized) {
      _tempBuffer.add(apiResponse);
      if (!_isInitializing) {
        _isInitializing = true;
        getAllApiResponses();
      }
      return;
    }

    _addToCache(apiResponse);
    _scheduleSync();
  }

  void _addToCache(ApiResponse apiResponse) {
    if (_apiResponsesCache.length >= ChuckerUiHelper.settings.apiThresholds) {
      _apiResponsesCache.removeLast();
    }
    _apiResponsesCache.insert(0, apiResponse);
  }

  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _syncToDisk();
    });
  }

  Future<void> _syncToDisk() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final cacheCopy = List<ApiResponse>.from(_apiResponsesCache);
      final jsonString = await compute(_encodeResponses, cacheCopy);
      await preferences.setString(_kApiResponses, jsonString);
    } catch (e) {
      debugPrint('Chucker Sync Error: $e');
    }
  }

  ///[getAllApiResponses] returns all api responses saved in local disk
  Future<List<ApiResponse>> getAllApiResponses() async {
    if (_cacheInitialized) return _apiResponsesCache;

    final preferences = await SharedPreferences.getInstance();
    final json = preferences.getString(_kApiResponses);

    if (json != null) {
      try {
        final list = await compute(_decodeResponses, json);
        _apiResponsesCache
          ..clear()
          ..addAll(list);
      } catch (e) {
        debugPrint('Chucker Load Error: $e');
      }
    }

    if (_tempBuffer.isNotEmpty) {
      for (final api in _tempBuffer.reversed) {
        _addToCache(api);
      }
      _tempBuffer.clear();
      _scheduleSync();
    }

    _apiResponsesCache.sort((a, b) => b.requestTime.compareTo(a.requestTime));
    _cacheInitialized = true;
    _isInitializing = false;
    return _apiResponsesCache;
  }

  ///[addLog] sets a log to local disk
  Future<void> addLog(Log log) async {
    if (!_logsCacheInitialized) {
      await getAllLogs();
    }

    if (_logsCache.length >= ChuckerUiHelper.settings.apiThresholds) {
      _logsCache.removeLast();
    }
    _logsCache.insert(0, log);

    _logDebounceTimer?.cancel();
    _logDebounceTimer = Timer(const Duration(milliseconds: 1000), () {
      _syncLogsToDisk();
    });
  }

  Future<void> _syncLogsToDisk() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final cacheCopy = List<Log>.from(_logsCache);
      final jsonString = await compute(_encodeLogs, cacheCopy);
      await preferences.setString(_kLogs, jsonString);
    } catch (e) {
      debugPrint('Chucker Log Sync Error: $e');
    }
  }

  ///[getAllLogs] returns all logs saved in local disk
  Future<List<Log>> getAllLogs() async {
    if (_logsCacheInitialized) return _logsCache;

    final preferences = await SharedPreferences.getInstance();
    final json = preferences.getString(_kLogs);

    if (json != null) {
      try {
        final list = await compute(_decodeLogs, json);
        _logsCache
          ..clear()
          ..addAll(list);
      } catch (e) {
        debugPrint('Chucker Log Load Error: $e');
      }
    }

    _logsCache.sort((a, b) => b.time.compareTo(a.time));
    _logsCacheInitialized = true;
    return _logsCache;
  }

  ///[deleteAnApi] deletes an api record from local disk
  Future<void> deleteAnApi(String dateTime) async {
    _apiResponsesCache.removeWhere((e) => e.requestTime.toString() == dateTime);
    _scheduleSync();
  }

  ///[deleteSelected] deletes api records from local disk
  Future<void> deleteSelected(List<String> dateTimes) async {
    _apiResponsesCache.removeWhere((e) => dateTimes.contains(e.requestTime.toString()));
    _scheduleSync();
  }

  ///[deleteLog] deletes a log record from local disk
  Future<void> deleteLog(String dateTime) async {
    _logsCache.removeWhere((e) => e.time.toString() == dateTime);
    _syncLogsToDisk();
  }

  ///[deleteSelectedLogs] deletes log records from local disk
  Future<void> deleteSelectedLogs(List<String> dateTimes) async {
    _logsCache.removeWhere((e) => dateTimes.contains(e.time.toString()));
    _syncLogsToDisk();
  }

  ///[setSettings] saves the chucker settings in user's disk
  Future<void> setSettings(Settings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_kSettings, jsonEncode(settings));
    ChuckerUiHelper.settings = settings;
  }

  ///[getSettings] gets the chucker settings from user's disk
  Future<Settings> getSettings() async {
    final preferences = await SharedPreferences.getInstance();
    var settings = Settings.defaultObject();
    final jsonString = preferences.getString(_kSettings);
    if (jsonString != null) {
      final json = jsonDecode(jsonString);
      settings = Settings.fromJson(json as Map<String, dynamic>);
    }
    ChuckerUiHelper.settings = settings;
    Localization.updateLocalization(ChuckerUiHelper.settings.language);
    return settings;
  }

  ///[getApiResponse] returns single api response at given time
  Future<ApiResponse> getApiResponse(DateTime time) async {
    final apiResponses = await getAllApiResponses();
    return apiResponses.firstWhere(
      (api) => api.requestTime.compareTo(time) == 0,
      orElse: () => apiResponses.isNotEmpty ? apiResponses.first : ApiResponse.mock(),
    );
  }
}

String _encodeResponses(List<ApiResponse> responses) => jsonEncode(responses);
List<ApiResponse> _decodeResponses(String json) {
  final list = jsonDecode(json) as List<dynamic>;
  return list.map((item) => ApiResponse.fromJson(item as Map<String, dynamic>)).toList();
}

String _encodeLogs(List<Log> logs) => jsonEncode(logs);
List<Log> _decodeLogs(String json) {
  final list = jsonDecode(json) as List<dynamic>;
  return list.map((item) => Log.fromJson(item as Map<String, dynamic>)).toList();
}
