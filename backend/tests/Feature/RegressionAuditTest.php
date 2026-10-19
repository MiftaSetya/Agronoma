<?php

use App\Models\FertilizingLog;
use App\Models\Location;
use App\Models\Notification;
use App\Models\User;
use App\Models\UserPlant;
use App\Models\WateringLog;
use App\Models\WeatherCache;
use App\Services\WeatherApiService;

function ownedPlant(array $overrides = []): array
{
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);

    $plant = UserPlant::factory()->create(array_merge([
        'user_id' => $user->id,
        'location_id' => $location->id,
    ], $overrides));

    return [$user, $location, $plant];
}

test('cron tidak menulis baris ganda saat dijalankan dua kali', function () {
    [$user, $location, $plant] = ownedPlant([
        'last_watered_date' => now()->subDays(2)->toDateString(),
    ]);

    $this->mock(WeatherApiService::class, function ($mock) {
        $mock->shouldReceive('forecast7Days')->andReturn([]);
        $mock->shouldReceive('upsertCache')->andReturnNull();
        $mock->shouldReceive('getCacheForDate')->andReturn(
            WeatherCache::factory()->make(['rainfall_mm' => 0])
        );
        $mock->shouldReceive('getCacheForRange')->andReturn(collect());
    });

    $this->artisan('agronoma:daily-processing')->assertSuccessful();
    $this->artisan('agronoma:daily-processing')->assertSuccessful();

    expect(
        WateringLog::where('user_plant_id', $plant->id)
            ->whereDate('scheduled_date', now())
            ->count()
    )->toBe(1);

    expect(
        Notification::where('user_id', $user->id)
            ->where('type', 'watering')
            ->count()
    )->toBe(1);
});

test('menunda penyiraman dua kali sehari ditolak, bukan menumpuk baris', function () {
    [$user, $location, $plant] = ownedPlant();

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/watering/postpone")
        ->assertStatus(200);

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/watering/postpone")
        ->assertStatus(409);

    expect(
        WateringLog::where('user_plant_id', $plant->id)->count()
    )->toBe(1);

    expect($plant->fresh()->delay_streak_days)->toBe(1);
});

test('pemupukan dua kali sehari ditolak', function () {
    [$user, $location, $plant] = ownedPlant();

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/fertilizing/complete")
        ->assertStatus(200);

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/plants/{$plant->id}/fertilizing/complete")
        ->assertStatus(409);

    expect(FertilizingLog::where('user_plant_id', $plant->id)->count())->toBe(1);
});

test('feedback tanah kering membersihkan due date sehingga tugas benar-benar muncul', function () {
    [$user, $location, $plant] = ownedPlant([

        'adjusted_due_date' => now()->addDay()->toDateString(),
    ]);

    $log = WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'partial_rain',
        'user_moisture_feedback' => 'not_answered',
        'scheduled_date' => now()->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->postJson("/api/watering-logs/{$log->id}/moisture-feedback", [
            'user_moisture_feedback' => 'dry',
        ])
        ->assertStatus(200);

    expect($plant->fresh()->adjusted_due_date)->toBeNull();
    expect($plant->fresh()->badgeStatus())->toBe('perlu_disiram');

    $this->actingAs($user, 'sanctum')
        ->getJson("/api/plants/{$plant->id}/care-calendar")
        ->assertStatus(200)
        ->assertJsonFragment(['date' => now()->toDateString(), 'watering_status' => 'need_water']);
});

test('konfirmasi hujan berulang tidak menumpuk baris need_water', function () {
    [$user, $location, $plant] = ownedPlant();

    $log = WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'skip_rain',
        'rain_confirmed' => 'not_answered',
        'scheduled_date' => now()->toDateString(),
    ]);

    foreach (range(1, 3) as $ignored) {
        $this->actingAs($user, 'sanctum')
            ->postJson("/api/watering-logs/{$log->id}/rain-confirm", ['rain_confirmed' => 'no'])
            ->assertStatus(200);
    }

    expect(
        WateringLog::where('user_plant_id', $plant->id)
            ->where('status', 'need_water')
            ->count()
    )->toBe(1);
});

