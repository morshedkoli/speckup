import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../router/app_router.dart';
import '../network/connectivity_service.dart';
import '../sync/sync_queue.dart';
import 'app_theme.dart';
import '../../features/settings/providers/settings_providers.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final connectivity = ref.watch(connectivityServiceProvider);
    // Watch theme mode — falls back to system while loading
    final themeMode = ref.watch(themeModeProvider).asData?.value ?? ThemeMode.system;

    return MaterialApp.router(
      title: 'SpeakUp AI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return StreamBuilder<bool>(
          stream: connectivity.onConnectivityChanged,
          builder: (context, snapshot) {
            if (snapshot.data == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(syncManagerProvider).syncPending();
              });
            }
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
