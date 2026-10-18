# Spesifikasi Proyek: Agronoma Backend
**Versi:** 1.0.0 | **Status:** Active

## 1. Konteks & Tujuan

Agronoma adalah "Personal Intelligent Agronomist" — aplikasi mobile yang membantu pengguna awam merawat tanaman rumahan/pekarangan/lahan terbuka secara adaptif berbasis AI dan data cuaca real-time. Backend ini adalah REST API yang menjadi otak dari aplikasi tersebut, dengan fungsionalitas inti:

1. **Onboarding tanaman berbasis AI** — pengguna memilih lokasi & media tanam, mendapatkan analisis jenis tanah (scan kamera atau manual), lalu menerima rekomendasi 3 jenis tanaman (atau memeriksa kecocokan tanaman pilihan sendiri) dari Google Gemini dengan grounding riset iklim jangka panjang lokasi tersebut.
2. **Generative care config** — begitu tanaman dikonfirmasi, AI menghasilkan jadwal penyiraman & pemupukan per fase pertumbuhan secara terstruktur (JSON), disimpan langsung ke `user_plants`.
3. **Cronjob harian adaptif cuaca** — setiap hari sistem mengambil prakiraan 7 hari dari WeatherAPI.com, lalu menjalankan mesin keputusan 4-cabang (siram/tunda/hujan penuh/hujan sebagian) untuk setiap tanaman aktif, mencatat log, dan mengirim notifikasi gabungan via Firebase Cloud Messaging (FCM).
4. **Deteksi visual berbasis AI** — scan foto tanah untuk klasifikasi jenis tanah, dan scan foto tanaman/daun untuk deteksi dini hama & penyakit beserta rekomendasi tindakan.
5. **Chatbot AI kontekstual** — asisten percakapan yang bisa dibuka umum atau dari halaman detail tanaman tertentu (context-aware).
6. **Dashboard & profil** — ringkasan status seluruh tanaman, cuaca hari ini, skor perawatan, dan riwayat/arsip tanaman.

## 2. Batasan Teknis (Tech Stack)

> **Agen AI:** Gunakan teknologi berikut secara eksklusif. Jangan menginstal dependensi tambahan tanpa persetujuan eksplisit.

- **Runtime:** PHP 8.3+
- **Framework:** Laravel 13
- **Autentikasi API:** Laravel Sanctum (token-based, personal access token — bukan session/cookie SPA mode)
- **Database:** MySQL 8.0+
- **ORM:** Eloquent (bawaan Laravel)
- **HTTP Client eksternal:** Guzzle (via `Illuminate\Support\Facades\Http`)
- **API Cuaca:** WeatherAPI.com (`forecast.json`, 7 hari)
- **AI Generatif:**
  - `gemini-2.5-flash-lite` **dengan Grounding (Google Search)** — khusus untuk Prompt 1 (rekomendasi tanaman) & Prompt 2 (cek kecocokan tanaman custom), karena butuh riset iklim jangka panjang lokasi.
  - `gemini-3.5-flash-lite` **tanpa Grounding** — untuk Prompt 3 (generate `watering_config` & `fertilizing_config`), serta untuk task vision (deteksi jenis tanah dari foto & deteksi hama/penyakit dari foto), karena tidak butuh riset eksternal dan harus cepat/deterministik.
  - Wajib mengaktifkan **Structured Output** (`response_mime_type: application/json` + `response_schema`) di setiap pemanggilan Gemini API.
- **Push Notification:** Firebase Cloud Messaging (FCM) via `kreait/firebase-php`
- **Scheduler:** Laravel Task Scheduling (`routes/console.php` / Kernel) untuk cronjob harian jam 04:00
- **Testing:** Pest (atau PHPUnit bawaan Laravel 13)
- **Format response:** JSON API konsisten (lihat §3), semua endpoint terautentikasi memakai middleware `auth:sanctum`

