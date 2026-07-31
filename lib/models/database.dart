import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../shared/constants.dart';
import 'datamodel.dart';

part 'database.g.dart';

class AppDatabase {
  static const _songKey = 'songsDb';
  static const _songLastFetchKey = 'songsDb_last_fetch';
  static const _cacheDuration = Duration(days: 14);

  static Map<String, dynamic> _cache = {};
  static bool _initialized = false;
  static late SharedPreferences _prefs;

  // -------------------- INIT --------------------
  static Future<void> _init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    final now = DateTime.now();
    final lastFetchMillis = _prefs.getInt(_songLastFetchKey);

    bool isCacheValid = false;
    if (lastFetchMillis != null) {
      final lastFetch = DateTime.fromMillisecondsSinceEpoch(lastFetchMillis);
      isCacheValid = now.difference(lastFetch) < _cacheDuration;
    }

    if (isCacheValid) {
      final stored = _prefs.getString(_songKey);
      if (stored != null) {
        final decoded = jsonDecode(stored);
        if (decoded is Map<String, dynamic>) {
          _cache = decoded;
        }
      }
    } else {
      // Cache expired → clear
      _cache.clear();
      await _prefs.remove(_songKey);
      await _prefs.remove(_songLastFetchKey);
    }

    _initialized = true;
  }

  // -------------------- SONG STORAGE --------------------
  static Future<SongDetail> saveSongDetail(SongDetail song) async {
    await _init();

    // Convert the song to JSON
    Map<String, dynamic> newJson = SongDetail.songDetailToJson(song);

    // Check if the song has download URLs
    final newDownloadUrls = (newJson['downloadUrl'] as List?) ?? [];
    if (newDownloadUrls.isEmpty) {
      debugPrint(
        "--- Song '${song.title}' has no download URLs, removing from cache",
      );
      _cache.remove(song.id);
      await _prefs.setString(_songKey, jsonEncode(_cache));
      return song;
    }

    // Merge with existing cache if present
    if (_cache.containsKey(song.id)) {
      final oldJson = Map<String, dynamic>.from(_cache[song.id]);

      for (final key in newJson.keys) {
        final newValue = newJson[key];

        // Skip null or empty values
        if (newValue == null) continue;
        if (newValue is String && newValue.isEmpty) continue;
        if (newValue is List && newValue.isEmpty) continue;
        if (newValue is Map && newValue.isEmpty) continue;

        oldJson[key] = newValue;
      }

      _cache[song.id] = oldJson;
    } else {
      _cache[song.id] = newJson;
    }

    // Save the updated cache to SharedPreferences
    await _prefs.setString(_songKey, jsonEncode(_cache));
    await _prefs.setInt(
      _songLastFetchKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    notifyChanges();

    debugPrint("--- Song '${song.title}' saved to cache successfully");

    // Return the stored song
    return SongDetail.fromJson(Map<String, dynamic>.from(_cache[song.id]));
  }

  /// Lightweight save for a Song (wrap into SongDetail)
  static Future<SongDetail> saveSong(Song song) async {
    final detail = SongDetail(
      id: song.id,
      title: song.title,
      type: song.type,
      url: song.url,
      images: song.images,
      description: song.description,
      language: song.language,
      album: song.album,
      primaryArtists: song.primaryArtists,
      singers: song.singers,
    );
    return saveSongDetail(detail);
  }

  static Future<SongDetail?> getSong(String id) async {
    await _init();
    if (!_cache.containsKey(id)) return null;
    return SongDetail.fromJson(Map<String, dynamic>.from(_cache[id]));
  }

  /// Batch lookup to reduce multiple DB hits
  static Future<List<SongDetail>> getSongs(List<String> ids) async {
    await _init();
    final List<SongDetail> results = [];

    for (final id in ids) {
      if (_cache.containsKey(id)) {
        results.add(SongDetail.fromJson(Map<String, dynamic>.from(_cache[id])));
      }
    }
    return results;
  }

  static Future<List<SongDetail>> getAllSongs() async {
    await _init();
    return _cache.values
        .map((e) => SongDetail.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> removeSong(String id) async {
    await _init();
    _cache.remove(id);
    await _prefs.setString(_songKey, jsonEncode(_cache));
  }

  static Future<void> clearSongs() async {
    await _init();
    _cache.clear();
    await _prefs.remove(_songKey);
    await _prefs.remove(_songLastFetchKey);
  }

  static final StreamController<void> _changes = StreamController.broadcast();

  static Stream<void> get changes => _changes.stream;

  static void notifyChanges() => _changes.add(null);

  /// Cleanup songs that don't have proper download URLs
  static Future<void> cleanupMalformedSongs() async {
    await _init();
    final List<String> toRemove = [];

    _cache.forEach((id, data) {
      if (data is! Map<String, dynamic>) return;
      
      final downloadUrlData = data['downloadUrl'];
      bool hasValidUrl = false;

      if (downloadUrlData is String && downloadUrlData.startsWith('http')) {
        hasValidUrl = true;
      } else if (downloadUrlData is List && downloadUrlData.isNotEmpty) {
        for (final item in downloadUrlData) {
          String? url;
          if (item is Map<String, dynamic>) {
            url = item['url']?.toString();
          } else if (item is String) {
            url = item;
          }

          if (url != null && url.startsWith('http')) {
            hasValidUrl = true;
            break;
          }
        }
      }

      if (!hasValidUrl) {
        final topLevelUrl = data['url']?.toString() ?? '';
        // If it looks like a direct stream URL, consider it valid
        if (topLevelUrl.startsWith('http') && 
            (topLevelUrl.contains('.mp3') || 
             topLevelUrl.contains('.m4a') || 
             topLevelUrl.contains('.flac'))) {
          hasValidUrl = true;
        }
      }

      if (!hasValidUrl) {
        toRemove.add(id);
      }
    });

    if (toRemove.isNotEmpty) {
      for (final id in toRemove) {
        _cache.remove(id);
      }
      await _prefs.setString(_songKey, jsonEncode(_cache));
      notifyChanges();
      debugPrint('--- [Database] Cleaned up ${toRemove.length} malformed songs');
    }
  }

  // played Duration
  static Future<void> addPlayedDuration(String songId, Duration played) async {
    await _init();

    final Map<String, dynamic> songData = _cache[songId] != null
        ? Map<String, dynamic>.from(_cache[songId])
        : {};

    final int oldMs = (songData['playedMs'] as int?) ?? 0;
    final int newMs = oldMs + played.inMilliseconds;

    songData['playedMs'] = newMs;

    // store last played timestamp
    songData['lastPlayed'] = DateTime.now().toIso8601String();

    _cache[songId] = songData;
    await _prefs.setString(_songKey, jsonEncode(_cache));
    await _prefs.setInt(
      _songLastFetchKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    notifyChanges();
  }

  // ----------------- DURATION PLAYED --------------------------
  static Future<double> getMonthlyListeningHours({DateTime? month}) async {
    await _init();
    final now = month ?? DateTime.now();
    final y = now.year;
    final m = now.month;

    int totalMs = 0;
    for (final entry in _cache.values) {
      final lastPlayedStr = entry['lastPlayed'] as String?;
      if (lastPlayedStr != null) {
        final lastPlayed = DateTime.tryParse(lastPlayedStr);
        if (lastPlayed != null &&
            lastPlayed.year == y &&
            lastPlayed.month == m) {
          totalMs += (entry['playedMs'] as int?) ?? 0;
        }
      }
    }

    return totalMs / 1000 / 60; // hours
  }
}

//unified cacheRecentDB
class CacheRecentDB {
  static final ArtistDB artists = ArtistDB();
  static final PlaylistDB playlists = PlaylistDB();
  static final AlbumDB albums = AlbumDB();

  static Future<void> initAll({int limit = 20}) async {
    await Future.wait([
      artists.init(limit: limit),
      playlists.init(limit: limit),
      albums.init(limit: limit),
    ]);
  }
}

abstract class CacheDB {
  final Map<String, String> _data = {};

  bool _isInitialized = false;
  DateTime? _lastFetched;

  /// 6 hour cache duration (change if needed)
  Duration get cacheDuration => const Duration(hours: 6);

  /// Must be implemented in child
  Future<List<dynamic>> fetch(int limit);

  /// Extract id from model
  String getId(dynamic item);

  /// Extract title/name from model
  String getTitle(dynamic item);

  /// The cache key for SharedPreferences
  String get storageKey;

  Future<void> init({int limit = 20, bool force = false}) async {
    final now = DateTime.now();

    if (!force &&
        _isInitialized &&
        _lastFetched != null &&
        now.difference(_lastFetched!) < cacheDuration) {
      debugPrint("CacheDB($runtimeType): still valid in memory, returning.");
      return; // still valid
    }

    final prefs = await SharedPreferences.getInstance();

    // Check SharedPreferences
    if (!force) {
      final storedData = prefs.getString('${storageKey}_data');
      final storedTime = prefs.getString('${storageKey}_time');

      if (storedData != null && storedTime != null) {
        final lastTime = DateTime.tryParse(storedTime);
        if (lastTime != null && now.difference(lastTime) < cacheDuration) {
          debugPrint(
            "CacheDB($runtimeType): valid data from SharedPreferences.",
          );
          _data.clear();
          try {
            final Map<String, dynamic> decoded = jsonDecode(storedData);
            decoded.forEach((key, value) {
              _data[key] = value.toString();
            });
            _isInitialized = true;
            _lastFetched = lastTime;
            return;
          } catch (e) {
            debugPrint(
              "CacheDB($runtimeType): failed to parse stored data: $e",
            );
          }
        }
      }
    }

    debugPrint("CacheDB($runtimeType): Fetching from network...");
    final list = await fetch(limit);
    debugPrint(
      "CacheDB($runtimeType): Fetched ${list.length} items from network.",
    );

    _data
      ..clear()
      ..addEntries(list.map((e) => MapEntry(getId(e), getTitle(e))));

    _isInitialized = true;
    _lastFetched = now;

    // Save to SharedPreferences
    await prefs.setString('${storageKey}_data', jsonEncode(_data));
    await prefs.setString('${storageKey}_time', now.toIso8601String());
  }

  bool get isStale {
    if (!_isInitialized || _lastFetched == null) return true;
    return DateTime.now().difference(_lastFetched!) >= cacheDuration;
  }

  String? getName(String id) => _data[id];

  String? getIdByName(String name) {
    try {
      return _data.entries
          .firstWhere((e) => e.value.toLowerCase() == name.toLowerCase())
          .key;
    } catch (_) {
      return null;
    }
  }

  List<MapEntry<String, String>> get all => _data.entries.toList();
}

// Artists
class ArtistDB extends CacheDB {
  @override
  String get storageKey => 'recent_artists_cache_v1';

  @override
  Future<List<dynamic>> fetch(int limit) => sb.getRecentArtists(limit: limit);

  @override
  String getId(item) => item.id;

  @override
  String getTitle(item) => item.title;
}

// Playlists
class PlaylistDB extends CacheDB {
  @override
  String get storageKey => 'recent_playlists_cache_v1';

  @override
  Future<List<dynamic>> fetch(int limit) => sb.getRecentPlaylists(limit: limit);

  @override
  String getId(item) => item.id;

  @override
  String getTitle(item) => item.title;
}

// Albums
class AlbumDB extends CacheDB {
  @override
  String get storageKey => 'recent_albums_cache_v1';

  @override
  Future<List<dynamic>> fetch(int limit) => sb.getRecentAlbums(limit: limit);

  @override
  String getId(item) => item.id;

  @override
  String getTitle(item) => item.title;
}

// Artist cache with persistence
class ArtistCache {
  static const _prefsKey = 'artist_cache';
  static const _usageKey = 'artist_usage';
  static const _fetchedKey = 'artist_fetched_at';
  static final ArtistCache _instance = ArtistCache._internal();
  factory ArtistCache() => _instance;
  ArtistCache._internal();

  final Map<String, ArtistDetails> _cache = {};
  final Map<String, int> _usageCount = {};
  final Map<String, DateTime> _fetchedAt = {};

  bool _initialized = false;
  late SharedPreferences _prefs;

  Future<void> _init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    final fetchedStored = _prefs.getString(_fetchedKey);
    if (fetchedStored != null) {
      final Map<String, dynamic> decoded = jsonDecode(fetchedStored);
      decoded.forEach((key, value) {
        _fetchedAt[key] = DateTime.parse(value as String);
      });
    }

    final stored = _prefs.getString(_prefsKey);
    if (stored != null) {
      final Map<String, dynamic> decoded = jsonDecode(stored);
      decoded.forEach((key, value) {
        _cache[key] = ArtistDetails.fromJson(Map<String, dynamic>.from(value));
      });
    }

    final usageStored = _prefs.getString(_usageKey);
    if (usageStored != null) {
      final Map<String, dynamic> usageDecoded = jsonDecode(usageStored);
      usageDecoded.forEach((key, value) {
        _usageCount[key] = value;
      });
    }

    _initialized = true;
  }

  Future<ArtistDetails?> get(String artistId) async {
    await _init();
    _incrementUsage(artistId);
    return _cache[artistId];
  }

  Future<void> set(String artistId, ArtistDetails details) async {
    await _init();
    _cache[artistId] = details;
    _fetchedAt[artistId] = DateTime.now();
    await _saveToPrefs();
  }

  bool isExpired(String artistId) {
    final fetched = _fetchedAt[artistId];
    if (fetched == null) return true;
    return DateTime.now().difference(fetched) > Duration(hours: 6);
  }

  void _incrementUsage(String artistId) {
    _usageCount[artistId] = (_usageCount[artistId] ?? 0) + 1;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () async {
      await _saveToPrefs();
    });
  }

  /// Get usage count for a specific artist

  int getUsageCount(String artistId) {
    return _usageCount[artistId] ?? 0;
  }

  Future<int> getTotalVisits() async {
    await _init();
    int total = 0;
    for (final count in _usageCount.values) {
      total += count;
    }
    return total == 0 ? 100 : total;
  }

  /// Return all artists with their usage counts together

  Future<List<MapEntry<ArtistDetails, int>>> getAllWithUsage() async {
    await _init();
    final list = _cache.values.toList();
    list.sort((a, b) {
      final usageA = _usageCount[a.id] ?? 0;
      final usageB = _usageCount[b.id] ?? 0;
      return usageB.compareTo(usageA);
    });

    return list
        .map((artist) => MapEntry(artist, _usageCount[artist.id] ?? 0))
        .toList();
  }

  Timer? _saveTimer;

  Future<void> _saveToPrefs() async {
    final Map<String, dynamic> toStore = {};
    final Map<String, String> fetchedStore = {};

    _cache.forEach((key, value) {
      toStore[key] = ArtistDetails.artistDetailsToJson(value);
    });

    _fetchedAt.forEach((key, value) {
      fetchedStore[key] = value.toIso8601String();
    });

    await _prefs.setString(_prefsKey, jsonEncode(toStore));
    await _prefs.setString(_usageKey, jsonEncode(_usageCount));
    await _prefs.setString(_fetchedKey, jsonEncode(fetchedStore));
  }

  Future<List<ArtistDetails>> getAll({bool sortByUsage = false}) async {
    await _init();
    final list = _cache.values.toList();
    if (sortByUsage) {
      list.sort((a, b) {
        final usageA = _usageCount[a.id] ?? 0;
        final usageB = _usageCount[b.id] ?? 0;
        return usageB.compareTo(usageA);
      });
    }
    return list;
  }

  Future<void> clear() async {
    await _init();
    _cache.clear();
    _usageCount.clear();
    _fetchedAt.clear();
    await _prefs.remove(_prefsKey);
    await _prefs.remove(_usageKey);
    await _prefs.remove(_fetchedKey);
  }

  static final StreamController<void> _artistChanges =
      StreamController.broadcast();

  static Stream<void> get artistChanges => _artistChanges.stream;

  static void notifyArtistChanges() => _artistChanges.add(null);
}

// Album cache with persistence
class AlbumCache {
  static const _prefsKey = 'album_cache';
  static const _usageKey = 'album_usage';
  static const _fetchedKey = 'album_fetched_at'; // <-- added
  static final AlbumCache _instance = AlbumCache._internal();
  factory AlbumCache() => _instance;
  AlbumCache._internal();

  final Map<String, Album> _cache = {};
  final Map<String, int> _usageCount = {}; // track usage
  final Map<String, DateTime> _fetchedAt = {}; // track fetch timestamp

  bool _initialized = false;
  late SharedPreferences _prefs;

  Future<void> _init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    final fetchedStored = _prefs.getString(_fetchedKey);
    if (fetchedStored != null) {
      final Map<String, dynamic> decoded = jsonDecode(fetchedStored);
      decoded.forEach((key, value) {
        _fetchedAt[key] = DateTime.parse(value as String);
      });
    }

    final stored = _prefs.getString(_prefsKey);
    if (stored != null) {
      final Map<String, dynamic> decoded = jsonDecode(stored);
      decoded.forEach((key, value) {
        _cache[key] = Album.fromJson(Map<String, dynamic>.from(value));
      });
    }

    final usageStored = _prefs.getString(_usageKey);
    if (usageStored != null) {
      final Map<String, dynamic> usageDecoded = jsonDecode(usageStored);
      usageDecoded.forEach((key, value) {
        _usageCount[key] = value;
      });
    }

    _initialized = true;
  }

  Future<Album?> get(String albumId) async {
    await _init();
    _incrementUsage(albumId);
    return _cache[albumId];
  }

  Future<void> set(String albumId, Album album) async {
    await _init();
    _cache[albumId] = album;
    _fetchedAt[albumId] = DateTime.now(); // <-- record fetch timestamp
    await _saveToPrefs();
    notifyAlbumChanges();
  }

  /// Check if cached album is older than 2 days
  bool isExpired(String albumId) {
    final fetched = _fetchedAt[albumId];
    if (fetched == null) return true;
    return DateTime.now().difference(fetched) > Duration(hours: 6);
  }

  int getUsageCount(String albumId) {
    return _usageCount[albumId] ?? 0;
  }

  Future<void> _saveToPrefs() async {
    final Map<String, dynamic> toStore = {};
    _cache.forEach((key, value) {
      toStore[key] = Album.albumToJson(value);
    });

    await _prefs.setString(
      _fetchedKey,
      jsonEncode(_fetchedAt.map((k, v) => MapEntry(k, v.toIso8601String()))),
    );
    await _prefs.setString(_prefsKey, jsonEncode(toStore));
    await _prefs.setString(_usageKey, jsonEncode(_usageCount));
  }

  void _incrementUsage(String albumId) {
    _usageCount[albumId] = (_usageCount[albumId] ?? 0) + 1;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () async {
      await _saveToPrefs();
    });
  }

  Future<List<Album>> getAll({bool sortByUsage = false}) async {
    await _init();
    final list = _cache.values.toList();
    if (sortByUsage) {
      list.sort((a, b) {
        final usageA = _usageCount[a.id] ?? 0;
        final usageB = _usageCount[b.id] ?? 0;
        return usageB.compareTo(usageA);
      });
    }
    return list;
  }

  Timer? _saveTimer;

  static final StreamController<void> _albumChanges =
      StreamController.broadcast();
  static Stream<void> get albumChanges => _albumChanges.stream;
  static void notifyAlbumChanges() => _albumChanges.add(null);

  Future<void> clear() async {
    await _init();
    _cache.clear();
    _usageCount.clear();
    _fetchedAt.clear(); // <-- clear timestamps
    _saveTimer?.cancel();
    _saveTimer = null;
    await _prefs.remove(_prefsKey);
    await _prefs.remove(_usageKey);
    await _prefs.remove(_fetchedKey);
  }
}

