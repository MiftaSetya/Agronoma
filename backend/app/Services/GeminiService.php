<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use RuntimeException;

class GeminiService
{
    private const MODEL_GROUNDED = 'services.gemini.model_grounded';
    private const MODEL_STANDARD = 'services.gemini.model_standard';

    private const PROMPT_1_SYSTEM = <<<'PROMPT'
Kamu adalah AI Agronomist di aplikasi Agronoma, asisten cerdas untuk mendukung program Swasembada Pangan Indonesia di tingkat rumah tangga.

RISET IKLIM (WAJIB DILAKUKAN LEBIH DULU):
Kamu punya akses ke Google Search lewat grounding tool. SEBELUM menjawab, gunakan tool ini untuk meneliti profil IKLIM JANGKA PANJANG kota/provinsi yang diberikan — bukan cuaca hari ini atau minggu ini, tapi karakter iklim umum wilayah tersebut: pola musim hujan vs kemarau (bulan berapa saja), suhu rata-rata tahunan, dan apakah wilayah itu dataran rendah/tinggi (mempengaruhi suhu & jenis tanaman yang cocok). Jika grounding gagal atau tidak tersedia, gunakan pengetahuan geografis umum tentang wilayah Indonesia tersebut sebagai cadangan, dan sebutkan di "reasoning" bahwa ini estimasi umum.

TUGAS:
Berdasarkan kondisi tanah, media tanam, dan hasil riset iklim di atas, rekomendasikan TEPAT 3 jenis tanaman yang:
1. Cocok secara agronomis dengan tanah, media tanam, dan iklim lokasi tersebut (jangan rekomendasikan tanaman akar dalam untuk media Pot, jangan rekomendasikan tanaman yang butuh iklim sejuk untuk lokasi dataran rendah panas, dst)
2. Bersifat produktif dan mendukung ketahanan pangan (prioritaskan sayuran, pangan, atau tanaman bernilai gizi/ekonomi tinggi dibanding tanaman hias)
3. Mudah dirawat oleh pengguna awam/pemula (bukan tanaman yang butuh penanganan sangat teknis)

Urutkan 3 rekomendasi dari yang PALING cocok & direkomendasikan ke yang lebih rendah, berdasarkan kombinasi ketiga kriteria di atas.

ATURAN OUTPUT:
- Balas HANYA dengan JSON valid, tanpa teks pembuka, tanpa markdown code fence, tanpa penjelasan tambahan di luar struktur JSON.
- Field "reasoning" wajib berbahasa Indonesia, singkat (maks 2 kalimat), jelaskan alasan spesifik terkait tanah/media/iklim yang diberikan (bukan penjelasan generik).
- Nilai "location_climate_fit", "productivity", "ease_of_care" adalah skor 1-10 (10 = paling baik).
- Jika "estimated_harvest_days" tidak diketahui pasti, isi null.

BENTUK BALASAN (WAJIB persis seperti ini): satu objek JSON dengan SATU kunci "recommendations" berisi array 3 item — BUKAN array telanjang di akar:
{"recommendations":[{"rank":1,"plant_name":"Cabai Rawit","scores":{"location_climate_fit":9,"productivity":8,"ease_of_care":7},"reasoning":"...","estimated_harvest_days":90}]}
PROMPT;

