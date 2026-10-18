<?php

namespace Database\Factories;

use App\Models\Location;
use App\Models\User;
use App\Models\UserPlant;
use Illuminate\Database\Eloquent\Factories\Factory;

class UserPlantFactory extends Factory
{

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'location_id' => Location::factory(),
            'plant_name' => fake()->randomElement(['Bayam', 'Cabai Rawit', 'Kangkung', 'Tomat', 'Padi']),
            'planting_medium' => fake()->randomElement(['home_yard', 'open_land', 'pot']),
            'soil_type' => fake()->randomElement(['fertile', 'clay', 'sandy', 'chalky', 'volcanic', 'peat', 'artificial_media']),
            'current_phase' => 'seedling',
            'phase_start_date' => now()->subDays(5)->toDateString(),
            'planting_date' => now()->subDays(5)->toDateString(),
            'watering_config' => [
                'phase_schedule' => [
                    [
                        'phase' => 'seedling',
                        'duration_days' => 10,
                        'watering_interval_days' => 1,
                        'watering_description' => 'Siram tipis merata, jaga tetap lembab karena akar belum kuat',
                        'rain_prob_threshold' => 40,
                        'min_significant_rain_mm' => 5,
                        'rain_equivalent_full_mm' => 10,
                        'lookahead_days' => 2,
                        'max_delay_days' => 1,
                    ],
                    [
                        'phase' => 'early_vegetative',
                        'duration_days' => 20,
                        'watering_interval_days' => 2,
                        'watering_description' => 'Siram hingga tanah lembab merata, jangan sampai becek',
                        'rain_prob_threshold' => 45,
                        'min_significant_rain_mm' => 8,
                        'rain_equivalent_full_mm' => 15,
                        'lookahead_days' => 2,
                        'max_delay_days' => 2,
                    ],
                    [
                        'phase' => 'late_vegetative',
                        'duration_days' => 25,
                        'watering_interval_days' => 3,
                        'watering_description' => 'Siram rutin, fase toleran terhadap penundaan singkat',
                        'rain_prob_threshold' => 50,
                        'min_significant_rain_mm' => 10,
                        'rain_equivalent_full_mm' => 18,
                        'lookahead_days' => 2,
                        'max_delay_days' => 4,
                    ],
                    [
                        'phase' => 'generative',
                        'duration_days' => null,
                        'watering_interval_days' => 2,
                        'watering_description' => 'Siram konsisten, fase pembungaan sangat sensitif kekurangan air',
                        'rain_prob_threshold' => 35,
                        'min_significant_rain_mm' => 6,
                        'rain_equivalent_full_mm' => 12,
                        'lookahead_days' => 2,
                        'max_delay_days' => 1,
                    ],
                ],
            ],
            'fertilizing_config' => [
                'phase_schedule' => [
                    [
                        'phase' => 'early_vegetative',
                        'interval_days' => 14,
                        'fertilizer_description' => 'NPK seimbang untuk mendukung pertumbuhan vegetatif',
                    ],
                    [
                        'phase' => 'generative',
                        'interval_days' => 12,
                        'fertilizer_description' => 'NPK tinggi Kalium untuk mendukung pembentukan buah',
                    ],
                ],
            ],
            'delay_streak_days' => 0,
            'status' => 'active',
        ];
    }

    public function active(): static
    {
        return $this->state(['status' => 'active']);
    }

    public function archived(): static
    {
        return $this->state(['status' => 'archived']);
    }

    public function phase(string $phase): static
    {
        return $this->state(['current_phase' => $phase]);
    }
}