// Playlist cache with persistence
class PlaylistCache {
  static const _prefsKey = 'playlist_cache';
  static const _usageKey = 'playlist_usage';
  static const fetchKey = 'playlist_fetched_at';
  static final PlaylistCache _instance = PlaylistCache._internal();
  factory PlaylistCache() => _instance;
  PlaylistCache._internal();

  final Map<String, Playlist> _cache = {};
  final Map<String, int> _usageCount = {}; // track usage
  final Map<String, DateTime> _fetchedAt = {};

  bool _initialized = false;
  late SharedPreferences _prefs;

  /// Initialize cache
  Future<void> _init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();

    final storedFetchedAt = _prefs.getString(fetchKey);
    if (storedFetchedAt != null) {
      final Map<String, dynamic> decoded = jsonDecode(storedFetchedAt);
      decoded.forEach((key, value) {
        _fetchedAt[key] = DateTime.parse(value as String);
      });
    }

    final stored = _prefs.getString(_prefsKey);
    if (stored != null) {
      final Map<String, dynamic> decoded = jsonDecode(stored);
      decoded.forEach((key, value) {
        _cache[key] = Playlist.fromJson(Map<String, dynamic>.from(value));
      });
    }

    final usageStored = _prefs.getString(_usageKey);
    if (usageStored != null) {
      final Map<String, dynamic> usageDecoded = jsonDecode(usageStored);
      usageDecoded.forEach((key, value) {
        _usageCount[key] = value;
      });
    }

