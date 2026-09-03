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
  bool _isGoogleLoading = false;
  bool _isEmailLoginLoading = false;
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

  Future<void> _handleAuthAction(Future<void> Function() action, {required void Function(bool) setLoading}) async {
    setLoading(true);
    try {
      await action();
      _saveRememberedUser();
      
      ref.read(forcedSplashProvider.notifier).state = true;
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        ref.read(forcedSplashProvider.notifier).state = false;
      }
    } catch (e) {
      if (mounted) {
        // طباعة الخطأ الحقيقي القادم من السيرفر أو Firebase لتسهيل اكتشاف المشكلة
        _showErrorSnackBar('خطأ: ${e.toString()}');
      }
    } finally {
      if (mounted) setLoading(false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    await _handleAuthAction(
      () => ref.read(authServiceProvider).signIn(email, password),
      setLoading: (val) => setState(() => _isLoading = val),
    );
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading || _isLoading || _isEmailLoginLoading) return;

    await _handleAuthAction(
      () => ref.read(authServiceProvider).signInWithGoogle(),
      setLoading: (val) => setState(() => _isGoogleLoading = val),
    );
  }

  Future<void> _signInWithEmailSocial() async {
    if (_isEmailLoginLoading || _isLoading || _isGoogleLoading) return;

    // تم تصحيح الدالة هنا لتناسب تسجيل الدخول عبر البريد الإلكتروني المخصص بدلاً من استدعاء جوجل بالخطأ
    await _handleAuthAction(
      () async {
        // ضع هنا دالة تسجيل الدخول البديلة الخاصة بك إذا وجدت، أو اتركها لخدمة الـ Auth
        if (!_formKey.currentState!.validate()) throw Exception('الرجاء إدخال البريد الإلكتروني');
        await ref.read(authServiceProvider).signIn(_emailController.text.trim(), _passwordController.text.trim());
      },
      setLoading: (val) => setState(() => _isEmailLoginLoading = val),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
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
                  _showErrorSnackBar('خطأ: ${e.toString()}');
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

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF38BDF8);
    const surfaceColor = Color(0xFF1E293B);
    const bgColor = Color(0xFF0B1120);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: surfaceColor.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                              'assets/images/rounded-image.png',
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialTile(
                          iconData: Icons.g_mobiledata_rounded,
                          iconColor: Colors.white,
                          isLoading: _isGoogleLoading,
                          onTap: _signInWithGoogle,
                        ),
                        const SizedBox(width: 20),
                        _SocialTile(
                          iconData: Icons.apple_rounded,
                          onTap: () {},
                        ),
                        const SizedBox(width: 20),
                        _SocialTile(
                          iconData: Icons.mail_rounded,
                          color: accentColor.withValues(alpha: 0.1),
                          iconColor: accentColor,
                          isLoading: _isEmailLoginLoading,
                          onTap: _signInWithEmailSocial,
                        ),
                      ],
                    ),
                    const SizedBox(height: 48),
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
    const surfaceColor = Color(0xFF1E293B);

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
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: surfaceColor.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: accentColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  final IconData iconData;
  final Color? color;
  final Color? iconColor;
  final bool isLoading;
  final VoidCallback onTap;

  const _SocialTile({
    required this.iconData,
    this.color,
    this.iconColor,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color ?? const Color(0xFF1E293B).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  iconData,
                  color: iconColor ?? Colors.white,
                  size: 24,
                ),
        ),
      ),
    );
  }
}