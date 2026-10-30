# Piedzīvo.lv – Detalizēta Tehniskā Specifikācija un Izstrādes Uzdevumi (Model-Ready)

> **Mērķis:** Šis dokuments satur 100% precīzas datu struktūras, Dart modeļus, API pieprasījumus, navigācijas arhitektūru un atomārus soļus, lai pat mazāks / lētāks AI modelis (piem., Gemini Flash, GPT-4o-mini) varētu bez kļūdām un halucinācijām programmēt mobilo aplikāciju soli pa solim.

---

## 1. Projekta Atkarības (`pubspec.yaml`)

Šīs ir fiksētās bibliotēkas un versijas, kuras jāizmanto projektā:

```yaml
name: piedzivo
description: "Piedzīvo.lv mobilā aplikācija kultūrai, pasākumiem un vietām."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.2.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Arhitektūra un Stāvokļa pārvaldība
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # Navigācija (Neatkarīgiem stakiem katrā cilnē)
  go_router: ^14.0.0

  # Tīkls un API
  dio: ^5.4.0
  pretty_dio_logger: ^1.3.1

  # Lokālā krātuve un kešošana
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Attēli un mediji
  cached_network_image: ^3.3.1
  photo_view: ^0.14.0

  # Kartes un ģeolokācija
  flutter_map: ^6.1.0
  latlong2: ^0.9.0

  # Utilītas un sistēma
  url_launcher: ^6.2.4
  intl: ^0.19.0
  google_fonts: ^6.1.0
  sentry_flutter: ^8.0.0

  # Sociālā autentifikācija
  google_sign_in: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  hive_generator: ^2.0.1
  build_runner: ^2.4.8

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

---

## 2. Dizaina Sistēmas Kods (`core/theme/`)

### 2.1. Krāsas (`core/theme/app_colors.dart`)
```dart
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Pamata toņi
  static const Color backgroundLight = Color(0xFFF9FBFC);
  static const Color primaryNavy = Color(0xFF121929);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSecondary = Color(0xFF475569);

  // Akcenta toņi (v4.0)
  static const Color primaryViolet = Color(0xFF7B3AED);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color accentEmerald = Color(0xFF15A34A);
  static const Color accentAmber = Color(0xFFEAB308);
  static const Color accentCoral = Color(0xFFF87271);
  static const Color accentTeal = Color(0xFF2DD4C0);

  // Funkcionālie toņi
  static const Color success = accentEmerald;
  static const Color warning = accentAmber;
  static const Color error = accentCoral;
  static const Color badgeRed = Color(0xFFEF4444);
}
```

### 2.2. Noapaļojumi un Izmēri (`core/theme/app_dimensions.dart`)
```dart
import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  static const double radiusCard = 16.0;
  static const double radiusButton = 12.0;
  static const double radiusBadge = 9999.0;
  static const double radiusImage = 10.0;

  static final BorderRadius cardBorderRadius = BorderRadius.circular(radiusCard);
  static final BorderRadius buttonBorderRadius = BorderRadius.circular(radiusButton);
  static final BorderRadius badgeBorderRadius = BorderRadius.circular(radiusBadge);
}
```

### 2.3. Tēma (`core/theme/app_theme.dart`)
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryViolet,
        secondary: AppColors.accentBlue,
        surface: AppColors.cardWhite,
        background: AppColors.backgroundLight,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.primaryNavy,
        onBackground: AppColors.primaryNavy,
      ),
      cardTheme: CardTheme(
        color: AppColors.cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryViolet,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.buttonBorderRadius,
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryNavy,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryNavy,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryNavy,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryNavy,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

---

## 3. Tīkla Klienta Konfigurācija (`core/network/api_client.dart`)

Katram pieprasījumam obligāti jāiekļauj galvenes un jāapstrādā Sanctum žetons:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static const String baseUrl = 'https://piedzivo.lv/api/v1'; // Vai lokālais dev host
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  ApiClient({required this.secureStorage})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Accept': 'application/json',
              'X-App-Version': '1.0.0',
              'X-App-Platform': 'android',
              'X-App-Locale': 'lv',
            },
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.read(key: 'sanctum_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // 401 Unauthorized gadījumā dzēšam žetonu
          if (error.response?.statusCode == 401) {
            secureStorage.delete(key: 'sanctum_token');
          }
          return handler.next(error);
        },
      ),
    );
  }
}
```

