<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{

    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'type' => $this->type,
            'related_plant_ids' => $this->related_plant_ids,
            'message' => $this->message,
            'sent_at' => $this->sent_at,
            'is_read' => $this->is_read,
            'created_at' => $this->created_at,
        ];
    }
}
