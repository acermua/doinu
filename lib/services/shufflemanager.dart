// lib\services\shufflemanager.dart

import 'dart:math';
import '../models/datamodel.dart';

class ShuffleManager {
  List<SongDetail> _originalQueue = [];
  List<SongDetail> _shuffledQueue = [];

  bool _isShuffling = false;
  bool _isShuffleChanging = false;
  int _currentIndex = -1;

  /// Keeps a lightweight playback history so recently played songs appear later in shuffle.
  final List<String> _recentlyPlayed = [];
  final int _historyLimit = 10;

  // --- Public getters
  bool get isShuffling => _isShuffling;
  bool get isShuffleChanging => _isShuffleChanging;
  List<SongDetail> get currentQueue =>
      _isShuffling ? _shuffledQueue : _originalQueue;
  int get currentIndex => _currentIndex;
  List<SongDetail> get originalQueue => List.unmodifiable(_originalQueue);
  SongDetail? get currentSong =>
      (currentQueue.isEmpty ||
          _currentIndex < 0 ||
          _currentIndex >= currentQueue.length)
      ? null
      : currentQueue[_currentIndex];

  /// Initialize with a queue and current index.
  /// Clears play history on queue replacement to prevent stale bias (GREY SPOT 4).
  void loadQueue(
    List<SongDetail> queue, {
    int currentIndex = 0,
    bool clearHistory = true,
  }) {
    _originalQueue = List.from(queue);
    _currentIndex = queue.isEmpty
        ? -1
        : currentIndex.clamp(0, queue.length - 1);

    if (clearHistory) {
      _recentlyPlayed.clear();
    }

    if (_isShuffling) _applyShuffle(currentSong: currentSong);
  }

  /// Toggle shuffle mode (safe re-entry guarded by [_isShuffleChanging]).
  void toggleShuffle({SongDetail? currentSong}) {
    if (_isShuffleChanging) return;
    _isShuffleChanging = true;

    try {
      final current = currentSong ?? this.currentSong;

      if (current == null) {
        // No current song - don't shuffle, let AudioHandler decide playback
        return;
      }

      if (_isShuffling) {
        // Disable shuffle
        _isShuffling = false;
        _shuffledQueue.clear();

        final idx = _originalQueue.indexWhere((s) => s.id == current.id);
        _currentIndex = idx >= 0
            ? idx
            : _currentIndex.clamp(0, _originalQueue.length - 1);
      } else {
        // Enable shuffle
        _isShuffling = true;
        _applyShuffle(currentSong: current);
      }
    } finally {
      // Always release lock, even if exception
      _isShuffleChanging = false;
    }
  }

  /// Weighted shuffle ensuring the current song starts first.
  void _applyShuffle({SongDetail? currentSong}) {
    if (_originalQueue.isEmpty) return;

    final rng = Random();

    // Safe fallback - only use _originalQueue.first as last resort
    final current =
        currentSong ??
        (_currentIndex >= 0 && _currentIndex < _originalQueue.length
            ? _originalQueue[_currentIndex]
            : _originalQueue.first);

    final candidates = List<SongDetail>.from(_originalQueue)
      ..removeWhere((s) => s.id == current.id);

    final filtered = candidates
        .where((s) => !_recentlyPlayed.contains(s.id))
        .toList();
    if (filtered.isEmpty) filtered.addAll(candidates);

    filtered.shuffle(rng);

    _shuffledQueue = [current, ...filtered];
    _currentIndex = 0; // Current song is at index 0
  }

  /// Get the next index considering shuffle mode (READ-ONLY).
  /// Returns null if queue is empty OR currentIndex is invalid (GREY SPOT 1).
  /// AudioHandler MUST handle null gracefully.
  int? getNextIndex() {
    if (currentQueue.isEmpty || _currentIndex < 0) return null;
    final next = _currentIndex + 1;
    if (next >= currentQueue.length) return null;
    return next;
  }

  /// Get the previous index considering shuffle mode (READ-ONLY).
  /// Returns null if queue is empty OR currentIndex is invalid (GREY SPOT 1).
  /// AudioHandler MUST handle null gracefully.
  int? getPreviousIndex() {
    if (currentQueue.isEmpty || _currentIndex < 0) return null;
    final prev = _currentIndex - 1;
    if (prev < 0) return null;
    return prev;
  }

