# Piedzivo.lv – Klasifikatoru un Tagu API Specifikācija (v1)

Šis dokuments apraksta *Piedzivo.lv* notikumu, pasākumu un resursu (objektu un pakalpojumu) taksonomijas un tagu reģistra API arhitektūru, autentifikāciju, versiju vadību un visus pieejamos galapunktus.

---

## 1. Pamatprincipus un bāzes URL

- **Bāzes URL:** `/api/v1` (piem., `https://piedzivo.lv/api/v1` vai lokāli `http://localhost:8000/api/v1`)
- **Datu formāts:** JSON (`application/json`)
- **Rakstzīmju kopa:** UTF-8
- **Identifikatori:** UUID v4
- **Daudzvalodu atbalsts:** `lv` (latviešu), `en` (angļu), `ru` (krievu)

---

## 2. Autentifikācija (Bearer Token)

Visi `/api/v1/*` klasifikācijas galapunkti ir aizsargāti ar pieejas kodu.

### Pieprasījuma galvenes
Pieprasījumam obligāti jāpievieno viena no šādām galvenēm:

```http
Authorization: Bearer <API_PIEKĻUVES_KODS>
```
*vai alternatīvi:*
```http
X-API-KEY: <API_PIEKĻUVES_KODS>
```

### Konfigurācija serverī (`.env`)
Piekļuves kods tiek iestatīts vides konfigurācijas failā `.env`:
```env
CLASSIFICATION_API_TOKEN="piedzivo_sec_a7f92b48e1c39045b6d192f4e0c81729"
```

### Kļūdas atbilde (401 Unauthorized)
Ja pieprasījums tiek veikts bez koda vai ar nederīgu kodu:

```json
{
  "status": "error",
  "message": "Unauthorized: Invalid or missing Bearer token."
}
```

---

## 3. Versiju vadība un kešatmiņa (Cache-Busting)

Lai minimizētu tīkla slodzi un nodrošinātu ātru darbību mobilajās lietotnēs un front-endā, API uztur monotoni pieaugošu versijas numuru un SHA-256 stāvokļa kontrolsummu (`checksum`).

### Kā integrēt klientā:
1. Klients startējot vai fonā izsauc vieglo versijas galapunktu:
   `GET /api/v1/classifications/version`
2. Klients salīdzina saņemto `version` vai `checksum` ar lokālajā kešatmiņā (`localStorage`, SQLite) saglabāto vērtību.
3. Ja versija nav mainījusies, pilnais datu koks netiek atkārtoti ielādēts.
4. Pieprasot pilnos datus, klients var nodot HTTP galveni `If-None-Match: "<checksum>"`. Ja dati nav mainījušies, serveris atgriež **`304 Not Modified`** bez satura ķermeņa.

---

## 4. API Galapunkti

### 4.1. Abu klasifikatoru versijas
Izgūst gan taksonomijas koka, gan tagu aktuālās versijas un hešus.

- **Metode:** `GET`
- **Ceļš:** `/api/v1/classifications/version`

#### cURL piemērs:
```bash
curl -X GET "http://localhost:8000/api/v1/classifications/version" \
  -H "Authorization: Bearer piedzivo_sec_a7f92b48e1c39045b6d192f4e0c81729" \
  -H "Accept: application/json"
```

#### Atbilde (`200 OK`):
```json
{
  "status": "success",
  "data": {
    "taxonomy": {
      "version": 1,
      "checksum": "fbb8df582b130dbb6be0079ca91c499ea8fe4459f979727ee2ecaa7eaeece379",
      "updated_at": "2026-10-09T13:43:55.000000Z"
    },
    "tags": {
      "version": 1,
      "checksum": "c138fd947d793037a0760186574b0282f2f435e70d73a40237237cb4456ea3be",
      "updated_at": "2026-10-09T13:43:55.000000Z"
    }
  }
}
```

---

### 4.2. Tikai taksonomijas versija
- **Metode:** `GET`
- **Ceļš:** `/api/v1/taxonomies/version`

#### Atbilde (`200 OK`):
```json
{
  "status": "success",
  "data": {
    "scope": "taxonomy",
    "version": 1,
    "checksum": "fbb8df582b130dbb6be0079ca91c499ea8fe4459f979727ee2ecaa7eaeece379",
    "updated_at": "2026-10-09T13:43:55.000000Z"
  }
}
```

---

