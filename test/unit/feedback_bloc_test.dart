import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piedzivo/core/network/api_client.dart';
import 'package:piedzivo/features/feedback/bloc/feedback_bloc.dart';
import 'package:piedzivo/features/feedback/bloc/feedback_event.dart';
import 'package:piedzivo/features/feedback/bloc/feedback_state.dart';
import 'package:piedzivo/features/feedback/models/feedback_submission.dart';
import 'package:piedzivo/features/feedback/repositories/feedback_repository.dart';
import 'api_client_test.dart';

void main() {
  group('Uzdevums 13: FeedbackBloc and FeedbackRepository Unit Tests', () {
    late FakeSecureStorage fakeStorage;
    late MockAdapter mockAdapter;
    late Dio dio;
    late ApiClient apiClient;
    late FeedbackRepository repository;
    late FeedbackBloc bloc;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      mockAdapter = MockAdapter();
      dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl));
      dio.httpClientAdapter = mockAdapter;
      apiClient = ApiClient(secureStorage: fakeStorage, dioClient: dio);
      repository = FeedbackRepository(apiClient: apiClient);
      bloc = FeedbackBloc(repository: repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state has default values and form is invalid when message is empty', () {
      expect(bloc.state.status, FeedbackStatus.initial);
      expect(bloc.state.submission.category, FeedbackCategory.contentIssue);
      expect(bloc.state.submission.contextType, FeedbackContextType.general);
      expect(bloc.state.submission.message, isEmpty);
      expect(bloc.state.isFormValid, isFalse);
    });

    test('FeedbackCategoryChanged updates category', () async {
      bloc.add(const FeedbackCategoryChanged(FeedbackCategory.bug));
      await expectLater(
        bloc.stream,
        emits(predicate<FeedbackState>(
          (s) => s.submission.category == FeedbackCategory.bug,
        )),
      );
    });

    test('FeedbackMessageChanged updates message and validates form', () async {
      bloc.add(const FeedbackMessageChanged('Nepareizs darba laiks'));
      await expectLater(
        bloc.stream,
        emits(predicate<FeedbackState>(
          (s) => s.submission.message == 'Nepareizs darba laiks' && s.isFormValid,
        )),
      );
    });

    test('FeedbackEmailChanged updates email', () async {
      bloc.add(const FeedbackEmailChanged('test@example.com'));
      await expectLater(
        bloc.stream,
        emits(predicate<FeedbackState>(
          (s) => s.submission.contactEmail == 'test@example.com',
        )),
      );
    });

    test('FeedbackReset re-initializes submission with context', () async {
      bloc.add(const FeedbackReset(
        contextType: FeedbackContextType.event,
        contextId: 'ev-123',
        contextTitle: 'Rudens koncerts',
        contactEmail: 'user@example.com',
      ));

      await expectLater(
        bloc.stream,
        emits(predicate<FeedbackState>((s) {
          return s.status == FeedbackStatus.initial &&
              s.submission.contextType == FeedbackContextType.event &&
              s.submission.contextId == 'ev-123' &&
              s.submission.contextTitle == 'Rudens koncerts' &&
              s.submission.contactEmail == 'user@example.com' &&
              s.submission.message.isEmpty;
        })),
      );
    });

    test('FeedbackSubmitted with empty message emits failure', () async {
      bloc.add(const FeedbackSubmitted());

      await expectLater(
        bloc.stream,
        emits(predicate<FeedbackState>((s) {
          return s.status == FeedbackStatus.failure &&
              s.errorMessage == 'Lūdzu, ievadiet ziņojuma tekstu!';
        })),
      );
    });

    test('FeedbackSubmitted with valid message calls API and emits success', () async {
      Map<String, dynamic>? receivedBody;

      mockAdapter.handler = (options) {
        if (options.path.contains('/feedback')) {
          receivedBody = options.data is Map<String, dynamic> ? options.data : jsonDecode(options.data.toString());
          return ResponseBody.fromString(
            jsonEncode({'status': 'success', 'message': 'Paldies! Jūsu ziņojums ir saņemts.'}),
            201,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(jsonEncode({'status': 'ok'}), 200);
      };

      bloc.add(const FeedbackReset(
        contextType: FeedbackContextType.place,
        contextId: 'pl-456',
        contextTitle: 'Kafejnīca Cēsis',
        contactEmail: 'info@cesis.lv',
      ));
      bloc.add(const FeedbackMessageChanged('Mainīts tālruņa numurs'));
      bloc.add(const FeedbackSubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<FeedbackState>((s) => s.submission.contextId == 'pl-456'),
          predicate<FeedbackState>((s) => s.submission.message == 'Mainīts tālruņa numurs'),
          predicate<FeedbackState>((s) => s.status == FeedbackStatus.submitting),
          predicate<FeedbackState>((s) => s.status == FeedbackStatus.success),
        ]),
      );

      expect(receivedBody, isNotNull);
      expect(receivedBody!['category'], 'content_issue');
      expect(receivedBody!['context_type'], 'place');
      expect(receivedBody!['context_id'], 'pl-456');
      expect(receivedBody!['context_title'], 'Kafejnīca Cēsis');
      expect(receivedBody!['message'], 'Mainīts tālruņa numurs');
      expect(receivedBody!['contact_email'], 'info@cesis.lv');
      expect(receivedBody!['app_version'], '1.0.0');
    });

    test('FeedbackSubmitted emits failure when repository returns false', () async {
      mockAdapter.handler = (options) {
        return ResponseBody.fromString('Bad Request', 400);
      };

      bloc.add(const FeedbackMessageChanged('Kaut kāda kļūda'));
      bloc.add(const FeedbackSubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<FeedbackState>((s) => s.submission.message == 'Kaut kāda kļūda'),
          predicate<FeedbackState>((s) => s.status == FeedbackStatus.submitting),
          predicate<FeedbackState>((s) => s.status == FeedbackStatus.failure && s.errorMessage != null),
        ]),
      );
    });
  });
}

