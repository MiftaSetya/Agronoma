<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

#[Fillable([
    'city',
    'province',
    'date',
    'condition',
    'rainfall_mm',
    'rain_probability_percent',
    'temp_min',
    'temp_max',
    'fetched_at',
])]
class WeatherCache extends Model
{

    use HasFactory;

    public const UPDATED_AT = null;

    public const CREATED_AT = null;

    protected $table = 'weather_cache';

    protected function casts(): array
    {
        return [
            'date' => 'date:Y-m-d',
            'rainfall_mm' => 'float',
            'rain_probability_percent' => 'integer',
            'temp_min' => 'float',
            'temp_max' => 'float',
            'fetched_at' => 'datetime',
        ];
    }
}
