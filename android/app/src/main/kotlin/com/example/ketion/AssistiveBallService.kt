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
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
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
                .setContentText("Tap to open Ketion")
                .setSmallIcon(android.R.drawable.ic_menu_edit)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .build()

            startForeground(1002, notification)
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            stopSelf()
            return START_NOT_STICKY
        }

        val action = intent?.action
        if (action == ACTION_STOP) {
            removeFloatingView()
            stopSelf()
            return START_NOT_STICKY
        }

        val normX = intent?.getFloatExtra(EXTRA_X, 0.9f) ?: 0.9f
        val normY = intent?.getFloatExtra(EXTRA_Y, 0.5f) ?: 0.5f

        if (floatingView == null) {
            setupFloatingView(normX, normY)
        } else if (action == ACTION_UPDATE_POS) {
            updateViewPosition(normX, normY)
        }

        return START_STICKY
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun setupFloatingView(initialNormX: Float, initialNormY: Float) {
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val displayMetrics = DisplayMetrics()
        windowManager?.defaultDisplay?.getMetrics(displayMetrics)
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        val ballSizeDp = 52
        val density = resources.displayMetrics.density
        val ballSizePx = (ballSizeDp * density).toInt()

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
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = ((screenWidth - ballSizePx) * initialNormX).toInt()
            y = ((screenHeight - ballSizePx) * initialNormY).toInt()
        }

        val ballView = ImageView(this).apply {
            val shape = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#4B68FF"))
            }
            background = shape
            setImageResource(android.R.drawable.ic_menu_edit)
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
                            // Snap to nearest edge
                            val currentX = layoutParams!!.x
                            val targetX = if (currentX + ballSizePx / 2 < screenWidth / 2) {
                                (16 * density).toInt()
                            } else {
                                screenWidth - ballSizePx - (16 * density).toInt()
                            }
                            layoutParams!!.x = targetX
                            windowManager?.updateViewLayout(floatingView, layoutParams)
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
        val displayMetrics = DisplayMetrics()
        windowManager?.defaultDisplay?.getMetrics(displayMetrics)
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels
        val ballSize = floatingView!!.width.takeIf { it > 0 } ?: (52 * resources.displayMetrics.density).toInt()

        layoutParams!!.x = ((screenWidth - ballSize) * normX).toInt()
        layoutParams!!.y = ((screenHeight - ballSize) * normY).toInt()
        windowManager?.updateViewLayout(floatingView, layoutParams)
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
