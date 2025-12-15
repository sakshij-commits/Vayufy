import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<String?> init() async {
    // 1️⃣ Permission
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2️⃣ Android channel (REQUIRED)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'aqi_alerts',
      'AQI Alerts',
      description: 'High AQI notifications',
      importance: Importance.max,
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3️⃣ Init local notifications
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _local.initialize(
      const InitializationSettings(android: androidInit),
    );

    // 4️⃣ FOREGROUND handler (THIS WAS MISSING)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 FOREGROUND NOTIFICATION RECEIVED");
      print("Title: ${message.notification?.title}");
      print("Body: ${message.notification?.body}");

      _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        message.notification?.title ?? "AQI Alert",
        message.notification?.body ?? "Air quality is poor",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'aqi_alerts',
            'AQI Alerts',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });

    // 5️⃣ Get FCM token
    final token = await _fcm.getToken();
    print("📲 FCM TOKEN: $token");

    return token;
  }
}
