import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _restTimerNotificationId = 999;
  static const String _channelId = 'rest_timer_channel';
  static const String _channelName = 'Rest Timer Alerts';
  static const String _channelDesc =
      'Alerts when your workout rest timer expires';

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.UTC);
    } catch (_) {}

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification click if needed
      },
    );

    // Create the high-importance channel on Android
    if (Platform.isAndroid) {
      final androidPlatformChannelSpecifics =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatformChannelSpecifics != null) {
        await androidPlatformChannelSpecifics.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
    }
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    try {
      if (Platform.isAndroid) {
        final androidPlatformChannelSpecifics =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlatformChannelSpecifics != null) {
          final granted = await androidPlatformChannelSpecifics
              .requestNotificationsPermission();
          return granted ?? false;
        }
      } else if (Platform.isIOS) {
        final iosPlatformChannelSpecifics =
            _plugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        if (iosPlatformChannelSpecifics != null) {
          final granted = await iosPlatformChannelSpecifics.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          return granted ?? false;
        }
      }
    } catch (e) {
      debugPrint('[NotificationService] Request permission error: $e');
    }
    return true;
  }

  Future<bool> hasPermission() async {
    if (kIsWeb) return true;
    try {
      if (Platform.isAndroid) {
        final androidPlatformChannelSpecifics =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlatformChannelSpecifics != null) {
          return true;
        }
      } else if (Platform.isIOS) {
        final iosPlatformChannelSpecifics =
            _plugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        if (iosPlatformChannelSpecifics != null) {
          return true;
        }
      }
    } catch (_) {}
    return true;
  }

  Future<void> scheduleRestTimerNotification({
    required String exerciseName,
    required DateTime endTime,
  }) async {
    if (kIsWeb) return;
    final now = DateTime.now();
    if (endTime.isBefore(now)) return;

    final scheduledUtc = tz.TZDateTime.from(endTime.toUtc(), tz.UTC);

    try {
      await _plugin.zonedSchedule(
        id: _restTimerNotificationId,
        title: 'Rest Over',
        body: 'Time to start your next set for $exerciseName!',
        scheduledDate: scheduledUtc,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDesc,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('[NotificationService] Schedule notification error: $e');
    }
  }

  Future<void> cancelRestTimerNotification() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(id: _restTimerNotificationId);
    } catch (_) {}
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  return service;
});
