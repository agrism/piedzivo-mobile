import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/app_config.dart';

class AppConfigRepository {
  final ApiClient apiClient;
  final SharedPreferences? _prefs;
  AppConfig? _cachedConfig;

  AppConfigRepository({
    required this.apiClient,
    SharedPreferences? prefs,
    AppConfig? initialConfig,
  })  : _prefs = prefs,
        _cachedConfig = initialConfig;

  AppConfig? get currentConfig => _cachedConfig;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<AppConfig> getAppConfig() async {
    final response = await apiClient.dio.get('/app-config');
    final config = AppConfig.fromJson(response.data as Map<String, dynamic>);
    _cachedConfig = config;

    await saveChecksums(config.checksums);
    return config;
  }

  Future<void> saveChecksums(Map<String, String> checksums) async {
    final prefs = await _getPrefs();
    for (final entry in checksums.entries) {
      await prefs.setString('checksum_${entry.key}', entry.value);
    }
  }

  Future<String?> getCachedChecksum(String type) async {
    final prefs = await _getPrefs();
    return prefs.getString('checksum_$type');
  }
}

