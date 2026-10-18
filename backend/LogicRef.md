========================================================
[04:00 - CRONJOB HARIAN DIMULAI]
========================================================

STEP 1: KELOMPOKKAN LOKASI
    Ambil semua user_plants dengan status = 'active'
    Kelompokkan berdasarkan (city, province) yang UNIK


STEP 2: FETCH & SIMPAN CUACA KE DATABASE
    FOR EACH (city, province) unik:
        response = GET WeatherAPI.com forecast.json?days=7
        
        FOR EACH hari dalam response (7 baris):
            UPSERT ke weather_cache
                WHERE (city, province, date) MATCH:
                    → UPDATE row yang sudah ada (revisi prediksi lama)
                ELSE:
                    → INSERT row baru
    
    → Selesai. weather_cache sekarang berisi data city ini untuk 7 hari ke depan


STEP 3: SELESAIKAN KONFIRMASI YANG MENGGANTUNG DARI KEMARIN
    (Catatan: kalau user sudah menjawab notifikasi secara real-time
     lewat tombol/app, log ini sudah ter-update duluan sebelum
     cronjob ini jalan. Step ini cuma jaring pengaman untuk yang
     belum dijawab sama sekali)

    FOR EACH watering_log kemarin DENGAN status = 'skip_rain'
        DAN rain_confirmed = 'not_answered':
            → auto-finalisasi: rain_confirmed = 'yes' (percaya data API)
            → last_watered_date pada user_plants terkait = tanggal log kemarin

    FOR EACH watering_log kemarin DENGAN status = 'partial_rain'
        DAN user_moisture_feedback = 'not_answered':
            → auto-finalisasi: user_moisture_feedback = 'moist'
              (asumsi aman, tidak ada tindakan lanjutan)


STEP 4: PROSES SETIAP TANAMAN AKTIF (loop satu per satu)

    4a. CEK PERGANTIAN FASE
        phase_config = watering_config.phase_schedule[current_phase]

        IF phase_config.duration_days IS NULL:
            → fase tak terbatas (ex: generatif mangga), lewati cek ini
        ELSE IF (hari_ini - phase_start_date) >= phase_config.duration_days:
            → current_phase = fase berikutnya
            → phase_start_date = hari_ini
            → kirim notif: "[Tanaman] memasuki fase {fase_baru}"
            → phase_config di-refresh ke config fase baru

    4b. TENTUKAN DUE DATE EFEKTIF
        effective_due_date = adjusted_due_date ATAU
            (last_watered_date + phase_config.watering_interval_days)

        IF hari_ini < effective_due_date:
            → belum waktunya, SKIP ke tanaman berikutnya (lanjut loop 4)

    4c. AMBIL DATA CUACA DARI CACHE (baca saja, tidak fetch baru)
        weather_today = SELECT weather_cache
            WHERE city = lokasi_tanaman.city AND date = hari_ini

        weather_lookahead = SELECT weather_cache
            WHERE city = lokasi_tanaman.city
            AND date BETWEEN hari_ini+1 AND hari_ini + phase_config.lookahead_days

    4d. LOGIKA KEPUTUSAN (4 CABANG)

        IF weather_today.rainfall_mm >= phase_config.rain_equivalent_full_mm:
            ┌─ CABANG 1: HUJAN PENUH (perlu konfirmasi)
            status = 'skip_rain'
            rain_confirmed = 'not_answered'   ← belum final
            → last_watered_date TIDAK diupdate dulu
            → kirim notif: "Diperkirakan hujan cukup untuk [Tanaman] 
                             hari ini. Benar terjadi hujan?"
                             [Ya, Benar Hujan] [Tidak, Cerah Saja]

        ELSE IF weather_today.rainfall_mm >= phase_config.min_significant_rain_mm:
            ┌─ CABANG 2: HUJAN SEBAGIAN (perlu cek besok pagi)
            status = 'partial_rain'
            user_moisture_feedback = 'not_answered'
            adjusted_due_date = hari_ini + 1   ← cek ulang lebih cepat
            → kirim notif: "Hujan membantu sebagian untuk [Tanaman], 
                             kami cek kondisi tanahnya besok pagi"

        ELSE:
            ┌─ tidak ada hujan signifikan hari ini, cek prediksi ke depan
            IF EXISTS hari dalam weather_lookahead DENGAN
                (rain_probability_percent >= phase_config.rain_prob_threshold
                 OR rainfall_mm >= phase_config.min_significant_rain_mm)
               AND delay_streak_days < phase_config.max_delay_days:

                ┌─ CABANG 3: DITUNDA, HUJAN DIPERKIRAKAN DATANG
                status = 'delayed_rain_expected'
                adjusted_due_date = hari_ini + 1
                delay_streak_days += 1
                → kirim notif: "Penyiraman [Tanaman] ditunda, hujan 
                                 diprediksi {tanggal} ({prob}% / {mm}mm)"

            ELSE:
                ┌─ CABANG 4: TIDAK ADA HARAPAN HUJAN, SIRAM SEKARANG
                status = 'need_water'
                delay_streak_days = 0
                IF delay_streak_days_sebelumnya > 0:
                    → kirim notif: "Prediksi hujan meleset, saatnya 
                                     siram [Tanaman] sekarang"
                ELSE:
                    → kirim notif: "Saatnya siram [Tanaman] hari ini"

    4e. SIMPAN LOG
        INSERT ke watering_logs:
            (user_plant_id, phase_at_time, scheduled_date = hari_ini,
             status, delay_streak_at_time, rain_confirmed atau 
             user_moisture_feedback (sesuai cabang), weather_snapshot)


STEP 5: AGREGASI & KIRIM NOTIFIKASI
    Kelompokkan semua notif per user (jangan kirim 1-1 per tanaman)
    Contoh gabungan: "2 tanaman perlu disiram, 1 ditunda karena 
    prediksi hujan, 1 perlu konfirmasi apakah benar hujan turun"
    → Kirim via FCM, log ke notifications table


========================================================
[CRONJOB SELESAI]
========================================================

--------------------------------------------------------
PROSES TERPISAH (real-time, di luar cronjob):
Saat user menekan tombol notif ATAU jawab di dalam app:
    → API Laravel menerima respons
    → UPDATE watering_logs.rain_confirmed / user_moisture_feedback
    → JIKA rain_confirmed = 'yes': last_watered_date = scheduled_date
    → JIKA rain_confirmed = 'no': trigger status baru 'need_water' 
      hari itu juga (tidak menunggu cronjob besok)
    → JIKA user_moisture_feedback = 'dry': trigger status 'need_water'
--------------------------------------------------------