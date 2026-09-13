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
    const statusChannel = AndroidNotificationChannel(
      AppKonstanta.notifStatusChannelId,
      AppKonstanta.notifStatusChannelName,
      description: AppKonstanta.notifStatusChannelDesc,
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
      showBadge: false,
    );
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(statusChannel);
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

  /// Notifikasi persisten bergaya media player untuk status latar belakang.
  Future<void> perbaruiNotifikasiStatus({
    required String judul,
    required String pesan,
    String? subteks,
  }) async {
    await init();
    final android = AndroidNotificationDetails(
      AppKonstanta.notifStatusChannelId,
      AppKonstanta.notifStatusChannelName,
      channelDescription: AppKonstanta.notifStatusChannelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      subText: subteks,
      category: AndroidNotificationCategory.transport,
      styleInformation: const MediaStyleInformation(
        htmlFormatContent: false,
        htmlFormatTitle: false,
      ),
    );
    final detail = NotificationDetails(android: android);
    await _plugin.show(
      AppKonstanta.notifStatusId,
      judul,
      pesan,
      detail,
    );
  }

  Future<void> hapusNotifikasiStatus() async {
    await init();
    await _plugin.cancel(AppKonstanta.notifStatusId);
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

  /// Versi status untuk background isolate.
  static Future<void> perbaruiNotifikasiStatusDiBackground({
    required String judul,
    required String pesan,
    String? subteks,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await plugin.initialize(initSettings);
    final android = AndroidNotificationDetails(
      AppKonstanta.notifStatusChannelId,
      AppKonstanta.notifStatusChannelName,
      channelDescription: AppKonstanta.notifStatusChannelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      subText: subteks,
      category: AndroidNotificationCategory.transport,
      styleInformation: const MediaStyleInformation(
        htmlFormatContent: false,
        htmlFormatTitle: false,
      ),
    );
    final detail = NotificationDetails(android: android);
    await plugin.show(
      AppKonstanta.notifStatusId,
      judul,
      pesan,
      detail,
    );
  }

  static Future<void> hapusNotifikasiStatusDiBackground() async {
    final plugin = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await plugin.initialize(initSettings);
    await plugin.cancel(AppKonstanta.notifStatusId);
  }
}
