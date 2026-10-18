<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class WateringLogResource extends JsonResource
{

    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_plant_id' => $this->user_plant_id,
            'phase_at_time' => $this->phase_at_time,
            'scheduled_date' => $this->scheduled_date?->toDateString(),
            'actual_date' => $this->actual_date?->toDateString(),
            'status' => $this->status,
            'delay_streak_at_time' => (int) $this->delay_streak_at_time,
            'rain_confirmed' => $this->rain_confirmed,
            'user_moisture_feedback' => $this->user_moisture_feedback,
            'weather_snapshot' => $this->weather_snapshot,
        ];
    }
}
