import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/rental_model.dart';
import '../models/application_model.dart';
import '../models/equipment_model.dart';

class FarmerRentalsScreen extends StatefulWidget {
  const FarmerRentalsScreen({Key? key}) : super(key: key);

  @override
  State<FarmerRentalsScreen> createState() => _FarmerRentalsScreenState();
}

class _FarmerRentalsScreenState extends State<FarmerRentalsScreen> {
  final _firestoreService = FirestoreService();
  final _db = FirebaseFirestore.instance;
  late final String _userId;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;

    if (_userId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(t.get('my_rentals'))),
        body: const Center(child: Text('User not logged in')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.get('my_rentals'))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _db.collection('rentals')
            .where('renterId', isEqualTo: _userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.agriculture, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(t.get('no_rentals'),
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (ctx, i) {
              try {
                final data = docs[i].data();
                final rental = EquipmentRental.fromMap(data, docs[i].id);
                return _FarmerRentalCard(
                  key: ValueKey('${rental.id}_${rental.status}_${rental.dailyRecords.length}'),
                  rental: rental,
                  firestoreService: _firestoreService,
                );
              } catch (e) {
                return Card(
                  color: Colors.red.shade50,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _FarmerRentalCard extends StatefulWidget {
  final EquipmentRental rental;
  final FirestoreService firestoreService;

  const _FarmerRentalCard({
    Key? key,
    required this.rental,
    required this.firestoreService,
  }) : super(key: key);

  @override
  State<_FarmerRentalCard> createState() => _FarmerRentalCardState();
}

class _FarmerRentalCardState extends State<_FarmerRentalCard> {
  Equipment? _equipment;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('equipment').doc(widget.rental.equipmentId).get();
      if (mounted) {
        setState(() {
          if (doc.exists) _equipment = Equipment.fromDocument(doc);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    final rental = widget.rental;

    String eqName = _loading ? '...' : (_equipment?.type ?? t.get('no_equipment'));

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
            Text('💰 ${rental.pricePerDay.toStringAsFixed(0)} MAD/${t.get("day")} × ${rental.durationDays} ${t.get("days")}'),

            // Cancel button for pending
            if (rental.status == 'pending') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmCancel(rental.id, t),
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                  label: Text(t.get('cancel_rental'),
                      style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red)),
                ),
              ),
            ],

            // Info for active
            if (rental.status == 'active') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('⏳ ${t.get("active") ?? "Waiting for owner to finish"}', 
                    style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
              ),
            ],

            // Action for completed (Farmer needs to pay)
            if (rental.status == 'completed') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRatingAndPay(rental, t),
                  icon: const Icon(Icons.payment, size: 18),
                  label: Text(t.get('confirm_and_pay')),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
            ],

            // Info for paid
            if (rental.status == 'paid') ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('✅ ${t.get("paid")}', 
                    style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }



  void _showRatingAndPay(EquipmentRental rental, AppLocalizations t) {
    double rating = 5.0;
    final totalPrice = rental.pricePerDay * rental.durationDays;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t.get('rate_equipment')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.get('rate_before_pay')),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  onPressed: () => setDialogState(() => rating = i + 1.0),
                  icon: Icon(i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber, size: 36),
                )),
              ),
              const SizedBox(height: 16),
              Text('${totalPrice.toStringAsFixed(0)} MAD',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('(${rental.durationDays} days × ${rental.pricePerDay.toStringAsFixed(0)})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.get('cancel'))),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await widget.firestoreService.payEquipmentOwner(
                    rental.id, rental.ownerId, rental.renterId,
                    totalPrice, rating);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t.get('payment_success'))));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${t.get("error")}: $e')));
                  }
                }
              },
              icon: const Icon(Icons.payment),
              label: Text(t.get('confirm_and_pay')),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(String rentalId, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.get('confirm')),
        content: Text(t.get('cancel_rental_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.get('cancel'))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.firestoreService.cancelRental(rentalId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t.get('confirm')),
          ),
        ],
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
