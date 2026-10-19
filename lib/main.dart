import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/shell/desktop_shell.dart';
import 'screens/shell/collector_shell.dart';
import 'services/data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DataService.init();

  final session = DataService.getCurrentUserSession();
  String initialRoute = '/login';
  if (session != null) {
    initialRoute = session.isOwner ? '/admin' : '/collector';
  }

  runApp(ProviderScope(child: MyApp(initialRoute: initialRoute)));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AScobrar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const DesktopShell(),
        '/collector': (context) => const CollectorShell(),
      },
    );
  }
}
