import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({
    required this.authRepository,
    AuthState? initialState,
  }) : super(initialState ?? const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthRequestOtp>(_onAuthRequestOtp);
    on<AuthVerifyOtp>(_onAuthVerifyOtp);
    on<AuthGoogleSignInRequested>(_onAuthGoogleSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthResetState>(_onAuthResetState);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final hasToken = await authRepository.isAuthenticated();
    if (!hasToken) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
      return;
    }

    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onAuthRequestOtp(
    AuthRequestOtp event,
    Emitter<AuthState> emit,
  ) async {
    final email = event.email.trim();
    if (email.isEmpty || !email.contains('@')) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Lūdzu ievadi derīgu e-pasta adresi.',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      await authRepository.requestEmailOtp(email);
      emit(state.copyWith(
        status: AuthStatus.otpSent,
        emailSentTo: email,
        clearError: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAuthVerifyOtp(
    AuthVerifyOtp event,
    Emitter<AuthState> emit,
  ) async {
    final code = event.code.trim();
    if (code.length != 6) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Lūdzu ievadi 6-ciparu kodu.',
      ));
      return;
    }

    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final user = await authRepository.verifyEmailOtp(
        email: event.email,
        code: code,
      );

      if (user != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearEmail: true,
          clearError: true,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Neizdevās saņemt lietotāja datus.',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAuthGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));

    try {
      final user = await authRepository.signInWithGoogle(
        idToken: event.idToken,
        accessToken: event.accessToken,
      );

      if (user != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearError: true,
        ));
      } else {
        // User cancelled Google Sign-In
        emit(state.copyWith(
          status: state.user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
          clearError: true,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await authRepository.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  void _onAuthResetState(
    AuthResetState event,
    Emitter<AuthState> emit,
  ) {
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      clearError: true,
      clearEmail: true,
    ));
  }
}
