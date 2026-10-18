<?php

namespace Database\Factories;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class NotificationFactory extends Factory
{

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'type' => fake()->randomElement(['watering', 'fertilizing', 'phase_change', 'pest_alert']),
            'related_plant_ids' => null,
            'message' => fake()->sentence(),
            'sent_at' => now(),
            'is_read' => false,
        ];
    }
}
