<?php

namespace App\Models;

use Carbon\Carbon;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'user_id',
    'location_id',
    'plant_name',
    'photo',
    'planting_medium',
    'soil_type',
    'current_phase',
    'phase_start_date',
    'planting_date',
    'watering_config',
    'fertilizing_config',
    'last_watered_date',
    'last_fertilized_date',
    'adjusted_due_date',
    'delay_streak_days',
    'status',
])]
class UserPlant extends Model
{
    use HasFactory;

    protected function casts(): array
    {
        return [
            'phase_start_date' => 'date:Y-m-d',
            'planting_date' => 'date:Y-m-d',
            'last_watered_date' => 'date:Y-m-d',
            'last_fertilized_date' => 'date:Y-m-d',
            'adjusted_due_date' => 'date:Y-m-d',
            'delay_streak_days' => 'integer',
            'watering_config' => 'array',
            'fertilizing_config' => 'array',
        ];
    }

    public function photoUrl(): ?string
    {
        return $this->photo === null ? null : asset('storage/'.$this->photo);
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function location(): BelongsTo
    {
        return $this->belongsTo(Location::class);
    }

    public function wateringLogs(): HasMany
    {
        return $this->hasMany(WateringLog::class);
    }

    public function fertilizingLogs(): HasMany
    {
        return $this->hasMany(FertilizingLog::class);
    }

    public function chatSessions(): HasMany
    {
        return $this->hasMany(ChatSession::class);
    }

    public function phaseConfig(): ?array
    {
        $schedule = $this->watering_config['phase_schedule'] ?? [];

        return collect($schedule)->firstWhere('phase', $this->current_phase);
    }

    public function effectiveWateringDueDate(): ?Carbon
    {
        $phaseConfig = $this->phaseConfig();
        $interval = $phaseConfig['watering_interval_days'] ?? null;

        if ($interval === null) {
            return null;
        }

        if ($this->adjusted_due_date) {
            return $this->adjusted_due_date;
        }

        $base = $this->last_watered_date ?: $this->phase_start_date;

        return Carbon::parse($base)->addDays((int) $interval);
    }

    public function effectiveFertilizingDueDate(): ?Carbon
    {
        $schedule = $this->fertilizing_config['phase_schedule'] ?? [];
        $phaseConfig = collect($schedule)->firstWhere('phase', $this->current_phase);

        if (($phaseConfig['interval_days'] ?? null) === null) {
            return null;
        }

        $base = $this->last_fertilized_date ?: $this->phase_start_date;

        return Carbon::parse($base)->addDays((int) $phaseConfig['interval_days']);
    }

    public function badgeStatus(): string
    {
        $today = Carbon::today();
        $wateringDueDate = $this->effectiveWateringDueDate();
        $fertilizingDueDate = $this->effectiveFertilizingDueDate();

        if ($wateringDueDate !== null && $wateringDueDate->lessThanOrEqualTo($today)) {
            return 'perlu_disiram';
        }

        if ($fertilizingDueDate !== null && $fertilizingDueDate->lessThanOrEqualTo($today)) {
            return 'perlu_pupuk';
        }

        return 'kondisi_aman';
    }
}