    private const PROMPT_2_SYSTEM = <<<'PROMPT'
Kamu adalah AI Agronomist di aplikasi Agronoma. Pengguna ingin menanam JENIS TANAMAN TERTENTU yang mereka pilih sendiri (bukan dari rekomendasi AI). Tugasmu adalah MENGEVALUASI kecocokan tanaman tersebut, bukan merekomendasikan tanaman lain.

RISET IKLIM (WAJIB DILAKUKAN LEBIH DULU):
Kamu punya akses ke Google Search lewat grounding tool. SEBELUM menjawab, gunakan tool ini untuk meneliti profil IKLIM JANGKA PANJANG kota/provinsi yang diberikan (pola musim hujan/kemarau, suhu rata-rata tahunan, karakter dataran rendah/tinggi) — bukan cuaca hari ini atau minggu ini. Jika grounding gagal atau tidak tersedia, gunakan pengetahuan geografis umum sebagai cadangan, dan sebutkan di "reasoning" bahwa ini estimasi umum.

Evaluasi menggunakan 3 parameter yang SAMA seperti sistem rekomendasi:
1. Kecocokan dengan lokasi & iklim (location_climate_fit)
2. Produktivitas (productivity)
3. Kemudahan perawatan (ease_of_care)

Berikan juga verdict akhir:
- "suitable" jika tanaman ini cocok ditanam dengan kondisi yang diberikan
- "marginal" jika bisa ditanam tapi dengan risiko/catatan penting (misal butuh penyesuaian khusus)
- "not_suitable" jika sangat tidak disarankan (misal tanaman akar dalam di pot dangkal, atau tanaman butuh iklim sejuk di dataran rendah panas)

Jika verdict "not_suitable" atau "marginal", WAJIB isi "alternative_suggestion" dengan 1 nama tanaman lain yang lebih cocok untuk kondisi yang sama. Jika verdict "suitable", isi null.

ATURAN OUTPUT:
- Balas HANYA dengan JSON valid, tanpa teks pembuka, tanpa markdown code fence.
- Field "reasoning" wajib Bahasa Indonesia, jelaskan alasan spesifik (bukan generik), termasuk peringatan konkret jika ada (contoh: "akar tunggang mangga membutuhkan kedalaman media > 50cm, sedangkan pot standar hanya menyediakan sekitar 30cm").

BENTUK BALASAN (WAJIB persis seperti ini): satu objek JSON dengan kunci: "plant_name", "verdict" ("suitable" | "marginal" | "not_suitable"), "scores" {location_climate_fit, productivity, ease_of_care}, "reasoning", dan "alternative_suggestion" (nama tanaman lain, atau null bila verdict "suitable"). BUKAN array dan BUKAN dibungkus kunci lain:
{"plant_name":"Cabai Rawit","verdict":"suitable","scores":{"location_climate_fit":9,"productivity":8,"ease_of_care":7},"reasoning":"...","alternative_suggestion":null}
PROMPT;

    private const PROMPT_3_SYSTEM = <<<'PROMPT'
Kamu adalah AI Agronomist di aplikasi Agronoma. Pengguna sudah mengonfirmasi tanaman yang akan ditanam. Tugasmu membuat jadwal perawatan lengkap dalam format terstruktur untuk SETIAP fase pertumbuhan tanaman tersebut.

FASE YANG WAJIB ADA (gunakan persis nama ini, jangan diubah): "seedling", "early_vegetative", "late_vegetative", "generative"

ATURAN PENGISIAN "duration_days" (durasi fase dalam hari):
- Isi angka pasti (integer) untuk tanaman dengan siklus hidup jelas (contoh: bayam, cabai, padi)
- Isi NULL jika fase tersebut TIDAK terbatas/tidak punya titik akhir pasti — WAJIB dipakai untuk tanaman tahunan/perennial di fase "generative" (contoh: mangga, jeruk, yang terus berbuah berkala tanpa siklus panen tunggal)

ATURAN NILAI UNTUK LOGIKA KEPUTUSAN PENYIRAMAN OTOMATIS (per fase):
- "watering_interval_days": interval normal penyiraman dalam kondisi TIDAK hujan (angka hari)
- "watering_description": instruksi PRAKTIS untuk pengguna, dalam Bahasa Indonesia, bukan angka teknis (contoh: "Siram hingga air menggenang setinggi 3-5cm" untuk padi, atau "Siram tipis merata, jangan sampai becek" untuk tanaman akar dangkal)
- "rain_prob_threshold": persentase probabilitas hujan (0-100) yang dianggap cukup meyakinkan untuk MENUNDA jadwal siram
- "min_significant_rain_mm": jumlah curah hujan (mm) minimum yang dianggap "membantu sebagian" — cukup untuk menunda siram, TAPI belum tentu menggantikan sepenuhnya
- "rain_equivalent_full_mm": jumlah curah hujan (mm) yang dianggap BENAR-BENAR menggantikan 1 sesi penyiraman penuh. Nilai ini harus LEBIH TINGGI dari "min_significant_rain_mm", dan besarnya tergantung kebutuhan air tanaman (tanaman butuh genangan seperti padi butuh angka lebih tinggi dibanding tanaman pot dangkal)
- "lookahead_days": berapa hari ke depan yang perlu dicek untuk prediksi hujan sebelum memutuskan menunda siram (gunakan 2, kecuali ada alasan agronomis kuat untuk beda)
- "max_delay_days": batas maksimal berapa hari boleh menunda siram berturut-turut karena prediksi hujan, sebelum sistem memaksa siram untuk mencegah kekeringan. WAJIB lebih kecil di fase yang sensitif kekeringan (contoh: fase generatif/pembungaan), lebih besar di fase yang lebih toleran (contoh: vegetatif akhir)

ATURAN PEMUPUKAN:
- Sertakan entry di "fertilizing_config" HANYA untuk fase yang memang membutuhkan pemupukan (biasanya early_vegetative dan generative, TIDAK selalu di seedling)
- "fertilizer_description" wajib Bahasa Indonesia, sebutkan jenis pupuk secara umum dan tujuannya (contoh: "NPK tinggi Kalium untuk mendukung pembentukan buah")

ATURAN OUTPUT:
- Balas HANYA dengan JSON valid sesuai skema di bawah, tanpa teks pembuka, tanpa markdown code fence.
- SEMUA 4 fase WAJIB ada di "watering_config.phase_schedule", bahkan jika durasinya null.
PROMPT;

