package com.example.ketion

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import java.io.File

class KetionWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: android.content.SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Launch App Action
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
                setOnClickPendingIntent(R.id.btn_launch_app, pendingIntent)

                // Quick Note Action (passes uri to flutter)
                val quickNoteIntent = HomeWidgetLaunchIntent.getActivity(
                    context, 
                    MainActivity::class.java,
                    Uri.parse("ketion://quick_note")
                )
                setOnClickPendingIntent(R.id.btn_quick_note, quickNoteIntent)

                // Update Sync Status
                val syncStatus = widgetData.getString("sync_status", "Unknown")
                val lastSyncTime = widgetData.getString("last_sync_time", "Never")
                setTextViewText(R.id.sync_status_text, "Sync: $syncStatus ($lastSyncTime)")

                // Read from Snapshot DB
                val snapshotDbPath = widgetData.getString("snapshot_db_path", null)
                var recentPagesText = "No recent pages"
                if (snapshotDbPath != null) {
                    val file = File(snapshotDbPath)
                    if (file.exists()) {
                        try {
                            val db = SQLiteDatabase.openDatabase(snapshotDbPath, null, SQLiteDatabase.OPEN_READONLY)
                            val cursor = db.rawQuery("SELECT title FROM recent_pages ORDER BY updated_at DESC LIMIT 3", null)
                            val titles = mutableListOf<String>()
                            while (cursor.moveToNext()) {
                                titles.add(cursor.getString(0) ?: "Untitled")
                            }
                            cursor.close()
                            db.close()
                            if (titles.isNotEmpty()) {
                                recentPagesText = titles.joinToString("\n- ", prefix = "- ")
                            }
                        } catch (e: Exception) {
                            recentPagesText = "Error reading DB: ${e.message}"
                        }
                    }
                }
                setTextViewText(R.id.recent_note_text, recentPagesText)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
