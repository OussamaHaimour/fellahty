import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility to create or promote admin account
/// Run once: AdminSetup.createAdminAccount()
class AdminSetup {
  /// Creates an admin account with the given credentials
  /// If user already exists, promotes them to admin
  static Future<void> createAdminAccount({
    String email = 'admin@fellahty.ma',
    String password = 'Admin123!',
    String name = 'Admin Fellahty',
  }) async {
    try {
      // Try to create new user
      UserCredential result = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).set({
          'name': name,
          'email': email,
          'phone': '+21200000000',
          'role': 'admin',
          'region': 'National',
          'score': 0.0,
          'walletBalance': 0.0,
        });
        print('✅ Admin account created: $email');
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Promote existing user to admin
        try {
          UserCredential result = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);
          if (result.user != null) {
            await FirebaseFirestore.instance.collection('users').doc(result.user!.uid).update({
              'role': 'admin',
            });
            print('✅ Existing user promoted to admin: $email');
          }
        } catch (e2) {
          print('❌ Failed to promote user: $e2');
        }
      } else {
        print('❌ Error creating admin: $e');
      }
    }
  }
}
