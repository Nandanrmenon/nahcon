import 'package:dynamic_color/dynamic_color.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nahcon/models/jellyfin_item.dart';
import 'package:nahcon/services/jellyfin_service.dart';
import 'package:nahcon/splash.dart';
import 'package:nahcon/theme/app_theme.dart';

import 'screens/app.dart';
import 'screens/login_screen.dart';

void main() {
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'nahCon',
          theme: lightTheme(dynamicScheme: lightDynamic),
          darkTheme: darkTheme(dynamicScheme: darkDynamic),
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          home: FutureBuilder(
            future: Future.wait([
              Future.delayed(const Duration(seconds: 2)),
              JellyfinService().tryAutoLogin(),
              // Preload movies in background if logged in
              JellyfinService()
                  .getAllMovies()
                  .catchError((e) => <JellyfinItem>[]),
            ]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              if (snapshot.hasData && snapshot.data![1] == true) {
                return App(service: JellyfinService());
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
