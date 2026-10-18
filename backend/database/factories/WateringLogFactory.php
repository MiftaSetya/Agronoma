<?php

namespace Database\Factories;

use App\Models\UserPlant;
use App\Models\WateringLog;
use Illuminate\Database\Eloquent\Factories\Factory;

class WateringLogFactory extends Factory
{

    public function definition(): array
    {
        return [
            'user_plant_id' => UserPlant::factory(),
            'phase_at_time' => 'seedling',
            'scheduled_date' => now()->toDateString(),
            'actual_date' => null,
            'status' => 'need_water',
            'delay_streak_at_time' => 0,
            'rain_confirmed' => null,
            'user_moisture_feedback' => null,
            'weather_snapshot' => null,
        ];
    }
}