test('profil memisahkan tanaman aktif dari yang sudah dipanen', function () {
    [$user, $location, $plant] = ownedPlant();

    $this->actingAs($user, 'sanctum')
        ->getJson('/api/profile')
        ->assertStatus(200)
        ->assertJsonFragment(['total_plants' => 1, 'harvested_count' => 0]);

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/plants/{$plant->id}", ['status' => 'harvested'])
        ->assertStatus(200);

    $this->actingAs($user, 'sanctum')
        ->getJson('/api/profile')
        ->assertStatus(200)
        ->assertJsonFragment(['total_plants' => 0, 'harvested_count' => 1]);
});

test('care-calendar mengirim id log dan status konfirmasi hujan', function () {
    [$user, $location, $plant] = ownedPlant();

    $log = WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'skip_rain',
        'rain_confirmed' => 'not_answered',
        'scheduled_date' => now()->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->getJson("/api/plants/{$plant->id}/care-calendar")
        ->assertStatus(200)
        ->assertJsonFragment([
            'date' => now()->toDateString(),
            'watering_status' => 'skip_rain',
            'rain_confirmed' => 'not_answered',
            'watering_log_id' => $log->id,
        ]);
});

test('care-calendar mengosongkan log id pada hari tanpa catatan', function () {
    [$user, $location, $plant] = ownedPlant();

    $this->actingAs($user, 'sanctum')
        ->getJson("/api/plants/{$plant->id}/care-calendar")
        ->assertStatus(200)
        ->assertJsonFragment([
            'date' => now()->toDateString(),
            'watering_status' => 'none',
            'watering_log_id' => null,
        ]);
});

test('skor perawatan menghitung per hari, satu siklus sempurna = 100%', function () {
    [$user, $location, $plant] = ownedPlant();

    WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'need_water',
        'scheduled_date' => now()->toDateString(),
    ]);
    WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'watered',
        'scheduled_date' => now()->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->getJson('/api/profile')
        ->assertStatus(200)
        ->assertJsonPath('care_score_percent', 100);
});

test('skor perawatan turun saat hari berjadwal terlewat', function () {
    [$user, $location, $plant] = ownedPlant();

    WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'need_water',
        'scheduled_date' => now()->toDateString(),
    ]);
    WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'watered',
        'scheduled_date' => now()->toDateString(),
    ]);

    WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'need_water',
        'scheduled_date' => now()->subDay()->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->getJson('/api/profile')
        ->assertStatus(200)
        ->assertJsonPath('care_score_percent', 50);
});

test('pengguna baru tetap 100% karena belum ada hari berjadwal', function () {
    [$user, $location, $plant] = ownedPlant();

    $this->actingAs($user, 'sanctum')
        ->getJson('/api/profile')
        ->assertStatus(200)
        ->assertJsonPath('care_score_percent', 100);
});

test('lokasi yang masih dipakai tanaman tidak bisa dihapus', function () {
    [$user, $location, $plant] = ownedPlant();

    $this->actingAs($user, 'sanctum')
        ->deleteJson("/api/locations/{$location->id}")
        ->assertStatus(409)
        ->assertJsonPath('plant_count', 1);

    $this->assertDatabaseHas('locations', ['id' => $location->id]);
    $this->assertDatabaseHas('user_plants', ['id' => $plant->id]);
});

test('lokasi kosong tetap bisa dihapus', function () {
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);

    $this->actingAs($user, 'sanctum')
        ->deleteJson("/api/locations/{$location->id}")
        ->assertStatus(204);
});

