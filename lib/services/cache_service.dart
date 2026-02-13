import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _cacheVersion = 3; // TTL + ders-bazlı pruning
  static const _cacheVersionKey = 'cache_version';
  static const _availableWeeksPrefix = 'available_weeks_cache_';
  static const _weeklyCurriculumPrefix = 'weekly_curriculum_cache_';
  static const _timestampSuffix = '__ts';
  static const _availableWeeksTtlMs = 7 * 24 * 60 * 60 * 1000; // 7 gün
  static const _weeklyCurriculumTtlMs = 48 * 60 * 60 * 1000; // 48 saat
  static const _maxWeeklyCachePerLesson = 6; // grade+lesson başına

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
      if (key.startsWith(_availableWeeksPrefix) ||
          key.startsWith(_weeklyCurriculumPrefix)) {
        await _prefs!.remove(key);
      }
    }
  }

  Future<List<dynamic>?> getAvailableWeeks({
    required int gradeId,
    required int lessonId,
  }) async {
    await _init();
    final key = '$_availableWeeksPrefix${gradeId}_$lessonId';
    final cachedData = _prefs!.getString(key);
    final ts = _prefs!.getInt(_timestampKey(key));
    if (_isExpired(ts, _availableWeeksTtlMs)) {
      await _prefs!.remove(key);
      await _prefs!.remove(_timestampKey(key));
      return null;
    }
    if (cachedData != null) {
      debugPrint('[CacheService] Available weeks for $key loaded from cache.');
      return jsonDecode(cachedData) as List<dynamic>;
    }
    return null;
  }

  Future<void> saveAvailableWeeks({
    required int gradeId,
    required int lessonId,
    required List<dynamic> weeks,
  }) async {
    await _init();
    final key = '$_availableWeeksPrefix${gradeId}_$lessonId';
    await _prefs!.setString(key, jsonEncode(weeks));
    await _prefs!.setInt(
      _timestampKey(key),
      DateTime.now().millisecondsSinceEpoch,
    );
    debugPrint('[CacheService] Available weeks for $key saved to cache.');
  }

  Future<Map<String, dynamic>?> getWeeklyCurriculumData({
    required int curriculumWeek,
    required int lessonId,
    required int gradeId,
  }) async {
    await _init();
    final key =
        '$_weeklyCurriculumPrefix${gradeId}_${lessonId}_$curriculumWeek';
    final cachedData = _prefs!.getString(key);
    final ts = _prefs!.getInt(_timestampKey(key));
    if (_isExpired(ts, _weeklyCurriculumTtlMs)) {
      await _prefs!.remove(key);
      await _prefs!.remove(_timestampKey(key));
      return null;
    }
    if (cachedData != null) {
      debugPrint(
        '[CacheService] Weekly curriculum data for $key loaded from cache.',
      );
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
    final key =
        '$_weeklyCurriculumPrefix${gradeId}_${lessonId}_$curriculumWeek';
    await _prefs!.setString(key, jsonEncode(data));
    await _prefs!.setInt(
      _timestampKey(key),
      DateTime.now().millisecondsSinceEpoch,
    );
    await _pruneWeeklyCacheForLesson(gradeId: gradeId, lessonId: lessonId);
    debugPrint(
      '[CacheService] Weekly curriculum data for $key saved to cache.',
    );
  }

  Future<void> clearWeeklyCurriculumData({
    required int curriculumWeek,
    required int lessonId,
    required int gradeId,
  }) async {
    await _init();
    final key =
        '$_weeklyCurriculumPrefix${gradeId}_${lessonId}_$curriculumWeek';
    await _prefs!.remove(key);
    await _prefs!.remove(_timestampKey(key));
    debugPrint('[CacheService] Cleared cache for key: $key');
  }

  bool _isExpired(int? timestampMs, int ttlMs) {
    if (timestampMs == null) return false;
    return DateTime.now().millisecondsSinceEpoch - timestampMs > ttlMs;
  }

  String _timestampKey(String key) => '$key$_timestampSuffix';

  Future<void> _pruneWeeklyCacheForLesson({
    required int gradeId,
    required int lessonId,
  }) async {
    final basePrefix = '$_weeklyCurriculumPrefix${gradeId}_${lessonId}_';
    final keys = _prefs!.getKeys();
    final weeklyEntries = <MapEntry<int, String>>[];

    for (final key in keys) {
      if (!key.startsWith(basePrefix)) continue;
      if (key.endsWith(_timestampSuffix)) continue;
      final weekPart = key.substring(basePrefix.length);
      final week = int.tryParse(weekPart);
      if (week == null) continue;
      weeklyEntries.add(MapEntry(week, key));
    }

    if (weeklyEntries.length <= _maxWeeklyCachePerLesson) return;

    weeklyEntries.sort((a, b) => b.key.compareTo(a.key)); // son haftalar kalsın
    final removable = weeklyEntries.skip(_maxWeeklyCachePerLesson);
    for (final entry in removable) {
      await _prefs!.remove(entry.value);
      await _prefs!.remove(_timestampKey(entry.value));
    }
  }
}
