import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class DeveloperProfileScreen extends StatelessWidget {
  const DeveloperProfileScreen({super.key});

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Developer Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Header Section
            _buildHeroHeader(colorScheme),
            const SizedBox(height: 32),

            // Bio Section
            _buildSection(
              title: 'ABOUT ME',
              content: 'I am a Computer Science student and Flutter developer from Pakistan, passionate about creating modern, user-friendly, and high-performance mobile applications.\n\nI specializes in developing Android and iOS apps using Flutter, with experience integrating Firebase, authentication systems, cloud storage, push notifications, and responsive UI/UX design. My projects focus on clean architecture, scalability, and delivering smooth user experiences.',
              colorScheme: colorScheme,
            ),
            
            const SizedBox(height: 32),

            // Skills Section
            _buildSkillsGrid(colorScheme),

            const SizedBox(height: 32),

            // Interests & Mission
            _buildSection(
              title: 'MISSION',
              content: 'To build reliable, innovative, and visually appealing applications that solve real-world problems while continuously learning new technologies and following industry best practices.',
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 32),

            // Social Links
            _buildSocialLinks(colorScheme),
            
            const SizedBox(height: 60),
            
            Text(
              'Zen Mart Pro • Built with ❤️ by Awais',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 20))
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Center(
              child: Text(
                'AT',
                style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Awais Tariq',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Computer Science Student • Flutter Expert',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content, required ColorScheme colorScheme}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.7,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsGrid(ColorScheme colorScheme) {
    final skills = [
      'Flutter & Dart', 'Firebase', 'REST APIs', 'UI/UX Design', 
      'Git & GitHub', 'Java', 'Python', 'C++', 'Node.js'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'TECHNICAL SKILLS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: skills.map((skill) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
            ),
            child: Text(
              skill,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSocialLinks(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _SocialTile(
            label: 'LinkedIn',
            icon: Icons.link_rounded,
            color: const Color(0xFF0077B5),
            onTap: () => _launchUrl('https://www.linkedin.com/in/awais-tariq-87b64a28a/'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SocialTile(
            label: 'GitHub',
            icon: Icons.terminal_rounded,
            color: const Color(0xFF181717),
            onTap: () => _launchUrl('https://github.com/awaist618'),
          ),
        ),
      ],
    );
  }
}

class _SocialTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SocialTile({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
