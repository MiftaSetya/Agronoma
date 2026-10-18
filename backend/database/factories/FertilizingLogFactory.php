<?php

namespace Database\Factories;

use App\Models\FertilizingLog;
use App\Models\UserPlant;
use Illuminate\Database\Eloquent\Factories\Factory;

class FertilizingLogFactory extends Factory
{

    public function definition(): array
    {
        return [
            'user_plant_id' => UserPlant::factory(),
            'scheduled_date' => now()->toDateString(),
            'actual_date' => null,
            'status' => 'fertilized',
            'fertilizer_description' => null,
        ];
    }
}
