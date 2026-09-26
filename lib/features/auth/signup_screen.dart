import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers.dart';
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
  final _referralController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  // دالة متقدمة لحساب قوة كلمة المرور وتحديث مؤشر العرض
  void _updatePasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.transparent;
      });
      return;
    }

    double strength = 0.0;
    if (password.length >= 6) strength += 0.3;
    if (password.contains(RegExp(r'[A-Z]')) && password.contains(RegExp(r'[a-z]'))) strength += 0.3;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    setState(() {
      _passwordStrength = strength.clamp(0.0, 1.0);
      if (_passwordStrength <= 0.3) {
        _passwordStrengthText = 'ضعيفة';
        _passwordStrengthColor = Colors.redAccent;
      } else if (_passwordStrength <= 0.7) {
        _passwordStrengthText = 'متوسطة';
        _passwordStrengthColor = Colors.orangeAccent;
      } else {
        _passwordStrengthText = 'قوية جداً';
        _passwordStrengthColor = Colors.greenAccent;
      }
    });
  }

  // دالة متقدمة للتحقق من صحة البريد الإلكتروني باحترافية
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرجاء إدخال البريد الإلكتروني';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value.trim())) {
      return 'الرجاء إدخال بريد إلكتروني صحيح (مثال: name@domain.com)';
    }
    return null;
  }

  // دالة متقدمة للتحقق من قوة كلمة المرور
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'الرجاء إدخال كلمة المرور';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      _showCustomSnackBar('كلمات المرور غير متطابقة', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // إرسال البيانات وتسجيل الحساب عبر فايربيس ومزود الخدمة
      await ref.read(authServiceProvider).signUpCustomer(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        referredBy: _referralController.text.trim().isEmpty ? null : _referralController.text.trim(),
      );

      if (!mounted) return;

      _showCustomSnackBar(
        'تم إنشاء الحساب بنجاح! يرجى التحقق من بريدك الإلكتروني لتفعيل الحساب.',
        AppColors.success,
      );

      // تفعيل حالة الانتقال أو التوجيه للشاشة الرئيسية أو شاشة انتظار التحقق
      ref.read(forcedSplashProvider.notifier).state = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          ref.read(forcedSplashProvider.notifier).state = false;
          context.go('/login');
        }
      });
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceAll('Exception: ', '');
        if (errorMessage.contains('email-already-in-use')) {
          errorMessage = 'البريد الإلكتروني مستخدم مسبقاً لحساب آخر.';
        } else if (errorMessage.contains('invalid-email')) {
          errorMessage = 'صيغة البريد الإلكتروني غير صالحة.';
        } else if (errorMessage.contains('weak-password')) {
          errorMessage = 'كلمة المرور ضعيفة جداً.';
        }
        _showCustomSnackBar('فشل التسجيل: $errorMessage', AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCustomSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: bgColor,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    
                    const SizedBox(height: 20),

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
                          const TextSpan(text: 'Join '),
                          TextSpan(
                            text: 'ROOZ Store',
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
                          _buildTextField(
                            ctrl: _nameController, 
                            hint: 'Full Name', 
                            icon: Icons.person_rounded,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'الرجاء إدخال الاسم الكامل' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            ctrl: _emailController, 
                            hint: 'Email Address', 
                            icon: Icons.email_rounded, 
                            type: TextInputType.emailAddress,
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            ctrl: _phoneController, 
                            hint: 'Phone Number', 
                            icon: Icons.phone_rounded, 
                            type: TextInputType.phone,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'الرجاء إدخال رقم الهاتف' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            ctrl: _passwordController, 
                            hint: 'Password', 
                            icon: Icons.lock_rounded, 
                            isPassword: true, 
                            isObscured: _obscurePassword,
                            toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            validator: _validatePassword,
                          ),
                          
                          // Password Strength Indicator Row
                          if (_passwordController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _passwordStrength,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _passwordStrengthText,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: _passwordStrengthColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 16),
                          _buildTextField(
                            ctrl: _confirmPasswordController, 
                            hint: 'Confirm Password', 
                            icon: Icons.verified_user_outlined, 
                            isPassword: true, 
                            isObscured: _obscureConfirmPassword,
                            toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'الرجاء تأكيد كلمة المرور';
                              if (v != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            ctrl: _referralController, 
                            hint: 'Referral Code (Optional)', 
                            icon: Icons.card_giftcard_rounded, 
                            required: false,
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Register Button
                          InkWell(
                            onTap: _isLoading ? null : _registerUser,
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
                                      'REGISTER',
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
                            'OSI',
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

  Widget _buildTextField({
    required TextEditingController ctrl, 
    required String hint, 
    required IconData icon, 
    bool isPassword = false, 
    bool isObscured = false,
    VoidCallback? toggleObscure,
    TextInputType? type, 
    bool enabled = true,
    bool required = true,
    String? Function(String?)? validator,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.02)),
        ),
      ),
      validator: validator ?? (v) => (required && (v == null || v.isEmpty)) ? 'Field required' : null,
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
  Widget build(BuildContext codeContext) {
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