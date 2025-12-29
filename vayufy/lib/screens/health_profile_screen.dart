import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/backend_service.dart';
import 'package:vayufy/main.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final BackendService backend =
      BackendService(baseUrl: "http://10.0.2.2:5000");

  final String uid = FirebaseAuth.instance.currentUser!.uid;

  String ageGroup = "";
  String skinType = "";
  List<String> conditions = [];
  String sensitivity = "";
  int alertThreshold = 150;

  bool saving = false;
  bool loading = true;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final data = await backend.getHealthProfile(uid);
      print("📥 Existing profile: $data");

      if (data != null) {
        ageGroup = data["ageGroup"] ?? "";
        skinType = data["skinType"] ?? "";
        conditions =
            List<String>.from(data["conditions"] ?? []);
        sensitivity = data["airSensitivity"] ?? "";
        alertThreshold = data["alertThreshold"] ?? 150;
      }
    } catch (e) {
      print("ℹ️ No profile yet");
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= UI HELPERS =================
  Widget pill(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget section(String title, Widget child, {String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
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
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    color: Colors.black54, fontSize: 13)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ================= SAVE =================
  Future<void> saveProfile() async {
    if (saving) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => saving = true);

    try {
      await backend.setHealthProfile(user.uid, {
        "ageGroup": ageGroup,
        "skinType": skinType,
        "conditions": conditions,
        "airSensitivity": sensitivity,
        "alertThreshold": alertThreshold,
        "profileCompleted": true,
      });

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save profile")),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }



  // ================= UI =================
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
        title: const Text("Health Profile"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            section(
              "Age Group",
              Wrap(
                spacing: 10,
                children: [
                  for (final a in ["Under 18", "18–30", "30–45", "45+"])
                    pill(a, ageGroup == a,
                        () => setState(() => ageGroup = a)),
                ],
              ),
            ),
            section(
              "Skin Type",
              Wrap(
                spacing: 10,
                children: [
                  for (final s in
                      ["Oily", "Dry", "Combination", "Sensitive"])
                    pill(s, skinType == s,
                        () => setState(() => skinType = s)),
                ],
              ),
              subtitle: "Pollution affects skin differently",
            ),
            section(
              "Health Conditions",
              Wrap(
                spacing: 10,
                children: [
                  for (final c in
                      ["Asthma", "Allergies", "Heart", "None"])
                    pill(c, conditions.contains(c), () {
                      setState(() {
                        if (c == "None") {
                          conditions = ["None"];
                        } else {
                          conditions.remove("None");
                          conditions.contains(c)
                              ? conditions.remove(c)
                              : conditions.add(c);
                        }
                      });
                    }),
                ],
              ),
            ),
            section(
              "Air Sensitivity",
              Wrap(
                spacing: 10,
                children: [
                  for (final s in ["Low", "Moderate", "High"])
                    pill(s, sensitivity == s,
                        () => setState(() => sensitivity = s)),
                ],
              ),
            ),
            section(
              "AQI Alert Threshold",
              Wrap(
                spacing: 10,
                children: [
                  for (final v in [100, 150, 200])
                    pill("$v+", alertThreshold == v,
                        () => setState(() => alertThreshold = v)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: saving ? null : saveProfile,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    saving ? "Saving..." : "Save & Continue",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
