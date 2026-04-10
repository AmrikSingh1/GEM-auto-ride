import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'services/hive_service.dart';
import 'services/permission_service.dart';
import 'services/background_service.dart';
import 'services/sync_service.dart';
import 'shared/widgets/gem_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surfaceElevated,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  AndroidGoogleMapsFlutter.useAndroidViewSurface = true;

  await HiveService.init();
  await SyncService.initialize();

  // Configure the background service (does NOT start it yet)
  await BackgroundServiceManager.initialize();

  runApp(
    const ProviderScope(
      child: GemApp(),
    ),
  );
}

class GemApp extends StatefulWidget {
  const GemApp({super.key});

  @override
  State<GemApp> createState() => _GemAppState();
}

class _GemAppState extends State<GemApp> {
  @override
  void initState() {
    super.initState();
    // Request permissions AFTER the first frame so the Android Activity
    // is fully attached — required for Notification, Bluetooth, Background
    // location dialogs to appear.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await PermissionService.requestAll();
      // Start the background FSM service after permissions are settled
      await BackgroundServiceManager.startService();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GEM – Go Extra Mile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const GemShell(),
    );
  }
}