### 4.3. Taksonomijas koka vai saraksta izgūšana
Atgriež 3 līmeņu klasifikatoru:
- **Kategorija** (`category`, 1. līmenis, `parent_id: null`)
- **Apakškategorija** (`subcategory`, 2. līmenis)
- **Tips** (`type`, 3. līmenis)

- **Metode:** `GET`
- **Ceļš:** `/api/v1/taxonomies`

#### Vaicājuma parametri (Query Parameters):
| Parametrs | Tips | Noklusējums | Apraksts |
| :--- | :--- | :--- | :--- |
| `locale` | `string` | *(visi)* | Valoda nosaukumiem (`lv`, `en`, `ru`). Ja nav norādīts, atgriež visus pieejamos tulkojumus masīvā. |
| `format` | `string` | `tree` | Datu struktūra: `tree` (hierarhisks koks ar `children`) vai `flat` (plakans saraksts ar `parent_id`). |
| `root` | `string` | *(visi)* | Konkrētas virskategorijas slug filtrs (piemēram, `root=pasakumi` vai `root=apskates-objekti-un-kultura`). |

#### cURL piemērs:
```bash
curl -X GET "http://localhost:8000/api/v1/taxonomies?locale=lv" \
  -H "Authorization: Bearer piedzivo_sec_a7f92b48e1c39045b6d192f4e0c81729" \
  -H "Accept: application/json"
```

#### Atbilde ar `locale=lv` (`200 OK`):
```json
{
  "status": "success",
  "version": 1,
  "checksum": "fbb8df582b130dbb6be0079ca91c499ea8fe4459f979727ee2ecaa7eaeece379",
  "locale": "lv",
  "data": [
    {
      "id": "1e7cb821-2f3b-48ae-b51c-6a1ec1bfa120",
      "parent_id": null,
      "level": "category",
      "slug": "pasakumi",
      "sort_order": 20,
      "icon": null,
      "name": "Pasākumi",
      "children": [
        {
          "id": "8bbce2c0-8d59-4b1f-aeec-cba85a66a7b1",
          "parent_id": "1e7cb821-2f3b-48ae-b51c-6a1ec1bfa120",
          "level": "subcategory",
          "slug": "muzika-un-koncerti",
          "sort_order": 80,
          "icon": null,
          "name": "Mūzika un koncerti",
          "children": [
            {
              "id": "a9c394c8-47bc-4ee7-91fb-eeb2b9442a8b",
              "parent_id": "8bbce2c0-8d59-4b1f-aeec-cba85a66a7b1",
              "level": "type",
              "slug": "koncerts",
              "sort_order": 190,
              "icon": null,
              "name": "Koncerts"
            },
            {
              "id": "675cb2fa-c967-4e78-9e19-94ea4fc69412",
              "parent_id": "8bbce2c0-8d59-4b1f-aeec-cba85a66a7b1",
              "level": "type",
              "slug": "muzikas-pasakums",
              "sort_order": 200,
              "icon": null,
              "name": "Mūzikas pasākums"
            }
          ]
        }
      ]
    }
  ]
}
```

#### Atbilde bez `locale` parametra (visi tulkojumi):
```json
{
  "id": "1e7cb821-2f3b-48ae-b51c-6a1ec1bfa120",
  "parent_id": null,
  "level": "category",
  "slug": "pasakumi",
  "translations": {
    "lv": { "name": "Pasākumi", "description": null },
    "en": { "name": "Events", "description": null },
    "ru": { "name": "Мероприятия", "description": null }
  }
}
```

---

### 4.4. Tikai tagu versija
- **Metode:** `GET`
- **Ceļš:** `/api/v1/tags/version`

#### Atbilde (`200 OK`):
```json
{
  "status": "success",
  "data": {
    "scope": "tags",
    "version": 1,
    "checksum": "c138fd947d793037a0760186574b0282f2f435e70d73a40237237cb4456ea3be",
    "updated_at": "2026-10-09T13:43:55.000000Z"
  }
}
```

---

### 4.5. Tagu reģistra izgūšana
Atgriež vienotu tagu sarakstu ar nosaukumiem, grupām un meklēšanas sinonīmiem (`aliases`).

- **Metode:** `GET`
- **Ceļš:** `/api/v1/tags`