---

## 4. Datu Modeļi un DTO (Data Transfer Objects)

### 4.1. `AppConfig` Modelis (`features/app_config/models/app_config.dart`)
Atbilst `GET /api/v1/app-config`:
```dart
class AppConfig {
  final String minSupportedVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String? androidStoreUrl;
  final String termsVersion;
  final String termsUrl;
  final String privacyUrl;
  final Map<String, String> checksums; // {'taxonomy': '...', 'tags': '...', 'geo_places': '...'}
  final List<ChangelogItem> changelog;

  AppConfig({
    required this.minSupportedVersion,
    required this.latestVersion,
    required this.forceUpdate,
    this.androidStoreUrl,
    required this.termsVersion,
    required this.termsUrl,
    required this.privacyUrl,
    required this.checksums,
    required this.changelog,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final appControl = data['app_control'] as Map<String, dynamic>? ?? {};
    final legal = data['legal'] as Map<String, dynamic>? ?? {};
    final classifications = data['classifications'] as Map<String, dynamic>? ?? {};

    return AppConfig(
      minSupportedVersion: appControl['min_supported_version'] ?? '1.0.0',
      latestVersion: appControl['latest_version'] ?? '1.0.0',
      forceUpdate: appControl['force_update'] ?? false,
      androidStoreUrl: appControl['store_urls']?['android'],
      termsVersion: legal['terms_version'] ?? '1.0',
      termsUrl: legal['terms_url'] ?? 'https://piedzivo.lv/noteikumi',
      privacyUrl: legal['privacy_url'] ?? 'https://piedzivo.lv/privatums',
      checksums: {
        'taxonomy': classifications['taxonomy']?['checksum'] ?? '',
        'tags': classifications['tags']?['checksum'] ?? '',
        'geo_places': classifications['geo_places']?['checksum'] ?? '',
      },
      changelog: (data['changelog'] as List<dynamic>? ?? [])
          .map((item) => ChangelogItem.fromJson(item))
          .toList(),
    );
  }
}

class ChangelogItem {
  final String version;
  final String date;
  final String title;
  final List<String> items;

  ChangelogItem({required this.version, required this.date, required this.title, required this.items});

  factory ChangelogItem.fromJson(Map<String, dynamic> json) {
    return ChangelogItem(
      version: json['version'] ?? '',
      date: json['date'] ?? '',
      title: json['title'] ?? '',
      items: (json['items'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
    );
  }
}
```

### 4.2. `GeoPlace` Modelis (`features/geo/models/geo_place.dart`)
Atbilst `GET /api/v1/geo-places`:
```dart
class GeoPlace {
  final String id;
  final String? parentId;
  final String name;
  final String slug;
  final String type; // 'city', 'municipality', 'region'
  final bool isStateCity;
  final GeoPlaceParent? parent;

  GeoPlace({
    required this.id,
    this.parentId,
    required this.name,
    required this.slug,
    required this.type,
    required this.isStateCity,
    this.parent,
  });

  factory GeoPlace.fromJson(Map<String, dynamic> json) {
    return GeoPlace(
      id: json['id'],
      parentId: json['parent_id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      type: json['type'] ?? 'city',
      isStateCity: json['is_state_city'] ?? false,
      parent: json['parent'] != null ? GeoPlaceParent.fromJson(json['parent']) : null,
    );
  }
}

class GeoPlaceParent {
  final String id;
  final String name;
  final String slug;
  final String type;

  GeoPlaceParent({required this.id, required this.name, required this.slug, required this.type});

  factory GeoPlaceParent.fromJson(Map<String, dynamic> json) {
    return GeoPlaceParent(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      type: json['type'] ?? '',
    );
  }
}
```

### 4.3. `Event` Modeļi (`features/events/models/`)
Atbilst `GET /api/v1/events` un `GET /api/v1/events/{id}`:

