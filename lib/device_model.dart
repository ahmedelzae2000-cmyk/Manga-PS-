import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceModel {
  final String id;
  final String name; // اسم أو رقم الجهاز (مثلاً: جهاز 1)
  final bool isOccupied; // هل الجهاز مشغول حالياً؟
  final String sessionType; // نوع الجلسة: 'Single' أو 'Multi'
  final DateTime? startTime; // وقت بداية الجلسة
  final double hourlyRateSingle; // سعر الساعة عادي
  final double hourlyRateMulti; // سعر الساعة ملتي

  DeviceModel({
    required this.id,
    required this.name,
    this.isOccupied = false,
    this.sessionType = 'Single',
    this.startTime,
    this.hourlyRateSingle = 20.0, // سعر افتراضي
    this.hourlyRateMulti = 30.0,  // سعر افتراضي
  });

  // تحويل البيانات من Firestore إلى Object
  factory DeviceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return DeviceModel(
      id: doc.id,
      name: data['name'] ?? '',
      isOccupied: data['isOccupied'] ?? false,
      sessionType: data['sessionType'] ?? 'Single',
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : null,
      hourlyRateSingle: (data['hourlyRateSingle'] ?? 20.0).toDouble(),
      hourlyRateMulti: (data['hourlyRateMulti'] ?? 30.0).toDouble(),
    );
  }

  // تحويل البيانات من Object إلى Map للحفظ في Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'isOccupied': isOccupied,
      'sessionType': sessionType,
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'hourlyRateSingle': hourlyRateSingle,
      'hourlyRateMulti': hourlyRateMulti,
    };
  }
}