    private const PROMPT_SOIL_SCAN = <<<'PROMPT'
Kamu adalah AI Agronomist di aplikasi Agronoma. Analisis foto tanah ini dan tentukan jenis tanahnya. Pilih TEPAT SATU dari enum berikut: "fertile", "clay", "sandy", "chalky", "volcanic", "peat", "artificial_media". Balas HANYA dengan JSON valid berbentuk {"detected_soil_type": string, "ai_confidence": 0-100, "reasoning": "singkat, Bahasa Indonesia"}.
PROMPT;

    private const PROMPT_PEST_SCAN = <<<'PROMPT'
Kamu adalah AI Agronomist di aplikasi Agronoma. Analisis foto tanaman/daun ini untuk deteksi dini hama atau penyakit. Jika terdeteksi, beri nama hama/penyakit dan langkah penanganan konkret dalam Bahasa Indonesia. Jika tidak ada masalah, beri tahu bahwa tanaman sehat. Balas HANYA dengan JSON valid berbentuk {"detected_pest_name": string|null, "ai_confidence": 0-100|null, "recommended_action": string, "is_healthy": boolean}.
PROMPT;

    public function recommendPlants(array $input): array
    {
        $prompt = "Media tanam: {$input['planting_medium']}\n"
            ."Jenis tanah: {$input['soil_type']}\n"
            ."Kota: {$input['city']}\n"
            ."Provinsi: {$input['province']}\n"
            .'Tanggal hari ini: '.now()->toDateString();

        $result = $this->generate(
            model: self::MODEL_GROUNDED,
            systemInstruction: self::PROMPT_1_SYSTEM,
            userPrompt: $prompt,
            responseSchema: [
                'type' => 'OBJECT',

                'required' => ['recommendations'],
                'properties' => [
                    'recommendations' => [
                        'type' => 'ARRAY',
                        'items' => [
                            'type' => 'OBJECT',
                            'required' => ['rank', 'plant_name', 'scores', 'reasoning', 'estimated_harvest_days'],
                            'properties' => [
                                'rank' => ['type' => 'INTEGER'],
                                'plant_name' => ['type' => 'STRING'],
                                'scores' => [
                                    'type' => 'OBJECT',
                                    'required' => ['location_climate_fit', 'productivity', 'ease_of_care'],
                                    'properties' => [
                                        'location_climate_fit' => ['type' => 'INTEGER'],
                                        'productivity' => ['type' => 'INTEGER'],
                                        'ease_of_care' => ['type' => 'INTEGER'],
                                    ],
                                ],
                                'reasoning' => ['type' => 'STRING'],
                                'estimated_harvest_days' => ['type' => 'INTEGER', 'nullable' => true],
                            ],
                        ],
                    ],
                ],
            ],
            grounded: true,
        );

        return $result['json'];
    }

    public function checkSuitability(array $input): array
    {
        $prompt = "Nama tanaman yang diinginkan pengguna: {$input['plant_name']}\n"
            ."Media tanam: {$input['planting_medium']}\n"
            ."Jenis tanah: {$input['soil_type']}\n"
            ."Kota: {$input['city']}\n"
            ."Provinsi: {$input['province']}\n"
            .'Tanggal hari ini: '.now()->toDateString();

        $result = $this->generate(
            model: self::MODEL_GROUNDED,
            systemInstruction: self::PROMPT_2_SYSTEM,
            userPrompt: $prompt,
            responseSchema: [
                'type' => 'OBJECT',
                'required' => ['plant_name', 'verdict', 'scores', 'reasoning', 'alternative_suggestion'],
                'properties' => [
                    'plant_name' => ['type' => 'STRING'],
                    'verdict' => ['type' => 'STRING', 'enum' => ['suitable', 'marginal', 'not_suitable']],
                    'scores' => [
                        'type' => 'OBJECT',
                        'required' => ['location_climate_fit', 'productivity', 'ease_of_care'],
                        'properties' => [
                            'location_climate_fit' => ['type' => 'INTEGER'],
                            'productivity' => ['type' => 'INTEGER'],
                            'ease_of_care' => ['type' => 'INTEGER'],
                        ],
                    ],
                    'reasoning' => ['type' => 'STRING'],
                    'alternative_suggestion' => ['type' => 'STRING', 'nullable' => true],
                ],
            ],
            grounded: true,
        );

        return $result['json'];
    }

