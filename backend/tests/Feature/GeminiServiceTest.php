<?php

use App\Services\GeminiService;
use Illuminate\Support\Facades\Http;

function geminiFakeResponse(string $text, int $status = 200): void
{
    Http::fake(fn () => Http::response(
        $status === 200
            ? ['candidates' => [['content' => ['parts' => [['text' => $text]]]]]]
            : ['error' => ['message' => 'gagal']],
        $status,
    ));
}

function geminiRequestPertama(): array
{
    $recorded = Http::recorded();

    expect($recorded)->not->toBeEmpty();

    [$request] = $recorded->first();

    return ['url' => $request->url(), 'body' => $request->data()];
}

function schemaPunyaTipeArray(array $schema): bool
{
    foreach ($schema as $key => $value) {
        if ($key === 'type' && is_array($value)) {
            return true;
        }

        if (is_array($value) && schemaPunyaTipeArray($value)) {
            return true;
        }
    }

    return false;
}

$inputWizard = [
    'planting_medium' => 'pot',
    'soil_type' => 'fertile',
    'city' => 'Surabaya',
    'province' => 'Jawa Timur',
];

test('bug #1: kunci API dikirim lewat query string, bukan di body', function () use ($inputWizard) {
    geminiFakeResponse('{"recommendations":[]}');

    app(GeminiService::class)->recommendPlants($inputWizard);

    ['url' => $url, 'body' => $body] = geminiRequestPertama();

    expect($url)->toContain(':generateContent?key=');
    expect($url)->toContain('/models/');
    expect($body)->toHaveKey('contents');
    expect($body)->toHaveKey('systemInstruction');
    expect($body)->not->toHaveKey('key');
});

test('bug #2: grounding memakai googleSearch tanpa responseMimeType JSON', function () use ($inputWizard) {
    geminiFakeResponse('{"recommendations":[]}');

    app(GeminiService::class)->recommendPlants($inputWizard);

    ['body' => $body] = geminiRequestPertama();

    expect($body['tools'][0])->toHaveKey('googleSearch');

    expect(json_encode($body['tools'][0]['googleSearch']))->toBe('{}');
    expect($body['generationConfig'])->toHaveKey('responseSchema');
    expect($body['generationConfig'])->not->toHaveKey('responseMimeType');
});

test('bug #2: pemanggilan tanpa grounding tetap pakai Structured Output penuh', function () {
    geminiFakeResponse('{"detected_soil_type":"fertile","ai_confidence":90,"reasoning":"ok"}');

    app(GeminiService::class)->detectSoil(base64_encode('gambar-palsu'), 'image/jpeg');

    ['body' => $body] = geminiRequestPertama();

    expect($body['generationConfig']['responseMimeType'])->toBe('application/json');
    expect($body)->not->toHaveKey('tools');
});

test('bug #3: schema tidak memakai tipe array dan memakai nullable', function () use ($inputWizard) {
    geminiFakeResponse('{"recommendations":[]}');
    app(GeminiService::class)->recommendPlants($inputWizard);
    $schemaGrounded = geminiRequestPertama()['body']['generationConfig']['responseSchema'];

    Http::fake();
    geminiFakeResponse('{"watering_config":{"phase_schedule":[]},"fertilizing_config":{"phase_schedule":[]}}');
    app(GeminiService::class)->generateCareConfig($inputWizard + ['plant_name' => 'Cabai Rawit']);
    $schemaCare = geminiRequestPertama()['body']['generationConfig']['responseSchema'];

    geminiFakeResponse('{"detected_pest_name":null,"ai_confidence":null,"recommended_action":"ok","is_healthy":true}');
    app(GeminiService::class)->detectPest(base64_encode('gambar-palsu'), 'image/jpeg');
    $schemaPest = geminiRequestPertama()['body']['generationConfig']['responseSchema'];

    foreach ([$schemaGrounded, $schemaCare, $schemaPest] as $schema) {
        expect(schemaPunyaTipeArray($schema))->toBeFalse();
    }

    expect($schemaPest['properties']['detected_pest_name'])
        ->toBe(['type' => 'STRING', 'nullable' => true]);
    expect($schemaCare['properties']['watering_config']['properties']['phase_schedule']['items']['properties']['duration_days'])
        ->toBe(['type' => 'INTEGER', 'nullable' => true]);
});

test('bug #2: balasan grounded yang terbungkus code fence tetap bisa diurai', function () use ($inputWizard) {
    $json = '{"recommendations":[{"rank":1,"plant_name":"Cabai Rawit","scores":{"location_climate_fit":9,"productivity":8,"ease_of_care":7},"reasoning":"cocok","estimated_harvest_days":90}]}';
    geminiFakeResponse("```json\n{$json}\n```");

    $hasil = app(GeminiService::class)->recommendPlants($inputWizard);

    expect($hasil['recommendations'])->toHaveCount(1);
    expect($hasil['recommendations'][0]['plant_name'])->toBe('Cabai Rawit');
});

test('bug #2: balasan grounded berupa array telanjang dibungkus ke kunci recommendations', function () use ($inputWizard) {
    geminiFakeResponse('[{"rank":1,"plant_name":"Bayam","scores":{"location_climate_fit":8,"productivity":7,"ease_of_care":9},"reasoning":"cocok","estimated_harvest_days":30}]');

    $hasil = app(GeminiService::class)->recommendPlants($inputWizard);

    expect($hasil)->toHaveKey('recommendations');
    expect($hasil['recommendations'][0]['plant_name'])->toBe('Bayam');
});

test('balasan tanpa teks melempar pesan yang menjelaskan finishReason', function () use ($inputWizard) {
    Http::fake(fn () => Http::response([
        'candidates' => [['finishReason' => 'SAFETY', 'content' => ['parts' => []]]],
    ]));

    app(GeminiService::class)->recommendPlants($inputWizard);
})->throws(RuntimeException::class, 'finishReason: SAFETY');
