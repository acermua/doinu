import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/datamodel.dart';
import '../shared/constants.dart';

class DashboardDailyFetcher {
  static const _cacheKey = 'daily_dashboard_v1';
  static const _cacheTsKey = 'daily_dashboard_ts_v1';
  static const _cacheDuration = Duration(hours: 6);

  static SharedPreferences? _prefs;
  static bool _initing = false;

  // ---------- INIT ----------

  static Future<void> _init() async {
    if (_prefs != null) return;

    if (_initing) {
      while (_prefs == null) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _initing = true;
    _prefs = await SharedPreferences.getInstance();
    _initing = false;
  }

  static bool _isStale(String? tsIso) {
    if (tsIso == null) return true;
    try {
      final then = DateTime.parse(tsIso);
      return DateTime.now().difference(then) > _cacheDuration;
    } catch (_) {
      return true;
    }
  }

  // ---------- PUBLIC API ----------

  /// Fetch dashboard sections in exact display order.
  /// Cached for 24h.
  static Future<List<DashboardSection>> getDashboard() async {
    await _init();

    try {
      final stale = _isStale(_prefs!.getString(_cacheTsKey));

      // ---- Serve cache if valid ----
      if (!stale) {
        final raw = _prefs!.getString(_cacheKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw) as List<dynamic>;
          return decoded
              .whereType<Map<String, dynamic>>()
              .map(DashboardSection.fromJson)
              .toList();
        }
      }

      // ---- Fetch fresh from Supabase ----
      final fresh = await sb.getDashboardData();

      // ---- Cache result ----
      await _prefs!.setString(
        _cacheKey,
        jsonEncode(fresh.map((e) => e.toJson()).toList()),
      );
      await _prefs!.setString(_cacheTsKey, DateTime.now().toIso8601String());

      return fresh;
    } catch (e, st) {
      debugPrint('DashboardDailyFetcher failed: $e');
      debugPrint('$st');
      return [];
    }
  }

  /// Optional manual reset
  static Future<void> clearCache() async {
    await _init();
    await _prefs!.remove(_cacheKey);
    await _prefs!.remove(_cacheTsKey);
  }
}

/// Helper
extension Cap on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
