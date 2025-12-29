import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/aqi_service.dart';
import '../services/geocoding_service.dart';
import '../services/backend_service.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---------------- LOCATION (FROM BACKEND) ----------------
  String? city;
  double? lat;
  double? lon;

  final AQIService service =
      AQIService("028455080c07238383047d76937dfa2c");
  final GeocodingService geo =
      GeocodingService("028455080c07238383047d76937dfa2c");

  late BackendService backend;
  String? uid;

  int? aqi;
  double? pm10;
  double? pm25;
  Map<String, dynamic>? pollutants;

  bool loading = true;
  bool _fetching = false;

  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  // ---------------- BOOTSTRAP ----------------
  Future<void> _bootstrap() async {
    print("🚀 HomeScreen bootstrap");

    final user = FirebaseAuth.instance.currentUser;
    uid = user?.uid;

    backend = BackendService(
      baseUrl: "http://10.0.2.2:5000",
    );

    if (uid == null) return;

    await _initNotifications();
    await _loadSavedCityAndAQI();
  }

  // ---------------- LOAD CITY FROM BACKEND ----------------
  Future<void> _loadSavedCityAndAQI() async {
    try {
      final savedCity = await backend.getSavedCity(uid!);

      if (savedCity == null) {
        print("❌ No saved city found");
        if (mounted) {
          setState(() => loading = false);
        }
        return;
      }


      city = savedCity["city"];
      lat = savedCity["lat"];
      lon = savedCity["lon"];

      print("📍 Loaded city → $city ($lat,$lon)");

      await fetchAQI();
    } catch (e) {
      print("❌ Failed to load city: $e");
      setState(() => loading = false);
    }
  }

  // ---------------- NOTIFICATIONS ----------------
  Future<void> _initNotifications() async {
    try {
      final token = await NotificationService().init();
      if (token != null && uid != null) {
        await backend.addDeviceToken(uid!, token);
        print("📲 FCM token saved");
      }
    } catch (e) {
      print("⚠️ Notification init failed: $e");
    }
  }

  // ================= FETCH AQI =================
  Future<void> fetchAQI() async {
    if (_fetching || lat == null || lon == null) return;

    _fetching = true;
    print("📡 fetchAQI → $city ($lat,$lon)");

    try {
      final data = await service.getAQI(lat!, lon!);

      if (!mounted) return;

      setState(() {
        aqi = data["aqi"];
        pm10 = data["pm10"];
        pm25 = data["pm25"];
        pollutants = data;
        loading = false;
      });

      // 🔹 Save AQI log
      backend.addAQILog(uid!, {
        "city": city,
        "lat": lat,
        "lon": lon,
        "aqi": aqi,
        "pm10": pm10,
        "pm25": pm25,
        "co": pollutants!["co"],
        "no2": pollutants!["no2"],
        "so2": pollutants!["so2"],
        "o3": pollutants!["o3"],
        "timestamp": DateTime.now().toIso8601String(),
      });

    } catch (e) {
      print("❌ AQI ERROR: $e");
      if (mounted) setState(() => loading = false);
    } finally {
      _fetching = false;
    }
  }

  // ================= CATEGORY =================
  String getCategory(int aqi) {
    if (aqi <= 50) return "Good";
    if (aqi <= 100) return "Moderate";
    if (aqi <= 200) return "Unhealthy";
    if (aqi <= 300) return "Severe";
    return "Hazardous";
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading || aqi == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ---------- HEADER ----------
              Row(
                children: [
                  const Text(
                    "Vayufy",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        enabled: false, // 🔒 city fixed to saved location
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.location_on, size: 20),
                          hintText: "Saved location",
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(city ?? "",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),

              const SizedBox(height: 18),

              aqiMainCard(aqi!, pm10!.toInt(), pm25!.toInt()),

              const SizedBox(height: 30),

              aqiScaleBar(context, aqi!),

              const SizedBox(height: 30),

              const Text("Major Pollutants",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.25,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                children: [
                  pollutantCard("PM2.5", "${pm25!.toStringAsFixed(1)} µg/m³", Colors.purple),
                  pollutantCard("PM10", "${pm10!.toStringAsFixed(1)} µg/m³", Colors.orange),
                  pollutantCard("CO", pollutants!["co"].toString(), Colors.green),
                  pollutantCard("NO₂", pollutants!["no2"].toString(), Colors.redAccent),
                  pollutantCard("SO₂", pollutants!["so2"].toString(), Colors.blueGrey),
                  pollutantCard("O₃", pollutants!["o3"].toString(), Colors.teal),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget aqiMainCard(int aqi, int pm10, int pm25) {
    Color aqiColor;
    if (aqi <= 50) aqiColor = Colors.green;
    else if (aqi <= 100) aqiColor = Colors.lightGreen;
    else if (aqi <= 200) aqiColor = Colors.orange;
    else if (aqi <= 300) aqiColor = Colors.red;
    else aqiColor = Colors.purple;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [aqiColor.withOpacity(.75), aqiColor.withOpacity(.45)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Live AQI",
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Text(getCategory(aqi),
                    style: TextStyle(
                        color: aqiColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text("$aqi",
              style: const TextStyle(
                  fontSize: 72,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("PM10: $pm10 µg/m³",
                  style: const TextStyle(color: Colors.white)),
              Text("PM2.5: $pm25 µg/m³",
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget pollutantCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: color.withOpacity(.15),
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget aqiScaleBar(BuildContext context, int aqi) {
    double width = MediaQuery.of(context).size.width - 80;
    double pointerX = (aqi.clamp(0, 250) / 250) * width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Air Quality Index",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Stack(
          children: [
            Container(
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  stops: [0, .2, .4, .6, .8, 1],
                  colors: [
                    Color(0xff50f158),
                    Color(0xffc2f456),
                    Color(0xfff8c144),
                    Color(0xfff8714b),
                    Color(0xffc755db),
                    Color(0xff8b1f1f),
                  ],
                ),
              ),
            ),
            Positioned(
              left: pointerX - 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
