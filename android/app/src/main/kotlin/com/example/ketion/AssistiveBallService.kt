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
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowInsets
import android.view.WindowManager
import android.widget.ImageView
import kotlin.math.abs

class AssistiveBallService : Service() {

    private var windowManager: WindowManager? = null
    private var floatingView: View? = null
    private var layoutParams: WindowManager.LayoutParams? = null

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

    @SuppressLint("ClickableViewAccessibility")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        if (intent?.action == ACTION_STOP) {
            prefs.edit().putBoolean(KEY_ENABLED, false).apply()
            removeFloatingView()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        // ACTION_START explicitly enables the feature. A null intent means
        // Android is recreating a previously sticky service.
        if (intent?.action == ACTION_START) {
            prefs.edit().putBoolean(KEY_ENABLED, true).apply()
        }

        if (!prefs.getBoolean(KEY_ENABLED, false)) {
            removeFloatingView()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M &&
            !Settings.canDrawOverlays(this)
        ) {
            prefs.edit().putBoolean(KEY_ENABLED, false).apply()
            removeFloatingView()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }

        val savedX = prefs.getFloat(KEY_NORM_X, MAX_POSITION)
        val savedY = prefs.getFloat(KEY_NORM_Y, MIN_POSITION)
        val normX = intent?.getFloatExtra(EXTRA_X, savedX) ?: savedX
        val normY = intent?.getFloatExtra(EXTRA_Y, savedY) ?: savedY

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundServiceNotification()
        }

        val clampedX = normX.coerceIn(MIN_POSITION, MAX_POSITION)
        val clampedY = normY.coerceIn(MIN_POSITION, MAX_POSITION)

        if (floatingView == null) {
            setupFloatingView(clampedX, clampedY)
        } else if (intent?.action == ACTION_UPDATE_POS) {
            updateViewPosition(clampedX, clampedY)
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
        val marginPx = (MARGIN_DP * density).toInt()
        val availableWidth = (usable.width - ballSizePx - 2 * marginPx).coerceAtLeast(1)
        val availableHeight = (usable.height - ballSizePx - 2 * marginPx).coerceAtLeast(1)

        val clampedNormX = normX.coerceIn(MIN_POSITION, MAX_POSITION)
        val clampedNormY = normY.coerceIn(MIN_POSITION, MAX_POSITION)

        val targetX = usable.left + marginPx + (clampedNormX * availableWidth).toInt()
        val targetY = usable.top + marginPx + (clampedNormY * availableHeight).toInt()
        return Pair(targetX, targetY)
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun setupFloatingView(initialNormX: Float, initialNormY: Float) {
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

        layoutParams = WindowManager.LayoutParams(
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
                setColor(Color.parseColor("#4B68FF"))
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
                if (event == null || layoutParams == null) return false

                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = layoutParams!!.x
                        initialY = layoutParams!!.y
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
                        }
                        layoutParams!!.x = initialX + dx.toInt()
                        layoutParams!!.y = initialY + dy.toInt()
                        windowManager?.updateViewLayout(floatingView, layoutParams)
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        if (isClick) {
                            val openIntent = Intent(this@AssistiveBallService, MainActivity::class.java).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                                putExtra("from_assistive_ball", true)
                            }
                            startActivity(openIntent)
                        } else {
                            val currentUsable = getUsableScreenArea()
                            val curDensity = resources.displayMetrics.density
                            val marginPx = (MARGIN_DP * curDensity).toInt()
                            val availableW = (currentUsable.width - ballSizePx - 2 * marginPx).coerceAtLeast(1)
                            val availableH = (currentUsable.height - ballSizePx - 2 * marginPx).coerceAtLeast(1)

                            val currentNormX = ((layoutParams!!.x - currentUsable.left - marginPx).toFloat() / availableW).coerceIn(0f, 1f)
                            val currentNormY = ((layoutParams!!.y - currentUsable.top - marginPx).toFloat() / availableH).coerceIn(0f, 1f)

                            val targetNormX = if (currentNormX < 0.5f) MIN_POSITION else MAX_POSITION
                            val targetNormY = if (currentNormY < 0.5f) MIN_POSITION else MAX_POSITION

                            val (snapX, snapY) = calculatePixelPosition(targetNormX, targetNormY, ballSizePx, currentUsable)
                            layoutParams!!.x = snapX
                            layoutParams!!.y = snapY
                            windowManager?.updateViewLayout(floatingView, layoutParams)

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

        floatingView = ballView
        windowManager?.addView(floatingView, layoutParams)
    }

    private fun updateViewPosition(normX: Float, normY: Float) {
        if (floatingView == null || layoutParams == null || windowManager == null) return
        val ballSize = floatingView!!.width.takeIf { it > 0 } ?: (52 * resources.displayMetrics.density).toInt()
        val usable = getUsableScreenArea()
        val (newX, newY) = calculatePixelPosition(normX, normY, ballSize, usable)

        layoutParams!!.x = newX
        layoutParams!!.y = newY
        windowManager?.updateViewLayout(floatingView, layoutParams)

        val clampedX = normX.coerceIn(MIN_POSITION, MAX_POSITION)
        val clampedY = normY.coerceIn(MIN_POSITION, MAX_POSITION)
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit()
            .putFloat(KEY_NORM_X, clampedX)
            .putFloat(KEY_NORM_Y, clampedY)
            .apply()
    }

    private fun removeFloatingView() {
        if (floatingView != null && windowManager != null) {
            try {
                windowManager?.removeView(floatingView)
            } catch (_: Exception) {}
            floatingView = null
        }
    }

    override fun onDestroy() {
        removeFloatingView()
        super.onDestroy()
    }

    companion object {
        const val PREFS_NAME = "assistive_ball_prefs"
        const val KEY_ENABLED = "enabled"
        const val KEY_NORM_X = "norm_x"
        const val KEY_NORM_Y = "norm_y"

        const val MIN_POSITION = 0.05f
        const val MAX_POSITION = 0.95f
        const val MARGIN_DP = 14

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
