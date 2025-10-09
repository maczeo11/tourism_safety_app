// lib/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();

    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    if (notificationStatus != PermissionStatus.granted) {
      return false;
    }

    // Request exact alarm permission for Android 12+
    await Permission.scheduleExactAlarm.request();

    return notificationStatus == PermissionStatus.granted;
  }

  Future<void> showIncidentAlert({
    required String incidentType,
    required String description,
    required double distance,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'incident_alerts',
          'Incident Alerts',
          channelDescription: 'Notifications for nearby incident locations',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFD32F2F), // Red color
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '⚠️ Safety Alert',
      'You are near a location where a $incidentType incident occurred. Distance: ${distance.toStringAsFixed(0)}m',
      details,
    );
  }

  Future<void> showGeofenceAlert({required String message}) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'geofence_alerts',
          'Geofence Alerts',
          channelDescription: 'Notifications for entering unsafe zones',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFFD32F2F), // Red color
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      '🚨 Unsafe Zone Alert',
      message,
      details,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
