import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/health_profile_screen.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'services/backend_service.dart';
import 'screens/select_city_screen.dart';
import 'screens/app_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VayufyApp());
}

class VayufyApp extends StatelessWidget {
  const VayufyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vayufy',

      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
      ),

      // Firebase Auth Listener
      home: const AppGate(),


      routes: {
        '/main': (context) => const MainPage(),
        '/home': (context) => HomeScreen(),
        '/history': (context) => HistoryScreen(),
        '/profile': (context) => ProfileScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/health': (context) => const HealthProfileScreen(),
        '/select-city': (context) => const SelectCityScreen(),
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  Future<void> _checkProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final backend = BackendService(baseUrl: "http://10.0.2.2:5000");

    try {
      final prefs = await backend.getPrefs(uid);

      // 1️⃣ Health profile not done
      if (prefs == null || prefs["profileCompleted"] != true) {
        Navigator.pushReplacementNamed(context, '/health');
        return;
      }

      // 2️⃣ City not selected
      if (prefs["citySelected"] != true) {
        Navigator.pushReplacementNamed(context, '/select-city');
        return;
      }

      // 3️⃣ Everything done → stay on MainPage
      print("✅ Onboarding complete");

    } catch (e) {
      print("❌ Onboarding check failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 60,
        backgroundColor: Colors.transparent,
        color: Colors.white,
        buttonBackgroundColor: Colors.blueAccent,
        animationDuration: const Duration(milliseconds: 300),

        items: const [
          Icon(Icons.home_filled, size: 28),
          Icon(Icons.show_chart, size: 28),
          Icon(Icons.person, size: 28),
        ],

        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
