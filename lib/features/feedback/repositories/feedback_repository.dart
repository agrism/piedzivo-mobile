import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/feedback_submission.dart';

class FeedbackRepository {
  final ApiClient apiClient;

  FeedbackRepository({required this.apiClient});

  Future<bool> sendFeedback(FeedbackSubmission submission) async {
    try {
      final response = await apiClient.dio.post(
        '/feedback',
        data: submission.toJson(),
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

