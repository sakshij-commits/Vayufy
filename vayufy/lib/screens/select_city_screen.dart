import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/backend_service.dart';
import '../services/geocoding_service.dart';

class SelectCityScreen extends StatefulWidget {
  const SelectCityScreen({super.key});

  @override
  State<SelectCityScreen> createState() => _SelectCityScreenState();
}

class _SelectCityScreenState extends State<SelectCityScreen> {
  final BackendService backend =
      BackendService(baseUrl: "http://10.0.2.2:5000");

  final GeocodingService geo =
      GeocodingService("028455080c07238383047d76937dfa2c");

  final TextEditingController controller = TextEditingController();

  String? city;
  double? lat;
  double? lon;

  bool saving = false;

  Future<void> searchCity(String name) async {
    if (name.trim().isEmpty) return;

    try {
      final result = await geo.searchCity(name);

      setState(() {
        city = "${result['name']}, ${result['country']}";
        lat = result['lat'];
        lon = result['lon'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("City not found")),
      );
    }
  }

//
  Future<void> saveCity() async {
    if (city == null || lat == null || lon == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => saving = true);

    try {
      // ✅ SAVE CITY TO BACKEND (SavedLocation collection)
      await backend.saveCity(
        userId: user.uid,
        city: city!,
        lat: lat!,
        lon: lon!,
      );

      if (!mounted) return;

      // 🔁 Reset app flow → AppGate will route correctly
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save city")),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

//

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("Select Your City"),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Where are you usually located?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              "This helps us show accurate air quality data.",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: controller,
                onSubmitted: searchCity,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "Search city",
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (city != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        city!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            GestureDetector(
              onTap: (city != null && !saving) ? saveCity : null,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: city != null ? Colors.black : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    saving ? "Saving..." : "Continue",
                    style: TextStyle(
                      color: city != null ? Colors.white : Colors.black38,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
