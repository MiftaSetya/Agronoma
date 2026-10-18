<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_plant_id',
    'scheduled_date',
    'actual_date',
    'status',
    'fertilizer_description',
])]
class FertilizingLog extends Model
{

    use HasFactory;

    protected function casts(): array
    {
        return [
            'scheduled_date' => 'date:Y-m-d',
            'actual_date' => 'date:Y-m-d',
        ];
    }

    public function userPlant(): BelongsTo
    {
        return $this->belongsTo(UserPlant::class);
    }
}
