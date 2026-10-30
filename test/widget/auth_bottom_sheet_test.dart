import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/core/theme/app_theme.dart';
import 'package:piedzivo/features/auth/bloc/auth_bloc.dart';
import 'package:piedzivo/features/auth/bloc/auth_state.dart';
import 'package:piedzivo/features/auth/repositories/auth_repository.dart';
import 'package:piedzivo/features/auth/widgets/auth_bottom_sheet.dart';
import '../unit/api_client_test.dart';

void main() {
  group('Uzdevums 11: AuthBottomSheet Widget Tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late ApiClient apiClient;
    late AuthRepository authRepo;
    late AuthBloc authBloc;

    setUp(() {
      AppTheme.isTestMode = true;
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();

      final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;

      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      authRepo = AuthRepository(apiClient: apiClient);
      authBloc = AuthBloc(authRepository: authRepo);
    });

    tearDown(() {
      authBloc.close();
    });

    Widget createTestApp({Widget? child}) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return child ??
                  ElevatedButton(
                    key: const Key('open_sheet_button'),
                    onPressed: () => showAuthBottomSheet(context),
                    child: const Text('Open Sheet'),
                  );
            },
          ),
        ),
      );
    }

    testWidgets('Renders Google button, email input, send OTP button, terms notice, and close button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: createTestApp(),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      // Assert UI components exist
      expect(find.byKey(const Key('auth_google_button')), findsOneWidget);
      expect(find.text('Turpināt ar Google'), findsOneWidget);
      expect(find.byKey(const Key('auth_email_input')), findsOneWidget);
      expect(find.byKey(const Key('auth_send_otp_button')), findsOneWidget);
      expect(find.text('Saņemt 6-ciparu kodu'), findsOneWidget);
      expect(find.byKey(const Key('auth_close_button')), findsOneWidget);
      expect(find.textContaining('lietošanas noteikumiem'), findsOneWidget);
    });

    testWidgets('Requesting OTP switches to OTP input view with 6-digit input and change email button', (
      WidgetTester tester,
    ) async {
      mockAdapter.handler = (options) {
        if (options.path.contains('/auth/otp/request')) {
          return ResponseBody.fromString(
            jsonEncode({'status': 'ok', 'message': 'OTP nosūtīts'}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: createTestApp(),
        ),
      );

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      // Enter valid email
      await tester.enterText(find.byKey(const Key('auth_email_input')), 'janis@example.com');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Tap send OTP
      await tester.tap(find.byKey(const Key('auth_send_otp_button')));
      await tester.pump();

      await tester.runAsync(() async {
        if (authBloc.state.status != AuthStatus.otpSent) {
          await authBloc.stream.firstWhere((s) => s.status == AuthStatus.otpSent);
        }
      });
      await tester.pumpAndSettle();

      // Assert OTP view is active
      expect(find.byKey(const Key('auth_otp_input')), findsOneWidget);
      expect(find.byKey(const Key('auth_verify_otp_button')), findsOneWidget);
      expect(find.byKey(const Key('auth_change_email_button')), findsOneWidget);
      expect(find.textContaining('janis@example.com'), findsOneWidget);

      // Tap change email button goes back to email input
      await tester.tap(find.byKey(const Key('auth_change_email_button')));
      await tester.pump();
      await tester.runAsync(() async {
        if (authBloc.state.status != AuthStatus.unauthenticated) {
          await authBloc.stream.firstWhere((s) => s.status == AuthStatus.unauthenticated);
        }
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_email_input')), findsOneWidget);
    });

    testWidgets('Entering valid OTP code verifies and dismisses bottom sheet', (
      WidgetTester tester,
    ) async {
      mockAdapter.handler = (options) {
        if (options.path.contains('/auth/otp/request')) {
          return ResponseBody.fromString(
            jsonEncode({'status': 'ok'}),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        if (options.path.contains('/auth/otp/verify')) {
          return ResponseBody.fromString(
            jsonEncode({
              'token': 'sanctum-token-123',
              'user': {
                'id': 'usr-1',
                'email': 'janis@example.com',
                'name': 'Jānis Bērziņš',
              },
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      bool? sheetResult;
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    key: const Key('open_sheet_button'),
                    onPressed: () async {
                      sheetResult = await showAuthBottomSheet(context);
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      // Enter email and request OTP
      await tester.enterText(find.byKey(const Key('auth_email_input')), 'janis@example.com');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.byKey(const Key('auth_send_otp_button')));
      await tester.pump();

      await tester.runAsync(() async {
        if (authBloc.state.status != AuthStatus.otpSent) {
          await authBloc.stream.firstWhere((s) => s.status == AuthStatus.otpSent);
        }
      });
      await tester.pumpAndSettle();

      // Enter 6-digit OTP
      await tester.enterText(find.byKey(const Key('auth_otp_input')), '123456');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Tap verify button
      await tester.tap(find.byKey(const Key('auth_verify_otp_button')));
      await tester.pump();

      await tester.runAsync(() async {
        if (authBloc.state.status != AuthStatus.authenticated) {
          await authBloc.stream.firstWhere((s) => s.status == AuthStatus.authenticated);
        }
      });
      await tester.pumpAndSettle();

      // Bottom sheet is closed and result is true
      expect(find.byType(AuthBottomSheet), findsNothing);
      expect(sheetResult, isTrue);
      expect(authBloc.state.isAuthenticated, isTrue);
      expect(authBloc.state.user?.email, equals('janis@example.com'));
    });

    testWidgets('Error message displays when API returns error', (
      WidgetTester tester,
    ) async {
      mockAdapter.handler = (options) {
        if (options.path.contains('/auth/otp/request')) {
          return ResponseBody.fromString(
            jsonEncode({'message': 'Pārāk daudz pieprasījumu, mēģiniet vēlāk'}),
            429,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: createTestApp(),
        ),
      );

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('auth_email_input')), 'janis@example.com');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.tap(find.byKey(const Key('auth_send_otp_button')));
      await tester.pump();

      await tester.runAsync(() async {
        if (authBloc.state.status != AuthStatus.failure) {
          await authBloc.stream.firstWhere((s) => s.status == AuthStatus.failure);
        }
      });
      await tester.pumpAndSettle();

      expect(find.textContaining('Pārāk daudz pieprasījumu'), findsOneWidget);
    });

    testWidgets('Tapping close button dismisses sheet with false/null', (
      WidgetTester tester,
    ) async {
      bool? sheetResult;
      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    key: const Key('open_sheet_button'),
                    onPressed: () async {
                      sheetResult = await showAuthBottomSheet(context);
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AuthBottomSheet), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_close_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AuthBottomSheet), findsNothing);
      expect(sheetResult, isFalse);
    });
  });
}
