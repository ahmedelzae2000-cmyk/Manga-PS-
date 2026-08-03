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
            "حدث خطأ في الواجهة:\n${details.exception}",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
          ),
        ),
      ),
    );
  };

  runApp(const MangaPsApp());
}

DateTime getBusinessDayStart(DateTime date) {
  if (date.hour < 12) {
    DateTime prev = date.subtract(const Duration(days: 1));
    return DateTime(prev.year, prev.month, prev.day, 12, 0, 0);
  } else {
    return DateTime(date.year, date.month, date.day, 12, 0, 0);
  }
}

class MangaPsApp extends StatelessWidget {
  const MangaPsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga PS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent, // شفاف عشان الخلفية تظهر
        primaryColor: const Color(0xFF6C5CE7),
      ),
      home: const FirebaseLoaderScreen(),
    );
  }
}

// 🖼️ ويدجت تغليف الشاشات بالخلفية
class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/bg.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
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
    _initialization = Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCY8JW1ZEpzcvS...", 
        appId: "1:49681326088:android:...", 
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
          return BackgroundWrapper(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SelectableText(
                    "فشل الاتصال بـ Firebase:\n${snapshot.error}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 16),
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return const MainNavigationScreen();
        }

        return const BackgroundWrapper(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF6C5CE7)),
            ),
          ),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DevicesDashboardScreen(),
    const ExpensesScreen(),
    const ReportsScreen(),
    const ShiftScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.9),
          selectedItemColor: const Color(0xFF6C5CE7),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'الأجهزة'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'المصروفات'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'التقارير'),
            BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'الوردية'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
          ],
        ),
      ),
    );
  }
}

// ----------------- 1. شاشة الأجهزة -----------------
class DevicesDashboardScreen extends StatefulWidget {
  const DevicesDashboardScreen({super.key});

  @override
  State<DevicesDashboardScreen> createState() => _DevicesDashboardScreenState();
}

class _DevicesDashboardScreenState extends State<DevicesDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  int _calculateElapsedSeconds(Map<String, dynamic> device) {
    bool isActive = device['isActive'] ?? false;
    int previousSeconds = (device['elapsedSeconds'] ?? 0).toInt();

    if (!isActive) return previousSeconds;

    Timestamp? startTimeTs = device['startTime'] as Timestamp?;
    if (startTimeTs == null) return previousSeconds;

    DateTime startTime = startTimeTs.toDate();
    int currentRunSeconds = DateTime.now().difference(startTime).inSeconds;