## 3. Skema Data & Kontrak API (API Contracts)

**Skema Database:**

```sql
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. USERS & LOCATIONS -----------------------------------------

CREATE TABLE users (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name            VARCHAR(150) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    email_verified_at TIMESTAMP NULL,
    password        VARCHAR(255) NOT NULL,
    remember_token  VARCHAR(100) NULL COMMENT 'standar Laravel/Sanctum',
    push_token      VARCHAR(255) NULL COMMENT 'FCM device token',
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE locations (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id         BIGINT UNSIGNED NOT NULL,
    label           VARCHAR(100) NOT NULL COMMENT 'ex: Home, Backyard Garden',
    city            VARCHAR(100) NOT NULL COMMENT 'query param WeatherAPI.com',
    province        VARCHAR(100) NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_locations_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_locations_user (user_id),
    INDEX idx_locations_city (city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. CORE: USER PLANTS (identitas tanaman free-text, tanpa katalog) --

CREATE TABLE user_plants (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id                 BIGINT UNSIGNED NOT NULL,
    location_id             BIGINT UNSIGNED NOT NULL,
    plant_name              VARCHAR(150) NOT NULL,
    planting_medium         ENUM('home_yard','open_land','pot') NOT NULL,
    soil_type               ENUM('fertile','clay','sandy','chalky','volcanic','peat','artificial_media') NOT NULL,
    current_phase           ENUM('seedling','early_vegetative','late_vegetative','generative') NOT NULL DEFAULT 'seedling',
    phase_start_date        DATE NOT NULL,
    planting_date           DATE NOT NULL,
    watering_config         JSON NOT NULL,
    fertilizing_config      JSON NOT NULL,
    last_watered_date       DATE NULL,
    last_fertilized_date    DATE NULL,
    adjusted_due_date       DATE NULL,
    delay_streak_days       SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    status                  ENUM('active','archived','failed') NOT NULL DEFAULT 'active',
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_plants_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_plants_location FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE,
    INDEX idx_user_plants_status_location (status, location_id),
    INDEX idx_user_plants_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. LOGS / HISTORY ----------------------------------------------

CREATE TABLE watering_logs (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_plant_id           BIGINT UNSIGNED NOT NULL,
    phase_at_time           ENUM('seedling','early_vegetative','late_vegetative','generative') NOT NULL,
    scheduled_date          DATE NOT NULL,
    actual_date             DATE NULL,
    status                  ENUM('watered','skip_rain','partial_rain','delayed_rain_expected','need_water','missed') NOT NULL,
    delay_streak_at_time    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    rain_confirmed          ENUM('yes','no','not_answered') NULL,
    user_moisture_feedback  ENUM('moist','dry','not_answered') NULL,
    weather_snapshot        JSON NULL,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_watering_logs_plant FOREIGN KEY (user_plant_id) REFERENCES user_plants(id) ON DELETE CASCADE,
    INDEX idx_watering_logs_plant_date (user_plant_id, scheduled_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE fertilizing_logs (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_plant_id           BIGINT UNSIGNED NOT NULL,
    scheduled_date          DATE NOT NULL,
    actual_date             DATE NULL,
    status                  ENUM('fertilized','delayed_rain','missed') NOT NULL,
    fertilizer_description  VARCHAR(255) NULL,
    created_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_fertilizing_logs_plant FOREIGN KEY (user_plant_id) REFERENCES user_plants(id) ON DELETE CASCADE,
    INDEX idx_fertilizing_logs_plant_date (user_plant_id, scheduled_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE pest_scan_history (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id                 BIGINT UNSIGNED NOT NULL,
    user_plant_id           BIGINT UNSIGNED NULL,
    image_url               VARCHAR(255) NOT NULL,
    detected_pest_name      VARCHAR(150) NULL,
    ai_confidence           DECIMAL(5,2) NULL,
    ai_raw_response         JSON NULL,
    recommended_action      TEXT NULL,
    scanned_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pest_scan_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_pest_scan_plant FOREIGN KEY (user_plant_id) REFERENCES user_plants(id) ON DELETE SET NULL,
    INDEX idx_pest_scan_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE soil_scan_history (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id                 BIGINT UNSIGNED NOT NULL,
    image_url               VARCHAR(255) NOT NULL,
    detected_soil_type      ENUM('fertile','clay','sandy','chalky','volcanic','peat','artificial_media') NOT NULL,
    ai_confidence           DECIMAL(5,2) NULL,
    scanned_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_soil_scan_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_soil_scan_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. WEATHER CACHE -------------------------------------------------

CREATE TABLE weather_cache (
    id                      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    city                    VARCHAR(100) NOT NULL,
    province                VARCHAR(100) NULL,
    date                    DATE NOT NULL,
    condition               ENUM('sunny','partly_cloudy','cloudy','light_rain','moderate_rain','heavy_rain') NOT NULL,
    rainfall_mm             DECIMAL(6,2) NOT NULL DEFAULT 0,
    rain_probability_percent TINYINT UNSIGNED NOT NULL DEFAULT 0,
    temp_min                DECIMAL(4,1) NULL,
    temp_max                DECIMAL(4,1) NULL,
    fetched_at              TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_weather_city_date (city, province, date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 5. NOTIFICATIONS & CHATBOT ---------------------------------------

CREATE TABLE notifications (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id             BIGINT UNSIGNED NOT NULL,
    type                ENUM('watering','fertilizing','phase_change','pest_alert') NOT NULL,
    related_plant_ids   JSON NULL,
    message             TEXT NOT NULL,
    sent_at             TIMESTAMP NULL,
    is_read             BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_notifications_user_read (user_id, is_read)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE chat_sessions (
    id                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id             BIGINT UNSIGNED NOT NULL,
    context_plant_id    BIGINT UNSIGNED NULL,
    created_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_chat_sessions_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_chat_sessions_plant FOREIGN KEY (context_plant_id) REFERENCES user_plants(id) ON DELETE SET NULL,
    INDEX idx_chat_sessions_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE chat_messages (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    session_id      BIGINT UNSIGNED NOT NULL,
    role            ENUM('user','ai') NOT NULL,
    content         TEXT NOT NULL,
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_chat_messages_session FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE,
    INDEX idx_chat_messages_session (session_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
```

