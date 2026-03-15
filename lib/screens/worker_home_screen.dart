import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../main.dart';
import 'browse_jobs_screen.dart';
import 'worker_applications_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'wallet_screen.dart';
import 'support_screen.dart';

class WorkerHomeScreen extends StatefulWidget {
  const WorkerHomeScreen({Key? key}) : super(key: key);

  @override
  State<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends State<WorkerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const WorkerDashboard(),
    const BrowseJobsScreen(),
    const WorkerApplicationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: t.get('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: const Icon(Icons.search),
            label: t.get('find_jobs'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.work_history_outlined),
            selectedIcon: const Icon(Icons.work_history),
            label: t.get('applications'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: t.get('profile'),
          ),
        ],
      ),
    );
  }

  void switchToTab(int index) {
    setState(() => _currentIndex = index);
  }
}

class WorkerDashboard extends StatefulWidget {
  const WorkerDashboard({Key? key}) : super(key: key);

  @override
  State<WorkerDashboard> createState() => _WorkerDashboardState();
}

class _WorkerDashboardState extends State<WorkerDashboard> {
  final _firestoreService = FirestoreService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  int _currentJobs = 0;
  double _score = 0.0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final jobs = await _firestoreService.countAcceptedJobsForWorker(_userId);
      final score = await _firestoreService.getWorkerScore(_userId);
      if (mounted) {
        setState(() {
          _currentJobs = jobs;
          _score = score;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(t.get('worker_dashboard')),
        actions: [
          // Language switcher
          PopupMenuButton<AppLanguage>(
            icon: const Icon(Icons.language),
            onSelected: (lang) {
              FellahtyApp.setLocale(context, lang);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: AppLanguage.fr, child: Text('🇫🇷 Français')),
              const PopupMenuItem(value: AppLanguage.ar, child: Text('🇲🇦 العربية')),
              const PopupMenuItem(value: AppLanguage.en, child: Text('🇬🇧 English')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.get('welcome'), style: Theme.of(context).textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(t.get('find_work'), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),

            // Dynamic Stats
            _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: t.get('current_jobs'),
                          value: '$_currentJobs',
                          icon: Icons.work,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          title: t.get('score'),
                          value: _score == 0 ? '-' : _score.toStringAsFixed(1),
                          icon: Icons.star,
                          color: Colors.amber,
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 32),
            Text(t.get('quick_actions'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            _buildActionCard(
              context,
              title: t.get('browse_jobs'),
              subtitle: t.get('new_opportunities'),
              icon: Icons.search,
              onTap: () {
                final parentState = context.findAncestorStateOfType<_WorkerHomeScreenState>();
                parentState?.switchToTab(1);
              },
            ),

            _buildActionCard(
              context,
              title: t.get('view_applications'),
              subtitle: t.get('check_status'),
              icon: Icons.assignment,
              onTap: () {
                final parentState = context.findAncestorStateOfType<_WorkerHomeScreenState>();
                parentState?.switchToTab(2);
              },
            ),

            _buildActionCard(
              context,
              title: t.get('my_wallet'),
              subtitle: t.get('check_earnings'),
              icon: Icons.account_balance_wallet,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
              },
            ),

            _buildActionCard(
              context,
              title: t.get('support'),
              subtitle: t.get('support_subtitle'),
              icon: Icons.headset_mic,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String title, required String value,
    required IconData icon, required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.displayMedium),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title, required String subtitle,
    required IconData icon, required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
