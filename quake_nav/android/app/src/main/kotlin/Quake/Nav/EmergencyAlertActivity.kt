package Quake.Nav

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.MotionEvent
import android.app.Activity
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

class EmergencyAlertActivity : Activity() {
    private var startY = 0f
    private var opened = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#B71C1C"))
        }

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(36, 36, 36, 36)
        }

        val title = TextView(this).apply {
            text = "EARTHQUAKE ALERT"
            setTextColor(Color.WHITE)
            textSize = 30f
            gravity = Gravity.CENTER
        }
        val subtitle = TextView(this).apply {
            text = "Swipe up to open evacuation route"
            setTextColor(Color.parseColor("#DDE1E6"))
            textSize = 16f
            gravity = Gravity.CENTER
        }
        val arrow = TextView(this).apply {
            text = "⇧"
            setTextColor(Color.WHITE)
            textSize = 56f
            gravity = Gravity.CENTER
        }

        content.addView(title)
        content.addView(subtitle)
        content.addView(arrow)
        root.addView(content)
        setContentView(root)

        root.setOnTouchListener { _, event ->
            when (event.actionMasked) {
                MotionEvent.ACTION_DOWN -> {
                    startY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val delta = startY - event.rawY
                    if (delta > 70) {
                        openMain()
                    }
                    true
                }
                MotionEvent.ACTION_UP -> {
                    val delta = startY - event.rawY
                    if (delta > 50) {
                        openMain()
                    }
                    true
                }
                else -> false
            }
        }
    }

    private fun openMain() {
        if (opened) return
        opened = true
        val i = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        startActivity(i)
        finish()
    }
}
