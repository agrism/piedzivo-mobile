import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthRequestOtp extends AuthEvent {
  final String email;

  const AuthRequestOtp(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthVerifyOtp extends AuthEvent {
  final String email;
  final String code;

  const AuthVerifyOtp({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

class AuthGoogleSignInRequested extends AuthEvent {
  final String? idToken;
  final String? accessToken;

  const AuthGoogleSignInRequested({
    this.idToken,
    this.accessToken,
  });

  @override
  List<Object?> get props => [idToken, accessToken];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthResetState extends AuthEvent {
  const AuthResetState();
}
