import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/application_model.dart';
import '../models/job_model.dart';

class WorkerApplicationsScreen extends StatefulWidget {
  const WorkerApplicationsScreen({Key? key}) : super(key: key);

  @override
  State<WorkerApplicationsScreen> createState() => _WorkerApplicationsScreenState();
}

class _WorkerApplicationsScreenState extends State<WorkerApplicationsScreen> {
  final _firestoreService = FirestoreService();
  final _db = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _items = []; // Each item: {app: Application, job: Job?}
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

      // Get all applications for this worker
      final appSnapshot = await _db.collection('applications')
          .where('workerId', isEqualTo: uid)
          .get();

      List<Map<String, dynamic>> items = [];

      for (var doc in appSnapshot.docs) {
        try {
          final app = Application.fromMap(doc.data(), doc.id);

          // Load the job
          Job? job;
          try {
            final jobDoc = await _db.collection('jobs').doc(app.jobId).get();
            if (jobDoc.exists) {
              job = Job.fromDocument(jobDoc);
            }
          } catch (_) {}

          items.add({'app': app, 'job': job});
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
        title: Text(t.get('my_applications')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _buildBody(t),
    );
  }

  Widget _buildBody(AppLocalizations t) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error', style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
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
            Text(t.get('no_applications'),
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

          // Handle parse errors
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

          final app = item['app'] as Application;
          final job = item['job'] as Job?;
          return _buildAppCard(app, job, t);
        },
      ),
    );
  }

  Widget _buildAppCard(Application app, Job? job, AppLocalizations t) {
    String jobTitle = job?.jobTitle ?? t.get('no_jobs');
    String location = job?.location ?? '';
    double salary = job?.salaryPerDay ?? 0;
    int duration = job?.durationDays ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with job info and status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(jobTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                _statusBadge(app.status, t),
              ],
            ),
            if (location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('📍 $location', style: TextStyle(color: Colors.grey[600])),
              Text('💰 ${salary.toStringAsFixed(0)} MAD/${t.get("day")} × $duration ${t.get("days")}',
                  style: TextStyle(color: Colors.grey[600])),
            ],

            // Cancel button for pending
            if (app.status == 'pending') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await _showConfirmDialog(
                        t.get('confirm'), t.get('cancel_application_confirm'), t);
                    if (confirmed == true) {
                      await _firestoreService.cancelApplication(app.id);
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                  label: Text(t.get('cancel_application'),
                      style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ),
            ],

            // Complete button for accepted
            if (app.status == 'accepted') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await _showConfirmDialog(
                        t.get('confirm'), t.get('finish_work_confirm') ?? 'Mark as completed?', t);
                    if (confirmed == true) {
                      await _firestoreService.completeApplication(app.id);
                      _loadData();
                    }
                  },
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: Text(t.get('finish_work') ?? 'Finish Work'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
            ],
            
            // Info for completed/paid
            if (app.status == 'completed') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('⏳ ${t.get("waiting_farmer_confirmation")}',
                    style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)),
              ),
            ],
            if (app.status == 'paid') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('✅ ${t.get("paid")}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Future<bool?> _showConfirmDialog(String title, String content, AppLocalizations t) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.get('cancel'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
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
    if (status == 'completed') { color = Colors.blue; label = t.get('completed') ?? 'Completed'; }
    if (status == 'paid') { color = Colors.purple; label = t.get('paid'); }
    if (status == 'rejected') { color = Colors.red; label = t.get('rejected'); }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
