package com.example.ketion.widgets.recent_notes

import android.database.sqlite.SQLiteDatabase
import java.io.File

data class RecentNote(val id: String, val title: String, val date: String)

class WidgetRepository(private val snapshotDbPath: String?) {
    enum class RepositoryStatus {
        SUCCESS,
        EMPTY,
        UNAVAILABLE,
        ERROR
    }

    var status: RepositoryStatus = RepositoryStatus.UNAVAILABLE
        private set

    fun getRecentNotes(): List<RecentNote> {
        val notes = mutableListOf<RecentNote>()
        if (snapshotDbPath == null) {
            status = RepositoryStatus.UNAVAILABLE
            return notes
        }

        val file = File(snapshotDbPath)
        if (!file.exists()) {
            status = RepositoryStatus.UNAVAILABLE
            return notes
        }

        var db: SQLiteDatabase? = null
        try {
            db = SQLiteDatabase.openDatabase(snapshotDbPath, null, SQLiteDatabase.OPEN_READONLY)
            val cursor = db.rawQuery("SELECT id, title, updated_at FROM recent_pages ORDER BY updated_at DESC LIMIT 10", null)
            
            while (cursor.moveToNext()) {
                val id = cursor.getString(0) ?: ""
                val title = cursor.getString(1) ?: "Untitled"
                val date = cursor.getString(2) ?: ""
                notes.add(RecentNote(id, title, date))
            }
            cursor.close()
            status = if (notes.isEmpty()) RepositoryStatus.EMPTY else RepositoryStatus.SUCCESS
        } catch (e: Exception) {
            e.printStackTrace()
            status = RepositoryStatus.ERROR
        } finally {
            db?.close()
        }
        return notes
    }
}
