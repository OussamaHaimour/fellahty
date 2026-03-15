import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String role; // farmer, worker, equipment_owner, admin
  final String region;
  final double score;
  final String email;
  final double walletBalance;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.region,
    this.score = 0.0,
    required this.email,
    this.walletBalance = 0.0,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? '',
      region: map['region'] ?? '',
      score: (map['score'] ?? 0.0).toDouble(),
      email: map['email'] ?? '',
      walletBalance: (map['walletBalance'] ?? 0.0).toDouble(),
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'role': role,
      'region': region,
      'score': score,
      'email': email,
      'walletBalance': walletBalance,
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? role,
    String? region,
    double? score,
    String? email,
    double? walletBalance,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      region: region ?? this.region,
      score: score ?? this.score,
      email: email ?? this.email,
      walletBalance: walletBalance ?? this.walletBalance,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}

