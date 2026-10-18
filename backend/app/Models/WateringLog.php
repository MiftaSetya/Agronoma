<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_plant_id',
    'phase_at_time',
    'scheduled_date',
    'actual_date',
    'status',
    'delay_streak_at_time',
    'rain_confirmed',
    'user_moisture_feedback',
    'weather_snapshot',
])]
class WateringLog extends Model
{

    use HasFactory;

    protected function casts(): array
    {
        return [
            'scheduled_date' => 'date:Y-m-d',
            'actual_date' => 'date:Y-m-d',
            'delay_streak_at_time' => 'integer',
            'weather_snapshot' => 'array',
        ];
    }

    public function userPlant(): BelongsTo
    {
        return $this->belongsTo(UserPlant::class);
    }
}
