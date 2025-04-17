// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:solarsim/screens/home_screen.dart';
import 'package:solarsim/screens/project_screen.dart';
import 'package:solarsim/screens/simulation_screen.dart';
import 'package:solarsim/screens/report_screen.dart';
import 'package:solarsim/screens/settings_screen.dart';
import 'package:solarsim/themes/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: SolarSimApp(),
    ),
  );
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/project/:id',
      builder: (context, state) => ProjectScreen(
        projectId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/simulation/:id',
      builder: (context, state) => SimulationScreen(
        simulationId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/report/:id',
      builder: (context, state) => ReportScreen(
        reportId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class SolarSimApp extends StatelessWidget {
  const SolarSimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SolarSim',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
















