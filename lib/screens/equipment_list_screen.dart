import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/equipment_model.dart';
import '../widgets/equipment_card.dart';

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({Key? key}) : super(key: key);

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  final _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _toggleAvailability(Equipment equipment) async {
    try {
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc(equipment.id)
          .update({'isAvailable': !equipment.isAvailable});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appLocale.get("error")}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.get('my_fleet')),
      ),
      body: StreamBuilder<List<Equipment>>(
        stream: _firestoreService.getEquipmentByOwner(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${t.get("error")}: ${snapshot.error}'));
          }

          final equipmentList = snapshot.data ?? [];

          if (equipmentList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.garage, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    t.get('no_equipment'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: equipmentList.length,
            itemBuilder: (context, index) {
              final equipment = equipmentList[index];
              return EquipmentCard(
                equipment: equipment,
                onTap: () {},
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: equipment.isAvailable,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      onChanged: (val) {
                        _toggleAvailability(equipment);
                      },
                    ),
                    Text(
                      equipment.isAvailable ? t.get('available') : t.get('rented'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: equipment.isAvailable ? Colors.green : Colors.red,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(t.get('confirm')),
                            content: Text(t.get('confirm_delete')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.get('cancel'))),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  await _firestoreService.deleteEquipment(equipment.id);
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: Text(t.get('confirm')),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
