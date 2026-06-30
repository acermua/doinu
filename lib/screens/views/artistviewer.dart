import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_action_cell/core/cell.dart';

import 'package:just_audio/just_audio.dart';
import 'package:page_transition/page_transition.dart';
import 'package:readmore/readmore.dart';

import '../../components/shimmers.dart';
import '../../components/showmenu.dart';
import '../../components/snackbar.dart';
import '../../models/datamodel.dart';
import '../../services/audiohandler.dart';
import '../../shared/constants.dart';
import '../../shared/likedsong.dart';
import '../../utils/format.dart';
import '../../utils/theme.dart';
import '../../l10n/app_localizations.dart';
import 'albumviewer.dart';

class ArtistViewer extends ConsumerStatefulWidget {
  final String artistId;

  const ArtistViewer({super.key, required this.artistId});

  @override
  ConsumerState<ArtistViewer> createState() => _ArtistViewerState();
}

class _ArtistViewerState extends ConsumerState<ArtistViewer> {
  ArtistDetails? _artist;
  bool _loading = true;
  Color artistCoverColour = Colors.black;

  final ScrollController _scrollController = ScrollController();
  bool _isTitleCollapsed = false;

  @override
  void initState() {
    super.initState();
    _fetchArtist();
    _scrollController.addListener(() {
      bool isCollapsed =
          _scrollController.hasClients &&
          _scrollController.offset > (400 - kToolbarHeight - 20);

      if (isCollapsed != _isTitleCollapsed) {
        _isTitleCollapsed = isCollapsed;
        setState(() {});
      }
    });
  }