    _initialized = true;
  }

  /// Get playlist by id
  Future<Playlist?> get(String playlistId) async {
    await _init();
    _incrementUsage(playlistId);
    return _cache[playlistId];
  }

  /// Set/update playlist
  Future<void> set(String playlistId, Playlist playlist) async {
    await _init();
    _cache[playlistId] = playlist;
    _fetchedAt[playlistId] = DateTime.now();
    await _saveToPrefs();
    notifyPlaylistChanges();
  }

  bool isExpired(String playlistId) {
    final fetched = _fetchedAt[playlistId];
    if (fetched == null) return true; // no timestamp → expired
    return DateTime.now().difference(fetched) > Duration(hours: 6);
  }

  /// Get all playlists, optionally sorted by usage
  Future<List<Playlist>> getAll({bool sortByUsage = false}) async {
    await _init();
    final list = _cache.values.toList();
    if (sortByUsage) {
      list.sort((a, b) {
        final usageA = _usageCount[a.id] ?? 0;
        final usageB = _usageCount[b.id] ?? 0;
        return usageB.compareTo(usageA); // most used first
      });
    }
    return list;
  }

  /// Clear cache
  Future<void> clear() async {
    await _init();
    _cache.clear();
    _fetchedAt.clear();
    _usageCount.clear();
    await _prefs.remove(_prefsKey);
    await _prefs.remove(_usageKey);
    _saveTimer?.cancel();
    _saveTimer = null;
  }

  /// Save current state to SharedPreferences
  Future<void> _saveToPrefs() async {
    final Map<String, dynamic> toStore = {};
    _cache.forEach((key, value) {
      toStore[key] = Playlist.playlistToJson(value);
    });
    await _prefs.setString(
      fetchKey,
      jsonEncode(_fetchedAt.map((k, v) => MapEntry(k, v.toIso8601String()))),
    );
    await _prefs.setString(_prefsKey, jsonEncode(toStore));
    await _prefs.setString(_usageKey, jsonEncode(_usageCount));
  }

  Timer? _saveTimer;

  /// Increment usage count for a playlist
  void _incrementUsage(String playlistId) {
    _usageCount[playlistId] = (_usageCount[playlistId] ?? 0) + 1;
    debugPrint(
      "Playlist usage incremented: $playlistId → ${_usageCount[playlistId]}",
    );

    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), () async {
      await _saveToPrefs();
    });
  }

  /// Notify listeners of changes
  static final StreamController<void> _playlistChanges =
      StreamController.broadcast();
  static Stream<void> get playlistChanges => _playlistChanges.stream;
  static void notifyPlaylistChanges() => _playlistChanges.add(null);
}

