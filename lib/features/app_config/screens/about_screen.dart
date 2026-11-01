import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../feedback/widgets/feedback_bottom_sheet.dart';
import '../models/app_config.dart';
import '../repositories/app_config_repository.dart';

class AboutScreen extends StatefulWidget {
  final PackageInfo? packageInfo;
  final AppConfig? initialConfig;

  const AboutScreen({
    super.key,
    this.packageInfo,
    this.initialConfig,
  });

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late PackageInfo _packageInfo;
  AppConfig? _config;

  @override
  void initState() {
    super.initState();
    _packageInfo = widget.packageInfo ??
        PackageInfo(
          appName: 'Piedzīvo.lv',
          packageName: 'lv.piedzivo.app',
          version: '1.0.0',
          buildNumber: '1',
        );

    _config = widget.initialConfig;

    if (widget.packageInfo == null) {
      _loadPackageInfo();
    }
    _loadConfig();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _packageInfo = info;
        });
      }
    } catch (_) {
      // Fallback to default
    }
  }

  Future<void> _loadConfig() async {
    if (_config != null) return;

    final repo = context.read<AppConfigRepository?>();
    if (repo == null) return;

    if (repo.currentConfig != null) {
      setState(() {
        _config = repo.currentConfig;
      });
      return;
    }

    try {
      final config = await repo.getAppConfig();
      if (mounted) {
        setState(() {
          _config = config;
        });
      }
    } catch (_) {}
  }

  String get _platformName {
    if (kIsWeb) return 'Pārlūks (Web)';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'Cita';
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestServerVersion = _config?.latestVersion;
    final isUpToDate = latestServerVersion == null ||
        _packageInfo.version == latestServerVersion ||
        _packageInfo.version.compareTo(latestServerVersion) >= 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Par aplikāciju',
          style: TextStyle(
            color: AppColors.primaryNavy,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.cardWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        shape: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          children: [
            // 1. Zīmols un logo
            Center(
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: AppColors.primaryViolet,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryViolet.withValues(alpha: 0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/Piedzivo.lv_AppIcon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text(
                          'P',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Piedzīvo.lv',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryNavy,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kultūras notikumi, pasākumi un vietas Latvijā',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 2. Versijas informācijas kartīte
            _buildSectionHeader('Lietotnes informācija'),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppDimensions.cardBorderRadius,
                side: const BorderSide(color: AppColors.borderSubtle, width: 1),
              ),
              color: AppColors.cardWhite,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryViolet.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: AppColors.primaryViolet,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Instalētā versija',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    subtitle: Text(
                      'v${_packageInfo.version} (${_packageInfo.buildNumber})',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUpToDate
                            ? const Color(0xFFE8F8F0)
                            : const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUpToDate
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFF2994A),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isUpToDate ? 'Jaunākā ✓' : 'Pieejams atjauninājums',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isUpToDate
                              ? const Color(0xFF219653)
                              : const Color(0xFFD35400),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 64, endIndent: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.devices_rounded,
                        color: AppColors.primaryNavy,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Platforma',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    subtitle: Text(
                      _platformName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (latestServerVersion != null && !isUpToDate) ...[
                    const Divider(height: 1, indent: 64, endIndent: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2994A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: Color(0xFFF2994A),
                          size: 22,
                        ),
                      ),
                      title: const Text(
                        'Jaunākā servera versija',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      subtitle: Text(
                        'v$latestServerVersion',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: _config?.androidStoreUrl != null
                          ? TextButton(
                              onPressed: () => _launchUrl(_config!.androidStoreUrl!),
                              child: const Text('Atjaunināt'),
                            )
                          : null,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Izmaiņu žurnāls (Changelog)
            if (_config != null && _config!.changelog.isNotEmpty) ...[
              _buildSectionHeader('Kas jauns'),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.cardBorderRadius,
                  side: const BorderSide(color: AppColors.borderSubtle, width: 1),
                ),
                color: AppColors.cardWhite,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final change in _config!.changelog) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryViolet.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'v${change.version}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryViolet,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (change.date.isNotEmpty)
                              Text(
                                change.date,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                        if (change.title.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            change.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        for (final item in change.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '• ',
                                  style: TextStyle(
                                    color: AppColors.primaryViolet,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primaryNavy,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 4. Saites un atbalsts
            _buildSectionHeader('Saites un atbalsts'),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppDimensions.cardBorderRadius,
                side: const BorderSide(color: AppColors.borderSubtle, width: 1),
              ),
              color: AppColors.cardWhite,
              child: Column(
                children: [
                  _buildLinkTile(
                    icon: Icons.language_rounded,
                    title: 'Mājaslapa',
                    subtitle: 'piedzivo.lv',
                    onTap: () => _launchUrl('https://piedzivo.lv'),
                  ),
                  const Divider(height: 1, indent: 64, endIndent: 16),
                  _buildLinkTile(
                    icon: Icons.description_outlined,
                    title: 'Lietošanas noteikumi',
                    onTap: () => _launchUrl(_config?.termsUrl ?? 'https://piedzivo.lv/noteikumi'),
                  ),
                  const Divider(height: 1, indent: 64, endIndent: 16),
                  _buildLinkTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privātuma politika',
                    onTap: () => _launchUrl(_config?.privacyUrl ?? 'https://piedzivo.lv/privatums'),
                  ),
                  const Divider(height: 1, indent: 64, endIndent: 16),
                  _buildLinkTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Atsauksmes vai ieteikumi',
                    subtitle: 'Ziņot par kļūdu vai ieteikt uzlabojumu',
                    onTap: () => showFeedbackBottomSheet(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 5. Kājene
            Center(
              child: Column(
                children: [
                  Text(
                    '© ${DateTime.now().year} Piedzīvo.lv',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Visas tiesības aizsargātas',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryNavy, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryNavy,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textMuted,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
