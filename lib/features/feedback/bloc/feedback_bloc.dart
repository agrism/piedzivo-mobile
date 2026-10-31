import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/feedback_submission.dart';
import '../repositories/feedback_repository.dart';
import 'feedback_event.dart';
import 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final FeedbackRepository repository;

  FeedbackBloc({
    required this.repository,
    FeedbackState? initialState,
  }) : super(initialState ?? const FeedbackState()) {
    on<FeedbackCategoryChanged>(_onCategoryChanged);
    on<FeedbackMessageChanged>(_onMessageChanged);
    on<FeedbackEmailChanged>(_onEmailChanged);
    on<FeedbackSubmitted>(_onSubmitted);
    on<FeedbackReset>(_onReset);
  }

  void _onCategoryChanged(
    FeedbackCategoryChanged event,
    Emitter<FeedbackState> emit,
  ) {
    emit(state.copyWith(
      submission: state.submission.copyWith(category: event.category),
    ));
  }

  void _onMessageChanged(
    FeedbackMessageChanged event,
    Emitter<FeedbackState> emit,
  ) {
    emit(state.copyWith(
      submission: state.submission.copyWith(message: event.message),
      clearError: true,
    ));
  }

  void _onEmailChanged(
    FeedbackEmailChanged event,
    Emitter<FeedbackState> emit,
  ) {
    emit(state.copyWith(
      submission: state.submission.copyWith(contactEmail: event.email),
    ));
  }

  void _onReset(
    FeedbackReset event,
    Emitter<FeedbackState> emit,
  ) {
    emit(FeedbackState(
      status: FeedbackStatus.initial,
      submission: FeedbackSubmission(
        contextType: event.contextType,
        contextId: event.contextId,
        contextTitle: event.contextTitle,
        contactEmail: event.contactEmail,
        message: '',
      ),
    ));
  }

  Future<void> _onSubmitted(
    FeedbackSubmitted event,
    Emitter<FeedbackState> emit,
  ) async {
    if (!state.isFormValid) {
      emit(state.copyWith(
        status: FeedbackStatus.failure,
        errorMessage: 'Lūdzu, ievadiet ziņojuma tekstu!',
      ));
      return;
    }

    emit(state.copyWith(
      status: FeedbackStatus.submitting,
      clearError: true,
    ));

    try {
      final success = await repository.sendFeedback(state.submission);
      if (success) {
        emit(state.copyWith(status: FeedbackStatus.success));
      } else {
        emit(state.copyWith(
          status: FeedbackStatus.failure,
          errorMessage: 'Neizdevās nosūtīt ziņojumu. Lūdzu, mēģiniet vēlreiz.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: FeedbackStatus.failure,
        errorMessage: 'Radās neparedzēta kļūda: $e',
      ));
    }
  }
}

