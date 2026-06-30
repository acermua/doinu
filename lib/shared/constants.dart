import 'dart:io';

import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/legacy.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/datamodel.dart';
import '../services/audiohandler.dart';
import '../services/supabase.dart';

// tab index
final tabIndexProvider = StateProvider<int>((ref) => 0);
final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

final currentSongProvider = StateProvider<SongDetail?>((ref) => null);

// shufflemanage
final shuffleProvider = StateProvider<bool>((ref) => false);

final repeatModeProvider = StateProvider<RepeatMode>((ref) => RepeatMode.none);

// common data
List<Playlist> playlists = [];
List<ArtistDetails> artists = [];
List<Album> albums = [];

PackageInfo packageInfo = PackageInfo(
  appName: 'Go Stream',
  packageName: 'com.hivemind.doinu',
  version: '1.0.0',
  buildNumber: 'h07',
);

// internet value
ValueNotifier<bool> hasInternet = ValueNotifier<bool>(true);

// profile update
File? profileFile;
String username = "Doinu";

// search
List<String> allSuggestions = [];

// supabase
late SupabaseApi sb;