```dart
class EventListItem {
  final String id;
  final String? publicId;
  final String slug;
  final String title;
  final String? shortDescription;
  final String? imageUrl;
  final int editorialPriority;
  final int recommendationsCount;
  final bool isNew;
  final bool isRecommendedByMe;
  final bool isFollowedByMe;
  final String? primaryTaxonomyName;
  final String priceLabel;
  final bool isFree;
  final String startsOn; // YYYY-MM-DD
  final String? startsAt; // HH:mm:ss
  final String? placeId;
  final String? placeTitle;
  final String? placeCity;

  EventListItem({
    required this.id,
    this.publicId,
    required this.slug,
    required this.title,
    this.shortDescription,
    this.imageUrl,
    required this.editorialPriority,
    required this.recommendationsCount,
    required this.isNew,
    required this.isRecommendedByMe,
    required this.isFollowedByMe,
    this.primaryTaxonomyName,
    required this.priceLabel,
    required this.isFree,
    required this.startsOn,
    this.startsAt,
    this.placeId,
    this.placeTitle,
    this.placeCity,
  });

  factory EventListItem.fromJson(Map<String, dynamic> json) {
    final priceBadge = json['price_badge'] as Map<String, dynamic>?;
    final occurrence = json['next_occurrence'] as Map<String, dynamic>?;
    final place = json['place'] as Map<String, dynamic>?;

    return EventListItem(
      id: json['id'],
      publicId: json['public_id'],
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      shortDescription: json['short_description'],
      imageUrl: json['image_url'],
      editorialPriority: json['editorial_priority'] ?? 0,
      recommendationsCount: json['recommendations_count'] ?? 0,
      isNew: json['is_new'] ?? false,
      isRecommendedByMe: json['is_recommended_by_me'] ?? false,
      isFollowedByMe: json['is_followed_by_me'] ?? false,
      primaryTaxonomyName: json['primary_taxonomy']?['name'],
      priceLabel: priceBadge?['label'] ?? '',
      isFree: priceBadge?['type'] == 'free',
      startsOn: occurrence?['starts_on'] ?? '',
      startsAt: occurrence?['starts_at'],
      placeId: place?['id'],
      placeTitle: place?['title'],
      placeCity: place?['city'],
    );
  }
}
```

### 4.4. `Place` Modeļi (`features/places/models/`)
Atbilst `GET /api/v1/places` un `GET /api/v1/places/{id}`:

```dart
class PlaceListItem {
  final String id;
  final String? publicId;
  final String slug;
  final String title;
  final String? shortDescription;
  final String city;
  final double? latitude;
  final double? longitude;
  final String? primaryImageUrl;
  final int imagesCount;
  final int editorialPriority;
  final int recommendationsCount;
  final int upcomingEventsCount;
  final bool isNew;
  final bool isRecommendedByMe;
  final bool isFollowedByMe;
  final bool isOpen;
  final String openingLabel;
  final String? rootCategoryName;
  final String? primaryTaxonomyName;

  PlaceListItem({
    required this.id,
    this.publicId,
    required this.slug,
    required this.title,
    this.shortDescription,
    required this.city,
    this.latitude,
    this.longitude,
    this.primaryImageUrl,
    required this.imagesCount,
    required this.editorialPriority,
    required this.recommendationsCount,
    required this.upcomingEventsCount,
    required this.isNew,
    required this.isRecommendedByMe,
    required this.isFollowedByMe,
    required this.isOpen,
    required this.openingLabel,
    this.rootCategoryName,
    this.primaryTaxonomyName,
  });

  factory PlaceListItem.fromJson(Map<String, dynamic> json) {
    final openingStatus = json['opening_status'] as Map<String, dynamic>?;

    return PlaceListItem(
      id: json['id'],
      publicId: json['public_id'],
      slug: json['slug'] ?? '',
      title: json['title'] ?? '',
      shortDescription: json['short_description'],
      city: json['city'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      primaryImageUrl: json['primary_image_url'],
      imagesCount: json['images_count'] ?? 1,
      editorialPriority: json['editorial_priority'] ?? 0,
      recommendationsCount: json['recommendations_count'] ?? 0,
      upcomingEventsCount: json['upcoming_events_count'] ?? 0,
      isNew: json['is_new'] ?? false,
      isRecommendedByMe: json['is_recommended_by_me'] ?? false,
      isFollowedByMe: json['is_followed_by_me'] ?? false,
      isOpen: openingStatus?['is_open'] ?? false,
      openingLabel: openingStatus?['label'] ?? '',
      rootCategoryName: json['root_category']?['name'],
      primaryTaxonomyName: json['primary_taxonomy']?['name'],
    );
  }
}
```

