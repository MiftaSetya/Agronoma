<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserPlantResource;
use App\Models\UserPlant;
use App\Models\WeatherCache;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $hour = (int) now()->format('H');
        $greeting = match (true) {
            $hour < 11 => 'Selamat pagi',
            $hour < 15 => 'Selamat siang',
            $hour < 19 => 'Selamat sore',
            default => 'Selamat malam',
        };

        $activePlants = $user->userPlants()
            ->with('location')
            ->where('status', 'active')
            ->orderBy('created_at', 'desc')
            ->get();

        $weatherToday = $this->weatherTodayFor($activePlants);

        return response()->json([
            'greeting' => $greeting.', '.$user->name,
            'weather_today' => $weatherToday,
            'plants' => UserPlantResource::collection($activePlants),
        ], 200);
    }

    private function weatherTodayFor($plants): ?array
    {
        $location = $plants->first()?->location;

        if ($location === null) {
            return null;
        }

        $weather = WeatherCache::where('city', $location->city)
            ->where('province', $location->province)
            ->where('date', now()->toDateString())
            ->first();

        if ($weather === null) {
            return null;
        }

        return [
            'city' => $location->city,
            'province' => $location->province,
            'condition' => $weather->condition,
            'temp_min' => $weather->temp_min,
            'temp_max' => $weather->temp_max,
            'rainfall_mm' => $weather->rainfall_mm,
            'rain_probability_percent' => $weather->rain_probability_percent,
        ];
    }
}