// ---------------- SEARCH HISTORY ----------------
List<String> searchHistory = [];

Future<void> loadSearchHistory() async {
  final prefs = await SharedPreferences.getInstance();
  searchHistory = prefs.getStringList('search_history') ?? [];
}

Future<void> saveSearchTerm(String term) async {
  term = term.trim();
  if (term.isEmpty) return;

  // remove duplicate if already exists
  searchHistory.remove(term);
  searchHistory.insert(0, term); // put latest at front

  // keep max 5
  if (searchHistory.length > 5) {
    searchHistory = searchHistory.sublist(0, 5);
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('search_history', searchHistory);
}

// ---------------- LAST SONGS ----------------
Future<List<SongDetail>> loadLastSongs() async {
  final prefs = await SharedPreferences.getInstance();
  final songsJson = prefs.getStringList('last_songs') ?? [];
  return songsJson.map((s) => SongDetail.fromJson(jsonDecode(s))).toList();
}

Future<void> storeLastSongs(List<SongDetail> newSongs) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = await loadLastSongs();

  final updated = [
    ...newSongs,
    ...existing.where((e) => !newSongs.any((n) => n.id == e.id)),
  ].take(5).toList(); // keep only 5

  final songsJson = updated
      .map((s) => jsonEncode(SongDetail.songDetailToJson(s)))
      .toList();
  await prefs.setStringList('last_songs', songsJson);
}

