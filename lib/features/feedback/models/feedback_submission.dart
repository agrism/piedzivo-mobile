import 'package:equatable/equatable.dart';

enum FeedbackCategory {
  contentIssue('content_issue', 'Satura labojums (laiks, vieta, cena)'),
  bug('bug', 'Darbības kļūda lietotnē'),
  suggestion('suggestion', 'Ieteikums vai ideja'),
  other('other', 'Cits jautājums');

  final String apiValue;
  final String label;

  const FeedbackCategory(this.apiValue, this.label);

  static FeedbackCategory fromApiValue(String val) {
    return FeedbackCategory.values.firstWhere(
      (e) => e.apiValue == val,
      orElse: () => FeedbackCategory.contentIssue,
    );
  }
}

enum FeedbackContextType {
  event('event', 'Pasākums'),
  place('place', 'Vieta'),
  general('general', 'Vispārīgi');

  final String apiValue;
  final String label;

  const FeedbackContextType(this.apiValue, this.label);

  static FeedbackContextType fromApiValue(String val) {
    return FeedbackContextType.values.firstWhere(
      (e) => e.apiValue == val,
      orElse: () => FeedbackContextType.general,
    );
  }
}

class FeedbackSubmission extends Equatable {
  final FeedbackCategory category;
  final FeedbackContextType contextType;
  final String? contextId;
  final String? contextTitle;
  final String message;
  final String? contactEmail;
  final String appVersion;
  final String? deviceInfo;

  const FeedbackSubmission({
    this.category = FeedbackCategory.contentIssue,
    this.contextType = FeedbackContextType.general,
    this.contextId,
    this.contextTitle,
    required this.message,
    this.contactEmail,
    this.appVersion = '1.0.0',
    this.deviceInfo,
  });

  FeedbackSubmission copyWith({
    FeedbackCategory? category,
    FeedbackContextType? contextType,
    String? contextId,
    String? contextTitle,
    String? message,
    String? contactEmail,
    String? appVersion,
    String? deviceInfo,
  }) {
    return FeedbackSubmission(
      category: category ?? this.category,
      contextType: contextType ?? this.contextType,
      contextId: contextId ?? this.contextId,
      contextTitle: contextTitle ?? this.contextTitle,
      message: message ?? this.message,
      contactEmail: contactEmail ?? this.contactEmail,
      appVersion: appVersion ?? this.appVersion,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category.apiValue,
      'context_type': contextType.apiValue,
      if (contextId != null) 'context_id': contextId,
      if (contextTitle != null) 'context_title': contextTitle,
      'message': message,
      if (contactEmail != null && contactEmail!.trim().isNotEmpty)
        'contact_email': contactEmail!.trim(),
      'app_version': appVersion,
      if (deviceInfo != null && deviceInfo!.isNotEmpty)
        'device_info': deviceInfo,
    };
  }

  factory FeedbackSubmission.fromJson(Map<String, dynamic> json) {
    return FeedbackSubmission(
      category: FeedbackCategory.fromApiValue(json['category'] ?? 'content_issue'),
      contextType: FeedbackContextType.fromApiValue(json['context_type'] ?? 'general'),
      contextId: json['context_id'],
      contextTitle: json['context_title'],
      message: json['message'] ?? '',
      contactEmail: json['contact_email'],
      appVersion: json['app_version'] ?? '1.0.0',
      deviceInfo: json['device_info'],
    );
  }

  @override
  List<Object?> get props => [
        category,
        contextType,
        contextId,
        contextTitle,
        message,
        contactEmail,
        appVersion,
        deviceInfo,
      ];
}

