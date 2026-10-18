<?php

use App\Services\WeatherApiService;
use App\Models\Location;
use App\Models\User;
use App\Models\UserPlant;
use App\Models\WateringLog;
use App\Models\WeatherCache;

function createActivePlant(array $plantOverrides = [], array $locationOverrides = []): array
{
    $user = User::factory()->create();
    $location = Location::factory()->create(array_merge([
        'user_id' => $user->id,
        'city' => 'Surabaya',
        'province' => 'Jawa Timur',
    ], $locationOverrides));

    $plant = UserPlant::factory()->create(array_merge([
        'user_id' => $user->id,
        'location_id' => $location->id,
        'last_watered_date' => now()->subDays(2)->toDateString(),
    ], $plantOverrides));

    return [$user, $plant];
}

function stubWeather(array $config): array
{
    $today = WeatherCache::factory()->make($config['today'] ?? [
        'rainfall_mm' => 0,
        'rain_probability_percent' => 0,
        'condition' => 'sunny',
    ]);

    $lookahead = collect($config['lookahead'] ?? []);

    test()->mock(WeatherApiService::class, function ($mock) use ($today, $lookahead) {
        $mock->shouldReceive('forecast7Days')->andReturn([]);
        $mock->shouldReceive('upsertCache')->andReturnNull();
        $mock->shouldReceive('getCacheForDate')->andReturn($today);
        $mock->shouldReceive('getCacheForRange')->andReturn($lookahead);
    });

    return [];
}

test('cabang 1: hujan penuh mencatat skip_rain menunggu konfirmasi', function () {
    [$user, $plant] = createActivePlant();

    stubWeather([
        'today' => [
            'rainfall_mm' => 12,
            'rain_probability_percent' => 90,
            'condition' => 'moderate_rain',
        ],
    ]);

    $this->artisan('agronoma:daily-processing')->assertSuccessful();

    $this->assertDatabaseHas('watering_logs', [
        'user_plant_id' => $plant->id,
        'scheduled_date' => now()->toDateString(),
        'status' => 'skip_rain',
        'rain_confirmed' => 'not_answered',
    ]);

    $this->assertDatabaseHas('notifications', [
        'user_id' => $user->id,
        'type' => 'watering',
    ]);
});

test('cabang 2: hujan sebagian menggeser due date dan menunggu feedback', function () {
    [$user, $plant] = createActivePlant();

    stubWeather([
        'today' => [
            'rainfall_mm' => 7,
            'rain_probability_percent' => 70,
            'condition' => 'light_rain',
        ],
    ]);

    $this->artisan('agronoma:daily-processing')->assertSuccessful();

    $this->assertDatabaseHas('watering_logs', [
        'user_plant_id' => $plant->id,
        'status' => 'partial_rain',
        'user_moisture_feedback' => 'not_answered',
    ]);

    $this->assertDatabaseHas('user_plants', [
        'id' => $plant->id,
        'adjusted_due_date' => now()->addDay()->toDateString(),
    ]);
});

test('cabang 3: hujan diprediksi mendadak menunda penyiraman', function () {
    [$user, $plant] = createActivePlant();

    stubWeather([
        'today' => [
            'rainfall_mm' => 0,
            'rain_probability_percent' => 10,
            'condition' => 'sunny',
        ],
        'lookahead' => [
            WeatherCache::factory()->make([
                'date' => now()->addDay()->toDateString(),
                'rain_probability_percent' => 60,
                'rainfall_mm' => 2,
            ]),
        ],
    ]);

    $this->artisan('agronoma:daily-processing')->assertSuccessful();

    $this->assertDatabaseHas('watering_logs', [
        'user_plant_id' => $plant->id,
        'status' => 'delayed_rain_expected',
    ]);

    $this->assertDatabaseHas('user_plants', [
        'id' => $plant->id,
        'adjusted_due_date' => now()->addDay()->toDateString(),
        'delay_streak_days' => 1,
    ]);
});

test('cabang 4: prediksi hujan meleset saat delay maksimal tercapai, wajib siram', function () {
    [$user, $plant] = createActivePlant([
        'delay_streak_days' => 1,
    ]);

    stubWeather([
        'lookahead' => [
            WeatherCache::factory()->make([
                'date' => now()->addDay()->toDateString(),
                'rain_probability_percent' => 60,
                'rainfall_mm' => 2,
            ]),
        ],
    ]);

    $this->artisan('agronoma:daily-processing')->assertSuccessful();

    $this->assertDatabaseHas('watering_logs', [
        'user_plant_id' => $plant->id,
        'status' => 'need_water',
        'delay_streak_at_time' => 1,
    ]);

    $this->assertDatabaseHas('user_plants', [
        'id' => $plant->id,
        'delay_streak_days' => 0,
    ]);
});

test('cabang 4: tanpa prediksi hujan, tanaman wajib disiram', function () {
    [$user, $plant] = createActivePlant();

    stubWeather([
        'lookahead' => [
            WeatherCache::factory()->make([
                'date' => now()->addDay()->toDateString(),
                'rain_probability_percent' => 10,
                'rainfall_mm' => 0,
            ]),
        ],
    ]);

    $this->artisan('agronoma:daily-processing')->assertSuccessful();

    $this->assertDatabaseHas('watering_logs', [
        'user_plant_id' => $plant->id,
        'status' => 'need_water',
        'delay_streak_at_time' => 0,
    ]);
});

test('cronjob menyelesaikan konfirmasi hujan yang menggantung dari kemarin', function () {
    [$user, $plant] = createActivePlant();

    $skipLog = WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'skip_rain',
        'rain_confirmed' => 'not_answered',
        'scheduled_date' => now()->subDay()->toDateString(),
    ]);

    $partialLog = WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'partial_rain',
        'user_moisture_feedback' => 'not_answered',
        'scheduled_date' => now()->subDay()->toDateString(),
    ]);

    stubWeather([]);

    $this->artisan('agronoma:daily-processing')->assertSuccessful();

    $this->assertDatabaseHas('watering_logs', [
        'id' => $skipLog->id,
        'rain_confirmed' => 'yes',
    ]);

    $this->assertDatabaseHas('user_plants', [
        'id' => $plant->id,
        'last_watered_date' => now()->subDay()->toDateString(),
    ]);

    $this->assertDatabaseHas('watering_logs', [
        'id' => $partialLog->id,
        'user_moisture_feedback' => 'moist',
    ]);
});

test('cronjob mendeteksi pergantian fase dan mengirim notifikasi phase_change', function () {
    [$user, $plant] = createActivePlant([
        'current_phase' => 'seedling',
        'phase_start_date' => now()->subDays(11)->toDateString(),
    ]);

    stubWeather([]);

    $this->artisan('agronoma:daily-processing')->assertSuccessful();

    $this->assertDatabaseHas('user_plants', [
        'id' => $plant->id,
        'current_phase' => 'early_vegetative',
    ]);

    $this->assertDatabaseHas('notifications', [
        'user_id' => $user->id,
        'type' => 'phase_change',
    ]);
});
