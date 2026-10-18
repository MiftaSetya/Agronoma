<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'image_url',
    'detected_soil_type',
    'ai_confidence',
    'scanned_at',
])]
class SoilScanHistory extends Model
{

    use HasFactory;

    protected $table = 'soil_scan_history';

    public const UPDATED_AT = null;

    public const CREATED_AT = null;

    protected function casts(): array
    {
        return [
            'ai_confidence' => 'float',
            'scanned_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
