<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\LocationResource;
use App\Models\Location;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class LocationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $locations = $request->user()
            ->locations()
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'data' => LocationResource::collection($locations),
        ], 200);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'label' => ['required', 'string', 'max:100'],
            'city' => ['required', 'string', 'max:100'],
            'province' => ['nullable', 'string', 'max:100'],
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
        ]);

        $location = $request->user()->locations()->create($validated);

        return response()->json([
            'location' => new LocationResource($location),
        ], 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $location = $this->resolveOwnedLocation($request, $id);

        $validated = $request->validate([
            'label' => ['sometimes', 'string', 'max:100'],
            'city' => ['sometimes', 'string', 'max:100'],
            'province' => ['sometimes', 'nullable', 'string', 'max:100'],
            'latitude' => ['sometimes', 'nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180'],
        ]);

        $location->update($validated);

        return response()->json([
            'location' => new LocationResource($location),
        ], 200);
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        $location = $this->resolveOwnedLocation($request, $id);

        $plantCount = $location->userPlants()->count();

        if ($plantCount > 0) {
            return response()->json([
                'message' => "Lokasi ini masih dipakai {$plantCount} tanaman. "
                    .'Pindahkan atau hapus tanamannya lebih dulu.',
                'errors' => [
                    'location' => ['Lokasi masih dipakai tanaman.'],
                ],
                'plant_count' => $plantCount,
            ], 409);
        }

        $location->delete();

        return response()->json(null, 204);
    }

    private function resolveOwnedLocation(Request $request, int $id): Location
    {
        $location = Location::with('user')->find($id);

        if ($location === null) {
            throw (new ModelNotFoundException)->setModel(Location::class, $id);
        }

        if ($location->user_id !== $request->user()->id) {
            throw new AccessDeniedHttpException;
        }

        return $location;
    }
}