#### Vaicājuma parametri (Query Parameters):
| Parametrs | Tips | Noklusējums | Apraksts |
| :--- | :--- | :--- | :--- |
| `locale` | `string` | *(visi)* | Valoda nosaukumiem un sinonīmiem (`lv`, `en`, `ru`). |
| `group` | `string` | *(visi)* | Grupas filtrs: `audience`, `price`, `accessibility`, `features`. |

#### cURL piemērs:
```bash
curl -X GET "http://localhost:8000/api/v1/tags?locale=lv" \
  -H "Authorization: Bearer piedzivo_sec_a7f92b48e1c39045b6d192f4e0c81729" \
  -H "Accept: application/json"
```

#### Atbilde ar `locale=lv` (`200 OK`):
```json
{
  "status": "success",
  "version": 1,
  "checksum": "c138fd947d793037a0760186574b0282f2f435e70d73a40237237cb4456ea3be",
  "locale": "lv",
  "data": [
    {
      "id": "e818b456-11f4-4a25-90ae-2cf1cb5eb042",
      "slug": "autostavvieta",
      "tag_group": "features",
      "name": "Autostāvvieta",
      "aliases": [
        "stāvvieta",
        "parkings",
        "bezmaksas stāvvieta"
      ]
    },
    {
      "id": "18f97b0a-f0ca-429d-9a67-ee5bf7b24ca1",
      "slug": "bezmaksas",
      "tag_group": "price",
      "name": "Bezmaksas ieeja",
      "aliases": [
        "bez maksas",
        "brīvbiļetes",
        "brīva ieeja"
      ]
    },
    {
      "id": "4261ca65-5b8d-4f1b-a590-b2ccb00b467a",
      "slug": "draugs-dzivniekiem",
      "tag_group": "features",
      "name": "Draudzīgs mājdzīvniekiem",
      "aliases": [
        "ar suņiem",
        "suņiem draudzīgs",
        "dzīvniekiem atļauts"
      ]
    },
    {
      "id": "f0312bd9-1b39-445a-8b8a-93e1858a7413",
      "slug": "gimenem-draudzigs",
      "tag_group": "audience",
      "name": "Ģimenei ar bērniem",
      "aliases": [
        "ar bērniem",
        "bērnu pasākumi",
        "ģimenēm",
        "bērniem"
      ]
    },
    {
      "id": "8b941ce0-6ea2-475a-a6aa-098555baec61",
      "slug": "pieejams-ratinkreslos",
      "tag_group": "accessibility",
      "name": "Pieejams ratiņkrēslos",
      "aliases": [
        "vides pieejamība",
        "invalīdu ratiņi",
        "pieejams personām ar kustību traucējumiem"
      ]
    },
    {
      "id": "782ca7f1-827c-4861-8ff8-e1c55ccbfa55",
      "slug": "wi-fi",
      "tag_group": "features",
      "name": "Bezvadu internets (Wi-Fi)",
      "aliases": [
        "wifi",
        "wi-fi",
        "internets",
        "bezmaksas wifi"
      ]
    }
  ]
}
```

---

## 5. Datu sasaiste ar Pasākumiem un Resursiem

Datu bāzē un Eloquent modeļos ir pieejamas šādas saites:

### Pasākumi (`Event` modelis)
- `$event->taxonomies` – visi pasākumam piesaistītie klasifikācijas mezgli (Kategorijas, Apakškategorijas vai Tipi).
- `$event->primaryTaxonomy()` – pasākuma galvenais klasifikācijas mezgls (nodrošināts ar DB ierobežojumu `is_primary = true`).
- `$event->tags` – visi pasākuma tagi.

### Objekti / Pakalpojumi (`Place` modelis)
- `$place->taxonomies` – objekta/pakalpojuma taksonomijas mezgli.
- `$place->primaryTaxonomy()` – objekta primārā klasifikācija.
- `$place->tags` – objektam piesaistītie tagi (piem., Wi-Fi, Stāvvieta).

---

## 6. CLI rīki administrēšanai

### Sākotnējais imports no Excel
Ja nepieciešams atkārtoti ielasīt vai papildināt taksonomijas datus no lokāla `.xlsx` faila:
```bash
php artisan taxonomy:import-xlsx --file=/home/esm/Downloads/Kategorijas.xlsx
```
Komanda:
1. Ielasa 5 virskategorijas, 33 apakškategorijas un 70 tipus.
2. Sinhronizē tulkojumus `lv`, `en`, `ru`.
3. Pārrēķina kontrolsummas un automātiski atjauno API versijas un iztīra kešatmiņu.

