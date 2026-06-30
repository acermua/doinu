import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:page_transition/page_transition.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toastification/toastification.dart';

import 'l10n/app_localizations.dart';
import 'screens/home.dart';
import 'screens/library.dart';
import 'screens/search.dart';
import 'services/audiohandler.dart';
import 'services/language_provider.dart';
import 'services/supabase.dart';
import 'services/localnotification.dart';
import 'services/systemconfig.dart';
import 'shared/constants.dart';
import 'models/database.dart';
import 'utils/env.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  packageInfo = await PackageInfo.fromPlatform();

  await initNotifications();
  await SystemUiConfigurator.configure();

  await Supabase.initialize(url: Env.url, anonKey: Env.anonKey);

  runApp(ToastificationWrapper(child: ProviderScope(child: MyApp())));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    // Deep links
    _linkSubscription = AppLinks().uriLinkStream.listen((uri) {
      debugPrint('onAppLink: $uri');
    });
    // Await the audioHandler FutureProvider
    await ref.read(audioHandlerProvider.future);
    sb = await ref.read(supabaseProvider);

    // One-time check for malformed songs in database
    unawaited(AppDatabase.cleanupMalformedSongs());
  }

  @override
  Widget build(BuildContext context) {
    final languageState = ref.watch(languageProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Doinu',
      locale: languageState.asData?.value ?? const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es'), Locale('eu')],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.accent),
        useMaterial3: true,
        textTheme: AppTheme.doinuTextTheme,
      ),
      themeMode: ThemeMode.dark,
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/search':
            page = const Search();
            break;
          case '/library':
            page = const LibraryPage();
            break;
          default:
            page = const Home();
        }
        return PageTransition(
          type: PageTransitionType.rightToLeft,
          child: page,
          settings: settings,
          duration: const Duration(milliseconds: 300),
          reverseDuration: const Duration(milliseconds: 300),
        );
      },
    );
  }
}
