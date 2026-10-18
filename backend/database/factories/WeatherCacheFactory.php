<?php

namespace Database\Factories;

use App\Models\WeatherCache;
use Illuminate\Database\Eloquent\Factories\Factory;

class WeatherCacheFactory extends Factory
{

    public function definition(): array
    {
        return [
            'city' => 'Surabaya',
            'province' => 'Jawa Timur',
            'date' => now()->toDateString(),
            'condition' => fake()->randomElement(['sunny', 'partly_cloudy', 'cloudy', 'light_rain', 'moderate_rain', 'heavy_rain']),
            'rainfall_mm' => 0,
            'rain_probability_percent' => fake()->numberBetween(0, 100),
            'temp_min' => fake()->randomFloat(1, 20, 26),
            'temp_max' => fake()->randomFloat(1, 28, 34),
            'fetched_at' => now(),
        ];
    }
}
