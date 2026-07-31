// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AllSongs)
final allSongsProvider = AllSongsProvider._();

final class AllSongsProvider
    extends $NotifierProvider<AllSongs, List<SongDetail>> {
  AllSongsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allSongsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allSongsHash();

  @$internal
  @override
  AllSongs create() => AllSongs();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SongDetail> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SongDetail>>(value),
    );
  }
}

String _$allSongsHash() => r'f6623ca10ad984f75e9fb82e775669e53f7c49ee';

abstract class _$AllSongs extends $Notifier<List<SongDetail>> {
  List<SongDetail> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<SongDetail>, List<SongDetail>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<SongDetail>, List<SongDetail>>,
              List<SongDetail>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ArtistsWithUsage)
final artistsWithUsageProvider = ArtistsWithUsageProvider._();

final class ArtistsWithUsageProvider
    extends
        $NotifierProvider<
          ArtistsWithUsage,
          List<MapEntry<ArtistDetails, int>>
        > {
  ArtistsWithUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'artistsWithUsageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$artistsWithUsageHash();

  @$internal
  @override
  ArtistsWithUsage create() => ArtistsWithUsage();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<MapEntry<ArtistDetails, int>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<MapEntry<ArtistDetails, int>>>(
        value,
      ),
    );
  }
}

String _$artistsWithUsageHash() => r'43c9018026c960e44ddbcc6cc5a80d42d8637684';

abstract class _$ArtistsWithUsage
    extends $Notifier<List<MapEntry<ArtistDetails, int>>> {
  List<MapEntry<ArtistDetails, int>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              List<MapEntry<ArtistDetails, int>>,
              List<MapEntry<ArtistDetails, int>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<MapEntry<ArtistDetails, int>>,
                List<MapEntry<ArtistDetails, int>>
              >,
              List<MapEntry<ArtistDetails, int>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(Artists)
final artistsProvider = ArtistsProvider._();

final class ArtistsProvider
    extends $NotifierProvider<Artists, List<ArtistDetails>> {
  ArtistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'artistsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$artistsHash();

  @$internal
  @override
  Artists create() => Artists();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ArtistDetails> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ArtistDetails>>(value),
    );
  }
}

String _$artistsHash() => r'0830b54e71bdd65a818c729bf61fdde657c76db4';

abstract class _$Artists extends $Notifier<List<ArtistDetails>> {
  List<ArtistDetails> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ArtistDetails>, List<ArtistDetails>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ArtistDetails>, List<ArtistDetails>>,
              List<ArtistDetails>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(AllAlbums)
final allAlbumsProvider = AllAlbumsProvider._();

final class AllAlbumsProvider
    extends $NotifierProvider<AllAlbums, List<Album>> {
  AllAlbumsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allAlbumsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allAlbumsHash();

  @$internal
  @override
  AllAlbums create() => AllAlbums();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Album> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Album>>(value),
    );
  }
}

String _$allAlbumsHash() => r'e99819b4094041951a43a316d654ad27d681612b';

abstract class _$AllAlbums extends $Notifier<List<Album>> {
  List<Album> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Album>, List<Album>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Album>, List<Album>>,
              List<Album>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(FrequentArtists)
final frequentArtistsProvider = FrequentArtistsProvider._();

final class FrequentArtistsProvider
    extends $NotifierProvider<FrequentArtists, List<ArtistDetails>> {
  FrequentArtistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'frequentArtistsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$frequentArtistsHash();

  @$internal
  @override
  FrequentArtists create() => FrequentArtists();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ArtistDetails> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ArtistDetails>>(value),
    );
  }
}

String _$frequentArtistsHash() => r'31e128871ebcd80ee8eaacebc5745b2b5cf1e175';

abstract class _$FrequentArtists extends $Notifier<List<ArtistDetails>> {
  List<ArtistDetails> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ArtistDetails>, List<ArtistDetails>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ArtistDetails>, List<ArtistDetails>>,
              List<ArtistDetails>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(FrequentAlbums)
final frequentAlbumsProvider = FrequentAlbumsProvider._();

final class FrequentAlbumsProvider
    extends $NotifierProvider<FrequentAlbums, List<Album>> {
  FrequentAlbumsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'frequentAlbumsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$frequentAlbumsHash();

  @$internal
  @override
  FrequentAlbums create() => FrequentAlbums();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Album> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Album>>(value),
    );
  }
}

String _$frequentAlbumsHash() => r'e786c1e91f9a08185fe03af521bf93618185d99f';

abstract class _$FrequentAlbums extends $Notifier<List<Album>> {
  List<Album> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Album>, List<Album>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Album>, List<Album>>,
              List<Album>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(FrequentPlaylists)
final frequentPlaylistsProvider = FrequentPlaylistsProvider._();

final class FrequentPlaylistsProvider
    extends $NotifierProvider<FrequentPlaylists, List<Playlist>> {
  FrequentPlaylistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'frequentPlaylistsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$frequentPlaylistsHash();

  @$internal
  @override
  FrequentPlaylists create() => FrequentPlaylists();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Playlist> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Playlist>>(value),
    );
  }
}

String _$frequentPlaylistsHash() => r'b1a9139680d9d406670e4dafc9e027287bc8e627';

abstract class _$FrequentPlaylists extends $Notifier<List<Playlist>> {
  List<Playlist> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Playlist>, List<Playlist>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Playlist>, List<Playlist>>,
              List<Playlist>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
