import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaya_desktop/features/account/screens/account_screen.dart';
import 'package:kaya_desktop/features/errors/screens/errors_list_screen.dart';
import 'package:kaya_desktop/features/everything/screens/everything_screen.dart';
import 'package:kaya_desktop/features/everything/screens/preview_screen.dart';
import 'package:kaya_desktop/features/save/screens/save_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: SaveScreen.routePath,
    routes: [
      GoRoute(
        path: SaveScreen.routePath,
        name: SaveScreen.routeName,
        builder: (context, state) => const SaveScreen(),
      ),
      GoRoute(
        path: EverythingScreen.routePath,
        name: EverythingScreen.routeName,
        builder: (context, state) => const EverythingScreen(),
      ),
      GoRoute(
        path: PreviewScreen.routePath,
        name: PreviewScreen.routeName,
        builder: (context, state) {
          final filename = state.pathParameters['filename']!;
          return PreviewScreen(filename: filename);
        },
      ),
      GoRoute(
        path: AccountScreen.routePath,
        name: AccountScreen.routeName,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: ErrorsListScreen.routePath,
        name: ErrorsListScreen.routeName,
        builder: (context, state) => const ErrorsListScreen(),
      ),
    ],
  );
}
