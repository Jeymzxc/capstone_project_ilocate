import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'a_user_login.dart';
import 'firebase_options.dart';
import 'g_admin_navigation.dart';
import 'g_rescuer_navigation.dart';

// Flutter plugin for showing local notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Global navigator key for navigation without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Handles background messages (when the app is in background/terminated)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

// Initializes local notifications and handles foreground taps
Future<void> _initLocalNotifications() async {
  const AndroidInitializationSettings initSettingsAndroid =
      AndroidInitializationSettings('@drawable/ic_stat_notification');

  const InitializationSettings initSettings =
      InitializationSettings(android: initSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    // 👉 Foreground notification tapped
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      debugPrint("🔔 Foreground notification tapped: ${response.payload}");

      final prefs = await SharedPreferences.getInstance();
      final adminId = prefs.getString('adminsId');
      final teamId = prefs.getString('teamsId');

      if (adminId != null) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AdminNavigationScreen(selectedIndex: 1),
          ),
        );
      } else if (teamId != null) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(initialIndex: 1),
          ),
        );
      } else {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const UserLogin(),
          ),
        );
      }
    },
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Widget startScreen = const UserLogin(); // fallback by default

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized successfully");

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Setup local notifications
    await _initLocalNotifications();

    // Request notification permission
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint("🔔 Notifications permission: ${settings.authorizationStatus}");

    // Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground notification: ${message.notification?.title}");

      if (message.notification != null) {
        flutterLocalNotificationsPlugin.show(
          message.hashCode,
          message.notification!.title,
          message.notification!.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'General Notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@drawable/ic_stat_notification',
            ),
          ),
          // 👉 you can pass a payload here to identify what screen to open
          payload: "sos_alert",
        );
      }
    });

    // Handle background-tap notifications
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint("🔗 User tapped notification (background): ${message.data}");

      final prefs = await SharedPreferences.getInstance();
      final adminId = prefs.getString('adminsId');
      final teamId = prefs.getString('teamsId');

      if (adminId != null) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const AdminNavigationScreen(selectedIndex: 1),
          ),
        );
      } else if (teamId != null) {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MainNavigationScreen(initialIndex: 1),
          ),
        );
      } else {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
            builder: (_) => const UserLogin(),
          ),
        );
      }
    });
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
  }

  // Check login state before launching app
  final prefs = await SharedPreferences.getInstance();
  final adminId = prefs.getString('adminsId');
  final teamId = prefs.getString('teamsId');

  if (adminId != null) {
    startScreen = const AdminNavigationScreen();
  } else if (teamId != null) {
    startScreen = const MainNavigationScreen();
  } else {
    startScreen = const UserLogin();
  }

  runApp(MyApp(startScreen: startScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iLocate',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // 👈 allows navigation outside BuildContext
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: startScreen,
    );
  }
}
