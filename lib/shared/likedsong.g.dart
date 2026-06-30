// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'likedsong.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LikedSongs)
final likedSongsProvider = LikedSongsProvider._();

final class LikedSongsProvider
    extends $NotifierProvider<LikedSongs, List<String>> {
  LikedSongsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'likedSongsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$likedSongsHash();

  @$internal
  @override
  LikedSongs create() => LikedSongs();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$likedSongsHash() => r'd210cb72d225388fe272faf8e84d34821e9b99e4';

abstract class _$LikedSongs extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
