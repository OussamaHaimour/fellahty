import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/app_localizations.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  // Initialize notifications
  await NotificationService.initialize(); // Added NotificationService.initialize()
  // Load saved language before app starts
  await appLocale.loadSavedLanguage();
  runApp(const FellahtyApp());
}

class FellahtyApp extends StatefulWidget {
  const FellahtyApp({Key? key}) : super(key: key);

  static void setLocale(BuildContext context, AppLanguage lang) {
    final state = context.findAncestorStateOfType<_FellahtyAppState>();
    state?.changeLanguage(lang);
  }

  @override
  State<FellahtyApp> createState() => _FellahtyAppState();
}

class _FellahtyAppState extends State<FellahtyApp> {
  void changeLanguage(AppLanguage lang) async {
    await appLocale.setLanguage(lang);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fellahty',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      builder: (context, child) {
        return Directionality(
          textDirection: appLocale.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}
