import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/providers.dart';
import '../../theme/app_colors.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String? email;
  const VerifyEmailScreen({super.key, this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;
  
  // متغيرات خاصة بالمؤقت لزر إعادة الإرسال
  int _resendCountdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);
    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        user = FirebaseAuth.instance.currentUser;

        if (user != null && user.emailVerified) {
          if (!mounted) return;
          _showCustomSnackBar('تم التحقق من البريد بنجاح!', AppColors.success);
          context.go('/customer');
        } else {
          if (!mounted) return;
          _showCustomSnackBar('لم يتم التحقق بعد. يرجى مراجعة بريدك والضغط على الرابط.', Colors.orange);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar('حدث خطأ: ${e.toString()}', AppColors.error);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (!_canResend) return;
    
    setState(() => _isResending = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (!mounted) return;
        _showCustomSnackBar('تم إعادة إرسال رابط التحقق بنجاح', AppColors.success);
        _startResendTimer(); // إعادة تفعيل المؤقت بعد الإرسال الناجح
      }
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar('فشل الإرسال: ${e.toString()}', AppColors.error);
    } finally {
      if (mounted) setState(() => _isResending = false);
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
          // Background Glow Effect
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Container with Glow & Gradient Border
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF6366F1), Color(0xFF34D399)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.2),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_rounded,
                          size: 56,
                          color: accentColor,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 36),
                    
                    Text(
                      'تحقق من بريدك الإلكتروني',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // توضيح احترافي للمستخدم لفتح البريد والضغط على الرابط والعودة
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.email != null 
                                ? 'أرسلنا رابط تفعيل إلى بريدك:\n${widget.email}' 
                                : 'أرسلنا رابط تفعيل إلى بريدك الإلكتروني.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.white,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'يرجى فتح بريدك الإلكتروني، الضغط على رابط التفعيل، ثم العودة إلى هذه الشاشة والضغط على زر "لقد قمت بالتحقق".',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: accentColor,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 36),

                    // Main Container Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: surfaceColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Column(
                        children: [
                          // Primary Button (Check Verification)
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isChecking ? null : _checkVerificationStatus,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accentColor,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 4,
                                shadowColor: accentColor.withValues(alpha: 0.4),
                              ),
                              child: _isChecking
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'لقد قمت بالتحقق، متابعة',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_rounded, size: 20),
                                      ],
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Secondary Button (Resend Email with Timer)
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: OutlinedButton(
                              onPressed: (_isResending || !_canResend) ? null : _resendVerificationEmail,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: _canResend ? accentColor.withValues(alpha: 0.5) : Colors.grey.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                backgroundColor: Colors.transparent,
                              ),
                              child: _isResending
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(color: accentColor, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      _canResend 
                                          ? 'إعادة إرسال البريد' 
                                          : 'إعادة الإرسال بعد (${_resendCountdown} ثانية)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _canResend ? accentColor : Colors.grey,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Back to Login Link
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(
                        'العودة إلى تسجيل الدخول',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}