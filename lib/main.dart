// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:intl/intl.dart';
// import 'firebase_options.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   runApp(const BMSTrackerApp());
// }

// class BMSTrackerApp extends StatelessWidget {
//   const BMSTrackerApp({super.key});
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         colorSchemeSeed: Colors.blueAccent,
//         brightness: Brightness.light,
//       ),
//       home: const MainNavigation(),
//     );
//   }
// }

// // ------------------- MAIN NAVIGATION -------------------
// class MainNavigation extends StatefulWidget {
//   const MainNavigation({super.key});

//   @override
//   State<MainNavigation> createState() => _MainNavigationState();
// }

// class _MainNavigationState extends State<MainNavigation> {
//   int _selectedIndex = 0;

//   final List<Widget> _screens = const [
//     DataScrubberScreen(),
//     MonthlyDistanceScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: _screens[_selectedIndex],
//       bottomNavigationBar: NavigationBar(
//         selectedIndex: _selectedIndex,
//         onDestinationSelected: (index) {
//           setState(() => _selectedIndex = index);
//         },
//         destinations: const [
//           NavigationDestination(
//             icon: Icon(Icons.dashboard_outlined),
//             selectedIcon: Icon(Icons.dashboard),
//             label: "Dashboard",
//           ),
//           NavigationDestination(
//             icon: Icon(Icons.calendar_month_outlined),
//             selectedIcon: Icon(Icons.calendar_month),
//             label: "Monthly",
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ------------------- DATA SCRUBBER SCREEN -------------------
// class DataScrubberScreen extends StatefulWidget {
//   const DataScrubberScreen({super.key});
//   @override
//   State<DataScrubberScreen> createState() => _DataScrubberScreenState();
// }

// class _DataScrubberScreenState extends State<DataScrubberScreen> {
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
//     'location',
//   );
//   List<Map<dynamic, dynamic>> _history = [];
//   double _currentIndex = 0;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _dbRef.onValue.listen((event) {
//       final snapshotValue = event.snapshot.value;
//       if (snapshotValue != null && snapshotValue is Map) {
//         final Map<dynamic, dynamic> rawData = snapshotValue;
//         final sortedKeys = rawData.keys.toList()..sort();
//         final List<Map<dynamic, dynamic>> sortedList = sortedKeys
//             .map((k) => Map<dynamic, dynamic>.from(rawData[k]))
//             .toList();

//         if (mounted) {
//           setState(() {
//             _history = sortedList;
//             if (_isLoading || _currentIndex >= _history.length - 2) {
//               _currentIndex = (_history.length - 1).toDouble();
//             }
//             _isLoading = false;
//           });
//         }
//       }
//     });
//   }

//   // Added seconds for precise display
//   String _formatDate(dynamic ts) {
//     if (ts == null) return "Unknown Time";
//     try {
//       DateTime date = DateTime.fromMillisecondsSinceEpoch(
//         (ts is int ? ts : int.parse(ts.toString())) * 1000,
//       );
//       return DateFormat('MMM dd, yyyy - hh:mm:ss a').format(date);
//     } catch (e) {
//       return "Invalid Date";
//     }
//   }

//   String _num(dynamic val, {int decimals = 1}) {
//     if (val == null) return "0.0";
//     double parsed = double.tryParse(val.toString()) ?? 0.0;
//     return parsed.toStringAsFixed(decimals);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }
//     if (_history.isEmpty) {
//       return const Scaffold(body: Center(child: Text("Waiting for data...")));
//     }

//     int safeIndex = _currentIndex.toInt().clamp(0, _history.length - 1);
//     final record = _history[safeIndex];

