import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_typography.dart';
import '../../services/config_service.dart';
import '../../widgets/static_footer.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => const LoginScreen(),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ConfigService.current;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 96))
                          .animate()
                          .scale(
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.3, 0.3),
                            end: const Offset(1.0, 1.0),
                          ),
                      const SizedBox(height: 20),
                      Text(
                        'Loan Collector',
                        style: AppTypography.displayLarge.copyWith(
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
                      const SizedBox(height: 8),
                      Text(
                        config.businessName,
                        style: AppTypography.titleMedium.copyWith(
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 40),
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ).animate().fadeIn(delay: 1000.ms),
                    ],
                  ),
                ),
              ),
              const StaticFooter(onDark: true),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}