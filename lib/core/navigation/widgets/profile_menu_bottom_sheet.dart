import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../features/auth/bloc/auth_bloc.dart';
import '../../../features/auth/bloc/auth_event.dart';
import '../../../features/auth/widgets/auth_bottom_sheet.dart';
import '../../../features/feedback/widgets/feedback_bottom_sheet.dart';
import '../../theme/app_colors.dart';

class ProfileMenuBottomSheet extends StatelessWidget {
  const ProfileMenuBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: const ProfileMenuBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Peldošā josla augšā
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Lietotāja profila sekcija
              if (authState.isAuthenticated && user != null) ...[
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primaryViolet,
                      child: Text(
                        ((user.name != null && user.name!.isNotEmpty)
                                ? user.name![0]
                                : (user.email.isNotEmpty ? user.email[0] : 'P'))
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (user.name != null && user.name!.isNotEmpty)
                            Text(
                              user.name!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryViolet.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primaryViolet,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ienākt profilā',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Sinhronizējiet iecienītās vietas un pasākumus',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        key: const Key('profile_menu_login_button'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          showAuthBottomSheet(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryViolet,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        child: const Text('Ienākt'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const Divider(color: AppColors.borderSubtle),

              // Par aplikāciju poga
              ListTile(
                key: const Key('profile_menu_about_tile'),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryViolet.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: AppColors.primaryViolet, size: 22),
                ),
                title: const Text(
                  'Par aplikāciju',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                ),
                subtitle: const Text(
                  'Versija, jaunumi un informācija',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/about');
                },
              ),

              // Atsauksmes poga
              ListTile(
                key: const Key('profile_menu_feedback_tile'),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryNavy, size: 22),
                ),
                title: const Text(
                  'Atsauksmes vai ieteikumi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                ),
                subtitle: const Text(
                  'Ziņot par kļūdu vai piedāvāt ideju',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.of(context).pop();
                  showFeedbackBottomSheet(context);
                },
              ),

              // Piedzivo.lv vietne
              ListTile(
                key: const Key('profile_menu_website_tile'),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language_rounded, color: AppColors.primaryNavy, size: 22),
                ),
                title: const Text(
                  'Apmeklēt piedzivo.lv',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primaryNavy),
                ),
                trailing: const Icon(Icons.open_in_new_rounded, color: AppColors.textMuted, size: 18),
                contentPadding: EdgeInsets.zero,
                onTap: () async {
                  final uri = Uri.parse('https://piedzivo.lv');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),

              if (authState.isAuthenticated) ...[
                const Divider(color: AppColors.borderSubtle),
                ListTile(
                  key: const Key('profile_menu_logout_tile'),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                  ),
                  title: const Text(
                    'Izrakstīties',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.error),
                  ),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    context.read<AuthBloc>().add(const AuthSignOutRequested());
                    Navigator.of(context).pop();
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
