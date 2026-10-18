<?php

namespace Database\Factories;

use App\Models\ChatSession;
use App\Models\User;
use App\Models\UserPlant;
use Illuminate\Database\Eloquent\Factories\Factory;

class ChatSessionFactory extends Factory
{

    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'context_plant_id' => null,
        ];
    }

    public function withPlant(): static
    {
        return $this->state(['context_plant_id' => UserPlant::factory()]);
    }
}
