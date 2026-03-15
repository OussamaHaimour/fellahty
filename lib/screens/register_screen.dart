import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/app_localizations.dart';
import '../main.dart';
import '../widgets/custom_text_field.dart';
import 'splash_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _regionController = TextEditingController();

  String _selectedRole = 'worker';
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = await _authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _nameController.text.trim(),
          _phoneController.text.trim(),
          _selectedRole,
          _regionController.text.trim(),
        );

        if (user != null && mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    final roles = [
      {'value': 'farmer', 'label': t.get('farmer'), 'icon': Icons.agriculture},
      {'value': 'worker', 'label': t.get('worker'), 'icon': Icons.pan_tool},
      {'value': 'equipment_owner', 'label': t.get('equipment_owner'), 'icon': Icons.agriculture},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.get('register')),
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.displayLarge?.color,
        elevation: 0,
        actions: [
          PopupMenuButton<AppLanguage>(
            icon: const Icon(Icons.language),
            onSelected: (lang) {
              FellahtyApp.setLocale(context, lang);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: AppLanguage.ar, child: Text('🇲🇦 العربية')),
              const PopupMenuItem(value: AppLanguage.fr, child: Text('🇫🇷 Français')),
              const PopupMenuItem(value: AppLanguage.en, child: Text('🇬🇧 English')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.get('select_role'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                // Role Selection Cards
                Column(
                  children: roles.map((role) {
                    final isSelected = _selectedRole == role['value'];
                    return Card(
                      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => setState(() => _selectedRole = role['value'] as String),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(
                                role['icon'] as IconData,
                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  role['label'] as String,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),
                Text(t.get('name'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),

                CustomTextField(
                  label: t.get('name'),
                  hint: t.get('name'),
                  icon: Icons.person_outline,
                  controller: _nameController,
                  validator: (val) => val == null || val.isEmpty ? t.get('name') : null,
                ),

                CustomTextField(
                  label: t.get('email'),
                  hint: t.get('email'),
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return t.get('email');
                    if (!val.contains('@')) return t.get('email');
                    return null;
                  },
                ),

                CustomTextField(
                  label: t.get('phone'),
                  hint: t.get('phone'),
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? t.get('phone') : null,
                ),

                CustomTextField(
                  label: t.get('region'),
                  hint: t.get('region'),
                  icon: Icons.location_on_outlined,
                  controller: _regionController,
                  validator: (val) => val == null || val.isEmpty ? t.get('region') : null,
                ),

                CustomTextField(
                  label: t.get('password'),
                  hint: t.get('password'),
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                  validator: (val) {
                    if (val == null || val.isEmpty) return t.get('password');
                    if (val.length < 6) return t.get('password');
                    return null;
                  },
                ),

                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        child: Text(t.get('register').toUpperCase()),
                      ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
