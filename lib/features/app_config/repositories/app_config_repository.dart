import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../models/app_config.dart';

class AppConfigRepository {
  final ApiClient apiClient;
  final SharedPreferences? _prefs;

  AppConfigRepository({
    required this.apiClient,
    SharedPreferences? prefs,
  }) : _prefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  Future<AppConfig> getAppConfig() async {
    final response = await apiClient.dio.get('/app-config');
    final config = AppConfig.fromJson(response.data as Map<String, dynamic>);

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

