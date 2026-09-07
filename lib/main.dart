import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bel_sekolah_otomatis/providers/pengaturan_provider.dart';
import 'package:bel_sekolah_otomatis/screens/dashboard_screen.dart';
import 'package:bel_sekolah_otomatis/screens/jadwal_list_screen.dart';
import 'package:bel_sekolah_otomatis/screens/pengaturan_screen.dart';
import 'package:bel_sekolah_otomatis/services/database_service.dart';
import 'package:bel_sekolah_otomatis/services/notification_service.dart';
import 'package:bel_sekolah_otomatis/services/permission_service.dart';
import 'package:bel_sekolah_otomatis/services/scheduler_service.dart';
import 'package:bel_sekolah_otomatis/utils/konstanta.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  await SchedulerService.init();
  await NotificationService.instance.init();
  await DatabaseService.instance.database;
  runApp(const ProviderScope(child: BelApp()));
}

class BelApp extends StatelessWidget {
  const BelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bel Sekolah Otomatis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(AppKonstanta.navy),
        ),
        scaffoldBackgroundColor: const Color(AppKonstanta.bgAbu),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(AppKonstanta.navy),
          foregroundColor: Colors.white,
        ),
      ),
      home: const MainNav(),
    );
  }
}

class MainNav extends ConsumerStatefulWidget {
  const MainNav({super.key});

  @override
  ConsumerState<MainNav> createState() => _MainNavState();
}

class _MainNavState extends ConsumerState<MainNav> {
  int _index = 0;

  static const _halaman = [
    DashboardScreen(),
    JadwalListScreen(),
    PengaturanScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _siap());
  }

  Future<void> _siap() async {
    // Pastikan alarm terpasang tiap aplikasi dibuka (termasuk setelah boot).
    try {
      await SchedulerService.rescheduleJikaButuh();
      await SchedulerService.rescheduleAll();
    } catch (_) {}
    // Minta izin sekali saat pertama buka.
    try {
      final notifier = ref.read(pengaturanProvider.notifier);
      final sudah = await notifier.izinAwalSudahDiminta();
      if (!sudah && mounted) {
        await _dialogIzin();
        await PermissionService.mintaIzinAwal();
        await notifier.tandaiIzinDiminta();
      }
    } catch (_) {}
  }

  Future<void> _dialogIzin() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('Izin dibutuhkan'),
        content: const Text(
          'Agar bel berbunyi tepat waktu walau HP dikunci, '
          'izinkan Notifikasi, Alarm Tepat Waktu, dan '
          'nonaktifkan optimasi baterai untuk aplikasi ini.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _halaman[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm_outlined),
            selectedIcon: Icon(Icons.alarm),
            label: 'Jadwal',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
