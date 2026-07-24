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
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardTheme(
          color: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        apiKey: "AIzaSyCY8JW1ZEpzcvS...", // 👈 ضع المفتاح الكامل هنا
        appId: "1:49681326088:android:...", // 👈 ضع الـ App ID الكامل هنا
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
          return const MainNavigationScreen();
        }

        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.purpleAccent),
                SizedBox(height: 20),
                Text("جاري تحميل Manga PS..."),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.purpleAccent,
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
    double rate = 0;
    bool isMulti = device['isMulti'] ?? false;
    String type = device['type'] ?? 'PS4';

    if (type == 'PS4') {
      rate = isMulti ? (rates['ps4MultiRate'] ?? 40.0) : (rates['ps4SingleRate'] ?? 25.0);
    } else {
      rate = isMulti ? (rates['ps5MultiRate'] ?? 60.0) : (rates['ps5SingleRate'] ?? 40.0);
    }
    return (totalSeconds / 3600.0) * rate;
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
        title: const Text('إضافة جهاز جديد'),
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
        title: Text('حذف $name؟'),
        content: const Text('هل أنت تأكد من إزالة هذا الجهاز نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            title: Text('إنهاء جلسة: ${device['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الوقت المنقضي: ${formatTime(totalSeconds)}'),
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
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
            title: const Text('Manga PS 🎮'),
            actions: [
              IconButton(icon: const Icon(Icons.add), onPressed: _showAddDeviceDialog),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('devices').snapshots(),
            builder: (context, devicesSnap) {
              if (devicesSnap.hasError) return Center(child: Text("خطأ: ${devicesSnap.error}"));
              if (!devicesSnap.hasData) return const Center(child: CircularProgressIndicator());

              final docs = devicesSnap.data!.docs;
              if (docs.isEmpty) return const Center(child: Text("اضغط + من الأعلى لإضافة جهاز جديد"));

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
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
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(device['name'] ?? 'جهاز', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => _deleteDevice(docId, device['name'] ?? 'الجهاز'),
                              ),
                            ],
                          ),
                          Chip(label: Text(device['type'] ?? 'PS4'), padding: EdgeInsets.zero),
                          Text(
                            formatTime(totalSeconds),
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isActive ? Colors.greenAccent : Colors.grey),
                          ),
                          Text('${cost.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 16, color: Colors.amber, fontWeight: FontWeight.bold)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('فردي', style: TextStyle(fontSize: 12)),
                                selected: !isMulti,
                                onSelected: (val) => _db.collection('devices').doc(docId).update({'isMulti': false}),
                              ),
                              const SizedBox(width: 4),
                              ChoiceChip(
                                label: const Text('زوجي', style: TextStyle(fontSize: 12)),
                                selected: isMulti,
                                onSelected: (val) => _db.collection('devices').doc(docId).update({'isMulti': true}),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.orange : Colors.green),
                                  onPressed: () => _toggleDeviceState(docId, device),
                                  child: Text(isActive ? 'إيقاف' : 'تشغيل', style: const TextStyle(fontSize: 12)),
                                ),
                              ),
                              if (isActive || totalSeconds > 0) ...[
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.receipt_long, color: Colors.purpleAccent),
                                  onPressed: () => _showCheckoutDialog(docId, device, totalSeconds, cost),
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
        title: const Text('تسجيل مصروف جديد'),
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
        title: const Text('سجل المصروفات 💸'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _showAddExpenseDialog),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('expenses').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text("لا توجد مصروفات مسجلة"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var exp = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.money_off)),
                title: Text(exp['title'] ?? ''),
                subtitle: Text('الفئة: ${exp['category']}'),
                trailing: Text('${exp['amount']} ج.م', style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              );
            },
          );
        },
      ),
    );
  }
}

