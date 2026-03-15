import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';
import '../models/equipment_model.dart';
import '../models/rental_model.dart';
import '../models/application_model.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;
  final _firestoreService = FirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      appBar: AppBar(
        title: Text('${t.get("admin_panel")} 🛡️'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.bar_chart), text: t.get('app_statistics')),
            Tab(icon: const Icon(Icons.people), text: t.get('worker')),
            Tab(icon: const Icon(Icons.work), text: t.get('my_jobs')),
            Tab(icon: const Icon(Icons.agriculture), text: t.get('my_fleet')),
            Tab(icon: const Icon(Icons.handshake), text: t.get('rental_requests')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsTab(),
          _buildUsersTab(),
          _buildJobsTab(),
          _buildEquipmentTab(),
          _buildRentalsTab(),
        ],
      ),
    );
  }

  // ===================== TAB 1: STATISTICS =====================
  Widget _buildStatsTab() {
    final t = appLocale;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _revenueCard(),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _statTile(t.get('farmer'), 'users', whereField: 'role', whereValue: 'farmer')),
            const SizedBox(width: 12),
            Expanded(child: _statTile(t.get('worker'), 'users', whereField: 'role', whereValue: 'worker')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _statTile(t.get('equipment_owner'), 'users', whereField: 'role', whereValue: 'equipment_owner')),
            const SizedBox(width: 12),
            Expanded(child: _statTile(t.get('my_jobs'), 'jobs')),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _statTile(t.get('my_fleet'), 'equipment')),
            const SizedBox(width: 12),
            Expanded(child: _statTile(t.get('rental_requests'), 'rentals')),
          ]),
        ],
      ),
    );
  }

  // ===================== TAB 2: USERS =====================
  Widget _buildUsersTab() {
    final t = appLocale;
    return StreamBuilder<List<UserModel>>(
      stream: _firestoreService.getAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (ctx, i) {
            final user = users[i];
            final isBanned = user.toMap()['banned'] == true;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isBanned ? Colors.red.shade100 : Colors.green.shade100,
                  child: Icon(Icons.person, color: isBanned ? Colors.red : Colors.green),
                ),
                title: Text(user.name, style: TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: isBanned ? TextDecoration.lineThrough : null,
                )),
                subtitle: Text('${user.role} • ${user.email}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (val) async {
                    if (val == 'ban') {
                      await _firestoreService.toggleUserBan(user.id, true);
                    } else if (val == 'unban') {
                      await _firestoreService.toggleUserBan(user.id, false);
                    }
                  },
                  itemBuilder: (ctx) => [
                    if (!isBanned)
                      PopupMenuItem(value: 'ban', child: Row(children: [
                        const Icon(Icons.block, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text(t.get('ban_user')),
                      ])),
                    if (isBanned)
                      PopupMenuItem(value: 'unban', child: Row(children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Text(t.get('unban_user')),
                      ])),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===================== TAB 3: JOBS =====================
  Widget _buildJobsTab() {
    final t = appLocale;
    return StreamBuilder<List<Job>>(
      stream: _firestoreService.getAllJobs(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final jobs = snapshot.data!;
        if (jobs.isEmpty) return Center(child: Text(t.get('no_jobs')));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: jobs.length,
          itemBuilder: (ctx, i) {
            final job = jobs[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.work)),
                title: Text(job.jobTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${job.location} • ${job.salaryPerDay.toStringAsFixed(0)} MAD • ${job.durationDays} ${t.get("days")}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(t, () => _firestoreService.deleteJob(job.id)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===================== TAB 4: EQUIPMENT =====================
  Widget _buildEquipmentTab() {
    final t = appLocale;
    return StreamBuilder<List<Equipment>>(
      stream: _firestoreService.getAllEquipment(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        if (items.isEmpty) return Center(child: Text(t.get('no_equipment')));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final eq = items[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.agriculture)),
                title: Text(eq.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${eq.location} • ${eq.price.toStringAsFixed(0)} MAD/${t.get("day")}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(t, () => _firestoreService.deleteEquipment(eq.id)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===================== TAB 5: RENTALS =====================
  Widget _buildRentalsTab() {
    final t = appLocale;
    return StreamBuilder<List<EquipmentRental>>(
      stream: _firestoreService.getAllRentals(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final rentals = snapshot.data!;
        if (rentals.isEmpty) return Center(child: Text(t.get('no_rentals')));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: rentals.length,
          itemBuilder: (ctx, i) {
            final rental = rentals[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: rental.status == 'active' ? Colors.blue.shade100 : Colors.orange.shade100,
                  child: Icon(Icons.handshake, color: rental.status == 'active' ? Colors.blue : Colors.orange),
                ),
                title: Text('${rental.pricePerDay.toStringAsFixed(0)} MAD × ${rental.durationDays} ${t.get("days")}'),
                subtitle: Text('${t.get("pending")}: ${rental.status}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(t, () => _firestoreService.cancelRental(rental.id)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===================== HELPERS =====================
  void _confirmDelete(AppLocalizations t, Future<void> Function() onConfirm) {
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
              await onConfirm();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.get('success'))),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(t.get('confirm')),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String collection, {String? whereField, String? whereValue}) {
    return StreamBuilder<QuerySnapshot>(
      stream: whereField != null
          ? _db.collection(collection).where(whereField, isEqualTo: whereValue).snapshots()
          : _db.collection(collection).snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('$count', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _revenueCard() {
    final t = appLocale;
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('commissions').snapshots(),
      builder: (context, snapshot) {
        double total = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            total += (doc.data() as Map<String, dynamic>)['amount'] ?? 0.0;
          }
        }
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.black87, Colors.blueGrey]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.get('total_revenue'), style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text('${total.toStringAsFixed(2)} MAD',
                   style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(t.get('from_commissions'), style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}
