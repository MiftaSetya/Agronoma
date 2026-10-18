<?php

namespace Database\Factories;

use App\Models\PestScanHistory;
use App\Models\User;
use App\Models\UserPlant;
use Illuminate\Database\Eloquent\Factories\Factory;

class PestScanHistoryFactory extends Factory
{

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'user_plant_id' => null,
            'image_url' => fake()->imageUrl(),
            'detected_pest_name' => fake()->randomElement(['Ulat Grayak', 'Kutu Daun', 'Tungau Merah']),
            'ai_confidence' => fake()->randomFloat(2, 60, 98),
            'ai_raw_response' => null,
            'recommended_action' => 'Semprot insektisida nabati dan pisahkan tanaman yang terinfeksi.',
            'scanned_at' => now(),
        ];
    }
}
