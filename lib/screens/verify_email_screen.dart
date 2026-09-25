import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/providers.dart';
import '../theme/app_colors.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;

  // دالة للتحقق مما إذا قام المستخدم بالضغط على رابط التفعيل في إيميله
  Future<void> _checkVerificationStatus() async {
    setState(() => _isChecking = true);
    try {
      final authService = ref.read(authServiceProvider);
      
      // إذا كان المستخدم غير مسجل دخول حالياً، نحاول تسجيل دخوله مؤقتاً عبر الجلسة أو توجيهه لتسجيل الدخول
      var user = authService.currentUser;
      
      if (user != null) {
        // تحديث معلومات المستخدم من سيرفر فايربيس لمعرفة حالة emailVerified الحالية
        await user.reload();
        user = authService.currentUser; // جلب النسخة المحدثة

        if (user != null && user.emailVerified) {
          if (!mounted) return;
          _showSnackBar('تم تفعيل البريد الإلكتروني بنجاح!', AppColors.success);
          context.go('/home'); // الانتقال للشاشة الرئيسية بعد التفعيل الكامل
        } else {
          if (!mounted) return;
          _showSnackBar(
            'لم يتم تفعيل البريد بعد. يرجى فتح بريدك الإلكتروني والضغط على رابط التحقق.',
            Colors.orange,
          );
        }
      } else {
        if (!mounted) return;
        _showSnackBar('انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى.', AppColors.error);
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('حدث خطأ أثناء التحقق: ${e.toString().replaceAll('Exception: ', '')}', AppColors.error);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  // دالة لإعادة إرسال رسالة التحقق
  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);
    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        if (!mounted) return;
        _showSnackBar('تم إعادة إرسال رسالة التحقق إلى بريدك بنجاح.', AppColors.success);
      } else {
        if (!mounted) return;
        _showSnackBar('البريد مفعل مسبقاً أو أن الجلسة منتهية.', Colors.orange);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('فشل الإرسال: حاول مرة أخرى لاحقاً.', AppColors.error);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
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
    const bgColor = Color(0xFF0B1120);
    const surfaceColor = Color(0xFF1E293B);
    const accentColor = Color(0xFF38BDF8);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Icon Container with Glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: surfaceColor.withValues(alpha: 0.5),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.mark_email_unread_rounded, size: 48, color: accentColor),
              ),
              const SizedBox(height: 32),
              
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
              const SizedBox(height: 16),
              
              Text(
                'لقد أرسلنا رابط تحقق إلى بريدك الإلكتروني:\n',
                style: GoogleFonts.plusJakartaSans(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              Text(
                widget.email,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'يرجى فتح بريدك، الضغط على الرابط لتفعيل الحساب، ثم العودة والضغط على الزر أدناه.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white60, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Action Card Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: surfaceColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    // Check Status Button
                    ElevatedButton(
                      onPressed: _isChecking ? null : _checkVerificationStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                            )
                          : Text(
                              'تحقق من تفعيل الحساب',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Resend Email Button
                    TextButton.icon(
                      onPressed: _isResending ? null : _resendVerificationEmail,
                      icon: _isResending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded, size: 18, color: accentColor),
                      label: Text(
                        _isResending ? 'جاري الإرسال...' : 'إعادة إرسال رسالة التحقق',
                        style: GoogleFonts.plusJakartaSans(
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Back to Login
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'العودة إلى تسجيل الدخول',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white38,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}