package com.example.ketion

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Point
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min

class AssistiveBallService : Service() {

    private var windowManager: WindowManager? = null
    private var floatingBallView: View? = null
    private var floatingMenuView: View? = null
    private var ballLayoutParams: WindowManager.LayoutParams? = null
    private var menuLayoutParams: WindowManager.LayoutParams? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundServiceNotification()
        }
    }

    private fun startForegroundServiceNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "assistive_ball_service_channel"
            val channelName = "Ketion Assistive Ball"
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_MIN
            ).apply {
                description = "Keeps Ketion Assistive Ball accessible"
                setShowBadge(false)
            }
            notificationManager.createNotificationChannel(channel)

            val openAppIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                openAppIntent,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
            )

            val notification: Notification = Notification.Builder(this, channelId)
                .setContentTitle("Ketion Assistive Ball")
                .setContentText("Tap to interact with Ketion")
                .setSmallIcon(R.drawable.ic_assistive_ball)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()

            startForeground(1002, notification)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        if (intent?.action == ACTION_STOP) {
            prefs.edit().putBoolean(KEY_ENABLED, false).apply()
            removeFloatingViews()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        if (intent?.action == ACTION_START) {
            prefs.edit().putBoolean(KEY_ENABLED, true).apply()
        }

        if (!prefs.getBoolean(KEY_ENABLED, false)) {
            removeFloatingViews()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            prefs.edit().putBoolean(KEY_ENABLED, false).apply()
            removeFloatingViews()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        val savedX = prefs.getFloat(KEY_NORM_X, DEFAULT_NORM_X)
        val savedY = prefs.getFloat(KEY_NORM_Y, DEFAULT_NORM_Y)
        val normX = intent?.getFloatExtra(EXTRA_X, savedX) ?: savedX
        val normY = intent?.getFloatExtra(EXTRA_Y, savedY) ?: savedY

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundServiceNotification()
        }

        val clampedX = normX.coerceIn(MIN_NORM_X, MAX_NORM_X)
        val clampedY = normY.coerceIn(MIN_NORM_Y, MAX_NORM_Y)

        if (floatingBallView == null) {
            setupFloatingBallView(clampedX, clampedY)
        } else if (intent?.action == ACTION_UPDATE_POS) {
            updateBallPosition(clampedX, clampedY)
        }

        return START_STICKY
    }

    private data class UsableScreenArea(
        val left: Int,
        val top: Int,
        val width: Int,
        val height: Int
    )

    private fun getUsableScreenArea(): UsableScreenArea {
        val wm = (windowManager ?: getSystemService(Context.WINDOW_SERVICE) as WindowManager)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val metrics = wm.currentWindowMetrics
            val insets = metrics.windowInsets.getInsetsIgnoringVisibility(
                WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout()
            )
            val bounds = metrics.bounds
            UsableScreenArea(
                left = insets.left,
                top = insets.top,
                width = (bounds.width() - insets.left - insets.right).coerceAtLeast(1),
                height = (bounds.height() - insets.top - insets.bottom).coerceAtLeast(1)
            )
        } else {
            val display = wm.defaultDisplay
            val size = Point()
            @Suppress("DEPRECATION")
            display.getSize(size)
            UsableScreenArea(
                left = 0,
                top = 0,
                width = size.x.coerceAtLeast(1),
                height = size.y.coerceAtLeast(1)
            )
        }
    }

    private fun calculatePixelPosition(
        normX: Float,
        normY: Float,
        ballSizePx: Int,
        usable: UsableScreenArea
    ): Pair<Int, Int> {
        val density = resources.displayMetrics.density
        val spacingX = max((16 * density).toInt(), (usable.width * 0.016f).toInt())
        val spacingY = max((16 * density).toInt(), (usable.height * 0.022f).toInt())
        val availableWidth = (usable.width - ballSizePx - 2 * spacingX).coerceAtLeast(1)
        val availableHeight = (usable.height - ballSizePx - 2 * spacingY).coerceAtLeast(1)

        val clampedNormX = normX.coerceIn(MIN_NORM_X, MAX_NORM_X)
        val clampedNormY = normY.coerceIn(MIN_NORM_Y, MAX_NORM_Y)

        val targetX = usable.left + spacingX + (clampedNormX * availableWidth).toInt()
        val targetY = usable.top + spacingY + (clampedNormY * availableHeight).toInt()
        return Pair(targetX, targetY)
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun setupFloatingBallView(initialNormX: Float, initialNormY: Float) {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val ballSizeDp = 52
        val density = resources.displayMetrics.density
        val ballSizePx = (ballSizeDp * density).toInt()

        val usableArea = getUsableScreenArea()
        val (initX, initY) = calculatePixelPosition(initialNormX, initialNormY, ballSizePx, usableArea)

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        ballLayoutParams = WindowManager.LayoutParams(
            ballSizePx,
            ballSizePx,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = initX
            y = initY
        }

        val ballView = ImageView(this).apply {
            val shape = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                // Use Ketion's primary brand purple instead of blue
                setColor(Color.parseColor("#6200EE"))
            }
            background = shape
            setImageResource(R.drawable.ic_assistive_ball)
            setColorFilter(Color.WHITE)
            val paddingPx = (14 * density).toInt()
            setPadding(paddingPx, paddingPx, paddingPx, paddingPx)
            elevation = 12f * density
        }

        ballView.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var touchStartX = 0f
            private var touchStartY = 0f
            private var isClick = false

            override fun onTouch(v: View?, event: MotionEvent?): Boolean {
                if (event == null || ballLayoutParams == null) return false

                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = ballLayoutParams!!.x
                        initialY = ballLayoutParams!!.y
                        touchStartX = event.rawX
                        touchStartY = event.rawY
                        isClick = true
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = event.rawX - touchStartX
                        val dy = event.rawY - touchStartY
                        if (abs(dx) > 10 || abs(dy) > 10) {
                            isClick = false
                            dismissMenu()
                        }
                        ballLayoutParams!!.x = initialX + dx.toInt()
                        ballLayoutParams!!.y = initialY + dy.toInt()
                        windowManager?.updateViewLayout(floatingBallView, ballLayoutParams)
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (isClick) {
                            toggleFloatingMenu()
                        } else {
                            val currentUsable = getUsableScreenArea()
                            val curDensity = resources.displayMetrics.density
                            val spacingX = max((16 * curDensity).toInt(), (currentUsable.width * 0.016f).toInt())
                            val spacingY = max((16 * curDensity).toInt(), (currentUsable.height * 0.022f).toInt())
                            val availableW = (currentUsable.width - ballSizePx - 2 * spacingX).coerceAtLeast(1)
                            val availableH = (currentUsable.height - ballSizePx - 2 * spacingY).coerceAtLeast(1)

                            val currentNormX = ((ballLayoutParams!!.x - currentUsable.left - spacingX).toFloat() / availableW).coerceIn(0f, 1f)
                            val currentNormY = ((ballLayoutParams!!.y - currentUsable.top - spacingY).toFloat() / availableH).coerceIn(0f, 1f)

                            val targetNormX = if (currentNormX < 0.5f) MIN_NORM_X else MAX_NORM_X
                            val targetNormY = if (currentNormY < 0.5f) MIN_NORM_Y else MAX_NORM_Y

                            val (snapX, snapY) = calculatePixelPosition(targetNormX, targetNormY, ballSizePx, currentUsable)
                            ballLayoutParams!!.x = snapX
                            ballLayoutParams!!.y = snapY
                            windowManager?.updateViewLayout(floatingBallView, ballLayoutParams)

                            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                            prefs.edit()
                                .putFloat(KEY_NORM_X, targetNormX)
                                .putFloat(KEY_NORM_Y, targetNormY)
                                .apply()

                            MainActivity.notifyPositionChanged(targetNormX.toDouble(), targetNormY.toDouble())
                        }
                        return true
                    }
                }
                return false
            }
        })

        floatingBallView = ballView
        windowManager?.addView(floatingBallView, ballLayoutParams)
    }

    private fun toggleFloatingMenu() {
        if (floatingMenuView != null) {
            dismissMenu()
        } else {
            showFloatingMenu()
        }
    }

    private fun showFloatingMenu() {
        val ballParams = ballLayoutParams ?: return
        val density = resources.displayMetrics.density
        val usableArea = getUsableScreenArea()

        val menuWidthPx = (200 * density).toInt()
        val isLeft = ballParams.x < (usableArea.width / 2)

        val menuX = if (isLeft) {
            ballParams.x + (60 * density).toInt()
        } else {
            (ballParams.x - menuWidthPx - (8 * density).toInt()).coerceAtLeast(usableArea.left)
        }
        val menuY = (ballParams.y - (20 * density).toInt()).coerceIn(
            usableArea.top + (10 * density).toInt(),
            (usableArea.height - (180 * density).toInt()).coerceAtLeast(usableArea.top)
        )

        val layoutType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        menuLayoutParams = WindowManager.LayoutParams(
            menuWidthPx,
            WindowManager.LayoutParams.WRAP_CONTENT,
            layoutType,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = menuX
            y = menuY
        }

        val menuContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 14f * density
                setColor(Color.parseColor("#2A2D32"))
                setStroke((1 * density).toInt(), Color.parseColor("#33FFFFFF"))
            }
            background = bg
            elevation = 16f * density
            setPadding((12 * density).toInt(), (10 * density).toInt(), (12 * density).toInt(), (10 * density).toInt())
        }

        // Quick Note Item
        menuContainer.addView(createMenuItem("Quick Note", android.R.drawable.ic_menu_edit) {
            dismissMenu()
            launchKetionWithAction("quick_note")
        })

        // Note Selector Item
        menuContainer.addView(createMenuItem("Note Selector", android.R.drawable.ic_menu_agenda) {
            dismissMenu()
            launchKetionWithAction("note_selector")
        })

        // Divider
        val divider = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                (1 * density).toInt()
            ).apply {
                setMargins(0, (6 * density).toInt(), 0, (6 * density).toInt())
            }
            setBackgroundColor(Color.parseColor("#22FFFFFF"))
        }
        menuContainer.addView(divider)

        // Hide Ball Item
        menuContainer.addView(createMenuItem("Hide Ball", android.R.drawable.ic_menu_close_clear_cancel) {
            dismissMenu()
            MainActivity.notifyHideBall()
            stopService(this)
        })

        menuContainer.setOnTouchListener { _, event ->
            if (event.action == MotionEvent.ACTION_OUTSIDE) {
                dismissMenu()
                true
            } else {
                false
            }
        }

        floatingMenuView = menuContainer
        windowManager?.addView(floatingMenuView, menuLayoutParams)
    }

    private fun createMenuItem(title: String, iconRes: Int? = null, onClick: () -> Unit): View {
        val density = resources.displayMetrics.density
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding((8 * density).toInt(), (10 * density).toInt(), (8 * density).toInt(), (10 * density).toInt())
            isClickable = true
            isFocusable = true

            if (iconRes != null) {
                val iconView = ImageView(this@AssistiveBallService).apply {
                    setImageResource(iconRes)
                    setColorFilter(Color.parseColor("#C4C7CF"))
                    val iconSize = (18 * density).toInt()
                    layoutParams = LinearLayout.LayoutParams(iconSize, iconSize).apply {
                        marginEnd = (10 * density).toInt()
                    }
                }
                addView(iconView)
            }

            val textView = TextView(this@AssistiveBallService).apply {
                text = title
                setTextColor(Color.parseColor("#E2E2E6"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            }
            addView(textView)

            setOnClickListener { onClick() }
        }
    }

    private fun launchKetionWithAction(action: String) {
        val openIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("action", action)
            putExtra("from_assistive_ball", true)
        }
        startActivity(openIntent)
    }

    private fun dismissMenu() {
        if (floatingMenuView != null && windowManager != null) {
            try {
                windowManager?.removeView(floatingMenuView)
            } catch (_: Exception) {}
            floatingMenuView = null
        }
    }

    private fun updateBallPosition(normX: Float, normY: Float) {
        if (floatingBallView == null || ballLayoutParams == null || windowManager == null) return
        val ballSize = floatingBallView!!.width.takeIf { it > 0 } ?: (52 * resources.displayMetrics.density).toInt()
        val usable = getUsableScreenArea()
        val (newX, newY) = calculatePixelPosition(normX, normY, ballSize, usable)

        ballLayoutParams!!.x = newX
        ballLayoutParams!!.y = newY
        windowManager?.updateViewLayout(floatingBallView, ballLayoutParams)
        dismissMenu()

        val clampedX = normX.coerceIn(MIN_NORM_X, MAX_NORM_X)
        val clampedY = normY.coerceIn(MIN_NORM_Y, MAX_NORM_Y)
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putFloat(KEY_NORM_X, clampedX)
            .putFloat(KEY_NORM_Y, clampedY)
            .apply()
    }

    private fun removeFloatingViews() {
        dismissMenu()
        if (floatingBallView != null && windowManager != null) {
            try {
                windowManager?.removeView(floatingBallView)
            } catch (_: Exception) {}
            floatingBallView = null
        }
    }

    override fun onDestroy() {
        removeFloatingViews()
        super.onDestroy()
    }

    companion object {
        const val PREFS_NAME = "assistive_ball_prefs"
        const val KEY_ENABLED = "enabled"
        const val KEY_NORM_X = "norm_x"
        const val KEY_NORM_Y = "norm_y"

        const val DEFAULT_NORM_X = 1.0f
        const val DEFAULT_NORM_Y = 1.0f

        const val MIN_NORM_X = 0.0f
        const val MAX_NORM_X = 1.0f
        const val MIN_NORM_Y = 0.0f
        const val MAX_NORM_Y = 1.0f
        const val MARGIN_DP = 20

        const val ACTION_START = "com.example.ketion.assistive_ball.START"
        const val ACTION_STOP = "com.example.ketion.assistive_ball.STOP"
        const val ACTION_UPDATE_POS = "com.example.ketion.assistive_ball.UPDATE_POS"
        const val EXTRA_X = "extra_norm_x"
        const val EXTRA_Y = "extra_norm_y"

        fun startService(context: Context, x: Float, y: Float) {
            val intent = Intent(context, AssistiveBallService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_X, x)
                putExtra(EXTRA_Y, y)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stopService(context: Context) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_ENABLED, false)
                .apply()

            val intent = Intent(context, AssistiveBallService::class.java).apply {
                action = ACTION_STOP
            }
            context.startService(intent)
        }

        fun updatePosition(context: Context, x: Float, y: Float) {
            val intent = Intent(context, AssistiveBallService::class.java).apply {
                action = ACTION_UPDATE_POS
                putExtra(EXTRA_X, x)
                putExtra(EXTRA_Y, y)
            }
            context.startService(intent)
        }
    }
}
