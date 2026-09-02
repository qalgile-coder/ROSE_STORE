import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../../core/providers.dart';
import '../../core/secrets.dart';
import '../../theme/app_colors.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpController = TextEditingController();
  final _referralController = TextEditingController();
  
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _obscurePassword = true;
  String? _generatedOtp;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your email'), backgroundColor: AppColors.error));
      return;
    }
    
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email format'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoading = true);
    final random = Random();
    _generatedOtp = (100000 + random.nextInt(900000)).toString();

    final smtpServer = gmail(AppSecrets.smtpEmail, AppSecrets.smtpPassword);
    final message = Message()
      ..from = const Address(AppSecrets.smtpEmail, 'Zen Mart Pro')
      ..recipients.add(email)
      ..subject = 'Verify Your Account - Zen Mart Pro'
      ..html = '''
        <div style="font-family: sans-serif; background-color: #0B1120; padding: 40px; color: #FFFFFF; text-align: center;">
          <div style="max-width: 500px; margin: auto; background: #1E293B; border-radius: 24px; padding: 40px; border: 1px solid rgba(255,255,255,0.05);">
            <h1 style="margin: 0; font-size: 24px; color: #38BDF8;">Zen Mart Pro</h1>
            <p style="color: #C5CBD8; font-size: 16px; margin: 20px 0;">Use the code below to verify your account</p>
            <div style="background: #0B1120; padding: 20px; border-radius: 12px; display: inline-block;">
              <span style="font-size: 32px; font-weight: 800; letter-spacing: 5px; color: #FFFFFF;">$_generatedOtp</span>
            </div>
            <p style="color: #6B7280; font-size: 12px; margin-top: 30px;">Valid for 10 minutes.</p>
          </div>
        </div>
      ''';

    try {
      await send(message, smtpServer);
      setState(() { _isLoading = false; _isOtpSent = true; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Verification code sent to your email.',
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
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send code. Please check your email and try again.',
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
  }

  Future<void> _verifyAndSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: AppColors.error));
      return;
    }
    if (_otpController.text.trim() != _generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).signUpCustomer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        referredBy: _referralController.text.trim().isEmpty ? null : _referralController.text.trim(),
      );

      // On successful signup, trigger a 3-second splash transition
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
              'Account creation failed. Please try again.',
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
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.1),
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
                    // Back Button
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
                    
                    // Logo with glowing border
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
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
                          const TextSpan(text: 'Join '),
                          TextSpan(
                            text: 'Zen Mart Pro',
                            style: TextStyle(color: accentColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your premium shopping journey today',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Feature Chips Row
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _FeatureItem(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'Secure',
                          subtitle: 'Your data is\nalways protected',
                        ),
                        _FeatureItem(
                          icon: Icons.local_offer_outlined,
                          title: 'Best Deals',
                          subtitle: 'Access exclusive\noffers & discounts',
                        ),
                        _FeatureItem(
                          icon: Icons.headset_mic_outlined,
                          title: '24/7 Support',
                          subtitle: "We're here\nto help you",
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Main Form Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                          _buildTextField(_nameController, 'Full Name', Icons.person_rounded),
                          const SizedBox(height: 16),
                          _buildTextField(_emailController, 'Email Address', Icons.email_rounded, enabled: !_isOtpSent, type: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildTextField(_phoneController, 'Phone Number', Icons.phone_rounded, type: TextInputType.phone),
                          const SizedBox(height: 16),
                          _buildTextField(
                            _passwordController, 
                            'Password', 
                            Icons.lock_rounded, 
                            isPassword: true,
                            isObscured: _obscurePassword,
                            toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            _confirmPasswordController, 
                            'Confirm Password', 
                            Icons.verified_user_outlined, 
                            isPassword: true, 
                            isObscured: _obscurePassword
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(_referralController, 'Referral Code (Optional)', Icons.card_giftcard_rounded, required: false),
                          
                          if (_isOtpSent) ...[
                            const SizedBox(height: 24),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 24),
                            _buildTextField(_otpController, 'Enter 6-Digit OTP', Icons.verified_rounded, type: TextInputType.number),
                            const SizedBox(height: 12),
                            Text(
                              "Check your email for the verification code.",
                              style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4), fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                          
                          const SizedBox(height: 32),
                          
                          // Continue Button
                          InkWell(
                            onTap: _isLoading ? null : (_isOtpSent ? _verifyAndSignup : _sendOtp),
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
                                      _isOtpSent ? 'VERIFY & REGISTER' : 'CONTINUE',
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
                    
                    const SizedBox(height: 32),
                    
                    // Login Link
                    Center(
                      child: GestureDetector(
                        onTap: () => context.push('/login'),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Login',
                                style: TextStyle(
                                  color: AppColors.premiumDarkPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: '  >',
                                style: TextStyle(
                                  color: AppColors.premiumDarkPrimary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // Designer Footer
                    Center(
                      child: Column(
                        children: [
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
                            'Zenvyro Labs',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildTextField(
    TextEditingController ctrl, 
    String hint, 
    IconData icon, {
    bool isPassword = false, 
    bool isObscured = false,
    VoidCallback? toggleObscure,
    TextInputType? type, 
    bool enabled = true,
    bool required = true,
  }) {
    const accentColor = Color(0xFF38BDF8);

    return TextFormField(
      controller: ctrl,
      obscureText: isObscured,
      keyboardType: type,
      enabled: enabled,
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
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.02)),
        ),
      ),
      validator: (v) => (required && v!.isEmpty) ? 'Field required' : null,
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Icon(icon, color: const Color(0xFF38BDF8), size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
