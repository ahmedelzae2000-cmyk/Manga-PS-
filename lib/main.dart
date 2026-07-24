import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "حدث خطأ في واجهة المستخدم:\n${details.exception}",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ),
      ),
    );
  };

  runApp(const MangaPsApp());
}

class MangaPsApp extends StatelessWidget {
  const MangaPsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga PS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const FirebaseLoaderScreen(),
    );
  }
}

class FirebaseLoaderScreen extends StatefulWidget {
  const FirebaseLoaderScreen({super.key});

  @override
  State<FirebaseLoaderScreen> createState() => _FirebaseLoaderScreenState();
}

class _FirebaseLoaderScreenState extends State<FirebaseLoaderScreen> {
  late Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    // إدخال الإعدادات مباشرة لتجاوز خطأ الـ PlatformException
    _initialization = Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCY8JW1ZEpzcvS...", // 👈 ضع الـ current_key المكتوب في google-services.json بالكامل
        appId: "1:49681326088:android:...", // 👈 ضع الـ mobilesdk_app_id المكتوب في google-services.json بالكامل
        messagingSenderId: "49681326088",
        projectId: "manga-ps",
        storageBucket: "manga-ps.firebasestorage.app",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SelectableText(
                  "فشل الاتصال بـ Firebase:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.orange, fontSize: 16),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return const DashboardScreen();
        }

        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.purpleAccent),
                SizedBox(height: 20),
                Text("جاري الاتصال بـ Manga PS..."),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final FirebaseFirestore _db;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _db = FirebaseFirestore.instance;

    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      try {
        final devicesSnap = await _db.collection('devices').get();
        for (var doc in devicesSnap.docs) {
          if (doc.data()['isActive'] == true) {
            _db.collection('devices').doc(doc.id).update({
              'elapsedSeconds': FieldValue.increment(1),
            });
          }
        }
      } catch (e) {
        debugPrint("Timer Exception: $e");
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String formatTime(int seconds) {
    final dur = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(dur.inHours)}:${twoDigits(dur.inMinutes.remainder(60))}:${twoDigits(dur.inSeconds.remainder(60))}";
  }

  double calculateCost(Map<String, dynamic> device, Map<String, dynamic> rates) {
    double rate = 0;
    bool isMulti = device['isMulti'] ?? false;
    String type = device['type'] ?? 'PS4';

    if (type == 'PS4') {
      rate = isMulti ? (rates['ps4MultiRate'] ?? 40.0) : (rates['ps4SingleRate'] ?? 25.0);
    } else {
      rate = isMulti ? (rates['ps5MultiRate'] ?? 60.0) : (rates['ps5SingleRate'] ?? 40.0);
    }
    int seconds = device['elapsedSeconds'] ?? 0;
    return (seconds / 3600.0) * rate;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('settings').doc('rates').snapshots(),
      builder: (context, ratesSnap) {
        Map<String, dynamic> rates = {};
        if (ratesSnap.hasData && ratesSnap.data!.data() != null) {
          rates = ratesSnap.data!.data() as Map<String, dynamic>;
        } else {
          rates = {
            'ps4SingleRate': 25.0,
            'ps4MultiRate': 40.0,
            'ps5SingleRate': 40.0,
            'ps5MultiRate': 60.0,
          };
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manga PS 🎮'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  _db.collection('devices').add({
                    'name': 'جهاز جديد',
                    'type': 'PS4',
                    'isActive': false,
                    'isMulti': false,
                    'elapsedSeconds': 0,
                  });
                },
              )
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('devices').snapshots(),
            builder: (context, devicesSnap) {
              if (devicesSnap.hasError) {
                return Center(child: Text("خطأ في Firestore: ${devicesSnap.error}"));
              }
              if (!devicesSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = devicesSnap.data!.docs;
              if (docs.isEmpty) {
                return const Center(child: Text("اضغط + من الأعلى لإضافة أول جهاز"));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  var device = docs[i].data() as Map<String, dynamic>;
                  String docId = docs[i].id;
                  bool isActive = device['isActive'] ?? false;
                  double cost = calculateCost(device, rates);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(device['name'] ?? 'جهاز', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Chip(label: Text(device['type'] ?? 'PS4')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(formatTime(device['elapsedSeconds'] ?? 0), style: const TextStyle(fontSize: 24, color: Colors.greenAccent)),
                          Text('${cost.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 18, color: Colors.amber)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.red : Colors.green),
                            onPressed: () {
                              _db.collection('devices').doc(docId).update({
                                'isActive': !isActive,
                              });
                            },
                            child: Text(isActive ? 'إيقاف' : 'تشغيل', style: const TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
