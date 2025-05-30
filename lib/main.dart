import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:nahcon/services/jellyfin_service.dart';
import 'package:nahcon/splash.dart';

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
    return MaterialApp(
      title: 'nahCon',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: Future.wait([
          Future.delayed(const Duration(seconds: 2)),
          JellyfinService().tryAutoLogin(),
          // Preload movies in background if logged in
          JellyfinService().getAllMovies().catchError((_) => []),
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
  }
}
