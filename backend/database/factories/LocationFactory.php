<?php

namespace Database\Factories;

use App\Models\Location;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class LocationFactory extends Factory
{

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'label' => fake()->randomElement(['Home', 'Backyard Garden', 'Teras Depan']),
            'city' => fake()->randomElement(['Surabaya', 'Bandung', 'Medan', 'Makassar']),
            'province' => fake()->randomElement(['Jawa Timur', 'Jawa Barat', 'Sumatera Utara', 'Sulawesi Selatan']),
        ];
    }
}
