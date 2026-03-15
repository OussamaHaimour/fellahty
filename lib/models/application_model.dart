import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Represents a single day's record for tracking work/rental confirmation
class DailyRecord {
  final String date; // "2026-03-15"
  final String code; // 4-digit code e.g. "7294"
  final bool workerConfirmed;
  final bool farmerConfirmed;
  final bool reportedAbsence;
  final bool paid;
  final double rating;

  DailyRecord({
    required this.date,
    required this.code,
    this.workerConfirmed = false,
    this.farmerConfirmed = false,
    this.reportedAbsence = false,
    this.paid = false,
    this.rating = 0.0,
  });

  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      date: map['date'] ?? '',
      code: map['code'] ?? '',
      workerConfirmed: map['workerConfirmed'] ?? false,
      farmerConfirmed: map['farmerConfirmed'] ?? false,
      reportedAbsence: map['reportedAbsence'] ?? false,
      paid: map['paid'] ?? false,
      rating: (map['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'code': code,
      'workerConfirmed': workerConfirmed,
      'farmerConfirmed': farmerConfirmed,
      'reportedAbsence': reportedAbsence,
      'paid': paid,
      'rating': rating,
    };
  }

  /// Generate a random 4-digit code
  static String generateCode() {
    return (1000 + Random().nextInt(9000)).toString();
  }
}

class Application {
  final String id;
  final String jobId;
  final String workerId;
  final String status; // pending, accepted, rejected, completed
  final DateTime appliedAt;
  final List<DailyRecord> dailyRecords;

  Application({
    required this.id,
    required this.jobId,
    required this.workerId,
    this.status = 'pending',
    DateTime? appliedAt,
    this.dailyRecords = const [],
  }) : appliedAt = appliedAt ?? DateTime.now();

  factory Application.fromMap(Map<String, dynamic> map, String id) {
    List<DailyRecord> records = [];
    if (map['dailyRecords'] != null) {
      records = (map['dailyRecords'] as List)
          .map((r) => DailyRecord.fromMap(Map<String, dynamic>.from(r)))
          .toList();
    }
    return Application(
      id: id,
      jobId: map['jobId'] ?? '',
      workerId: map['workerId'] ?? '',
      status: map['status'] ?? 'pending',
      appliedAt: map['appliedAt'] != null
          ? (map['appliedAt'] as Timestamp).toDate()
          : DateTime.now(),
      dailyRecords: records,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'jobId': jobId,
      'workerId': workerId,
      'status': status,
      'appliedAt': Timestamp.fromDate(appliedAt),
      'dailyRecords': dailyRecords.map((r) => r.toMap()).toList(),
    };
  }

  factory Application.fromDocument(DocumentSnapshot doc) {
    return Application.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  /// Generate daily records when application is accepted
  static List<DailyRecord> generateDailyRecords(DateTime startDate, int durationDays) {
    List<DailyRecord> records = [];
    for (int i = 0; i < durationDays; i++) {
      final date = startDate.add(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      records.add(DailyRecord(
        date: dateStr,
        code: DailyRecord.generateCode(),
      ));
    }
    return records;
  }
}