  Future<void> _updateBgColor() async {
    if (_artist == null || _artist!.images.isEmpty) return;

    final imageUrl = _artist!.images.last.url;
    if (imageUrl.isEmpty) return;

    final dominant = await getDominantColorFromImage(imageUrl);
    artistCoverColour = getDominantDarker(dominant);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchArtist() async {
    setState(() => _loading = true);
    final details = await sb.fetchArtistDetailsById(artistId: widget.artistId);

    if (mounted) {
      _artist = details;
      _loading = false;
      setState(() {});
    }
    if (!mounted) return;
    await _updateBgColor();
  }

  Widget _buildHeaderImage() {
    final imageUrl = _artist!.images.isNotEmpty ? _artist!.images.last.url : '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [artistCoverColour, AppTheme.bg],
        ),
      ),
      child: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: AspectRatio(
            aspectRatio: 1,
            child: CacheNetWorkImg(
              url: imageUrl.isNotEmpty ? imageUrl : '',
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isTitleCollapsed)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _artist!.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (_artist!.isVerified == true)
                  const Icon(
                    Icons.verified,
                    size: 18,
                    color: Colors.blueAccent,
                  ),
              ],
            ),
          const SizedBox(height: 4),
          if ((_artist?.followerCount ?? 0) > 0)
            Text(
              '${followersFormatter(_artist?.followerCount ?? 0)} ${AppLocalizations.of(context).followers}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          // if (_artist?.dominantType != null && _artist!.dominantType.isNotEmpty)
          //   Text(
          //     'Known as ${_artist?.dominantType}',
          //     style: const TextStyle(color: Colors.white70, fontSize: 13),
          //   ),
          if (_artist!.bio.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ReadMoreText(
                _artist!.bio.map((bio) => sanitizeBio(bio)).join("\n\n"),
                trimLines: 3,
                trimMode: TrimMode.Line,
                colorClickableText: AppTheme.accent,
                trimCollapsedText:
                    " ...${AppLocalizations.of(context).readMore}",
                trimExpandedText: " ${AppLocalizations.of(context).showLess}",
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSongList() {
    final songs = _artist?.topSongs ?? [];
    if (_loading) return buildAlbumShimmer();

    if (songs.isEmpty || _artist == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_buildShufflePlayButtons()],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).topSongs,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Text(
              //   'Famous for ${_artist?.dominantLanguage} Language',
              //   style: TextStyle(
              //     color: Colors.white30,
              //     fontSize: 13,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        ...songs.map((song) => ArtistSongRow(song: song, artist: _artist!)),
      ],
    );
  }

  Widget _buildShufflePlayButtons() {
    final isShuffle = ref.watch(shuffleProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Image.asset(
              'assets/icons/menu.png',
              width: 26,
              height: 26,
              color: Colors.grey[600],
            ),
            onPressed: () {
              if (_artist != null) showMediaItemMenu(context, _artist!);
            },
          ),

          // Shuffle button
          GestureDetector(
            onTap: () async {
              final handler = await ref.read(audioHandlerProvider.future);
              handler.toggleShuffle();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Image.asset(
                'assets/icons/shuffle.png',
                width: 24,
                height: 24,
                color: isShuffle ? AppTheme.accent : Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Play Artist / Top Songs / Shuffle
          StreamBuilder<PlayerState>(
            stream: ref
                .read(audioHandlerProvider.future)
                .asStream()
                .asyncExpand((h) => h.playerStateStream),
            builder: (context, snapshot) {
              final isPlaying = snapshot.data?.playing ?? false;
              final currentSong = ref.watch(currentSongProvider);

              return FutureBuilder(
                future: ref.read(audioHandlerProvider.future),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();
                  final audioHandler = snapshot.data!;

                  // ✅ Check if current queue matches artist's top songs
                  final bool isSameSource =
                      audioHandler.queueSourceId == _artist?.id;
                  final bool isCurrentInList =
                      isSameSource &&
                      currentSong != null &&
                      _artist!.topSongs.any((s) => s.id == currentSong.id);

                  // Icon logic
                  final icon = isCurrentInList
                      ? (isPlaying ? Icons.pause : Icons.play_arrow)
                      : Icons.play_arrow;

                  return GestureDetector(
                    onTap: () async {
                      try {
                        if (isSameSource) {
                          // 🔁 Current artist queue already loaded → toggle playback
                          if (isPlaying) {
                            await audioHandler.pause();
                          } else {
                            await audioHandler.play();
                          }
                        } else {
                          // 🚀 New artist queue → load top songs
                          int startIndex = 0;

                          // Shuffle handling
                          final isShuffle = ref.read(shuffleProvider);
                          if (isShuffle && _artist!.topSongs.isNotEmpty) {
                            startIndex =
                                DateTime.now().millisecondsSinceEpoch %
                                _artist!.topSongs.length;
                          }

                          await audioHandler.loadQueue(
                            _artist!.topSongs,
                            startIndex: startIndex,
                            sourceId: _artist?.id,
                            nature: 'artist',
                            sourceName: '${_artist?.title} Artist',
                          );

                          if (isShuffle && !audioHandler.isShuffle) {
                            audioHandler.toggleShuffle();
                          }

                          await audioHandler.play();
                        }
                      } catch (e, st) {
                        debugPrint(
                          "Error handling artist play button: $e\n$st",
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accent,
                      ),
                      child: Icon(icon, color: Colors.black, size: 30),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscographySection() {
    if (_loading) return buildAlbumShimmer();

    final List<Album> discography = [...(_artist?.topAlbums ?? [])];

    if (discography.isEmpty) return const SizedBox.shrink();

    // Deduplicate by ID
    final seenIds = <String>{};
    final uniqueDiscography = discography
        .where((a) => seenIds.add(a.id) && a.type.toLowerCase() == 'album')
        .toList();

    // Sort by year: newest to oldest
    uniqueDiscography.sort((a, b) {
      final yearA = int.tryParse(a.year) ?? 0;
      final yearB = int.tryParse(b.year) ?? 0;
      return yearB.compareTo(yearA);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            AppLocalizations.of(context).discography,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...uniqueDiscography.map((album) => DiscographyAlbumRow(album: album)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: artistCoverColour,
      body: Container(
        decoration: BoxDecoration(color: AppTheme.bg),
        child: _loading
            ? Padding(
                padding: const EdgeInsets.only(top: 60),
                child: buildAlbumShimmer(),
              )
            : _artist == null
            ? Center(
                child: Text(
                  AppLocalizations.of(context).failedToLoadArtist,
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    backgroundColor: artistCoverColour,
                    expandedHeight: 400,
                    elevation: 0,
                    leading: const BackButton(color: Colors.white),
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      centerTitle: false,
                      titlePadding: EdgeInsets.only(
                        left: _isTitleCollapsed ? 72 : 16,
                        bottom: 16,
                        right: 16,
                      ),
                      title: AnimatedOpacity(
                        opacity: _isTitleCollapsed ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _artist?.title ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      background: _buildHeaderImage(),
                    ),
                  ),

                  SliverToBoxAdapter(child: _buildHeaderDetails()),

                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        _buildSongList(),
                        const SizedBox(height: 20),
                        _buildDiscographySection(),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ArtistSongRow extends ConsumerWidget {
  final SongDetail song;
  final ArtistDetails artist;

  const ArtistSongRow({super.key, required this.song, required this.artist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = currentSong?.id == song.id;
    final isLiked = ref.watch(likedSongsProvider).contains(song.id);

    return SwipeActionCell(
      backgroundColor: Colors.transparent,
      key: ValueKey(song.id),
      fullSwipeFactor: 0.01,
      editModeOffset: 2,
      leadingActions: [
        SwipeAction(
          color: AppTheme.accent,
          icon: Image.asset('assets/icons/add_to_queue.png', height: 20),
          performsFirstActionWithFullSwipe: true,
          onTap: (handler) async {
            final audioHandler = await ref.read(audioHandlerProvider.future);
            await audioHandler.addSongNext(song);
            info('${song.title} will play next', Severity.success);
            await handler(false);
          },
        ),
      ],
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          try {
            final audioHandler = await ref.read(audioHandlerProvider.future);
            final queue = audioHandler.queue.valueOrNull ?? [];
            final queueIds = queue.map((m) => m.id).toList();

            final tappedIndex = artist.topSongs.indexWhere(
              (s) => s.id == song.id,
            );
            if (tappedIndex == -1) return;

            final currentSong = ref.read(currentSongProvider);
            final isPlaying = currentSong?.id == song.id;
            final isShuffle = audioHandler.isShuffle;

            // -------------------------------
            // 1️⃣ Tapped song is currently playing → toggle play/pause
            // -------------------------------
            if (isPlaying) {
              final playing =
                  (await audioHandler.playerStateStream.first).playing;
              if (playing) {
                await audioHandler.pause();
              } else {
                await audioHandler.play();
              }
              return;
            }

            // -------------------------------
            // 2️⃣ Queue already contains all artist top songs
            // -------------------------------
            final isSameQueue =
                queueIds.length == artist.topSongs.length &&
                queueIds.every((id) => artist.topSongs.any((s) => s.id == id));

            if (isSameQueue) {
              // Try to find tapped song after current song
              final currentIndex = queue.indexWhere(
                (m) => m.id == currentSong?.id,
              );

              int nextIndex = -1;
              if (currentIndex != -1 && currentIndex + 1 < queue.length) {
                final subQueue = queue.sublist(currentIndex + 1);
                final subIndex = subQueue.indexWhere((m) => m.id == song.id);
                if (subIndex != -1) nextIndex = currentIndex + 1 + subIndex;
              }

              // Fallback: search entire queue
              if (nextIndex == -1) {
                nextIndex = queue.indexWhere((m) => m.id == song.id);
              }

              if (nextIndex != -1) {
                await audioHandler.skipToQueueItem(nextIndex);
                await audioHandler.play();
                return;
              }
            }

            // -------------------------------
            // 3️⃣ Queue missing artist songs → load top songs
            // -------------------------------
            if (isShuffle) await audioHandler.disableShuffle();

            await audioHandler.loadQueue(
              artist.topSongs,
              startIndex: tappedIndex,
              sourceId: artist.id,
              nature: 'artist',
              sourceName: '${artist.title} Artist',
            );

            if (isShuffle) await audioHandler.toggleShuffle();

            await audioHandler.play();
          } catch (e, st) {
            debugPrint("Error playing artist song: $e\n$st");
          }
        },

        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            children: [
              CacheNetWorkImg(
                url: song.images.isNotEmpty ? song.images.last.url : '',
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isPlaying)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Image(
                              image: AssetImage('assets/icons/player.gif'),
                              height: 18,
                              fit: BoxFit.contain,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            song.title,
                            style: TextStyle(
                              color: isPlaying ? AppTheme.accent : Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      song.primaryArtists.isNotEmpty
                          ? song.primaryArtists
                          : song.album,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              if (isLiked)
                if (isLiked)
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Image.asset(
                      'assets/icons/tick.png',
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                      color: AppTheme.accent,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class AlbumRow extends StatelessWidget {
  final Album album;
  const AlbumRow({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final imageUrl = album.images.isNotEmpty ? album.images.last.url : '';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 300),
            child: AlbumViewer(albumId: album.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: CacheNetWorkImg(
              url: imageUrl,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              album.title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (album.artist.isNotEmpty)
            Flexible(
              child: Text(
                album.artist,
                style: TextStyle(color: Colors.white54, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }
}

class AlbumColumn extends StatelessWidget {
  final Album album;
  const AlbumColumn({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final imageUrl = album.images.isNotEmpty ? album.images.last.url : '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 300),
            child: AlbumViewer(albumId: album.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1:1 image
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CacheNetWorkImg(url: imageUrl, fit: BoxFit.cover),
            ),
          ),

          const SizedBox(height: 8),

          // Album title
          Text(
            album.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Artist
          if (album.artist.isNotEmpty)
            Text(
              album.artist,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class DiscographyAlbumRow extends StatelessWidget {
  final Album album;
  const DiscographyAlbumRow({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    final imageUrl = album.images.isNotEmpty ? album.images.last.url : '';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 300),
            child: AlbumViewer(albumId: album.id),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            CacheNetWorkImg(
              url: imageUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    album.year,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
