import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/job_model.dart';
import '../models/application_model.dart';
import '../widgets/job_card.dart';

class BrowseJobsScreen extends StatefulWidget {
  const BrowseJobsScreen({Key? key}) : super(key: key);

  @override
  State<BrowseJobsScreen> createState() => _BrowseJobsScreenState();
}

class _BrowseJobsScreenState extends State<BrowseJobsScreen> {
  final _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final _searchController = TextEditingController();
  bool _isLoading = false;
  String _searchQuery = '';

  // Filter values
  String _filterRegion = '';
  double _minSalary = 0;
  double _maxSalary = 10000;
  DateTime? _filterDate;

  Future<void> _applyToJob(Job job) async {
    final existingApp = await FirebaseFirestore.instance
        .collection('applications')
        .where('jobId', isEqualTo: job.id)
        .where('workerId', isEqualTo: _currentUserId)
        .get();

    if (existingApp.docs.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocale.get('already_applied'))),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final docRef = FirebaseFirestore.instance.collection('applications').doc();
      final application = Application(
        id: docRef.id,
        jobId: job.id,
        workerId: _currentUserId,
      );

      await _firestoreService.applyToJob(application);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocale.get('applied'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appLocale.get("error")}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Job> _filterJobs(List<Job> jobs) {
    return jobs.where((job) {
      // Text search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!job.jobTitle.toLowerCase().contains(q) &&
            !job.location.toLowerCase().contains(q)) {
          return false;
        }
      }
      // Region filter
      if (_filterRegion.isNotEmpty) {
        if (!job.location.toLowerCase().contains(_filterRegion.toLowerCase())) {
          return false;
        }
      }
      // Salary filter
      if (job.salaryPerDay < _minSalary || job.salaryPerDay > _maxSalary) {
        return false;
      }
      // Date filter
      if (_filterDate != null) {
        if (job.startDate.isBefore(_filterDate!)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showFilterSheet() {
    final t = appLocale;
    final regionCtrl = TextEditingController(text: _filterRegion);
    double tempMin = _minSalary;
    double tempMax = _maxSalary;
    DateTime? tempDate = _filterDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('🔍 ${t.get("find_jobs")}',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),

                  // Region
                  TextField(
                    controller: regionCtrl,
                    decoration: InputDecoration(
                      labelText: t.get('region'),
                      prefixIcon: const Icon(Icons.location_on),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Salary range
                  Text('${t.get("salary_per_day")} (MAD)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  RangeSlider(
                    values: RangeValues(tempMin, tempMax),
                    min: 0,
                    max: 10000,
                    divisions: 100,
                    labels: RangeLabels(
                      '${tempMin.toInt()}',
                      '${tempMax.toInt()}',
                    ),
                    onChanged: (values) {
                      setSheetState(() {
                        tempMin = values.start;
                        tempMax = values.end;
                      });
                    },
                  ),
                  Text('${tempMin.toInt()} - ${tempMax.toInt()} MAD',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Date filter
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: tempDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setSheetState(() => tempDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      tempDate != null
                          ? '${t.get("start_date")}: ${tempDate!.day}/${tempDate!.month}/${tempDate!.year}'
                          : t.get('select_start_date'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Apply / Reset buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filterRegion = '';
                              _minSalary = 0;
                              _maxSalary = 10000;
                              _filterDate = null;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Text(t.get('cancel')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filterRegion = regionCtrl.text.trim();
                              _minSalary = tempMin;
                              _maxSalary = tempMax;
                              _filterDate = tempDate;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Text(t.get('apply')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool get _hasActiveFilters {
    return _filterRegion.isNotEmpty || _minSalary > 0 || _maxSalary < 10000 || _filterDate != null;
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
        title: Text(t.get('available_jobs')),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '${t.get("find_jobs")}...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: _showFilterSheet,
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<Job>>(
        stream: _firestoreService.getOpenJobs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('${t.get("error")}: ${snapshot.error}'));
          }

          final allJobs = snapshot.data ?? [];
          final jobs = _filterJobs(allJobs);

          if (allJobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(t.get('no_jobs'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          if (jobs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_list_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(t.get('no_jobs'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: jobs.length,
                itemBuilder: (context, index) {
                  final job = jobs[index];
                  return JobCard(
                    job: job,
                    onTap: () => _showJobDetails(context, job),
                    trailing: ElevatedButton(
                      onPressed: () => _applyToJob(job),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(80, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(t.get('apply_now')),
                    ),
                  );
                },
              ),
              if (_isLoading)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showJobDetails(BuildContext context, Job job) {
    final t = appLocale;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(job.jobTitle, style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: Text(t.get('location')),
                    subtitle: Text(job.location),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: const Icon(Icons.attach_money),
                    title: Text(t.get('salary_per_day')),
                    subtitle: Text('${job.salaryPerDay.toStringAsFixed(0)} MAD'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: Text(t.get('workers_needed')),
                    subtitle: Text('${job.workersNeeded}'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(t.get('start_date')),
                    subtitle: Text('${job.startDate.day}/${job.startDate.month}/${job.startDate.year}'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _applyToJob(job);
                      },
                      child: Text(t.get('apply_now').toUpperCase()),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
