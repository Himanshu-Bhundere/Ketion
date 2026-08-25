package com.example.ketion.widgets.recent_notes

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.example.ketion.R
import es.antonborri.home_widget.HomeWidgetPlugin
import android.net.Uri

class RecentNotesWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return RecentNotesRemoteViewsFactory(this.applicationContext)
    }
}

class RecentNotesRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var notes: List<RecentNote> = emptyList()
    private lateinit var repository: WidgetRepository

    override fun onCreate() {
        // Initialization if needed
    }

    override fun onDataSetChanged() {
        val widgetData = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val snapshotDbPath = widgetData.getString("snapshot_db_path", null)
        repository = WidgetRepository(snapshotDbPath)
        notes = repository.getRecentNotes()
    }

    override fun onDestroy() {
        notes = emptyList()
    }

    override fun getCount(): Int = notes.size

    override fun getViewAt(position: Int): RemoteViews {
        val note = notes[position]
        val views = RemoteViews(context.packageName, R.layout.widget_recent_notes_item)
        views.setTextViewText(R.id.note_title, note.title)
        views.setTextViewText(R.id.note_date, note.date)

        val fillInIntent = Intent().apply {
            data = Uri.parse("ketion://note/${note.id}")
        }
        views.setOnClickFillInIntent(R.id.note_title, fillInIntent)
        return views
    }

    override fun getLoadingView(): RemoteViews? = null
    override fun getViewTypeCount(): Int = 1
    override fun getItemId(position: Int): Long = position.toLong()
    override fun hasStableIds(): Boolean = true
}
