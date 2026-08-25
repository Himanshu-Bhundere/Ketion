package com.example.ketion.widgets.quick_note

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import com.example.ketion.MainActivity
import com.example.ketion.R
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class QuickNoteWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_quick_note).apply {
                val intent = HomeWidgetLaunchIntent.getActivity(
                    context, 
                    MainActivity::class.java,
                    Uri.parse("ketion://new-note")
                )
                setOnClickPendingIntent(R.id.btn_quick_note, intent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
