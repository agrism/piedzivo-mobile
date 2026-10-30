import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/auth/bloc/auth_bloc.dart';
import 'package:piedzivo/features/auth/bloc/auth_event.dart';
import 'package:piedzivo/features/auth/bloc/auth_state.dart';
import 'package:piedzivo/features/auth/models/user.dart';
import 'package:piedzivo/features/auth/repositories/auth_repository.dart';
import 'api_client_test.dart';

void main() {
  group('Uzdevums 11: AuthBloc & AuthRepository Unit Tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late AuthRepository authRepo;
    late AuthBloc authBloc;

    const mockUser = User(
      id: 'usr-123',
      email: 'test@piedzivo.lv',
      name: 'Jānis Bērziņš',
      avatarUrl: 'https://piedzivo.lv/storage/avatars/janis.jpg',
      termsAcceptedVersion: '1.0',
    );

    setUp(() {
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();

      mockAdapter.handler = (options) {
        final path = options.path;

        if (path == '/me') {
          return ResponseBody.fromString(
            jsonEncode({'data': mockUser.toJson()}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }

        if (path == '/auth/otp/request') {
          final data = options.data as Map<String, dynamic>? ?? {};
          final email = data['email'] as String? ?? '';
          if (email == 'fail@piedzivo.lv') {
            return ResponseBody.fromString(
              jsonEncode({'message': 'Pārāk daudz mēģinājumu'}),
              429,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }
          return ResponseBody.fromString(
            jsonEncode({'status': 'sent'}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }

        if (path == '/auth/otp/verify') {
          final data = options.data as Map<String, dynamic>? ?? {};
          final code = data['code'] as String? ?? '';
          if (code != '123456') {
            return ResponseBody.fromString(
              jsonEncode({'message': 'Nederīgs drošības kods'}),
              422,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }
          return ResponseBody.fromString(
            jsonEncode({
              'token': 'sanctum_token_xyz',
              'user': mockUser.toJson(),
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }

        if (path == '/auth/social') {
          final data = options.data as Map<String, dynamic>? ?? {};
          final token = data['token'] as String? ?? '';
          if (token == 'invalid_token') {
            return ResponseBody.fromString(
              jsonEncode({'message': 'Google autorizācijas kļūda'}),
              401,
              headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
            );
          }
          return ResponseBody.fromString(
            jsonEncode({
              'token': 'sanctum_google_token',
              'user': mockUser.toJson(),
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }

        if (path == '/auth/logout') {
          return ResponseBody.fromString(
            jsonEncode({'status': 'logged_out'}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }

        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      authRepo = AuthRepository(apiClient: apiClient);
      authBloc = AuthBloc(authRepository: authRepo);
    });

    tearDown(() {
      authBloc.close();
    });

    test('initial state has AuthStatus.initial', () {
      expect(authBloc.state, const AuthState(status: AuthStatus.initial));
    });

    test('AuthCheckRequested emits unauthenticated when token is missing', () async {
      authBloc.add(const AuthCheckRequested());
      await expectLater(
        authBloc.stream,
        emits(const AuthState(status: AuthStatus.unauthenticated)),
      );
      expect(authBloc.state.isAuthenticated, isFalse);
    });

    test('AuthCheckRequested emits authenticated when token exists and profile succeeds', () async {
      await fakeStorage.write(key: 'sanctum_token', value: 'token123');

      authBloc.add(const AuthCheckRequested());
      await expectLater(
        authBloc.stream,
        emits(const AuthState(
          status: AuthStatus.authenticated,
          user: mockUser,
        )),
      );
      expect(authBloc.state.isAuthenticated, isTrue);
      expect(authBloc.state.user?.name, 'Jānis Bērziņš');
    });

    test('AuthRequestOtp validates email format', () async {
      authBloc.add(const AuthRequestOtp('invalid_email'));
      await expectLater(
        authBloc.stream,
        emits(const AuthState(
          status: AuthStatus.failure,
          errorMessage: 'Lūdzu ievadi derīgu e-pasta adresi.',
        )),
      );
    });

    test('AuthRequestOtp emits loading then otpSent on valid email', () async {
      authBloc.add(const AuthRequestOtp('test@piedzivo.lv'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthState(status: AuthStatus.loading),
          const AuthState(
            status: AuthStatus.otpSent,
            emailSentTo: 'test@piedzivo.lv',
          ),
        ]),
      );
      expect(authBloc.state.emailSentTo, 'test@piedzivo.lv');
    });

    test('AuthRequestOtp emits failure on backend error', () async {
      authBloc.add(const AuthRequestOtp('fail@piedzivo.lv'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthState(status: AuthStatus.loading),
          const AuthState(
            status: AuthStatus.failure,
            errorMessage: 'Pārāk daudz mēģinājumu',
          ),
        ]),
      );
    });

    test('AuthVerifyOtp validates code length of 6 digits', () async {
      authBloc.add(const AuthVerifyOtp(email: 'test@piedzivo.lv', code: '123'));
      await expectLater(
        authBloc.stream,
        emits(const AuthState(
          status: AuthStatus.failure,
          errorMessage: 'Lūdzu ievadi 6-ciparu kodu.',
        )),
      );
    });

    test('AuthVerifyOtp emits loading then authenticated and saves token on success', () async {
      authBloc.add(const AuthVerifyOtp(email: 'test@piedzivo.lv', code: '123456'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthState(status: AuthStatus.loading),
          const AuthState(
            status: AuthStatus.authenticated,
            user: mockUser,
          ),
        ]),
      );
      expect(await fakeStorage.read(key: 'sanctum_token'), 'sanctum_token_xyz');
    });

    test('AuthGoogleSignInRequested emits loading then authenticated on success', () async {
      authBloc.add(const AuthGoogleSignInRequested(idToken: 'valid_google_token'));
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthState(status: AuthStatus.loading),
          const AuthState(
            status: AuthStatus.authenticated,
            user: mockUser,
          ),
        ]),
      );
      expect(await fakeStorage.read(key: 'sanctum_token'), 'sanctum_google_token');
    });

    test('AuthSignOutRequested deletes token and emits unauthenticated', () async {
      await fakeStorage.write(key: 'sanctum_token', value: 'token_to_delete');

      authBloc.add(const AuthSignOutRequested());
      await expectLater(
        authBloc.stream,
        emitsInOrder([
          const AuthState(status: AuthStatus.loading),
          const AuthState(status: AuthStatus.unauthenticated),
        ]),
      );
      expect(await fakeStorage.read(key: 'sanctum_token'), isNull);
    });
  });
}
