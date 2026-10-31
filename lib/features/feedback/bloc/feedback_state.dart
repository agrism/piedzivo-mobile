import 'package:equatable/equatable.dart';
import '../models/feedback_submission.dart';

enum FeedbackStatus {
  initial,
  submitting,
  success,
  failure,
}

class FeedbackState extends Equatable {
  final FeedbackStatus status;
  final FeedbackSubmission submission;
  final String? errorMessage;

  const FeedbackState({
    this.status = FeedbackStatus.initial,
    this.submission = const FeedbackSubmission(message: ''),
    this.errorMessage,
  });

  bool get isFormValid => submission.message.trim().isNotEmpty;

  FeedbackState copyWith({
    FeedbackStatus? status,
    FeedbackSubmission? submission,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FeedbackState(
      status: status ?? this.status,
      submission: submission ?? this.submission,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, submission, errorMessage];
}

