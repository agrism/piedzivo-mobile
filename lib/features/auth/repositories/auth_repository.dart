import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/api_client.dart';
import '../models/user.dart';

class AuthRepository {
  static const String keyToken = 'sanctum_token';

  final ApiClient apiClient;
  final GoogleSignIn? googleSignIn;

  AuthRepository({
    required this.apiClient,
    this.googleSignIn,
  });

  Future<bool> isAuthenticated() async {
    try {
      final token = await apiClient.secureStorage.read(key: keyToken);
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String?> getToken() async {
    try {
      return await apiClient.secureStorage.read(key: keyToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await apiClient.secureStorage.write(key: keyToken, value: token);
    } catch (_) {}
  }

  Future<void> deleteToken() async {
    try {
      await apiClient.secureStorage.delete(key: keyToken);
    } catch (_) {}
  }

  Future<User?> getCurrentUser() async {
    try {
      final response = await apiClient.dio.get('/me');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final userData = data.containsKey('data') && data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
        return User.fromJson(userData);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> requestEmailOtp(String email) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/otp/request',
        data: {'email': email.trim()},
      );
      return response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204;
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'] ?? e.response?.data['error'];
        if (msg != null) throw Exception(msg.toString());
      }
      rethrow;
    }
  }

  Future<User?> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await apiClient.dio.post(
        '/auth/otp/verify',
        data: {
          'email': email.trim(),
          'code': code.trim(),
        },
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final token = (data['token'] ?? data['data']?['token']) as String?;
      if (token != null && token.isNotEmpty) {
        await saveToken(token);
      }

      final userData = (data['user'] ?? data['data']?['user']) as Map<String, dynamic>?;
      if (userData != null) {
        return User.fromJson(userData);
      }

      return await getCurrentUser();
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'] ?? e.response?.data['error'];
        if (msg != null) throw Exception(msg.toString());
      }
      rethrow;
    }
  }

  Future<User?> signInWithGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    try {
      String? tokenToUse = idToken ?? accessToken;

      if (tokenToUse == null && googleSignIn != null) {
        final account = await googleSignIn!.signIn();
        if (account == null) {
          // User cancelled Google Sign In
          return null;
        }
        final auth = await account.authentication;
        tokenToUse = auth.idToken ?? auth.accessToken;
      }

      if (tokenToUse == null || tokenToUse.isEmpty) {
        throw Exception('Neizdevās iegūt Google autorizācijas žetonu.');
      }

      final response = await apiClient.dio.post(
        '/auth/social',
        data: {
          'provider': 'google',
          'token': tokenToUse,
        },
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};

      final token = (data['token'] ?? data['data']?['token']) as String?;
      if (token != null && token.isNotEmpty) {
        await saveToken(token);
      }

      final userData = (data['user'] ?? data['data']?['user']) as Map<String, dynamic>?;
      if (userData != null) {
        return User.fromJson(userData);
      }

      return await getCurrentUser();
    } catch (e) {
      if (e is DioException && e.response?.data != null) {
        final msg = e.response?.data['message'] ?? e.response?.data['error'];
        if (msg != null) throw Exception(msg.toString());
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await apiClient.dio.post('/auth/logout');
    } catch (_) {
      // Ignore network failures on logout
    } finally {
      await deleteToken();
      try {
        await googleSignIn?.signOut();
      } catch (_) {}
    }
  }
}
