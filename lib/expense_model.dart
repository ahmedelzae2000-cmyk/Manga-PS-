import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String title; // سبب الصرف (مثلاً: شراء كروت/شاي)
  final double amount; // المبلغ
  final DateTime date; // وقت الصرف

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      title: data['title'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
    };
  }
}
