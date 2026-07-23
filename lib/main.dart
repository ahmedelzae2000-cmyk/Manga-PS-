import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package0:cloud_firestore/cloud_firestore.dart';
import 'device_model.dart';
import 'expense_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // إضافة جهاز جديد
  Future<void> _addDevice(BuildContext context) async {
    final count = await FirebaseFirestore.instance.collection('devices').get();
    final newId = count.docs.length + 1;
    await FirebaseFirestore.instance.collection('devices').add({
      'name': 'جهاز $newId',
      'isOccupied': false,
      'sessionType': 'Single',
      'startTime': null,
      'hourlyRateSingle': 20.0,
      'hourlyRateMulti': 30.0,
    });
  }

  // إضافة مصروف جديد
  void _addExpense(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مصروف جديد 💸'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'سبب الصرف (مثلاً: شاي/صيانة)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ', suffixText: 'جنيه'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0.0;

              if (title.isNotEmpty && amount > 0) {
                await FirebaseFirestore.instance.collection('expenses').add({
                  'title': title,
                  'amount': amount,
                  'date': FieldValue.serverTimestamp(),
                });
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل المصروف بنجاح')),
                );
              }
            },
            child: const Text('حفظ المصروف'),
          ),
        ],
      ),
    );
  }

  // عرض تقرير الوردية (الشيفت)
  void _showShiftReport(BuildContext context) async {
    // جلب إجمالي الأرباح من الجلسات المغلقة
    final sessionsDocs = await FirebaseFirestore.instance.collection('completed_sessions').get();
    double totalIncome = 0.0;
    for (var doc in sessionsDocs.docs) {
      totalIncome += (doc.data()['totalAmount'] ?? 0.0).toDouble();
    }

    // جلب إجمالي المصاريف
    final expenseDocs = await FirebaseFirestore.instance.collection('expenses').get();
    double totalExpenses = 0.0;
    for (var doc in expenseDocs.docs) {
      totalExpenses += (doc.data()['amount'] ?? 0.0).toDouble();
    }

    final netProfit = totalIncome - totalExpenses;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('📊 تقرير الوردية الحالية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إجمالي دخل الجلسات: ${totalIncome.toStringAsFixed(2)} جنيه',
                style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('إجمالي المصاريف: ${totalExpenses.toStringAsFixed(2)} جنيه',
                style: const TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Text('صافي أرباح الوردية: ${netProfit.toStringAsFixed(2)} جنيه',
                style: const TextStyle(fontSize: 18, color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // بدء الجلسة
  void _startSession(String docId, String type) {
    FirebaseFirestore.instance.collection('devices').doc(docId).update({
      'isOccupied': true,
      'sessionType': type,
      'startTime': FieldValue.serverTimestamp(),
    });
  }

  // إنهاء الجلسة وحفظ قيمتها في الأرباح
  void _stopSession(BuildContext context, DeviceModel device) async {
    if (device.startTime == null) return;

    final now = DateTime.now();
    final duration = now.difference(device.startTime!);
    final hours = duration.inMinutes / 60.0;
    final rate = device.sessionType == 'Single'
        ? device.hourlyRateSingle
        : device.hourlyRateMulti;
    final total = hours * rate;

    // إعادة ضبط الجهاز
    await FirebaseFirestore.instance.collection('devices').doc(device.id).update({
      'isOccupied': false,
      'startTime': null,
    });

    // تسجيل الجلسة كمنتهية لحساب التقارير
    await FirebaseFirestore.instance.collection('completed_sessions').add({
      'deviceName': device.name,
      'totalAmount': total,
      'sessionType': device.sessionType,
      'endTime': FieldValue.serverTimestamp(),
    });

    // عرض الفاتورة
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('فاتورة ${device.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('نوع الجلسة: ${device.sessionType == 'Single' ? 'فردي' : 'زوجي'}'),
            Text('الوقت: ${duration.inMinutes} دقيقة'),
            const SizedBox(height: 10),
            Text(
              'المبلغ المطلوب: ${total.toStringAsFixed(2)} جنيه',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تم السداد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga PS - إدارة الوردية'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'تقرير الوردية',
            onPressed: () => _showShiftReport(context),
          ),
          IconButton(
            icon: const Icon(Icons.money_off),
            tooltip: 'إضافة مصروف',
            onPressed: () => _addExpense(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDevice(context),
        icon: const Icon(Icons.add),
        label: const Text('إضافة جهاز'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('devices').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('لا توجد أجهزة مضافة بعد.'),
            );
          }

          final devices = snapshot.data!.docs
              .map((doc) => DeviceModel.fromFirestore(doc))
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return Card(
                elevation: 4,
                color: device.isOccupied ? Colors.red.shade50 : Colors.green.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: device.isOccupied ? Colors.red : Colors.green,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Icon(
                        Icons.sports_esports,
                        size: 36,
                        color: device.isOccupied ? Colors.red : Colors.green,
                      ),
                      Text(
                        device.isOccupied ? 'مشغول' : 'متاح',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: device.isOccupied ? Colors.red : Colors.green,
                        ),
                      ),
                      if (!device.isOccupied) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () => _startSession(device.id, 'Single'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                              child: const Text('فردي', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                            ElevatedButton(
                              onPressed: () => _startSession(device.id, 'Multi'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                              child: const Text('زوجي', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ],
                        )
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: () => _stopSession(context, device),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          icon: const Icon(Icons.stop, color: Colors.white, size: 16),
                          label: const Text('إنهاء وسداد', style: TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
 