---

## 7. Mobilās Lietotnes REST API v1 (`/api/v1/*`)

Šī sadaļa apraksta visus mobilajai lietotnei paredzētos API galapunktus, to parametrus, atgrieztās shēmas un autentifikācijas prasības.

### 7.1. Klienta galvenes un aktivitātes izsekošana (`TrackMobileActivity`)

Mobilajai lietotnei ieteicams katrā pieprasījumā iekļaut šādas galvenes:
- `X-App-Version`: Lietotnes versija (piemēram, `1.0.0`)
- `X-App-Platform`: Platforma (`ios` vai `android`)
- `X-Device-Id`: Unikāls ierīces identifikators
- `Accept`: `application/json`

Ja lietotājs ir autentificējies ar Sanctum `Bearer <token>`, starpprogrammatūra automātiski asinhroni atjaunina lietotāja profilā `last_active_at`, `last_app_version` un `last_app_platform`.

---

### 7.2. Konfigurācija un Ģeogrāfiskās Vietas

#### `GET /api/v1/app-config`
Atgriež globālo lietotnes konfigurāciju (minimālo atbalstīto versiju, jaunāko versiju, uzturēšanas režīmu, atbalsta kontaktus, noteikumu versiju un klasifikatoru versijas).
- **Autentifikācija:** Nav nepieciešama (viesu pieeja)
- **Atbilde (`200 OK`):**
```json
{
  "status": "success",
  "data": {
    "min_version": "1.0.0",
    "latest_version": "1.0.0",
    "force_update": false,
    "maintenance_mode": false,
    "support_email": "atbalsts@piedzivo.lv",
    "terms_version": "1.0",
    "terms_url": "https://piedzivo.lv/terms",
    "privacy_url": "https://piedzivo.lv/privacy",
    "classification_versions": {
      "taxonomy": 1,
      "tags": 1
    }
  }
}
```

#### `GET /api/v1/geo-places`
Atgriež visus pārlūkojamos Latvijas ģeogrāfiskos punktus (valstspilsētas, novadus) hierarhiskā vai saraksta veidā.
- **Autentifikācija:** Nav nepieciešama
- **Parametri:**
  - `type`: `city`, `municipality` (neobligāts)
  - `region_id`: filtrēt pēc reģiona (neobligāts)
- **Atbilde (`200 OK`):**
```json
{
  "status": "success",
  "data": [
    {
      "id": "9d3e8a12-...",
      "name": "Cēsis",
      "type": "city",
      "slug": "cesis",
      "is_state_city": false,
      "latitude": 57.3125,
      "longitude": 25.2741,
      "region": {
        "id": "...",
        "name": "Vidzeme",
        "slug": "vidzeme"
      }
    }
  ]
}
```

---

### 7.3. Autentifikācija un Sesijas Vadība (`/api/v1/auth/*`)

#### `POST /api/v1/auth/otp/request`
Pieprasa vienreizēju SMS autorizācijas kodu uz tālruņa numuru.
- **Ķermenis:**
```json
{
  "phone": "+37120000000"
}
```
- **Atbilde (`200 OK`):**
```json
{
  "status": "success",
  "message": "OTP kods nosūtīts uz norādīto tālruņa numuru.",
  "data": {
    "phone": "+37120000000",
    "expires_in_seconds": 300
  }
}
```

#### `POST /api/v1/auth/otp/verify`
Pārbauda ievadīto OTP kodu un izsniedz Laravel Sanctum piekļuves marķieri (`token`).
- **Ķermenis:**
```json
{
  "phone": "+37120000000",
  "code": "123456",
  "device_name": "iPhone 15 Pro"
}
```
- **Atbilde (`200 OK`):**
```json
{
  "status": "success",
  "data": {
    "token": "1|abc12345...",
    "user": {
      "id": 1,
      "public_id": "a1b2c3d4",
      "name": "Lietotājs",
      "phone": "+37120000000",
      "role": "user"
    }
  }
}
```

#### `POST /api/v1/auth/social`
Sociālā autentifikācija ar Google vai Apple Identity Token.
- **Ķermenis:**
```json
{
  "provider": "google",
  "token": "id_token_string...",
  "device_name": "Pixel 8"
}
```
- **Atbilde (`200 OK`):** Atgriež Sanctum tokenu un lietotāja profilu.