// ---------------- LAST ALBUMS ----------------
Future<List<Album>> loadLastAlbums() async {
  final prefs = await SharedPreferences.getInstance();
  final albumsJson = prefs.getStringList('last_albums') ?? [];
  return albumsJson.map((a) => Album.fromJson(jsonDecode(a))).toList();
}

Future<void> storeLastAlbums(List<Album> newAlbums) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = await loadLastAlbums();

  final updated = [
    ...newAlbums,
    ...existing.where((e) => !newAlbums.any((n) => n.id == e.id)),
  ].take(5).toList();

  final albumsJson = updated
      .map((a) => jsonEncode(Album.albumToJson(a)))
      .toList();
  await prefs.setStringList('last_albums', albumsJson);
}

// ---------------- REMOVE LAST SONG ----------------
Future<void> removeLastSong(String songId) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = await loadLastSongs();

  final updated = existing.where((s) => s.id != songId).toList();

  final songsJson = updated
      .map((s) => jsonEncode(SongDetail.songDetailToJson(s)))
      .toList();
  await prefs.setStringList('last_songs', songsJson);
}

// ---------------- REMOVE LAST ALBUM ----------------
Future<void> removeLastAlbum(String albumId) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = await loadLastAlbums();

  final updated = existing.where((a) => a.id != albumId).toList();

  final albumsJson = updated
      .map((a) => jsonEncode(Album.albumToJson(a)))
      .toList();
  await prefs.setStringList('last_albums', albumsJson);
}

