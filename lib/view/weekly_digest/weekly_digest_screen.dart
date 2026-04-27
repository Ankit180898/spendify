import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/model/weekly_digest_model.dart';

class WeeklyDigestScreen extends StatelessWidget {
  final WeeklyDigest digest;

  const WeeklyDigestScreen({super.key, required this.digest});

  @override
  Widget build(BuildContext context) {
    final sym = Get.find<HomeController>().currencySymbol.value;
    return Scaffold(
      backgroundColor: AppColor.darkBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(weekNumber: digest.weekNumber),
              _HeroSection(digest: digest, sym: sym),
              const SizedBox(height: 28),
              _StatsRow(digest: digest, sym: sym),
              const SizedBox(height: 20),
              _NudgeCard(nudge: digest.nudge),
              if (digest.weeklyBudget > 0) ...[
                const SizedBox(height: 20),
                _BudgetSection(digest: digest, sym: sym),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int weekNumber;
  const _TopBar({required this.weekNumber});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: Get.back,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColor.darkSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                PhosphorIconsLight.x,
                color: AppColor.textSecondary,
                size: 18,
              ),
            ),
          ),
          const Spacer(),
          Text(
            'Weekly Digest',
            style: TextStyle(
              color: AppColor.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero — week label, giant amount, change badge
// ─────────────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final WeeklyDigest digest;
  final String sym;
  const _HeroSection({required this.digest, required this.sym});

  @override
  Widget build(BuildContext context) {
    final startFmt = DateFormat('MMM d').format(digest.weekStart);
    final endFmt = digest.weekEnd.month == digest.weekStart.month
        ? DateFormat('d').format(digest.weekEnd)
        : DateFormat('MMM d').format(digest.weekEnd);
    final dateRange = '$startFmt – $endFmt';
    final year = DateFormat('y').format(digest.weekEnd);

    final hasPrev = digest.prevWeekSpent > 0;
    final diff = digest.totalSpent - digest.prevWeekSpent;
    final pct = hasPrev ? (diff / digest.prevWeekSpent * 100).round() : 0;
    final isUp = diff >= 0;
    final changeColor = isUp ? AppColor.expense : AppColor.income;
    final changeLabel = hasPrev
        ? '${isUp ? '↑' : '↓'} ${pct.abs()}% vs last week'
        : 'No data from previous week';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        children: [
          // Week number + date range
          Text(
            'Week ${digest.weekNumber}',
            style: TextStyle(
              color: AppColor.primarySoft,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$dateRange, $year',
            style: TextStyle(color: AppColor.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 28),

          // Giant amount
          Text(
            _fmt(digest.totalSpent, sym),
            style: TextStyle(
              color: AppColor.textPrimary,
              fontSize: 52,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'total spent',
            style: TextStyle(color: AppColor.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Change badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: changeColor.withOpacity(0.3)),
            ),
            child: Text(
              changeLabel,
              style: TextStyle(
                color: changeColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row — top category, biggest spend, transaction count
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final WeeklyDigest digest;
  final String sym;
  const _StatsRow({required this.digest, required this.sym});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: PhosphorIconsLight.chartPie,
              label: 'Top category',
              value: digest.topCategory.isNotEmpty ? digest.topCategory : '—',
              sub: digest.topCategory.isNotEmpty
                  ? _fmt(digest.topCategoryAmount, sym)
                  : '',
              color: AppColor.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: PhosphorIconsLight.arrowFatLinesUp,
              label: 'Biggest spend',
              value: _fmt(digest.biggestTxAmount, sym),
              sub: digest.biggestTxDescription,
              color: AppColor.expense,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: PhosphorIconsLight.receipt,
              label: 'Transactions',
              value: '${digest.txCount}',
              sub: 'logged',
              color: AppColor.income,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColor.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: AppColor.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: AppColor.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(color: AppColor.textSecondary, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nudge card — the one surprising insight
// ─────────────────────────────────────────────────────────────────────────────

class _NudgeCard extends StatelessWidget {
  final String nudge;
  const _NudgeCard({required this.nudge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColor.primaryExtraSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.primary.withOpacity(0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColor.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                PhosphorIconsLight.lightbulb,
                color: AppColor.primarySoft,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This week\'s insight',
                    style: TextStyle(
                      color: AppColor.primarySoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    nudge,
                    style: TextStyle(
                      color: AppColor.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Budget section — progress bar vs weekly budget
// ─────────────────────────────────────────────────────────────────────────────

class _BudgetSection extends StatelessWidget {
  final WeeklyDigest digest;
  final String sym;
  const _BudgetSection({required this.digest, required this.sym});

  @override
  Widget build(BuildContext context) {
    final pct = (digest.totalSpent / digest.weeklyBudget).clamp(0.0, 1.0);
    final isOver = digest.totalSpent > digest.weeklyBudget;
    final barColor = isOver ? AppColor.expense : AppColor.income;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColor.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColor.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly budget',
                  style: TextStyle(
                    color: AppColor.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${_fmt(digest.totalSpent, sym)} / ${_fmt(digest.weeklyBudget, sym)}',
                  style: TextStyle(
                    color: isOver ? AppColor.expense : AppColor.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: AppColor.darkElevated,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isOver
                  ? 'Over weekly budget by ${_fmt(digest.totalSpent - digest.weeklyBudget, sym)}'
                  : '${_fmt(digest.weeklyBudget - digest.totalSpent, sym)} remaining this week',
              style: TextStyle(
                color: isOver ? AppColor.expense : AppColor.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _fmt(double v, String sym) {
  if (v >= 100000) return '$sym${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '$sym${(v / 1000).toStringAsFixed(1)}K';
  return '$sym${v.toStringAsFixed(0)}';
}
