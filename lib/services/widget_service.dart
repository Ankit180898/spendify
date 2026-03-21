import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:spendify/widgets/spendify_widget_preview.dart';

class WidgetService {
  static const _androidProvider = 'SpendifyWidgetReceiver';
  static const _iOSKind = 'SpendifyWidget';
  static const _appGroupId = 'group.com.sentientlabs.spendify';

  static bool get _supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> init() async {
    if (!_supported) return;
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> update({
    required double balance,
    required double monthSpent,
    required double monthlyBudget,
    required String currencySymbol,
    required String userName,
  }) async {
    if (!_supported) return;

    final fmt       = NumberFormat('#,##0', 'en_IN');
    final spentStr  = '$currencySymbol${fmt.format(monthSpent)}';
    final budgetStr = monthlyBudget > 0 ? '$currencySymbol${fmt.format(monthlyBudget)}' : '';
    final budgetPct = monthlyBudget > 0
        ? (monthSpent / monthlyBudget).clamp(0.0, 1.0)
        : 0.0;
    final hasBudget = monthlyBudget > 0;
    final subtitle  = hasBudget ? 'of $budgetStr spent this month' : 'spent this month';

    // iOS: keep data-based approach (SwiftUI reads from UserDefaults)
    if (Platform.isIOS) {
      await HomeWidget.saveWidgetData('month_spent', spentStr);
      await HomeWidget.saveWidgetData('monthly_budget', budgetStr);
      await HomeWidget.saveWidgetData('budget_pct', budgetPct.toString());
      await HomeWidget.updateWidget(iOSName: _iOSKind);
      return;
    }

    // Android: render a Flutter widget snapshot → displayed as ImageView
    await HomeWidget.renderFlutterWidget(
      SpendifyWidgetPreview(
        monthSpent: spentStr,
        subtitle: subtitle,
        budgetPct: budgetPct,
        hasBudget: hasBudget,
      ),
      key: 'widget_snapshot',
      logicalSize: const Size(350, 175),
      pixelRatio: 2.0, // fixed ratio keeps bitmap size ≤ ~1 MB
    );

    await HomeWidget.updateWidget(androidName: _androidProvider);
  }
}
