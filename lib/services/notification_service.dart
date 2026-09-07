import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:bel_sekolah_otomatis/utils/konstanta.dart';

// Notifikasi "Bel berbunyi". Suara bel sendiri diputar via AudioService,
// notifikasi ini hanya penanda visual di status bar.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _siap = false;

  Future<void> init() async {
    if (_siap) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    const channel = AndroidNotificationChannel(
      AppKonstanta.notifChannelId,
      AppKonstanta.notifChannelName,
      description: AppKonstanta.notifChannelDesc,
      importance: Importance.max,
      playSound: false,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    _siap = true;
  }

  Future<void> tampilBel(String nama, String jamLabel) async {
    await init();
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000 % 2147483647;
    const android = AndroidNotificationDetails(
      AppKonstanta.notifChannelId,
      AppKonstanta.notifChannelName,
      channelDescription: AppKonstanta.notifChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
    );
    const detail = NotificationDetails(android: android);
    await _plugin.show(id, 'Bel berbunyi: $nama', 'Pukul $jamLabel', detail);
  }

  /// Versi untuk background isolate (buat instance plugin baru).
  static Future<void> tampilDiBackground(
    String nama,
    String jamLabel,
  ) async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await plugin.initialize(initSettings);
    const android = AndroidNotificationDetails(
      AppKonstanta.notifChannelId,
      AppKonstanta.notifChannelName,
      channelDescription: AppKonstanta.notifChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      enableVibration: true,
    );
    const detail = NotificationDetails(android: android);
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000 % 2147483647;
    await plugin.show(id, 'Bel berbunyi: $nama', 'Pukul $jamLabel', detail);
  }
}
