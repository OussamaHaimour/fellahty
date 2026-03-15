import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/rental_model.dart';
import '../models/application_model.dart';
import '../models/equipment_model.dart';
import '../models/user_model.dart';

class OwnerRentalsScreen extends StatefulWidget {
  const OwnerRentalsScreen({Key? key}) : super(key: key);

  @override
  State<OwnerRentalsScreen> createState() => _OwnerRentalsScreenState();
}

class _OwnerRentalsScreenState extends State<OwnerRentalsScreen> {
  final _firestoreService = FirestoreService();
  final _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        setState(() { _error = 'Not logged in'; _loading = false; });
        return;
      }

      final rentalSnapshot = await _db.collection('rentals')
          .where('ownerId', isEqualTo: uid)
          .get();

      List<Map<String, dynamic>> items = [];

      for (var doc in rentalSnapshot.docs) {
        try {
          final rental = EquipmentRental.fromMap(doc.data(), doc.id);

          Equipment? eq;
          UserModel? renter;
          try {
            final eqDoc = await _db.collection('equipment').doc(rental.equipmentId).get();
            if (eqDoc.exists) eq = Equipment.fromDocument(eqDoc);
          } catch (_) {}
          try {
            renter = await _firestoreService.getUser(rental.renterId);
          } catch (_) {}

          items.add({'rental': rental, 'equipment': eq, 'renter': renter});
        } catch (e) {
          items.add({'error': 'Parse error: $e', 'docId': doc.id});
        }
      }

      if (mounted) {
        setState(() { _items = items; _loading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.get('rental_requests')),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: Text(t.get('retry'))),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(t.get('no_rentals'),
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: Text(t.get('retry')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (ctx, i) {
          final item = _items[i];
          if (item.containsKey('error')) {
            return Card(
              color: Colors.red.shade50,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${item['error']}', style: const TextStyle(color: Colors.red)),
              ),
            );
          }

          final rental = item['rental'] as EquipmentRental;
          final eq = item['equipment'] as Equipment?;
          final renter = item['renter'] as UserModel?;
          return _buildRentalCard(rental, eq, renter, t);
        },
      ),
    );
  }

  Widget _buildRentalCard(EquipmentRental rental, Equipment? eq, UserModel? renter, AppLocalizations t) {
    String eqName = eq?.type ?? t.get('no_equipment');
    String renterName = renter?.name ?? '...';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(eqName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                _statusBadge(rental.status, t),
              ],
            ),
            const SizedBox(height: 4),
            Text('👤 ${t.get("renter")}: $renterName'),
            Text('💰 ${rental.pricePerDay.toStringAsFixed(0)} MAD/${t.get("day")} × ${rental.durationDays} ${t.get("days")}'),

            // Accept/Reject for pending
            if (rental.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await _firestoreService.updateRentalStatus(rental.id, 'rejected');
                        _loadData();
                      },
                      icon: const Icon(Icons.close, color: Colors.red, size: 18),
                      label: Text(t.get('reject'), style: const TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _firestoreService.updateRentalStatus(rental.id, 'active');
                        _loadData();
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(t.get('accept')),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],
              ),
            ],

            // Finish rental action for active
            if (rental.status == 'active') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _firestoreService.completeRental(rental.id);
                    _loadData();
                  },
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: Text(t.get('finish_rental') ?? 'Finish Rental'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ),
            ],

            // Completed/Paid info
            if (rental.status == 'completed') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('⏳ ${t.get("waiting_farmer_confirmation")}', 
                    style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)),
              ),
            ],

            if (rental.status == 'paid') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('✅ ${t.get("paid")}', 
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _statusBadge(String status, AppLocalizations t) {
    Color color = Colors.orange;
    String label = t.get('pending');
    if (status == 'active') { color = Colors.blue; label = t.get('active'); }
    if (status == 'completed') { color = Colors.orange; label = t.get('completed') ?? 'Completed'; }
    if (status == 'paid') { color = Colors.purple; label = t.get('paid'); }
    if (status == 'rejected') { color = Colors.red; label = t.get('rejected'); }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
