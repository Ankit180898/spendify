import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/services/progress_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Celebration kit — short, code-drawn reward animations.
//
//   showCelebration(...)   bottom sheet with confetti, animated badge,
//                          XP count-up, streak and level-up moments
//   ConfettiBurst          one-shot particle burst
//   AnimatedCheckBadge     ringed icon that pops in with an elastic scale
//   PulsingFlame           streak flame that breathes
// ─────────────────────────────────────────────────────────────────────────────

class CelebrationData {
  final String title;
  final String? subtitle;
  final Object icon; // Phosphor icon data (any style)
  final Color color;

  /// UserProgress before/after the action. When both are given the sheet shows
  /// XP gained, the streak, any level-up and newly unlocked badges.
  final UserProgress? before;
  final UserProgress? after;

  /// Optional one-line context, e.g. "₹12,400 left in this month's budget".
  final String? footnote;

  const CelebrationData({
    required this.title,
    required this.icon,
    required this.color,
    this.subtitle,
    this.before,
    this.after,
    this.footnote,
  });
}

Future<void> showCelebration(CelebrationData data) {
  HapticFeedback.mediumImpact();
  return Get.bottomSheet(
    _CelebrationSheet(data: data),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
  );
}

class _CelebrationSheet extends StatefulWidget {
  final CelebrationData data;
  const _CelebrationSheet({required this.data});

  @override
  State<_CelebrationSheet> createState() => _CelebrationSheetState();
}