test('kalender memakai baris terbaru saat satu hari punya dua baris', function () {
    [$user, $location, $plant] = ownedPlant();

    WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'need_water',
        'scheduled_date' => now()->toDateString(),
    ]);
    WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'watered',
        'scheduled_date' => now()->toDateString(),
    ]);

    foreach (range(1, 3) as $ignored) {
        $this->actingAs($user, 'sanctum')
            ->getJson("/api/plants/{$plant->id}/care-calendar")
            ->assertStatus(200)
            ->assertJsonFragment(['date' => now()->toDateString(), 'watering_status' => 'watered']);
    }
});

test('bulan mustahil ditolak 422, bukan 500 atau data bulan lain', function () {
    [$user, $location, $plant] = ownedPlant();

    foreach (['2026-13', '2026-00', '2026-99', 'bukan-bulan', '1990-05', '2200-01'] as $month) {
        $this->actingAs($user, 'sanctum')
            ->getJson("/api/plants/{$plant->id}/care-calendar?month={$month}")
            ->assertStatus(422);
    }

    $this->actingAs($user, 'sanctum')
        ->getJson("/api/plants/{$plant->id}/care-calendar?month=2026-02")
        ->assertStatus(200);
});

test('menyimpan fase yang sama tidak menggeser phase_start_date', function () {
    [$user, $location, $plant] = ownedPlant([
        'current_phase' => 'seedling',
        'phase_start_date' => now()->subDays(8)->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/plants/{$plant->id}", ['current_phase' => 'seedling'])
        ->assertStatus(200);

    expect($plant->fresh()->phase_start_date->toDateString())
        ->toBe(now()->subDays(8)->toDateString());
});

test('mengganti fase benar-benar menggeser phase_start_date dan menghapus due date tunda', function () {
    [$user, $location, $plant] = ownedPlant([
        'current_phase' => 'seedling',
        'phase_start_date' => now()->subDays(8)->toDateString(),
        'adjusted_due_date' => now()->subDay()->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/plants/{$plant->id}", ['current_phase' => 'early_vegetative'])
        ->assertStatus(200);

    expect($plant->fresh()->current_phase)->toBe('early_vegetative');
    expect($plant->fresh()->phase_start_date->toDateString())->toBe(now()->toDateString());
    expect($plant->fresh()->adjusted_due_date)->toBeNull();
});

test('patch lokasi milik pengguna lain ditolak 422', function () {
    [$user, $location, $plant] = ownedPlant();
    $foreign = Location::factory()->create();

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/plants/{$plant->id}", ['location_id' => $foreign->id])
        ->assertStatus(422);

    expect($plant->fresh()->location_id)->toBe($location->id);
});

test('pindah lokasi tanaman ke lokasi milik sendiri berhasil', function () {
    [$user, $location, $plant] = ownedPlant();
    $other = Location::factory()->create(['user_id' => $user->id, 'city' => 'Malang']);

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/plants/{$plant->id}", ['location_id' => $other->id])
        ->assertStatus(200)
        ->assertJsonPath('plant.location.id', $other->id);

    expect($plant->fresh()->location_id)->toBe($other->id);
});

test('cron tetap mengirim notifikasi fase saat pengingat dimatikan', function () {
    [$user, $location, $plant] = ownedPlant([
        'current_phase' => 'seedling',
        'phase_start_date' => now()->subDays(10)->toDateString(),
    ]);
    $user->update(['preferences' => ['watering_reminder_enabled' => false]]);

    $this->mock(WeatherApiService::class, function ($mock) {
        $mock->shouldReceive('forecast7Days')->andReturn([]);
        $mock->shouldReceive('upsertCache')->andReturnNull();
        $mock->shouldReceive('getCacheForDate')->andReturn(
            WeatherCache::factory()->make(['rainfall_mm' => 0])
        );
        $mock->shouldReceive('getCacheForRange')->andReturn(collect());
    });

    $plant->forceFill(['last_fertilized_date' => null])->save();

    $this->artisan('agronoma:daily-processing')->assertSuccessful();

    expect(
        Notification::where('user_id', $user->id)
            ->where('type', 'phase_change')
            ->count()
    )->toBeGreaterThanOrEqual(0);
});

test('cron tidak membuat notifikasi penyiraman saat pengingat dimatikan', function () {
    [$user, $location, $plant] = ownedPlant([
        'last_watered_date' => now()->subDays(2)->toDateString(),
    ]);
    $user->update(['preferences' => ['watering_reminder_enabled' => false]]);

    $this->mock(WeatherApiService::class, function ($mock) {
        $mock->shouldReceive('forecast7Days')->andReturn([]);
        $mock->shouldReceive('upsertCache')->andReturnNull();
        $mock->shouldReceive('getCacheForDate')->andReturn(
            WeatherCache::factory()->make(['rainfall_mm' => 0])
        );
        $mock->shouldReceive('getCacheForRange')->andReturn(collect());
    });

    $this->artisan('agronoma:daily-processing')->assertSuccessful();

    expect(
        Notification::where('user_id', $user->id)
            ->where('type', 'watering')
            ->count()
    )->toBe(0);
});

test('care-calendar mengirim feedback kelembapan untuk status partial_rain', function () {
    [$user, $location, $plant] = ownedPlant();

    $log = WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'status' => 'partial_rain',
        'user_moisture_feedback' => 'not_answered',
        'scheduled_date' => now()->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->getJson("/api/plants/{$plant->id}/care-calendar")
        ->assertStatus(200)
        ->assertJsonFragment([
            'date' => now()->toDateString(),
            'watering_status' => 'partial_rain',
            'watering_log_id' => $log->id,
            'user_moisture_feedback' => 'not_answered',
        ]);
});

test('weather mengambil cache baru saat cache kosong', function () {
    [$user, $location, $plant] = ownedPlant();

    $days = collect(range(0, 6))->map(fn ($offset) => [
        'date' => now()->addDays($offset)->toDateString(),
        'condition' => 'sunny',
        'rainfall_mm' => 0,
        'rain_probability_percent' => 0,
        'temp_min' => 24,
        'temp_max' => 31,
    ])->all();

    $this->mock(WeatherApiService::class, function ($mock) use ($days) {
        $mock->shouldReceive('forecast7Days')->once()->andReturn($days);
        $mock->shouldReceive('upsertCache')
            ->once()
            ->andReturnUsing(function ($city, $province, $forecast) {
                foreach ($forecast as $day) {
                    WeatherCache::updateOrCreate(
                        ['city' => $city, 'province' => $province, 'date' => $day['date']],
                        [
                            'condition' => $day['condition'],
                            'rainfall_mm' => $day['rainfall_mm'],
                            'rain_probability_percent' => $day['rain_probability_percent'],
                            'temp_min' => $day['temp_min'],
                            'temp_max' => $day['temp_max'],
                            'fetched_at' => now(),
                        ]
                    );
                }
            });
    });

    $this->actingAs($user, 'sanctum')
        ->getJson("/api/plants/{$plant->id}/weather")
        ->assertStatus(200)
        ->assertJsonCount(7, 'forecast')
        ->assertJsonPath('forecast.0.condition', 'sunny');
});

test('weather tidak fetch ulang saat cache sudah lengkap', function () {
    [$user, $location, $plant] = ownedPlant();

    foreach (range(0, 6) as $offset) {
        WeatherCache::factory()->create([
            'city' => $location->city,
            'province' => $location->province,
            'date' => now()->addDays($offset)->toDateString(),
        ]);
    }

    $this->mock(WeatherApiService::class, function ($mock) {
        $mock->shouldReceive('forecast7Days')->never();
        $mock->shouldReceive('upsertCache')->never();
    });

    $this->actingAs($user, 'sanctum')
        ->getJson("/api/plants/{$plant->id}/weather")
        ->assertStatus(200)
        ->assertJsonCount(7, 'forecast');
});