  /// Register a song as recently played (for weighted shuffle bias).
  /// CRITICAL: AudioHandler MUST call this after every successful play start (GREY SPOT 2).
  void registerPlay(SongDetail song) {
    _recentlyPlayed.remove(song.id);
    _recentlyPlayed.insert(0, song.id);
    if (_recentlyPlayed.length > _historyLimit) {
      _recentlyPlayed.removeLast();
    }
  }

  /// Reset play history (call when switching playlists/sources).
  /// Prevents stale bias from affecting new queue (GREY SPOT 4).
  void resetHistory() {
    _recentlyPlayed.clear();
  }

  // --- Queue modification helpers

  /// Add a song while maintaining current shuffle mode.
  void addSong(SongDetail song) {
    if (_originalQueue.any((s) => s.id == song.id)) return;

    _originalQueue.add(song);

    if (_isShuffling) {
      final insertPos = _shuffledQueue.length > 1
          ? Random().nextInt(_shuffledQueue.length - 1) + 1
          : 1;
      _shuffledQueue.insert(insertPos.clamp(0, _shuffledQueue.length), song);
    }
  }

  /// Remove a song from both queues safely.
  /// If removing current song, AudioHandler MUST handle playback transition (GREY SPOT 6).
  void removeSong(String songId) {
    final wasCurrentSong = currentSong?.id == songId;

    _originalQueue.removeWhere((s) => s.id == songId);
    _shuffledQueue.removeWhere((s) => s.id == songId);

    if (_currentIndex >= currentQueue.length) {
      _currentIndex = currentQueue.isEmpty ? -1 : currentQueue.length - 1;
    }

    // Signal to caller that current song was removed
    if (wasCurrentSong && currentQueue.isNotEmpty) {
      // Index now points to next song - caller should handle transition
      _currentIndex = _currentIndex.clamp(0, currentQueue.length - 1);
    }
  }

  /// Reorder a song in the queue safely.
  void reorder(int oldIndex, int newIndex) {
    oldIndex = oldIndex.clamp(0, currentQueue.length - 1);
    newIndex = newIndex.clamp(0, currentQueue.length - 1);
    if (oldIndex == newIndex) return;

    if (_isShuffling) {
      final movedSong = _shuffledQueue.removeAt(oldIndex);
      _shuffledQueue.insert(newIndex, movedSong);

      if (oldIndex == _currentIndex) {
        _currentIndex = newIndex;
      } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
        _currentIndex--;
      } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
        _currentIndex++;
      }
    } else {
      final movedSong = _originalQueue.removeAt(oldIndex);
      _originalQueue.insert(newIndex, movedSong);

      if (oldIndex == _currentIndex) {
        _currentIndex = newIndex;
      } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
        _currentIndex--;
      } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
        _currentIndex++;
      }
    }
  }

  /// Force update the current index.
  void updateCurrentIndex(int index) {
    if (index >= 0 && index < currentQueue.length) {
      _currentIndex = index;
    }
  }

  /// Insert a song at a specific index.
  void insertSong(int index, SongDetail song) {
    if (_isShuffling) {
      _shuffledQueue.insert(index.clamp(0, _shuffledQueue.length), song);
      if (!_originalQueue.any((s) => s.id == song.id)) {
        _originalQueue.add(song);
      }
      if (index <= _currentIndex) {
        _currentIndex++;
      }

      // OPTIONAL Mark inserted song as "recent" until first play
      // This prevents it from appearing immediately in weighted shuffle
      _recentlyPlayed.insert(0, song.id);
    } else {
      _originalQueue.insert(index.clamp(0, _originalQueue.length), song);
      if (index <= _currentIndex) {
        _currentIndex++;
      }
    }
  }
  /// Update a specific song's metadata in the queue (e.g. after fetching URLs).
  void updateSongInQueue(SongDetail song) {
    final origIdx = _originalQueue.indexWhere((s) => s.id == song.id);
    if (origIdx != -1) {
      _originalQueue[origIdx] = song;
    }

    final shuffleIdx = _shuffledQueue.indexWhere((s) => s.id == song.id);
    if (shuffleIdx != -1) {
      _shuffledQueue[shuffleIdx] = song;
    }
  }
}
