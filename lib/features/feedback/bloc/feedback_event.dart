import 'package:equatable/equatable.dart';
import '../models/feedback_submission.dart';

abstract class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

class FeedbackCategoryChanged extends FeedbackEvent {
  final FeedbackCategory category;

  const FeedbackCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

class FeedbackMessageChanged extends FeedbackEvent {
  final String message;

  const FeedbackMessageChanged(this.message);

  @override
  List<Object?> get props => [message];
}

class FeedbackEmailChanged extends FeedbackEvent {
  final String email;

  const FeedbackEmailChanged(this.email);

  @override
  List<Object?> get props => [email];
}

class FeedbackSubmitted extends FeedbackEvent {
  const FeedbackSubmitted();
}

class FeedbackReset extends FeedbackEvent {
  final FeedbackContextType contextType;
  final String? contextId;
  final String? contextTitle;
  final String? contactEmail;

  const FeedbackReset({
    this.contextType = FeedbackContextType.general,
    this.contextId,
    this.contextTitle,
    this.contactEmail,
  });

  @override
  List<Object?> get props => [contextType, contextId, contextTitle, contactEmail];
}

