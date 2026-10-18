<?php

use App\Models\Location;
use App\Models\User;
use App\Models\UserPlant;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

function photoPlant(): array
{
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);

    $plant = UserPlant::factory()->create([
        'user_id' => $user->id,
        'location_id' => $location->id,
    ]);

    return [$user, $plant];
}

test('user dapat mengunggah foto tanaman', function () {
    Storage::fake('public');
    [$user, $plant] = photoPlant();

    $image = UploadedFile::fake()->image('tanaman.jpg', 100, 100);

    $response = $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/photo", ['image' => $image])
        ->assertStatus(200);

    $path = $plant->fresh()->photo;
    expect($path)->toStartWith('photos/plants/');
    Storage::disk('public')->assertExists($path);

    $response->assertJsonPath('photo_url', $plant->fresh()->photoUrl());
});

test('unggah foto tanaman menolak file bukan gambar', function () {
    Storage::fake('public');
    [$user, $plant] = photoPlant();

    $file = UploadedFile::fake()->create('catatan.txt', 10);

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/photo", ['image' => $file])
        ->assertStatus(422);

    expect($plant->fresh()->photo)->toBeNull();
});

test('foto tanaman lama terhapus setelah unggah baru', function () {
    Storage::fake('public');
    [$user, $plant] = photoPlant();

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/photo", [
            'image' => UploadedFile::fake()->image('satu.jpg', 100, 100),
        ])
        ->assertStatus(200);
    $oldPath = $plant->fresh()->photo;

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/photo", [
            'image' => UploadedFile::fake()->image('dua.jpg', 100, 100),
        ])
        ->assertStatus(200);
    $newPath = $plant->fresh()->photo;

    expect($newPath)->not->toBe($oldPath);
    Storage::disk('public')->assertExists($newPath);
    Storage::disk('public')->assertMissing($oldPath);
});

test('user tidak dapat mengunggah foto tanaman milik orang lain', function () {
    Storage::fake('public');
    [, $plant] = photoPlant();
    $intruder = User::factory()->create();

    $this->actingAs($intruder, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/photo", [
            'image' => UploadedFile::fake()->image('hack.jpg', 100, 100),
        ])
        ->assertStatus(403);

    expect($plant->fresh()->photo)->toBeNull();
});

test('resource tanaman memuat photo_url setelah unggah', function () {
    Storage::fake('public');
    [$user, $plant] = photoPlant();

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/photo", [
            'image' => UploadedFile::fake()->image('tanaman.jpg', 100, 100),
        ])
        ->assertStatus(200);

    $response = $this->actingAs($user, 'sanctum')
        ->getJson("/api/plants/{$plant->id}")
        ->assertStatus(200);

    expect($response->json('plant.photo_url'))->toContain('photos/plants/');
});

test('resource tanaman mengirim photo_url null tanpa foto', function () {
    [$user, $plant] = photoPlant();

    $this->actingAs($user, 'sanctum')
        ->getJson("/api/plants/{$plant->id}")
        ->assertStatus(200)
        ->assertJsonPath('plant.photo_url', null);
});