#### `POST /api/v1/auth/logout`
Atsauc pašreizējo Sanctum marķieri.
- **Autentifikācija:** Obligāta (`Authorization: Bearer <token>`)
- **Atbilde (`200 OK`):** `{"status": "success", "message": "Veiksmīgi izrakstījies."}`

---

### 7.4. Lietotāja Profils un Ieskatīšanās Laiki (`/api/v1/me`)

#### `GET /api/v1/me`
Atgriež autentificētā lietotāja profilu, mājas lokāciju, ieskatīšanās laikus un jauno pasākumu/vietu skaitu kopš pēdējā skatījuma (`badge counts`).
- **Autentifikācija:** Obligāta (`Bearer <token>`)
- **Atbilde (`200 OK`):**
```json
{
  "status": "success",
  "data": {
    "id": 1,
    "public_id": "k8f2a1b9",
    "name": "Jānis Bērziņš",
    "email": "janis@example.com",
    "phone": "+37120000000",
    "role": "user",
    "home_geo_place": {
      "id": "...",
      "name": "Cēsis",
      "type": "city"
    },
    "badges": {
      "new_events_count": 5,
      "new_places_count": 2
    },
    "terms_accepted": true,
    "created_at": "2026-10-29T10:00:00Z"
  }
}
```

#### `PUT /api/v1/me`
Atjaunina vārdu, e-pastu, mājas pilsētu (`home_geo_place_id`) vai apstiprināto noteikumu versiju (`terms_accepted_version`).

#### `POST /api/v1/me/sync-viewed`
Sinhronizē laiku, kad lietotājs pēdējo reizi apskatījis mājas pasākumu vai vietu plūsmu (nodrošina badges atiestatīšanu lietotnē).
- **Ķermenis:** `{"type": "events"}` vai `{"type": "places"}`

---

### 7.5. Pasākumu Galapunkti (`/api/v1/events`)

#### `GET /api/v1/events`
Saraksta skats pasākumu kartītēm ar bagātīgu filtrēšanu un kārtošanu.
- **Autentifikācija:** Nav obligāta (ja autorizējies, atgriež personalizētos laukus `is_recommended_by_me` un `is_followed_by_me`).
- **Filtrēšanas parametri:**
  - `geo_place_id`: UUID filtrs pēc ģeogrāfiskās vietas
  - `category`: taksonomijas slug
  - `time_window`: `today`, `tomorrow`, `this_weekend`, `this_week`, `next_week`, `this_month`
  - `date_from`, `date_to`: precīzs datumu diapazons (`YYYY-MM-DD`)
  - `is_free`: `true` / `false`
  - `has_tickets`: `true` / `false`
  - `q`: meklēšana pēc nosaukuma, apraksta, organizatora
  - `sort`: `date_asc` (noklusējums), `priority`, `recommended`, `popular`
  - `page`: lapas numurs (noklusējumā 20 vienības lapā)
- **Kartītes resursa formāts (`EventCardResource`):**
```json
{
  "id": "uuid...",
  "public_id": "a9x2b3c1",
  "title": "Cēsu Mūzikas Festivāls",
  "slug": "cesu-muzikas-festivals-a9x2b3c1",
  "image_url": "https://...",
  "editorial_priority": 3,
  "recommendations_count": 42,
  "follows_count": 18,
  "is_recommended_by_me": false,
  "is_followed_by_me": false,
  "next_occurrence": {
    "starts_on": "2026-11-05",
    "starts_at": "19:00:00",
    "ends_on": "2026-11-05",
    "ends_at": "22:00:00"
  },
  "place": {
    "id": "uuid...",
    "title": "Vidzemes koncertzāle Cēsis",
    "city": "Cēsis",
    "address": "Raunas iela 12"
  },
  "primary_taxonomy": {
    "id": "...",
    "name": "Mūzika un koncerti",
    "slug": "muzika-un-koncerti"
  }
}
```

#### `GET /api/v1/events/{id}`
Pilns detalizētais pasākuma skats (`EventDetailResource`). Automātiski palielina pasākuma mobilos skatījumus `entity_views_daily` tabulā.
- Parametrs `{id}` var būt gan UUID, gan īsais `public_id`.
- Ietver: pilnu aprakstu, visas norises (`occurrences`), biļešu saites un cenas diapazonu (`ticket_offers`), organizatoru, tagus un saistīto vietu.

---

### 7.6. Vietu Galapunkti (`/api/v1/places`)

