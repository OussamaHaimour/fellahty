import 'package:cloud_firestore/cloud_firestore.dart';

class Equipment {
  final String id;
  final String ownerId;
  final String type;
  final double price;
  final String location;
  final String description;
  final bool isAvailable;
  final List<String> imageUrls;

  Equipment({
    required this.id,
    required this.ownerId,
    required this.type,
    required this.price,
    required this.location,
    required this.description,
    this.isAvailable = true,
    this.imageUrls = const [],
  });

  factory Equipment.fromMap(Map<String, dynamic> map, String id) {
    return Equipment(
      id: id,
      ownerId: map['ownerId'] ?? '',
      type: map['type'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'type': type,
      'price': price,
      'location': location,
      'description': description,
      'isAvailable': isAvailable,
      'imageUrls': imageUrls,
    };
  }

  factory Equipment.fromDocument(DocumentSnapshot doc) {
    return Equipment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
