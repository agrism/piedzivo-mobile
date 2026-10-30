import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

Future<bool?> showAuthBottomSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalContext) => BlocProvider.value(
      value: context.read<AuthBloc>(),
      child: const AuthBottomSheet(),
    ),
  );
}

class AuthBottomSheet extends StatefulWidget {
  const AuthBottomSheet({super.key});

  @override
  State<AuthBottomSheet> createState() => _AuthBottomSheetState();
}

class _AuthBottomSheetState extends State<AuthBottomSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _manualOtpMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _requestOtp() {
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _emailController.text.trim();
    if (email.isNotEmpty) {
      context.read<AuthBloc>().add(AuthRequestOtp(email));
    }
  }

  void _verifyOtp(String email) {
    FocusManager.instance.primaryFocus?.unfocus();
    final code = _otpController.text.trim();
    if (code.isNotEmpty) {
      context.read<AuthBloc>().add(AuthVerifyOtp(email: email, code: code));
    }
  }

  void _signInWithGoogle() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.read<AuthBloc>().add(const AuthGoogleSignInRequested());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final isOtpMode = _manualOtpMode || state.status == AuthStatus.otpSent;
        final currentEmail = state.emailSentTo ?? _emailController.text.trim();

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusCard),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vilkšanas rokturis
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Galvene ar aizvēršanas pogu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryViolet.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.primaryViolet,
                        size: 22,
                      ),
                    ),
                    IconButton(
                      key: const Key('auth_close_button'),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Virsraksts un apraksts
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isOtpMode ? 'Ievadi drošības kodu' : 'Pieslēgties vai reģistrēties',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isOtpMode
                        ? '6-ciparu kods nosūtīts uz $currentEmail'
                        : 'Pieslēdzies, lai ieteiktu pasākumus un sekotu iecienītākajām vietām.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Kļūdas paziņojums
                if (state.errorMessage != null && state.errorMessage!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (!isOtpMode) ...[
                  // 1. Google Sign-In poga
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      key: const Key('auth_google_button'),
                      onPressed: state.status == AuthStatus.loading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.borderSubtle, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        ),
                        backgroundColor: AppColors.cardWhite,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (AppTheme.isTestMode)
                            const Icon(
                              Icons.g_mobiledata_rounded,
                              size: 24,
                              color: Colors.red,
                            )
                          else
                            Image.network(
                              'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                              height: 20,
                              width: 20,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 24,
                                color: Colors.red,
                              ),
                            ),
                          const SizedBox(width: 10),
                          const Text(
                            'Turpināt ar Google',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Atdalītājs
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.borderSubtle)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text(
                          'vai ar e-pastu',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.borderSubtle)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // E-pasta ievades lauks
                  TextField(
                    key: const Key('auth_email_input'),
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: false,
                    showCursor: !AppTheme.isTestMode,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryNavy,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Tavs e-pasts',
                      hintText: 'piem., janis@inbox.lv',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        borderSide: const BorderSide(color: AppColors.primaryViolet, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _requestOtp(),
                  ),
                  const SizedBox(height: 16),

                  // Koda pieprasīšanas poga
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('auth_send_otp_button'),
                      onPressed: state.status == AuthStatus.loading ? null : _requestOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryViolet,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        ),
                        elevation: 0,
                      ),
                      child: state.status == AuthStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Saņemt 6-ciparu kodu',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  // 2. OTP ievades režīms
                  TextField(
                    key: const Key('auth_otp_input'),
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    autofocus: false,
                    showCursor: !AppTheme.isTestMode,
                    style: const TextStyle(
                      fontSize: 24,
                      letterSpacing: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                    ),
                    decoration: InputDecoration(
                      hintText: '123456',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        borderSide: const BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        borderSide: const BorderSide(color: AppColors.primaryViolet, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (_) => _verifyOtp(currentEmail),
                  ),
                  const SizedBox(height: 16),

                  // Apstiprināt kodu poga
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      key: const Key('auth_verify_otp_button'),
                      onPressed: state.status == AuthStatus.loading
                          ? null
                          : () => _verifyOtp(currentEmail),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryViolet,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimensions.radiusButton),
                        ),
                        elevation: 0,
                      ),
                      child: state.status == AuthStatus.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Apstiprināt kodu',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mainīt e-pastu un nosūtīt vēlreiz
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        key: const Key('auth_change_email_button'),
                        onPressed: () {
                          setState(() {
                            _manualOtpMode = false;
                          });
                          context.read<AuthBloc>().add(const AuthResetState());
                        },
                        child: const Text(
                          'Mainīt e-pastu',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const Key('auth_resend_otp_button'),
                        onPressed: () {
                          if (currentEmail.isNotEmpty) {
                            context.read<AuthBloc>().add(AuthRequestOtp(currentEmail));
                          }
                        },
                        child: const Text(
                          'Nosūtīt vēlreiz',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryViolet,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Lietošanas noteikumu atsauce
                const Text(
                  'Turpinot, tu piekrīti Piedzīvo.lv lietošanas noteikumiem un privātuma politikai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
