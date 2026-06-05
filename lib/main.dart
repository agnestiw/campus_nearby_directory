import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'core/app_theme.dart';
import 'core/app_logger.dart';
import 'models/place_model.dart';
// Mengubah import Home menjadi SplashScreen
import 'screens/auth/splash_screen.dart';
import 'screens/map_route_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(details.exceptionAsString());
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>();

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Nearby Directory',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      // Home diganti ke SplashScreen untuk check session
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/map-route') {
          final place = settings.arguments as PlaceModel;
          return MaterialPageRoute(
            builder: (_) => MapRouteScreen(destination: place),
          );
        }
        return null;
      },
    );
  }
}