**Spesifikasi Endpoint Utama:**

Semua endpoint diprefix `/api`, response error konsisten: `{"message": "...", "errors": {...}}` (422 untuk validasi, 401 tidak terautentikasi, 403 bukan pemilik resource, 404 tidak ditemukan, 500 disamarkan tanpa stack trace).

### Auth (publik kecuali disebutkan)
| Method & Path | Request Body | Success | Error |
|---|---|---|---|
| `POST /api/register` | `{name, email, password, password_confirmation}` | `201 {user, token}` | `422` email sudah dipakai / validasi gagal |
| `POST /api/login` | `{email, password}` | `200 {user, token}` | `422` kredensial salah |
| `POST /api/logout` *(auth)* | — | `200 {message}` | `401` |
| `GET /api/user` *(auth)* | — | `200 {user}` | `401` |
| `POST /api/device-token` *(auth)* | `{push_token}` | `200 {message}` | `422` |

### Locations *(auth, semua scoped ke user login)*
| Method & Path | Request Body | Success | Error |
|---|---|---|---|
| `GET /api/locations` | — | `200 {data:[location]}` | `401` |
| `POST /api/locations` | `{label, city, province}` | `201 {location}` | `422` |
| `PATCH /api/locations/{id}` | `{label?, city?, province?}` | `200 {location}` | `404`, `403` |
| `DELETE /api/locations/{id}` | — | `204` | `404`, `403` |

