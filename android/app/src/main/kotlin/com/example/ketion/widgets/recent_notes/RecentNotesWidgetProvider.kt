package com.example.ketion.widgets.recent_notes

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import com.example.ketion.R
import es.antonborri.home_widget.HomeWidgetProvider
import com.example.ketion.MainActivity
import es.antonborri.home_widget.HomeWidgetLaunchIntent

class RecentNotesWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_recent_notes).apply {
                val intent = Intent(context, RecentNotesWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
                }
                setRemoteAdapter(R.id.recent_notes_list, intent)
                setEmptyView(R.id.recent_notes_list, R.id.empty_view)

                // PendingIntent template for list items
                val clickIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                }
                val clickPendingIntent = PendingIntent.getActivity(
                    context, 0, clickIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
                )
                setPendingIntentTemplate(R.id.recent_notes_list, clickPendingIntent)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
