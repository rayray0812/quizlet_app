package com.studyapp.recall_app.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import com.studyapp.recall_app.R
import es.antonborri.home_widget.HomeWidgetPlugin

class DailyMissionWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_daily_mission)

            val data = HomeWidgetPlugin.getData(context)
            val headline = data.getString("headline", "")
            val subtitle = data.getString("subtitle", "")
            val streakText = data.getString("streakText", "")
            val ctaText = data.getString("ctaText", "Start Review")
            val mood = data.getString("mood", "normal")

            val emoji = when (mood) {
                "celebration" -> "\uD83C\uDF89"  // 🎉
                "urgent" -> "\uD83D\uDD25"        // 🔥
                else -> "\uD83D\uDCDA"            // 📚
            }

            views.setTextViewText(R.id.tv_emoji, emoji)
            views.setTextViewText(R.id.tv_headline, headline)
            views.setTextViewText(R.id.tv_subtitle, subtitle)
            views.setTextViewText(R.id.tv_streak, streakText)
            views.setTextViewText(R.id.tv_cta, ctaText)
            views.setViewVisibility(
                R.id.tv_subtitle,
                if (subtitle.isNullOrBlank()) View.GONE else View.VISIBLE
            )
            views.setViewVisibility(
                R.id.tv_streak,
                if (streakText.isNullOrBlank()) View.GONE else View.VISIBLE
            )

            // Deep link: recall://review
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("recall://review")).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 0, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