### Wizard Tambah Tanaman *(auth)*
| Method & Path | Request Body | Success | Error |
|---|---|---|---|
| `POST /api/soil-scan` | multipart `{image, location_id?}` | `200 {detected_soil_type, ai_confidence}` — tersimpan ke `soil_scan_history` | `422` file bukan gambar |
| `POST /api/plant-recommendations` | `{planting_medium, soil_type, city, province}` | `200 {recommendations:[{rank, plant_name, scores, reasoning, estimated_harvest_days}]}` (Prompt 1, `gemini-2.5-flash-lite` + grounding, **tidak disimpan ke DB**) | `422`, `502` AI gagal merespons |
| `POST /api/plant-suitability` | `{plant_name, planting_medium, soil_type, city, province}` | `200 {plant_name, verdict, scores, reasoning, alternative_suggestion}` (Prompt 2, `gemini-2.5-flash-lite` + grounding) | `422`, `502` |
| `POST /api/plants` | `{location_id, plant_name, planting_medium, soil_type, current_phase, planting_date}` | `201 {plant}` — backend memanggil Prompt 3 (`gemini-3.5-flash-lite`, tanpa grounding) untuk generate `watering_config` & `fertilizing_config`, lalu insert `user_plants` | `422`, `502` AI gagal |

### Plants *(auth, scoped ke user login)*
| Method & Path | Request Body | Success | Error |
|---|---|---|---|
| `GET /api/plants?status=active` | — | `200 {data:[{...plant, badge_status}]}` (badge dihitung dari due date & log terakhir: `perlu_disiram`, `perlu_pupuk`, `kondisi_aman`) | `401` |
| `GET /api/plants/{id}` | — | `200 {plant}` — tab "Ringkasan" | `404`, `403` |
| `GET /api/plants/{id}/weather` | — | `200 {forecast:[{date,condition,temp_min,temp_max,rainfall_mm}]}` (7 hari, dari `weather_cache` by kota lokasi tanaman) | `404` |
| `GET /api/plants/{id}/care-calendar?month=YYYY-MM` | — | `200 {days:[{date, watering_status, fertilizing_status}]}` — tab "Perawatan" | `404` |
| `PATCH /api/plants/{id}` | `{status?, current_phase?}` | `200 {plant}` | `422`, `404` |
| `DELETE /api/plants/{id}` | — | `204` | `404`, `403` |

### Aksi Perawatan *(auth)*
| Method & Path | Request Body | Success | Error |
|---|---|---|---|
| `POST /api/plants/{id}/watering/complete` | — | `200 {watering_log}` — tombol "Selesai" | `404`, `409` sudah selesai hari ini |
| `POST /api/plants/{id}/watering/postpone` | — | `200 {watering_log}` — tombol "Tunda" | `404` |
| `POST /api/watering-logs/{id}/rain-confirm` | `{rain_confirmed: yes\|no}` | `200 {watering_log}` — sesuai alur real-time di cronjob doc | `422`, `404` |
| `POST /api/watering-logs/{id}/moisture-feedback` | `{user_moisture_feedback: moist\|dry}` | `200 {watering_log}` | `422`, `404` |
| `POST /api/plants/{id}/fertilizing/complete` | — | `200 {fertilizing_log}` | `404` |

### Deteksi Hama & Penyakit *(auth)*
| Method & Path | Request Body | Success | Error |
|---|---|---|---|
| `POST /api/pest-scans` | multipart `{image, user_plant_id?}` | `201 {detected_pest_name, ai_confidence, recommended_action}` (`gemini-3.5-flash-lite` vision, tanpa grounding) | `422`, `502` |
| `GET /api/pest-scans?user_plant_id=` | — | `200 {data:[pest_scan]}` | `401` |

### Notifikasi *(auth)*
| Method & Path | Request Body | Success | Error |
|---|---|---|---|
| `GET /api/notifications?is_read=` | — | `200 {data:[notification]}` | `401` |
| `PATCH /api/notifications/{id}/read` | — | `200 {notification}` | `404` |
| `PATCH /api/notifications/read-all` | — | `200 {message}` | `401` |

