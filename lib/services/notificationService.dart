import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService extends ChangeNotifier {

  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Notification 초기화
  static Future initialize() async {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

    IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings();

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Notification 표시
  static Future instantNotification(String payload) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channelId', 'channelName', 'channelDescription',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
      fullScreenIntent: true,
      timeoutAfter: 10000,
    );

    const IOSNotificationDetails iOSPlatformChannelSpecifics = IOSNotificationDetails();

    const MacOSNotificationDetails macOSPlatformChannelSpecifics = MacOSNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
        macOS: macOSPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      0,
      'Background fetch 알림',
      payload,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Notification 표시
  static Future instantNotification_1() async {
    print('Notification 표시');
    var android = AndroidNotificationDetails("id", "channel", "description");
    var ios = IOSNotificationDetails();
    var platform = new NotificationDetails(android: android, iOS: ios);
    await _flutterLocalNotificationsPlugin.show(
        0,
        "Demo",
        "Tap to do something",
        platform,
        payload: "Welcome to demo app");
  }

  // Notification 취소
  static Future cancelNotification() async{
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
