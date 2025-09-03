import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'a_user_login.dart';
import 'firebase_options.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iLocate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const UserLogin(),
    );
  }
}