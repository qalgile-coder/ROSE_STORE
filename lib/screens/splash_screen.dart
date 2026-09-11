import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تعريف درجات الوردي الغامض (Mysterious Pink Palette)
    const Color mysteriousPink = Color(0xFFC2185B); 
    const Color darkNavyBg = Color(0xFF0F0810); // خلفية متناسقة مع الوردي الغامض
    const Color cardBgColor = Color(0xFF1E111C);

    return Scaffold(
      backgroundColor: darkNavyBg, 
      body: Stack(
        children: [
          // Background Aesthetic Glow بالوردي الغامض
          Positioned(
            top: -150,
            right: -150,
            child: _GlowCircle(
              color: mysteriousPink.withValues(alpha: 0.15), 
              size: 500
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium Logo Container with Mysterious Pink styling
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color: cardBgColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(54),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4), 
                          blurRadius: 60, 
                          offset: const Offset(0, 30)
                        ),
                        BoxShadow(
                          color: mysteriousPink.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: -10,
                        ),
                      ],
                      border: Border.all(color: mysteriousPink.withValues(alpha: 0.2), width: 2),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'assets/images/image.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.auto_awesome_mosaic_rounded,
                          size: 72,
                          color: mysteriousPink,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),

                  const Text(
                    'ROOZ Store',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    'PREMIUM MARKETPLACE',
                    style: TextStyle(
                      color: mysteriousPink.withValues(alpha: 0.9),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  
                  const SizedBox(height: 120),

                  // SaaS-style Loader
                  const _ModernLoader(mysteriousPink: mysteriousPink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernLoader extends StatefulWidget {
  final Color mysteriousPink;
  const _ModernLoader({required this.mysteriousPink});

  @override
  State<_ModernLoader> createState() => _ModernLoaderState();
}

class _ModernLoaderState extends State<_ModernLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF1E111C),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Positioned(
                left: _controller.value * 150,
                child: Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: widget.mysteriousPink,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: widget.mysteriousPink.withValues(alpha: 0.6), blurRadius: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}