# Piedzīvo.lv Mobilās Aplikācijas Izstrādes Plāns (Flutter / Android)

> **Dokumenta versija:** 1.0  
> **Platforma:** Flutter (sākotnējais fokuss uz **Android**, ar kross-platformu arhitektūru vēlākai iOS aktivizēšanai)  
> **Projekta avoti:** Balstīts uz [`PROJEKTA_SAITES.md`](file:///Users/agrismarkus/code1/piedzivo-mobile/PROJEKTA_SAITES.md) norādīto arhitektūras specifikāciju v1.0, vizuālās identitātes vadlīnijām v4.0 un REST API specifikāciju.  
> **Sīkāka tehniskā specifikācija un prompti AI modeļiem:** [`TEHNISKA_SPECIFIKACIJA_IZSTRADEI.md`](file:///Users/agrismarkus/code1/piedzivo-mobile/TEHNISKA_SPECIFIKACIJA_IZSTRADEI.md) (satur gatavus Dart modeļus, DTO, Dio konfigurāciju, dizaina kodu un 14 atomārus uzdevumus).

---

## 1. Projekta Mērķis un Galvenie Principi

Piedzīvo.lv mobilā aplikācija ir vienota, no informācijas trokšņa un sociālo tīklu algoritmiem brīva kultūras, tūrisma un brīvā laika pavadīšanas platforma Latvijas pilsētām un novadiem.

### Galvenie arhitektūras un UX principi:
1. **"Guest Mode First" pieeja:** Lietotājam ir pieejama visa satura pārlūkošana, meklēšana, filtri un kartes bez reģistrācijas. Autorizācija tiek pieprasīta tikai personīgajām darbībām (*Iesaku*, *Sekoju*, *Mani sekotie*, mājas pilsētas saglabāšana serverī).
2. **"Konteksta Piltuve" (Context Funnel):**
   - **Augšējā josla (Top Bar):** Atbild uz jautājumu **"KUR?"** (Teritorijas izvēle ar mājas pilsētas fiksāciju `🏠`, meklēšana `[🔍]`, profils `[👤]`).
   - **Apakšējā navigācija (Bottom Nav):** Atbild uz jautājumu **"KO ES DARU?"** (3 neatkarīgas cilnes: `📅 Pasākumi`, `📍 Vietas`, `❤️ Sekotie`).
   - **Neatkarīgi ekrānu steki (Navigator Stacks):** Katrai cilnei ir savs neatkarīgs pāreju steks — atgriežoties no pasākuma vai vietas detaļām, lietotājs paliek tieši tajā pašā ritināšanas pozīcijā ar visiem aktīvajiem filtriem.
3. **Offline-first un ātrdarbība:**
   - Klasifikatoru (taksonomijas koks, tagu reģistrs, pārlūkojamās teritorijas `geo_places`) lokālā kešošana ar SHA-256 čeksumu pārbaudi pie startēšanas (`/api/v1/app-config`).
   - Attēlu kešošana ar `cached_network_image` un `?v=<timestamp>` cache-busting atbalstu.
   - Vietējā PostgreSQL meklēšana bez AI/LLM aiztures, nodrošinot reakcijas laiku < 50 ms.

---

## 2. Vizuālā Identitāte un Dizaina Sistēma (Design Tokens v4.0)

Aplikācijas saskarne tiek veidota atbilstoši apstiprinātajām *Piedzīvo.lv* vizuālajām vadlīnijām.

### 2.1. Tipogrāfija
- **Fontu saime:** `Plus Jakarta Sans` (Google Fonts / lokālie asseti).
- **Svari:** Regular (400), Medium (500), SemiBold (600), Bold (700), ExtraBold (800).

### 2.2. Krāsu palete
| Krāsas nosaukums | Hex kods | RGB | Pielietojums |
| :--- | :--- | :--- | :--- |
| **Background Light** | `#F9FBFC` | `249, 251, 252` | Galvenais ekrānu un fona tonis |
| **Deep Navy Text** | `#121929` | `18, 25, 41` | Pamatteksts, tumšie virsraksti, aktīvie elementi |
| **Primary Violet** | `#7B3AED` | `123, 58, 237` | Primārā akcenta krāsa, galvenās pogas, aktīvie indikatori |
| **Royal Blue** | `#2563EB` | `37, 99, 235` | Sekundārie akcenti, saites, info birkas |
| **Emerald Green** | `#15A34A` | `21, 163, 74` | Veiksmes stāvokļi, "🟢 Atvērts" darba laiks, bezmaksas birkas |
| **Amber Gold** | `#EAB308` | `234, 179, 8` | "⭐ Piedzīvo.lv iesaka" prioritātes birkas un zvaigznes |
| **Coral Pink** | `#F87271` | `248, 114, 113` | "✨ JAUNS" birka, "❤️ Sekotie" ikona, kļūdas/slēgts statuss |
| **Teal / Turquoise** | `#2DD4C0` | `45, 212, 192` | Dabas un aktīvās atpūtas kategoriju akcenti |

### 2.3. Noapaļojumi un Ģeometrija (Radius)
- **Kartītes (`Card`):** `16px` noapaļojums, maiga ēna (`box-shadow`), balts fons (`#FFFFFF`) uz fona `#F9FBFC`.
- **Pogas (`Button`):** `12px` noapaļojums.
- **Birkas un Čipi (`Badges / Chips`):** `9999px` (kapsulas forma / Pill).
- **Afišas un Sīkattēli:** `8px` līdz `12px` ar `BoxFit.cover`.
- **Aplikācijas ikona:** P + Star Fusion squircle adaptīvā Android ikona (`res/mipmap-*`).

---

## 3. Tehnoloģiskais Steks (Flutter / Android)

| Komponente | Izvēlētā bibliotēka / Tehnoloģija | Pamatojums |
| :--- | :--- | :--- |
| **Karkass** | `Flutter 3.x` (Dart 3.x) | Stabila kross-platformu vide ar natīvu Android veiktspēju |
| **Stāvokļa pārvaldība** | `flutter_bloc` un `equatable` *(vai Riverpod)* | Prognozējams vienvirziena datu plūsmas modelis, ērta testēšana |
| **Tīkla klients** | `dio` + `pretty_dio_logger` | Pielāgoti interseptori (Sanctum žetons, `X-App-*` galvenes, kļūdas) |
| **Lokālā krātuve** | `flutter_secure_storage` + `shared_preferences` / `hive` | Droša žetonu glabāšana un ātrs bezsaistes klasifikatoru kešs |
| **Attēlu kešošana** | `cached_network_image` | Automātisks diska kešs (LRU), vietturi, kļūdu skati, `?v=` hešošana |
| **Interaktīvā karte** | `flutter_map` (OSM) vai `google_maps_flutter` | Viegls 120px minikartes logs un pilnekrāna vietu karte |
| **Navigācijas saites** | `url_launcher` | Ārējo saišu, telefona zvanu, Waze (`waze://`) un Google Maps atvēršana |
| **Sociālā Auth** | `google_sign_in`, `sign_in_with_apple` | Ātra pieslēgšanās ar Google kontu un Apple ID |
| **Kļūdu telemetrija** | `sentry_flutter` | Reāllaika kļūdu un avāriju fiksēšana produkcijā |

### Pieprasījumu HTTP galvenes (API Headers):
Katrā mobilā klienta izsaukumā automātiski tiek padots:
```http
Accept: application/json
X-App-Version: 1.0.0
X-App-Platform: android
X-App-Locale: lv
Authorization: Bearer <sanctum_token> (ja autorizējies)
```

---

## 4. Ekrānu un UX/UI Funkcionalitātes Tvērums (MVP1)

### 4.1. Globālā Navigācija un Top Bar
- **Top Bar:**
  - Aktīvās teritorijas izvēlne ar meklēšanu un atgriešanās pogu uz mājas pilsētu `🏠`.
  - Teritorijas slēdzis (Variants A): `(• Tikai pilsētā)` $\leftrightarrow$ `( Visā novadā -> )`.
  - Ātrā meklēšana `[🔍]` un Profila/Iestatījumu poga `[👤]`.
- **Bottom Navigation Bar (3 cilnes):**
  - `📅 Pasākumi` – ar jauno pasākumu skaitītāju (`1..99`, `99+` tikai Home teritorijai).
  - `📍 Vietas` – ar jauno vietu skaitītāju (`1..99`, `99+` tikai Home teritorijai).
  - `❤️ Sekotie` – ar neizlasīto jaunumu indikatoriem sekotajām vietām.

### 4.2. Cilne #1: Pasākumi (`EventsListScreen`)
- Hronoloģisks saraksts, kas sagrupēts pa dienām (*ŠODIEN, RĪT, DATUMS*).
- Kompaktas kartītes:
  - `64x64px` afišas sīkattēls ar palielināmā stikla `[🔍]` pārklājumu (uzspiežot atver pilnekrāna zoom).
  - Laiks un kategorija (piem., `19:00 • Koncerts`).
  - Cenas birka (`🎟️ Bezmaksas` vai `🎟️ no 15 €`).
  - Prioritātes birka (`⭐ Piedzīvo`) un jaunuma birka (`✨ JAUNS`).
  - Ieteikumu skaits (`👍 42`) un ātrā sekošanas poga `[+Sek]`.
- Ātro kategoriju čipu josla augšā + poga uz dziļo filtru paneli.

### 4.3. Cilne #2: Vietas un Karte (`PlacesListScreen`)
- Saraksts sagrupēts pa 1. līmeņa kategorijām (*Ēdināšana*, *Apskates objekti*, *Naktsmītnes* u.c.).
- Kārtošana pēc ranga: `editorial_priority` $\rightarrow$ `recommendations_count` $\rightarrow$ `upcoming_events_count`.
- Reāllaika darba laika statuss: `🟢 Atvērts (līdz 22:00)` vai `🔴 Slēgts (atvērsies rīt 10:00)`.
- Galvenais foto (`80x80px`) ar fotogrāfiju skaita birku `[📷 12]`.
- **120px augsts Mini-kartes ieskats** saraksta augšgalā ar pogu `[ ⛶ Atvērt pilnekrāna karti ]`.
- Pilnekrāna interaktīvā karte ar marķieriem un vietas priekšskatījuma apakšējo kartīti uz klikšķa.

### 4.4. Detaļu Ekrāni (Push Stack)
- **Pasākuma detalizētais skats (`EventDetailScreen`):**
  - Pilna afiša ar galerijas atvēršanu, nosaukums, laiks, norises vieta.
  - Poga *"Pirkt biļetes"* vai *"Plašāka informācija"* (ar drošu `url_launcher`).
  - Poga *"Iesaku"* (`👍`) un *"Sekoju"* (`🔔`).
  - Saistītās norises vietas bloks ar pāreju uz Vietas kartīti.
  - Kopīgošanas (`📤`) un kļūdu ziņošanas (`🚩`) iespējas.
- **Vietas detalizētais skats (`PlaceDetailScreen`):**
  - Fotoattēlu galerija ar swipe (1 līdz 20 attēli ar `?v=` hešiem).
  - Darba laiks ar izvēršamu pilno nedēļas grafiku un svētku izņēmumiem.
  - Visi vietas tagi (stāvvieta, ratiņkrēsls, ģimenei, dzīvniekiem, Wi-Fi).
  - **Līdz 7 gaidāmajiem pasākumiem šajā vietā** ar pogu *"Skatīties visus (N) ->"*, kas atver filtrētu pasākumu sarakstu steka virsotnē.
  - Atrašanās vieta kartē un **tiešās pogas:** `[ 🚗 Atvērt Waze ]` un `[ 🗺️ Atvērt Google Maps ]`.
  - Kontakti (zvans uz tālruni, mājaslapa, sociālie tīkli).

### 4.5. Cilne #3: "Mani Sekotie" (`FollowingScreen`)
- Segmentētais slēdzis:
  - **Mani Pasākumi:** Sekoto pasākumu personīgais kalendārs ar afišām, sakārtots hronoloģiski.
  - **Manas Vietas:** Sekoto vietu saraksts ar sarkano neizlasīto jauno pasākumu burbuli `[ 🔴 +N jauni! ]`, kas automātiski nodziest, kad vieta tiek atvērta.

### 4.6. Globālā Meklēšana un Izslīdošie Paneļi (Bottom Sheets)
- **Globālā meklēšana (`SearchScreen`):**
  - Meklēšanas lauks ar tūlītēju rezultātu atlasi.
  - 1 klikšķa pārslēdzis: `(• 📍 Cēsīs)` $\leftrightarrow$ `( 🇱🇻 Visā Latvijā )`.
  - Viedais alternatīvais ieteikums: ja pilsētā nav rezultātu, piedāvā *"Rādīt N rezultātus visā Latvijā"*.
- **Izslīdošie paneļi (Modal Bottom Sheets):**
  1. *Dziļais filtru panelis:* 2. un 3. līmeņa kategoriju koks, cena, pieejamība, auditorija.
  2. *Autorizācijas panelis:* Google konts, Apple ID, E-pasta 6-ciparu OTP kods.
  3. *Atsauksmju / Kļūdu ziņošanas panelis:* Automātiski piesaistīts kontekstam (pasākums/vieta), kategorijas izvēle un komentārs.
  4. *Versiju kontroles logs:* Bloķējošs dialogs, ja `force_update = true`.

---

## 5. Izstrādes Fāzes un Soļu Plāns (Roadmap)

### Fāze 1: Projekta Inicializācija un Bāzes Arhitektūra
- [ ] Izveidot Flutter projektu ar pakotnes identifikatoru `lv.piedzivo.app`.
- [ ] Sakārtot `pubspec.yaml` ar visām pamata atkarībām (`flutter_bloc`, `dio`, `cached_network_image`, `flutter_map`, `shared_preferences`, `flutter_secure_storage`, `url_launcher`, `sentry_flutter`).
- [ ] Izveidot Clean/Feature-first mapju struktūru:
  - `core/` (network, storage, theme, constants, utils)
  - `features/app_config/`
  - `features/events/`
  - `features/places/`
  - `features/following/`
  - `features/search/`
  - `features/auth/`
  - `features/feedback/`
- [ ] Izveidot `AppTheme` ar Design Tokens v4.0 krāsām, `Plus Jakarta Sans` fontu, radiuss 16/12/9999px.
- [ ] Izveidot Dio koka klientu ar Sanctum token un `X-App-*` interseptoriem.

### Fāze 2: Sistēmas Konfigurācija un Lokālā Datu Sinhronizācija
- [ ] Implementēt `AppConfigRepository`:
  - `GET /api/v1/app-config` izsaukums pie aplikācijas ielādes.
  - Pārbaudīt `force_update` un `min_supported_version`.
  - SHA-256 čeksumu salīdzināšana priekš `taxonomy`, `tags`, `geo_places`.
- [ ] Implementēt klasifikatoru bezsaistes glabātuvi (`TaxonomyLocalService`, `GeoPlacesLocalService`).
- [ ] Izveidot mājas pilsētas izvēles un saglabāšanas loģiku lokāli un sinhronizāciju ar serveri.

### Fāze 3: Galvenais Karkass un Globālā Navigācija
- [ ] Izveidot `MainScaffold` ar `IndexedStack` vai `PageView`, lai saglabātu stāvokli starp 3 cilnēm.
- [ ] Implementēt neatkarīgos navigatoru stekus katrai cilnei.
- [ ] Izveidot universālo `GlobalTopBar`:
  - Teritorijas izvēles poga ar modālo pilsētu sarakstu.
  - Pilsēta $\leftrightarrow$ Novads pārslēdzis (Variants A).
  - Meklēšanas un profila pogas.
- [ ] Izveidot `PiedzivoBottomNav` ar skaitītāju indikatoriem (`1..99`, `99+`).

### Fāze 4: Pasākumu Modulis (Cilne "Pasākumi")
- [ ] Pasākumu saraksta BLoC / Repozitorijs (`GET /api/v1/events`).
- [ ] Dienu grupēšanas loģika (*Šodien*, *Rīt*, *Datums*).
- [ ] Kompaktā `EventCard` komponente:
  - 64x64px afišas ielāde ar vietturi un kļūdu apstrādi.
  - Palielināmā stikla ikona un pilnekrāna attēla skatītājs ar zoom.
  - Cenu birkas (`🎟️ Bezmaksas`, `no X €`), `⭐ Piedzīvo`, `✨ JAUNS`.
- [ ] Horizontālā ātro filtru josla.
- [ ] Dziļais filtru Bottom Sheet ar taksonomiju kokiem un tagiem.
- [ ] Pasākuma detalizētās lapas ekrāns (`EventDetailScreen`):
  - Pilns apraksts, laiki, biļešu poga ar `url_launcher`.
  - Pāreja uz norises vietu.

### Fāze 5: Vietu Modulis un Karšu Integrācija (Cilne "Vietas")
- [ ] Vietu saraksta BLoC / Repozitorijs (`GET /api/v1/places`).
- [ ] Grupēšana pa pamatkategorijām un kārtošana pēc ranga.
- [ ] Reāllaika darba laika stāvokļa vizualizācija (`🟢 Atvērts` / `🔴 Slēgts`).
- [ ] 120px augsta minikartes logrīka izveide saraksta galvgalī.
- [ ] Pilnekrāna interaktīvā karte (`FullscreenMapScreen`):
  - Vietu marķieri kartē, atrašanās vietas punkts.
  - Kartītes izlecošais logs uz marķiera pieskāriena.
- [ ] Vietas detalizētā lapa (`PlaceDetailScreen`):
  - Galerija ar horizontālo swipe (1..20 attēli).
  - Waze un Google Maps tiešās navigācijas pogas.
  - Izvēršams darba laika grafiks pa dienām.
  - Pirmie 7 gaidāmie pasākumi ar pogu *"Skatīt visus pasākumus"*, kas atver sarakstu virs steka.

### Fāze 6: Globālā Meklēšana
- [ ] Izveidot `SearchScreen` ar teksta meklēšanas lauku un debounce.
- [ ] Pārslēdzis starp meklēšanu aktīvajā pilsētā un **visā Latvijā**.
- [ ] Rezultātu iedalījums: Pasākumi un Vietas.
- [ ] Gudrais "0 rezultātu" ieteikums ar vienu klikšķi pāriet uz visas Latvijas meklēšanu.

### Fāze 7: Autentifikācija un Sociālā Mijiedarbība
- [ ] Autorizācijas modālais Bottom Sheet:
  - E-pasta OTP pieprasīšana (`/auth/otp/request`) un verifikācija (`/auth/otp/verify`).
  - Google Sign-In integrācija (`/auth/social`).
  - Lietošanas noteikumu versijas apstiprināšana.
- [ ] Token glabāšana `flutter_secure_storage` un lietotāja profila sinhronizācija (`GET /api/v1/me`).
- [ ] "Iesaku" (`👍`) toggle ar optimistisku UI atjaunināšanu (`/recommendations/toggle`).
- [ ] "Sekoju" (`🔔`) toggle ar optimistisku UI atjaunināšanu (`/follows/toggle`).
- [ ] Cilne "Mani Sekotie" (`FollowingScreen`):
  - Sub-tab "Mani Pasākumi" un "Manas Vietas".
  - Neizlasīto jauno pasākumu sarkanā bumba `[ 🔴 +N jauni! ]`.
  - Lasīšanas fiksēšana (`/me/mark-home-viewed` vai atverot vietu).

### Fāze 8: Atsauksmes, Kļūdu Ziņošana un Sistēmas Rīki
- [ ] Atsauksmju un kļūdu ziņošanas Bottom Sheet (`POST /api/v1/feedback`) ar automātisku konteksta (pasākums/vieta) piesaisti.
- [ ] "Kas jauns" (*Changelog*) dialogs vai ekrāns no `app-config`.
- [ ] Sentry telemetrijas inicializācija kļūdu fiksēšanai un lietotāja versiju monitoringam.

### Fāze 9: Android Specifika, Optimizācija un Būvēšana
- [ ] Pievienot Android atļaujas `AndroidManifest.xml` (`INTERNET`, `ACCESS_FINE_LOCATION` ja nepieciešams kartei).
- [ ] Konfigurēt Android adaptīvās ikonas (`mipmap-xxxhdpi`, `ic_launcher`).
- [ ] Splash ekrāns ar balto fonu un P+Star logotipu.
- [ ] Pārbaudīt R8 / ProGuard noteikumus Release būvējumam.
- [ ] Testēšana Android emulatorā un fiziskā ierīcē.
- [ ] Sagatavot Release APK / AAB failus.

---

## 6. Projekta Mapju Struktūra

```
lib/
├── app.dart                       # Galvenais MaterialApp un tēmas piesaiste
├── main.dart                      # Startēšanas punkts, Sentry un DI inicializācija
├── core/
│   ├── config/                    # Vides mainīgie, AppConfig, API URL
│   ├── constants/                 # Krāsu kodi, radiusi, stili (Design Tokens v4.0)
│   ├── network/                   # Dio instance, Sanctum interseptors, kļūdu pārvaldnieks
│   ├── storage/                   # Secure storage, SharedPreferences, Hive kešs
│   ├── theme/                     # ThemeData, Plus Jakarta Sans, krāsu shēmas
│   └── utils/                     # Datumu formatēšana, URL atvērējs, koordinātas
├── features/
│   ├── app_config/                # Versiju kontrole, force update, klasifikatoru sinhronizācija
│   ├── auth/                      # OTP, Google auth, profils, noteikumu apstiprināšana
│   ├── events/                    # Pasākumu saraksts, dienu grupēšana, 64x64 afišas, detaļas
│   ├── places/                    # Vietu saraksts, ranga kārtošana, darba laiki, 1..20 galerija
│   ├── map/                       # 120px minikarte un pilnekrāna karte ar marķieriem
│   ├── following/                 # Cilne "Sekotie", jaunumu indikatori, personīgais kalendārs
│   ├── search/                    # Globālā meklēšana, pilsēta vs visa Latvija
│   └── feedback/                  # Atsauksmju un kļūdu ziņošanas modālais logs
└── shared/
    ├── widgets/                   # Pogas, birkas (Badges), ievades lauki, attēlu vietturi
    └── navigation/                # BottomNav, GlobalTopBar, neatkarīgie ekrānu steki
```

---

## 7. Nākamais Solis un Rīcības Plāns

1. **Flutter projekta inicializācija:** Veikt `flutter create --org lv.piedzivo --platforms android,ios .` darba direktorijā.
2. **Atkarību un dizaina konfigurācija:** Ievietot `pubspec.yaml` nepieciešamās pakotnes un definēt Design Tokens un fontus.
3. **Pirmās fāzes izpilde:** Izveidot tīkla slāni un pieslēgties servera `/api/v1/app-config` un pasākumu galapunktiem.

