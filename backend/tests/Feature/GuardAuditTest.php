<?php

use App\Models\Location;
use App\Models\User;
use App\Models\UserPlant;
use App\Services\GeminiService;

function guardPlant(array $overrides = []): array
{
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);
    $plant = UserPlant::factory()->create(array_merge([
        'user_id' => $user->id,
        'location_id' => $location->id,
        'status' => 'active',
    ], $overrides));

    return [$user, $plant];
}

test('id non-numerik dibalas 404, bukan 500', function () {
    [$user] = guardPlant();

    foreach ([
        '/api/plants/abc',
        '/api/plants/abc/weather',
        '/api/plants/abc/care-calendar',
    ] as $path) {
        $this->actingAs($user, 'sanctum')->getJson($path)->assertStatus(404);
    }

    $this->actingAs($user, 'sanctum')
        ->patchJson('/api/plants/abc', ['status' => 'active'])
        ->assertStatus(404);

    $this->actingAs($user, 'sanctum')
        ->deleteJson('/api/locations/abc')
        ->assertStatus(404);

    $this->actingAs($user, 'sanctum')
        ->postJson('/api/plants/abc/watering/complete')
        ->assertStatus(404);
});

test('tanaman yang diarsipkan tidak bisa disiram lagi', function () {
    [$user, $plant] = guardPlant(['status' => 'archived']);

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/watering/complete")
        ->assertStatus(409);

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/fertilizing/complete")
        ->assertStatus(409);

    $this->assertDatabaseCount('watering_logs', 0);
    $this->assertDatabaseCount('fertilizing_logs', 0);
});

test('tanaman aktif tetap bisa disiram', function () {
    [$user, $plant] = guardPlant();

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/watering/complete")
        ->assertStatus(200);
});

test('tanggal tanam di masa depan ditolak 422', function () {
    $this->mock(GeminiService::class, function ($mock) {
        $mock->shouldReceive('generateCareConfig')->never();
    });

    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);

    $this->actingAs($user, 'sanctum')
        ->postJson('/api/plants', [
            'plant_name' => 'Kangkung',
            'location_id' => $location->id,
            'planting_medium' => 'pot',
            'soil_type' => 'fertile',
            'current_phase' => 'seedling',
            'planting_date' => now()->addDays(3)->toDateString(),
        ])
        ->assertStatus(422);
});

test('tanggal tanam hari ini tetap diterima', function () {
    $this->mock(GeminiService::class, function ($mock) {
        $mock->shouldReceive('generateCareConfig')->once()->andReturn([
            'watering_config' => wateringConfig(),
            'fertilizing_config' => fertilizingConfig(),
        ]);
    });

    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);

    $this->actingAs($user, 'sanctum')
        ->postJson('/api/plants', [
            'plant_name' => 'Kangkung',
            'location_id' => $location->id,
            'planting_medium' => 'pot',
            'soil_type' => 'fertile',
            'current_phase' => 'seedling',
            'planting_date' => now()->toDateString(),
        ])
        ->assertStatus(201);
});
