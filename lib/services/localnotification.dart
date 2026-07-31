import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
// Note: Darwin-specific types are often in the platform interface or exported by the main package.
// If not found, we use the permission_handler fallback for status check.

final FlutterLocalNotificationsPlugin notifications =
    FlutterLocalNotificationsPlugin();

Future<bool> checkNotificationStatus() async {
  final status = await Permission.notification.status;
  debugPrint('🔔 Permission status check: $status');
  return status.isGranted || status.isProvisional;
}

Future<void> requestNotificationPermission() async {
  if (Platform.isIOS || Platform.isMacOS) {
    // Request using the plugin's internal method (safe on all versions)
    await notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return;
  }

  // Fallback for Android
  final status = await Permission.notification.request();
  if (status.isPermanentlyDenied) {
    await openAppSettings();
  }
}

Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings(
    '@drawable/ic_launcher_foreground',
  );

  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    requestProvisionalPermission: false,
  );

  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await notifications.initialize(settings: initSettings);

  const androidChannel = AndroidNotificationChannel(
    'downloads_channel',
    'Song Downloads',
    description: 'Shows song download progress',
    importance: Importance.high,
  );

  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(androidChannel);

  const generalChannel = AndroidNotificationChannel(
    'general_channel',
    'General Notifications',
    description: 'General app notifications to make engage users',
    importance: Importance.high,
  );

  await notifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(generalChannel);

  debugPrint("Notifications initialized with channel 'downloads_channel'");
}

Future<void> showDownloadNotification(
  String title,
  double progress, {
  String? desc,
}) async {
  final androidDetails = AndroidNotificationDetails(
    'offlinedownloads_channel',
    'Song Downloads',
    channelDescription: 'Shows song download progress',
    importance: Importance.max,
    icon: '@drawable/ic_launcher_foreground',
    priority: Priority.high,
    onlyAlertOnce: true,
    showProgress: true,
    maxProgress: 100,
    playSound: false,
    enableVibration: false,
    silent: true,
    colorized: true,
    progress: progress.toInt(),
    subText: '${progress.toInt()}% completed',
  );

  const darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: false,
  );

  final details = NotificationDetails(
    android: androidDetails,
    iOS: darwinDetails,
  );

  await notifications.show(
    id: 0,
    title: title,
    body: desc ?? 'Downloading...',
    notificationDetails: details,
    payload: 'download_progress',
  );
}

Future<void> cancelDownloadNotification() async {
  await notifications.cancel(id: 0);
}

Future<void> showSimpleNotification(String title, String body) async {
  const androidDetails = AndroidNotificationDetails(
    'general_channel',
    'General Notifications',
    channelDescription: 'General app notifications to make engage users',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@drawable/ic_launcher_foreground',
  );

  const darwinDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const details = NotificationDetails(
    android: androidDetails,
    iOS: darwinDetails,
  );

  await notifications.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    notificationDetails: details,
  );
}