### Chatbot *(auth)*
| Method & Path | Request Body | Success | Error |
|---|---|---|---|
| `POST /api/chat-sessions` | `{context_plant_id?}` | `201 {chat_session}` | `422` |
| `GET /api/chat-sessions/{id}/messages` | — | `200 {data:[chat_message]}` | `404` |
| `POST /api/chat-sessions/{id}/messages` | `{content}` | `201 {user_message, ai_message}` | `422`, `502` |

### Dashboard & Profil *(auth)*
| Method & Path | Request Body | Success | Error |
|---|---|---|---|
| `GET /api/dashboard` | — | `200 {greeting, weather_today, plants:[...]}` | `401` |
| `GET /api/profile` | — | `200 {total_plants, harvested_count, care_score_percent, preferences}` — `harvested_count` = `count(status=archived)` | `401` |
| `PATCH /api/profile/preferences` | `{watering_reminder_enabled}` | `200 {preferences}` | `422` |

### Internal (bukan HTTP endpoint)
`php artisan agronoma:daily-processing` — dijadwalkan `04:00` via scheduler, menjalankan seluruh pseudocode cronjob (fetch cuaca 7 hari per kota unik → upsert `weather_cache` → selesaikan konfirmasi tertunda kemarin → loop tiap `user_plants` aktif: cek pergantian fase → hitung due date efektif → 4-cabang keputusan siram berdasar `weather_cache` → insert `watering_logs` → agregasi notifikasi per user → kirim FCM & log ke `notifications`).

## 4. Rencana Implementasi (Task Execution)

> **Agen AI:** Eksekusi tugas berikut secara berurutan. Setelah satu tugas selesai dan terverifikasi, ubah status menjadi `[x]`.

### Fase 1: Setup & Konfigurasi Dasar
- [ ] Inisialisasi proyek Laravel 13, install `laravel/sanctum`, `kreait/firebase-php`
- [ ] Konfigurasi `.env`: koneksi MySQL, `WEATHERAPI_KEY`, `GEMINI_API_KEY`, kredensial Firebase (service account JSON), `GEMINI_MODEL_GROUNDED=gemini-2.5-flash-lite`, `GEMINI_MODEL_STANDARD=gemini-3.5-flash-lite`
- [ ] Buat migration sesuai skema §3 (termasuk `remember_token` di `users`) dan jalankan `migrate`
- [ ] Buat Eloquent model + relasi untuk semua tabel (`User`, `Location`, `UserPlant`, `WateringLog`, `FertilizingLog`, `PestScanHistory`, `SoilScanHistory`, `WeatherCache`, `Notification`, `ChatSession`, `ChatMessage`)
- [ ] Setup exception handler global agar semua error API mengembalikan format JSON konsisten (§3), sembunyikan detail internal di lingkungan produksi
- [ ] Setup Sanctum untuk personal access token (bukan mode SPA/cookie), definisikan route grup `auth:sanctum`

