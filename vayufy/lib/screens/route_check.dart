import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/backend_service.dart';

class RouteCheck extends StatefulWidget {
  const RouteCheck({super.key});

  @override
  State<RouteCheck> createState() => _RouteCheckState();
}

class _RouteCheckState extends State<RouteCheck> {
  @override
  void initState() {
    super.initState();
    checkProfile();
  }

  Future<void> checkProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final backend = BackendService(baseUrl: "http://10.0.2.2:5000");

    final exists = await backend.profileExists(uid);

    if (!mounted) return;

    if (exists) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/health-profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
