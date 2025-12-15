import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  final String apiKey;
  GeocodingService(this.apiKey);

  Future<Map<String, dynamic>> searchCity(String city) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1&appid=$apiKey",
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data.isEmpty) {
        throw Exception("City not found");
      }

      return {
        "name": data[0]["name"],
        "lat": data[0]["lat"],
        "lon": data[0]["lon"],
        "country": data[0]["country"]
      };
    } else {
      throw Exception("Error searching city");
    }
  }
}
