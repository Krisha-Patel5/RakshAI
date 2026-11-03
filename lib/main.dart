// Copyright (c) 2026 Krisha Patel. All Rights Reserved.
// Project: RakshAI - AI POWERED PERSONAL SAFETY APP
// Notice: Source code is provided for inspection only. Commercial use,
// modification, and redistribution are strictly prohibited.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/sos_manager.dart';
import 'services/monitoring_service.dart';
import 'ui/dashboard_page.dart';
import 'ui/login_page.dart';
import 'ui/main_navigation.dart';
import 'ui/safety_lab_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  await Supabase.initialize(
    url: 'https://erskcnyonygqjswphykr.supabase.co',
    anonKey: 'sb_publishable_pqs2xBtWCbYKbTHKSKlRyQ_MTQsJka5',
  );

  await _requestAppPermissions();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SOSManager()),
        ChangeNotifierProvider(create: (_) => MonitoringService()),
      ],
      child: const AISafetyApp(),
    ),
  );
}

Future<void> _requestAppPermissions() async {
  await [
    Permission.microphone,
    Permission.location,
    Permission.sms,
    Permission.sensors,
    Permission.notification,
  ].request();
}

class AISafetyApp extends StatelessWidget {
  const AISafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RakshAI',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorSchemeSeed: Colors.red,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),

      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const LoginPage(),
        '/nav': (context) => const MainNavigation(),
        '/dashboard': (context) => const DashboardPage(),
        '/lab': (context) => const SafetyLabPage(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/icon.png',
              width: 140,
              height: 140,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.shield, size: 140, color: Colors.red);
              },
            ),
            const SizedBox(height: 30),
            const Text(
              "RakshAI",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "AI Safety App with Automatic Emergency Detection",
              style: TextStyle(
                fontSize: 10,
                color: Colors.black54,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}