### Fase 2: Pembuatan Endpoint & Logika Bisnis
- [ ] Buat `WeatherApiService` — fetch `forecast.json` 7 hari per kota, upsert ke `weather_cache`
- [ ] Buat `GeminiService` dengan 2 mode pemanggilan: grounded (`gemini-2.5-flash-lite`) untuk Prompt 1 & 2, standar (`gemini-3.5-flash-lite`) untuk Prompt 3 & vision (soil scan, pest scan) — semua wajib `response_schema` terstruktur
- [ ] Implementasi Auth (`register`, `login`, `logout`, `user`, `device-token`)
- [ ] Implementasi CRUD `Locations`
- [ ] Implementasi endpoint wizard: `soil-scan`, `plant-recommendations`, `plant-suitability`, `plants` (create + generate config)
- [ ] Implementasi `GET /plants`, `/plants/{id}`, `/plants/{id}/weather`, `/plants/{id}/care-calendar`, update/delete
- [ ] Implementasi logika badge status (`perlu_disiram`/`perlu_pupuk`/`kondisi_aman`) sebagai accessor/service, bukan di route
- [ ] Buat Artisan Command `agronoma:daily-processing` sesuai pseudocode cronjob lengkap (fase, due date, 4 cabang keputusan, delay streak, agregasi notifikasi), daftarkan di scheduler jam 04:00
- [ ] Implementasi endpoint aksi perawatan (`watering/complete`, `watering/postpone`, `rain-confirm`, `moisture-feedback`, `fertilizing/complete`) — termasuk efek real-time sesuai dokumen cronjob (rain_confirmed=no → trigger `need_water` hari itu juga)
- [ ] Implementasi `FcmService` untuk kirim push notification, endpoint `pest-scans` (vision) dan `notifications`
- [ ] Implementasi `chat-sessions` & `chat-messages` (kirim histori + context tanaman ke Gemini bila `context_plant_id` ada)
- [ ] Implementasi `dashboard` & `profile` (termasuk kalkulasi `care_score_percent`)
- [ ] Tulis test (Pest/PHPUnit) untuk: auth flow, CRUD locations, generate config AI (mock Gemini), dan terutama 4 cabang logika cronjob dengan berbagai skenario cuaca

## 5. Kriteria Penerimaan (Acceptance Criteria)

Fitur dianggap selesai jika:
- [ ] Migration berjalan bersih dan menghasilkan skema identik dengan §3 (termasuk `remember_token`)
- [ ] Seluruh endpoint selain `register`/`login` terproteksi `auth:sanctum` dan hanya mengembalikan data milik user yang login
- [ ] `agronoma:daily-processing` menghasilkan status (`need_water`/`skip_rain`/`partial_rain`/`delayed_rain_expected`) yang tepat sesuai pseudocode untuk setiap skenario cuaca uji, dan aman dijalankan berulang (idempotent via upsert `weather_cache`)
- [ ] Pemanggilan AI menggunakan model yang benar: `gemini-2.5-flash-lite` + grounding untuk Prompt 1 & 2, `gemini-3.5-flash-lite` tanpa grounding untuk Prompt 3 & scan visual
- [ ] Notifikasi tergabung per user (bukan 1 notifikasi per tanaman) dan berhasil terkirim via FCM serta tercatat di tabel `notifications`
- [ ] Semua response error mengikuti format JSON konsisten dan tidak membocorkan stack trace/query SQL
- [ ] Seluruh test suite berjalan hijau (`pass`)

## 6. Aturan Ketat (Anti-Patterns / Do NOT Do)

- **JANGAN** menaruh logika bisnis (pemanggilan AI, WeatherAPI, mesin keputusan cronjob) langsung di dalam route/controller — wajib dibungkus di Service/Action class.
- **JANGAN** mengembalikan response mentah Gemini/WeatherAPI atau stack trace database ke client — selalu transformasikan ke bentuk kontrak API di §3.
- **JANGAN** membuat tabel katalog tanaman tetap — `plant_name` sengaja free-text agar rekomendasi AI tidak dibatasi daftar tertutup.
- **JANGAN** melewatkan pencatatan ke `watering_logs`/`fertilizing_logs` untuk keputusan apa pun (baik dari cronjob maupun aksi manual user) — ini satu-satunya sumber kebenaran untuk kalender perawatan & skor perawatan.
- **JANGAN** hardcode API key (WeatherAPI, Gemini, Firebase) di kode — semua wajib lewat `.env`/`config`.
- **JANGAN** menjalankan ulang fetch cuaca per lokasi individual — `weather_cache` di-fetch sekali per kota unik per hari lalu dibaca ulang oleh semua tanaman di kota yang sama.
- **JANGAN** menginstal library tambahan di luar stack §2 tanpa persetujuan eksplisit.
