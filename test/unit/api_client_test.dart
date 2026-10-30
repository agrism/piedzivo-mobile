import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    data.remove(key);
  }
}

class MockAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ApiClient', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiClient.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Accept': 'application/json',
            'X-App-Version': '1.0.0',
            'X-App-Platform': 'android',
            'X-App-Locale': 'lv',
          },
        ),
      );
      dio.httpClientAdapter = mockAdapter;
      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
    });

    test('has expected default headers and base URL', () {
      expect(apiClient.dio.options.baseUrl, 'https://piedzivo.lv/api/v1');
      expect(apiClient.dio.options.headers['Accept'], 'application/json');
      expect(apiClient.dio.options.headers['X-App-Version'], '1.0.0');
      expect(apiClient.dio.options.headers['X-App-Platform'], 'android');
      expect(apiClient.dio.options.headers['X-App-Locale'], 'lv');
    });

    test('injects Authorization header when sanctum_token exists', () async {
      await fakeStorage.write(key: 'sanctum_token', value: 'secret-token-xyz');

      RequestOptions? interceptedOptions;
      mockAdapter.handler = (options) {
        interceptedOptions = options;
        return ResponseBody.fromString(
          jsonEncode({'status': 'ok'}),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      await apiClient.dio.get('/test');

      expect(interceptedOptions, isNotNull);
      expect(
        interceptedOptions!.headers['Authorization'],
        'Bearer secret-token-xyz',
      );
    });

    test('deletes sanctum_token when 401 Unauthorized is returned', () async {
      await fakeStorage.write(key: 'sanctum_token', value: 'expired-token');

      mockAdapter.handler = (options) {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Unauthenticated'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      try {
        await apiClient.dio.get('/protected');
      } on DioException {
        // Expected
      }

      final remainingToken = await fakeStorage.read(key: 'sanctum_token');
      expect(remainingToken, isNull);
    });
  });
}

