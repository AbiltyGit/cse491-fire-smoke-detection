import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/fcm_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiService = ApiService();
  final fcmService = FcmService();

  await fcmService.initialize(
    onTokenReady: (token, platform) async {
      await apiService.registerFcmToken(
        fcmToken: token,
        platform: platform,
      );
    },
  );

  runApp(
    PyroGuardApp(
      apiService: apiService,
      fcmService: fcmService,
    ),
  );
}

class PyroGuardApp extends StatelessWidget {
  final ApiService apiService;
  final FcmService fcmService;

  const PyroGuardApp({
    super.key,
    required this.apiService,
    required this.fcmService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PyroGuard — Fire & Smoke Early Warning',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(
        apiService: apiService,
        fcmService: fcmService,
      ),
    );
  }
}
