<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserPlantResource;
use App\Models\Location;
use App\Models\SoilScanHistory;
use App\Models\UserPlant;
use App\Services\GeminiService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Throwable;

class PlantWizardController extends Controller
{
    public function __construct(private readonly GeminiService $gemini)
    {
    }

    public function soilScan(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'image' => ['required', 'image', 'max:5120'],
            'location_id' => ['nullable', 'integer', 'exists:locations,id'],
        ]);

        $locationId = $validated['location_id'] ?? null;

        if ($locationId !== null && ! $this->ownsLocation($request, (int) $locationId)) {
            throw new AccessDeniedHttpException;
        }

        $image = $request->file('image');
        $path = $image->store('scans/soil', 'public');

        try {
            $result = $this->gemini->detectSoil(
                base64_encode(file_get_contents($image->getRealPath())),
                $image->getMimeType(),
            );
        } catch (Throwable $e) {
            throw new RuntimeException('Gagal menganalisis foto tanah.', 0, $e);
        }

        SoilScanHistory::create([
            'user_id' => $request->user()->id,
            'image_url' => asset('storage/'.$path),
            'detected_soil_type' => $result['detected_soil_type'],
            'ai_confidence' => $result['ai_confidence'] ?? null,
        ]);

        return response()->json([
            'detected_soil_type' => $result['detected_soil_type'],
            'ai_confidence' => $result['ai_confidence'] ?? null,
        ], 200);
    }

    public function plantRecommendations(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'planting_medium' => ['required', 'in:home_yard,open_land,pot'],
            'soil_type' => ['required', 'in:fertile,clay,sandy,chalky,volcanic,peat,artificial_media'],
            'city' => ['required', 'string', 'max:100'],
            'province' => ['required', 'string', 'max:100'],
        ]);

        try {
            $result = $this->gemini->recommendPlants($validated);
        } catch (Throwable $e) {
            throw new RuntimeException('Gagal mendapatkan rekomendasi tanaman.', 0, $e);
        }

        return response()->json($result, 200);
    }

    public function plantSuitability(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'plant_name' => ['required', 'string', 'max:150'],
            'planting_medium' => ['required', 'in:home_yard,open_land,pot'],
            'soil_type' => ['required', 'in:fertile,clay,sandy,chalky,volcanic,peat,artificial_media'],
            'city' => ['required', 'string', 'max:100'],
            'province' => ['required', 'string', 'max:100'],
        ]);

        try {
            $result = $this->gemini->checkSuitability($validated);
        } catch (Throwable $e) {
            throw new RuntimeException('Gagal mengevaluasi tanaman.', 0, $e);
        }

        return response()->json($result, 200);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'location_id' => ['required', 'integer', 'exists:locations,id'],
            'plant_name' => ['required', 'string', 'max:150'],
            'planting_medium' => ['required', 'in:home_yard,open_land,pot'],
            'soil_type' => ['required', 'in:fertile,clay,sandy,chalky,volcanic,peat,artificial_media'],
            'current_phase' => ['required', 'in:seedling,early_vegetative,late_vegetative,generative'],
            'planting_date' => ['required', 'date', 'before_or_equal:today'],
        ]);

        if (! $this->ownsLocation($request, (int) $validated['location_id'])) {
            throw new AccessDeniedHttpException;
        }

        $location = Location::findOrFail($validated['location_id']);

        try {
            $config = $this->gemini->generateCareConfig([
                'plant_name' => $validated['plant_name'],
                'planting_medium' => $validated['planting_medium'],
                'soil_type' => $validated['soil_type'],
                'city' => $location->city,
                'province' => $location->province,
            ]);
        } catch (Throwable $e) {
            throw new RuntimeException('Gagal menghasilkan jadwal perawatan.', 0, $e);
        }

        $plant = UserPlant::create([
            'user_id' => $request->user()->id,
            'location_id' => $validated['location_id'],
            'plant_name' => $validated['plant_name'],
            'planting_medium' => $validated['planting_medium'],
            'soil_type' => $validated['soil_type'],
            'current_phase' => $validated['current_phase'],
            'phase_start_date' => $validated['planting_date'],
            'planting_date' => $validated['planting_date'],
            'watering_config' => $config['watering_config'],
            'fertilizing_config' => $config['fertilizing_config'],
            'status' => 'active',
        ]);

        return response()->json([
            'plant' => new UserPlantResource($plant->load('location')),
        ], 201);
    }

    private function ownsLocation(Request $request, int $locationId): bool
    {
        return Location::where('id', $locationId)
            ->where('user_id', $request->user()->id)
            ->exists();
    }
}
