import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/backend_service.dart';

import 'login_screen.dart';
import 'health_profile_screen.dart';
import 'select_city_screen.dart';
import 'package:vayufy/main.dart';

class AppGate extends StatelessWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {

        // ⏳ Auth loading
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!authSnap.hasData) {
          return const LoginScreen();
        }

        final uid = authSnap.data!.uid;
        final backend = BackendService(baseUrl: "http://10.0.2.2:5000");

        // 🔹 STEP 1: Check Health Profile existence
        return FutureBuilder(
          future: backend.getHealthProfile(uid),
          builder: (context, profileSnap) {

            if (profileSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ❌ Health profile NOT created
            if (!profileSnap.hasData || profileSnap.data == null) {
              return const HealthProfileScreen();
            }

            // 🔹 STEP 2: Check City selection via prefs
            
            // AFTER health profile exists
            return FutureBuilder(
              future: backend.getSavedCity(uid),
              builder: (context, citySnap) {

                if (citySnap.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                // ❌ NO SAVED CITY → FORCE SELECT CITY
                if (!citySnap.hasData || citySnap.data == null) {
                  return const SelectCityScreen();
                }

                // ✅ ALL GOOD
                return const MainPage();
              },
            );


          },
        );
      },
    );
  }
}
