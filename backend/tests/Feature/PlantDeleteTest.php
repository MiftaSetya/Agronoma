<?php

use App\Models\Location;
use App\Models\User;
use App\Models\UserPlant;
use App\Models\WateringLog;

function deletePlantFixture(): array
{
    $user = User::factory()->create();
    $location = Location::factory()->create(['user_id' => $user->id]);

    $plant = UserPlant::factory()->create([
        'user_id' => $user->id,
        'location_id' => $location->id,
    ]);

    return [$user, $plant];
}

test('user dapat menghapus tanaman miliknya', function () {
    [$user, $plant] = deletePlantFixture();

    $this->actingAs($user, 'sanctum')
        ->deleteJson("/api/plants/{$plant->id}")
        ->assertStatus(204);

    expect(UserPlant::find($plant->id))->toBeNull();
});

test('menghapus tanaman ikut menghapus riwayat perawatannya', function () {
    [$user, $plant] = deletePlantFixture();

    WateringLog::factory()->create([
        'user_plant_id' => $plant->id,
        'scheduled_date' => now()->toDateString(),
    ]);

    $this->actingAs($user, 'sanctum')
        ->deleteJson("/api/plants/{$plant->id}")
        ->assertStatus(204);

    expect(WateringLog::where('user_plant_id', $plant->id)->count())->toBe(0);
});

test('user tidak dapat menghapus tanaman milik orang lain', function () {
    [, $plant] = deletePlantFixture();
    $other = User::factory()->create();

    $this->actingAs($other, 'sanctum')
        ->deleteJson("/api/plants/{$plant->id}")
        ->assertStatus(403);

    expect(UserPlant::find($plant->id))->not->toBeNull();
});

test('menghapus tanaman yang tidak ada menghasilkan 404', function () {
    $user = User::factory()->create();

    $this->actingAs($user, 'sanctum')
        ->deleteJson('/api/plants/999999')
        ->assertStatus(404);
});

test('menghapus tanaman memerlukan autentikasi', function () {
    [, $plant] = deletePlantFixture();

    $this->deleteJson("/api/plants/{$plant->id}")->assertStatus(401);

    expect(UserPlant::find($plant->id))->not->toBeNull();
});
