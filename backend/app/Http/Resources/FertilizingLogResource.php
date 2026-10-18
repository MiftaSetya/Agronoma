<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class FertilizingLogResource extends JsonResource
{

    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_plant_id' => $this->user_plant_id,
            'scheduled_date' => $this->scheduled_date?->toDateString(),
            'actual_date' => $this->actual_date?->toDateString(),
            'status' => $this->status,
            'fertilizer_description' => $this->fertilizer_description,
        ];
    }
}
