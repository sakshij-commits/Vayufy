import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  final String apiKey;

  GeocodingService(this.apiKey);

  Future<Map<String, dynamic>> searchCity(String city) async {
    final encodedCity = Uri.encodeComponent(city.trim());

    final url =
        "https://api.openweathermap.org/geo/1.0/direct"
        "?q=$encodedCity&limit=5&appid=$apiKey";

    print("🌍 GEOCODE URL → $url");

    final res = await http.get(Uri.parse(url));

    print("🌍 GEOCODE STATUS → ${res.statusCode}");
    print("🌍 GEOCODE BODY → ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Geocoding API failed");
    }

    final List data = jsonDecode(res.body);

    if (data.isEmpty) {
      throw Exception("City not found");
    }

    final result = data.firstWhere(
      (c) => c["country"] == "IN",
      orElse: () => data[0],
    );

    return {
      "name": result["name"],
      "lat": result["lat"],
      "lon": result["lon"],
      "country": result["country"],
    };
  }
}
