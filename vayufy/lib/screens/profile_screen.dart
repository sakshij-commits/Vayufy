import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/backend_service.dart';
import 'health_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final backend = BackendService(baseUrl: "http://10.0.2.2:5000");

  final user = FirebaseAuth.instance.currentUser!;
  bool loading = true;

  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await backend.getHealthProfile(user.uid);
      profile = data;
    } catch (e) {
      profile = null;
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 👤 USER INFO
            Text(
              user.email ?? "",
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 24),

            // 🧠 HEALTH PROFILE CARD
            _card(
              title: "Health Profile",
              children: profile == null
                  ? [
                      const Text("No health profile found"),
                    ]
                  : [
                      _row("Age Group", profile!["ageGroup"]),
                      _row("Skin Type", profile!["skinType"]),
                      _row("Sensitivity", profile!["airSensitivity"]),
                      _row(
                        "Conditions",
                        (profile!["conditions"] as List).join(", "),
                      ),
                      _row(
                        "Alert Threshold",
                        "AQI ${profile!["alertThreshold"]}+",
                      ),
                    ],
            ),

            const SizedBox(height: 16),

            // ✏️ EDIT PROFILE
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HealthProfileScreen(),
                  ),
                );
                _loadProfile(); // refresh after edit
              },
              child: _actionButton("Edit Health Profile"),
            ),

            const SizedBox(height: 30),

            // 🚪 LOGOUT
            GestureDetector(
              onTap: () async {
                await FirebaseAuth.instance.signOut();
              },
              child: _actionButton(
                "Logout",
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black54)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _actionButton(String text, {Color color = Colors.black}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
