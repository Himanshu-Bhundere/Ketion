package com.example.ketion.widgets.sync_status

import android.appwidget.AppWidgetManager
import android.content.Context
import android.widget.RemoteViews
import com.example.ketion.R
import es.antonborri.home_widget.HomeWidgetProvider

class SyncStatusWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_sync_status).apply {
                val syncStatus = widgetData.getString("sync_status", "Unknown")
                val lastSyncTime = widgetData.getString("last_sync_time", "Never")
                
                setTextViewText(R.id.sync_status_text, syncStatus)
                setTextViewText(R.id.sync_time_text, "Last sync: $lastSyncTime")

                val intent = es.antonborri.home_widget.HomeWidgetLaunchIntent.getActivity(
                    context, 
                    com.example.ketion.MainActivity::class.java,
                    android.net.Uri.parse("ketion://settings/sync")
                )
                setOnClickPendingIntent(R.id.sync_status_title, intent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