    public function generateCareConfig(array $input): array
    {
        $prompt = "Nama tanaman: {$input['plant_name']}\n"
            ."Media tanam: {$input['planting_medium']}\n"
            ."Jenis tanah: {$input['soil_type']}\n"
            ."Kota: {$input['city']}\n"
            ."Provinsi: {$input['province']}";

        $phaseProperties = [
            'type' => 'STRING',
            'enum' => ['seedling', 'early_vegetative', 'late_vegetative', 'generative'],
        ];

        $wateringPhase = [
            'type' => 'OBJECT',
            'required' => ['phase', 'duration_days', 'watering_interval_days', 'watering_description', 'rain_prob_threshold', 'min_significant_rain_mm', 'rain_equivalent_full_mm', 'lookahead_days', 'max_delay_days'],
            'properties' => [
                'phase' => $phaseProperties,
                'duration_days' => ['type' => 'INTEGER', 'nullable' => true],
                'watering_interval_days' => ['type' => 'INTEGER'],
                'watering_description' => ['type' => 'STRING'],
                'rain_prob_threshold' => ['type' => 'INTEGER'],
                'min_significant_rain_mm' => ['type' => 'NUMBER'],
                'rain_equivalent_full_mm' => ['type' => 'NUMBER'],
                'lookahead_days' => ['type' => 'INTEGER'],
                'max_delay_days' => ['type' => 'INTEGER'],
            ],
        ];

        $fertilizingPhase = [
            'type' => 'OBJECT',
            'required' => ['phase', 'interval_days', 'fertilizer_description'],
            'properties' => [
                'phase' => $phaseProperties,
                'interval_days' => ['type' => 'INTEGER'],
                'fertilizer_description' => ['type' => 'STRING'],
            ],
        ];

        $result = $this->generate(
            model: self::MODEL_STANDARD,
            systemInstruction: self::PROMPT_3_SYSTEM,
            userPrompt: $prompt,
            responseSchema: [
                'type' => 'OBJECT',

                'required' => ['watering_config', 'fertilizing_config'],
                'properties' => [
                    'watering_config' => [
                        'type' => 'OBJECT',
                        'required' => ['phase_schedule'],
                        'properties' => [
                            'phase_schedule' => ['type' => 'ARRAY', 'items' => $wateringPhase],
                        ],
                    ],
                    'fertilizing_config' => [
                        'type' => 'OBJECT',
                        'required' => ['phase_schedule'],
                        'properties' => [
                            'phase_schedule' => ['type' => 'ARRAY', 'items' => $fertilizingPhase],
                        ],
                    ],
                ],
            ],
        );

        return $result['json'];
    }

    public function detectSoil(string $imageBase64, string $mimeType): array
    {
        $result = $this->generate(
            model: self::MODEL_STANDARD,
            systemInstruction: self::PROMPT_SOIL_SCAN,
            imageBase64: $imageBase64,
            mimeType: $mimeType,
            responseSchema: [
                'type' => 'OBJECT',
                'required' => ['detected_soil_type', 'ai_confidence', 'reasoning'],
                'properties' => [
                    'detected_soil_type' => ['type' => 'STRING', 'enum' => ['fertile', 'clay', 'sandy', 'chalky', 'volcanic', 'peat', 'artificial_media']],
                    'ai_confidence' => ['type' => 'NUMBER'],
                    'reasoning' => ['type' => 'STRING'],
                ],
            ],
        );

        return $result['json'];
    }

    public function detectPest(string $imageBase64, string $mimeType): array
    {
        $result = $this->generate(
            model: self::MODEL_STANDARD,
            systemInstruction: self::PROMPT_PEST_SCAN,
            imageBase64: $imageBase64,
            mimeType: $mimeType,
            responseSchema: [
                'type' => 'OBJECT',
                'required' => ['detected_pest_name', 'ai_confidence', 'recommended_action', 'is_healthy'],
                'properties' => [
                    'detected_pest_name' => ['type' => 'STRING', 'nullable' => true],
                    'ai_confidence' => ['type' => 'NUMBER', 'nullable' => true],
                    'recommended_action' => ['type' => 'STRING'],
                    'is_healthy' => ['type' => 'BOOLEAN'],
                ],
            ],
        );

        return $result['json'];
    }

