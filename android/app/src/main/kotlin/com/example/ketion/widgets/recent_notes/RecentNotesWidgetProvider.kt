package com.example.ketion.widgets.recent_notes

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import com.example.ketion.MainActivity
import com.example.ketion.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class RecentNotesWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            updateWidget(context, appWidgetManager, appWidgetId, widgetData, options)
        }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        updateWidget(context, appWidgetManager, appWidgetId, widgetData, newOptions)
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        widgetData: android.content.SharedPreferences,
        options: Bundle?
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_recent_notes).apply {
            val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 110
            // Responsive layout: 2x1 is compact (height < 100dp), 2x2 is expanded
            if (minHeight < 100) {
                setViewVisibility(R.id.header_layout, View.GONE)
            } else {
                setViewVisibility(R.id.header_layout, View.VISIBLE)
            }

            val newNoteIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("ketion://new-note")
            )
            setOnClickPendingIntent(R.id.btn_header_new_note, newNoteIntent)

            val intent = Intent(context, RecentNotesWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            setRemoteAdapter(R.id.recent_notes_list, intent)
            setEmptyView(R.id.recent_notes_list, R.id.empty_view)

            // Check data state to show distinct messages
            val snapshotDbPath = widgetData.getString("snapshot_db_path", null)
            val repo = WidgetRepository(snapshotDbPath)
            repo.getRecentNotes()
            when (repo.status) {
                WidgetRepository.RepositoryStatus.UNAVAILABLE -> {
                    setTextViewText(R.id.empty_view, "Notes unavailable\nOpen Ketion to sync")
                }
                WidgetRepository.RepositoryStatus.ERROR -> {
                    setTextViewText(R.id.empty_view, "Error loading notes")
                }
                WidgetRepository.RepositoryStatus.EMPTY -> {
                    setTextViewText(R.id.empty_view, "No recent notes")
                }
                WidgetRepository.RepositoryStatus.SUCCESS -> {
                    setTextViewText(R.id.empty_view, "No recent notes")
                }
            }

            // PendingIntent template for list items using HomeWidgetLaunchIntent
            val clickIntent = Intent(context, MainActivity::class.java).apply {
                action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
            }
            val clickPendingIntent = PendingIntent.getActivity(
                context, 0, clickIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            setPendingIntentTemplate(R.id.recent_notes_list, clickPendingIntent)
        }

        appWidgetManager.updateAppWidget(appWidgetId, views)
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.recent_notes_list)
    }
}
