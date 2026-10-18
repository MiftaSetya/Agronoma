<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class PestScanResource extends JsonResource
{

    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'user_plant_id' => $this->user_plant_id,
            'image_url' => $this->image_url,
            'detected_pest_name' => $this->detected_pest_name,
            'ai_confidence' => $this->ai_confidence,
            'recommended_action' => $this->recommended_action,
            'scanned_at' => $this->scanned_at,
        ];
    }
}
