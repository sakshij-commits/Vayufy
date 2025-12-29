import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  final String baseUrl;
  final String? idToken; // optional: Firebase ID token for auth

  BackendService({required this.baseUrl, this.idToken});

  Map<String, String> _headers() {
    final h = {'Content-Type': 'application/json'};
    if (idToken != null) h['Authorization'] = 'Bearer $idToken';
    return h;
  }

  // ================= SAVED LOCATIONS =================
  Future<List<dynamic>> getSavedLocations(String uid) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/locations/user/$uid'),
      headers: _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}: ${res.body}');
  }

  Future<dynamic> addLocation(
      String uid, String city, double lat, double lon) async {
    final body =
        jsonEncode({'userId': uid, 'city': city, 'lat': lat, 'lon': lon});
    final res = await http.post(
      Uri.parse('$baseUrl/api/locations/add'),
      headers: _headers(),
      body: body,
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error ${res.statusCode}');
  }

  Future<void> deleteLocation(String id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/locations/$id'),
      headers: _headers(),
    );
    if (res.statusCode != 200) throw Exception('Delete failed');
  }

  // ================= SEARCH ================= 
  Future<dynamic> addSearch(String uid, String query) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/search/add'),
      headers: _headers(),
      body: jsonEncode({'userId': uid, 'query': query}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error');
  }

  Future<List<dynamic>> getSearchHistory(String uid) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/search/user/$uid'),
      headers: _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error');
  }

  // ================= AQI LOGS =================
  Future<void> addAQILog(String uid, Map<String, dynamic> data) async {
    final body = {
      "userId": uid,
      ...data,
    };

    print("📤 SENDING AQI LOG: $body");

    final res = await http.post(
      Uri.parse("$baseUrl/api/aqi/add"),
      headers: _headers(),
      body: jsonEncode(body),
    );

    print("📥 AQI LOG RESPONSE: ${res.statusCode} ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("AQI log failed");
    }
  }

  // ================= BASIC PREFS =================
  Future<dynamic> setPrefs(String uid, Map<String, dynamic> prefs) async {
    final payload = {
      "userId": uid,
      ...prefs,
    };

    print("📤 PREF SAVE PAYLOAD → $payload");

    final res = await http.post(
      Uri.parse('$baseUrl/api/prefs/set'),
      headers: _headers(),
      body: jsonEncode(payload),
    );

    print("📥 PREF SAVE RESPONSE → ${res.statusCode}");
    print("📥 PREF SAVE BODY → ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    throw Exception("Prefs save failed ${res.statusCode}");
  }

  Future<dynamic> getPrefs(String uid) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/prefs/user/$uid'),
      headers: _headers(),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Error');
  }


  // ================= HEALTH PROFILE =================

  Future<void> setHealthProfile(String uid, Map<String, dynamic> data) async {
    print("📤 Saving health profile: $data");

    final res = await http.post(
      Uri.parse("$baseUrl/api/health/set"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "userId": uid,
        ...data,
      }),
    );

    print("📥 Health profile response: ${res.statusCode} ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Failed to save health profile");
    }
  }

  Future<Map<String, dynamic>?> getHealthProfile(String uid) async {
    print("📥 FETCHING HEALTH PROFILE for $uid");

    final res = await http.get(
      Uri.parse("$baseUrl/api/health/user/$uid"),
      headers: _headers(),
    );

    print("📥 PROFILE RESPONSE: ${res.statusCode} ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    if (res.statusCode == 404) {
      return null; // profile not created yet
    }

    throw Exception("Failed to fetch profile");
  }


  // ================= DEVICES / NOTIFICATIONS =================
  Future<void> addDeviceToken(String uid, String token) async {
    await http.post(
      Uri.parse("$baseUrl/api/devices/register"),
      headers: _headers(),
      body: jsonEncode({
        "userId": uid,
        "token": token,
      }),
    );
  }

  Future<bool> profileExists(String uid) async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/prefs/health/$uid"),
      headers: _headers(),
    );
    return res.statusCode == 200;
  }

  // SAVE CITY
  Future<void> saveCity({
    required String userId,
    required String city,
    required double lat,
    required double lon,
  }) async {
    final url = Uri.parse("$baseUrl/api/locations");

    print("📤 SAVE CITY REQUEST → $url");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userId": userId,
        "city": city,
        "lat": lat,
        "lon": lon,
      }),
    );

    print("📥 SAVE CITY STATUS → ${response.statusCode}");
    print("📥 SAVE CITY BODY → ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Save city failed: ${response.body}");
    }
  }


  // GET SAVED CITY
  Future<Map<String, dynamic>?> getSavedCity(String userId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/api/locations/$userId"),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data;
    }

    return null;
  }

}
