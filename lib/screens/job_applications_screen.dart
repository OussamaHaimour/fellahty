import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/application_model.dart';
import '../models/job_model.dart';
import '../models/user_model.dart';

class JobApplicationsScreen extends StatefulWidget {
  final Job job;
  const JobApplicationsScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      appBar: AppBar(title: Text(t.get('applications'))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('applications')
            .where('jobId', isEqualTo: widget.job.id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final apps = snapshot.data!.docs.map((d) {
            try { return Application.fromMap(d.data(), d.id); } catch(_) { return null; }
          }).where((e) => e != null).cast<Application>().toList();

          if (apps.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(t.get('no_applications_yet') ?? 'No applications yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            itemBuilder: (ctx, i) => _buildApplicationCard(apps[i]),
          );
        },
      ),
    );
  }

  Widget _buildApplicationCard(Application app) {
    final t = appLocale;
    return FutureBuilder<UserModel?>(
      future: _firestoreService.getUser(app.workerId),
      builder: (context, userSnap) {
        final worker = userSnap.data;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Worker info
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(worker?.name ?? '...', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          if (worker != null)
                            Row(
                              children: [
                                const Icon(Icons.star, size: 14, color: Colors.amber),
                                Text(' ${worker.score.toStringAsFixed(1)}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                Text(' • ${worker.region}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                        ],
                      ),
                    ),
                    _statusBadge(app.status, t),
                  ],
                ),

                // Actions for pending
                if (app.status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _firestoreService.updateApplicationStatus(app.id, 'rejected'),
                          icon: const Icon(Icons.close, color: Colors.red, size: 18),
                          label: Text(t.get('reject'), style: const TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _firestoreService.updateApplicationStatus(app.id, 'accepted');
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.get('accepted'))));
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(t.get('accept')),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ],

                // Action for completed (Farmer needs to pay)
                if (app.status == 'completed' && worker != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showRatingAndPay(app, worker, t),
                      icon: const Icon(Icons.payment, size: 18),
                      label: Text(t.get('confirm_and_pay')),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                  ),
                ],

                // Info for active/accepted or paid
                if (app.status == 'accepted') ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text('⏳ ${t.get("waiting_worker_code") ?? "Waiting for worker to finish"}', 
                        style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold)),
                  ),
                ],

                if (app.status == 'paid') ...[
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
      },
    );
  }

  void _showRatingAndPay(Application app, UserModel worker, AppLocalizations t) {
    double rating = 5.0;
    final totalSalary = widget.job.salaryPerDay * widget.job.durationDays;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(t.get('confirm_and_pay')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.get('rate_worker') ?? 'Rate the worker'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => IconButton(
                  onPressed: () => setDialogState(() => rating = i + 1.0),
                  icon: Icon(i < rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
                )),
              ),
              const SizedBox(height: 16),
              Text('${totalSalary.toStringAsFixed(0)} MAD', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text('(${widget.job.durationDays} days × ${widget.job.salaryPerDay.toStringAsFixed(0)})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.get('cancel'))),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _firestoreService.payWorker(
                    app.id, worker.id, widget.job.farmerId, 
                    totalSalary, rating
                  );
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.get('payment_success') ?? 'Payment done')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              icon: const Icon(Icons.payment),
              label: Text(t.get('confirm')),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, AppLocalizations t) {
    Color color = Colors.orange;
    String label = t.get('pending');
    if (status == 'accepted') { color = Colors.blue; label = t.get('accepted'); }
    if (status == 'completed') { color = Colors.green; label = t.get('completed') ?? 'Completed'; }
    if (status == 'paid') { color = Colors.purple; label = t.get('paid'); }
    if (status == 'rejected') { color = Colors.red; label = t.get('rejected'); }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
