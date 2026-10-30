import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../models/app_config.dart';
import '../repositories/app_config_repository.dart';

class SplashScreen extends StatefulWidget {
  final AppConfigRepository repository;
  final void Function(AppConfig config)? onConfigLoaded;

  const SplashScreen({
    super.key,
    required this.repository,
    this.onConfigLoaded,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  AppConfig? _config;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = await widget.repository.getAppConfig();
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _config = config;
      });

      widget.onConfigLoaded?.call(config);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Neizdevās ielādēt konfigurāciju. Pārbaudiet interneta savienojumu.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo un nosaukums
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryViolet,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryViolet.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'P',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.headlineMedium,
                    children: const [
                      TextSpan(text: 'Piedzīvo'),
                      TextSpan(
                        text: '.lv',
                        style: TextStyle(color: AppColors.primaryViolet),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kultūra, pasākumi un vietas',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 48),

                // Ielādes indikators vai kļūdas paziņojums
                if (_isLoading)
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryViolet),
                    ),
                  )
                else if (_errorMessage != null)
                  Column(
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadConfig,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDimensions.buttonBorderRadius,
                          ),
                        ),
                        child: const Text('Mēģināt vēlreiz'),
                      ),
                    ],
                  )
                else if (_config != null && _config!.forceUpdate)
                  Column(
                    children: [
                      Text(
                        'Nepieciešams atjaunināt lietotni uz jaunāko versiju (${_config!.latestVersion}).',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Tiks izsaukts url_launcher nākamajās fāzēs
                        },
                        child: const Text('Atjaunināt'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
