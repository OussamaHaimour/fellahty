import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/app_localizations.dart';
import '../main.dart';
import '../widgets/custom_text_field.dart';
import 'register_screen.dart';
import 'splash_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (user != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appLocale.get('error'))),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Language switcher at top
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: PopupMenuButton<AppLanguage>(
                      icon: const Icon(Icons.language, size: 28),
                      onSelected: (lang) {
                        FellahtyApp.setLocale(context, lang);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: AppLanguage.ar, child: Text('🇲🇦 العربية')),
                        const PopupMenuItem(value: AppLanguage.fr, child: Text('🇫🇷 Français')),
                        const PopupMenuItem(value: AppLanguage.en, child: Text('🇬🇧 English')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Icon(
                    Icons.agriculture,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    t.get('welcome'),
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.get('connect_grow'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  CustomTextField(
                    label: t.get('email'),
                    hint: t.get('email'),
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) => val == null || val.isEmpty ? t.get('email') : null,
                  ),
                  CustomTextField(
                    label: t.get('password'),
                    hint: t.get('password'),
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    isPassword: true,
                    validator: (val) => val == null || val.isEmpty ? t.get('password') : null,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _login,
                          child: Text(t.get('login').toUpperCase()),
                        ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.get('no_account')),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen()),
                          );
                        },
                        child: Text(t.get('register_here')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
