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

// دالة حساب بداية اليوم الحسابي (12 ظهراً)
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
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E17), // أسود نيون غامق
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF), // Cyan Neon
          secondary: Color(0xFFFF007F), // Pink Neon
          surface: Color(0xFF131927),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF131927),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF1F293D), width: 1.5),
          ),
        ),
      ),
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
          return Scaffold(
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
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return const MainNavigationScreen();
        }

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.5), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: const CircularProgressIndicator(color: Color(0xFF00E5FF), strokeWidth: 3),
                ),
                const SizedBox(height: 25),
                const Text(
                  "MANGA PS",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF), letterSpacing: 3),
                ),
              ],
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
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.15), blurRadius: 20, spreadRadius: 1),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF0D121D),
          selectedItemColor: const Color(0xFF00E5FF),
          unselectedItemColor: Colors.grey.shade600,
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

// ----------------- 1. شاشة الأجهزة (Cyberpunk Neon) -----------------
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

  // ⚡ حساب التكلفة بناءً على سعر الربع ساعة (Quarter Hours Calculation)
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

    double quarterRate = hourlyRate / 4.0;
    
    // التقريب لأقرب ربع ساعة (15 دقيقة = 900 ثانية)
    int quarters = (totalSeconds / 900).ceil();

    return quarters * quarterRate;
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
        backgroundColor: const Color(0xFF131927),
        title: const Text('إضافة جهاز جديد 🎮', style: TextStyle(color: Color(0xFF00E5FF))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'اسم الجهاز (مثال: جهاز 1)'),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
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
        backgroundColor: const Color(0xFF131927),
        title: Text('حذف $name؟', style: const TextStyle(color: Colors.redAccent)),
        content: const Text('هل أنت تأكد من إزالة هذا الجهاز نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _db.collection('devices').doc(docId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('حذف الجهاز'),
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
            backgroundColor: const Color(0xFF131927),
            title: Text('إنهاء جلسة: ${device['name']}', style: const TextStyle(color: Color(0xFFFF007F))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الوقت المنقضي: ${formatTime(totalSeconds)}', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 5),
                Text('حساب الربع ساعة: ${calculatedCost.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ النهائي (تعديل السعر ج.م)',
                    border: OutlineInputBorder(),
                    suffixText: 'ج.م',
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  items: const [
                    DropdownMenuItem(value: 'كاش', child: Text('نقداً (كاش)')),
                    DropdownMenuItem(value: 'فيزا/محفظة', child: Text('دفع إلكتروني (فيزا/فودافون كاش)')),
                  ],
                  onChanged: (val) => setDialogState(() => paymentMethod = val!),
                  decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF007F), foregroundColor: Colors.white),
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
                child: const Text('حفظ وتسجيل الفاتورة'),
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
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D121D),
            title: const Text('MANGA PS 🎮', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, letterSpacing: 2)),
            actions: [
              IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00E5FF), size: 28), onPressed: _showAddDeviceDialog),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('devices').snapshots(),
            builder: (context, devicesSnap) {
              if (devicesSnap.hasError) return Center(child: Text("خطأ: ${devicesSnap.error}"));
              if (!devicesSnap.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));

              final docs = devicesSnap.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("اضغط + من الأعلى لإضافة جهاز جديد"));

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
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

                  Color activeNeonColor = isActive ? const Color(0xFF00E5FF) : const Color(0xFF1F293D);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131927),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? const Color(0xFF00E5FF) : Colors.white10,
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.3), blurRadius: 15, spreadRadius: 1),
                            ]
                          : [],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(device['name'] ?? 'جهاز', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteDevice(docId, device['name'] ?? 'الجهاز'),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: device['type'] == 'PS5' ? const Color(0xFFFF007F).withOpacity(0.2) : const Color(0xFF00E5FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              device['type'] ?? 'PS4',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: device['type'] == 'PS5' ? const Color(0xFFFF007F) : const Color(0xFF00E5FF),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                formatTime(totalSeconds),
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? const Color(0xFF00E5FF) : Colors.grey,
                                  shadows: isActive
                                      ? [const Shadow(color: Color(0xFF00E5FF), blurRadius: 10)]
                                      : [],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${cost.toStringAsFixed(2)} ج.م',
                                style: const TextStyle(fontSize: 16, color: Color(0xFFFFD700), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('فردي', style: TextStyle(fontSize: 11)),
                                selected: !isMulti,
                                selectedColor: const Color(0xFF00E5FF).withOpacity(0.3),
                                onSelected: (val) => _db.collection('devices').doc(docId).update({'isMulti': false}),
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: const Text('زوجي', style: TextStyle(fontSize: 11)),
                                selected: isMulti,
                                selectedColor: const Color(0xFFFF007F).withOpacity(0.3),
                                onSelected: (val) => _db.collection('devices').doc(docId).update({'isMulti': true}),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isActive ? Colors.orangeAccent : const Color(0xFF00E5FF),
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                      color: const Color(0xFFFF007F).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFFF007F)),
                                    ),
                                    child: const Icon(Icons.receipt_long, color: Color(0xFFFF007F), size: 20),
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
        backgroundColor: const Color(0xFF131927),
        title: const Text('تسجيل مصروف جديد 💸', style: TextStyle(color: Color(0xFFFF007F))),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF007F)),
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
            child: const Text('حفظ المصروف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D121D),
        title: const Text('سجل المصروفات 💸', style: TextStyle(color: Color(0xFFFF007F))),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF007F), size: 28), onPressed: _showAddExpenseDialog),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('expenses').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFF007F)));

          var docs = snapshot.data!.docs.toList();

          docs.sort((a, b) {
            var dataA = a.data() as Map<String, dynamic>;
            var dataB = b.data() as Map<String, dynamic>;
            Timestamp? tsA = dataA['timestamp'] as Timestamp?;
            Timestamp? tsB = dataB['timestamp'] as Timestamp?;
            if (tsA == null) return 1;
            if (tsB == null) return -1;
            return tsB.compareTo(tsA);
          });

          if (docs.isEmpty) return const Center(child: Text("لا توجد مصروفات مسجلة"));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var exp = docs[i].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Color(0xFF1F293D), child: Icon(Icons.money_off, color: Color(0xFFFF007F))),
                  title: Text(exp['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('الفئة: ${exp['category']}', style: const TextStyle(color: Colors.grey)),
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

// ----------------- 3. شاشة التقارير الحسابية -----------------
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool isMonthly = false;

  void _editInvoice(String docId, Map<String, dynamic> invoice) {
    TextEditingController amountCtrl = TextEditingController(text: (invoice['finalAmount'] ?? 0).toString());
    String method = invoice['paymentMethod'] ?? 'كاش';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF131927),
            title: Text('تعديل فاتورة: ${invoice['deviceName'] ?? ''}', style: const TextStyle(color: Color(0xFF00E5FF))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'المبلغ المعدل (ج.م)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: method,
                  items: const [
                    DropdownMenuItem(value: 'كاش', child: Text('نقداً (كاش)')),
                    DropdownMenuItem(value: 'فيزا/محفظة', child: Text('دفع إلكتروني (فيزا/فودافون كاش)')),
                  ],
                  onChanged: (val) => setDialogState(() => method = val!),
                  decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                ),
              ],
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: () async {
                  await _db.collection('invoices').doc(docId).delete();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('حذف الفاتورة'),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                onPressed: () async {
                  double? newAmount = double.tryParse(amountCtrl.text);
                  if (newAmount != null) {
                    await _db.collection('invoices').doc(docId).update({
                      'finalAmount': newAmount,
                      'paymentMethod': method,
                    });
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('تحديث'),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    int mins = (seconds / 60).round();
    return '$mins دقيقة';
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime startPeriod = isMonthly
        ? DateTime(now.year, now.month, 1, 0, 0, 0)
        : getBusinessDayStart(now);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D121D),
        title: const Text('التقارير الحسابية 📊', style: TextStyle(color: Color(0xFF00E5FF))),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('تقرير اليوم (12ظ - 12ظ)'),
                  selected: !isMonthly,
                  selectedColor: const Color(0xFF00E5FF).withOpacity(0.3),
                  onSelected: (val) => setState(() => isMonthly = false),
                ),
                const SizedBox(width: 15),
                ChoiceChip(
                  label: const Text('تقرير الشهر'),
                  selected: isMonthly,
                  selectedColor: const Color(0xFFFF007F).withOpacity(0.3),
                  onSelected: (val) => setState(() => isMonthly = true),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('invoices').snapshots(),
                builder: (context, invoicesSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _db.collection('expenses').snapshots(),
                    builder: (context, expensesSnap) {
                      if (!invoicesSnap.hasData || !expensesSnap.hasData) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
                      }

                      final invoices = invoicesSnap.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        Timestamp? ts = data['timestamp'] as Timestamp?;
                        if (ts == null) return false;
                        return ts.toDate().isAfter(startPeriod);
                      }).toList();

                      invoices.sort((a, b) {
                        var tsA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                        var tsB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                        if (tsA == null) return 1;
                        if (tsB == null) return -1;
                        return tsB.compareTo(tsA);
                      });

                      double totalIncome = 0;
                      double cashIncome = 0;
                      double visaIncome = 0;

                      for (var doc in invoices) {
                        var data = doc.data() as Map<String, dynamic>;
                        double amount = (data['finalAmount'] ?? 0).toDouble();
                        totalIncome += amount;
                        if (data['paymentMethod'] == 'فيزا/محفظة') {
                          visaIncome += amount;
                        } else {
                          cashIncome += amount;
                        }
                      }

                      final expenses = expensesSnap.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        Timestamp? ts = data['timestamp'] as Timestamp?;
                        if (ts == null) return false;
                        return ts.toDate().isAfter(startPeriod);
                      }).toList();

                      double totalExpenses = 0;
                      for (var doc in expenses) {
                        var data = doc.data() as Map<String, dynamic>;
                        totalExpenses += (data['amount'] ?? 0).toDouble();
                      }

                      double netProfit = totalIncome - totalExpenses;

                      return ListView(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF1F293D), Color(0xFF131927)]),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.5)),
                              boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.15), blurRadius: 15)],
                            ),
                            child: Column(
                              children: [
                                Text(isMonthly ? 'صافي أرباح الشهر' : 'صافي أرباح اليوم (من 12 ظهراً)', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                                const SizedBox(height: 10),
                                Text(
                                  '${netProfit.toStringAsFixed(2)} ج.م',
                                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        const Text('إجمالي الدخل', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text('${totalIncome.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 16, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        const Text('إجمالي المصروفات', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Text('${totalExpenses.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 30, color: Colors.white10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('سجل الفواتير (${invoices.length}) 🧾', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF007F))),
                              Text('كاش: $cashIncome | فيزا: $visaIncome', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (invoices.isEmpty)
                            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("لا توجد فواتير مسجلة للفترة")))
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: invoices.length,
                              itemBuilder: (context, index) {
                                var invDoc = invoices[index];
                                var inv = invDoc.data() as Map<String, dynamic>;
                                String invId = invDoc.id;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFF1F293D),
                                      child: Icon(inv['paymentMethod'] == 'فيزا/محفظة' ? Icons.credit_card : Icons.money, size: 20, color: const Color(0xFF00E5FF)),
                                    ),
                                    title: Text(inv['deviceName'] ?? 'جهاز', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('المدة: ${_formatDuration(inv['durationSeconds'] ?? 0)} • ${inv['paymentMethod']}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${inv['finalAmount']} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFFFD700))),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18, color: Color(0xFF00E5FF)),
                                          onPressed: () => _editInvoice(invId, inv),
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- 4. شاشة إدارة الورديات -----------------
class ShiftScreen extends StatefulWidget {
  const ShiftScreen({super.key});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DateTime? _selectedDate;

  void _startShift() {
    TextEditingController cashCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF131927),
        title: const Text('فتح وردية جديدة ⏱️', style: TextStyle(color: Color(0xFF00E5FF))),
        content: TextField(
          controller: cashCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'مبلغ درج الكاش للبداية (الدرج)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
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
        backgroundColor: const Color(0xFF131927),
        title: const Text('تأكيد إغلاق الوردية', style: TextStyle(color: Colors.redAccent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إجمالي الدخل: ${totalIncome.toStringAsFixed(2)} ج.م'),
            Text('إجمالي المصروفات: ${totalExpenses.toStringAsFixed(2)} ج.م'),
            const Divider(),
            Text('الصافي المتوقع بالدرج: ${netCashInDrawer.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
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
            child: const Text('إغلاق وتسليم الوردية'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return 'غير محدد';
    DateTime dt = ts.toDate();
    return "${dt.year}/${dt.month}/${dt.day}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D121D),
        title: const Text('إدارة الورديات ⏱️', style: TextStyle(color: Color(0xFF00E5FF))),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Color(0xFF00E5FF)),
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2023),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.redAccent),
              onPressed: () => setState(() => _selectedDate = null),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('shifts').where('isOpen', isEqualTo: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));

                if (snapshot.data!.docs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('لا توجد وردية مفتوحة حالياً', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF), foregroundColor: Colors.black),
                            onPressed: _startShift,
                            child: const Text('فتح وردية جديدة الآن'),
                          )
                        ],
                      ),
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
                            color: const Color(0xFF131927),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF00E5FF)),
                            boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.2), blurRadius: 15)],
                          ),
                          child: Column(
                            children: [
                              const Text('الوردية الحالية نشطة 🟢', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
                              const SizedBox(height: 5),
                              Text('بداية الوردية: ${_formatTimestamp(shiftData['startTime'] as Timestamp?)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('عهد البداية: $startCash ج.م', style: const TextStyle(fontSize: 13)),
                              const Divider(height: 20, color: Colors.white10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      const Text('الدخل', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('${currentIncome.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('المصروفات', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('${currentExpenses.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      const Text('الصافي بالدرج', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text('${netDrawerCash.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                onPressed: () => _closeShift(shiftId, currentIncome, currentExpenses, netDrawerCash),
                                child: const Text('إغلاق وتسليم الوردية'),
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

            const SizedBox(height: 25),
            Text(
              _selectedDate == null
                  ? 'سجل الورديات السابقة 📜'
                  : 'تصفية تاريخ: ${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF007F)),
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('shifts').where('isOpen', isEqualTo: false).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));

                var docs = snapshot.data!.docs.toList();

                docs.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  Timestamp? tsA = dataA['startTime'] as Timestamp?;
                  Timestamp? tsB = dataB['startTime'] as Timestamp?;
                  if (tsA == null) return 1;
                  if (tsB == null) return -1;
                  return tsB.compareTo(tsA);
                });

                if (_selectedDate != null) {
                  DateTime startFilter = getBusinessDayStart(_selectedDate!);
                  DateTime endFilter = startFilter.add(const Duration(hours: 24));

                  docs = docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    Timestamp? ts = data['startTime'] as Timestamp?;
                    if (ts == null) return false;
                    DateTime dt = ts.toDate();
                    return dt.isAfter(startFilter.subtract(const Duration(seconds: 1))) && dt.isBefore(endFilter);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(child: Text('لا توجد ورديات سابقة مسجلة')),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var shift = docs[i].data() as Map<String, dynamic>;
                    double totalInc = (shift['totalIncome'] ?? 0).toDouble();
                    double totalExp = (shift['totalExpenses'] ?? 0).toDouble();
                    double net = (shift['netProfit'] ?? 0).toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        leading: const CircleAvatar(backgroundColor: Color(0xFF1F293D), child: Icon(Icons.history, color: Color(0xFF00E5FF))),
                        title: Text('بداية: ${_formatTimestamp(shift['startTime'] as Timestamp?)}', style: const TextStyle(fontSize: 14)),
                        subtitle: Text('الصافي: $net ج.م  |  المصروفات: $totalExp ج.م', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('عهد البداية: ${shift['startCash'] ?? 0} ج.م'),
                                    Text('إجمالي الدخل: $totalInc ج.م', style: const TextStyle(color: Colors.greenAccent)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('المصروفات: $totalExp ج.م', style: const TextStyle(color: Colors.redAccent)),
                                    Text('صافي الدرج: ${shift['expectedDrawerCash'] ?? 0} ج.م', style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D121D),
        title: const Text('إعدادات الأسعار ⚙️', style: TextStyle(color: Color(0xFF00E5FF))),
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
                const Text('أسعار ساعة PS4 (بالجنيه المصري)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
                const SizedBox(height: 10),
                TextField(controller: _ps4SingleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الفردي (Single)')),
                TextField(controller: _ps4MultiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر المتعدد (Multi)')),
                const Divider(height: 30, color: Colors.white10),
                const Text('أسعار ساعة PS5 (بالجنيه المصري)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF007F))),
                const SizedBox(height: 10),
                TextField(controller: _ps5SingleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الفردي (Single)')),
                TextField(controller: _ps5MultiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر المتعدد (Multi)')),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.all(15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    _db.collection('settings').doc('rates').set({
                      'ps4SingleRate': double.tryParse(_ps4SingleCtrl.text) ?? 25.0,
                      'ps4MultiRate': double.tryParse(_ps4MultiCtrl.text) ?? 40.0,
                      'ps5SingleRate': double.tryParse(_ps5SingleCtrl.text) ?? 40.0,
                      'ps5MultiRate': double.tryParse(_ps5MultiCtrl.text) ?? 60.0,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الأسعار بنجاح!')));
                  },
                  child: const Text('حفظ الأسعار الجديدة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
 
