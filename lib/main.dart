import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MangaPSApp());
}

class MangaPSApp extends StatelessWidget {
  const MangaPSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga PS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        brightness: Brightness.dark,
      ),
      home: const MainHomeScreen(),
    );
  }
}

// نموذج بيانات الجهاز
class Device {
  String id;
  String name; // مثال: جهاز 1
  String type; // PS4 أو PS5
  double hourlyRate; // السعر يدوي
  bool isRunning;
  DateTime? startTime;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.hourlyRate,
    this.isRunning = false,
    this.startTime,
  });
}

// نموذج بيانات المعاملة المالية
class TransactionRecord {
  final String id;
  final String title;
  final double amount;
  final bool isIncome; // true: أرباح, false: مصاريف
  final String paymentMethod; // Cash أو Visa
  final DateTime timestamp;

  TransactionRecord({
    required this.id,
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.paymentMethod,
    required this.timestamp,
  });
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  // قائمة الأجهزة
  List<Device> devices = [
    Device(id: '1', name: 'جهاز 1', type: 'PS4', hourlyRate: 40.0),
    Device(id: '2', name: 'جهاز 2', type: 'PS5', hourlyRate: 60.0),
  ];

  // سجل المعاملات المالية
  List<TransactionRecord> transactions = [];

  // دالة تحديد بداية ونهاية الوردية (من 12 ظهراً إلى 12 ظهراً)
  DateTime getShiftStart(DateTime time) {
    DateTime adjusted = time.subtract(const Duration(hours: 12));
    return DateTime(adjusted.year, adjusted.month, adjusted.day, 12, 0);
  }

  // حساب أرباح الوردية الحالية
  double get currentShiftIncome {
    DateTime now = DateTime.now();
    DateTime shiftStart = getShiftStart(now);
    DateTime shiftEnd = shiftStart.add(const Duration(hours: 24));

    return transactions
        .where((t) => t.isIncome && t.timestamp.isAfter(shiftStart) && t.timestamp.isBefore(shiftEnd))
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  // إضافة جهاز جديد يدوي
  void _addDevice(String name, String type, double rate) {
    setState(() {
      devices.add(Device(
        id: DateTime.now().toString(),
        name: name,
        type: type,
        hourlyRate: rate,
      ));
    });
  }

  // إضافة مصروف يدوي
  void _addExpense(String title, double amount, String method) {
    setState(() {
      transactions.add(TransactionRecord(
        id: DateTime.now().toString(),
        title: title,
        amount: amount,
        isIncome: false,
        paymentMethod: method,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDevicesTab(),
      _buildReportsTab(),
    ];

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.black.withOpacity(0.85),
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/logo.jpg', height: 40, errorBuilder: (_, __, ___) => const Icon(Icons.gamepad)),
              const SizedBox(width: 12),
              const Text('Manga PS'),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          backgroundColor: Colors.black87,
          selectedItemColor: Colors.deepOrangeAccent,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'الأجهزة'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقارير الشهرية'),
          ],
        ),
      ),
    );
  }

