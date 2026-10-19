import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/collector_dashboard.dart';
import '../shell/desktop_shell.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const LoginScreen();
    }

    // Administrador: Carga siempre el DesktopShell con la barra lateral izquierda
    if (currentUser.role == UserRole.owner) {
      return const DesktopShell();
    }

    // Cobrador: Entra directo al portal móvil de cobranza
    return const CollectorDashboard();
  }
}
