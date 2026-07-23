import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'device_model.dart';

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

  // إضافة جهاز جديد تلقائياً للتجربة
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

  // بدء الجلسة
  void _startSession(String docId, String type) {
    FirebaseFirestore.instance.collection('devices').doc(docId).update({
      'isOccupied': true,
      'sessionType': type,
      'startTime': FieldValue.serverTimestamp(),
    });
  }

  // إنهاء الجلسة وحساب الحساب
  void _stopSession(BuildContext context, DeviceModel device) {
    if (device.startTime == null) return;

    final now = DateTime.now();
    final duration = now.difference(device.startTime!);
    final hours = duration.inMinutes / 60.0;
    final rate = device.sessionType == 'Single'
        ? device.hourlyRateSingle
        : device.hourlyRateMulti;
    final total = hours * rate;

    // إعادة ضبط الجهاز
    FirebaseFirestore.instance.collection('devices').doc(device.id).update({
      'isOccupied': false,
      'startTime': null,
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
            Text('نوع الجلسة: ${device.sessionType == 'Single' ? 'عادي' : 'ملتي'}'),
            Text('الوقت المنقضي: ${duration.inMinutes} دقيقة'),
            const SizedBox(height: 10),
            Text(
              'المبلغ المطلوب: ${total.toStringAsFixed(2)} جنيه',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga PS - إدارة الأجهزة'),
        centerTitle: true,
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
              child: Text('لا توجد أجهزة مضافة بعد. اضغط على زر "إضافة جهاز" بالأسفل.'),
            );
          }

          final devices = snapshot.data!.docs
              .map((doc) => DeviceModel.fromFirestore(doc))
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.sports_esports,
                        size: 40,
                        color: device.isOccupied ? Colors.red : Colors.green,
                      ),
                      Text(
                        device.isOccupied ? 'مشغول' : 'متاح',
                        style: TextStyle(
                          fontSize: 16,
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
                              child: const Text('فردي', style: TextStyle(color: Colors.white)),
                            ),
                            ElevatedButton(
                              onPressed: () => _startSession(device.id, 'Multi'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                              child: const Text('زوجي', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        )
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: () => _stopSession(context, device),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          icon: const Icon(Icons.stop, color: Colors.white),
                          label: const Text('إنهاء وسداد', style: TextStyle(color: Colors.white)),
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
