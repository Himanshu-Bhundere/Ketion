package com.example.ketion

import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.view.Gravity
import android.view.MotionEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.ArrayList

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.ketion/assistive_ball"
    private val SHARE_CHANNEL = "com.example.ketion/share_target"
    private var shareMethodChannel: MethodChannel? = null
    private val pendingShares = mutableListOf<Map<String, Any?>>()
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var lastBallX: Int = -1
    private var lastBallY: Int = -1
    private var lastBallSize: Int = -1

    override fun getBackgroundMode(): BackgroundMode {
        return BackgroundMode.transparent
    }

    companion object {
        private var methodChannel: MethodChannel? = null

        fun notifyPositionChanged(x: Double, y: Double) {
            methodChannel?.invokeMethod("onPositionChanged", mapOf("x" to x, "y" to y))
        }

        fun notifyBallClicked(): Boolean {
            return if (methodChannel != null) {
                methodChannel?.invokeMethod("onBallClicked", null)
                true
            } else {
                false
            }
        }

        fun notifyHideBall() {
            methodChannel?.invokeMethod("hideOverlay", null)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }

        handleIncomingShareIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        result.success(Settings.canDrawOverlays(this))
                    } else {
                        result.success(true)
                    }
                }
                "requestOverlayPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                        pendingPermissionResult = result
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        startActivity(intent)
                    } else {
                        result.success(true)
                    }
                }
                "showOverlay" -> {
                    val x = (call.argument<Double>("x") ?: 1.0).toFloat()
                    val y = (call.argument<Double>("y") ?: 1.0).toFloat()
                    AssistiveBallService.startService(this, x, y)
                    result.success(null)
                }
                "hideOverlay" -> {
                    AssistiveBallService.stopService(this)
                    result.success(null)
                }
                "updatePosition" -> {
                    val x = (call.argument<Double>("x") ?: 1.0).toFloat()
                    val y = (call.argument<Double>("y") ?: 1.0).toFloat()
                    AssistiveBallService.updatePosition(this, x, y)
                    result.success(null)
                }
                "setOverlayWindowMode" -> {
                    val enable = call.argument<Boolean>("enable") ?: false
                    configureFloatingDialogMode(enable)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        val shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
        shareMethodChannel = shareChannel
        shareChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingShares" -> {
                    val list = synchronized(pendingShares) {
                        val copy = ArrayList(pendingShares)
                        pendingShares.clear()
                        copy
                    }
                    result.success(list)
                }
                "clearPendingShares" -> {
                    synchronized(pendingShares) {
                        pendingShares.clear()
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        processIntentAction(intent)
    }

    private fun configureFloatingDialogMode(enable: Boolean) {
        if (enable) {
            val dm = resources.displayMetrics
            val density = dm.density
            val widthPx = (270 * density).toInt().coerceAtMost((dm.widthPixels * 0.72f).toInt())
            val heightPx = (300 * density).toInt().coerceAtMost((dm.heightPixels * 0.45f).toInt())

            window.setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
            window.setLayout(widthPx, heightPx)

            val bX = if (lastBallX >= 0) lastBallX else dm.widthPixels - (60 * density).toInt()
            val bY = if (lastBallY >= 0) lastBallY else (100 * density).toInt()
            val bSize = if (lastBallSize > 0) lastBallSize else (52 * density).toInt()

            val isLeft = bX < (dm.widthPixels / 2)
            val posX = if (isLeft) {
                bX + bSize + (8 * density).toInt()
            } else {
                bX - widthPx - (8 * density).toInt()
            }.coerceIn(12, (dm.widthPixels - widthPx - 12).coerceAtLeast(12))

            val posY = (bY - (20 * density).toInt()).coerceIn(
                (24 * density).toInt(),
                (dm.heightPixels - heightPx - (24 * density).toInt()).coerceAtLeast(24)
            )

            window.setGravity(Gravity.TOP or Gravity.START)
            val params = window.attributes
            params.x = posX
            params.y = posY
            window.attributes = params

            window.addFlags(
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH
            )
        } else {
            window.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT)
            val params = window.attributes
            params.x = 0
            params.y = 0
            window.attributes = params
            moveTaskToBack(true)
        }
    }

    override fun onTouchEvent(event: MotionEvent?): Boolean {
        if (event?.action == MotionEvent.ACTION_OUTSIDE) {
            methodChannel?.invokeMethod("closeFloatingNote", null)
            configureFloatingDialogMode(false)
            return true
        }
        return super.onTouchEvent(event)
    }

    private fun processIntentAction(intent: Intent?) {
        if (intent == null) return
        val ballX = intent.getIntExtra("ball_x", -1)
        val ballY = intent.getIntExtra("ball_y", -1)
        val ballSize = intent.getIntExtra("ball_size", -1)
        if (ballX >= 0) lastBallX = ballX
        if (ballY >= 0) lastBallY = ballY
        if (ballSize > 0) lastBallSize = ballSize

        val action = intent.getStringExtra("action")
        when (action) {
            "quick_note" -> {
                configureFloatingDialogMode(true)
                methodChannel?.invokeMethod("openQuickNote", mapOf("isStandalone" to true))
                intent.removeExtra("action")
            }
            "note_selector" -> {
                configureFloatingDialogMode(true)
                methodChannel?.invokeMethod("openNoteSelector", mapOf("isStandalone" to true))
                intent.removeExtra("action")
            }
            else -> {
                if (intent.getBooleanExtra("from_assistive_ball", false)) {
                    intent.removeExtra("from_assistive_ball")
                    methodChannel?.invokeMethod("onBallClicked", null)
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        pendingPermissionResult?.let { res ->
            val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Settings.canDrawOverlays(this)
            } else {
                true
            }
            res.success(granted)
            pendingPermissionResult = null
        }

        processIntentAction(intent)
    }

    override fun onDestroy() {
        pendingPermissionResult = null
        if (methodChannel != null) {
            methodChannel = null
        }
        shareMethodChannel = null
        super.onDestroy()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        processIntentAction(intent)
        handleIncomingShareIntent(intent)
    }

    private fun handleIncomingShareIntent(intent: Intent?) {
        if (intent == null) return
        val action = intent.action ?: return
        if (action != Intent.ACTION_SEND && action != Intent.ACTION_SEND_MULTIPLE && action != Intent.ACTION_VIEW) return

        val receivedItems = mutableListOf<Map<String, Any?>>()

        try {
            if (action == Intent.ACTION_VIEW) {
                val uri = intent.data
                val mimeType = intent.type ?: "application/octet-stream"
                if (uri != null) {
                    processUri(uri, mimeType)?.let { receivedItems.add(it) }
                } else if (intent.clipData != null && intent.clipData!!.itemCount > 0) {
                    for (i in 0 until intent.clipData!!.itemCount) {
                        val clipUri = intent.clipData!!.getItemAt(i).uri
                        if (clipUri != null) {
                            processUri(clipUri, mimeType)?.let { receivedItems.add(it) }
                        }
                    }
                }
            } else if (action == Intent.ACTION_SEND) {
                val mimeType = intent.type ?: "application/octet-stream"
                val extraText = intent.getStringExtra(Intent.EXTRA_TEXT)
                val extraStream = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                }

                if (extraStream != null) {
                    processUri(extraStream, mimeType)?.let { receivedItems.add(it) }
                } else if (intent.clipData != null && intent.clipData!!.itemCount > 0) {
                    for (i in 0 until intent.clipData!!.itemCount) {
                        val clipUri = intent.clipData!!.getItemAt(i).uri
                        if (clipUri != null) {
                            processUri(clipUri, mimeType)?.let { receivedItems.add(it) }
                        }
                    }
                } else if (!extraText.isNullOrBlank()) {
                    val isUrl = extraText.startsWith("http://") || extraText.startsWith("https://")
                    receivedItems.add(
                        mapOf(
                            "type" to if (isUrl) "link" else "text",
                            "name" to if (isUrl) extraText else "Shared Text",
                            "url" to if (isUrl) extraText else null,
                            "text" to if (!isUrl) extraText else null
                        )
                    )
                }
            } else if (action == Intent.ACTION_SEND_MULTIPLE) {
                val mimeType = intent.type ?: "application/octet-stream"
                val extraStreams = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM)
                }

                if (!extraStreams.isNullOrEmpty()) {
                    extraStreams.forEach { uri ->
                        processUri(uri, mimeType)?.let { receivedItems.add(it) }
                    }
                } else if (intent.clipData != null && intent.clipData!!.itemCount > 0) {
                    for (i in 0 until intent.clipData!!.itemCount) {
                        val clipUri = intent.clipData!!.getItemAt(i).uri
                        if (clipUri != null) {
                            processUri(clipUri, mimeType)?.let { receivedItems.add(it) }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to extract shared items", e)
        }

        if (receivedItems.isNotEmpty()) {
            if (shareMethodChannel != null) {
                shareMethodChannel?.invokeMethod("onShareReceived", receivedItems)
            } else {
                synchronized(pendingShares) {
                    pendingShares.addAll(receivedItems)
                }
            }
        }
    }

    private fun processUri(uri: Uri, fallbackMimeType: String): Map<String, Any?>? {
        return try {
            var name: String? = null
            var size: Long? = null
            if (uri.scheme == "content") {
                contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    val nameIndex = cursor.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    val sizeIndex = cursor.getColumnIndex(android.provider.OpenableColumns.SIZE)
                    if (nameIndex != -1 && cursor.moveToFirst()) {
                        name = cursor.getString(nameIndex)
                    }
                    if (sizeIndex != -1 && !cursor.isNull(sizeIndex)) {
                        size = cursor.getLong(sizeIndex)
                    }
                }
            }
            if (name == null) {
                name = uri.lastPathSegment ?: "shared_file_${System.currentTimeMillis()}"
            }

            val mimeType = contentResolver.getType(uri) ?: fallbackMimeType
            val safeName = name!!.replace(Regex("[^a-zA-Z0-9._-]"), "_")
            val shareDir = File(cacheDir, "shared_incoming")
            if (!shareDir.exists()) shareDir.mkdirs()

            val destFile = File(shareDir, "${System.currentTimeMillis()}_$safeName")
            contentResolver.openInputStream(uri)?.use { input ->
                destFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }

            mapOf(
                "type" to "file",
                "name" to name,
                "localPath" to destFile.absolutePath,
                "mimeType" to mimeType,
                "size" to (size ?: destFile.length())
            )
        } catch (e: Exception) {
            android.util.Log.e("MainActivity", "Failed to process shared URI: $uri", e)
            null
        }
    }
}