//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: AppBar(
//         title: const Text(
//           'BMS Dashboard',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//         backgroundColor: Theme.of(context).colorScheme.primaryContainer,
//       ),
//       body: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Center(
//             child: SizedBox(
//               width: MediaQuery.of(context).size.width * 0.88,
//               height: MediaQuery.of(context).size.height * 0.65,
//               child: Card(
//                 elevation: 10,
//                 shadowColor: Colors.black26,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(28),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 24,
//                     vertical: 25,
//                   ),
//                   child: Column(
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 _num(record['speed']),
//                                 style: const TextStyle(
//                                   fontSize: 48,
//                                   fontWeight: FontWeight.bold,
//                                   letterSpacing: -1,
//                                 ),
//                               ),
//                               const Text(
//                                 "km/h",
//                                 style: TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           _buildAlarmChip(
//                             record['alarm']?.toString() ?? "No Alarm",
//                           ),
//                         ],
//                       ),
//                       const Divider(height: 30),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           _buildStatCircle(
//                             Icons.battery_charging_full,
//                             "${record['soc']}%",
//                             "SOC",
//                             Colors.green,
//                           ),
//                           _buildStatCircle(
//                             Icons.bolt,
//                             "${_num(record['voltage'])}V",
//                             "Voltage",
//                             Colors.orange,
//                           ),
//                           _buildStatCircle(
//                             Icons.thermostat,
//                             "${record['avg_temp']}°C",
//                             "Temp",
//                             Colors.redAccent,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 15),
//                       Expanded(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             _buildDetailRow(
//                               Icons.electric_moped,
//                               "Current",
//                               "${_num(record['current'])} A",
//                             ),
//                             _buildDetailRow(
//                               Icons.history,
//                               "Odometer",
//                               "${record['odometer']} km",
//                             ),
//                             _buildDetailRow(
//                               Icons.location_on,
//                               "Latitude",
//                               "${record['latitude']}",
//                             ),
//                             _buildDetailRow(
//                               Icons.location_on_outlined,
//                               "Longitude",
//                               "${record['longitude']}",
//                             ),
//                           ],
//                         ),
//                       ),
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(10),
//                         decoration: BoxDecoration(
//                           color: Colors.blueAccent.withAlpha(25),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Icon(
//                               Icons.access_time,
//                               size: 18,
//                               color: Colors.blueAccent,
//                             ),
//                             const SizedBox(width: 8),
//                             Text(
//                               _formatDate(record['timestamp']),
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 15,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(height: 40),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 40),
//             child: Column(
//               children: [
//                 Slider(
//                   value: safeIndex.toDouble(),
//                   min: 0,
//                   max: (_history.length - 1).toDouble(),
//                   divisions: _history.length > 1 ? _history.length - 1 : 1,
//                   onChanged: (val) => setState(() => _currentIndex = val),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 10),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       _buildTimeLabel("HISTORY", Colors.grey),
//                       _buildTimeLabel("LIVE DATA", Colors.blueAccent),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 40),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCircle(
//     IconData icon,
//     String value,
//     String label,
//     Color color,
//   ) {
//     return Column(
//       children: [
//         CircleAvatar(
//           backgroundColor: color.withAlpha(25),
//           radius: 20,
//           child: Icon(icon, color: color, size: 20),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           value,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
//       ],
//     );
//   }

