import 'package:cloud_firestore/cloud_firestore.dart';
import 'application_model.dart'; // reuse DailyRecord

class EquipmentRental {
  final String id;
  final String equipmentId;
  final String renterId; // The farmer who rents
  final String ownerId;
  final String status; // pending, accepted, rejected, active, completed
  final double pricePerDay;
  final int durationDays;
  final DateTime startDate;
  final DateTime requestedAt;
  final List<DailyRecord> dailyRecords;

  EquipmentRental({
    required this.id,
    required this.equipmentId,
    required this.renterId,
    required this.ownerId,
    this.status = 'pending',
    required this.pricePerDay,
    required this.durationDays,
    required this.startDate,
    DateTime? requestedAt,
    this.dailyRecords = const [],
  }) : requestedAt = requestedAt ?? DateTime.now();

  factory EquipmentRental.fromMap(Map<String, dynamic> map, String id) {
    List<DailyRecord> records = [];
    if (map['dailyRecords'] != null) {
      records = (map['dailyRecords'] as List)
          .map((r) => DailyRecord.fromMap(Map<String, dynamic>.from(r)))
          .toList();
    }
    return EquipmentRental(
      id: id,
      equipmentId: map['equipmentId'] ?? '',
      renterId: map['renterId'] ?? '',
      ownerId: map['ownerId'] ?? '',
      status: map['status'] ?? 'pending',
      pricePerDay: (map['pricePerDay'] ?? 0.0).toDouble(),
      durationDays: map['durationDays'] ?? 1,
      startDate: map['startDate'] != null
          ? (map['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      requestedAt: map['requestedAt'] != null
          ? (map['requestedAt'] as Timestamp).toDate()
          : DateTime.now(),
      dailyRecords: records,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipmentId': equipmentId,
      'renterId': renterId,
      'ownerId': ownerId,
      'status': status,
      'pricePerDay': pricePerDay,
      'durationDays': durationDays,
      'startDate': Timestamp.fromDate(startDate),
      'requestedAt': Timestamp.fromDate(requestedAt),
      'dailyRecords': dailyRecords.map((r) => r.toMap()).toList(),
    };
  }

  factory EquipmentRental.fromDocument(DocumentSnapshot doc) {
    return EquipmentRental.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  double get totalPrice => pricePerDay * durationDays;
}
