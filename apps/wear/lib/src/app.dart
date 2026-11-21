import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/watch/diagnostics_screen.dart';
import 'features/watch/watch_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const WatchScreen(),
        routes: [
          GoRoute(
            path: 'diagnostics',
            builder: (context, state) => const DiagnosticsScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class WearApp extends ConsumerWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Wear Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF00BFA5),
        brightness: Brightness.dark,
        // Pure black saves power on OLED watch screens.
        scaffoldBackgroundColor: Colors.black,
        visualDensity: VisualDensity.compact,
        useMaterial3: true,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
