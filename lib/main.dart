import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaya_desktop/core/routing/router.dart';
import 'package:kaya_desktop/features/account/screens/account_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(500, 550),
    minimumSize: Size(360, 450),
    title: 'Save Button',
    center: true,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: KayaDesktopApp()));
}

class KayaDesktopApp extends ConsumerWidget {
  const KayaDesktopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Save Button',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD700),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFD700),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
      shortcuts: {
        ...WidgetsApp.defaultShortcuts,
        const SingleActivator(LogicalKeyboardKey.keyQ, control: true):
            const _QuitIntent(),
        const SingleActivator(LogicalKeyboardKey.comma, control: true):
            const _PreferencesIntent(),
      },
      actions: {
        ...WidgetsApp.defaultActions,
        _QuitIntent: CallbackAction<_QuitIntent>(
          onInvoke: (_) {
            windowManager.close();
            return null;
          },
        ),
        _PreferencesIntent: CallbackAction<_PreferencesIntent>(
          onInvoke: (_) {
            router.push(AccountScreen.routePath);
            return null;
          },
        ),
      },
    );
  }
}

class _QuitIntent extends Intent {
  const _QuitIntent();
}

class _PreferencesIntent extends Intent {
  const _PreferencesIntent();
}
