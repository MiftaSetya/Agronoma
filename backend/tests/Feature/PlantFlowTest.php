<?php

use App\Services\GeminiService;
use App\Models\Location;
use App\Models\User;
use App\Models\UserPlant;
use App\Models\WateringLog;
use App\Models\WeatherCache;

function wateringConfig(): array
{
    return [
        'phase_schedule' => [
            ['phase' => 'seedling', 'duration_days' => 10, 'watering_interval_days' => 1, 'watering_description' => 'Siram tipis', 'rain_prob_threshold' => 40, 'min_significant_rain_mm' => 5, 'rain_equivalent_full_mm' => 10, 'lookahead_days' => 2, 'max_delay_days' => 1],
            ['phase' => 'early_vegetative', 'duration_days' => 20, 'watering_interval_days' => 2, 'watering_description' => 'Siram merata', 'rain_prob_threshold' => 45, 'min_significant_rain_mm' => 8, 'rain_equivalent_full_mm' => 15, 'lookahead_days' => 2, 'max_delay_days' => 2],
            ['phase' => 'late_vegetative', 'duration_days' => 25, 'watering_interval_days' => 3, 'watering_description' => 'Siram rutin', 'rain_prob_threshold' => 50, 'min_significant_rain_mm' => 10, 'rain_equivalent_full_mm' => 18, 'lookahead_days' => 2, 'max_delay_days' => 4],
            ['phase' => 'generative', 'duration_days' => null, 'watering_interval_days' => 2, 'watering_description' => 'Siram konsisten', 'rain_prob_threshold' => 35, 'min_significant_rain_mm' => 6, 'rain_equivalent_full_mm' => 12, 'lookahead_days' => 2, 'max_delay_days' => 1],
        ],
    ];
}

function fertilizingConfig(): array
{
    return [
        'phase_schedule' => [
            ['phase' => 'early_vegetative', 'interval_days' => 14, 'fertilizer_description' => 'NPK seimbang'],
            ['phase' => 'generative', 'interval_days' => 12, 'fertilizer_description' => 'NPK tinggi Kalium'],
        ],
    ];
}

test('wizard dapat membuat plant dan generate config via Gemini', function () {
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
            'location_id' => $location->id,
            'plant_name' => 'Bayam',
            'planting_medium' => 'pot',
            'soil_type' => 'fertile',
            'current_phase' => 'seedling',
            'planting_date' => now()->toDateString(),
        ])->assertStatus(201)
        ->assertJsonPath('plant.plant_name', 'Bayam')
        ->assertJsonPath('plant.current_phase', 'seedling');

    $this->assertDatabaseHas('user_plants', [
        'plant_name' => 'Bayam',
        'watering_config' => json_encode(wateringConfig(), JSON_UNESCAPED_UNICODE),
    ]);
});

test('wizard menolak membuat plant di lokasi milik orang lain', function () {
    $user = User::factory()->create();
    $otherLocation = Location::factory()->create();

    $this->actingAs($user, 'sanctum')
        ->postJson('/api/plants', [
            'location_id' => $otherLocation->id,
            'plant_name' => 'Bayam',
            'planting_medium' => 'pot',
            'soil_type' => 'fertile',
            'current_phase' => 'seedling',
            'planting_date' => now()->toDateString(),
        ])->assertStatus(403);
});

