<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PestScanResource;
use App\Models\PestScanHistory;
use App\Models\UserPlant;
use App\Services\GeminiService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Throwable;

class PestScanController extends Controller
{
    public function __construct(private readonly GeminiService $gemini)
    {
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'image' => ['required', 'image', 'max:5120'],
            'user_plant_id' => ['nullable', 'integer', 'exists:user_plants,id'],
        ]);

        $plantId = $validated['user_plant_id'] ?? null;

        if ($plantId !== null && ! $this->ownsPlant($request, (int) $plantId)) {
            throw new AccessDeniedHttpException;
        }

        $image = $request->file('image');
        $path = $image->store('scans/pest', 'public');

        try {
            $result = $this->gemini->detectPest(
                base64_encode(file_get_contents($image->getRealPath())),
                $image->getMimeType(),
            );
        } catch (Throwable $e) {
            throw new RuntimeException('Gagal menganalisis foto tanaman.', 0, $e);
        }

        $scan = PestScanHistory::create([
            'user_id' => $request->user()->id,
            'user_plant_id' => $plantId,
            'image_url' => asset('storage/'.$path),
            'detected_pest_name' => $result['detected_pest_name'] ?? null,
            'ai_confidence' => $result['ai_confidence'] ?? null,
            'ai_raw_response' => $result,
            'recommended_action' => $result['recommended_action'] ?? null,
        ]);

        return response()->json(new PestScanResource($scan), 201);
    }

    public function index(Request $request): JsonResponse
    {
        $query = $request->user()->pestScanHistories();

        if ($request->has('user_plant_id')) {
            $query->where('user_plant_id', $request->query('user_plant_id'));
        }

        $scans = $query->orderBy('scanned_at', 'desc')->get();

        return response()->json([
            'data' => PestScanResource::collection($scans),
        ], 200);
    }

    private function ownsPlant(Request $request, int $plantId): bool
    {
        return UserPlant::where('id', $plantId)
            ->where('user_id', $request->user()->id)
            ->exists();
    }
}
