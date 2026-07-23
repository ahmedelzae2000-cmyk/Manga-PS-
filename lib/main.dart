import 'package:flutter/material.dart';

void main() {
  runApp(const MangaPsApp());
}

class MangaPsApp extends StatelessWidget {
  const MangaPsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga PS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.deepPurple,
        cardColor: const Color(0xFF1E1E1E),
      ),
      home: const HomeScreen(),
    );
  }
}

enum SessionMode { single, multi }

class Device {
  final String id;
  String name;
  double singleRate;
  double multiRate;
  bool isBusy;
  DateTime? startTime;
  SessionMode currentMode;

  Device({
    required this.id,
    required this.name,
    required this.singleRate,
    required this.multiRate,
    this.isBusy = false,
    this.startTime,
    this.currentMode = SessionMode.single,
  });
}

class Expense {
  final String title;
  final double amount;
  final DateTime date;

  Expense({required this.title, required this.amount, required this.date});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Device> devices = [];
  final List<Expense> expenses = [];
  double totalIncome = 0.0;

  void _addDeviceDialog() {
    final nameController = TextEditingController();
    final singleRateController = TextEditingController();
    final multiRateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة جهاز جديد'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الجهاز (مثال: جهاز 1 - PS5)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: singleRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سعر ساعة Single (ج.م)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: multiRateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'سعر ساعة Multi (ج.م)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () {
              final name = nameController.text.trim();
              final singleRate = double.tryParse(singleRateController.text) ?? 0.0;
              final multiRate = double.tryParse(multiRateController.text) ?? 0.0;

              if (name.isNotEmpty) {
                setState(() {
                  devices.add(
                    Device(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      singleRate: singleRate,
                      multiRate: multiRate,
                    ),
                  );
                });
                Navigator.pop(context);
              }
            },
            child: const Text('إضافة الجهاز'),
          ),
        ],
      ),
    );
  }

  void _addExpenseDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مصروفات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'سبب المصروف (كهرباء، صيانة...)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ (ج.م)',
                border: OutlineInputBorder(),
                suffixText: 'ج.م',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0.0;

              if (title.isNotEmpty && amount > 0) {
                setState(() {
                  expenses.add(
                    Expense(title: title, amount: amount, date: DateTime.now()),
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم إضافة مصروف: $amount ج.م')),
                );
              }
            },
            child: const Text('خصم المصروف'),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final double totalExpenseAmount = expenses.fold(0.0, (sum, item) => sum + item.amount);
    final double netProfit = totalIncome - totalExpenseAmount;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('التقرير المالي الحسابي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('إجمالي الإيرادات:'),
              trailing: Text('${totalIncome.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('إجمالي المصاريف الخصم:'),
              trailing: Text('${totalExpenseAmount.toStringAsFixed(2)} ج.م',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ListTile(
              title: const Text('الصافي المتبقي:'),
              trailing: Text('${netProfit.toStringAsFixed(2)} ج.م',
                  style: TextStyle(
                      color: netProfit >= 0 ? Colors.cyan : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _deleteDevice(Device device) {
    setState(() {
      devices.removeWhere((d) => d.id == device.id);
    });
  }

  void _startSession(Device device, SessionMode mode) {
    setState(() {
      device.isBusy = true;
      device.startTime = DateTime.now();
      device.currentMode = mode;
    });
  }

  void _endSession(Device device) {
    if (device.startTime == null) return;

    final now = DateTime.now();
    final duration = now.difference(device.startTime!);
    final hours = duration.inMinutes / 60.0;
    final rate = device.currentMode == SessionMode.single ? device.singleRate : device.multiRate;
    double calculatedCost = hours * rate;

    final TextEditingController costController = TextEditingController(
      text: calculatedCost.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إنهاء الجلسة - ${device.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الوقت المستغرق: ${duration.inMinutes} دقيقة'),
            Text('الوضع: ${device.currentMode == SessionMode.single ? "Single" : "Multi"}'),
            const SizedBox(height: 15),
            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'المبلغ النهائي (قابل للتعديل)',
                border: OutlineInputBorder(),
                suffixText: 'ج.م',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            onPressed: () {
              final finalAmount = double.tryParse(costController.text) ?? 0.0;
              setState(() {
                totalIncome += finalAmount;
                device.isBusy = false;
                device.startTime = null;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم إنهاء الجلسة. المبلغ: $finalAmount ج.م'),
                ),
              );
            },
            child: const Text('تأكيد وحفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manga PS', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'التقرير المالي',
            onPressed: _showReportDialog,
          ),
          IconButton(
            icon: const Icon(Icons.money_off, color: Colors.redAccent),
            tooltip: 'خصم مصروفات',
            onPressed: _addExpenseDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDeviceDialog,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add),
        label: const Text('إضافة جهاز'),
      ),
      body: devices.isEmpty
          ? const Center(
              child: Text(
                'لا توجد أجهزة مضافة حالياً.\nاضغط "+ إضافة جهاز" بالأسفل للبدء!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final dev = devices[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              dev.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (!dev.isBusy)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteDevice(dev),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        dev.isBusy
                            ? 'الحالة: مشغول (${dev.currentMode == SessionMode.single ? "Single" : "Multi"})'
                            : 'Single: ${dev.singleRate} ج.م/س | Multi: ${dev.multiRate} ج.م/س',
                        style: TextStyle(color: dev.isBusy ? Colors.orange : Colors.green),
                      ),
                      trailing: dev.isBusy
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              onPressed: () => _endSession(dev),
                              child: const Text('إيقاف'),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                                  onPressed: () => _startSession(dev, SessionMode.single),
                                  child: const Text('Single'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                                  onPressed: () => _startSession(dev, SessionMode.multi),
                                  child: const Text('Multi'),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
