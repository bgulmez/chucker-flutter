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
      getAllApiResponses();
    }
  }

  static SharedPreferencesManager? _sharedPreferencesManager;

  ///[getInstance] returns the singleton object of [SharedPreferencesManager]
  // ignore: prefer_constructors_over_static_methods
  static SharedPreferencesManager getInstance({bool initData = true}) {
    return _sharedPreferencesManager ??= SharedPreferencesManager._(initData);
  }

  static const String _kApiResponses = 'api_responses';
  static const String _kSettings = 'chucker_settings';

  static final List<ApiResponse> _apiResponsesCache = [];
  static bool _cacheInitialized = false;

  ///[addApiResponse] sets an API response to local disk
  Future<void> addApiResponse(ApiResponse apiResponse) async {
    if (ChuckerUiHelper.settings.apiThresholds == 0) {
      return;
    }

    if (!_cacheInitialized) {
      await getAllApiResponses();
    }

    if (_apiResponsesCache.length >= ChuckerUiHelper.settings.apiThresholds) {
      _apiResponsesCache.removeLast();
    }

    _apiResponsesCache.insert(0, apiResponse);

    final preferences = await SharedPreferences.getInstance();
    final jsonString = await compute(_encodeResponses, _apiResponsesCache);
    await preferences.setString(_kApiResponses, jsonString);
  }

  ///[getAllApiResponses] returns all api responses saved in local disk
  Future<List<ApiResponse>> getAllApiResponses() async {
    if (_cacheInitialized) {
      return _apiResponsesCache;
    }

    final preferences = await SharedPreferences.getInstance();

    final json = preferences.getString(_kApiResponses);

    if (json == null) {
      _cacheInitialized = true;
      return _apiResponsesCache;
    }

    final list = await compute(_decodeResponses, json);

    _apiResponsesCache
      ..clear()
      ..addAll(list)
      ..sort((a, b) => b.requestTime.compareTo(a.requestTime));

    _cacheInitialized = true;
    return _apiResponsesCache;
  }

  ///[deleteAnApi] deletes an api record from local disk
  Future<void> deleteAnApi(String dateTime) async {
    final apis = await getAllApiResponses();
    apis.removeWhere((e) => e.requestTime.toString() == dateTime);

    final preferences = await SharedPreferences.getInstance();
    final jsonString = await compute(_encodeResponses, apis);
    await preferences.setString(_kApiResponses, jsonString);
  }

  ///[deleteSelected] deletes api records from local disk
  Future<void> deleteSelected(List<String> dateTimes) async {
    final apis = await getAllApiResponses();
    apis.removeWhere((e) => dateTimes.contains(e.requestTime.toString()));

    final preferences = await SharedPreferences.getInstance();
    final jsonString = await compute(_encodeResponses, apis);
    await preferences.setString(_kApiResponses, jsonString);
  }

  ///[setSettings] saves the chucker settings in user's disk
  Future<void> setSettings(Settings settings) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _kSettings,
      jsonEncode(settings),
    );

    ChuckerUiHelper.settings = settings;
  }

  ///[getSettings] gets the chucker settings from user's disk
  Future<Settings> getSettings() async {
    final preferences = await SharedPreferences.getInstance();

    var settings = Settings.defaultObject();

    final jsonString = preferences.getString(_kSettings);

    if (jsonString == null) {
      return settings;
    }

    final json = jsonDecode(jsonString);

    settings = Settings.fromJson(json as Map<String, dynamic>);

    ChuckerUiHelper.settings = settings;
    Localization.updateLocalization(ChuckerUiHelper.settings.language);
    return settings;
  }

  ///[getApiResponse] returns single api response at given time
  Future<ApiResponse> getApiResponse(DateTime time) async {
    final apiResponses = await getAllApiResponses();

    return apiResponses.firstWhere(
      (api) => api.requestTime.compareTo(time) == 0,
      orElse: () => apiResponses.first,
    );
  }
}

///Top level function to be used with compute
String _encodeResponses(List<ApiResponse> responses) {
  return jsonEncode(responses);
}

///Top level function to be used with compute
List<ApiResponse> _decodeResponses(String json) {
  final list = jsonDecode(json) as List<dynamic>;
  return list.map((item) => ApiResponse.fromJson(item as Map<String, dynamic>)).toList();
}
