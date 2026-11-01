import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:piedzivo/features/app_config/models/app_config.dart';
import 'package:piedzivo/features/app_config/screens/about_screen.dart';

void main() {
  group('AboutScreen Widget Tests', () {
    final testPackageInfo = PackageInfo(
      appName: 'Piedzīvo.lv',
      packageName: 'lv.piedzivo.app',
      version: '1.0.0',
      buildNumber: '1',
    );

    final testConfig = AppConfig(
      minSupportedVersion: '1.0.0',
      latestVersion: '1.0.0',
      forceUpdate: false,
      termsVersion: '1.0',
      termsUrl: 'https://piedzivo.lv/noteikumi',
      privacyUrl: 'https://piedzivo.lv/privatums',
      checksums: {},
      changelog: [
        ChangelogItem(
          version: '1.0.0',
          date: '2026-11-01',
          title: 'Piedzīvo.lv pirmā versija!',
          items: [
            'Pasākumu un vietu pārlūkošana visās Latvijas pilsētās.',
            'Iespēja piesekot iecienītajām vietām.',
          ],
        ),
      ],
    );

    testWidgets('renders brand, version info, changelog and links correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(
            packageInfo: testPackageInfo,
            initialConfig: testConfig,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Brand
      expect(find.text('Par aplikāciju'), findsOneWidget);
      expect(find.text('Piedzīvo.lv'), findsOneWidget);
      expect(
        find.text('Kultūras notikumi, pasākumi un vietas Latvijā'),
        findsOneWidget,
      );

      // Version
      expect(find.text('Instalētā versija'), findsOneWidget);
      expect(find.text('v1.0.0 (1)'), findsOneWidget);
      expect(find.text('Jaunākā ✓'), findsOneWidget);

      // Changelog
      expect(find.text('Kas jauns'), findsOneWidget);
      expect(find.text('v1.0.0'), findsOneWidget);
      expect(find.text('2026-11-01'), findsOneWidget);
      expect(find.text('Piedzīvo.lv pirmā versija!'), findsOneWidget);
      expect(
        find.text('Pasākumu un vietu pārlūkošana visās Latvijas pilsētās.'),
        findsOneWidget,
      );

      // Links
      expect(find.text('Mājaslapa'), findsOneWidget);
      expect(find.text('Lietošanas noteikumi'), findsOneWidget);
      expect(find.text('Privātuma politika'), findsOneWidget);
      expect(find.text('Atsauksmes vai ieteikumi'), findsOneWidget);
    });

    testWidgets('indicates update available when server version is higher', (
      WidgetTester tester,
    ) async {
      final configWithUpdate = AppConfig(
        minSupportedVersion: '1.0.0',
        latestVersion: '2.0.0',
        forceUpdate: false,
        androidStoreUrl: 'https://play.google.com/store/apps/details?id=lv.piedzivo.app',
        termsVersion: '1.0',
        termsUrl: 'https://piedzivo.lv/noteikumi',
        privacyUrl: 'https://piedzivo.lv/privatums',
        checksums: {},
        changelog: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(
            packageInfo: testPackageInfo,
            initialConfig: configWithUpdate,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pieejams atjauninājums'), findsOneWidget);
      expect(find.text('Jaunākā servera versija'), findsOneWidget);
      expect(find.text('v2.0.0'), findsOneWidget);
      expect(find.text('Atjaunināt'), findsOneWidget);
    });

    testWidgets('handles 0.0.x app version correctly when server returns placeholder 1.0.0', (
      WidgetTester tester,
    ) async {
      final alphaPackageInfo = PackageInfo(
        appName: 'Piedzīvo.lv',
        packageName: 'lv.piedzivo.app',
        version: '0.0.4',
        buildNumber: '11',
      );

      final serverConfigWithPlaceholder = AppConfig(
        minSupportedVersion: '1.0.0',
        latestVersion: '1.0.0',
        forceUpdate: false,
        termsVersion: '1.0',
        termsUrl: 'https://piedzivo.lv/noteikumi',
        privacyUrl: 'https://piedzivo.lv/privatums',
        checksums: {},
        changelog: [
          ChangelogItem(
            version: '1.0.0',
            date: '2026-11-01',
            title: 'Piedzīvo.lv pirmā versija!',
            items: ['Pasākumu un vietu pārlūkošana.'],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AboutScreen(
            packageInfo: alphaPackageInfo,
            initialConfig: serverConfigWithPlaceholder,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Instalētā versija'), findsOneWidget);
      expect(find.text('v0.0.4 (11)'), findsOneWidget);
      expect(find.text('Jaunākā ✓'), findsOneWidget);
      expect(find.text('Pieejams atjauninājums'), findsNothing);
      expect(find.text('Jaunākā servera versija'), findsNothing);
      expect(find.text('v0.0.4'), findsOneWidget);
      expect(find.text('v1.0.0'), findsNothing);
    });
  });
}

