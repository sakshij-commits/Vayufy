import 'dart:convert';
import 'package:http/http.dart' as http;

class AQIService {
  final String apiKey;
  AQIService(this.apiKey);

  int calculateAQIFromPM25(double pm25) {
    final breakpoints = [
      {"cLow": 0.0, "cHigh": 12.0, "iLow": 0, "iHigh": 50},
      {"cLow": 12.1, "cHigh": 35.4, "iLow": 51, "iHigh": 100},
      {"cLow": 35.5, "cHigh": 55.4, "iLow": 101, "iHigh": 150},
      {"cLow": 55.5, "cHigh": 150.4, "iLow": 151, "iHigh": 200},
      {"cLow": 150.5, "cHigh": 250.4, "iLow": 201, "iHigh": 300},
      {"cLow": 250.5, "cHigh": 500.0, "iLow": 301, "iHigh": 500},
    ];

    for (var bp in breakpoints) {
      if (pm25 >= bp["cLow"]! && pm25 <= bp["cHigh"]!) {
        return (((bp["iHigh"]! - bp["iLow"]!) /
                    (bp["cHigh"]! - bp["cLow"]!)) *
                (pm25 - bp["cLow"]!) +
            bp["iLow"]!)
            .round();
      }
    }
    return 0;
  }


  Future<Map<String, dynamic>> getAQI(double lat, double lon) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/air_pollution"
      "?lat=$lat&lon=$lon&appid=$apiKey",
    );

    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch AQI");
    }

    final data = jsonDecode(res.body);
    final components = data["list"][0]["components"];

    final pm25 = components["pm2_5"].toDouble();
    final pm10 = components["pm10"].toDouble();

    final aqi = calculateAQIFromPM25(pm25);

    return {
      "aqi": aqi,
      "pm25": pm25,
      "pm10": pm10,
      "co": components["co"],
      "no2": components["no2"],
      "so2": components["so2"],
      "o3": components["o3"],
    };
  }
}