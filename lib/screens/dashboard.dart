import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../components/generalcards.dart';
import '../components/shimmers.dart';
import '../l10n/app_localizations.dart';
import '../services/defaultfetcher.dart';
import '../models/database.dart';
import '../models/datamodel.dart';
import '../services/supabase.dart';
import '../services/offlinemanager.dart';
import '../services/dailyfetcher.dart';

import '../services/localnotification.dart';
import '../services/systemconfig.dart';
import '../shared/constants.dart';
import '../utils/theme.dart';
import 'features/profile.dart';
import 'views/albumviewer.dart';
import 'views/artistviewer.dart';
import 'views/playlistviewer.dart';
import 'views/songsviewer.dart';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  bool loading = true;
  List<Playlist> playlists = [];
  List<Playlist> freqplaylists = [];
  List<ArtistDetails> artists = [];
  List<Album> albums = [];
  List<Playlist> freqRecentPlaylists = [];

  // cached shuffled lists
  bool _showWaitingCard = true;
  bool _showUpdateAvailable = true;
  List<DashboardSection> _dashboardSection = [];

  @override
  void initState() {
    super.initState();
    _initInternetChecker();
    _init();
  }

  bool _isInitRunning = false;
  Future<void> _init() async {
    if (_isInitRunning) {
      debugPrint('[_init] Already running. Abort.');
      return;
    }

    _isInitRunning = true;

    if (!mounted) {
      debugPrint('[_init] Widget not mounted. Abort.');
      _isInitRunning = false;
      return;
    }

    setState(() => loading = true);

    try {
      sb = await ref.read(supabaseProvider);

      final results = await Future.wait([
        DailyFetches.getPlaylistsFromCache(), // [0]
        DailyFetches.getArtistsAsListFromCache(), // [1]
        DashboardDailyFetcher.getDashboard(), // [2]
      ]);

      playlists = results[0] as List<Playlist>;
      artists = results[1] as List<ArtistDetails>;
      _dashboardSection = results[2] as List<DashboardSection>;

      freqplaylists = ref.read(frequentPlaylistsProvider).take(10).toList();

      albums = ref.read(frequentAlbumsProvider).take(10).toList();

      await CacheRecentDB.initAll();

      await mergeCachedData();

      final frequentArtists = ref
          .read(frequentArtistsProvider)
          .take(5)
          .toList();

      final existingIds = artists.map((a) => a.id.toString()).toSet();

      for (final artist in frequentArtists.reversed) {
        if (!existingIds.contains(artist.id.toString())) {
          artists.insert(0, artist);
        }
      }

      _buildFreqRecent();

      if (mounted) {
        setState(() => loading = false);
      }

      // Run heavy work AFTER first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runBackgroundTasks();
      });
    } catch (e, st) {
      debugPrint('[_init] ERROR: $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _isInitRunning = false;
    }
  }

  Future<void> _runBackgroundTasks() async {
    debugPrint('[BG] Background tasks started');

    try {
      await Future.wait([
        DailyFetches.refreshAllDaily(),
        offlineManager.init(),
        AppDatabase.getMonthlyListeningHours(),
      ]);

      await Future.delayed(const Duration(seconds: 3));

      final status = await Permission.notification.status;
      if (!status.isGranted && !status.isProvisional) {
        if (mounted) _showPermissionBottomSheet();
      }

      await checkForUpdate();

      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint('[BG] ERROR: $e');
      debugPrintStack(stackTrace: st);
    }

    debugPrint('[BG] Background tasks finished');
  }

  Future<void> mergeCachedData() async {
    // ---------------- ARTISTS ----------------
    final existingArtistIds = artists.map((a) => a.id.toString()).toSet();

    final missingArtistIds = CacheRecentDB.artists.all
        .map((entry) => entry.key)
        .where((id) => !existingArtistIds.contains(id));

    final fetchedArtists = await Future.wait(
      missingArtistIds.map((id) => sb.fetchArtistDetailsById(artistId: id)),
    );

    artists.addAll(fetchedArtists.whereType<ArtistDetails>());

    // ---------------- PLAYLISTS ----------------
    final existingPlaylistIds = playlists.map((p) => p.id.toString()).toSet();

    final missingPlaylistIds = CacheRecentDB.playlists.all
        .map((entry) => entry.key)
        .where((id) => !existingPlaylistIds.contains(id));

    final fetchedPlaylists = await Future.wait(
      missingPlaylistIds.map((id) => sb.fetchPlaylistById(playlistId: id)),
    );

    playlists.addAll(fetchedPlaylists.whereType<Playlist>());

    // ---------------- ALBUMS ----------------
    final existingAlbumIds = albums.map((a) => a.id.toString()).toSet();

    final missingAlbumIds = CacheRecentDB.albums.all
        .map((entry) => entry.key)
        .where((id) => !existingAlbumIds.contains(id));

    final fetchedAlbums = await Future.wait(
      missingAlbumIds.map((id) => sb.fetchAlbumById(albumId: id)),
    );

    albums.addAll(fetchedAlbums.whereType<Album>());
  }

  void _buildFreqRecent() {
    const int minItems = 7;
    const int maxItems = 10;

    final List<Playlist> temp = [];
    final Set<String> existingIds = {};

    void addIfValid(Playlist p) {
      if (p.id.isEmpty ||
          p.title.isEmpty ||
          p.images.isEmpty ||
          existingIds.contains(p.id)) {
        return;
      }

      temp.add(p);
      existingIds.add(p.id);
    }

    // Frequent playlists (max 3)
    for (final p in freqplaylists.take(3)) {
      addIfValid(p);
    }

    // Frequent albums (max 3)
    for (final album in albums.take(3)) {
      addIfValid(album.toPlaylist());
    }

    // Dashboard fallback
    for (final section in _dashboardSection) {
      for (final p in section.playlists) {
        if (temp.length >= maxItems) break;
        addIfValid(p);
      }
    }

    // Hard minimum guarantee
    if (temp.length < minItems) {
      final fallbackPool = [...playlists, ...albums.map((a) => a.toPlaylist())];

      for (final p in fallbackPool) {
        if (temp.length >= minItems) break;
        addIfValid(p);
      }
    }

    freqRecentPlaylists = temp.take(maxItems).toList();

    if (freqRecentPlaylists.length.isEven &&
        freqRecentPlaylists.length > minItems) {
      freqRecentPlaylists.removeLast();
    }
  }

  Future<void> _initInternetChecker() async {
    InternetConnection().onStatusChange.listen((status) {
      if (status == InternetStatus.disconnected) {
        hasInternet.value = false;
      } else {
        hasInternet.value = true;
      }
      if (mounted) setState(() {});
    });
  }

  List<Widget> _buildDashboardSections() {
    return _dashboardSection.map((section) {
      switch (section.contentType) {
        case 'album':
          return _sectionAlbumList(section.title, section.albums);

        case 'playlist':
          return _sectionList(section.title, section.playlists);

        default:
          return const SizedBox.shrink();
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // ref.listen<List<Playlist>>(frequentPlaylistsProvider, (_, next) {
    //   freqplaylists = next.take(10).toList();
    //   _buildFreqRecent();
    //   if (mounted) setState(() {});
    // });

    // ref.listen<List<Album>>(frequentAlbumsProvider, (_, next) {
    //   albums = next.take(10).toList();
    //   _buildFreqRecent();
    //   if (mounted) setState(() {});
    // });

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        title: _buildHeader(),
      ),
      body: loading
          ? ListView(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              children: [
                if (_showWaitingCard)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: GeneralCards(
                        onClose: () {
                          _showWaitingCard = false;
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                heroGridShimmer(),
                const SizedBox(height: 16),
                buildPlaylistSectionShimmer(),
                const SizedBox(height: 16),
                buildPlaylistSectionShimmer(),
                const SizedBox(height: 70),
              ],
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionGrid(freqRecentPlaylists),
                  const SizedBox(height: 20),
                  if (isAppUpdateAvailable && _showUpdateAvailable)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: GeneralCards(
                          iconPath: 'assets/icons/alert.png',
                          title: AppLocalizations.of(context).updateAvailable,
                          content: AppLocalizations.of(context).updateContent,
                          downloadUrl:
                              'https://play.google.com/store/apps/details?id=com.hiveminds.doinu',
                          onClose: () {
                            _showUpdateAvailable = false;
                            setState(() {});
                          },
                        ),
                      ),
                    ),

                  ..._buildDashboardSections(),
                  _sectionArtistList(AppLocalizations.of(context).favArtists, artists),
                  _sectionAlbumList(AppLocalizations.of(context).recentAlbums, albums),
                  _sectionList(AppLocalizations.of(context).yourFavorites, playlists),

                  const SizedBox(height: 60),
                  makeItHappenCard(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  void _showPermissionBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bg,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/icons/bell.png',
                  width: 32,
                  height: 32,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).enrichExperience,
                style: AppTheme.text.h3.copyWith(letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                AppLocalizations.of(context).notificationPermissionDialog,
                textAlign: TextAlign.center,
                style: AppTheme.text.bodyMuted.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.white60,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    requestNotificationPermission();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context).gotIt,
                    style: AppTheme.text.label.copyWith(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return ValueListenableBuilder(
      valueListenable: profileRefreshNotifier,
      builder: (context, value, child) {
        return Row(
          children: [
            GestureDetector(
              onTap: () => scaffoldKey.currentState?.openDrawer(),
              behavior: HitTestBehavior.opaque,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.bg,
                backgroundImage:
                    (profileFile != null && profileFile!.existsSync())
                    ? FileImage(profileFile!)
                    : const AssetImage('assets/icons/doinu.png')
                          as ImageProvider,
              ),
            ),
            const SizedBox(width: 15),
            const Text(
              'Doinu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            // const Spacer(),
            // // Notifications / icons can go here
            // const SizedBox(width: 10),
          ],
        );
      },
    );
  }

  Widget _sectionGrid(List<Playlist> playlists) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (playlists.isEmpty) return const SizedBox.shrink();

    final combined = [
      Playlist(
        id: 'liked',
        title: AppLocalizations.of(context).likedSongs,
        type: 'custom',
        url: '',
        images: [],
      ),
      // Playlist(
      //   id: 'all',
      //   title: 'All Songs',
      //   type: 'custom',
      //   url: '',
      //   images: [],
      // ),
      ...playlists,
    ];

    // Only take first 10 for the grid
    final displayList = combined.take(12).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayList.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: MediaQuery.of(context).size.width > 600
                  ? 4.5
                  : 3.5,
            ),
            itemBuilder: (context, index) {
              final playlist = displayList[index];
              return _gridCard(playlist);
            },
          ),
        ],
      ),
    );
  }

  Widget _gridCard(Playlist p) {
    final isSpecial = p.id == 'liked' || p.id == 'all';
    final isAlbum = p.type == 'album';
    final img = p.images.isNotEmpty ? p.images.first.url : '';
    final subtitle = (p.artists.isNotEmpty
        ? p.artists.first.title
        : p.description.isNotEmpty
        ? p.description
        : (p.songCount != null ? '${p.songCount} ${AppLocalizations.of(context).songs}' : ''));

    return GestureDetector(
      onTap: () {
        if (p.id == 'liked') {
          Navigator.of(context).push(
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
              child: SongsViewer(showLikedSongs: true),
            ),
          );
        } else if (isAlbum) {
          Navigator.of(context).push(
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
              child: AlbumViewer(albumId: p.id),
            ),
          );
        } else {
          Navigator.of(context).push(
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
              child: PlaylistViewer(playlistId: p.id),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            // BoxShadow(
            //   color: Colors.black.withAlpha(70),
            //   blurRadius: 1,
            //   offset: const Offset(0, 2),
            // ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
              child: isSpecial
                  ? Container(
                      height: double.infinity,
                      width: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: p.id == 'liked'
                              ? [Colors.purpleAccent, Colors.deepPurple]
                              : [AppTheme.accent, Colors.teal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        p.id == 'liked' ? Icons.favorite : Icons.library_music,
                        color: Colors.white,
                      ),
                    )
                  : (img.isNotEmpty
                        ? CacheNetWorkImg(
                            url: img,
                            width: 50,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 60,
                            color: Colors.grey[800],
                            child: const Icon(Icons.album, color: Colors.white),
                          )),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 5),
          ],
        ),
      ),
    );
  }

  // ---------- LIST SECTION (refined)
  Widget _sectionList(String title, List<Playlist> list) {
    if (loading) return buildPlaylistSectionShimmer();
    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: PageController(
                viewportFraction: MediaQuery.of(context).size.width > 600
                    ? 0.25
                    : 0.45,
              ),
              padEnds: false,
              physics: const BouncingScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final playlist = list[index];
                return Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: _playlistCard(playlist),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _playlistCard(Playlist playlist) {
    final imageUrl = playlist.images.isNotEmpty
        ? playlist.images.first.url
        : '';
    final subtitle = playlist.artists.isNotEmpty
        ? playlist.artists.first.title
        : (playlist.songCount != null ? '${playlist.songCount} ${AppLocalizations.of(context).songs}' : '');
    final description = playlist.description;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (playlist.id == 'liked') {
          Navigator.of(context).push(
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
              child: SongsViewer(showLikedSongs: true),
            ),
          );
        } else if (playlist.id == 'all') {
          Navigator.of(context).push(
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
              child: SongsViewer(showLikedSongs: false),
            ),
          );
        } else {
          Navigator.of(context).push(
            PageTransition(
              type: PageTransitionType.rightToLeft,
              duration: const Duration(milliseconds: 300),
              child: PlaylistViewer(playlistId: playlist.id),
            ),
          );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: imageUrl.isNotEmpty
                  ? CacheNetWorkImg(url: imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade800,
                      child: const Icon(
                        Icons.album,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              playlist.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          if (subtitle.isNotEmpty)
            Flexible(
              child: Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          if (description.isNotEmpty)
            Flexible(
              child: Text(
                description,
                style: TextStyle(color: Colors.white38, fontSize: 10),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionArtistList(String title, List<ArtistDetails> artists) {
    if (artists.isEmpty) return const SizedBox.shrink();

    final PageController controller = PageController(
      viewportFraction: MediaQuery.of(context).size.width > 600 ? 0.18 : 0.35,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _sectionHeader(title),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: controller,
            padEnds: false,
            physics: const BouncingScrollPhysics(),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  double scale = 1.0;
                  if (controller.position.haveDimensions) {
                    double page =
                        controller.page ?? controller.initialPage.toDouble();
                    scale = (1 - ((page - index).abs() * 0.3)).clamp(0.95, 1.0);
                  }
                  return Transform.scale(scale: scale, child: child);
                },
                child: _artistCard(artists[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _artistCard(ArtistDetails artist) {
    final imageUrl = artist.images.isNotEmpty ? artist.images.last.url : '';

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 300),
            child: ArtistViewer(artistId: artist.id),
          ),
        );
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            backgroundColor: Colors.grey.shade800,
            child: imageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 100,
            child: Column(
              children: [
                Text(
                  artist.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
                Text(
                  artist.dominantLanguage,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionAlbumList(String title, List<Album> albums) {
    if (albums.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title),
          const SizedBox(height: 8),
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: PageController(
                viewportFraction: MediaQuery.of(context).size.width > 600
                    ? 0.25
                    : 0.45,
              ),
              padEnds: false,
              physics: const BouncingScrollPhysics(),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: _albumCard(albums[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _albumCard(Album album) {
    final imageUrl = album.images.isNotEmpty ? album.images.last.url : '';
    final description = [
      album.artist,
      album.label,
      album.songs.isNotEmpty ? '${album.songs.length} ${AppLocalizations.of(context).songs}' : null,
    ].whereType<String>().where((e) => e.trim().isNotEmpty).join(' · ');

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
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: imageUrl.isNotEmpty
                  ? CacheNetWorkImg(url: imageUrl, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey.shade800,
                      child: const Icon(
                        Icons.album,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 6),
          Text(
            album.title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          Text(
            description,
            style: TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.w300,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
