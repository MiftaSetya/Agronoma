<?php

use App\Models\Location;
use App\Models\User;

test('index hanya menampilkan lokasi milik user login', function () {
    $user = User::factory()->create();
    $otherUser = User::factory()->create();

    $myLocation = Location::factory()->create(['user_id' => $user->id]);
    Location::factory()->create(['user_id' => $otherUser->id]);

    $this->actingAs($user, 'sanctum')
        ->getJson('/api/locations')
        ->assertStatus(200)
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', $myLocation->id);
});

test('user dapat membuat lokasi baru', function () {
    $user = User::factory()->create();

    $this->actingAs($user, 'sanctum')
        ->postJson('/api/locations', [
            'label' => 'Taman Belakang',
            'city' => 'Bandung',
            'province' => 'Jawa Barat',
        ])->assertStatus(201)
        ->assertJsonPath('location.city', 'Bandung');
});

test('user dapat mengupdate lokasi miliknya sendiri', function () {
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/locations/{$location->id}", ['label' => 'Ganti Nama'])
        ->assertStatus(200)
        ->assertJsonPath('location.label', 'Ganti Nama');
});

test('user tidak dapat mengupdate lokasi milik orang lain', function () {
    $user = User::factory()->create();
    $otherLocation = Location::factory()->create();

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/locations/{$otherLocation->id}", ['label' => 'Hack'])
        ->assertStatus(403);
});

test('user dapat menghapus lokasi miliknya sendiri', function () {
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);

    $this->actingAs($user, 'sanctum')
        ->deleteJson("/api/locations/{$location->id}")
        ->assertStatus(204);

    $this->assertDatabaseMissing('locations', ['id' => $location->id]);
});
