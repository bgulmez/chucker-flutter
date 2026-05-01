import 'dart:async';
import 'dart:convert';

import 'package:chucker_flutter/src/localization/localization.dart';
import 'package:chucker_flutter/src/models/api_response.dart';
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
  static SharedPreferencesManager getInstance({bool initData = true}) {
    return _sharedPreferencesManager ??= SharedPreferencesManager._(initData);
  }

  static const String _kApiResponses = 'api_responses';
  static const String _kSettings = 'chucker_settings';

  static final List<ApiResponse> _apiResponsesCache = [];
  static final List<ApiResponse> _tempBuffer = [];
  static bool _cacheInitialized = false;
  static bool _isInitializing = false;

  Timer? _debounceTimer;

  ///[addApiResponse] sets an API response to local disk
  Future<void> addApiResponse(ApiResponse apiResponse) async {
    if (ChuckerUiHelper.settings.apiThresholds == 0) return;

    // Eğer cache henüz hazır değilse, isteği geçici belleğe al ve init başlat
    if (!_cacheInitialized) {
      _tempBuffer.add(apiResponse);
      if (!_isInitializing) {
        _isInitializing = true;
        getAllApiResponses(); // Arka planda başlasın, bekleme yapmasın
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

    // Geçici bellekteki (init sırasında gelen) istekleri asıl cache'e aktar
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

  Future<void> deleteAnApi(String dateTime) async {
    _apiResponsesCache.removeWhere((e) => e.requestTime.toString() == dateTime);
    _scheduleSync();
  }

  Future<void> deleteSelected(List<String> dateTimes) async {
    _apiResponsesCache.removeWhere((e) => dateTimes.contains(e.requestTime.toString()));
    _scheduleSync();
  }

  Future<void> setSettings(Settings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_kSettings, jsonEncode(settings));
    ChuckerUiHelper.settings = settings;
  }

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
