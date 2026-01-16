import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const BMSTrackerApp());
}

class BMSTrackerApp extends StatelessWidget {
  const BMSTrackerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueAccent,
        brightness: Brightness.light,
      ),
      home: const DataScrubberScreen(),
    );
  }
}

class DataScrubberScreen extends StatefulWidget {
  const DataScrubberScreen({super.key});
  @override
  State<DataScrubberScreen> createState() => _DataScrubberScreenState();
}

class _DataScrubberScreenState extends State<DataScrubberScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'location',
  );
  List<Map<dynamic, dynamic>> _history = [];
  double _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dbRef.onValue.listen((event) {
      final snapshotValue = event.snapshot.value;
      if (snapshotValue != null && snapshotValue is Map) {
        final Map<dynamic, dynamic> rawData = snapshotValue;
        final sortedKeys = rawData.keys.toList()..sort();
        final List<Map<dynamic, dynamic>> sortedList = sortedKeys
            .map((k) => Map<dynamic, dynamic>.from(rawData[k]))
            .toList();

        if (mounted) {
          setState(() {
            _history = sortedList;
            if (_isLoading || _currentIndex >= _history.length - 2) {
              _currentIndex = (_history.length - 1).toDouble();
            }
            _isLoading = false;
          });
        }
      }
    });
  }

  // UPDATED: Added seconds (:ss) to the format
  String _formatDate(dynamic ts) {
    if (ts == null) return "Unknown Time";
    try {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(
        (ts is int ? ts : int.parse(ts.toString())) * 1000,
      );
      return DateFormat('MMM dd, yyyy - hh:mm:ss a').format(date);
    } catch (e) {
      return "Invalid Date";
    }
  }

  String _num(dynamic val, {int decimals = 1}) {
    if (val == null) return "0.0";
    double parsed = double.tryParse(val.toString()) ?? 0.0;
    return parsed.toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_history.isEmpty) {
      return const Scaffold(body: Center(child: Text("Waiting for data...")));
    }

    int safeIndex = _currentIndex.toInt().clamp(0, _history.length - 1);
    final record = _history[safeIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'BMS Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.88,
              height:
                  MediaQuery.of(context).size.height *
                  0.65, // Slight increase to fit extra location rows
              child: Card(
                elevation: 10,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 25,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _num(record['speed']),
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1,
                                ),
                              ),
                              const Text(
                                "km/h",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          _buildAlarmChip(
                            record['alarm']?.toString() ?? "No Alarm",
                          ),
                        ],
                      ),
                      const Divider(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCircle(
                            Icons.battery_charging_full,
                            "${record['soc']}%",
                            "SOC",
                            Colors.green,
                          ),
                          _buildStatCircle(
                            Icons.bolt,
                            "${_num(record['voltage'])}V",
                            "Voltage",
                            Colors.orange,
                          ),
                          _buildStatCircle(
                            Icons.thermostat,
                            "${record['avg_temp']}°C",
                            "Temp",
                            Colors.redAccent,
                          ),
                        ],
                      ),

                      const SizedBox(height: 15),

                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildDetailRow(
                              Icons.electric_moped,
                              "Current",
                              "${_num(record['current'])} A",
                            ),
                            _buildDetailRow(
                              Icons.history,
                              "Odometer",
                              "${record['odometer']} km",
                            ),
                            // UPDATED: Split Lat and Long for better visibility and precision
                            _buildDetailRow(
                              Icons.location_on,
                              "Latitude",
                              "${record['latitude']}",
                            ),
                            _buildDetailRow(
                              Icons.location_on_outlined,
                              "Longitude",
                              "${record['longitude']}",
                            ),
                          ],
                        ),
                      ),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 18,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(record['timestamp']),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Slider(
                  value: safeIndex.toDouble(),
                  min: 0,
                  max: (_history.length - 1).toDouble(),
                  divisions: _history.length > 1 ? _history.length - 1 : 1,
                  onChanged: (val) => setState(() => _currentIndex = val),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTimeLabel("HISTORY", Colors.grey),
                      _buildTimeLabel("LIVE DATA", Colors.blueAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCircle(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withAlpha(25),
          radius: 20,
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAlarmChip(String alarm) {
    bool isWarning = alarm.toLowerCase() != "no alarm";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red : Colors.green.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        alarm.toUpperCase(),
        style: TextStyle(
          color: isWarning ? Colors.white : Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ), // Tighter padding for extra rows
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 1.0,
      ),
    );
  }
}
