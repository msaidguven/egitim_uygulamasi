import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _cacheVersion = 2; // Önbellek sürümünü 2'ye yükselt
  static const _cacheVersionKey = 'cache_version';
  static const _availableWeeksPrefix = 'available_weeks_cache_';
  static const _weeklyCurriculumPrefix = 'weekly_curriculum_cache_';

  SharedPreferences? _prefs;

  Future<void> _init() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
      final storedVersion = _prefs!.getInt(_cacheVersionKey) ?? 0;
      if (storedVersion < _cacheVersion) {
        await clearAll(); // Sürüm eskiyse tüm önbelleği temizle
        await _prefs!.setInt(_cacheVersionKey, _cacheVersion);
      }
    }
  }

  Future<void> clearAll() async {
    _prefs ??= await SharedPreferences.getInstance();
    final keys = _prefs!.getKeys();
    for (String key in keys) {
      if (key.startsWith(_availableWeeksPrefix) || key.startsWith(_weeklyCurriculumPrefix)) {
        await _prefs!.remove(key);
      }
    }
  }

  Future<List<dynamic>?> getAvailableWeeks({required int gradeId, required int lessonId}) async {
    await _init();
    final key = '$_availableWeeksPrefix${gradeId}_$lessonId';
    final cachedData = _prefs!.getString(key);
    if (cachedData != null) {
      debugPrint('[CacheService] Available weeks for $key loaded from cache.');
      return jsonDecode(cachedData) as List<dynamic>;
    }
    return null;
  }

  Future<void> saveAvailableWeeks({required int gradeId, required int lessonId, required List<dynamic> weeks}) async {
    await _init();
    final key = '$_availableWeeksPrefix${gradeId}_$lessonId';
    await _prefs!.setString(key, jsonEncode(weeks));
    debugPrint('[CacheService] Available weeks for $key saved to cache.');
  }

  Future<Map<String, dynamic>?> getWeeklyCurriculumData({
    required int curriculumWeek,
    required int lessonId,
    required int gradeId,
  }) async {
    await _init();
    final key = '$_weeklyCurriculumPrefix${gradeId}_${lessonId}_$curriculumWeek';
    final cachedData = _prefs!.getString(key);
    if (cachedData != null) {
      debugPrint('[CacheService] Weekly curriculum data for $key loaded from cache.');
      return jsonDecode(cachedData) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> saveWeeklyCurriculumData({
    required int curriculumWeek,
    required int lessonId,
    required int gradeId,
    required Map<String, dynamic> data,
  }) async {
    await _init();
    final key = '$_weeklyCurriculumPrefix${gradeId}_${lessonId}_$curriculumWeek';
    await _prefs!.setString(key, jsonEncode(data));
    debugPrint('[CacheService] Weekly curriculum data for $key saved to cache.');
  }

  Future<void> clearWeeklyCurriculumData({
    required int curriculumWeek,
    required int lessonId,
    required int gradeId,
  }) async {
    await _init();
    final key = '$_weeklyCurriculumPrefix${gradeId}_${lessonId}_$curriculumWeek';
    await _prefs!.remove(key);
    debugPrint('[CacheService] Cleared cache for key: $key');
  }
}
