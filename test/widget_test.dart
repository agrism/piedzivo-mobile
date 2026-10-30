import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/core/theme/app_colors.dart';
import 'package:piedzivo/features/app_config/models/app_config.dart';
import 'package:piedzivo/features/app_config/repositories/app_config_repository.dart';
import 'package:piedzivo/features/app_config/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'unit/api_client_test.dart';

void main() {
  testWidgets('App initializes with PiedzivoApp and shows SplashScreen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final fakeStorage = FakeSecureStorage();
    final mockAdapter = MockAdapter();

    mockAdapter.handler = (options) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'app_control': {
              'min_supported_version': '1.0.0',
              'latest_version': '1.0.0',
              'force_update': false,
            },
            'legal': {
              'terms_version': '1.0',
              'terms_url': 'https://piedzivo.lv/noteikumi',
              'privacy_url': 'https://piedzivo.lv/privatums',
            },
            'classifications': {
              'taxonomy': {'checksum': 'chk1'},
              'tags': {'checksum': 'chk2'},
              'geo_places': {'checksum': 'chk3'},
            },
            'changelog': [],
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    };

    final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
    dio.httpClientAdapter = mockAdapter;

    final repo = AppConfigRepository(
      apiClient: ApiClient(secureStorage: fakeStorage, dioClient: dio),
    );

    AppConfig? loadedConfig;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          repository: repo,
          onConfigLoaded: (config) {
            loadedConfig = config;
          },
        ),
      ),
    );

    // Initial frame shows loading indicator and Piedzīvo branding
    expect(find.text('Kultūra, pasākumi un vietas'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.backgroundLight);

    await tester.pumpAndSettle();

    expect(loadedConfig, isNotNull);
    expect(loadedConfig!.latestVersion, '1.0.0');
    expect(loadedConfig!.checksums['geo_places'], 'chk3');
  });
}
