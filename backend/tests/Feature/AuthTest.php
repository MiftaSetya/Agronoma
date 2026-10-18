<?php

use App\Models\User;

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
