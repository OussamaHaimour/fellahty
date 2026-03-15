import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String farmerId;
  final String jobTitle;
  final int workersNeeded;
  final double salaryPerDay;
  final String location;
  final DateTime startDate;
  final int durationDays;
  final String status; // open, closed

  Job({
    required this.id,
    required this.farmerId,
    required this.jobTitle,
    required this.workersNeeded,
    required this.salaryPerDay,
    required this.location,
    required this.startDate,
    this.durationDays = 1,
    this.status = 'open',
  });

  factory Job.fromMap(Map<String, dynamic> map, String id) {
    return Job(
      id: id,
      farmerId: map['farmerId'] ?? '',
      jobTitle: map['jobTitle'] ?? '',
      workersNeeded: map['workersNeeded'] ?? 0,
      salaryPerDay: (map['salaryPerDay'] ?? 0.0).toDouble(),
      location: map['location'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      durationDays: map['durationDays'] ?? 1,
      status: map['status'] ?? 'open',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'jobTitle': jobTitle,
      'workersNeeded': workersNeeded,
      'salaryPerDay': salaryPerDay,
      'location': location,
      'startDate': Timestamp.fromDate(startDate),
      'durationDays': durationDays,
      'status': status,
    };
  }

  factory Job.fromDocument(DocumentSnapshot doc) {
    return Job.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
