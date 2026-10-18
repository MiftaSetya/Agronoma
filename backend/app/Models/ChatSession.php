<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['user_id', 'context_plant_id'])]
class ChatSession extends Model
{

    use HasFactory;

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function contextPlant(): BelongsTo
    {
        return $this->belongsTo(UserPlant::class, 'context_plant_id');
    }

    public function messages(): HasMany
    {

        return $this->hasMany(ChatMessage::class, 'session_id');
    }
}
