package com.sekolah.bel.bel_sekolah_otomatis

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

// Dipanggil sistem setelah HP selesai boot.
// Implementasi penuh reschedule ada di Dart (SchedulerService).
// Di sini cukup aman: tidak akses plugin, hanya menandai perlu reschedule
// lewat SharedPreferences agar dibaca saat aplikasi berikutnya dibuka.
// Tahap 3 akan menambahkan pemicu background via WorkManager jika diperlukan.
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences",
                Context.MODE_PRIVATE
            )
            prefs.edit().putBoolean("flutter.butuh_reschedule_boot", true).apply()
        }
    }
}
