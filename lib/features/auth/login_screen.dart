import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
import '../../core/settings_provider.dart';
import '../../theme/app_colors.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  void _loadRememberedUser() {
    final prefs = ref.read(sharedPrefsProvider);
    final savedEmail = prefs.getString('remember_email');
    final savedPassword = prefs.getString('remember_password');
    if (savedEmail != null && savedPassword != null) {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      setState(() => _rememberMe = true);
    }
  }

  void _saveRememberedUser() {
    final prefs = ref.read(sharedPrefsProvider);
    if (_rememberMe) {
      prefs.setString('remember_email', _emailController.text.trim());
      prefs.setString('remember_password', _passwordController.text.trim());
    } else {
      prefs.remove('remember_email');
      prefs.remove('remember_password');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      // 1. Real Login
      await ref.read(authServiceProvider).signIn(email, password);
      _saveRememberedUser();
      
      // On successful login, trigger a 3-second splash transition
      ref.read(forcedSplashProvider.notifier).state = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          ref.read(forcedSplashProvider.notifier).state = false;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Invalid email or password. Please try again.',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Reset Password', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address to receive a recovery link.',
              style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Recovery Email',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                prefixIcon: const Icon(Icons.mail_rounded, size: 20, color: Color(0xFF38BDF8)),
                fillColor: const Color(0xFF0B1120).withValues(alpha: 0.5),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text('CANCEL', style: TextStyle(color: Colors.white.withValues(alpha: 0.5)))
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              try {
                await ref.read(authServiceProvider).sendPasswordResetEmail(emailController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Recovery link sent! Check your inbox.',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Unable to process request. Please try again later.',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF38BDF8),
              minimumSize: const Size(100, 48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('SEND'),
          ),
        ],
      ),
    );
  }

  void _showDevelopmentMessage(BuildContext context) {
    // For social buttons, since they are "under development", we don't trigger a splash.
    // But if they WERE working, we'd add the splash here.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This feature is currently unavailable and under development.',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF38BDF8),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF38BDF8);
    const surfaceColor = Color(0xFF1E293B);
    const bgColor = Color(0xFF0B1120);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          
          // Subtle particle/wave effect simulation (top left)
          Positioned(
            top: 20,
            left: -40,
            child: Opacity(
              opacity: 0.4,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      accentColor.withValues(alpha: 0.2),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Animated Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(-20 * (1 - value), 0),
                            child: Opacity(
                              opacity: value,
                              child: IconButton(
                                onPressed: () => context.pop(),
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: surfaceColor.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Logo with glowing border
                    Center(
                      child: Container(
                        width: 130,
                        height: 130,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38BDF8), Color(0xFF6366F1), Color(0xFF34D399)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(36),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Hero(
                            tag: 'app_logo',
                            child: Image.asset(
                              'assets/images/rounded-image.png', // Updated logo
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(Icons.auto_awesome_mosaic_rounded, color: accentColor, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                        children: [
                          const TextSpan(text: 'Welcome '),
                          TextSpan(
                            text: 'Back',
                            style: TextStyle(color: accentColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Access your premium marketplace',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Main Card Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            hint: 'Email Address',
                            icon: Icons.mail_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v!.isEmpty ? 'Email is required' : null,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Password',
                            icon: Icons.lock_rounded,
                            isPassword: true,
                            isObscured: _obscurePassword,
                            toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: (v) => v!.isEmpty ? 'Password is required' : null,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: _rememberMe ? accentColor : Colors.white24,
                                          width: 1.5,
                                        ),
                                        color: _rememberMe ? accentColor : Colors.transparent,
                                      ),
                                      child: _rememberMe 
                                          ? const Icon(Icons.check, size: 14, color: Colors.white) 
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Remember me',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white.withValues(alpha: 0.6),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _showForgotPasswordDialog,
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: accentColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Sign In Button
                          InkWell(
                            onTap: _isLoading ? null : _login,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [accentColor, Color(0xFF2563EB)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isLoading)
                                    const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  else ...[
                                    const Spacer(flex: 2),
                                    Text(
                                      'SIGN IN',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 16),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // OR Continue With
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.white10)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.25),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.white10)),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Social Login Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialTile(
                          icon: 'assets/icons/google.png', 
                          isIcon: true,
                          iconData: Icons.g_mobiledata_rounded, // Using built-in icon as fallback
                          iconColor: Colors.white,
                          onTap: () => _showDevelopmentMessage(context),
                        ),
                        const SizedBox(width: 20),
                        _SocialTile(
                          icon: 'assets/icons/apple.png', 
                          isIcon: true, 
                          iconData: Icons.apple_rounded, 
                          onTap: () => _showDevelopmentMessage(context),
                        ),
                        const SizedBox(width: 20),
                        _SocialTile(
                          icon: 'assets/icons/email.png', 
                          isIcon: true, 
                          iconData: Icons.mail_rounded, 
                          color: accentColor.withValues(alpha: 0.1), 
                          iconColor: accentColor, 
                          onTap: () => _showDevelopmentMessage(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Sign Up Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                      ),
                      child: InkWell(
                        onTap: () => context.push('/signup'),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.person_outline_rounded, color: accentColor, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Don't have an account?",
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Sign Up',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: accentColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.3)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Footer
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified_user_outlined, color: accentColor, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Secure. Reliable. Premium.',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.3),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'POWERED BY',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.15),
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Zenvyro Labs X Awais',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    const accentColor = Color(0xFF38BDF8);

    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.2), fontSize: 15),
        prefixIcon: Icon(icon, size: 20, color: accentColor),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(
            isObscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.white.withValues(alpha: 0.3),
            size: 20,
          ),
          onPressed: toggleObscure,
        ) : null,
        filled: true,
        fillColor: const Color(0xFF0B1120).withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: accentColor, width: 1.5),
        ),
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  final String icon;
  final bool isIcon;
  final IconData? iconData;
  final Color? color;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SocialTile({required this.icon, this.isIcon = false, this.iconData, this.color, this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color ?? const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: isIcon 
            ? Icon(iconData, color: iconColor ?? Colors.white, size: 28)
            : Image.asset(icon, width: 24, errorBuilder: (c,e,s) => const Icon(Icons.public, color: Colors.white24)),
        ),
      ),
    );
  }
}
