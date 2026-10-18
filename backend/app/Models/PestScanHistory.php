<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'user_plant_id',
    'image_url',
    'detected_pest_name',
    'ai_confidence',
    'ai_raw_response',
    'recommended_action',
    'scanned_at',
])]
class PestScanHistory extends Model
{

    use HasFactory;

    protected $table = 'pest_scan_history';

    public const UPDATED_AT = null;

    public const CREATED_AT = null;

    protected function casts(): array
    {
        return [
            'ai_confidence' => 'float',
            'ai_raw_response' => 'array',
            'scanned_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function userPlant(): BelongsTo
    {
        return $this->belongsTo(UserPlant::class);
    }
}
