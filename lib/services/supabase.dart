import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/database.dart';
import '../models/datamodel.dart';
import '../shared/constants.dart';

part 'supabase.g.dart';

@riverpod
SupabaseApi supabase(Ref ref) {
  final client = Supabase.instance.client;
  return SupabaseApi(client);
}

class SupabaseApi {
  SupabaseApi(this.client);

  final SupabaseClient client;

  Future<List<SongDetail>> getSongDetails({
    List<String>? ids,
    String? link, // kept for API parity; not used in Supabase
  }) async {
    if ((ids == null || ids.isEmpty) && (link == null || link.isEmpty)) {
      debugPrint('getSongDetails: Either ids or link must be provided');
      return [];
    }

    final Map<String, SongDetail> resultMap = {};

    // ---------------- LOCAL CACHE FIRST ----------------
    if (ids != null && ids.isNotEmpty) {
      final cachedSongs = await AppDatabase.getSongs(ids);

      for (final song in cachedSongs) {
        if (song.downloadUrls.isEmpty) {
          debugPrint(
            "--- Cached song '${song.title}' has no download URLs, removing",
          );
          await AppDatabase.removeSong(song.id);
          continue;
        }
        resultMap[song.id] = song;
      }
    }

    // If all found locally, return
    if (ids != null && resultMap.length == ids.length) {
      return ids.map((id) => resultMap[id]!).toList();
    }

    // ---------------- FETCH MISSING FROM SUPABASE ----------------
    final missingIds = ids == null
        ? <String>[]
        : ids.where((id) => !resultMap.containsKey(id)).toList();

    if (missingIds.isEmpty) {
      return resultMap.values.toList();
    }

    try {
      final response = await client.rpc(
        'get_song_details',
        params: {'song_ids': missingIds.map((e) => int.parse(e)).toList()},
      );

      if (response == null || (response as List).isEmpty) {
        return resultMap.values.toList();
      }

      final fetched = response.map((row) {
        final payload = (row as Map<String, dynamic>)['data'];
        return SongDetail.fromJson(payload as Map<String, dynamic>);
      }).toList();

      // Cache locally
      for (final song in fetched) {
        await AppDatabase.saveSongDetail(song);
        resultMap[song.id] = song;
      }
    } catch (e, st) {
      debugPrint('❌ getSongDetails RPC failed: $e');
      debugPrint('$st');
    }

    return ids != null
        ? ids
              .where((id) => resultMap.containsKey(id))
              .map((id) => resultMap[id]!)
              .toList()
        : resultMap.values.toList();
  }

  final Map<String, String> headers = {
    "Accept": "application/json",
    "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36",
  };

  Future<List<DashboardSection>> getDashboardData() async {
    try {
      // Call RPC that returns the dashboard JSON
      final response = await client.rpc('get_dashboard');

      if (response == null || response is! List) return [];

      final List<DashboardSection> sections = response
          .whereType<Map<String, dynamic>>()
          .map((json) => DashboardSection.fromJson(json))
          .toList();

      // Sort by display_order just in case
      sections.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

      return sections;
    } catch (e, st) {
      debugPrint('❌ getDashboardData failed: $e');
      debugPrint('$st');
      return [];
    }
  }

  Future<ArtistDetails?> fetchArtistDetailsById({
    required String artistId,
    int page = 0,
    int songCount = 20,
    int albumCount = 20,
    String sortBy = 'popularity',
    String sortOrder = 'desc',
    bool forceFetch = false,
  }) async {
    final cache = ArtistCache();

    // ---------------- CACHE FIRST ----------------
    final cached = await cache.get(artistId);
    if (cached != null && !forceFetch && !cache.isExpired(artistId)) {
      debugPrint('fetchArtistDetailsById: loaded from cache ($artistId)');
      return cached;
    } else if (cached != null) {
      debugPrint(
        'fetchArtistDetailsById: cache expired, refetching ($artistId)',
      );
    }

    try {
      final response = await client.rpc(
        'get_artist_details',
        params: {
          'artist_id': int.parse(artistId),
          'song_limit': songCount,
          'album_limit': albumCount,
        },
      );

      if (response == null) return null;

      // RPC returns: List<{ data: {...} }>
      final raw = (response as List).first as Map<String, dynamic>;

      // Extract the actual artist payload
      final Map<String, dynamic> artistJson =
          raw['data'] as Map<String, dynamic>;

      final details = ArtistDetails.fromJson(artistJson);

      // ---------------- CACHE RESULT ----------------
      await cache.set(artistId, details);

      debugPrint(
        '🎤 fetchArtistDetailsById: fetched from Supabase ($artistId)',
      );

      return details;
    } catch (e, st) {
      debugPrint('❌ fetchArtistDetailsById RPC failed: $e');
      debugPrint('$st');
    }

    return null;
  }

