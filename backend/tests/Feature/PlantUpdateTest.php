<?php

use App\Models\Location;
use App\Models\User;
use App\Models\UserPlant;

function patchablePlant(): array
{
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);

    $plant = UserPlant::factory()->create([
        'user_id' => $user->id,
        'location_id' => $location->id,
        'plant_name' => 'Kangkung',
        'planting_medium' => 'pot',
        'soil_type' => 'fertile',
        'current_phase' => 'seedling',
    ]);

    return [$user, $plant];
}

test('nama, media tanam, dan jenis tanah bisa diperbarui', function () {
    [$user, $plant] = patchablePlant();

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/plants/{$plant->id}", [
            'plant_name' => 'Bayam Merah',
            'planting_medium' => 'open_land',
            'soil_type' => 'volcanic',
        ])
        ->assertStatus(200)
        ->assertJsonPath('plant.plant_name', 'Bayam Merah')
        ->assertJsonPath('plant.planting_medium', 'open_land')
        ->assertJsonPath('plant.soil_type', 'volcanic');

    $fresh = $plant->fresh();
    expect($fresh->plant_name)->toBe('Bayam Merah');
    expect($fresh->planting_medium)->toBe('open_land');
    expect($fresh->soil_type)->toBe('volcanic');

    expect($fresh->current_phase)->toBe('seedling');
});

test('nilai di luar enum ditolak 422', function () {
    [$user, $plant] = patchablePlant();

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/plants/{$plant->id}", ['soil_type' => 'bukan_tanah'])
        ->assertStatus(422);

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/plants/{$plant->id}", ['planting_medium' => 'bukan_media'])
        ->assertStatus(422);

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/plants/{$plant->id}", ['plant_name' => ''])
        ->assertStatus(422);

    expect($plant->fresh()->plant_name)->toBe('Kangkung');
});

test('user tidak dapat mengubah tanaman milik orang lain', function () {
    [, $plant] = patchablePlant();
    $intruder = User::factory()->create();

    $this->actingAs($intruder, 'sanctum')
        ->patchJson("/api/plants/{$plant->id}", ['plant_name' => 'Hack'])
        ->assertStatus(403);

    expect($plant->fresh()->plant_name)->toBe('Kangkung');
});

test('patch nama saja tidak menggeser phase_start_date', function () {
    [$user, $plant] = patchablePlant();
    $original = $plant->phase_start_date->toDateString();

    $this->actingAs($user, 'sanctum')
        ->patchJson("/api/plants/{$plant->id}", ['plant_name' => 'Kangkung Baru'])
        ->assertStatus(200);

    expect($plant->fresh()->phase_start_date->toDateString())->toBe($original);
});
