import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/health_score_controller/health_score_controller.dart';
import 'package:spendify/model/health_score_model.dart';

class HealthScoreScreen extends StatelessWidget {
  const HealthScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HealthScoreController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColor.darkBg : Colors.white;
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textMuted = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final s = ctrl.score.value;
          if (s == null) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColor.primary,
                strokeWidth: 2,
              ),
            );
          }
          final change = ctrl.weeklyChange;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _TopBar(isDark: isDark, textPrimary: textPrimary),
              ),
              SliverToBoxAdapter(
                child: _HeroSection(score: s, change: change, isDark: isDark),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: _sectionLabel('Score Breakdown', textMuted),
                ),
              ),
              SliverToBoxAdapter(
                child: _BreakdownSection(score: s, isDark: isDark),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: _sectionLabel('History', textMuted),
                ),
              ),
              SliverToBoxAdapter(
                child: _HistorySection(history: ctrl.history.toList(), isDark: isDark),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: _sectionLabel('How to improve', textMuted),
                ),
              ),
              SliverToBoxAdapter(
                child: _ImprovementSection(score: s, isDark: isDark),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 100,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) => Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isDark;
  final Color textPrimary;
  const _TopBar({required this.isDark, required this.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: PhosphorIcon(
              PhosphorIconsLight.arrowLeft,
              color: textPrimary,
              size: 20,
            ),
          ),
          Text(
            'Financial Health',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero — large arc gauge + score + level + change badge
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final HealthScore score;
  final int? change;
  final bool isDark;
  const _HeroSection({required this.score, required this.change, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textMuted = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final trackColor = isDark ? AppColor.darkBorder : const Color(0xFFE8E6E2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: [
          // Arc gauge
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: _ArcPainter(
                    progress: score.total / 100,
                    color: score.levelColor,
                    trackColor: trackColor,
                    strokeWidth: 12,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.total}',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'of 100',
                      style: TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Level pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: score.levelColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              score.levelLabel,
              style: TextStyle(
                color: score.levelColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          if (change != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PhosphorIcon(
                  change! >= 0
                      ? PhosphorIconsLight.trendUp
                      : PhosphorIconsLight.trendDown,
                  size: 14,
                  color: change! >= 0 ? AppColor.income : AppColor.expense,
                ),
                const SizedBox(width: 4),
                Text(
                  '${change! >= 0 ? '+' : ''}$change points since last check',
                  style: TextStyle(
                    color: change! >= 0 ? AppColor.income : AppColor.expense,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score breakdown — one row per component
// ─────────────────────────────────────────────────────────────────────────────

class _BreakdownSection extends StatelessWidget {
  final HealthScore score;
  final bool isDark;
  const _BreakdownSection({required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rows = [
      _ComponentData(
        icon: PhosphorIconsLight.piggyBank,
        label: 'Savings Rate',
        subLabel: _savingsLabel(score.savingsScore),
        subScore: score.savingsScore,
        weight: '30%',
      ),
      _ComponentData(
        icon: PhosphorIconsLight.shieldCheck,
        label: 'Budget Adherence',
        subLabel: _budgetLabel(score.budgetScore),
        subScore: score.budgetScore,
        weight: '25%',
      ),
      _ComponentData(
        icon: PhosphorIconsLight.target,
        label: 'Goal Progress',
        subLabel: _goalLabel(score.goalScore),
        subScore: score.goalScore,
        weight: '25%',
      ),
      _ComponentData(
        icon: PhosphorIconsLight.waveform,
        label: 'Consistency',
        subLabel: _consistencyLabel(score.consistencyScore),
        subScore: score.consistencyScore,
        weight: '20%',
      ),
    ];

    final cardBg = isDark ? AppColor.darkCard : const Color(0xFFF6F5F3);
    final divColor = isDark ? AppColor.darkBorder : AppColor.lightBorder;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: rows.asMap().entries.map((entry) {
            final i = entry.key;
            final row = entry.value;
            return Column(
              children: [
                _ComponentRow(data: row, isDark: isDark),
                if (i < rows.length - 1)
                  Divider(height: 1, color: divColor, indent: 56),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  String _savingsLabel(int s) {
    if (s >= 80) return 'Saving 20%+ of income — excellent';
    if (s >= 60) return 'Saving 10–20% of income — good';
    if (s >= 40) return 'Saving under 10% — room to grow';
    return 'Spending more than you earn this month';
  }

  String _budgetLabel(int s) {
    if (s >= 90) return 'All spending limits well under control';
    if (s >= 70) return 'Most limits in check, a few at risk';
    if (s >= 40) return 'Some limits near or over threshold';
    return 'One or more limits exceeded';
  }

  String _goalLabel(int s) {
    if (s >= 80) return 'Savings goals on track or ahead';
    if (s >= 60) return 'Slightly behind — small boost helps';
    if (s >= 40) return 'Goals falling behind schedule';
    if (s == 60) return 'No savings goals set yet';
    return 'Goals significantly behind';
  }

  String _consistencyLabel(int s) {
    if (s >= 80) return 'Spending is steady day-to-day';
    if (s >= 60) return 'A few above-average days this month';
    if (s >= 40) return 'Some large daily spikes detected';
    return 'Very uneven spending pattern';
  }
}

class _ComponentData {
  final PhosphorIconData icon;
  final String label;
  final String subLabel;
  final int subScore;
  final String weight;

  const _ComponentData({
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.subScore,
    required this.weight,
  });
}

class _ComponentRow extends StatelessWidget {
  final _ComponentData data;
  final bool isDark;
  const _ComponentRow({required this.data, required this.isDark});

  Color _scoreColor(int s) {
    if (s >= 80) return AppColor.income;
    if (s >= 60) return AppColor.warning;
    if (s >= 40) return const Color(0xFFFF7849);
    return AppColor.expense;
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textMuted = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final track = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.06);
    final color = _scoreColor(data.subScore);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: PhosphorIcon(data.icon, size: 16, color: color),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data.label,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${data.subScore}',
                      style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                        color: track, borderRadius: BorderRadius.circular(3)),
                  ),
                  FractionallySizedBox(
                    widthFactor: (data.subScore / 100).clamp(0.0, 1.0),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                          color: color, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(
                  data.subLabel,
                  style: TextStyle(color: textMuted, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History — bar chart of past snapshots
// ─────────────────────────────────────────────────────────────────────────────

class _HistorySection extends StatelessWidget {
  final List<HealthScore> history;
  final bool isDark;
  const _HistorySection({required this.history, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;
    final emptyBar = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    if (history.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        child: Text(
          'History will appear here as you use the app.',
          style: TextStyle(color: textMuted, fontSize: 13),
        ),
      );
    }

    // Show last 12, oldest → newest left → right
    final visible = history.length > 12 ? history.sublist(history.length - 12) : history;
    final maxScore = visible.map((h) => h.total).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: visible.map((h) {
            final frac = maxScore > 0 ? h.total / 100 : 0.0;
            final color = _scoreColor(h.total);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                          width: double.infinity,
                          height: (frac * 56).clamp(4.0, 56.0),
                          decoration: BoxDecoration(
                            color: frac > 0 ? color.withValues(alpha: 0.75) : emptyBar,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      h.total.toString(),
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _scoreColor(int s) {
    if (s >= 81) return AppColor.primary;
    if (s >= 66) return AppColor.income;
    if (s >= 46) return AppColor.warning;
    if (s >= 26) return const Color(0xFFFF7849);
    return AppColor.expense;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Improvement tips — targets the two weakest components
// ─────────────────────────────────────────────────────────────────────────────

class _ImprovementSection extends StatelessWidget {
  final HealthScore score;
  final bool isDark;
  const _ImprovementSection({required this.score, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tips = _buildTips();
    if (tips.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
        child: Text(
          'Your score is excellent — keep it up!',
          style: TextStyle(
            color: AppColor.income,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
      child: Column(
        children: tips
            .map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TipCard(tip: tip, isDark: isDark),
                ))
            .toList(),
      ),
    );
  }

  List<_Tip> _buildTips() {
    final tips = <_Tip>[];

    if (score.savingsScore < 60) {
      tips.add(_Tip(
        emoji: '💰',
        title: 'Boost your savings rate',
        body: 'Aim to save at least 10% of your monthly income. Try cutting your top spending category by 15%.',
        color: AppColor.income,
      ));
    }
    if (score.budgetScore < 60) {
      tips.add(_Tip(
        emoji: '🛡️',
        title: 'Review your spending limits',
        body: 'One or more of your budget limits is at risk. Visit Goals to tighten or reassign limits.',
        color: AppColor.warning,
      ));
    }
    if (score.goalScore < 60) {
      tips.add(_Tip(
        emoji: '🎯',
        title: 'Put savings goals back on track',
        body: 'Add a fixed amount to your savings goals each month — even a small top-up keeps momentum.',
        color: AppColor.primary,
      ));
    }
    if (score.consistencyScore < 60) {
      tips.add(_Tip(
        emoji: '📅',
        title: 'Smooth out your spending',
        body: 'Large single-day spikes drag this score down. Spreading purchases across the month helps.',
        color: const Color(0xFF29B6F6),
      ));
    }

    return tips.take(3).toList();
  }
}

class _Tip {
  final String emoji;
  final String title;
  final String body;
  final Color color;
  const _Tip({required this.emoji, required this.title, required this.body, required this.color});
}

class _TipCard extends StatelessWidget {
  final _Tip tip;
  final bool isDark;
  const _TipCard({required this.tip, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColor.darkCard : const Color(0xFFF6F5F3);
    final textPrimary = isDark ? AppColor.textPrimary : AppColor.lightTextPrimary;
    final textMuted = isDark ? AppColor.textSecondary : AppColor.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tip.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tip.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.body,
                  style: TextStyle(color: textMuted, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arc gauge painter
// Draws a 270° arc (135° → 405°). Track = background. Active = score fill.
// ─────────────────────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double progress; // 0.0–1.0
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  const _ArcPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 10,
  });

  static const _startAngle = 135.0 * math.pi / 180;
  static const _sweepTotal = 270.0 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track
    canvas.drawArc(
      rect,
      _startAngle,
      _sweepTotal,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Active fill
    final fill = _sweepTotal * progress.clamp(0.0, 1.0);
    if (fill > 0) {
      canvas.drawArc(
        rect,
        _startAngle,
        fill,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color || old.trackColor != trackColor;
}
