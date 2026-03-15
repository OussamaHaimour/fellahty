import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../services/notification_service.dart';
import '../models/job_model.dart';
import '../widgets/custom_text_field.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({Key? key}) : super(key: key);

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _workersController = TextEditingController();
  final _salaryController = TextEditingController();
  final _locationController = TextEditingController();
  final _durationController = TextEditingController(text: '1');
  
  DateTime? _selectedDate;
  bool _isLoading = false;
  final _firestoreService = FirestoreService();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitJob() async {
    final t = appLocale;
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.get('select_date'))),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final docRef = FirebaseFirestore.instance.collection('jobs').doc();
        
        final job = Job(
          id: docRef.id,
          farmerId: userId,
          jobTitle: _titleController.text.trim(),
          workersNeeded: int.parse(_workersController.text),
          salaryPerDay: double.parse(_salaryController.text),
          location: _locationController.text.trim(),
          startDate: _selectedDate!,
          durationDays: int.parse(_durationController.text),
        );

        await _firestoreService.createJob(job);
        
        await NotificationService.notifyWorkersInRegion(
          job.location, t.get('new_job_available'), '${job.jobTitle} - ${job.location}'
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.get('job_posted'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${t.get("error")}: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _workersController.dispose();
    _salaryController.dispose();
    _locationController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      appBar: AppBar(title: Text(t.get('post_a_new_job'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.get('job_details'), style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              
              CustomTextField(
                label: t.get('job_title'),
                hint: t.get('job_title_hint'),
                icon: Icons.work_outline,
                controller: _titleController,
                validator: (val) => val == null || val.isEmpty ? t.get('error') : null,
              ),
              
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: t.get('workers_needed'),
                      hint: '5',
                      icon: Icons.people_outline,
                      controller: _workersController,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.isEmpty) return t.get('error');
                        if (int.tryParse(val) == null) return t.get('error');
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      label: '${t.get("salary_per_day")} (MAD)',
                      hint: '150',
                      icon: Icons.attach_money,
                      controller: _salaryController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (val) {
                        if (val == null || val.isEmpty) return t.get('error');
                        if (double.tryParse(val) == null) return t.get('error');
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              CustomTextField(
                label: t.get('location'),
                hint: t.get('location_hint'),
                icon: Icons.location_on_outlined,
                controller: _locationController,
                validator: (val) => val == null || val.isEmpty ? t.get('error') : null,
              ),

              CustomTextField(
                label: t.get('duration_days'),
                hint: '1',
                icon: Icons.timer_outlined,
                controller: _durationController,
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.isEmpty) return t.get('error');
                  if (int.tryParse(val) == null || int.parse(val) < 1) return t.get('error');
                  return null;
                },
              ),
              
              const SizedBox(height: 8),
              
              InkWell(
                onTap: () => _selectDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 16),
                      Text(
                        _selectedDate == null 
                            ? t.get('select_start_date')
                            : '${t.get("start_date")}: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                          color: _selectedDate == null ? Colors.grey.shade600 : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitJob,
                      child: Text(t.get('post_job').toUpperCase()),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