  Future<Playlist?> fetchPlaylistById({
    String? playlistId,
    String? link,
    int page = 0,
    int limit = 50,
    ArtistSongsSortBy sortBy = ArtistSongsSortBy.popularity,
    SortOrder sortOrder = SortOrder.desc,
  }) async {
    if (playlistId == null && link == null) {
      debugPrint('❌ fetchPlaylistById: playlistId or link required');
      return null;
    }

    final cache = PlaylistCache();

    // ---------------- CACHE FIRST ----------------
    if (playlistId != null) {
      final cached = await cache.get(playlistId);
      if (cached != null && !cache.isExpired(playlistId)) {
        debugPrint('fetchPlaylistById: loaded from cache ($playlistId)');
        return cached;
      } else if (cached != null) {
        debugPrint(
          'fetchPlaylistById: cache expired, refetching ($playlistId)',
        );
      }
    }

    try {
      // Supabase RPC requires playlist_id
      if (playlistId == null) {
        debugPrint(
          '❌ fetchPlaylistById: link-based fetch not supported in Supabase RPC',
        );
        return null;
      }

      final response = await client.rpc(
        'get_playlist_details',
        params: {
          'playlist_id': int.parse(playlistId),
          'page': page,
          'limit_count': limit,
        },
      );

      if (response == null || (response as List).isEmpty) {
        return null;
      }
      final Map<String, dynamic> row = response.first as Map<String, dynamic>;

      final Map<String, dynamic> data = row['data'] as Map<String, dynamic>;

      final playlist = Playlist.fromJson(data);

      // ---------------- CACHE RESULT ----------------
      await cache.set(playlistId, playlist);

      debugPrint('fetchPlaylistById: fetched from Supabase ($playlistId)');

      return playlist;
    } catch (e, st) {
      debugPrint('❌ fetchPlaylistById RPC failed: $e');
      debugPrint('$st');
    }

    return null;
  }

  Future<Album?> fetchAlbumById({
    String? albumId,
    String? link,
    int page = 0,
    int limit = 50,
    bool forceFetch = false,
  }) async {
    if (albumId == null && link == null) {
      debugPrint('❌ fetchAlbumById: albumId or link required');
      return null;
    }

    final cache = AlbumCache();

    // Use albumId as cache key if available, else fallback to link
    final cacheKey = albumId ?? link!;

    // ---------------- CACHE FIRST with TTL ----------------
    final cached = await cache.get(cacheKey);
    if (cached != null && !forceFetch && !cache.isExpired(cacheKey)) {
      debugPrint('fetchAlbumById: loaded from cache ($cacheKey)');
      return cached;
    } else if (cached != null && cache.isExpired(cacheKey)) {
      debugPrint('fetchAlbumById: cache expired, refetching ($cacheKey)');
    }

    try {
      // Supabase RPC requires album_id
      if (albumId == null) {
        debugPrint(
          '❌ fetchAlbumById: link-based fetch not supported in Supabase RPC',
        );
        return null;
      }

      final response = await client.rpc(
        'get_album_details',
        params: {
          'album_id': int.parse(albumId),
          'page': page,
          'limit_count': limit,
        },
      );
      if (response == null || response is! Map<String, dynamic>) return null;

      final album = Album.fromJson(response);

      // ---------------- CACHE RESULT ----------------
      await cache.set(cacheKey, album);

      debugPrint('📀 fetchAlbumById: fetched from Supabase ($cacheKey)');

      return album;
    } catch (e, st) {
      debugPrint('❌ fetchAlbumById RPC failed: $e');
      debugPrint('$st');
    }

    return null;
  }

