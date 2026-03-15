package com.example.spendify

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import android.app.PendingIntent
import es.antonborri.home_widget.HomeWidgetProvider

class SpendifyWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            val balance = widgetData.getString("balance", "—") ?: "—"
            val monthSpent = widgetData.getString("month_spent", "—") ?: "—"
            val monthlyBudget = widgetData.getString("monthly_budget", "") ?: ""
            val budgetPct = (widgetData.getString("budget_pct", "0") ?: "0").toFloatOrNull() ?: 0f

            val views = RemoteViews(context.packageName, R.layout.spendify_widget)

            views.setTextViewText(R.id.tv_balance, balance)
            views.setTextViewText(R.id.tv_spent, monthSpent)

            if (monthlyBudget.isNotEmpty()) {
                views.setTextViewText(R.id.tv_budget_of, " / $monthlyBudget")
                views.setViewVisibility(R.id.pb_budget, View.VISIBLE)
                views.setProgressBar(R.id.pb_budget, 100, (budgetPct * 100).toInt(), false)
            } else {
                views.setTextViewText(R.id.tv_budget_of, "")
                views.setViewVisibility(R.id.pb_budget, View.GONE)
            }

            // Open app on tap
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            if (launchIntent != null) {
                val pendingIntent = PendingIntent.getActivity(
                    context, 0, launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
