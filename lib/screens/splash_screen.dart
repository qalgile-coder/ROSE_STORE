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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const navyBg = Color(0xFF0B1120);

    return Scaffold(
      backgroundColor: navyBg, 
      body: Stack(
        children: [
          // Background Aesthetic Glow
          Positioned(
            top: -150,
            right: -150,
            child: _GlowCircle(
              color: colorScheme.primary.withValues(alpha: 0.1), 
              size: 500
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Premium Logo Container with sophisticated SaaS styling
                  Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(54),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3), 
                          blurRadius: 60, 
                          offset: const Offset(0, 30)
                        ),
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: -10,
                        ),
                      ],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 2),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        'assets/images/rounded-image.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.auto_awesome_mosaic_rounded,
                          size: 72,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),

                  const Text(
                    'Zen Mart Pro',
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
                      color: colorScheme.primary.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  
                  const SizedBox(height: 120),

                  // SaaS-style Loader
                  const _ModernLoader(),
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
  const _ModernLoader();

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
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
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
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(color: colorScheme.primary.withValues(alpha: 0.5), blurRadius: 10),
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
