<?php

namespace Database\Factories;

use App\Models\SoilScanHistory;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class SoilScanHistoryFactory extends Factory
{

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'image_url' => fake()->imageUrl(),
            'detected_soil_type' => fake()->randomElement(['fertile', 'clay', 'sandy', 'chalky', 'volcanic', 'peat', 'artificial_media']),
            'ai_confidence' => fake()->randomFloat(2, 60, 98),
            'scanned_at' => now(),
        ];
    }
}
