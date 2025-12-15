import 'dart:math';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedRange = '24 Hours';
  String _selectedPollutant = 'AQI';
  String _chartMode = 'Line';

  TooltipBehavior? _tooltipBehavior;
  TrackballBehavior? _trackballBehavior;

  List<TimeSeriesPoint> _points = [];

  final List<String> _pollutants = ['AQI', 'PM2.5', 'PM10', 'CO', 'SO2', 'NO2', 'O3'];
  final List<String> _ranges = ['12 Hours', '24 Hours', '7 Days', '30 Days'];

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true, format: 'point.x : point.y');
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipDisplayMode: TrackballDisplayMode.floatAllPoints,
    );
    _regenerateData();
  }

  void _regenerateData() {
    int points;
    Duration step;
    final now = DateTime.now();

    switch (_selectedRange) {
      case '12 Hours':
        points = 12;
        step = Duration(hours: 1);
        break;
      case '24 Hours':
        points = 24;
        step = Duration(hours: 1);
        break;
      case '7 Days':
        points = 7;
        step = Duration(days: 1);
        break;
      case '30 Days':
        points = 30;
        step = Duration(days: 1);
        break;
      default:
        points = 24;
        step = Duration(hours: 1);
    }

    final List<TimeSeriesPoint> p = [];

    for (int i = 0; i < points; i++) {
      final t = now.subtract(step * (points - 1 - i));
      double value = _mockVal(_selectedPollutant, i, points);
      p.add(TimeSeriesPoint(t, value));
    }

    setState(() => _points = p);
  }

  double _mockVal(String pollutant, int index, int total) {
    final base = index.toDouble();
    final wave = (sin(base * 0.25) + 1) / 2;

    switch (pollutant) {
      case 'PM2.5': return 60 + wave * 140 + (index % 3) * 2;
      case 'PM10': return 80 + wave * 180;
      case 'CO': return 200 + wave * 300;
      case 'SO2': return 1 + wave * 15;
      case 'NO2': return 10 + wave * 60;
      case 'O3': return 20 + wave * 80;
      default:
        double v = 160 + wave * 120;
        final mid = (total / 2).round();
        if ((index - mid).abs() <= 1) v += 20;
        return v;
    }
  }

  double get _minValue => _points.map((e) => e.value).reduce(min);
  double get _maxValue => _points.map((e) => e.value).reduce(max);

  String _date(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final am = dt.hour >= 12 ? "PM" : "AM";
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return "$h:$m $am on ${dt.day} ${months[dt.month - 1]}";
  }

  @override
  Widget build(BuildContext context) {
    DateTime minAt = _points.firstWhere((e) => e.value == _minValue).time;
    DateTime maxAt = _points.firstWhere((e) => e.value == _maxValue).time;

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          "Historical Air Quality Data",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [

            /// --- TOP CONTROLS ---
            Row(
              children: [
                ToggleButtons(
                  isSelected: [_chartMode == 'Line', _chartMode == 'Bar'],
                  onPressed: (i) => setState(() => _chartMode = i == 0 ? 'Line' : 'Bar'),
                  borderRadius: BorderRadius.circular(10),
                  fillColor: Colors.blueAccent,
                  selectedColor: Colors.white,
                  children: [
                    Padding(padding: EdgeInsets.all(10), child: Icon(Icons.show_chart)),
                    Padding(padding: EdgeInsets.all(10), child: Icon(Icons.bar_chart)),
                  ],
                ),

                Spacer(),

                _drop(_selectedRange, _ranges, (v) {
                  _selectedRange = v!;
                  _regenerateData();
                }),

                SizedBox(width: 12),

                _drop(_selectedPollutant, _pollutants, (v) {
                  _selectedPollutant = v!;
                  _regenerateData();
                }),
              ],
            ),

            SizedBox(height: 20),

            /// ---- CHART CARD ----
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0,4))],
              ),
              child: Column(
                children: [

                  /// LEGEND + MIN + MAX (with wrap)
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      legendChip(),

                      _pill(_minValue.round(), "Min.", _date(minAt)),
                      _pill(_maxValue.round(), "Max.", _date(maxAt)),
                    ],
                  ),

                  SizedBox(height: 16),

                  /// CHART
                  SizedBox(
                    height: 350,
                    child: _chart(),
                  ),

                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_short(_points.first.time), style: TextStyle(fontFamily: 'Poppins')),
                      Text(_short(_points.last.time), style: TextStyle(fontFamily: 'Poppins')),
                    ],
                  )
                ],
              ),
            ),

            SizedBox(height: 24),

            /// ---- LUNG IMPACT CARD ----
            lungImpactCard(
              7.1,   // daily
              49.7,  // weekly
              212.0, // monthly
            ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // -------------------- WIDGETS -----------------------

  Widget legendChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle)),
          SizedBox(width: 6),
          Text("Pune", style: TextStyle(fontFamily: 'Poppins')),
        ],
      ),
    );
  }

  Widget _pill(int val, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("$val",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              )),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
              Text(subtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chart() {
    final color = Colors.purpleAccent;

    if (_chartMode == 'Line') {
      return SfCartesianChart(
        tooltipBehavior: _tooltipBehavior,
        trackballBehavior: _trackballBehavior,
        primaryXAxis: DateTimeAxis(),
        primaryYAxis: NumericAxis(),
        series: [
          LineSeries<TimeSeriesPoint, DateTime>(
            dataSource: _points,
            xValueMapper: (p, _) => p.time,
            yValueMapper: (p, _) => p.value,
            color: color,
            width: 3,
            markerSettings: MarkerSettings(isVisible: true),
          ),
        ],
      );
    }

    return SfCartesianChart(
      tooltipBehavior: _tooltipBehavior,
      primaryXAxis: DateTimeAxis(),
      primaryYAxis: NumericAxis(),
      series: [
        ColumnSeries<TimeSeriesPoint, DateTime>(
          dataSource: _points,
          xValueMapper: (p, _) => p.time,
          yValueMapper: (p, _) => p.value,
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _drop(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: SizedBox(),
        onChanged: onChanged,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontFamily: 'Poppins')))).toList(),
      ),
    );
  }

  String _short(DateTime dt) {
    return "${dt.day}-${dt.month}-${dt.year}";
  }

  // -------- LUNG IMPACT CARD ---------

  Widget lungImpactCard(double daily, double weekly, double monthly) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0,4))],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Lung Age Impact",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text("Based on today's PM2.5 exposure",
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54)),
          SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your lungs aged by",
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 16)),
                    SizedBox(height: 4),
                    Text(
                      "${daily.toStringAsFixed(1)} days today",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Image.asset("assets/images/lungs.png", height: 80),
            ],
          ),

          SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Weekly", style: TextStyle(fontFamily: 'Poppins', color: Colors.black87)),
                  Text(
                    "${weekly.toStringAsFixed(1)} days",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Monthly", style: TextStyle(fontFamily: 'Poppins', color: Colors.black87)),
                  Text(
                    "${monthly.toStringAsFixed(1)} days",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 18, color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}

// DATA MODEL
class TimeSeriesPoint {
  final DateTime time;
  final double value;
  TimeSeriesPoint(this.time, this.value);
}
