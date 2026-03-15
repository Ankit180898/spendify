import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

class WidgetService {
  static const _androidProvider = 'SpendifyWidgetProvider';
  static const _iOSKind = 'SpendifyWidget';
  static const _appGroupId = 'group.com.example.spendify';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<void> update({
    required double balance,
    required double monthSpent,
    required double monthlyBudget,
    required String currencySymbol,
    required String userName,
  }) async {
    final fmt = NumberFormat('#,##0', 'en_IN');

    await HomeWidget.saveWidgetData('balance', '$currencySymbol${fmt.format(balance)}');
    await HomeWidget.saveWidgetData('month_spent', '$currencySymbol${fmt.format(monthSpent)}');
    await HomeWidget.saveWidgetData('monthly_budget', monthlyBudget > 0 ? '$currencySymbol${fmt.format(monthlyBudget)}' : '');
    await HomeWidget.saveWidgetData('budget_pct', (monthlyBudget > 0 ? (monthSpent / monthlyBudget).clamp(0.0, 1.0) : 0.0).toString());
    await HomeWidget.saveWidgetData('currency', currencySymbol);
    await HomeWidget.saveWidgetData('user_name', userName.split(' ').first);

    await HomeWidget.updateWidget(
      androidName: _androidProvider,
      iOSName: _iOSKind,
    );
  }
}
