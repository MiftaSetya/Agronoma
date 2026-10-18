<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserPlantResource;
use App\Models\UserPlant;
use App\Models\WeatherCache;
use App\Services\WeatherApiService;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Throwable;

class PlantController extends Controller
{
    public function __construct(private readonly WeatherApiService $weatherApiService) {}

    public function index(Request $request): JsonResponse
    {
        $plantQuery = $request->user()->userPlants()->with('location');

        if ($request->has('status')) {
            $plantQuery->where('status', $request->query('status'));
        }

        $plants = $plantQuery->orderBy('created_at', 'desc')->get();

        return response()->json([
            'data' => UserPlantResource::collection($plants),
        ], 200);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $plant = $this->resolveOwnedPlant($request, $id);

        return response()->json([
            'plant' => new UserPlantResource($plant->load('location')),
        ], 200);
    }

    public function weather(Request $request, int $id): JsonResponse
    {
        $plant = $this->resolveOwnedPlant($request, $id)->load('location');
        $city = $plant->location->city;
        $province = $plant->location->province;

        $from = now()->toDateString();
        $to = now()->addDays(6)->toDateString();

        $cache = WeatherCache::where('city', $city)
            ->where('province', $province)
            ->whereBetween('date', [$from, $to])
            ->orderBy('date')
            ->get();

        if ($cache->count() < 7) {
            try {
                $forecast = $this->weatherApiService->forecast7Days($city);
                $this->weatherApiService->upsertCache($city, $province, $forecast);
            } catch (Throwable) {
            }

            $cache = WeatherCache::where('city', $city)
                ->where('province', $province)
                ->whereBetween('date', [$from, $to])
                ->orderBy('date')
                ->get();
        }

        $forecast = $cache->map(fn (WeatherCache $entry): array => [
            'date' => $entry->date->toDateString(),
            'condition' => $entry->condition,
            'temp_min' => $entry->temp_min,
            'temp_max' => $entry->temp_max,
            'rainfall_mm' => $entry->rainfall_mm,
        ]);

        return response()->json(['forecast' => $forecast], 200);
    }

    public function careCalendar(Request $request, int $id): JsonResponse
    {
        $plant = $this->resolveOwnedPlant($request, $id);

        $month = $request->query('month', now()->format('Y-m'));

        if (! is_string($month) || ! preg_match('/^(\d{4})-(0[1-9]|1[0-2])$/', $month, $matches)) {
            return response()->json([
                'message' => 'Format bulan tidak valid.',
                'errors' => ['month' => ['Format bulan harus YYYY-MM.']],
            ], 422);
        }

        if ((int) $matches[1] < 2000 || (int) $matches[1] > 2100) {
            return response()->json([
                'message' => 'Tahun di luar jangkauan.',
                'errors' => ['month' => ['Tahun harus antara 2000 dan 2100.']],
            ], 422);
        }

        $start = Carbon::parse($month.'-01')->startOfDay();
        $end = $start->copy()->endOfMonth()->endOfDay();

        $wateringLogs = $plant->wateringLogs()
            ->whereBetween('scheduled_date', [$start, $end])
            ->orderBy('id')
            ->get()
            ->keyBy(fn ($log) => $log->scheduled_date->toDateString());

        $fertilizingLogs = $plant->fertilizingLogs()
            ->whereBetween('scheduled_date', [$start, $end])
            ->orderBy('id')
            ->get()
            ->keyBy(fn ($log) => $log->scheduled_date->toDateString());

        $days = [];

        for ($date = $start->copy(); $date->lte($end); $date->addDay()) {
            $key = $date->toDateString();
            $days[] = [
                'date' => $key,
                'watering_status' => $wateringLogs[$key]->status ?? 'none',
                'fertilizing_status' => $fertilizingLogs[$key]->status ?? 'none',
                'watering_log_id' => $wateringLogs[$key]->id ?? null,
                'rain_confirmed' => $wateringLogs[$key]->rain_confirmed ?? null,
                'user_moisture_feedback' => $wateringLogs[$key]->user_moisture_feedback ?? null,
            ];
        }

        return response()->json(['days' => $days], 200);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $plant = $this->resolveOwnedPlant($request, $id);
        $validated = $request->validate([
            'status' => ['sometimes', 'in:active,archived,failed'],
            'current_phase' => ['sometimes', 'in:seedling,early_vegetative,late_vegetative,generative'],

            'plant_name' => ['sometimes', 'string', 'max:150'],
            'planting_medium' => ['sometimes', 'in:home_yard,open_land,pot'],
            'soil_type' => ['sometimes', 'in:fertile,clay,sandy,chalky,volcanic,peat,artificial_media'],
            'location_id' => [
                'sometimes',
                'integer',
                Rule::exists('locations', 'id')->where('user_id', $request->user()->id),
            ],
        ], [
            'location_id.exists' => 'Lokasi tanam itu tidak tersedia untuk akun Anda.',
        ]);

        if (isset($validated['current_phase'])) {

            if ($validated['current_phase'] !== $plant->current_phase) {
                $validated['phase_start_date'] = now()->toDateString();

                $validated['adjusted_due_date'] = null;
            } else {
                unset($validated['current_phase']);
            }
        }

        $plant->update($validated);

        return response()->json([
            'plant' => new UserPlantResource($plant->load('location')),
        ], 200);
    }

    public function uploadPhoto(Request $request, int $id): JsonResponse
    {
        $plant = $this->resolveOwnedPlant($request, $id);

        $validated = $request->validate([
            'image' => ['required', 'image', 'max:5120'],
        ]);

        $oldPhoto = $plant->photo;
        $path = $validated['image']->store('photos/plants', 'public');

        $plant->update(['photo' => $path]);

        if ($oldPhoto !== null) {
            Storage::disk('public')->delete($oldPhoto);
        }

        return response()->json([
            'photo_url' => $plant->photoUrl(),
        ], 200);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $plant = $this->resolveOwnedPlant($request, $id);

        $plant->delete();

        return response()->json(null, 204);
    }

    public function resolveOwnedPlant(Request $request, int $id): UserPlant
    {
        $plant = UserPlant::find($id);

        if ($plant === null) {
            throw (new ModelNotFoundException)->setModel(UserPlant::class, $id);
        }

        if ($plant->user_id !== $request->user()->id) {
            throw new AccessDeniedHttpException;
        }

        return $plant;
    }
}