---

## 5. Navigācijas Arhitektūra (`go_router`)

Lai realizētu **specifikācijas 4.1. sadaļas prasību par neatkarīgiem stakiem**, izmanto `StatefulShellRoute.indexedStack`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/events/screens/events_list_screen.dart';
import '../../features/events/screens/event_detail_screen.dart';
import '../../features/places/screens/places_list_screen.dart';
import '../../features/places/screens/place_detail_screen.dart';
import '../../features/places/screens/fullscreen_map_screen.dart';
import '../../features/following/screens/following_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../navigation/main_scaffold.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/events',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // 1. Zars: Pasākumi
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/events',
              builder: (context, state) => const EventsListScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => EventDetailScreen(
                    eventId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. Zars: Vietas
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/places',
              builder: (context, state) => const PlacesListScreen(),
              routes: [
                GoRoute(
                  path: 'map',
                  builder: (context, state) => const FullscreenMapScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => PlaceDetailScreen(
                    placeId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
          ],
        ),

        // 3. Zars: Sekotie
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/following',
              builder: (context, state) => const FollowingScreen(),
            ),
          ],
        ),
      ],
    ),

    // Globālie modālie maršruti
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
  ],
);
```

---

## 6. Soļu Pa Solim Uzdevumi Izstrādei (Prompt Tasks for AI)

Katrs uzdevums ir neatkarīgs un izpildāms ar skaidru rezultātu:

### **Uzdevums 1: Pamata Projekta un Tēmas Inicializācija**
- Izveidot Flutter failu struktūru `lib/core/theme/` ar `app_colors.dart`, `app_dimensions.dart`, `app_theme.dart`.
- Pievienot `GoogleFonts.plusJakartaSans` un fiksēt krāsas atbilstoši Design Tokens v4.0.
- Izveidot `lib/main.dart` un `lib/app.dart`, kas startē aplikāciju ar šo tēmu.
- *Verifikācija:* `flutter analyze` bez kļūdām, `flutter run` parāda gaišu tukšu ekrānu ar krāsu `#F9FBFC`.

### **Uzdevums 2: Tīkla Slānis un Sistēmas Konfigurācija**
- Izveidot `lib/core/network/api_client.dart` ar Dio un Sanctum žetona nolasīšanu.
- Izveidot `AppConfig` modeli un repozitoriju `AppConfigRepository`.
- Izveidot startēšanas Splash/Loading ekrānu, kas izsauc `GET /api/v1/app-config` un saglabā `checksums` SharedPreferences.
- *Verifikācija:* Vienības tests `AppConfig.fromJson` un pareiza galveņu klātbūtne pieprasījumos.

### **Uzdevums 3: Teritoriju (GeoPlaces) Pārvaldība un Lokālais Kešs**
- Izveidot `GeoPlace` modeli.
- Implementēt `GeoRepository`, kas ielādē `/api/v1/geo-places` tikai tad, ja nesakrīt `checksum`.
- Izveidot `GeoCubit` (vai BLoC), kas uztur aktīvo pilsētu un pārslēdzi `isMunicipalityWide` (Variants A).
- *Verifikācija:* Lietotājs var pārslēgt aktīvo pilsētu no saraksta un stāvoklis saglabājas `SharedPreferences`.

### **Uzdevums 4: MainScaffold, GlobalTopBar un BottomNav**
- Izveidot `MainScaffold` ar `StatefulNavigationShell`.
- Implementēt `GlobalTopBar` ar aktīvās pilsētas pogu, slēdzi pilsēta/novads un meklēšanas `[🔍]` ikonu.
- Implementēt `PiedzivoBottomNav` ar 3 cilnēm un sarkanajiem skaitītāju indikatoriem (`1..99`, `99+`).
- *Verifikācija:* Var pārslēgties starp 3 cilnēm un katras cilnes stāvoklis neatiestatās.