// ----------------- 3. شاشة التقارير مع تعديل وحذف الفواتير -----------------
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
            title: Text('تعديل فاتورة: ${invoice['deviceName'] ?? ''}'),
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
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  await _db.collection('invoices').doc(docId).delete();
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('حذف الفاتورة'),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
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
        ? DateTime(now.year, now.month, 1)
        : DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير الحسابية والفواتير 📊')),
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
                  label: const Text('تقرير الشهر'),
                  selected: isMonthly,
                  onSelected: (val) => setState(() => isMonthly = true),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('invoices').where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startPeriod)).orderBy('timestamp', descending: true).snapshots(),
                builder: (context, invoicesSnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _db.collection('expenses').where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startPeriod)).snapshots(),
                    builder: (context, expensesSnap) {
                      if (!invoicesSnap.hasData || !expensesSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      double totalIncome = 0;
                      double cashIncome = 0;
                      double visaIncome = 0;

                      final invoices = invoicesSnap.data!.docs;

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

                      double totalExpenses = 0;
                      for (var doc in expensesSnap.data!.docs) {
                        var data = doc.data() as Map<String, dynamic>;
                        totalExpenses += (data['amount'] ?? 0).toDouble();
                      }

                      double netProfit = totalIncome - totalExpenses;

                      return ListView(
                        children: [
                          Card(
                            color: Colors.purple.shade900,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Text(isMonthly ? 'صافي أرباح الشهر' : 'صافي أرباح اليوم', style: const TextStyle(fontSize: 18)),
                                  const SizedBox(height: 10),
                                  Text('${netProfit.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        const Text('إجمالي الدخل', style: TextStyle(fontSize: 12)),
                                        Text('${totalIncome.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
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
                                        const Text('إجمالي المصروفات', style: TextStyle(fontSize: 12)),
                                        Text('${totalExpenses.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 16, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 25),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('سجل الفواتير (${invoices.length}) 🧾', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
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
                                      backgroundColor: inv['paymentMethod'] == 'فيزا/محفظة' ? Colors.blue.shade800 : Colors.green.shade800,
                                      child: Icon(inv['paymentMethod'] == 'فيزا/محفظة' ? Icons.credit_card : Icons.money, size: 20, color: Colors.white),
                                    ),
                                    title: Text(inv['deviceName'] ?? 'جهاز'),
                                    subtitle: Text('المدة: ${_formatDuration(inv['durationSeconds'] ?? 0)} • ${inv['paymentMethod']}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('${inv['finalAmount']} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber)),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18, color: Colors.purpleAccent),
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
        title: const Text('فتح وردية جديدة'),
        content: TextField(
          controller: cashCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'مبلغ درج الكاش للبداية (الدرج)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
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
        title: const Text('تأكيد إغلاق الوردية'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        title: const Text('إدارة والورديات ⏱️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.purpleAccent),
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
                if (!snapshot.hasData) return const CircularProgressIndicator();

                if (snapshot.data!.docs.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text('لا توجد وردية مفتوحة حالياً', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
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

                        return Card(
                          color: Colors.green.shade900,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text('الوردية الحالية نشطة 🟢', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text('بداية الوردية: ${_formatTimestamp(shiftData['startTime'] as Timestamp?)}'),
                                Text('عهد البداية: $startCash ج.م'),
                                const Divider(height: 20, color: Colors.white24),
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
                                        Text('${netDrawerCash.toStringAsFixed(2)} ج.م', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => _closeShift(shiftId, currentIncome, currentExpenses, netDrawerCash),
                                  child: const Text('إغلاق وتسليم الوردية'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? 'سجل الورديات السابقة 📜'
                      : 'تصفية تاريخ: ${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                ),
              ],
            ),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('shifts').where('isOpen', isEqualTo: false).orderBy('startTime', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs;

                if (_selectedDate != null) {
                  docs = docs.where((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    Timestamp? ts = data['startTime'] as Timestamp?;
                    if (ts == null) return false;
                    DateTime dt = ts.toDate();
                    return dt.year == _selectedDate!.year && dt.month == _selectedDate!.month && dt.day == _selectedDate!.day;
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
                        leading: const CircleAvatar(child: Icon(Icons.history)),
                        title: Text('بداية: ${_formatTimestamp(shift['startTime'] as Timestamp?)}'),
                        subtitle: Text('الصافي: $net ج.م  |  المصروفات: $totalExp ج.م'),
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
                                    Text('المصروفات المخصومة: $totalExp ج.م', style: const TextStyle(color: Colors.redAccent)),
                                    Text('صافي الدرج عند الغلق: ${shift['expectedDrawerCash'] ?? 0} ج.م', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(title: const Text('إعدادات الأسعار ⚙️')),
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
                const Text('أسعار ساعة PS4 (بالجنيه المصري)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                const SizedBox(height: 10),
                TextField(controller: _ps4SingleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الفردي (Single)')),
                TextField(controller: _ps4MultiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر المتعدد (Multi)')),
                const Divider(height: 30),
                const Text('أسعار ساعة PS5 (بالجنيه المصري)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purpleAccent)),
                const SizedBox(height: 10),
                TextField(controller: _ps5SingleCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر الفردي (Single)')),
                TextField(controller: _ps5MultiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر المتعدد (Multi)')),
                const SizedBox(height: 30),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.all(15)),
                  onPressed: () {
                    _db.collection('settings').doc('rates').set({
                      'ps4SingleRate': double.tryParse(_ps4SingleCtrl.text) ?? 25.0,
                      'ps4MultiRate': double.tryParse(_ps4MultiCtrl.text) ?? 40.0,
                      'ps5SingleRate': double.tryParse(_ps5SingleCtrl.text) ?? 40.0,
                      'ps5MultiRate': double.tryParse(_ps5MultiCtrl.text) ?? 60.0,
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الأسعار بنجاح!')));
                  },
                  child: const Text('حفظ الأسعار الجديدة', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
