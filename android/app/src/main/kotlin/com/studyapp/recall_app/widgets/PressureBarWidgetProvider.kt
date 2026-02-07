package com.studyapp.recall_app.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import com.studyapp.recall_app.R
import es.antonborri.home_widget.HomeWidgetPlugin

class PressureBarWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_pressure_bar)

            val data = HomeWidgetPlugin.getData(context)
            val progressText = data.getString("progressText", "")
            val dailyProgressStr = data.getString("dailyProgress", "0.0")
            val dailyProgress = dailyProgressStr?.toDoubleOrNull() ?: 0.0
            val progressPercent = (dailyProgress * 100).toInt().coerceIn(0, 100)

            views.setTextViewText(R.id.tv_progress_text, progressText)
            views.setTextViewText(R.id.tv_progress_percent, "$progressPercent%")
            views.setProgressBar(R.id.progress_bar, 100, progressPercent, false)

            // Deep link: recall://review
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("recall://review")).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 1, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
