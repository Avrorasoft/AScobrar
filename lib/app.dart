import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/user_model.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/collector_dashboard.dart';
import 'screens/shell/desktop_shell.dart';

class LoanCollectorApp extends ConsumerWidget {
  const LoanCollectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'AScobrar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: const AuthGate(),
      routes: {
        '/cobrador': (context) => const _CollectorRouteGate(),
        '/admin': (context) => const _AdminRouteGate(),
      },
    );
  }
}

class _CollectorRouteGate extends ConsumerWidget {
  const _CollectorRouteGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.role != UserRole.collector) {
      return const LoginScreen();
    }
    return const CollectorDashboard();
  }
}

class _AdminRouteGate extends ConsumerWidget {
  const _AdminRouteGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null || user.role != UserRole.owner) {
      return const LoginScreen();
    }
    return const DesktopShell();
  }
}
