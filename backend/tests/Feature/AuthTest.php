<?php

use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;

test('pengguna dapat registrasi dan menerima token', function () {
    $response = $this->postJson('/api/register', [
        'name' => 'Budi Santoso',
        'email' => 'budi@example.com',
        'password' => 'rahasia123',
        'password_confirmation' => 'rahasia123',
    ]);

    $response->assertStatus(201)
        ->assertJsonStructure(['user' => ['id', 'name', 'email'], 'token']);

    $this->assertDatabaseHas('users', ['email' => 'budi@example.com']);
});

test('registrasi gagal validasi saat email sudah dipakai', function () {
    User::factory()->create(['email' => 'dipakai@example.com']);

    $this->postJson('/api/register', [
        'name' => 'Budi',
        'email' => 'dipakai@example.com',
        'password' => 'rahasia123',
        'password_confirmation' => 'rahasia123',
    ])->assertStatus(422)
        ->assertJsonValidationErrors('email');
});

test('pengguna dapat login', function () {
    $user = User::factory()->create(['password' => bcrypt('rahasia123')]);

    $this->postJson('/api/login', [
        'email' => $user->email,
        'password' => 'rahasia123',
    ])->assertStatus(200)
        ->assertJsonStructure(['user', 'token']);
});

test('login dengan kredensial salah ditolak', function () {
    $user = User::factory()->create(['password' => bcrypt('rahasia123')]);

    $this->postJson('/api/login', [
        'email' => $user->email,
        'password' => 'salah-salah',
    ])->assertStatus(422)
        ->assertJsonStructure(['message', 'errors']);
});

test('logout mencabut token aktif', function () {
    $user = User::factory()->create();
    $token = $user->createToken('mobile')->plainTextToken;

    $this->withToken($token)->postJson('/api/logout')->assertStatus(200);
});

test('endpoint terproteksi auth:sanctum', function () {
    $this->getJson('/api/locations')->assertStatus(401);
});

test('user dapat menyimpan push token device', function () {
    $user = User::factory()->create();

    $this->actingAs($user, 'sanctum')
        ->postJson('/api/device-token', ['push_token' => 'fcm-token-abc'])
        ->assertStatus(200);

    $this->assertDatabaseHas('users', [
        'id' => $user->id,
        'push_token' => 'fcm-token-abc',
    ]);
});

test('user dapat mengunggah foto profil', function () {
    Storage::fake('public');
    $user = User::factory()->create();

    $image = UploadedFile::fake()->image('profil.jpg', 100, 100);

    $response = $this->actingAs($user, 'sanctum')
        ->postJson('/api/profile/photo', ['image' => $image])
        ->assertStatus(200);

    $path = $user->fresh()->photo;
    expect($path)->toStartWith('photos/profile/');
    Storage::disk('public')->assertExists($path);

    $url = $user->fresh()->photoUrl();
    expect($url)->toContain($path);
});

test('unggah foto profil menolak file bukan gambar', function () {
    Storage::fake('public');
    $user = User::factory()->create();

    $file = UploadedFile::fake()->create('catatan.txt', 10);

    $this->actingAs($user, 'sanctum')
        ->postJson('/api/profile/photo', ['image' => $file])
        ->assertStatus(422);
});

test('foto profil lama terhapus setelah unggah baru', function () {
    Storage::fake('public');
    $user = User::factory()->create();

    $first = UploadedFile::fake()->image('satu.jpg', 100, 100);
    $this->actingAs($user, 'sanctum')
        ->postJson('/api/profile/photo', ['image' => $first])
        ->assertStatus(200);
    $oldPath = $user->fresh()->photo;

    $second = UploadedFile::fake()->image('dua.jpg', 100, 100);
    $this->actingAs($user, 'sanctum')
        ->postJson('/api/profile/photo', ['image' => $second])
        ->assertStatus(200);
    $newPath = $user->fresh()->photo;

    Storage::disk('public')->assertExists($newPath);
    Storage::disk('public')->assertMissing($oldPath);
});
