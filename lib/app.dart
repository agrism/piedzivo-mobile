import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/app_config/repositories/app_config_repository.dart';
import 'features/app_config/screens/splash_screen.dart';

class PiedzivoApp extends StatelessWidget {
  final AppConfigRepository? appConfigRepository;

  const PiedzivoApp({
    super.key,
    this.appConfigRepository,
  });

  @override
  Widget build(BuildContext context) {
    final repository = appConfigRepository ??
        AppConfigRepository(
          apiClient: ApiClient(
            secureStorage: const FlutterSecureStorage(),
          ),
        );

    return MaterialApp(
      title: 'Piedzīvo.lv',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: SplashScreen(repository: repository),
    );
  }
}
