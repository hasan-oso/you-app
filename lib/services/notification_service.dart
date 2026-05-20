import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:get/get.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // Handle notification tap
      },
    );
    
    // Register notification channel for Android 8.0+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_quest_channel',
      'Daily Quests',
      description: 'Reminders to complete daily scanning quests',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    // Request notification permission (Android 13+)
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // Schedule repeating quest reminders with localized messages and dynamic username
  Future<void> scheduleRepeatingQuestReminder(int remainingScans, {String username = 'User'}) async {
    await cancelQuestReminders(); // Clear previous

    // Get localized strings with parameter replacement
    final title = 'notify_quest_title'.tr;
    final message = 'notify_quest_msg'.tr
        .replaceAll('@username', username)
        .replaceAll('@scans', remainingScans.toString());

    await _flutterLocalNotificationsPlugin.periodicallyShow(
        0,
        title,
        message,
        RepeatInterval.everyMinute, // DEBUG: using everyMinute for test. Real: use scheduled reminders below
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'daily_quest_channel', 'Daily Quests',
                channelDescription: 'Reminders to complete daily scanning quests',
                importance: Importance.max,
                priority: Priority.high,
            )),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle
    );
    
    // Schedule explicit reminders for better control
    _scheduleNext4Hours(remainingScans, username);
  }

  Future<void> _scheduleNext4Hours(int remainingScans, String username) async {
     final now = tz.TZDateTime.now(tz.local);
     
     // Get localized strings
     final title = 'notify_quest_update_title'.tr;
     final messageTemplate = 'notify_quest_update_msg'.tr;
     
     // Schedule 3 reminders: +4h, +8h, +12h
     for (int i = 1; i <= 3; i++) {
       final message = messageTemplate
           .replaceAll('@username', username)
           .replaceAll('@scans', remainingScans.toString());
           
       await _flutterLocalNotificationsPlugin.zonedSchedule(
         i, // ID 1, 2, 3
         title,
         message,
         now.add(Duration(hours: 4 * i)),
         const NotificationDetails(
           android: AndroidNotificationDetails(
               'daily_quest_channel', 'Daily Quests',
               importance: Importance.max, priority: Priority.high,
           )),
         androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
         uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime
       );
     }
  }

  Future<void> cancelQuestReminders() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