class _CelebrationSheetState extends State<_CelebrationSheet> {
  @override
  void initState() {
    super.initState();
    final b = widget.data.before;
    final a = widget.data.after;
    if (b != null && a != null && a.level > b.level) {
      Future.delayed(const Duration(milliseconds: 900), HapticFeedback.heavyImpact);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final before = d.before;
    final after = d.after;
    final hasProgress = before != null && after != null;
    final xpGained = hasProgress ? after.xp - before.xp : 0;
    final leveledUp = hasProgress && after.level > before.level;
    final newBadges = hasProgress
        ? after.badges
            .where((b) => b.unlocked &&
                !before.badges.any((p) => p.id == b.id && p.unlocked))
            .toList()
        : <Achievement>[];
    final streakGrew = hasProgress && after.streak > before.streak;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              24, 14, 24, 24 + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(
            color: AppColor.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.border,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 22),
              AnimatedCheckBadge(icon: d.icon, color: d.color),
              const SizedBox(height: 16),
              _FadeUp(
                delay: 150,
                child: Text(
                  d.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.urbanist(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              if (d.subtitle != null) ...[
                const SizedBox(height: 4),
                _FadeUp(
                  delay: 200,
                  child: Text(
                    d.subtitle!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ),
              ],

              // ── Rewards row ─────────────────────────────────────────
              if (hasProgress) ...[
                const SizedBox(height: 20),
                _FadeUp(
                  delay: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RewardChip(
                        leading: const PhosphorIcon(
                          PhosphorIconsDuotone.lightning,
                          size: 18,
                          color: AppColor.warning,
                        ),
                        child: xpGained > 0
                            ? _CountUp(
                                to: xpGained,
                                prefix: '+',
                                suffix: ' XP',
                                delay: 350,
                              )
                            : const _ChipText('Daily XP maxed'),
                      ),
                      const SizedBox(width: 10),
                      _RewardChip(
                        leading: PulsingFlame(
                          size: 18,
                          active: after.streak > 0,
                          burst: streakGrew,
                        ),
                        child: _ChipText(
                          after.streak == 1
                              ? '1-day streak'
                              : '${after.streak}-day streak',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _FadeUp(
                  delay: 400,
                  child: _XpBar(before: before, after: after),
                ),
              ],

              // ── Level up ────────────────────────────────────────────
              if (leveledUp) ...[
                const SizedBox(height: 16),
                _PopIn(
                  delay: 900,
                  child: _Highlight(
                    icon: PhosphorIconsDuotone.crown,
                    color: AppColor.warning,
                    title: 'Level ${after.level} unlocked',
                    subtitle: 'You\'re now a ${after.levelTitle}',
                  ),
                ),
              ],

              // ── New badges ──────────────────────────────────────────
              for (var i = 0; i < newBadges.length; i++) ...[
                const SizedBox(height: 10),
                _PopIn(
                  delay: 1050 + i * 150,
                  child: _Highlight(
                    icon: newBadges[i].icon,
                    color: newBadges[i].color,
                    title: 'Badge earned · ${newBadges[i].title}',
                    subtitle: newBadges[i].description,
                  ),
                ),
              ],

              if (d.footnote != null) ...[
                const SizedBox(height: 16),
                _FadeUp(
                  delay: 500,
                  child: Text(
                    d.footnote!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: Get.back,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Keep going'),
                ),
              ),
            ],
          ),
        ),
        // Confetti rains from just above the badge
        const Positioned(
          top: -20,
          left: 0,
          right: 0,
          height: 380,
          child: IgnorePointer(child: ConfettiBurst()),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confetti
// ─────────────────────────────────────────────────────────────────────────────

class ConfettiBurst extends StatefulWidget {
  final int count;
  final Duration duration;
  const ConfettiBurst({
    super.key,
    this.count = 46,
    this.duration = const Duration(milliseconds: 1600),
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)..forward();
  late final List<_Particle> _particles;

  static const _palette = [
    AppColor.primary,
    AppColor.warning,
    AppColor.income,
    AppColor.expense,
    Color(0xFFB9A3D6),
    Color(0xFFE8C9A8),
  ];

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    _particles = List.generate(widget.count, (_) {
      // Fan upward, biased to the centre
      final angle = -math.pi / 2 + (r.nextDouble() - 0.5) * math.pi * 0.95;
      return _Particle(
        angle: angle,
        speed: 260 + r.nextDouble() * 260,
        spin: (r.nextDouble() - 0.5) * 14,
        size: 5 + r.nextDouble() * 5,
        color: _palette[r.nextInt(_palette.length)],
        isCircle: r.nextDouble() < 0.35,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _c.value),
        ),
      );
}

class _Particle {
  final double angle, speed, spin, size;
  final Color color;
  final bool isCircle;
  const _Particle({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.color,
    required this.isCircle,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, 110);
    const gravity = 620.0;
    final secs = t * 1.6;
    final fade = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
    final paint = Paint();

    for (final p in particles) {
      final dx = math.cos(p.angle) * p.speed * secs;
      final dy = math.sin(p.angle) * p.speed * secs + 0.5 * gravity * secs * secs;
      paint.color = p.color.withValues(alpha: fade.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(origin.dx + dx, origin.dy + dy);
      canvas.rotate(p.spin * secs);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated badge — ring draws in, icon pops with elastic scale
// ─────────────────────────────────────────────────────────────────────────────

class AnimatedCheckBadge extends StatefulWidget {
  final Object icon; // Phosphor icon data (any style)
  final Color color;
  final double size;
  const AnimatedCheckBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 84,
  });

  @override
  State<AnimatedCheckBadge> createState() => _AnimatedCheckBadgeState();
}

class _AnimatedCheckBadgeState extends State<AnimatedCheckBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ring = CurvedAnimation(parent: _c, curve: const Interval(0, 0.55, curve: Curves.easeOutCubic));
    final pop = CurvedAnimation(parent: _c, curve: const Interval(0.2, 1, curve: Curves.elasticOut));
    final tick = CurvedAnimation(parent: _c, curve: const Interval(0.55, 0.85, curve: Curves.easeOutBack));

    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(widget.size),
              painter: _RingPainter(ring.value, widget.color),
            ),
            Transform.scale(
              scale: pop.value,
              child: Container(
                width: widget.size - 18,
                height: widget.size - 18,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: PhosphorIcon(
                    widget.icon,
                    size: widget.size * 0.42,
                    color: widget.color,
                    duotoneSecondaryOpacity: 0.3,
                  ),
                ),
              ),
            ),
            // Small check pip, bottom-right
            Positioned(
              right: 2,
              bottom: 2,
              child: Transform.scale(
                scale: tick.value,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColor.surface, width: 2.5),
                  ),
                  child: const Center(
                    child: PhosphorIcon(PhosphorIconsBold.check,
                        size: 13, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  final Color color;
  _RingPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.55);
    canvas.drawArc(rect.deflate(2), -math.pi / 2, 2 * math.pi * t, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing streak flame
// ─────────────────────────────────────────────────────────────────────────────

class PulsingFlame extends StatefulWidget {
  final double size;
  final bool active;

  /// Plays one bigger bounce first — use when the streak just grew.
  final bool burst;
  const PulsingFlame({
    super.key,
    this.size = 20,
    this.active = true,
    this.burst = false,
  });

  @override
  State<PulsingFlame> createState() => _PulsingFlameState();
}

class _PulsingFlameState extends State<PulsingFlame>
    with TickerProviderStateMixin {
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _breathe.repeat(reverse: true);
    if (widget.burst) {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) _burst.forward();
      });
    }
  }

  @override
  void dispose() {
    _breathe.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.active ? const Color(0xFFE07A3F) : AppColor.textTertiary;
    return AnimatedBuilder(
      animation: Listenable.merge([_breathe, _burst]),
      builder: (_, __) {
        final breathe = 1 + 0.08 * Curves.easeInOut.transform(_breathe.value);
        final burst = 1 + 0.45 * math.sin(math.pi * Curves.easeOut.transform(_burst.value));
        return Transform.scale(
          scale: breathe * burst,
          alignment: Alignment.bottomCenter,
          child: PhosphorIcon(
            PhosphorIconsDuotone.fire,
            size: widget.size,
            color: color,
            duotoneSecondaryOpacity: 0.35,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small pieces
// ─────────────────────────────────────────────────────────────────────────────

class _XpBar extends StatelessWidget {
  final UserProgress before;
  final UserProgress after;
  const _XpBar({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    // On level-up the bar starts empty in the new level
    final start = after.level > before.level ? 0.0 : before.levelProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Level ${after.level} · ${after.levelTitle}',
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColor.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${after.xp - after.levelStartXp} / ${after.nextLevelXp - after.levelStartXp} XP',
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColor.textTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: start, end: after.levelProgress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, v, __) => _ProgressTrack(value: v),
        ),
      ],
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  final double value;
  const _ProgressTrack({required this.value});

  @override
  Widget build(BuildContext context) => Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppColor.surfaceVariant,
          borderRadius: BorderRadius.circular(100),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD99A4E), Color(0xFFE07A3F)],
              ),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      );
}

class _RewardChip extends StatelessWidget {
  final Widget leading;
  final Widget child;
  const _RewardChip({required this.leading, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColor.primaryExtraSoft,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppColor.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [leading, const SizedBox(width: 6), child],
        ),
      );
}

class _ChipText extends StatelessWidget {
  final String text;
  const _ChipText(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.urbanist(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColor.textPrimary,
        ),
      );
}

class _CountUp extends StatefulWidget {
  final int to;
  final String prefix;
  final String suffix;
  final int delay;
  const _CountUp({
    required this.to,
    this.prefix = '',
    this.suffix = '',
    this.delay = 0,
  });

  @override
  State<_CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<_CountUp> {
  bool _go = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) setState(() => _go = true);
    });
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: _go ? widget.to.toDouble() : 0),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => _ChipText('${widget.prefix}${v.round()}${widget.suffix}'),
      );
}

class _Highlight extends StatelessWidget {
  final Object icon; // Phosphor icon data (any style)
  final Color color;
  final String title;
  final String subtitle;
  const _Highlight({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: PhosphorIcon(icon, size: 22, color: color,
                    duotoneSecondaryOpacity: 0.3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.urbanist(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.urbanist(
                          fontSize: 12, color: AppColor.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Fades and lifts a child in after [delay] ms.
class _FadeUp extends StatelessWidget {
  final int delay;
  final Widget child;
  const _FadeUp({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) => _Delayed(
        delay: delay,
        duration: 380,
        builder: (t) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child),
        ),
      );
}

/// Scales a child in with a springy overshoot after [delay] ms.
class _PopIn extends StatelessWidget {
  final int delay;
  final Widget child;
  const _PopIn({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) => _Delayed(
        delay: delay,
        duration: 520,
        curve: Curves.easeOutBack,
        builder: (t) => Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
        ),
      );
}

class _Delayed extends StatefulWidget {
  final int delay;
  final int duration;
  final Curve curve;
  final Widget Function(double t) builder;
  const _Delayed({
    required this.delay,
    required this.duration,
    required this.builder,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<_Delayed> createState() => _DelayedState();
}

class _DelayedState extends State<_Delayed> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.duration),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => widget.builder(widget.curve.transform(_c.value)),
      );
}
