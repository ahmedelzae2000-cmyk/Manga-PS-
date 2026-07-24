import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const MangaPsApp());
}

class MangaPsApp extends StatelessWidget {
  const MangaPsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga PS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF673AB7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // مؤقت محلي لزيادة ثواني الأجهزة الشغالة وتحديث Firebase
    timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      final devicesSnap = await _db.collection('devices').get();
      for (var doc in devicesSnap.docs) {
        if (doc.data()['isActive'] == true) {
          _db.collection('devices').doc(doc.id).update({
            'elapsedSeconds': FieldValue.increment(1),
          });
        }
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

  void stopAndCheckout(String deviceId, Map<String, dynamic> device, Map<String, dynamic> rates) {
    double cost = calculateCost(device, rates);
    String selectedPayment = device['paymentMethod'] ?? 'كاش (نقداً)';

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('إنهاء جلسة ${device['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الوقت المستغرق: ${formatTime(device['elapsedSeconds'] ?? 0)}'),
              const SizedBox(height: 5),
              Text('المبلغ المستحق: ${cost.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              const SizedBox(height: 10),
              const Text('طريقة الدفع:'),
              DropdownButton<String>(
                value: selectedPayment,
                isExpanded: true,
                items: ['كاش (نقداً)', 'فيزا'].map((val) {
                  return DropdownMenuItem(value: val, child: Text(val));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedPayment = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                // إضافة المبلغ للإيراد المناسب
                String fieldToUpdate = (selectedPayment == 'كاش (نقداً)') ? 'totalCashRevenue' : 'totalVisaRevenue';
                await _db.collection('settings').doc('financials').set({
                  fieldToUpdate: FieldValue.increment(cost),
                }, SetOptions(merge: true));

                // إعادة تصفية الجهاز
                await _db.collection('devices').doc(deviceId).update({
                  'isActive': false,
                  'elapsedSeconds': 0,
                  'paymentMethod': 'كاش (نقداً)',
                });

                if (mounted) Navigator.pop(dialogContext);
              },
              child: const Text('تأكيد التحصيل والإغلاق', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void openDrawerMenu(Map<String, dynamic> rates) {
    final nameController = TextEditingController();
    String selectedType = 'PS4';

    final ps4SController = TextEditingController(text: (rates['ps4SingleRate'] ?? 25.0).toString());
    final ps4MController = TextEditingController(text: (rates['ps4MultiRate'] ?? 40.0).toString());
    final ps5SController = TextEditingController(text: (rates['ps5SingleRate'] ?? 40.0).toString());
    final ps5MController = TextEditingController(text: (rates['ps5MultiRate'] ?? 60.0).toString());

    final expTitleController = TextEditingController();
    final expAmountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('القائمة والإدارة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(sheetContext)),
                ],
              ),
              const Divider(),

              // تعديل الأسعار
              const Text('⚙️ أسعار الساعات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
              TextField(controller: ps4SController, decoration: const InputDecoration(labelText: 'سنجل PS4'), keyboardType: TextInputType.number),
              TextField(controller: ps4MController, decoration: const InputDecoration(labelText: 'ملتي PS4'), keyboardType: TextInputType.number),
              TextField(controller: ps5SController, decoration: const InputDecoration(labelText: 'سنجل PS5'), keyboardType: TextInputType.number),
              TextField(controller: ps5MController, decoration: const InputDecoration(labelText: 'ملتي PS5'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await _db.collection('settings').doc('rates').set({
                    'ps4SingleRate': double.tryParse(ps4SController.text) ?? 25.0,
                    'ps4MultiRate': double.tryParse(ps4MController.text) ?? 40.0,
                    'ps5SingleRate': double.tryParse(ps5SController.text) ?? 40.0,
                    'ps5MultiRate': double.tryParse(ps5MController.text) ?? 60.0,
                  });
                  if (mounted) Navigator.pop(sheetContext);
                },
                child: const Text('حفظ الأسعار في Firebase'),
              ),
              const Divider(height: 30),

              // إضافة جهاز
              const Text('➕ إضافة جهاز جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الجهاز (مثال: طاولة 3)')),
              DropdownButton<String>(
                value: selectedType,
                isExpanded: true,
                items: ['PS4', 'PS5'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) {
                  if (val != null) setSheetState(() => selectedType = val);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    await _db.collection('devices').add({
                      'name': nameController.text,
                      'type': selectedType,
                      'isActive': false,
                      'isMulti': false,
                      'elapsedSeconds': 0,
                      'paymentMethod': 'كاش (نقداً)',
                    });
                    if (mounted) Navigator.pop(sheetContext);
                  }
                },
                child: const Text('إضافة الجهاز', style: TextStyle(color: Colors.white)),
              ),
              const Divider(height: 30),

              // تسجيل مصروف
              const Text('💸 تسجيل مصروف جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
              TextField(controller: expTitleController, decoration: const InputDecoration(labelText: 'اسم المصروف')),
              TextField(controller: expAmountController, decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () async {
                  if (expTitleController.text.isNotEmpty && expAmountController.text.isNotEmpty) {
                    await _db.collection('expenses').add({
                      'title': expTitleController.text,
                      'amount': double.tryParse(expAmountController.text) ?? 0.0,
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    if (mounted) Navigator.pop(sheetContext);
                  }
                },
                child: const Text('تسجيل المصروف', style: TextStyle(color: Colors.white)),
              ),
              const Divider(height: 30),

              // تصفية إيرادات اليوم
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
                icon: const Icon(Icons.refresh, color: Colors.orange),
                label: const Text('بدء يوم جديد (تصفية الحسابات)', style: TextStyle(color: Colors.orange)),
                onPressed: () async {
                  await _db.collection('settings').doc('financials').set({
                    'totalCashRevenue': 0.0,
                    'totalVisaRevenue': 0.0,
                  });
                  // مسح المصاريف
                  var expensesDocs = await _db.collection('expenses').get();
                  for (var doc in expensesDocs.docs) {
                    await doc.reference.delete();
                  }
                  if (mounted) Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('settings').doc('rates').snapshots(),
      builder: (context, ratesSnap) {
        Map<String, dynamic> rates = ratesSnap.data?.data() as Map<String, dynamic>? ?? {
          'ps4SingleRate': 25.0,
          'ps4MultiRate': 40.0,
          'ps5SingleRate': 40.0,
          'ps5MultiRate': 60.0,
        };

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manga PS 🎮'),
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.pinkAccent),
              onPressed: () => openDrawerMenu(rates),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // عرض الأجهزة لحظياً من Firebase
              StreamBuilder<QuerySnapshot>(
                stream: _db.collection('devices').snapshots(),
                builder: (context, devicesSnap) {
                  if (!devicesSnap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = devicesSnap.data!.docs;

                  return Column(
                    children: docs.map((doc) {
                      var device = doc.data() as Map<String, dynamic>;
                      String docId = doc.id;
                      bool isActive = device['isActive'] ?? false;
                      bool isMulti = device['isMulti'] ?? false;
                      double currentCost = calculateCost(device, rates);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Chip(
                                    label: Text(device['type'] ?? 'PS4'),
                                    backgroundColor: device['type'] == 'PS4' ? Colors.blue.shade900 : Colors.purple.shade900,
                                  ),
                                  Text(device['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ChoiceChip(
                                    label: const Text('Single'),
                                    selected: !isMulti,
                                    onSelected: (val) {
                                      _db.collection('devices').doc(docId).update({'isMulti': false});
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  ChoiceChip(
                                    label: const Text('Multi'),
                                    selected: isMulti,
                                    onSelected: (val) {
                                      _db.collection('devices').doc(docId).update({'isMulti': true});
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: [
                                    Text(formatTime(device['elapsedSeconds'] ?? 0), style: const TextStyle(fontSize: 28, color: Colors.greenAccent, fontFamily: 'monospace')),
                                    Text('${currentCost.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 20, color: Colors.amber)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: isActive ? Colors.red : Colors.green),
                                      onPressed: () {
                                        if (!isActive) {
                                          _db.collection('devices').doc(docId).update({
                                            'isActive': true,
                                            'elapsedSeconds': 0,
                                          });
                                        } else {
                                          stopAndCheckout(docId, device, rates);
                                        }
                                      },
                                      child: Text(
                                        isActive ? 'إنهاء وتصفية' : 'بدء الجلسة',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 20),
              const Text('📊 التقرير المالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan)),
              const SizedBox(height: 10),

              // عرض الحسابات والمصاريف لحظياً
              StreamBuilder<DocumentSnapshot>(
                stream: _db.collection('settings').doc('financials').snapshots(),
                builder: (context, finSnap) {
                  var finData = finSnap.data?.data() as Map<String, dynamic>? ?? {};
                  double cash = (finData['totalCashRevenue'] ?? 0.0).toDouble();
                  double visa = (finData['totalVisaRevenue'] ?? 0.0).toDouble();
                  double gross = cash + visa;

                  return StreamBuilder<QuerySnapshot>(
                    stream: _db.collection('expenses').snapshots(),
                    builder: (context, expSnap) {
                      double totalExp = 0.0;
                      if (expSnap.hasData) {
                        for (var doc in expSnap.data!.docs) {
                          totalExp += ((doc.data() as Map<String, dynamic>)['amount'] ?? 0.0).toDouble();
                        }
                      }
                      double netProfit = gross - totalExp;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              ListTile(
                                title: const Text('إيراد اليوم كاش 💵'),
                                trailing: Text('${cash.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                              ListTile(
                                title: const Text('إيراد اليوم فيزا 💳'),
                                trailing: Text('${visa.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                              ),
                              ListTile(
                                title: const Text('إجمالي الإيرادات 📈'),
                                trailing: Text('${gross.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                              ),
                              ListTile(
                                title: const Text('إجمالي المصاريف 💸'),
                                trailing: Text('- ${totalExp.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                              ),
                              const Divider(),
                              ListTile(
                                title: const Text('صافي الربح 💰', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                trailing: Text('${netProfit.toStringAsFixed(2)} ج.م',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: netProfit >= 0 ? Colors.greenAccent : Colors.red,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
