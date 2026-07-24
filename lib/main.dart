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
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.purpleAccent,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'الأجهزة'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'المصروفات'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

// ----------------- 1. شاشة إدارة الأجهزة والجلسات -----------------
class DevicesDashboardScreen extends StatefulWidget {
  const DevicesDashboardScreen({super.key});

  @override
  State<DevicesDashboardScreen> createState() => _DevicesDashboardScreenState();
}

class _DevicesDashboardScreenState extends State<DevicesDashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
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
        debugPrint("Timer Error: $e");
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  void _showCheckoutDialog(String docId, Map<String, dynamic> device, double calculatedCost) {
    TextEditingController discountController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          double discount = double.tryParse(discountController.text) ?? 0.0;
          double finalAmount = (calculatedCost - discount) < 0 ? 0 : (calculatedCost - discount);

          return AlertDialog(
            title: Text('إنهاء جلسة: ${device['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المدُة: ${formatTime(device['elapsedSeconds'] ?? 0)}'),
                Text('الحساب الأساسي: ${calculatedCost.toStringAsFixed(2)} ج.م'),
                const SizedBox(height: 15),
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'خصم / تعديل فاتورة (ج.م)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => setDialogState(() {}),
                ),
                const SizedBox(height: 15),
                Text(
                  'المبلغ النهائي: ${finalAmount.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: () async {
                  // حفظ الفاتورة في السجل
                  await _db.collection('invoices').add({
                    'deviceName': device['name'],
                    'durationSeconds': device['elapsedSeconds'],
                    'originalAmount': calculatedCost,
                    'discount': discount,
                    'finalAmount': finalAmount,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  // إعادة تصفير الجهاز وإيقافه
                  await _db.collection('devices').doc(docId).update({
                    'isActive': false,
                    'elapsedSeconds': 0,
                    'isMulti': false,
                  });

                  Navigator.pop(context);
                },
                child: const Text('إنهاء الفاتورة وحفظ'),
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
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  var device = docs[i].data() as Map<String, dynamic>;
                  String docId = docs[i].id;
                  bool isActive = device['isActive'] ?? false;
                  bool isMulti = device['isMulti'] ?? false;
                  double cost = calculateCost(device, rates);

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(device['name'] ?? 'جهاز', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Chip(label: Text(device['type'] ?? 'PS4'), padding: EdgeInsets.zero),
                            ],
                          ),
                          Text(
                            formatTime(device['elapsedSeconds'] ?? 0),
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isActive ? Colors.greenAccent : Colors.grey),
                          ),
                          Text('${cost.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 16, color: Colors.amber)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('فردي'),
                                selected: !isMulti,
                                onSelected: (val) {
                                  _db.collection('devices').doc(docId).update({'isMulti': false});
                                },
                              ),
                              const SizedBox(width: 5),
                              ChoiceChip(
                                label: const Text('زوجي'),
                                selected: isMulti,
                                onSelected: (val) {
                                  _db.collection('devices').doc(docId).update({'isMulti': true});
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.orange : Colors.green),
                                  onPressed: () {
                                    _db.collection('devices').doc(docId).update({'isActive': !isActive});
                                  },
                                  child: Text(isActive ? 'إيقاف' : 'تشغيل'),
                                ),
                              ),
                              if (isActive || (device['elapsedSeconds'] ?? 0) > 0) ...[
                                const SizedBox(width: 5),
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.purpleAccent),
                                  onPressed: () => _showCheckoutDialog(docId, device, cost),
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

// ----------------- 2. شاشة المصروفات والإنفاق -----------------
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
              decoration: const InputDecoration(labelText: 'بند المصروف (مثال: دراعات/كهرباء)'),
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
            onPressed: () {
              if (title.isNotEmpty && amount > 0) {
                _db.collection('expenses').add({
                  'title': title,
                  'amount': amount,
                  'category': category,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
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

// ----------------- 3. شاشة إعدادات الأسعار -----------------
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
 
