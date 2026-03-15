import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/job_model.dart';
import '../widgets/job_card.dart';
import 'job_applications_screen.dart';

class FarmerJobsScreen extends StatefulWidget {
  const FarmerJobsScreen({Key? key}) : super(key: key);

  @override
  State<FarmerJobsScreen> createState() => _FarmerJobsScreenState();
}

class _FarmerJobsScreenState extends State<FarmerJobsScreen> {
  final _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.get('my_posted_jobs')),
      ),
      body: StreamBuilder<List<Job>>(
        stream: _firestoreService.getJobsByFarmer(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${t.get("error")}: ${snapshot.error}'));
          }

          final jobs = snapshot.data ?? [];

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.work_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    t.get('no_jobs_posted'),
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
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return JobCard(
                job: job,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => JobApplicationsScreen(job: job),
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('applications')
                          .where('jobId', isEqualTo: job.id)
                          .get(),
                      builder: (context, appSnapshot) {
                        if (!appSnapshot.hasData) return const SizedBox();
                        final count = appSnapshot.data!.docs.length;
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 4),
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
                                  await _firestoreService.deleteJob(job.id);
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