#### `GET /api/v1/places`
Saraksta skats apskates vietu kartītēm (`PlaceCardResource`).
- **Filtrēšanas parametri:**
  - `geo_place_id`: UUID filtrs
  - `category`: taksonomijas slug
  - `editorial_priority`: `1`, `2`, `3`
  - `q`: teksta meklēšana
  - `sort`: `priority` (noklusējums), `recommended`, `popular`, `title`
- **Kartītes resursa formāts:**
```json
{
  "id": "uuid...",
  "public_id": "p7k2m1n0",
  "title": "Cēsu viduslaiku pils",
  "slug": "cesu-viduslaiku-pils-p7k2m1n0",
  "city": "Cēsis",
  "address": "Pils laukums 9",
  "latitude": 57.3131,
  "longitude": 25.2718,
  "cover_image_url": "https://...",
  "editorial_priority": 3,
  "recommendations_count": 128,
  "follows_count": 85,
  "is_recommended_by_me": true,
  "is_followed_by_me": false,
  "primary_taxonomy": {
    "name": "Vēsture un arhitektūra",
    "slug": "vesture-un-arhitektura"
  }
}
```

#### `GET /api/v1/places/{id}`
Pilns detalizētais vietas skats (`PlaceDetailResource`). Automātiski uzskaita `entity_views_daily` mobilos skatījumus.
- Ietver: pilnu aprakstu, fotogaleriju (`images`), nedēļas darba laikus (`opening_hours`), ārējās saites (`links`: Google Maps, Facebook, Instagram, mājaslapa), ārējos reitingus un atsauksmju skaitu (`metrics`).

---

### 7.7. Lietotāja Iesaiste: Ieteikumi un Sekošana

#### `POST /api/v1/recommendations/toggle`
Pārslēdz (ieslēdz/izslēdz) ieteikumu ("Piedzīvoju un iesaku") pasākumam vai vietai.
- **Autentifikācija:** Obligāta (`Bearer <token>`)
- **Ķermenis:**
```json
{
  "type": "event",
  "id": "uuid..."
}
```
- **Atbilde (`200 OK`):**
```json
{
  "status": "success",
  "data": {
    "is_recommended": true,
    "recommendations_count": 43
  }
}
```

#### `POST /api/v1/follows/toggle`
Pārslēdz sekošanu ("Sekot jaunumiem / paziņojumiem") pasākumam vai vietai.
- **Autentifikācija:** Obligāta (`Bearer <token>`)
- **Ķermenis:**
```json
{
  "type": "place",
  "id": "uuid..."
}
```
- **Atbilde (`200 OK`):**
```json
{
  "status": "success",
  "data": {
    "is_followed": true,
    "follows_count": 86
  }
}
```

#### `GET /api/v1/me/following`
Atgriež autentificētā lietotāja sekoto pasākumu un vietu sarakstu.
- **Autentifikācija:** Obligāta (`Bearer <token>`)

---

### 7.8. Atsauksmes un Kļūdu Ziņojumi (`POST /api/v1/feedback`)

Iesniedz kļūdas ziņojumu, satura labojumu vai ieteikumu no mobilās lietotnes.
- **Autentifikācija:** Viesiem un autorizētiem lietotājiem
- **Ķermenis:**
```json
{
  "category": "content_issue",
  "context_type": "event",
  "context_id": "uuid...",
  "message": "Pasākuma sākuma laiks ir mainīts uz plkst. 20:00",
  "contact_email": "janis@example.com",
  "app_version": "1.0.0",
  "device_info": "iPhone 15, iOS 17.5"
}
```
- Atbalstītās kategorijas: `content_issue`, `bug`, `suggestion`, `other`.
- Atbalstītie konteksta tipi: `event`, `place`, `general`.

---

### 7.9. Push Paziņojumu Iekārtu Reģistrācija (`POST /api/v1/devices`)

Reģistrē Firebase Cloud Messaging (FCM) vai APNs iekārtas marķieri personalizētiem push paziņojumiem.
- **Autentifikācija:** Obligāta (`Bearer <token>`)
- **Ķermenis:**
```json
{
  "device_token": "fcm_token_string...",
  "platform": "ios",
  "app_version": "1.0.0",
  "device_model": "iPhone 15 Pro"
}
```
- **Atbilde (`200 OK`):** `{"status": "success", "message": "Iekārta veiksmīgi reģistrēta."}`