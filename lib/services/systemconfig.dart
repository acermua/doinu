import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

// handle update tracker
bool isAppUpdateAvailable = false;

class SystemUiConfigurator {
  static Future<void> configure() async {
    // Restrict orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set edge-to-edge system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }
}

Future<void> checkForUpdate() async {
  await Future.delayed(const Duration(seconds: 1));

  if (!await InternetConnection().hasInternetAccess) {
    debugPrint('[UPDATERTOOL] Skipped: No internet');
    return;
  }

  if (Platform.isAndroid) {
    await _checkAndroidUpdate();
  } else if (Platform.isIOS) {
    await _checkIOSUpdate();
  }
}

Future<void> _checkAndroidUpdate() async {
  try {
    debugPrint('[UPDATERTOOL] Checking Play Store update...');
    final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      isAppUpdateAvailable = true;
      debugPrint('[UPDATERTOOL] Update available on Play Store');

      if (updateInfo.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
      } else if (updateInfo.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } else {
      debugPrint('[UPDATERTOOL] No Play Store update available');
    }
  } catch (e) {
    debugPrint('[UPDATERTOOL] Android in-app update failed: $e');
  }
}

Future<void> _checkIOSUpdate() async {
  try {
    debugPrint('[UPDATERTOOL] Checking App Store update...');
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = packageInfo.version;
    final String bundleId = packageInfo.packageName;

    final response = await http.get(
      Uri.parse('https://itunes.apple.com/lookup?bundleId=$bundleId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['resultCount'] > 0) {
        final String latestVersion = data['results'][0]['version'];

        if (_isVersionGreater(latestVersion, currentVersion)) {
          isAppUpdateAvailable = true;
          debugPrint('[UPDATERTOOL] Update available on App Store: $latestVersion');
          
          // Note: On iOS, we usually show a dialog here since native in-app update 
          // isn't as direct as Android's. For now, we update the flag.
        }
      }
    }
  } catch (e) {
    debugPrint('[UPDATERTOOL] iOS update check failed: $e');
  }
}

bool _isVersionGreater(String latest, String current) {
  List<int> latestParts = latest.split('.').map(int.parse).toList();
  List<int> currentParts = current.split('.').map(int.parse).toList();

  for (int i = 0; i < latestParts.length && i < currentParts.length; i++) {
    if (latestParts[i] > currentParts[i]) return true;
    if (latestParts[i] < currentParts[i]) return false;
  }
  return latestParts.length > currentParts.length;
}
