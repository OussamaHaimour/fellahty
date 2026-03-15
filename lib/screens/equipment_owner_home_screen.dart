import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart';
import '../models/equipment_model.dart';
import '../main.dart';
import 'add_equipment_screen.dart';
import 'equipment_list_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'wallet_screen.dart';
import 'owner_rentals_screen.dart';
import 'support_screen.dart';

class EquipmentOwnerHomeScreen extends StatefulWidget {
  const EquipmentOwnerHomeScreen({Key? key}) : super(key: key);

  @override
  State<EquipmentOwnerHomeScreen> createState() => _EquipmentOwnerHomeScreenState();
}

class _EquipmentOwnerHomeScreenState extends State<EquipmentOwnerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const EquipmentDashboard(),
    const EquipmentListScreen(),
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
            icon: const Icon(Icons.agriculture),
            selectedIcon: const Icon(Icons.agriculture),
            label: t.get('my_fleet'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: t.get('profile'),
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEquipmentScreen()));
              },
              icon: const Icon(Icons.add),
              label: Text(t.get('add_equipment')),
            )
          : null,
    );
  }
}

class EquipmentDashboard extends StatefulWidget {
  const EquipmentDashboard({Key? key}) : super(key: key);

  @override
  State<EquipmentDashboard> createState() => _EquipmentDashboardState();
}

class _EquipmentDashboardState extends State<EquipmentDashboard> {
  final _firestoreService = FirestoreService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  int _totalFleet = 0;
  int _rentedOut = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      _firestoreService.getEquipmentByOwner(_userId).first.then((list) {
        if (mounted) {
          setState(() {
            _totalFleet = list.length;
            _rentedOut = list.where((e) => !e.isAvailable).length;
            _loading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.get('equipment_dashboard')),
        actions: [
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
            Text(t.get('manage_equipment'), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),

            _loading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(context,
                          title: t.get('total_fleet'), value: '$_totalFleet',
                          icon: Icons.agriculture, color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(context,
                          title: t.get('rented_out'), value: '$_rentedOut',
                          icon: Icons.assignment_turned_in, color: Colors.orange,
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 32),
            Text(t.get('quick_actions'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            _buildActionCard(context,
              title: t.get('add_new_equipment'), subtitle: t.get('list_equipment'),
              icon: Icons.add_circle,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEquipmentScreen()));
              },
            ),

            _buildActionCard(context,
              title: t.get('rental_requests'),
              subtitle: t.get('manage_bookings'),
              icon: Icons.history,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const OwnerRentalsScreen()));
              },
            ),

            _buildActionCard(context,
              title: t.get('my_wallet'),
              subtitle: t.get('check_earnings'),
              icon: Icons.account_balance_wallet,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
              },
            ),

            _buildActionCard(context,
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
