import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/desktop_shell.dart';
import 'screens/shell/collector_shell.dart';
import 'services/data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // En Web, deshabilitamos la persistencia interna de Firestore para evitar
    // el bloqueo exclusivo de pestañas (multi-tab lock). Hive maneja el caché local.
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // 2. Inicializar almacenamiento local (Hive)
  await DataService.init();

  final session = DataService.getCurrentUserSession();
  String initialRoute = '/login';
  if (session != null) {
    initialRoute = session.isOwner ? '/admin' : '/collector';
  }

  runApp(
    ProviderScope(
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = DataService.getCurrentUserSession();
      if (session != null) {
        try {
          ref.read(currentUserProvider.notifier).state = session;
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AScobrar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: widget.initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const DesktopShell(),
        '/collector': (context) => const CollectorShell(),
      },
    );
  }
}
