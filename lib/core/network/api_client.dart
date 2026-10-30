import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://piedzivo.lv/api/v1';
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  ApiClient({
    required this.secureStorage,
    Dio? dioClient,
    String? customBaseUrl,
  }) : dio = dioClient ??
            Dio(
              BaseOptions(
                baseUrl: customBaseUrl ?? baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'Accept': 'application/json',
                  'X-App-Version': '1.0.0',
                  'X-App-Platform': 'android',
                  'X-App-Locale': 'lv',
                },
              ),
            ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.read(key: 'sanctum_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // 401 Unauthorized gadījumā dzēšam žetonu
          if (error.response?.statusCode == 401) {
            await secureStorage.delete(key: 'sanctum_token');
          }
          return handler.next(error);
        },
      ),
    );
  }
}