    return previousSeconds + currentRunSeconds;
  }

  String formatTime(int seconds) {
    final dur = Duration(seconds: seconds < 0 ? 0 : seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(dur.inHours)}:${twoDigits(dur.inMinutes.remainder(60))}:${twoDigits(dur.inSeconds.remainder(60))}";
  }

  double calculateCost(Map<String, dynamic> device, Map<String, dynamic> rates, int totalSeconds) {
    if (totalSeconds <= 0) return 0.0;

    double hourlyRate = 0;
    bool isMulti = device['isMulti'] ?? false;
    String type = device['type'] ?? 'PS4';

    if (type == 'PS4') {
      hourlyRate = isMulti ? (rates['ps4MultiRate'] ?? 40.0) : (rates['ps4SingleRate'] ?? 25.0);
    } else {
      hourlyRate = isMulti ? (rates['ps5MultiRate'] ?? 60.0) : (rates['ps5SingleRate'] ?? 40.0);
    }

    return (totalSeconds / 3600.0) * hourlyRate;
  }

  void _toggleDeviceState(String docId, Map<String, dynamic> device) async {
    bool isActive = device['isActive'] ?? false;

    if (!isActive) {
      await _db.collection('devices').doc(docId).update({
        'isActive': true,
        'startTime': FieldValue.serverTimestamp(),
      });
    } else {
      int totalSeconds = _calculateElapsedSeconds(device);
      await _db.collection('devices').doc(docId).update({
        'isActive': false,
        'elapsedSeconds': totalSeconds,
        'startTime': null,
      });
    }
  }

  void _showAddDeviceDialog() {
    String name = '';
    String type = 'PS4';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('إضافة جهاز جديد 🎮'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'اسم الجهاز'),
              onChanged: (val) => name = val,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: 'PS4', child: Text('PS4')),
                DropdownMenuItem(value: 'PS5', child: Text('PS5')),
              ],
              onChanged: (val) => type = val!,
              decoration: const InputDecoration(labelText: 'نوع الجهاز'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () {
              if (name.isNotEmpty) {
                _db.collection('devices').add({
                  'name': name,
                  'type': type,
                  'isActive': false,
                  'isMulti': false,
                  'elapsedSeconds': 0,
                  'startTime': null,
                });
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _deleteDevice(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('حذف $name؟', style: const TextStyle(color: Colors.redAccent)),
        content: const Text('هل أنت تأكد من إزالة هذا الجهاز؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _db.collection('devices').doc(docId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(String docId, Map<String, dynamic> device, int totalSeconds, double calculatedCost) {
    TextEditingController priceController = TextEditingController(text: calculatedCost.toStringAsFixed(2));
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: Text('إنهاء جلسة: ${device['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الوقت المنقضي: ${formatTime(totalSeconds)}'),
                const SizedBox(height: 5),
                Text('السعر المحسوب: ${calculatedCost.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 15),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ النهائي (ج.م)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  items: const [
                    DropdownMenuItem(value: 'كاش', child: Text('كاش')),
                    DropdownMenuItem(value: 'فيزا/محفظة', child: Text('فيزا/فودافون كاش')),
                  ],
                  onChanged: (val) => setDialogState(() => paymentMethod = val!),
                  decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                onPressed: () async {
                  double finalAmount = double.tryParse(priceController.text) ?? calculatedCost;

                  var activeShift = await _db.collection('shifts').where('isOpen', isEqualTo: true).get();
                  String? shiftId = activeShift.docs.isNotEmpty ? activeShift.docs.first.id : null;

                  await _db.collection('invoices').add({
                    'deviceName': device['name'],
                    'durationSeconds': totalSeconds,
                    'calculatedAmount': calculatedCost,
                    'finalAmount': finalAmount,
                    'paymentMethod': paymentMethod,
                    'shiftId': shiftId,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  await _db.collection('devices').doc(docId).update({
                    'isActive': false,
                    'elapsedSeconds': 0,
                    'startTime': null,
                    'isMulti': false,
                  });

                  if (mounted) Navigator.pop(context);
                },
                child: const Text('إنهاء وتسجيل الفاتورة'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('settings').doc('rates').snapshots(),
      builder: (context, ratesSnap) {
        Map<String, dynamic> rates = {
          'ps4SingleRate': 25.0,
          'ps4MultiRate': 40.0,
          'ps5SingleRate': 40.0,
          'ps5MultiRate': 60.0,
        };
        if (ratesSnap.hasData && ratesSnap.data!.data() != null) {
          rates = ratesSnap.data!.data() as Map<String, dynamic>;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.8),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/logo.jpg',
                    height: 35,
                    width: 35,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.sports_esports, color: Color(0xFF6C5CE7)),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('Manga PS', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6C5CE7), size: 28), onPressed: _showAddDeviceDialog),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('devices').snapshots(),
            builder: (context, devicesSnap) {
              if (devicesSnap.hasError) return Center(child: Text("خطأ: ${devicesSnap.error}"));
              if (!devicesSnap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));

              final docs = devicesSnap.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("اضغط + من الأعلى لإضافة جهاز جديد", style: TextStyle(color: Colors.white)));

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  var device = docs[i].data() as Map<String, dynamic>;
                  String docId = docs[i].id;
                  bool isActive = device['isActive'] ?? false;
                  bool isMulti = device['isMulti'] ?? false;

                  int totalSeconds = _calculateElapsedSeconds(device);
                  double cost = calculateCost(device, rates, totalSeconds);

                  return Card(
                    color: const Color(0xFF1E1E1E).withOpacity(0.85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: isActive ? const Color(0xFF6C5CE7) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(device['name'] ?? 'جهاز', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteDevice(docId, device['name'] ?? 'الجهاز'),
                              ),
                            ],
                          ),
                          Text(
                            device['type'] ?? 'PS4',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          Column(
                            children: [
                              Text(
                                formatTime(totalSeconds),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? const Color(0xFF6C5CE7) : Colors.white,
                                ),
                              ),
                              Text(
                                '${cost.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(fontSize: 15, color: Colors.greenAccent, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('فردي', style: TextStyle(fontSize: 11)),
                                selected: !isMulti,
                                onSelected: (val) => _db.collection('devices').doc(docId).update({'isMulti': false}),
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: const Text('زوجي', style: TextStyle(fontSize: 11)),
                                selected: isMulti,
                                onSelected: (val) => _db.collection('devices').doc(docId).update({'isMulti': true}),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isActive ? Colors.orangeAccent : const Color(0xFF6C5CE7),
                                  ),
                                  onPressed: () => _toggleDeviceState(docId, device),
                                  child: Text(isActive ? 'إيقاف' : 'تشغيل', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              if (isActive || totalSeconds > 0) ...[
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => _showCheckoutDialog(docId, device, totalSeconds, cost),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.greenAccent),
                                    ),
                                    child: const Icon(Icons.receipt_long, color: Colors.greenAccent, size: 20),
                                  ),
                                )
                              ]
                            ],
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

// ----------------- 2. شاشة المصروفات -----------------
class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _showAddExpenseDialog() {
    String title = '';
    double amount = 0;
    String category = 'صيانة';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('تسجيل مصروف جديد 💸'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'بند المصروف'),
              onChanged: (val) => title = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => amount = double.tryParse(val) ?? 0,
            ),
            DropdownButtonFormField<String>(
              value: category,
              items: const [
                DropdownMenuItem(value: 'صيانة', child: Text('صيانة')),
                DropdownMenuItem(value: 'فواتير', child: Text('فواتير / كهرباء')),
                DropdownMenuItem(value: 'مشروبات', child: Text('مقتنيات ومشروبات')),
                DropdownMenuItem(value: 'أخرى', child: Text('أخرى')),
              ],
              onChanged: (val) => category = val!,
              decoration: const InputDecoration(labelText: 'الفئة'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () async {
              if (title.isNotEmpty && amount > 0) {
                var activeShift = await _db.collection('shifts').where('isOpen', isEqualTo: true).get();
                String? shiftId = activeShift.docs.isNotEmpty ? activeShift.docs.first.id : null;

                await _db.collection('expenses').add({
                  'title': title,
                  'amount': amount,
                  'category': category,
                  'shiftId': shiftId,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.8),
        title: const Text('المصروفات 💸'),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF6C5CE7), size: 28), onPressed: _showAddExpenseDialog),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('expenses').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));

          var docs = snapshot.data!.docs.toList();
          if (docs.isEmpty) return const Center(child: Text("لا توجد مصروفات مسجلة"));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var exp = docs[i].data() as Map<String, dynamic>;
              return Card(
                color: const Color(0xFF1E1E1E).withOpacity(0.85),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(exp['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('الفئة: ${exp['category']}'),
                  trailing: Text('${exp['amount']} ج.م', style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------- 3. شاشة التقارير -----------------
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isMonthly = false;

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'غير محدد';
    DateTime dt = ts.toDate();
    return "${dt.year}/${dt.month}/${dt.day} (${dt.hour}:${dt.minute.toString().padLeft(2, '0')})";
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startPeriod = isMonthly
        ? DateTime(now.year, now.month, 1, 0, 0, 0)
        : getBusinessDayStart(now);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.8),
        title: const Text('التقارير الحسابية 📊'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('تقرير اليوم'),
                  selected: !isMonthly,
                  onSelected: (val) => setState(() => isMonthly = false),
                ),
                const SizedBox(width: 15),
                ChoiceChip(
                  label: const Text('تقرير الشهر (ملخص الورديات)'),
                  selected: isMonthly,
                  onSelected: (val) => setState(() => isMonthly = true),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: isMonthly
                  ? _buildMonthlySummaryReport(startPeriod)
                  : _buildDailyDetailedReport(startPeriod),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryReport(DateTime startPeriod) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('shifts').where('isOpen', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));

        var shiftDocs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          Timestamp? ts = data['startTime'] as Timestamp?;
          if (ts == null) return false;
          return ts.toDate().isAfter(startPeriod);
        }).toList();

        shiftDocs.sort((a, b) {
          var tsA = (a.data() as Map<String, dynamic>)['startTime'] as Timestamp?;
          var tsB = (b.data() as Map<String, dynamic>)['startTime'] as Timestamp?;
          if (tsA == null) return 1;
          if (tsB == null) return -1;
          return tsB.compareTo(tsA);
        });

        double totalMonthIncome = 0;
        double totalMonthExpenses = 0;

        for (var doc in shiftDocs) {
          var data = doc.data() as Map<String, dynamic>;
          totalMonthIncome += (data['totalIncome'] ?? 0).toDouble();
          totalMonthExpenses += (data['totalExpenses'] ?? 0).toDouble();
        }

        double totalMonthNet = totalMonthIncome - totalMonthExpenses;

        return ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withOpacity(0.85),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF6C5CE7)),
              ),
              child: Column(
                children: [
                  const Text('إجمالي أرباح الشهر', style: TextStyle(fontSize: 15, color: Colors.grey)),
                  const SizedBox(height: 5),
                  Text('${totalMonthNet.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('الدخل: ${totalMonthIncome.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      Text('المصاريف: ${totalMonthExpenses.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text('ملخص ورديات الشهر (${shiftDocs.length}) 📜', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7))),
            const SizedBox(height: 10),
            if (shiftDocs.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("لا توجد ورديات مغلقة هذا الشهر")))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shiftDocs.length,
                itemBuilder: (context, i) {
                  var shift = shiftDocs[i].data() as Map<String, dynamic>;
                  double inc = (shift['totalIncome'] ?? 0).toDouble();
                  double exp = (shift['totalExpenses'] ?? 0).toDouble();
                  double net = (shift['netProfit'] ?? 0).toDouble();

                  return Card(
                    color: const Color(0xFF1E1E1E).withOpacity(0.85),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_formatTimestamp(shift['startTime'] as Timestamp?), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('دخل: ${inc.toStringAsFixed(1)} | مصاريف: ${exp.toStringAsFixed(1)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          Text(
                            'الصافي: ${net.toStringAsFixed(1)} ج.م',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildDailyDetailedReport(DateTime startPeriod) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('invoices').snapshots(),
      builder: (context, invoicesSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: _db.collection('expenses').snapshots(),
          builder: (context, expensesSnap) {
            if (!invoicesSnap.hasData || !expensesSnap.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));
            }

            final invoices = invoicesSnap.data!.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              Timestamp? ts = data['timestamp'] as Timestamp?;
              if (ts == null) return false;
              return ts.toDate().isAfter(startPeriod);
            }).toList();

            double totalIncome = 0;
            for (var doc in invoices) {
              totalIncome += ((doc.data() as Map<String, dynamic>)['finalAmount'] ?? 0).toDouble();
            }

            final expenses = expensesSnap.data!.docs.where((doc) {
              var data = doc.data() as Map<String, dynamic>;
              Timestamp? ts = data['timestamp'] as Timestamp?;
              if (ts == null) return false;
              return ts.toDate().isAfter(startPeriod);
            }).toList();

            double totalExpenses = 0;
            for (var doc in expenses) {
              totalExpenses += ((doc.data() as Map<String, dynamic>)['amount'] ?? 0).toDouble();
            }

            double netProfit = totalIncome - totalExpenses;

            return ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withOpacity(0.85),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      const Text('صافي أرباح اليوم', style: TextStyle(fontSize: 15, color: Colors.grey)),
                      const SizedBox(height: 5),
                      Text('${netProfit.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: const Color(0xFF1E1E1E).withOpacity(0.85),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Text('إجمالي الدخل', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('${totalIncome.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 15, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        color: const Color(0xFF1E1E1E).withOpacity(0.85),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Text('إجمالي المصروفات', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('${totalExpenses.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 15, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ----------------- 4. شاشة الورديات -----------------
class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _startShift() {
    TextEditingController cashCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('فتح وردية جديدة ⏱️'),
        content: TextField(
          controller: cashCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'مبلغ درج الكاش للبداية'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
            onPressed: () async {
              await _db.collection('shifts').add({
                'isOpen': true,
                'startCash': double.tryParse(cashCtrl.text) ?? 0,
                'startTime': FieldValue.serverTimestamp(),
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('بدء الوردية'),
          ),
        ],
      ),
    );
  }

  void _closeShift(String shiftId, double totalIncome, double totalExpenses, double netCashInDrawer) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('تأكيد إغلاق الوردية', style: TextStyle(color: Colors.redAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إجمالي الدخل: ${totalIncome.toStringAsFixed(2)} ج.م'),
            Text('إجمالي المصروفات: ${totalExpenses.toStringAsFixed(2)} ج.م'),
            const Divider(),
            Text('الصافي المتوقع بالدرج: ${netCashInDrawer.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _db.collection('shifts').doc(shiftId).update({
                'isOpen': false,
                'endTime': FieldValue.serverTimestamp(),
                'totalIncome': totalIncome,
                'totalExpenses': totalExpenses,
                'netProfit': totalIncome - totalExpenses,
                'expectedDrawerCash': netCashInDrawer,
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('إغلاق الوردية'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.8),
        title: const Text('إدارة الورديات ⏱️'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('shifts').where('isOpen', isEqualTo: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF6C5CE7)));

            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('لا توجد وردية مفتوحة حالياً', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                      onPressed: _startShift,
                      child: const Text('فتح وردية جديدة'),
                    )
                  ],
                ),
              );
            }

            var shiftData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
            String shiftId = snapshot.data!.docs.first.id;
            double startCash = (shiftData['startCash'] ?? 0).toDouble();

            return StreamBuilder<QuerySnapshot>(
              stream: _db.collection('invoices').where('shiftId', isEqualTo: shiftId).snapshots(),
              builder: (context, invoicesSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('expenses').where('shiftId', isEqualTo: shiftId).snapshots(),
                  builder: (context, expensesSnap) {
                    double currentIncome = 0;
                    double currentExpenses = 0;

                    if (invoicesSnap.hasData) {
                      for (var doc in invoicesSnap.data!.docs) {
                        currentIncome += ((doc.data() as Map<String, dynamic>)['finalAmount'] ?? 0).toDouble();
                      }
                    }

                    if (expensesSnap.hasData) {
                      for (var doc in expensesSnap.data!.docs) {
                        currentExpenses += ((doc.data() as Map<String, dynamic>)['amount'] ?? 0).toDouble();
                      }
                    }

                    double netProfit = currentIncome - currentExpenses;
                    double netDrawerCash = startCash + netProfit;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('الوردية الحالية نشطة 🟢', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                          const SizedBox(height: 10),
                          Text('عهد البداية: $startCash ج.م'),
                          const Divider(),
                          Text('الدخل: ${currentIncome.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.greenAccent)),
                          Text('المصروفات: ${currentExpenses.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.redAccent)),
                          Text('الصافي بالدرج: ${netDrawerCash.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                            onPressed: () => _closeShift(shiftId, currentIncome, currentExpenses, netDrawerCash),
                            child: const Text('إغلاق الوردية'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ----------------- 5. شاشة إعدادات الأسعار -----------------
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _ps4SingleCtrl = TextEditingController();
  final TextEditingController _ps4MultiCtrl = TextEditingController();
  final TextEditingController _ps5SingleCtrl = TextEditingController();
  final TextEditingController _ps5MultiCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.8),
        title: const Text('إعدادات الأسعار ⚙️'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('settings').doc('rates').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.data() != null) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            _ps4SingleCtrl.text = (data['ps4SingleRate'] ?? 25.0).toString();
            _ps4MultiCtrl.text = (data['ps4MultiRate'] ?? 40.0).toString();
            _ps5SingleCtrl.text = (data['ps5SingleRate'] ?? 40.0).toString();
            _ps5MultiCtrl.text = (data['ps5MultiRate'] ?? 60.0).toString();
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                const Text('أسعار ساعة PS4', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(controller: _ps4SingleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الفردي')),
                TextField(controller: _ps4MultiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الزوجي')),
                const Divider(height: 30),
                const Text('أسعار ساعة PS5', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(controller: _ps5SingleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الفردي')),
                TextField(controller: _ps5MultiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الزوجي')),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C5CE7)),
                  onPressed: () {
                    _db.collection('settings').doc('rates').set({
                      'ps4SingleRate': double.tryParse(_ps4SingleCtrl.text) ?? 25.0,
                      'ps4MultiRate': double.tryParse(_ps4MultiCtrl.text) ?? 40.0,
                      'ps5SingleRate': double.tryParse(_ps5SingleCtrl.text) ?? 40.0,
                      'ps5MultiRate': double.tryParse(_ps5MultiCtrl.text) ?? 60.0,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الأسعار بنجاح!')));
                  },
                  child: const Text('حفظ الأسعار'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
 
