package com.example.signasphere

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class ModesWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_modes)

        // Text → Sign button
        views.setOnClickPendingIntent(R.id.btn_text_to_sign,
            createNavIntent(context, "/conversation", 1))

        // Sign → Text button
        views.setOnClickPendingIntent(R.id.btn_sign_to_text,
            createNavIntent(context, "/live-sign", 2))

        // Voice → Sign button
        views.setOnClickPendingIntent(R.id.btn_voice_to_sign,
            createNavIntent(context, "/avatar", 3))

        // Sign → Voice button
        views.setOnClickPendingIntent(R.id.btn_sign_to_voice,
            createNavIntent(context, "/live-sign", 4))

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun createNavIntent(context: Context, route: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            putExtra("route", route)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        return PendingIntent.getActivity(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