  // واجهة الأجهزة
  Widget _buildDevicesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Card(
            color: Colors.deepOrange.withOpacity(0.2),
            child: ListTile(
              title: const Text('أرباح الوردية الحالية (12 ظهراً - 12 ظهراً)'),
              subtitle: Text(
                '${currentShiftIncome.toStringAsFixed(1)} ج.م',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.greenAccent),
              ),
              trailing: ElevatedButton(
                onPressed: _showAddExpenseDialog,
                child: const Text('إضافة مصروف'),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final dev = devices[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(
                    dev.type == 'PS5' ? Icons.gamepad : Icons.sports_esports,
                    color: dev.type == 'PS5' ? Colors.blueAccent : Colors.white,
                  ),
                  title: Text('${dev.name} (${dev.type})'),
                  subtitle: Text('السعر: ${dev.hourlyRate} ج.م/ساعة'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showEditRateDialog(dev),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dev.isRunning ? Colors.red : Colors.green,
                        ),
                        onPressed: () {
                          setState(() {
                            if (dev.isRunning) {
                              dev.isRunning = false;
                              // إضافة الدخل عند إنهاء الجلسة (تبسيط للحسبة)
                              transactions.add(TransactionRecord(
                                id: DateTime.now().toString(),
                                title: 'جلسة ${dev.name}',
                                amount: dev.hourlyRate,
                                isIncome: true,
                                paymentMethod: 'Cash',
                                timestamp: DateTime.now(),
                              ));
                            } else {
                              dev.isRunning = true;
                              dev.startTime = DateTime.now();
                            }
                          });
                        },
                        child: Text(dev.isRunning ? 'إنهاء' : 'تشغيل'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: _showAddDeviceDialog,
            icon: const Icon(Icons.add),
            label: const Text('إضافة جهاز جديد'),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(45)),
          ),
        )
      ],
    );
  }

  // واجهة التقارير الشهرية (تجميع الأرباح والمصاريف)
  Widget _buildReportsTab() {
    double totalIncome = transactions.where((t) => t.isIncome).fold(0.0, (s, i) => s + i.amount);
    double totalExpenses = transactions.where((t) => !t.isIncome).fold(0.0, (s, i) => s + i.amount);
    double totalCash = transactions.where((t) => t.paymentMethod == 'Cash' && t.isIncome).fold(0.0, (s, i) => s + i.amount);
    double totalVisa = transactions.where((t) => t.paymentMethod == 'Visa' && t.isIncome).fold(0.0, (s, i) => s + i.amount);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الملخص المالي الشامل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard('إجمالي الأرباح', '${totalIncome.toStringAsFixed(1)} ج.م', Colors.green),
              _buildStatCard('إجمالي المصاريف', '${totalExpenses.toStringAsFixed(1)} ج.م', Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('كاش (Cash)', '${totalCash.toStringAsFixed(1)} ج.م', Colors.amber),
              _buildStatCard('فيزا (Visa)', '${totalVisa.toStringAsFixed(1)} ج.م', Colors.blue),
            ],
          ),
          const SizedBox(height: 20),
          const Text('سجل العمليات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final item = transactions[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text(DateFormat('yyyy/MM/dd - hh:mm a').format(item.timestamp)),
                  trailing: Text(
                    '${item.isIncome ? '+' : '-'}${item.amount} ج.م (${item.paymentMethod})',
                    style: TextStyle(
                      color: item.isIncome ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // النافذة المنبثقة لإضافة جهاز
  void _showAddDeviceDialog() {
    String name = '';
    String type = 'PS4';
    double rate = 40.0;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة جهاز جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'اسم الجهاز (مثال: جهاز 3)'),
              onChanged: (val) => name = val,
            ),
            DropdownButtonFormField<String>(
              value: type,
              items: const [
                DropdownMenuItem(value: 'PS4', child: Text('PlayStation 4')),
                DropdownMenuItem(value: 'PS5', child: Text('PlayStation 5')),
              ],
              onChanged: (val) => type = val!,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'سعر الساعة (ج.م)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => rate = double.tryParse(val) ?? 40.0,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (name.isNotEmpty) _addDevice(name, type, rate);
              Navigator.pop(ctx);
            },
            child: const Text('إضافة'),
          )
        ],
      ),
    );
  }

  // النافذة المنبثقة لتعديل السعر
  void _showEditRateDialog(Device dev) {
    double newRate = dev.hourlyRate;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تعديل سعر ${dev.name}'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'السعر الجديد للساعة'),
          keyboardType: TextInputType.number,
          onChanged: (val) => newRate = double.tryParse(val) ?? dev.hourlyRate,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() => dev.hourlyRate = newRate);
              Navigator.pop(ctx);
            },
            child: const Text('حفظ'),
          )
        ],
      ),
    );
  }

  // النافذة المنبثقة لإضافة مصروف
  void _showAddExpenseDialog() {
    String title = '';
    double amount = 0.0;
    String method = 'Cash';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مصروف جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'بيان المصروف'),
              onChanged: (val) => title = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'المبلغ (ج.م)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => amount = double.tryParse(val) ?? 0.0,
            ),
            DropdownButtonFormField<String>(
              value: method,
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('كاش (Cash)')),
                DropdownMenuItem(value: 'Visa', child: Text('فيزا (Visa)')),
              ],
              onChanged: (val) => method = val!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (title.isNotEmpty && amount > 0) _addExpense(title, amount, method);
              Navigator.pop(ctx);
            },
            child: const Text('حفظ المصروف'),
          )
        ],
      ),
    );
  }
}
