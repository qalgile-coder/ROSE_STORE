import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';

class SupportCenterScreen extends StatelessWidget {
  const SupportCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rider Support', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/rider');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need Assistance?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text('Search our help desk or reach out to our team.', style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4), fontWeight: FontWeight.w500)),
            const SizedBox(height: 32),
            
            // Modern Search Bar
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
              ),
              child: TextField(
                style: const TextStyle(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search help topics...',
                  hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.2)),
                  prefixIcon: Icon(Icons.search_rounded, color: colorScheme.primary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            _SectionTitle(title: 'POPULAR ARTICLES', color: colorScheme.primary),
            const SizedBox(height: 16),
            _SupportItem(title: 'Optimizing delivery performance', icon: Icons.insights_rounded, colorScheme: colorScheme, onTap: () {}),
            _SupportItem(title: 'Earnings withdrawal policies', icon: Icons.payments_rounded, colorScheme: colorScheme, onTap: () {}),
            _SupportItem(title: 'Dealing with unavailable customers', icon: Icons.person_off_rounded, colorScheme: colorScheme, onTap: () {}),
            
            const SizedBox(height: 40),
            _SectionTitle(title: 'DIRECT CONTACT', color: colorScheme.primary),
            const SizedBox(height: 16),
            Row(
              children: [
                _ContactCard(
                  label: 'Support Hub',
                  icon: Icons.forum_rounded,
                  color: Colors.blue,
                  colorScheme: colorScheme,
                  onTap: () => context.push('/support'),
                ),
                const SizedBox(width: 16),
                _ContactCard(
                  label: 'Rider Helpline',
                  icon: Icons.headset_mic_rounded,
                  color: AppColors.rider,
                  colorScheme: colorScheme,
                  onTap: () => launchUrl(Uri.parse('tel:+923001234567')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SupportItem(title: 'Report a technical glitch', icon: Icons.bug_report_rounded, color: AppColors.error, colorScheme: colorScheme, onTap: () {}),
            _SupportItem(title: 'Terms and Conditions', icon: Icons.gavel_rounded, colorScheme: colorScheme, onTap: () {}),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;
  const _SectionTitle({required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Row(children: [const SizedBox(width: 4), Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6), letterSpacing: 2))]);
}

class _SupportItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _SupportItem({required this.title, required this.icon, this.color, required this.colorScheme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.05)),
        ),
        child: ListTile(
          leading: Icon(icon, color: color ?? AppColors.rider, size: 20),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.1)),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _ContactCard({required this.label, required this.icon, required this.color, required this.colorScheme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface, 
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
