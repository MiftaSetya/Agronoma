<?php

namespace Database\Factories;

use App\Models\ChatMessage;
use App\Models\ChatSession;
use Illuminate\Database\Eloquent\Factories\Factory;

class ChatMessageFactory extends Factory
{

    public function definition(): array
    {
        return [
            'session_id' => ChatSession::factory(),
            'role' => fake()->randomElement(['user', 'ai']),
            'content' => fake()->sentence(),
        ];
    }
}
