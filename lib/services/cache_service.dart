// lib/services/cache_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulamanın önbellek mekanizmasını yöneten servis.
class CacheService {
  static const _dashboardCacheKey = 'dashboard_cache';
  static const _curriculumCachePrefix = 'curriculum_cache_';
  static const _availableWeeksCachePrefix = 'available_weeks_cache_';

  // --- Dashboard Cache ---

  Future<void> saveDashboardData({
    required int weekNo,
    required List<Map<String, dynamic>> agendaData,
    required List<Map<String, dynamic>> nextStepsData,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataToCache = {
        'week_no': weekNo,
        'timestamp': DateTime.now().toIso8601String(),
        'agenda': agendaData,
        'next_steps': nextStepsData,
      };
      final encodedData = jsonEncode(dataToCache);
      await prefs.setString(_dashboardCacheKey, encodedData);
      debugPrint('[CacheService] Dashboard data for week $weekNo saved successfully.');
    } catch (e) {
      debugPrint('[CacheService] Error saving dashboard data: $e');
    }
  }

  Future<Map<String, dynamic>?> getDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_dashboardCacheKey);
      if (cachedString == null || cachedString.isEmpty) return null;
      final decodedData = jsonDecode(cachedString) as Map<String, dynamic>;
      debugPrint('[CacheService] Dashboard data for week ${decodedData['week_no']} loaded from cache.');
      return decodedData;
    } catch (e) {
      debugPrint('[CacheService] Error loading dashboard data: $e');
      return null;
    }
  }

  // --- Weekly Curriculum Cache ---

  Future<void> saveWeeklyCurriculumData({
    required int weekNo,
    required int lessonId,
    required int gradeId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_curriculumCachePrefix${gradeId}_${lessonId}_$weekNo';
      final encodedData = jsonEncode(data);
      await prefs.setString(key, encodedData);
      debugPrint('[CacheService] Curriculum data for $key saved successfully.');
    } catch (e) {
      debugPrint('[CacheService] Error saving curriculum data: $e');
    }
  }

  Future<Map<String, dynamic>?> getWeeklyCurriculumData({
    required int weekNo,
    required int lessonId,
    required int gradeId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_curriculumCachePrefix${gradeId}_${lessonId}_$weekNo';
      final cachedString = prefs.getString(key);
      if (cachedString == null || cachedString.isEmpty) return null;
      final decodedData = jsonDecode(cachedString) as Map<String, dynamic>;
      debugPrint('[CacheService] Curriculum data for $key loaded from cache.');
      return decodedData;
    } catch (e) {
      debugPrint('[CacheService] Error loading curriculum data: $e');
      return null;
    }
  }

  // --- Available Weeks Cache ---

  Future<void> saveAvailableWeeks({
    required int gradeId,
    required int lessonId,
    required List<dynamic> weeks,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_availableWeeksCachePrefix${gradeId}_$lessonId';
      final encodedData = jsonEncode(weeks);
      await prefs.setString(key, encodedData);
      debugPrint('[CacheService] Available weeks for $key saved successfully.');
    } catch (e) {
      debugPrint('[CacheService] Error saving available weeks: $e');
    }
  }

  Future<List<dynamic>?> getAvailableWeeks({
    required int gradeId,
    required int lessonId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_availableWeeksCachePrefix${gradeId}_$lessonId';
      final cachedString = prefs.getString(key);
      if (cachedString == null || cachedString.isEmpty) return null;
      final decodedData = jsonDecode(cachedString) as List<dynamic>;
      debugPrint('[CacheService] Available weeks for $key loaded from cache.');
      return decodedData;
    } catch (e) {
      debugPrint('[CacheService] Error loading available weeks: $e');
      return null;
    }
  }

  // --- General ---

  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith(_dashboardCacheKey) ||
            key.startsWith(_curriculumCachePrefix) ||
            key.startsWith(_availableWeeksCachePrefix)) {
          await prefs.remove(key);
        }
      }
      debugPrint('[CacheService] All relevant cache cleared.');
    } catch (e) {
      debugPrint('[CacheService] Error clearing all cache: $e');
    }
  }
}
