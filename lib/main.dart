import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

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

// نموذج الجهاز
class DeviceModel {
  int id;
  String name;
  String type; // 'PS4' أو 'PS5'
  bool isActive;
  bool isMulti; // false = Single, true = Multi
  int elapsedSeconds;
  String paymentMethod; // 'كاش (نقداً)' أو 'فيزا'

  DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    this.isActive = false,
    this.isMulti = false,
    this.elapsedSeconds = 0,
    this.paymentMethod = 'كاش (نقداً)',
  });
}

// نموذج المصروف
class ExpenseModel {
  String title;
  double amount;
  ExpenseModel({required this.title, required this.amount});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // أسعار الساعات الافتراضية
  double ps4SingleRate = 25.0;
  double ps4MultiRate = 40.0;
  double ps5SingleRate = 40.0;
  double ps5MultiRate = 60.0;

  // التقارير المالية
  double totalCashRevenue = 0.0;
  double totalVisaRevenue = 0.0;

  // قائمة الأجهزة
  List<DeviceModel> devices = [
    DeviceModel(id: 1, name: 'جهاز 1', type: 'PS4'),
    DeviceModel(id: 2, name: 'جهاز 2', type: 'PS5'),
  ];

  // قائمة المصاريف
  List<ExpenseModel> expenses = [];

  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          for (var device in devices) {
            if (device.isActive) {
              device.elapsedSeconds++;
            }
          }
        });
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

  double calculateCost(DeviceModel device) {
    double rate = 0;
    if (device.type == 'PS4') {
      rate = device.isMulti ? ps4MultiRate : ps4SingleRate;
    } else {
      rate = device.isMulti ? ps5MultiRate : ps5SingleRate;
    }
    return (device.elapsedSeconds / 3600.0) * rate;
  }

  void stopAndCheckout(DeviceModel device) {
    double cost = calculateCost(device);
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('إنهاء جلسة ${device.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الوقت: ${formatTime(device.elapsedSeconds)}'),
              Text('المبلغ المستحق: ${cost.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
              const SizedBox(height: 10),
              const Text('طريقة الدفع:'),
              DropdownButton<String>(
                value: device.paymentMethod,
                isExpanded: true,
                items: ['كاش (نقداً)', 'فيزا'].map((val) {
                  return DropdownMenuItem(value: val, child: Text(val));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      device.paymentMethod = val;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  if (device.paymentMethod == 'كاش (نقداً)') {
                    totalCashRevenue += cost;
                  } else {
                    totalVisaRevenue += cost;
                  }
                  device.isActive = false;
                  device.elapsedSeconds = 0;
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('تأكيد التحصيل والإغلاق', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void openDrawerMenu() {
    final TextEditingController nameController = TextEditingController();
    String selectedType = 'PS4';
    
    final TextEditingController ps4SController = TextEditingController(text: ps4SingleRate.toString());
    final TextEditingController ps4MController = TextEditingController(text: ps4MultiRate.toString());
    final TextEditingController ps5SController = TextEditingController(text: ps5SingleRate.toString());
    final TextEditingController ps5MController = TextEditingController(text: ps5MultiRate.toString());

    final TextEditingController expTitleController = TextEditingController();
    final TextEditingController expAmountController = TextEditingController();

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
                onPressed: () {
                  setState(() {
                    ps4SingleRate = double.tryParse(ps4SController.text) ?? ps4SingleRate;
                    ps4MultiRate = double.tryParse(ps4MController.text) ?? ps4MultiRate;
                    ps5SingleRate = double.tryParse(ps5SController.text) ?? ps5SingleRate;
                    ps5MultiRate = double.tryParse(ps5MController.text) ?? ps5MultiRate;
                  });
                  Navigator.pop(sheetContext);
                },
                child: const Text('حفظ الأسعار'),
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
                  if (val != null) {
                    setSheetState(() => selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    setState(() {
                      devices.add(DeviceModel(id: devices.length + 1, name: nameController.text, type: selectedType));
                    });
                    Navigator.pop(sheetContext);
                  }
                },
                child: const Text('إضافة الجهاز', style: TextStyle(color: Colors.white)),
              ),
              const Divider(height: 30),

              // تسجيل مصروف
              const Text('💸 تسجيل مصروف جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)),
              TextField(controller: expTitleController, decoration: const InputDecoration(labelText: 'اسم المصروف (كهرباء، بيبسي...)')),
              TextField(controller: expAmountController, decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () {
                  if (expTitleController.text.isNotEmpty && expAmountController.text.isNotEmpty) {
                    setState(() {
                      expenses.add(ExpenseModel(title: expTitleController.text, amount: double.tryParse(expAmountController.text) ?? 0.0));
                    });
                    Navigator.pop(sheetContext);
                  }
                },
                child: const Text('إضافة وتسجيل المصروف', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalRevenue = totalCashRevenue + totalVisaRevenue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga PS 🎮'),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.pinkAccent),
          onPressed: openDrawerMenu,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // عرض الأجهزة
          ...devices.map((device) {
            double currentCost = calculateCost(device);
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
                          label: Text(device.type),
                          backgroundColor: device.type == 'PS4' ? Colors.blue.shade900 : Colors.purple.shade900,
                        ),
                        Text(device.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('Single'),
                          selected: !device.isMulti,
                          onSelected: device.isActive ? null : (val) => setState(() => device.isMulti = false),
                        ),
                        const SizedBox(width: 10),
                        ChoiceChip(
                          label: const Text('Multi'),
                          selected: device.isMulti,
                          onSelected: device.isActive ? null : (val) => setState(() => device.isMulti = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          Text(formatTime(device.elapsedSeconds), style: const TextStyle(fontSize: 28, color: Colors.greenAccent, fontFamily: 'monospace')),
                          Text('${currentCost.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 20, color: Colors.amber)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: device.isActive ? Colors.red : Colors.green),
                            onPressed: () {
                              setState(() {
                                if (!device.isActive) {
                                  device.isActive = true;
                                  device.elapsedSeconds = 0;
                                } else {
                                  stopAndCheckout(device);
                                }
                              });
                            },
                            child: Text(
                              device.isActive ? 'إنهاء وتصفية' : 'بدء الجلسة',
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
          }),

          const SizedBox(height: 20),
          // التقرير المالي
          const Text('📊 التقرير المالي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.cyan)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('إيراد اليوم كاش 💵'),
                    trailing: Text('${totalCashRevenue.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    title: const Text('إيراد اليوم فيزا 💳'),
                    trailing: Text('${totalVisaRevenue.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    title: const Text('إجمالي اليوم 📅'),
                    trailing: Text('${totalRevenue.toStringAsFixed(2)} ج.م', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
