import 'package:equatable/equatable.dart';
import '../models/user.dart';

enum AuthStatus {
  initial,
  loading,
  otpSent,
  authenticated,
  unauthenticated,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? emailSentTo;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.emailSentTo,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? emailSentTo,
    String? errorMessage,
    bool clearError = false,
    bool clearEmail = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      emailSentTo: clearEmail ? null : (emailSentTo ?? this.emailSentTo),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        emailSentTo,
        errorMessage,
      ];
}
