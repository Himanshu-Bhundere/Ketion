package com.example.ketion.widgets.quick_note

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
import com.example.ketion.widgets.recent_notes.WidgetRepository
import es.antonborri.home_widget.HomeWidgetProvider

class QuickNoteWidgetProvider : HomeWidgetProvider() {
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
        val views = RemoteViews(context.packageName, R.layout.widget_quick_note).apply {
            val minHeight = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT) ?: 60
            val minWidth = options?.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH) ?: 60

            val is2x2OrLarger = minHeight >= 90 && minWidth >= 90 &&
                (minWidth.toFloat() / minHeight.toFloat()).let { it in 0.6f..1.65f }

            val newNoteIntent = Intent(context, MainActivity::class.java).apply {
                action = "es.antonborri.home_widget.action.LAUNCH"
                data = Uri.parse("ketion://new-note")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val newNotePendingIntent = PendingIntent.getActivity(
                context,
                1001,
                newNoteIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Direct button tap always creates note
            setOnClickPendingIntent(R.id.btn_quick_note, newNotePendingIntent)

            if (is2x2OrLarger) {
                setViewVisibility(R.id.quick_note_label, View.VISIBLE)

                var latestId = widgetData.getString("latest_note_id", null)
                var latestTitle = widgetData.getString("latest_note_title", null)

                if (latestId.isNullOrEmpty()) {
                    val snapshotDbPath = widgetData.getString("snapshot_db_path", null)
                    val repo = WidgetRepository(snapshotDbPath)
                    val recent = repo.getRecentNotes()
                    if (recent.isNotEmpty()) {
                        latestId = recent.first().id
                        latestTitle = recent.first().title
                    }
                }

                if (!latestId.isNullOrEmpty() && !latestTitle.isNullOrEmpty()) {
                    setViewVisibility(R.id.latest_note_container, View.VISIBLE)
                    setTextViewText(R.id.latest_note_title, latestTitle)

                    val openNoteIntent = Intent(context, MainActivity::class.java).apply {
                        action = "es.antonborri.home_widget.action.LAUNCH"
                        data = Uri.parse("ketion://note/$latestId")
                        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    }
                    val openNotePendingIntent = PendingIntent.getActivity(
                        context,
                        1004,
                        openNoteIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    setOnClickPendingIntent(R.id.latest_note_container, openNotePendingIntent)
                    setOnClickPendingIntent(R.id.widget_root, newNotePendingIntent)
                } else {
                    setViewVisibility(R.id.latest_note_container, View.GONE)
                    setOnClickPendingIntent(R.id.widget_root, newNotePendingIntent)
                }
            } else {
                setViewVisibility(R.id.quick_note_label, View.GONE)
                setViewVisibility(R.id.latest_note_container, View.GONE)
                setOnClickPendingIntent(R.id.widget_root, newNotePendingIntent)
            }
        }
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

