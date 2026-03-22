package Quake.Nav

import android.content.Intent
import androidx.core.content.ContextCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class QuakeFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        val level = extractLevel(message)
        if (level != null && level >= 5) {
            val serviceIntent = Intent(this, EmergencyAlertService::class.java).apply {
                action = EmergencyAlertService.ACTION_START
            }
            ContextCompat.startForegroundService(this, serviceIntent)
        } else if (level != null && level in 0..4) {
            val stopIntent = Intent(this, EmergencyAlertService::class.java).apply {
                action = EmergencyAlertService.ACTION_STOP
            }
            startService(stopIntent)
        }
    }

    private fun extractLevel(message: RemoteMessage): Int? {
        val direct = message.data["level"]?.toIntOrNull()
        if (direct != null) return direct

        val text = message.data["intensity"]?.lowercase()?.trim().orEmpty()
        if (text.isEmpty()) return null
        val numberMatch = Regex("(^|\\D)(10|[0-9])(\\D|$)").find(text)
        if (numberMatch != null && numberMatch.groupValues.size >= 3) {
            return numberMatch.groupValues[2].toIntOrNull()
        }
        if (text.contains("system ready")) return 0
        if (text.contains("barely felt")) return 1
        if (text.contains("slightly felt")) return 2
        if (text.contains("weak")) return 3
        if (text.contains("moderate")) return 4
        if (text.contains("fairly strong")) return 5
        if (text == "strong" || text.contains(" strong")) return 6
        if (text.contains("very strong")) return 7
        if (text.contains("destructive")) return 8
        if (text.contains("devastating")) return 9
        if (text.contains("catastrophic")) return 10
        return null
    }
}
