<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'type',
    'related_plant_ids',
    'message',
    'sent_at',
    'is_read',
])]
class Notification extends Model
{

    use HasFactory;

    protected function casts(): array
    {
        return [
            'related_plant_ids' => 'array',
            'sent_at' => 'datetime',
            'is_read' => 'boolean',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