  Future<List<String>> getSearchBoxSuggestions({required String query}) async {
    final q = query.trim().toLowerCase();

    if (q.isEmpty) return _getRandomSuggestions(allSuggestions, count: 5);

    final scored = <_ScoredItem>[];

    for (final original in allSuggestions) {
      final s = original.trim();
      if (s.isEmpty) continue;
      final lower = s.toLowerCase();
      int score = 0;

      if (lower == q)                                    score += 1000;
      if (lower.startsWith(q))                           score += 500;
      if (lower.split(' ').any((w) => w.startsWith(q))) score += 300;
      if (lower.contains(q))                             score += 100;
      score -= lower.length ~/ 5;

      if (score > 0) scored.add(_ScoredItem(s, score));
    }

    // Live fetch only when local has nothing
    if (scored.isEmpty) {
      try {
        final response = await client.rpc(
          'search_suggestions_live',
          params: {'query_text': q, 'limit_count': 10},
        );
        if (response != null && response is List) {
          return response.map((e) => e.toString()).toList();
        }
      } catch (e) {
        debugPrint('❌ search_suggestions_live failed: $e');
      }
      return [];
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    final seen = <String>{};
    final out = <String>[];
    for (final item in scored) {
      if (seen.add(item.value.toLowerCase().trim()) && out.length < 5) {
        out.add(item.value);
      }
    }
    return out;
  }

  List<String> _getRandomSuggestions(List<String> list, {int count = 5}) {
    final copy = List<String>.from(list);
    copy.shuffle();
    return copy.take(count).toList();
  }

  Future<List<SongDetail>> searchSongs({
    required String query,
    int page = 0,
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) return [];

    final offset = page * limit;

    try {
      final response = await client.rpc(
        'search_songs',
        params: {'query': query, 'limit_count': limit, 'offset_count': offset},
      );

      if (response == null) return [];

      final List<dynamic> rows = response as List<dynamic>;

      return rows
          .map((e) => SongDetail.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, st) {
      debugPrint('❌ Supabase searchSongs failed: $e');
      debugPrint('$st');
      return [];
    }
  }

  Future<SearchPlaylistsResponse?> searchPlaylists({
    required String query,
    int page = 0,
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return null;

    final offset = page * limit;

    try {
      final response = await client.rpc(
        'search_playlists',
        params: {'query': query, 'limit_count': limit, 'offset_count': offset},
      );

      if (response == null) return null;

      final List<dynamic> rows = response as List<dynamic>;

      return SearchPlaylistsResponse.fromJson({
        'success': true,
        'data': {
          'results': rows,
          'total': rows.length, // matches your current usage
        },
      });
    } catch (e, st) {
      debugPrint('❌ Supabase searchPlaylists failed: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<SearchArtistsResponse?> searchArtists({
    required String query,
    int page = 0,
    int limit = 10,
  }) async {
    if (query.trim().isEmpty) return null;

    final offset = page * limit;

    try {
      final response = await client.rpc(
        'search_artists',
        params: {'query': query, 'limit_count': limit, 'offset_count': offset},
      );

      if (response == null) return null;

      final List<dynamic> rows = response as List<dynamic>;

      return SearchArtistsResponse.fromJson({
        'success': true,
        'data': {
          'results': rows,
          'total': rows.length, // consistent with your current API
        },
      });
    } catch (e, st) {
      debugPrint('❌ Supabase searchArtists failed: $e');
      debugPrint('$st');
      return null;
    }
  }

  Future<GlobalSearch?> globalSearch(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.isEmpty) return null;

    try {
      final response = await client.rpc(
        'global_search',
        params: {'query': query, 'limit_count': limit, 'offset_count': offset},
      );

      if (response == null || (response as List).isEmpty) {
        return GlobalSearch.empty();
      }

      final List<Map<String, dynamic>> rows = (response)
          .cast<Map<String, dynamic>>();

      // Split by type → exactly how Saavn response behaved
      final songs = <Map<String, dynamic>>[];
      final artists = <Map<String, dynamic>>[];
      final albums = <Map<String, dynamic>>[];
      final playlists = <Map<String, dynamic>>[];

      for (final row in rows) {
        switch (row['type']) {
          case 'song':
            songs.add(row);
            break;
          case 'artist':
            artists.add(row);
            break;
          case 'album':
            albums.add(row);
            break;
          case 'playlist':
            playlists.add(row);
            break;
        }
      }
      final json = {
        'songs': {'results': songs, 'total': songs.length},
        'albums': {'results': albums, 'total': albums.length},
        'artists': {'results': artists, 'total': artists.length},
        'playlists': {'results': playlists, 'total': playlists.length},
      };

      return GlobalSearch.fromJson(json);
    } catch (e, st) {
      debugPrint('❌ globalSearch RPC failed: $e');
      debugPrint('$st');
      return null;
    }
  }

  /// Fetches search suggestion strings
  Future<List<String>> getSearchSuggestions({
    int limit = 1500,
    bool forceFetch = false,
  }) async {
    const cacheKey = 'search_suggestions_cache';
    const lastFetchKey = 'search_suggestions_last_fetch';
    const cacheDuration = Duration(hours: 6);

    final prefs = await SharedPreferences.getInstance();

    try {
      final now = DateTime.now();
      final lastFetchMillis = prefs.getInt(lastFetchKey);

      // ---------- USE CACHE ----------
      if (!forceFetch && lastFetchMillis != null) {
        final lastFetch = DateTime.fromMillisecondsSinceEpoch(lastFetchMillis);

        if (now.difference(lastFetch) < cacheDuration) {
          final cachedJson = prefs.getString(cacheKey);
          if (cachedJson != null) {
            final List decoded = jsonDecode(cachedJson);
            return decoded.map((e) => e.toString()).toList();
          }
        }
      }

      // ---------- FETCH FROM SUPABASE ----------
      final response = await client.rpc(
        'get_search_suggestions',
        params: {'limit_count': limit},
      );

      if (response == null || response is! List) {
        throw Exception('Invalid RPC response');
      }

      final suggestions = response.map((e) => e.toString()).toList();

      // ---------- SAVE CACHE ----------
      await prefs.setString(cacheKey, jsonEncode(suggestions));
      await prefs.setInt(lastFetchKey, now.millisecondsSinceEpoch);

      return suggestions;
    } catch (e, st) {
      debugPrint('❌ getSearchSuggestions failed: $e');
      debugPrint('$st');

      // ---------- FALLBACK TO CACHE ----------
      final cachedJson = prefs.getString(cacheKey);
      if (cachedJson != null) {
        final List decoded = jsonDecode(cachedJson);
        return decoded.map((e) => e.toString()).toList();
      }

      return [];
    }
  }

  //default fetcher
  Future<List<Playlist>> getRecentPlaylists({int limit = 20}) async {
    try {
      final response = await client.rpc(
        'get_recent_playlists',
        params: {'limit_count': limit},
      );

      if (response == null) return [];

      final List data = response is List
          ? response
          : (response as List<dynamic>? ?? []);

      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => Playlist.fromJson(e))
          .toList();
    } catch (e, st) {
      debugPrint('❌ getRecentPlaylists failed: $e');
      debugPrint('$st');
      return [];
    }
  }

  Future<List<Artist>> getRecentArtists({int limit = 20}) async {
    try {
      final response = await client.rpc(
        'get_recent_artists',
        params: {'limit_count': limit},
      );

      if (response == null) return [];

      final List data = response is List
          ? response
          : (response as List<dynamic>? ?? []);

      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => Artist.fromJson(e))
          .toList();
    } catch (e, st) {
      debugPrint('❌ getRecentArtists failed: $e');
      debugPrint('$st');
      return [];
    }
  }

  Future<List<Album>> getRecentAlbums({int limit = 20}) async {
    try {
      final response = await client.rpc(
        'get_recent_albums',
        params: {'limit_count': limit},
      );

      if (response == null) return [];

      final List data = response is List
          ? response
          : (response as List<dynamic>? ?? []);

      return data
          .whereType<Map<String, dynamic>>()
          .map((e) => Album.fromJson(e))
          .toList();
    } catch (e, st) {
      debugPrint('❌ getRecentAlbums failed: $e');
      debugPrint('$st');
      return [];
    }
  }
}

// enum types
enum ArtistSongsSortBy { popularity, latest, alphabetical }

extension ArtistSongsSortByExt on ArtistSongsSortBy {
  String get value {
    switch (this) {
      case ArtistSongsSortBy.popularity:
        return "popularity";
      case ArtistSongsSortBy.latest:
        return "latest";
      case ArtistSongsSortBy.alphabetical:
        return "alphabetical";
    }
  }
}

enum SortOrder { asc, desc }

extension SortOrderExt on SortOrder {
  String get value => this == SortOrder.asc ? "asc" : "desc";
}

int getTotalDuration(List<SongDetail> songs) {
  return songs.fold<int>(0, (sum, song) {
    final dur = (song.duration is int)
        ? song.duration as int
        : int.tryParse(song.duration.toString()) ?? 0;
    return sum + dur;
  });
}

class _ScoredItem {
  final String value;
  final int score;

  _ScoredItem(this.value, this.score);
}

