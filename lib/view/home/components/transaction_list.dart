import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spendify/config/app_color.dart';
import 'package:spendify/controller/home_controller/home_controller.dart';
import 'package:spendify/utils/utils.dart';
import 'package:spendify/view/wallet/add_transaction_screen.dart';
import 'package:spendify/view/wallet/all_transaction_screen.dart';
import 'package:spendify/view/wallet/transaction_list_item.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColor.textPrimary : const Color(0xFF09090B);
    final textMuted = isDark ? AppColor.textSecondary : const Color(0xFF71717A);
    final divColor = isDark ? AppColor.darkBorder : const Color(0xFFF4F4F5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
          child: Row(
            children: [
              Text('Recent', style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () => Get.to(() => const AllTransactionsScreen()),
                style: TextButton.styleFrom(
                  foregroundColor: AppColor.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('See all', style: TextStyle(color: AppColor.primary, fontSize: 13)),
              ),
            ],
          ),
        ),

        Obx(() {
          if (ctrl.isLoading.value) {
            return _TransactionShimmer(isDark: isDark);
          }

          if (ctrl.transactions.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Column(
                  children: [
                    PhosphorIcon(PhosphorIconsLight.receipt, size: 40, color: textMuted.withValues(alpha: 0.3)),
                    const SizedBox(height: 10),
                    Text('No transactions yet', style: TextStyle(color: textMuted, fontSize: 14)),
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
                    child: Text(month, style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                  ),
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: txs.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: divColor, indent: 66, endIndent: 20),
                    itemBuilder: (_, j) => TransactionListItem(
                      key: ValueKey(txs[j]),
                      transaction: txs,
                      index: j,
                      categoryList: categoryList,
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
