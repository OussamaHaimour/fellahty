import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_localizations.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final t = appLocale;
    return Scaffold(
      appBar: AppBar(title: Text(t.get('support'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.headset_mic, size: 48, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(t.get('support_title'), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(t.get('support_subtitle'), style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Contact options
            _buildContactCard(
              context,
              icon: Icons.email_outlined,
              title: t.get('email_support'),
              subtitle: 'support@fellahty.ma',
              onTap: () => _launchUrl('mailto:support@fellahty.ma'),
            ),
            _buildContactCard(
              context,
              icon: Icons.phone_outlined,
              title: t.get('phone_support'),
              subtitle: '+212 6XX XXX XXX',
              onTap: () => _launchUrl('tel:+212600000000'),
            ),
            _buildContactCard(
              context,
              icon: Icons.chat_outlined,
              title: 'WhatsApp',
              subtitle: t.get('whatsapp_support'),
              onTap: () => _launchUrl('https://wa.me/212600000000'),
            ),

            const SizedBox(height: 32),
            Text(t.get('faq'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            _buildFaqItem(context, t.get('faq_q1'), t.get('faq_a1')),
            _buildFaqItem(context, t.get('faq_q2'), t.get('faq_a2')),
            _buildFaqItem(context, t.get('faq_q3'), t.get('faq_a3')),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, {
    required IconData icon, required String title, required String subtitle, required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
        title: Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(answer, style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
