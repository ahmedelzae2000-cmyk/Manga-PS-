import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase عبر الأكواد
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "YOUR_API_KEY",
        appId: "YOUR_APP_ID",
        messagingSenderId: "YOUR_SENDER_ID",
        projectId: "YOUR_PROJECT_ID",
        storageBucket: "YOUR_STORAGE_BUCKET",
      ),
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(const MangaPSApp());
}

class MangaPSApp extends StatefulWidget {
  const MangaPSApp({super.key});

  @override
  State<MangaPSApp> createState() => _MangaPSAppState();
}

class _MangaPSAppState extends State<MangaPSApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga PS',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.deepOrange),
      darkTheme: ThemeData(brightness: Brightness.dark, primarySwatch: Colors.deepOrange),
      home: SplashScreen(onToggleTheme: _toggleTheme),
    );
  }
}

// 1. شاشة ترحيبية (Splash Screen)
class SplashScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const SplashScreen({super.key, required this.onToggleTheme});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainHomeScreen(onToggleTheme: widget.onToggleTheme)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.jpg', height: 120, errorBuilder: (_, __, ___) => const Icon(Icons.gamepad, size: 80, color: Colors.deepOrange)),
            const SizedBox(height: 20),
            const Text('مرحباً بكم في Manga PS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

// نموذج البيانات للجهاز
class Device {
  String id;
  String name;
  String type; // PS4, PS5
  double singleRate;
  double multiRate;
  bool isMulti;
  bool isRunning;
  DateTime? startTime;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.singleRate,
    required this.multiRate,
    this.isMulti = false,
    this.isRunning = false,
    this.startTime,
  });
}

class MainHomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const MainHomeScreen({super.key, required this.onToggleTheme});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;
  bool isShiftActive = false;
  DateTime? shiftStartTime;

  List<Device> devices = [
    Device(id: '1', name: 'جهاز 1', type: 'PS4', singleRate: 40.0, multiRate: 50.0),
    Device(id: '2', name: 'جهاز 2', type: 'PS5', singleRate: 60.0, multiRate: 80.0),
  ];

  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> reports = [];

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildMainTab(),
      _buildExpensesTab(),
      _buildShiftTab(),
      _buildReportsTab(),
      _buildSettingsTab(),
    ];

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/bg.jpg'), fit: BoxFit.cover),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.black.withOpacity(0.85) 
            : Colors.white.withOpacity(0.85),
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset('assets/logo.jpg', height: 35, errorBuilder: (_, __, ___) => const Icon(Icons.gamepad)),
              const SizedBox(width: 10),
              const Text('Manga PS'),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.brightness_6), onPressed: widget.onToggleTheme),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.deepOrange,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.money_off), label: 'المصروفات'),
            BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'الوردية'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التقرير'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'إعدادات السعر'),
          ],
        ),
      ),
    );
  }

  // 1. شاشة الرئيسية (الأجهزة واللعب فردي/مالتي)
  Widget _buildMainTab() {
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (context, i) {
        final d = devices[i];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text('${d.name} (${d.type})'),
            subtitle: Text('فردي: ${d.singleRate} | مالتي: ${d.multiRate} ج.م'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<bool>(
                  value: d.isMulti,
                  items: const [
                    DropdownMenuItem(value: false, child: Text('فردي')),
                    DropdownMenuItem(value: true, child: Text('مالتي')),
                  ],
                  onChanged: d.isRunning ? null : (val) => setState(() => d.isMulti = val!),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: d.isRunning ? Colors.red : Colors.green),
                  onPressed: () {
                    if (d.isRunning) {
                      _finishSessionDialog(d);
                    } else {
                      setState(() {
                        d.isRunning = true;
                        d.startTime = DateTime.now();
                      });
                    }
                  },
                  child: Text(d.isRunning ? 'إنهاء' : 'تشغيل'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // إغلاق الفاتورة وتعديل الحساب يدوياً
  void _finishSessionDialog(Device d) {
    double baseRate = d.isMulti ? d.multiRate : d.singleRate;
    double calculatedAmount = baseRate; 
    double finalAmount = calculatedAmount;
    String paymentMethod = 'كاش';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إنهاء فاتورة ${d.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('المبلغ المحسوب: $calculatedAmount ج.م'),
            TextField(
              decoration: const InputDecoration(labelText: 'تعديل الحساب يدوياً (الصافي)'),
              keyboardType: TextInputType.number,
              onChanged: (val) => finalAmount = double.tryParse(val) ?? calculatedAmount,
            ),
            DropdownButtonFormField<String>(
              value: paymentMethod,
              items: const [
                DropdownMenuItem(value: 'كاش', child: Text('كاش')),
                DropdownMenuItem(value: 'فيزا', child: Text('فيزا')),
                DropdownMenuItem(value: 'نقدي', child: Text('نقدي')),
              ],
              onChanged: (val) => paymentMethod = val!,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                d.isRunning = false;
                reports.add({
                  'title': 'جلسة ${d.name}',
                  'amount': finalAmount,
                  'method': paymentMethod,
                  'date': DateTime.now(),
                });
              });
              Navigator.pop(ctx);
            },
            child: const Text('حفظ واغلاق الفاتورة'),
          )
        ],
      ),
    );
  }

  // 2. شاشة المصروفات
  Widget _buildExpensesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // إضافة مصروف
            },
            child: const Text('إضافة مصروف جديد'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: expenses.length,
              itemBuilder: (ctx, i) => ListTile(title: Text(expenses[i]['title'])),
            ),
          )
        ],
      ),
    );
  }

  // 3. شاشة الوردية (بدء يدوي من 12 ظهراً)
  Widget _buildShiftTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isShiftActive ? 'الوردية شغالة من 12 ظهراً' : 'لا يوجد وردية مفتوحة حالياً'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                isShiftActive = !isShiftActive;
                shiftStartTime = isShiftActive ? DateTime.now() : null;
              });
            },
            child: Text(isShiftActive ? 'إنهاء الوردية' : 'بدء وردية جديدة (12ظ - 12ظ)'),
          ),
        ],
      ),
    );
  }

  // 4. شاشة التقرير
  Widget _buildReportsTab() {
    return ListView.builder(
      itemCount: reports.length,
      itemBuilder: (ctx, i) {
        final r = reports[i];
        return ListTile(
          title: Text(r['title']),
          subtitle: Text('طريقة الدفع: ${r['method']}'),
          trailing: Text('${r['amount']} ج.م', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  // 5. شاشة إعدادات السعر للأجهزة
  Widget _buildSettingsTab() {
    return ListView.builder(
      itemCount: devices.length,
      itemBuilder: (ctx, i) {
        final d = devices[i];
        return ListTile(
          title: Text(d.name),
          subtitle: Text('فردي: ${d.singleRate} | مالتي: ${d.multiRate}'),
          trailing: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // تعديل أسعار الفردي والمالتي
            },
          ),
        );
      },
    );
  }
}
 