//   Widget _buildAlarmChip(String alarm) {
//     bool isWarning = alarm.toLowerCase() != "no alarm";
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: isWarning ? Colors.red : Colors.green.withAlpha(40),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         alarm.toUpperCase(),
//         style: TextStyle(
//           color: isWarning ? Colors.white : Colors.green,
//           fontWeight: FontWeight.bold,
//           fontSize: 10,
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(IconData icon, String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Icon(icon, size: 24, color: Colors.blueGrey),
//           const SizedBox(width: 12),
//           Text(
//             label,
//             style: const TextStyle(fontSize: 16, color: Colors.black54),
//           ),
//           const Spacer(),
//           Text(
//             value,
//             style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTimeLabel(String text, Color color) {
//     return Text(
//       text,
//       style: TextStyle(
//         fontSize: 10,
//         fontWeight: FontWeight.w900,
//         color: color,
//         letterSpacing: 1.0,
//       ),
//     );
//   }
// }

// // ------------------- MONTHLY DISTANCE SCREEN -------------------
// // ------------------- MONTHLY DISTANCE SCREEN (WITH LABELS) -------------------
// class MonthlyDistanceScreen extends StatefulWidget {
//   const MonthlyDistanceScreen({super.key});

//   @override
//   State<MonthlyDistanceScreen> createState() => _MonthlyDistanceScreenState();
// }

// class _MonthlyDistanceScreenState extends State<MonthlyDistanceScreen> {
//   final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
//     'location',
//   );

//   double? _distance; // Current month distance
//   double? _prevDistance; // Previous month distance (simulated)
//   bool _loading = true;

//   @override
//   void initState() {
//     super.initState();
//     _calculateTestDistance();
//   }

//   int _toUnix(DateTime dt) => dt.toUtc().millisecondsSinceEpoch ~/ 1000;

//   Future<void> _calculateTestDistance() async {
//     // -------------------- TEST RANGE --------------------
//     final startAnchor = DateTime.utc(2026, 2, 2, 10);
//     final endAnchor = DateTime.utc(2026, 2, 5, 10);

//     final startUnix = _toUnix(startAnchor);
//     final endUnix = _toUnix(endAnchor);

//     final snapshot = await _dbRef.get();

//     if (!snapshot.exists) {
//       setState(() => _loading = false);
//       return;
//     }

//     final Map<dynamic, dynamic> rawData =
//         snapshot.value as Map<dynamic, dynamic>;

//     double? startOdo;
//     double? endOdo;

//     rawData.forEach((key, value) {
//       final record = Map<dynamic, dynamic>.from(value);
//       final ts = record['timestamp'];
//       final odo = double.tryParse(record['odometer'].toString());
//       if (ts == null || odo == null) return;

//       if (ts <= startUnix) {
//         if (startOdo == null || ts > startUnix) startOdo = odo;
//       }
//       if (ts <= endUnix) {
//         if (endOdo == null || ts > endUnix) endOdo = odo;
//       }
//     });

//     if (startOdo != null && endOdo != null) {
//       _distance = endOdo! - startOdo!;
//     }

//     // For demo: simulate previous month distance
//     _prevDistance = 120.0; // placeholder, replace with real logic later

//     setState(() {
//       _loading = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     }

//     return Scaffold(
//       appBar: AppBar(title: const Text("Monthly Distance"), centerTitle: true),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ------------------ CURRENT MONTH ------------------
//             Text(
//               "Current Month",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blueGrey.shade700,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Center(
//               child: _distance == null
//                   ? const Text("Not enough data")
//                   : Text(
//                       "${_distance!.toStringAsFixed(2)} km",
//                       style: const TextStyle(
//                         fontSize: 40,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blueAccent,
//                       ),
//                     ),
//             ),
//             const SizedBox(height: 30),
//             // ------------------ PREVIOUS MONTH ------------------
//             Text(
//               "Previous Month",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blueGrey.shade700,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Center(
//               child: _prevDistance == null
//                   ? const Text("-- km")
//                   : Text(
//                       "${_prevDistance!.toStringAsFixed(2)} km",
//                       style: const TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey,
//                       ),
//                     ),
//             ),
//             const SizedBox(height: 40),
//             // ------------------ INFO CARD ------------------
//             Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               elevation: 5,
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.info_outline,
//                           color: Colors.blueAccent,
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: Text(
//                             "This view shows the total distance traveled by the vehicle for the current month compared to the previous month.",
//                             style: const TextStyle(
//                               fontSize: 14,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 15),
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.calendar_today,
//                           color: Colors.blueAccent,
//                         ),
//                         const SizedBox(width: 10),
//                         Text(
//                           "Timeframe: Feb 2 → Feb 5 (Test)",
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: Colors.black87,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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
      home: const MainNavigation(),
    );
  }
}

// ------------------- MAIN NAVIGATION -------------------
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DataScrubberScreen(),
    MonthlyDistanceScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: "Dashboard",
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: "Monthly",
          ),
        ],
      ),
    );
  }
}

