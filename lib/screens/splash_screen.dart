import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'farmer_home_screen.dart';
import 'worker_home_screen.dart';
import 'equipment_owner_home_screen.dart';
import 'admin_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2)); // Show splash for at least 2 seconds
    
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } else {
      try {
        final userData = await FirestoreService().getUser(user.uid);
        if (userData != null) {
          _navigateBasedOnRole(userData.role);
        } else {
          // User document doesn't exist, sign out and go to login
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  void _navigateBasedOnRole(String role) {
    if (!mounted) return;
    
    Widget nextScreen;
    switch (role) {
      case 'farmer':
        nextScreen = const FarmerHomeScreen();
        break;
      case 'worker':
        nextScreen = const WorkerHomeScreen();
        break;
      case 'equipment_owner':
        nextScreen = const EquipmentOwnerHomeScreen();
        break;
      case 'admin':
        nextScreen = const AdminHomeScreen();
        break;
      default:
        nextScreen = const LoginScreen();
    }
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/fellahty_logo.png',
                width: 150,
                height: 150,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              appLocale.get('app_name'),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              appLocale.get('connect_grow'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
