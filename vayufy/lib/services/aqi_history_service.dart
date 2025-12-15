// lib/services/aqi_history_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Small data model used by the chart screen
class TimeSeriesPoint {
  final DateTime time;
  final double value;
  TimeSeriesPoint(this.time, this.value);
}

class AQIHistoryService {
  final String apiKey;
  AQIHistoryService(this.apiKey);

  /// Fetch history from OpenWeather for lat/lon between startUnix and endUnix (both inclusive)
  /// Returns raw list of map entries with 'dt' (unix) and 'components'
  Future<List<Map<String, dynamic>>> _fetchRawHistory(
      double lat, double lon, int startUnix, int endUnix) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/air_pollution/history?lat=$lat&lon=$lon&start=$startUnix&end=$endUnix&appid=$apiKey",
    );

    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception("History fetch failed: ${res.statusCode} ${res.body}");
    }

    final body = jsonDecode(res.body);
    if (body == null || body['list'] == null) return [];
    final List raw = body['list'];
    return List<Map<String, dynamic>>.from(raw);
  }

  /// Public helper: returns timeseries for requested pollutant
  /// pollutant: 'pm2_5', 'pm10', 'co', 'no2', 'so2', 'o3', or 'AQI' (converted from pm2_5)
  /// ranges: '12h', '24h', '7d', '30d' — implemented per your spec (hourly/ daily averages)
  Future<List<TimeSeriesPoint>> fetchHistory({
    required double lat,
    required double lon,
    required String range, // '12h','24h','7d','30d'
    required String pollutant, // 'AQI' or components
  }) async {
    final now = DateTime.now().toUtc();
    final endUnix = now.millisecondsSinceEpoch ~/ 1000;
    int startUnix;

    if (range == '12h') {
      startUnix = now.subtract(Duration(hours: 12)).millisecondsSinceEpoch ~/ 1000;
    } else if (range == '24h') {
      startUnix = now.subtract(Duration(hours: 24)).millisecondsSinceEpoch ~/ 1000;
    } else if (range == '7d') {
      startUnix = now.subtract(Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;
    } else if (range == '30d') {
      startUnix = now.subtract(Duration(days: 30)).millisecondsSinceEpoch ~/ 1000;
    } else {
      throw Exception("Unsupported range: $range");
    }

    final raw = await _fetchRawHistory(lat, lon, startUnix, endUnix);

    if (raw.isEmpty) return [];

    // For 12h and 24h -> hourly points (use every hour sample or average samples in same hour)
    if (range == '12h' || range == '24h') {
      // Map by hour (year,month,day,hour)
      final Map<String, List<double>> group = {};
      final Map<String, DateTime> groupTime = {};

      for (final entry in raw) {
        final dt = DateTime.fromMillisecondsSinceEpoch((entry['dt'] as int) * 1000, isUtc: true).toLocal();
        final key = "${dt.year}-${dt.month}-${dt.day}-${dt.hour}";
        groupTime.putIfAbsent(key, () => DateTime(dt.year, dt.month, dt.day, dt.hour));
        double val = _extractValue(entry, pollutant);
        if (val.isNaN) continue;
        group.putIfAbsent(key, () => []).add(val);
      }

      final List<TimeSeriesPoint> pts = group.entries.map((e) {
        final avg = e.value.reduce((a, b) => a + b) / e.value.length;
        final time = groupTime[e.key]!;
        return TimeSeriesPoint(time, avg);
      }).toList();

      pts.sort((a, b) => a.time.compareTo(b.time));

      // ensure we have continuous points for the requested hours: fill missing hours with last known (optional)
      return _fillHourlyGaps(pts, range == '12h' ? 12 : 24);
    }

    // For 7d and 30d -> daily averages
    final Map<String, List<double>> dayGroup = {};
    final Map<String, DateTime> dayTime = {};

    for (final entry in raw) {
      final dt = DateTime.fromMillisecondsSinceEpoch((entry['dt'] as int) * 1000, isUtc: true).toLocal();
      final key = "${dt.year}-${dt.month}-${dt.day}";
      dayTime.putIfAbsent(key, () => DateTime(dt.year, dt.month, dt.day));
      double val = _extractValue(entry, pollutant);
      if (val.isNaN) continue;
      dayGroup.putIfAbsent(key, () => []).add(val);
    }

    final List<TimeSeriesPoint> days = dayGroup.entries.map((e) {
      final avg = e.value.reduce((a, b) => a + b) / e.value.length;
      final time = dayTime[e.key]!;
      return TimeSeriesPoint(time, avg);
    }).toList();

    days.sort((a, b) => a.time.compareTo(b.time));

    // If 7d requested but we got hourly samples only for shorter time window, try to ensure 7 points
    return _fillDailyGaps(days, range == '7d' ? 7 : 30);
  }

  // Extract pollutant numeric value from a single raw response entry
  double _extractValue(Map<String, dynamic> entry, String pollutant) {
    final comps = entry['components'] as Map<String, dynamic>?;
    if (comps == null) return double.nan;

    if (pollutant == 'AQI') {
      // Use pm2_5 conversion to US AQI
      final pm25 = (comps['pm2_5'] as num?)?.toDouble() ?? double.nan;
      if (pm25.isNaN) return double.nan;
      return convertPM25ToAQI(pm25).toDouble();
    }

    // pollutant key mapping: we expect user to pass 'pm2_5','pm10','co','no2','so2','o3'
    final available = comps[pollutant];
    if (available == null) return double.nan;
    return (available as num).toDouble();
  }

  // Helper: fill missing hourly gaps for last N hours, doing simple forward-fill or interpolation (forward-fill is used)
  List<TimeSeriesPoint> _fillHourlyGaps(List<TimeSeriesPoint> pts, int hoursNeeded) {
    // target: last `hoursNeeded` hours, each hour slot ending at now
    final now = DateTime.now();
    final List<TimeSeriesPoint> out = [];
    DateTime start = DateTime(now.year, now.month, now.day, now.hour).subtract(Duration(hours: hoursNeeded - 1));
    DateTime cursor = start;
    double? lastVal;
    final Map<String, double> map = {for (var p in pts) _hourKey(p.time): p.value};

    for (int i = 0; i < hoursNeeded; i++) {
      final key = _hourKey(cursor);
      if (map.containsKey(key)) {
        lastVal = map[key];
        out.add(TimeSeriesPoint(cursor, lastVal!));
      } else {
        // forward fill with last known or 0 if none
        out.add(TimeSeriesPoint(cursor, lastVal ?? 0.0));
      }
      cursor = cursor.add(Duration(hours: 1));
    }

    return out;
  }

  // Helper: fill daily gaps to guarantee N days (forward-fill)
  List<TimeSeriesPoint> _fillDailyGaps(List<TimeSeriesPoint> pts, int daysNeeded) {
    final now = DateTime.now();
    DateTime start = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysNeeded - 1));
    DateTime cursor = start;
    double? lastVal;
    final Map<String, double> map = {for (var p in pts) _dayKey(p.time): p.value};

    final List<TimeSeriesPoint> out = [];
    for (int i = 0; i < daysNeeded; i++) {
      final key = _dayKey(cursor);
      if (map.containsKey(key)) {
        lastVal = map[key];
        out.add(TimeSeriesPoint(cursor, lastVal!));
      } else {
        out.add(TimeSeriesPoint(cursor, lastVal ?? 0.0));
      }
      cursor = cursor.add(Duration(days: 1));
    }
    return out;
  }

  String _hourKey(DateTime dt) => "${dt.year}-${dt.month}-${dt.day}-${dt.hour}";
  String _dayKey(DateTime dt) => "${dt.year}-${dt.month}-${dt.day}";

  // US EPA PM2.5 conversion (returns int AQI 0-500)
  int convertPM25ToAQI(double pm25) {
    if (pm25 <= 12.0) return _linear(pm25, 0.0, 12.0, 0, 50);
    if (pm25 <= 35.4) return _linear(pm25, 12.1, 35.4, 51, 100);
    if (pm25 <= 55.4) return _linear(pm25, 35.5, 55.4, 101, 150);
    if (pm25 <= 150.4) return _linear(pm25, 55.5, 150.4, 151, 200);
    if (pm25 <= 250.4) return _linear(pm25, 150.5, 250.4, 201, 300);
    if (pm25 <= 350.4) return _linear(pm25, 250.5, 350.4, 301, 400);
    return _linear(pm25, 350.5, 500.4, 401, 500);
  }

  int _linear(double C, double Clow, double Chigh, int Ilow, int Ihigh) {
    final result = ((Ihigh - Ilow) / (Chigh - Clow)) * (C - Clow) + Ilow;
    return result.round();
  }
}