// ------------------- DATA SCRUBBER SCREEN -------------------
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

  String _formatDate(dynamic ts) {
    if (ts == null) return "Unknown Time";

    try {
      final int timestamp = ts is int ? ts : int.parse(ts.toString());

      if (timestamp == 0) return "No Data";

      DateTime date = DateTime.fromMillisecondsSinceEpoch(
        timestamp * 1000,
        isUtc: true, // optional but recommended
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
              height: MediaQuery.of(context).size.height * 0.65,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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

// ------------------- MONTHLY DISTANCE SCREEN -------------------
class MonthlyDistanceScreen extends StatefulWidget {
  const MonthlyDistanceScreen({super.key});

  @override
  State<MonthlyDistanceScreen> createState() => _MonthlyDistanceScreenState();
}

class _MonthlyDistanceScreenState extends State<MonthlyDistanceScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child(
    'location',
  );

  double? _currentRunningDistance; // Current month running
  double? _currentMonthDistance; // Completed month distance
  double? _prevMonthDistance; // Previous month distance
  bool _loading = true;

  final int blockStartHour = 9;

  @override
  void initState() {
    super.initState();
    _calculateMonthlyDistance();
  }

  int _toUnix(DateTime dt) => dt.toUtc().millisecondsSinceEpoch ~/ 1000;

  DateTime getMonthStart(DateTime date, {int hour = 9}) =>
      DateTime.utc(date.year, date.month, 1, hour);

  DateTime getPrevMonthStart(DateTime date, {int hour = 9}) {
    final prevMonth = DateTime(date.year, date.month - 1, 1);
    return DateTime.utc(prevMonth.year, prevMonth.month, 1, hour);
  }

  DateTime getMonthEnd(DateTime date) {
    final nextMonth = (date.month < 12)
        ? DateTime.utc(date.year, date.month + 1, 1)
        : DateTime.utc(date.year + 1, 1, 1);
    return nextMonth.subtract(const Duration(seconds: 1));
  }

  Future<void> _calculateMonthlyDistance() async {
    final now = DateTime.now().toUtc();

    final startCurrentMonth = getMonthStart(now, hour: blockStartHour);
    final startPrevMonth = getPrevMonthStart(now, hour: blockStartHour);
    final startMonthBeforePrev = getPrevMonthStart(
      startPrevMonth,
      hour: blockStartHour,
    );

    final snapshot = await _dbRef.get();
    if (!snapshot.exists) {
      setState(() => _loading = false);
      return;
    }

    final Map<dynamic, dynamic> rawData =
        snapshot.value as Map<dynamic, dynamic>;

    double? odoFirstPrevMonth;
    double? odoFirstPrevPrevMonth;
    double? odoFirstCurrentMonth;
    double? odoLatestCurrentMonth;

    int tsFirstPrevMonth = 1 << 30;
    int tsFirstPrevPrevMonth = 1 << 30;
    int tsFirstCurrentMonth = 1 << 30;
    int tsLatestCurrentMonth = 0;

    for (var entry in rawData.entries) {
      final record = Map<dynamic, dynamic>.from(entry.value);
      final ts = record['timestamp'];
      final odo = double.tryParse(record['odometer'].toString());
      if (ts == null || odo == null) continue;

      // Previous month start reading
      if (ts >= _toUnix(startPrevMonth) && ts < tsFirstPrevMonth) {
        odoFirstPrevMonth = odo;
        tsFirstPrevMonth = ts;
      }

      // Month before previous start reading
      if (ts >= _toUnix(startMonthBeforePrev) && ts < tsFirstPrevPrevMonth) {
        odoFirstPrevPrevMonth = odo;
        tsFirstPrevPrevMonth = ts;
      }

      // Current month start reading
      if (ts >= _toUnix(startCurrentMonth) && ts < tsFirstCurrentMonth) {
        odoFirstCurrentMonth = odo;
        tsFirstCurrentMonth = ts;
      }

      // Latest reading up to now
      if (ts <= _toUnix(now) && ts > tsLatestCurrentMonth) {
        odoLatestCurrentMonth = odo;
        tsLatestCurrentMonth = ts;
      }
    }

    // Current running distance (from 1st of month → latest)
    if (odoFirstCurrentMonth != null && odoLatestCurrentMonth != null) {
      _currentRunningDistance = odoLatestCurrentMonth - odoFirstCurrentMonth;
    }

    // Completed month distance (only if month is complete)
    final isMonthComplete = now.isAfter(getMonthEnd(now));
    if (isMonthComplete &&
        odoFirstCurrentMonth != null &&
        odoLatestCurrentMonth != null) {
      _currentMonthDistance = odoLatestCurrentMonth - odoFirstCurrentMonth;
    }

    // Previous month distance
    if (odoFirstPrevMonth != null && odoFirstPrevPrevMonth != null) {
      _prevMonthDistance = odoFirstPrevMonth - odoFirstPrevPrevMonth;
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Distance"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildDistanceCard(
              "Current Month Completed",
              _currentMonthDistance,
              highlightColor: Colors.green,
            ),
            _buildDistanceCard(
              "Current Month Running",
              _currentRunningDistance,
              highlightColor: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            _buildDistanceCard(
              "Previous Month",
              _prevMonthDistance,
              highlightColor: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceCard(
    String label,
    double? value, {
    Color highlightColor = Colors.blueAccent,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade700,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: value == null
                  ? const Text("-- km")
                  : Text(
                      "${value.toStringAsFixed(2)} km",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: highlightColor,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
