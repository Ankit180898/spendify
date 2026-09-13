import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/add_transaction_screen.dart';
import 'package:spendify/view/wallet/all_transaction_screen.dart';
import 'package:spendify/view/wallet/transaction_list_item.dart';

class _StaggeredItem extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredItem({required this.index, required this.child});

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(curved);

    Future.delayed(
      Duration(milliseconds: (widget.index % 12) * 45),
      () { if (mounted) _ctrl.forward(); },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      );
}

class _TransactionShimmer extends StatelessWidget {
  final bool isDark;
  const _TransactionShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF4F4F5);
    final highlight = isDark ? const Color(0xFF2A2A3E) : const Color(0xFFE4E4E7);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Column(
        children: List.generate(5, (i) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 13, width: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 6),
                    Container(height: 11, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
              Container(height: 13, width: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            ],
          ),
        )),
      ),
    );
  }
}

class TransactionsContent extends StatelessWidget {
  final int limit;
  const TransactionsContent(this.limit, {super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    const textMuted = AppColor.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
          child: Row(
            children: [
              Text('RECENT', style: GoogleFonts.urbanist(color: AppColor.textTertiary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
              const Spacer(),
              TextButton(
                onPressed: () => Get.to(() => const AllTransactionsScreen()),
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('See all', style: GoogleFonts.urbanist(color: AppColor.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        Obx(() {
          if (ctrl.isLoading.value) {
            return const _TransactionShimmer(isDark: false);
          }

          if (ctrl.transactions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    PhosphorIcon(PhosphorIconsLight.receipt, size: 40, color: textMuted.withValues(alpha: 0.3)),
                    const SizedBox(height: 10),
                    Text('No transactions yet', style: GoogleFonts.urbanist(color: textMuted, fontSize: 14)),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () => Get.to(() => const AddTransactionScreen()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.primary,
                        side: const BorderSide(color: AppColor.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: const Text('Add first transaction'),
                    ),
                  ],
                ),
              ),
            );
          }

          final groups = ctrl.groupedTransactions;

          return ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: groups.keys.length,
            itemBuilder: (_, i) {
              final month = groups.keys.elementAt(i);
              var txs = groups[month] ?? [];
              if (limit > 0 && txs.length > limit) txs = txs.take(limit).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Text(month, style: GoogleFonts.urbanist(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
                  ),
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: txs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColor.border, indent: 66, endIndent: 20),
                    itemBuilder: (_, j) => _StaggeredItem(
                      index: j,
                      child: TransactionListItem(
                        key: ValueKey(txs[j]),
                        transaction: txs,
                        index: j,
                        categoryList: categoryList,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ],
    );
  }
}
