import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'likedsong.g.dart';

@Riverpod(keepAlive: true)
class LikedSongs extends _$LikedSongs {
  @override
  List<String> build() {
    _loadLikes();
    return [];
  }

  Future<void> _loadLikes() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList('likedSongs') ?? [];
  }

  Future<void> _saveLikes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('likedSongs', state);
  }

  bool isLiked(String songId) => state.contains(songId);

  void like(String songId) {
    if (!state.contains(songId)) {
      state = [...state, songId];
      _saveLikes();
    }
  }

  void unlike(String songId) {
    state = state.where((id) => id != songId).toList();
    _saveLikes();
  }

  void toggle(String songId) {
    if (isLiked(songId)) {
      unlike(songId);
    } else {
      like(songId);
    }
  }
}
