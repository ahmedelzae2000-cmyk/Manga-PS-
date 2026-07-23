import 'package:flutter/material.dart';

class DeviceCard extends StatefulWidget {
  final String deviceName;
  final String deviceType; // 'PS4' or 'PS5'

  const DeviceCard({
    super.key,
    required this.deviceName,
    required this.deviceType,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool isSingle = true;
  bool isSessionActive = false;
  String paymentMethod = 'كاش (نقداً)';

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF161B26), // خلفية الكارت الغامقة
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الهيدر: اسم الجهاز والنوع
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.deviceName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.deviceType == 'PS5' ? Colors.pinkAccent : Colors.blueAccent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.deviceType,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // أزرار فردي / زوجي (Single / Multi) مترجمة وموحدة
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSingle ? Colors.cyan : Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => setState(() => isSingle = true),
                      child: Text(
                        'فردي',
                        style: TextStyle(
                          color: isSingle ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isSingle ? Colors.cyan : Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => setState(() => isSingle = false),
                      child: Text(
                        'زوجي (متعدد)',
                        style: TextStyle(
                          color: !isSingle ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // العداد والسعر
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
                color: Colors.black26,
              ),
              child: const Column(
                children: [
                  Text(
                    '00 : 00 : 00',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '0 ج.م',
                    style: TextStyle(color: Colors.amber, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // طريقة الدفع
            DropdownButtonFormField<String>(
              value: paymentMethod,
              dropdownColor: const Color(0xFF161B26),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'طريقة الدفع عند التقفيل:',
                labelStyle: const TextStyle(color: Colors.white70),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: ['كاش (نقداً)', 'فيزا (Visa)']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => setState(() => paymentMethod = val!),
            ),
            const SizedBox(height: 16),

            // أزرار التحكم (بدء / إنهاء)
            Row(
              children: [
                // زر إنهاء وتصفية (يكون معطل إذا لم تبدأ الجلسة)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      disabledBackgroundColor: Colors.redAccent.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSessionActive
                        ? () => setState(() => isSessionActive = false)
                        : null, // معطل
                    child: const Text('إنهاء وتصفية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                // زر بدء الجلسة
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => setState(() => isSessionActive = true),
                    child: const Text('بدء الجلسة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
