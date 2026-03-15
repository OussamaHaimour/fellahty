import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../services/notification_service.dart';
import '../models/equipment_model.dart';
import '../models/rental_model.dart';
import '../widgets/equipment_card.dart';

class BrowseEquipmentScreen extends StatefulWidget {
  const BrowseEquipmentScreen({Key? key}) : super(key: key);

  @override
  State<BrowseEquipmentScreen> createState() => _BrowseEquipmentScreenState();
}

class _BrowseEquipmentScreenState extends State<BrowseEquipmentScreen> {
  final _firestoreService = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterRegion = '';
  String _filterType = '';
  double _minPrice = 0;
  double _maxPrice = 5000;

  List<Equipment> _filterEquipment(List<Equipment> items) {
    return items.where((eq) {
      if (!eq.isAvailable) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!eq.type.toLowerCase().contains(q) && !eq.location.toLowerCase().contains(q) && !eq.description.toLowerCase().contains(q)) return false;
      }
      if (_filterRegion.isNotEmpty && !eq.location.toLowerCase().contains(_filterRegion.toLowerCase())) return false;
      if (_filterType.isNotEmpty && !eq.type.toLowerCase().contains(_filterType.toLowerCase())) return false;
      if (eq.price < _minPrice || eq.price > _maxPrice) return false;
      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.get('find_equipment')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '${t.get("find_equipment")}...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Equipment>>(
        stream: _firestoreService.getAllEquipment(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allEquipment = snapshot.data ?? [];
          final filtered = _filterEquipment(allEquipment);
          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(t.get('no_equipment'), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600])),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final eq = filtered[index];
              return EquipmentCard(equipment: eq, onTap: () => _showRentDialog(context, eq));
            },
          );
        },
      ),
    );
  }

  void _showRentDialog(BuildContext context, Equipment eq) {
    final t = appLocale;
    final daysController = TextEditingController(text: '1');
    DateTime? startDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            int days = int.tryParse(daysController.text) ?? 1;
            double total = eq.price * days;
            return Padding(
              padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 24),
                  Text(eq.type, style: Theme.of(ctx).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('${t.get("rental_price")}: ${eq.price.toStringAsFixed(0)} MAD/${t.get("day")}'),
                  Text('${t.get("location")}: ${eq.location}'),
                  if (eq.description.isNotEmpty) Text('${t.get("description")}: ${eq.description}'),
                  const Divider(height: 32),

                  // Start date
                  Text(t.get('select_start_date'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setSheetState(() => startDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(startDate != null ? startDate.toString().split(' ')[0] : t.get('select_date')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Duration
                  Text(t.get('duration_days'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: daysController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: '1',
                      suffixText: t.get('days'),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Total
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(t.get('total_price'), style: TextStyle(color: Colors.grey[600])),
                        Text('${total.toStringAsFixed(0)} MAD', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                        Text('(${t.get("daily_payment")})', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (startDate == null || days < 1)
                          ? null
                          : () async {
                              final renterId = FirebaseAuth.instance.currentUser!.uid;
                              final rental = EquipmentRental(
                                id: FirebaseFirestore.instance.collection('rentals').doc().id,
                                equipmentId: eq.id,
                                renterId: renterId,
                                ownerId: eq.ownerId,
                                pricePerDay: eq.price,
                                durationDays: days,
                                startDate: startDate!,
                              );
                              try {
                                await _firestoreService.requestRental(rental);
                                final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(eq.ownerId).get();
                                final ownerToken = ownerDoc.data()?['fcmToken'];
                                if (ownerToken != null) {
                                  await NotificationService.sendNotification(
                                    targetToken: ownerToken,
                                    title: t.get('new_rental_request'),
                                    body: '${eq.type} - $days ${t.get("days")}',
                                  );
                                }
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.get('rental_requested'))),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                }
                              }
                            },
                      icon: const Icon(Icons.agriculture),
                      label: Text(t.get('rent_now').toUpperCase()),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
