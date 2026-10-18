<?php

namespace App\Services;

use App\Models\WeatherCache;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Http;

class WeatherApiService
{

    public function forecast7Days(string $city): array
    {
        $response = Http::acceptJson()
            ->timeout(15)
            ->get(config('services.weatherapi.base_url').'/forecast.json', [
                'key' => config('services.weatherapi.key'),
                'q' => $city,
                'days' => 7,
                'aqi' => 'no',
            ]);

        $response->throw();

        $days = $response->json('forecast.forecastday') ?? [];

        return array_map(fn (array $day): array => $this->normalizeDay($day), $days);
    }

    public function upsertCache(string $city, ?string $province, array $days): void
    {
        foreach ($days as $day) {
            WeatherCache::updateOrCreate(
                [
                    'city' => $city,
                    'province' => $province,
                    'date' => $day['date'],
                ],
                [
                    'condition' => $day['condition'],
                    'rainfall_mm' => $day['rainfall_mm'],
                    'rain_probability_percent' => $day['rain_probability_percent'],
                    'temp_min' => $day['temp_min'],
                    'temp_max' => $day['temp_max'],
                    'fetched_at' => now(),
                ],
            );
        }
    }

    public function getCacheForDate(string $city, ?string $province, string $date): ?WeatherCache
    {
        return WeatherCache::where('city', $city)
            ->where('province', $province)
            ->where('date', $date)
            ->first();
    }

    public function getCacheForRange(string $city, ?string $province, string $from, string $to): Collection
    {
        return WeatherCache::where('city', $city)
            ->where('province', $province)
            ->whereBetween('date', [$from, $to])
            ->orderBy('date')
            ->get();
    }

    private function normalizeDay(array $day): array
    {
        $dayData = $day['day'] ?? [];
        $rainfallMm = (float) ($dayData['totalprecip_mm'] ?? 0);
        $conditionText = strtolower((string) ($dayData['condition']['text'] ?? ''));

        $condition = match (true) {
            $rainfallMm >= 10 => 'heavy_rain',
            $rainfallMm >= 5 => 'moderate_rain',
            $rainfallMm >= 0.5 => 'light_rain',
            str_contains($conditionText, 'partly') => 'partly_cloudy',
            str_contains($conditionText, 'cloud') => 'cloudy',
            default => 'sunny',
        };

        return [
            'date' => $day['date'],
            'condition' => $condition,
            'rainfall_mm' => $rainfallMm,
            'rain_probability_percent' => (int) ($dayData['daily_chance_of_rain'] ?? 0),
            'temp_min' => (float) ($dayData['mintemp_c'] ?? 0),
            'temp_max' => (float) ($dayData['maxtemp_c'] ?? 0),
        ];
    }
}
