import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spendify/controller/splash/splash_controller.dart';

/// Mocha splash that continues seamlessly from the native launch screen:
/// the mark pops in, the sparkle twinkles, then the wordmark rises.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    Get.put(SplashController());
  }

  @override
  void dispose() {
    _intro.dispose();
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mark = CurvedAnimation(
        parent: _intro, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
    final fade = CurvedAnimation(
        parent: _intro, curve: const Interval(0.0, 0.3, curve: Curves.easeOut));
    final words = CurvedAnimation(
        parent: _intro, curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic));
    final tagline = CurvedAnimation(
        parent: _intro, curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF86695B),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF9A7E70), Color(0xFF86695B), Color(0xFF6A5043)],
            ),
          ),
          child: Stack(
            children: [
              // Soft glow behind the mark
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 0.7,
                      colors: [
                        Colors.white.withValues(alpha: 0.14),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_intro, _twinkle]),
                  builder: (_, __) {
                    final tw = 0.85 + 0.15 * math.sin(_twinkle.value * 2 * math.pi);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: fade.value,
                          child: Transform.scale(
                            scale: 0.6 + 0.4 * mark.value,
                            child: Transform.scale(
                              scale: tw.clamp(0.0, 1.0) * 0.04 + 0.96,
                              child: Image.asset(
                                'assets/brand_mark.png',
                                width: 150,
                                height: 150,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: words.value,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - words.value)),
                            child: Text(
                              'Spendify',
                              style: GoogleFonts.urbanist(
                                color: const Color(0xFFFFFBF6),
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Opacity(
                          opacity: tagline.value * 0.85,
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1 - tagline.value)),
                            child: Text(
                              'Track it. Save it. Level up.',
                              style: GoogleFonts.urbanist(
                                color: const Color(0xFFF2E9E3),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Loading dots
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 40,
                child: AnimatedBuilder(
                  animation: _twinkle,
                  builder: (_, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      final phase = (_twinkle.value - i * 0.18) % 1.0;
                      final a = 0.3 + 0.7 * math.max(0, math.sin(phase * math.pi));
                      return Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2C27B).withValues(alpha: a),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
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