### **Uzdevums 5: Pasākumu Saraksts un Dienu Grupēšana**
- Izveidot `EventListItem` modeli un `EventsRepository.getEvents(...)`.
- Izveidot `EventsBloc` (`LoadEvents`, `FilterEvents`).
- Izveidot `EventCard` logrīku ar 64x64 afišu, cenu birku, ieteikumu skaitu un palielināmā stikla zoom pogu.
- Grupēt pasākumus pēc `startsOn` virsrakstiem (*ŠODIEN*, *RĪT*, *DATUMS*).
- *Verifikācija:* Saraksts attēlo reālus datus vai mock datus atbilstoši UX zīmējumam 4.2.

### **Uzdevums 6: Pasākuma Detalizētais Skats**
- Izveidot `EventDetailScreen` ar pilna izmēra afišu, aprakstu, norises vietu, pogām "Iesaku" un "Sekoju".
- Pievienot biļešu iegādes pogu ar `url_launcher`.
- Pievienot pāreju uz saistīto `PlaceDetailScreen`.
- *Verifikācija:* Atpakaļ poga `[ <- ]` atgriež sarakstā tieši tajā pašā skrollēšanas pozīcijā.

### **Uzdevums 7: Vietu Saraksts, Rangs un Darba Laika Statuss**
- Izveidot `PlaceListItem` modeli un `PlacesRepository.getPlaces(...)`.
- Grupēt vietas pa galvenajām kategorijām, kārtojot pēc ranga.
- Rādīt reāllaika statusu `🟢 Atvērts` / `🔴 Slēgts`.
- Pievienot 120px mini-kartes priekšskatījumu saraksta augšgalā ar pogu uz pilnekrāna karti.
- *Verifikācija:* Saraksts atbilst UX zīmējumam 4.3.

### **Uzdevums 8: Pilnekrāna Interaktīvā Karte**
- Izmantojot `flutter_map` un OpenStreetMap flīzes, parādīt vietu adatiņas.
- Nospiežot uz adatiņas, apakšā izslīd kompakta vietas kartīte ar attēlu un darba laiku.
- Poga atvērt detalizēto skatu.

### **Uzdevums 9: Vietas Detalizētais Skats un Ārējā Navigācija**
- Izveidot `PlaceDetailScreen` ar 1..20 fotogrāfiju swipe galeriju un `PhotoView` pilnekrāna skatu.
- Pievienot darba laika izvēršamo grafiku.
- Implementēt navigācijas pogas: `waze://?ll=lat,lng&navigate=yes` un `google.navigation:q=lat,lng`.
- Rādīt līdz 7 gaidāmajiem pasākumiem šajā vietā un pogu *"Skatīt visus pasākumus (N)"*.

### **Uzdevums 10: Globālā Meklēšana**
- Izveidot `SearchScreen` ar ievades lauku un debounce (300 ms).
- Pārslēdzis starp meklēšanu aktīvajā pilsētā un **visā Latvijā**.
- Ja pilsētā ir 0 rezultāti, rādīt alternatīvo pogu *"Rādīt rezultātus visā Latvijā"*.

### **Uzdevums 11: Autentifikācija un Sociālā Mijiedarbība**
- Izveidot `AuthBottomSheet` (Google Sign-In, E-pasta OTP kods).
- Implementēt "Iesaku" (`👍`) un "Sekoju" (`🔔`) ar optimistisku UI un tūlītēju skaitītāja maiņu.
- Ja lietotājs nav ielogojies, atvērt `AuthBottomSheet`.

### **Uzdevums 12: Cilne "Mani Sekotie"**
- Implementēt `FollowingScreen` ar divām apakšcilnēm: *Mani Pasākumi* un *Manas Vietas*.
- Rādīt sarkano birku `[ 🔴 +N jauni! ]` vietām, kurām pievienoti jauni pasākumi.
- Nodzēst birku, kad lietotājs atver vietas lapu.

### **Uzdevums 13: Atsauksmes un Kļūdu Ziņošana**
- Izveidot `FeedbackBottomSheet`, kas izsauc `POST /api/v1/feedback`.
- Automātiski piesaistīt pasākuma vai vietas konteksta ID un nosaukumu.

### **Uzdevums 14: Android Būvējuma Sagatavošana**
- Sagatavot `ic_launcher` adaptīvās ikonas no `Piedzivo.lv_AppIcon.png`.
- Iestatīt `AndroidManifest.xml` atļaujas (`INTERNET`, `ACCESS_COARSE_LOCATION`).
- Pārbaudīt Release būvējumu ar `flutter build apk --release`.