    public function chat(string $systemInstruction, array $messages): string
    {
        $contents = array_map(
            fn (array $message): array => [
                'role' => $message['role'] === 'ai' ? 'model' : 'user',
                'parts' => [['text' => $message['parts']]],
            ],
            $messages,
        );

        $result = $this->generate(
            model: self::MODEL_STANDARD,
            systemInstruction: $systemInstruction,
            contentArray: $contents,
            responseSchema: null,
            temperature: 0.7,
        );

        return $result['text'];
    }

    private function generate(
        string $model,
        string $systemInstruction,
        ?string $userPrompt = null,
        ?string $imageBase64 = null,
        ?string $mimeType = null,
        ?array $contentArray = null,
        ?array $responseSchema = null,
        bool $grounded = false,
        float $temperature = 0.4,
    ): array {
        if ($contentArray === null) {
            $parts = [];

            if ($imageBase64 !== null && $mimeType !== null) {
                $parts[] = ['inlineData' => ['mimeType' => $mimeType, 'data' => $imageBase64]];
            }

            if ($userPrompt !== null) {
                $parts[] = ['text' => $userPrompt];
            }

            $contentArray = [['role' => 'user', 'parts' => $parts]];
        }

        $payload = [
            'contents' => $contentArray,
            'systemInstruction' => ['parts' => [['text' => $systemInstruction]]],
            'generationConfig' => $this->generationConfig(
                $temperature,
                $responseSchema,
                $grounded,
            ),
        ];

        if ($grounded) {

            $payload['tools'] = [['googleSearch' => (object) []]];
        }

        $modelName = config($model);

        $response = Http::acceptJson()

            ->timeout(120)
            ->post(
                config('services.gemini.base_url')."/models/{$modelName}:generateContent?key=".config('services.gemini.key'),
                $payload,
            );

        $response->throw();

        $json = $response->json();
        $candidate = $json['candidates'][0] ?? [];
        $text = $this->concatTextParts($candidate['content']['parts'] ?? []);

        if ($text === '') {

            throw new RuntimeException(
                'Gemini tidak mengembalikan teks. finishReason: '.($candidate['finishReason'] ?? 'tidak diketahui')
            );
        }

        return [
            'text' => $text,
            'json' => $this->decodeJson($text, $responseSchema !== null),
        ];
    }

    private function concatTextParts(array $parts): string
    {
        $text = '';

        foreach ($parts as $part) {
            if (isset($part['text']) && is_string($part['text'])) {
                $text .= $part['text'];
            }
        }

        return trim($text);
    }

    private function generationConfig(
        float $temperature,
        ?array $responseSchema,
        bool $grounded,
    ): array {
        $config = ['temperature' => $temperature];

        if ($responseSchema !== null) {
            $config['responseSchema'] = $responseSchema;

            if (! $grounded) {
                $config['responseMimeType'] = 'application/json';
            }
        }

        return $config;
    }

    private function decodeJson(string $text, bool $expectJson): ?array
    {
        if (! $expectJson) {
            return null;
        }

        $trimmed = trim($text);
        $decoded = json_decode($trimmed, true);

        if (! is_array($decoded)) {
            $decoded = json_decode($this->extractJson($trimmed), true);
        }

        if (! is_array($decoded)) {
            throw new RuntimeException('Respons Gemini tidak dapat diuraikan sebagai JSON.');
        }

        if (array_is_list($decoded)) {
            $decoded = $this->wrapListResponse($decoded);
        }

        return $decoded;
    }

    private function extractJson(string $text): string
    {
        if (preg_match('/```(?:json)?\s*(.*?)\s*```/s', $text, $matches) === 1) {
            return $matches[1];
        }

        $start = strpos($text, '{');
        $end = strrpos($text, '}');

        if ($start !== false && $end !== false && $end > $start) {
            return substr($text, $start, $end - $start + 1);
        }

        return $text;
    }

    private function wrapListResponse(array $items): array
    {
        if ($items === []) {
            return ['recommendations' => []];
        }

        $first = $items[0];

        if (is_array($first) && array_key_exists('verdict', $first)) {
            return $first;
        }

        return ['recommendations' => $items];
    }
}
