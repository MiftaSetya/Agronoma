<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserPlantResource extends JsonResource
{

    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'plant_name' => $this->plant_name,
            'planting_medium' => $this->planting_medium,
            'soil_type' => $this->soil_type,
            'current_phase' => $this->current_phase,
            'phase_start_date' => $this->phase_start_date?->toDateString(),
            'planting_date' => $this->planting_date?->toDateString(),
            'last_watered_date' => $this->last_watered_date?->toDateString(),
            'last_fertilized_date' => $this->last_fertilized_date?->toDateString(),
            'adjusted_due_date' => $this->adjusted_due_date?->toDateString(),
            'delay_streak_days' => (int) $this->delay_streak_days,
            'status' => $this->status,
            'badge_status' => $this->badgeStatus(),
            'location' => new LocationResource($this->whenLoaded('location')),
            'created_at' => $this->created_at,
            'updated_at' => $this->updated_at,
        ];
    }
}
