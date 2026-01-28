import 'package:cleanspot/screens/splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cleanspot/screens/login_screen.dart';
import 'package:cleanspot/providers/booking_provider.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (_) => BookingProvider(),
      child: const CleanSpotApp(),
    ),
  );
}

class CleanSpotApp extends StatelessWidget {
  const CleanSpotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CleanSpot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.amber,
        fontFamily: 'Roboto',
      ),
      home: SplashScreen(),
    );
  }
}
