package com.example.signasphere

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class EmergencyWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
        val views = RemoteViews(context.packageName, R.layout.widget_emergency)

        // Call Police (100)
        views.setOnClickPendingIntent(R.id.btn_call_police,
            createDialIntent(context, "100", 10))

        // Call Ambulance (108)
        views.setOnClickPendingIntent(R.id.btn_call_ambulance,
            createDialIntent(context, "108", 11))

        // Call Fire Brigade (101)
        views.setOnClickPendingIntent(R.id.btn_call_fire,
            createDialIntent(context, "101", 12))

        // SOS Message
        views.setOnClickPendingIntent(R.id.btn_sos_message,
            createSosIntent(context, 13))

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    private fun createDialIntent(context: Context, number: String, requestCode: Int): PendingIntent {
        val intent = Intent(Intent.ACTION_DIAL).apply {
            data = Uri.parse("tel:$number")
        }
        return PendingIntent.getActivity(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun createSosIntent(context: Context, requestCode: Int): PendingIntent {
        // Read emergency contact from SharedPreferences
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val emergencyNumber = prefs.getString("flutter.emergency_contact_phone", null) ?: ""
        val sosMessage = "SOS! I need help immediately. This is an emergency. Please contact me ASAP."

        val intent = Intent(Intent.ACTION_SENDTO).apply {
            data = Uri.parse("smsto:$emergencyNumber")
            putExtra("sms_body", sosMessage)
        }
        return PendingIntent.getActivity(
            context, requestCode, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