test('daftar tanaman menyertakan badge status perlu_disiram', function () {
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);

    UserPlant::factory()->create([
        'user_id' => $user->id,
        'location_id' => $location->id,
        'last_watered_date' => now()->subDays(2)->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->getJson('/api/plants')
        ->assertStatus(200)
        ->assertJsonPath('data.0.badge_status', 'perlu_disiram');
});

test('complete watering mencatat log dan update last_watered_date', function () {
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);
    $plant = UserPlant::factory()->create([
        'user_id' => $user->id,
        'location_id' => $location->id,
        'last_watered_date' => now()->subDays(2)->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/watering/complete")
        ->assertStatus(200)
        ->assertJsonPath('watering_log.status', 'watered');

    $this->assertDatabaseHas('user_plants', [
        'id' => $plant->id,
        'last_watered_date' => now()->toDateString(),
    ]);
});

test('complete watering dua kali di hari yang sama menolak (409)', function () {
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);
    $plant = UserPlant::factory()->create([
        'user_id' => $user->id,
        'location_id' => $location->id,
    ]);

    WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'watered',
        'scheduled_date' => now()->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/watering/complete")
        ->assertStatus(409);
});

test('postpone watering menambah delay streak dan menggeser due date', function () {
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);
    $plant = UserPlant::factory()->create([
        'user_id' => $user->id,
        'location_id' => $location->id,
    ]);

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/watering/postpone")
        ->assertStatus(200)
        ->assertJsonPath('watering_log.status', 'delayed_rain_expected');

    $this->assertDatabaseHas('user_plants', [
        'id' => $plant->id,
        'adjusted_due_date' => now()->addDay()->toDateString(),
        'delay_streak_days' => 1,
    ]);
});

test('rain confirm yes mengesahkan curah hujan dan update last_watered_date', function () {
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);
    $plant = UserPlant::factory()->create([
        'user_id' => $user->id,
        'location_id' => $location->id,
    ]);

    $log = WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'skip_rain',
        'rain_confirmed' => 'not_answered',
        'scheduled_date' => now()->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/watering-logs/{$log->id}/rain-confirm", ['rain_confirmed' => 'yes'])
        ->assertStatus(200)
        ->assertJsonPath('watering_log.rain_confirmed', 'yes');

    $this->assertDatabaseHas('user_plants', [
        'id' => $plant->id,
        'last_watered_date' => now()->toDateString(),
    ]);
});

test('rain confirm no memicu status need_water hari itu juga', function () {
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);
    $plant = UserPlant::factory()->create([
        'user_id' => $user->id,
        'location_id' => $location->id,
    ]);

    $log = WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'skip_rain',
        'rain_confirmed' => 'not_answered',
        'scheduled_date' => now()->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/watering-logs/{$log->id}/rain-confirm", ['rain_confirmed' => 'no'])
        ->assertStatus(200);

    $this->assertDatabaseHas('watering_logs', [
        'user_plant_id' => $plant->id,
        'scheduled_date' => now()->toDateString(),
        'status' => 'need_water',
    ]);
});

test('kalender perawatan memetakan status per hari dari log', function () {
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);
    $plant = UserPlant::factory()->create([
        'user_id' => $user->id,
        'location_id' => $location->id,
    ]);

    WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'watered',
        'scheduled_date' => now()->toDateString(),
    ]);

    $month = now()->format('Y-m');

    $this->actingAs($user, 'sanctum')
        ->getJson("/api/plants/{$plant->id}/care-calendar?month={$month}")
        ->assertStatus(200)
        ->assertJsonPath('days.'.(now()->day - 1).'.watering_status', 'watered');
});

test('weather tanaman mengembalikan prakiraan dari weather cache', function () {
    $user = User::factory()->create();
    $location = Location::factory()->create([
        'user_id' => $user->id,
        'city' => 'Surabaya',
        'province' => 'Jawa Timur',
    ]);
    $plant = UserPlant::factory()->create([
        'user_id' => $user->id,
        'location_id' => $location->id,
    ]);

    foreach (range(0, 6) as $offset) {
        WeatherCache::factory()->create([
            'city' => 'Surabaya',
            'province' => 'Jawa Timur',
            'date' => now()->addDays($offset)->toDateString(),
        ]);
    }

    $this->actingAs($user, 'sanctum')
        ->getJson("/api/plants/{$plant->id}/weather")
        ->assertStatus(200)
        ->assertJsonCount(7, 'forecast');
});
