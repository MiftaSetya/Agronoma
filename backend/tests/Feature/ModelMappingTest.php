<?php

use App\Models\ChatMessage;
use App\Models\ChatSession;
use App\Models\PestScanHistory;
use App\Models\SoilScanHistory;
use App\Models\User;

test('model scan memakai nama tabel tunggal sesuai migrasi', function () {
    expect((new SoilScanHistory)->getTable())->toBe('soil_scan_history');
    expect((new PestScanHistory)->getTable())->toBe('pest_scan_history');
});

test('riwayat scan tanah dapat disimpan dan dibaca kembali', function () {
    $user = User::factory()->create();

    SoilScanHistory::create([
        'user_id' => $user->id,
        'image_url' => 'http://localhost/storage/scans/soil/contoh.jpg',
        'detected_soil_type' => 'fertile',
        'ai_confidence' => 92.5,
    ]);

    $riwayat = $user->soilScanHistories()->first();

    expect($riwayat)->not->toBeNull();
    expect($riwayat->detected_soil_type)->toBe('fertile');
    expect($riwayat->ai_confidence)->toBe(92.5);
});

test('riwayat scan hama dapat disimpan dan dibaca kembali', function () {
    $user = User::factory()->create();

    PestScanHistory::create([
        'user_id' => $user->id,
        'image_url' => 'http://localhost/storage/scans/pest/contoh.jpg',
        'detected_pest_name' => null,
        'ai_confidence' => 98.5,
        'ai_raw_response' => ['is_healthy' => true],
        'recommended_action' => 'Lanjutkan perawatan rutin.',
    ]);

    $riwayat = $user->pestScanHistories()->first();

    expect($riwayat)->not->toBeNull();
    expect($riwayat->recommended_action)->toBe('Lanjutkan perawatan rutin.');
    expect($riwayat->ai_raw_response)->toBe(['is_healthy' => true]);
});

test('relasi percakapan memakai kolom session_id', function () {
    $user = User::factory()->create();
    $session = $user->chatSessions()->create(['context_plant_id' => null]);

    ChatMessage::create([
        'session_id' => $session->id,
        'role' => 'user',
        'content' => 'Berapa kali menyiram cabai?',
    ]);

    $pesan = $session->messages()->get();

    expect($pesan)->toHaveCount(1);
    expect($pesan->first()->content)->toBe('Berapa kali menyiram cabai?');
    expect($pesan->first()->session->id)->toBe($session->id);
});
