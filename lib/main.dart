import 'package:flutter/material.dart';
import 'package:flutter/services.dart';   // untuk SystemNavigator
import 'package:provider/provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'providers/optimizer_provider.dart';
import 'providers/settings_store.dart';
import 'providers/log_store.dart';
import 'pages/status_page.dart';
import 'pages/riwayat_page.dart';
import 'pages/pengaturan_page.dart';
import 'widgets/confirm_exit_dialog.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'driver_optimizer_channel',
      channelName: 'Driver Optimizer Service',
      channelDescription: 'Notifikasi untuk monitoring koneksi & GPS',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(30000),
      autoRunOnBoot: true,
      autoRunOnMyPackageReplaced: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );

  final settingsStore = SettingsStore();
  final logStore = LogStore();
  await settingsStore.load();
  await logStore.load();

  final optimizerProvider = OptimizerProvider(
    settingsStore: settingsStore,
    logStore: logStore,
  );
  await optimizerProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: optimizerProvider),
        ChangeNotifierProvider.value(value: settingsStore),
        ChangeNotifierProvider.value(value: logStore),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsStore = context.watch<SettingsStore>();
    ThemeMode themeMode;
    switch (settingsStore.themeMode) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    return MaterialApp(
      title: 'Driver Optimizer',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.accentGreen,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A2E),
          selectedItemColor: AppColors.accentGreen,
          unselectedItemColor: Colors.white70,
        ),
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.accentGreen,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.accentGreen,
          unselectedItemColor: Colors.grey,
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    StatusPage(),
    RiwayatPage(),
    PengaturanPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final provider = context.read<OptimizerProvider>();
        final shouldExit = await ConfirmExitDialog.show(
          context,
          isOptimizerActive: provider.isActive,
        );
        if (shouldExit && mounted) {
          SystemNavigator.pop();   // 👈 benar-benar keluar dari aplikasi
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Status'),
            BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Riwayat'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
          ],
        ),
      ),
    );
  }
}