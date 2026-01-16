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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueAccent),
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
        setState(() {
          _history = sortedList;
          if (_isLoading || _currentIndex == _history.length - 2) {
            _currentIndex = (_history.length - 1).toDouble();
          }
          _isLoading = false;
        });
      }
    });
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return "Unknown Time";
    DateTime date = DateTime.fromMillisecondsSinceEpoch(
      (ts is int ? ts : int.parse(ts.toString())) * 1000,
    );
    return DateFormat('MMM dd, yyyy - hh:mm:ss a').format(date);
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
    final currentRecord = _history[safeIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Odometer'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                // This makes the card elongated (taller)
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.6,
                child: Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 20,
                  shadowColor: Colors.black.withAlpha(205),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25.0,
                      vertical: 30,
                    ),
                    child: Column(
                      // Changed to spaceEvenly to distribute items vertically
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            const Icon(
                              Icons.speed,
                              size: 70, // Slightly larger icon
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "${currentRecord['speed']?.toStringAsFixed(1) ?? '0.0'} Km/s",
                              style: const TextStyle(
                                fontSize: 55,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 40, thickness: 1.2),
                        Column(
                          children: [
                            _buildRow(
                              Icons.history,
                              "Odometer",
                              "${currentRecord['odometer']} km",
                            ),
                            _buildRow(
                              Icons.location_on,
                              "Latitude",
                              "${currentRecord['latitude']}",
                            ),
                            _buildRow(
                              Icons.location_searching,
                              "Longitude",
                              "${currentRecord['longitude']}",
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withAlpha(13),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blueAccent.withAlpha(26),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 22,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatDate(currentRecord['timestamp']),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
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
                      _buildTimeLabel("OLDEST", Colors.grey),
                      _buildTimeLabel("NEWEST", Colors.blueAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: color,
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
      ), // Increased vertical spacing
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