// ---------------- ALL SONGS PROVIDER -------------------
@Riverpod(keepAlive: true)
class AllSongs extends _$AllSongs {
  StreamSubscription? _sub;

  @override
  List<SongDetail> build() {
    // Listen to DB changes
    _sub = AppDatabase.changes.listen((_) {
      refresh();
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    _loadSongs();
    return [];
  }

  Future<void> _loadSongs() async {
    state = await AppDatabase.getAllSongs();
  }

  Future<void> refresh() async {
    await _loadSongs();
  }
}

// ---------------- ARTIST CACHE PROVIDER ------------------
@Riverpod(keepAlive: true)
class ArtistsWithUsage extends _$ArtistsWithUsage {
  StreamSubscription? _sub;

  @override
  List<MapEntry<ArtistDetails, int>> build() {
    _sub = ArtistCache.artistChanges.listen((_) {
      refresh();
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    refresh();
    return [];
  }

  Future<void> refresh() async {
    state = await ArtistCache().getAllWithUsage();
  }
}

@Riverpod(keepAlive: true)
class Artists extends _$Artists {
  @override
  List<ArtistDetails> build() {
    _loadArtists();
    return [];
  }

  Future<void> _loadArtists() async {
    final artists = await ArtistCache().getAll();

    // Remove duplicates by artist ID (preserve order)
    final uniqueArtists = <String, ArtistDetails>{};
    for (final artist in artists) {
      uniqueArtists[artist.id] = artist;
    }

    state = uniqueArtists.values.toList();
  }

  Future<void> refresh() async {
    await _loadArtists();
  }
}

// ----------------- ALBUM CACHE PROVIDER -------------------
@Riverpod(keepAlive: true)
class AllAlbums extends _$AllAlbums {
  StreamSubscription? _sub;

  @override
  List<Album> build() {
    // Listen to album cache changes
    _sub = AlbumCache.albumChanges.listen((_) {
      refresh();
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    _loadAlbums();
    return [];
  }

  Future<void> _loadAlbums() async {
    state = await AlbumCache().getAll();
  }

  Future<void> refresh() async {
    await _loadAlbums();
  }
}

// ---------------- FREQUENT ARTISTS PROVIDER ------------------
@Riverpod(keepAlive: true)
class FrequentArtists extends _$FrequentArtists {
  StreamSubscription? _sub;

  @override
  List<ArtistDetails> build() {
    // Listen to artist cache changes
    _sub = ArtistCache.artistChanges.listen((_) {
      refresh();
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    _loadFrequentArtists();
    return [];
  }

  Future<void> _loadFrequentArtists() async {
    final artists = await ArtistCache().getAll(sortByUsage: true);

    // Remove duplicates by ID while preserving order
    final uniqueArtists = <String, ArtistDetails>{};
    for (final artist in artists) {
      uniqueArtists[artist.id] = artist;
    }

    state = uniqueArtists.values.toList();
  }

  Future<void> refresh() async {
    await _loadFrequentArtists();
  }

  /// Promote an artist (increase usage)
  Future<void> promoteArtist(String artistId) async {
    final artist = await ArtistCache().get(artistId);
    if (artist == null) return;

    await ArtistCache().set(artistId, artist);
    await _loadFrequentArtists();
  }

  /// Remove an artist completely
  Future<void> removeArtist(String artistId) async {
    final allArtists = await ArtistCache().getAll();
    allArtists.removeWhere((a) => a.id == artistId);

    await ArtistCache().clear();
    for (final artist in allArtists) {
      await ArtistCache().set(artist.id, artist);
    }

    await _loadFrequentArtists();
  }
}

// ---------------- FREQUENT ALBUMS PROVIDER ------------------
@Riverpod(keepAlive: true)
class FrequentAlbums extends _$FrequentAlbums {
  StreamSubscription? _sub;

  @override
  List<Album> build() {
    // Listen to album cache changes
    _sub = AlbumCache.albumChanges.listen((_) {
      refresh();
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    _loadFrequentAlbums();
    return [];
  }

  Future<void> _loadFrequentAlbums() async {
    final albums = await AlbumCache().getAll(sortByUsage: true);

    // Filter out duplicates by ID while preserving order
    final uniqueAlbums = <String, Album>{};
    for (final album in albums) {
      uniqueAlbums[album.id] = album;
    }

    state = uniqueAlbums.values.toList();
  }

  Future<void> refresh() async {
    await _loadFrequentAlbums();
  }

  /// Promote an album (increase usage)
  Future<void> promoteAlbum(String albumId) async {
    final album = await AlbumCache().get(albumId);
    if (album == null) return;

    await AlbumCache().set(albumId, album);
    await _loadFrequentAlbums();
  }

  /// Remove an album completely
  Future<void> removeAlbum(String albumId) async {
    final allAlbums = await AlbumCache().getAll();
    allAlbums.removeWhere((a) => a.id == albumId);

    await AlbumCache().clear();
    for (final a in allAlbums) {
      await AlbumCache().set(a.id, a);
    }

    await _loadFrequentAlbums();
  }
}

// ---------------- FREQUENT PLAYLISTS PROVIDER ------------------
@Riverpod(keepAlive: true)
class FrequentPlaylists extends _$FrequentPlaylists {
  StreamSubscription? _sub;

  @override
  List<Playlist> build() {
    // Listen to cache changes
    _sub = PlaylistCache.playlistChanges.listen((_) {
      refresh();
    });

    ref.onDispose(() {
      _sub?.cancel();
    });

    // Initial load
    _loadFrequentPlaylists();

    return [];
  }

  Future<void> _loadFrequentPlaylists() async {
    final playlists = await PlaylistCache().getAll(sortByUsage: true);

    // Remove duplicates + invalid entries
    final uniquePlaylists = <String, Playlist>{};
    for (final playlist in playlists) {
      if (playlist.id.isNotEmpty && playlist.title.isNotEmpty) {
        uniquePlaylists[playlist.id] = playlist;
      }
    }

    state = uniquePlaylists.values.toList();
  }

  /// Public refresh
  Future<void> refresh() async {
    await _loadFrequentPlaylists();
  }

  /// Promote a playlist (increase usage)
  Future<void> promotePlaylist(String playlistId) async {
    final playlist = await PlaylistCache().get(playlistId);
    if (playlist == null) return;

    await PlaylistCache().set(playlistId, playlist);
    await _loadFrequentPlaylists();
  }

  /// Remove a playlist completely
  Future<void> removePlaylist(String playlistId) async {
    final playlist = await PlaylistCache().get(playlistId);
    if (playlist == null) return;

    final allPlaylists = await PlaylistCache().getAll();
    allPlaylists.removeWhere((p) => p.id == playlistId);

    await PlaylistCache().clear();
    for (final p in allPlaylists) {
      await PlaylistCache().set(p.id, p);
    }

    await _loadFrequentPlaylists();
  }
}
