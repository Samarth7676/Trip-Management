import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/enums.dart';
import '../models/itinerary_item.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(DateTime.now().timeZoneName));
    } catch (_) {
      // Fall back to UTC offset based resolution if the platform timezone
      // name isn't recognized by the tz database.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );
    await _plugin.initialize(initSettings);

    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      await androidImpl?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> scheduleForItineraryItem(ItineraryItem item) async {
    final scheduledTime = item.startDateTime.subtract(
      Duration(minutes: item.reminderMinutesBefore),
    );
    if (scheduledTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'itinerary_reminders',
      'Itinerary Reminders',
      channelDescription: 'Reminders for flights, trains, hotels and activities',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      item.notificationId,
      _titleFor(item),
      _bodyFor(item),
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancel(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  static String _titleFor(ItineraryItem item) {
    switch (item.type) {
      case ItineraryType.flight:
        return '✈️ Upcoming flight: ${item.title}';
      case ItineraryType.train:
        return '🚆 Upcoming train: ${item.title}';
      case ItineraryType.bus:
        return '🚌 Upcoming bus: ${item.title}';
      case ItineraryType.hotel:
        return '🏨 Check-in reminder: ${item.title}';
      case ItineraryType.activity:
        return '🗓️ Upcoming activity: ${item.title}';
      case ItineraryType.other:
        return '🔔 Reminder: ${item.title}';
    }
  }

  static String _bodyFor(ItineraryItem item) {
    final where = item.location.isNotEmpty ? ' at ${item.location}' : '';
    return 'Starts$where in ${item.reminderMinutesBefore} minutes.';
  }
}
