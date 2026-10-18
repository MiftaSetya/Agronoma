<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\FertilizingLogResource;
use App\Http\Resources\WateringLogResource;
use App\Models\FertilizingLog;
use App\Models\UserPlant;
use App\Models\WateringLog;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class CareActionController extends Controller
{
    public function completeWatering(Request $request, int $plantId): JsonResponse
    {
        $plant = $this->resolveOwnedPlant($request, $plantId);

        $exists = $plant->wateringLogs()
            ->whereDate('scheduled_date', today())
            ->where('status', 'watered')
            ->exists();

        if ($exists) {
            return response()->json([
                'message' => 'Penyiraman sudah diselesaikan hari ini.',
            ], 409);
        }

        $log = $this->recordWatering($plant, scheduledDate: today()->toDateString(), status: 'watered');

        $plant->forceFill([
            'last_watered_date' => today()->toDateString(),
            'adjusted_due_date' => null,
            'delay_streak_days' => 0,
        ])->save();

        return response()->json([
            'watering_log' => new WateringLogResource($log),
        ], 200);
    }

    public function postponeWatering(Request $request, int $plantId): JsonResponse
    {
        $plant = $this->resolveOwnedPlant($request, $plantId);

        if ($this->hasLogToday($plant, ['delayed_rain_expected', 'watered'])) {
            return response()->json([
                'message' => 'Jadwal penyiraman hari ini sudah diputuskan.',
            ], 409);
        }

        $log = $this->recordWatering($plant, scheduledDate: today()->toDateString(), status: 'delayed_rain_expected');

        $plant->forceFill([
            'adjusted_due_date' => today()->addDay()->toDateString(),
            'delay_streak_days' => $plant->delay_streak_days + 1,
        ])->save();

        return response()->json([
            'watering_log' => new WateringLogResource($log),
        ], 200);
    }

    public function rainConfirm(Request $request, int $id): JsonResponse
    {
        $log = $this->resolveOwnedWateringLog($request, $id);

        $request->validate([
            'rain_confirmed' => ['required', 'in:yes,no'],
        ]);

        $log->update([
            'rain_confirmed' => $request->input('rain_confirmed'),
            'actual_date' => $log->scheduled_date->toDateString(),
        ]);

        $plant = $log->userPlant;

        if ($request->input('rain_confirmed') === 'yes') {
            $plant->forceFill([
                'last_watered_date' => $log->scheduled_date->toDateString(),
                'adjusted_due_date' => null,
                'delay_streak_days' => 0,
            ])->save();
        } else {

            $this->triggerNeedWater($plant);
        }

        return response()->json([
            'watering_log' => new WateringLogResource($log),
        ], 200);
    }

    public function moistureFeedback(Request $request, int $id): JsonResponse
    {
        $log = $this->resolveOwnedWateringLog($request, $id);

        $request->validate([
            'user_moisture_feedback' => ['required', 'in:moist,dry'],
        ]);

        $log->update([
            'user_moisture_feedback' => $request->input('user_moisture_feedback'),
            'actual_date' => $log->scheduled_date->toDateString(),
        ]);

        if ($request->input('user_moisture_feedback') === 'dry') {

            $log->userPlant->forceFill([
                'adjusted_due_date' => null,
                'delay_streak_days' => 0,
            ])->save();

            $this->triggerNeedWater($log->userPlant);
        }

        return response()->json([
            'watering_log' => new WateringLogResource($log),
        ], 200);
    }

    public function completeFertilizing(Request $request, int $plantId): JsonResponse
    {
        $plant = $this->resolveOwnedPlant($request, $plantId);

        $scheduledDate = today()->toDateString();

        $alreadyFertilized = $plant->fertilizingLogs()
            ->whereDate('scheduled_date', $scheduledDate)
            ->where('status', 'fertilized')
            ->exists();

        if ($alreadyFertilized) {
            return response()->json([
                'message' => 'Pemupukan sudah diselesaikan hari ini.',
            ], 409);
        }

        $log = FertilizingLog::create([
            'user_plant_id' => $plant->id,
            'scheduled_date' => $scheduledDate,
            'actual_date' => $scheduledDate,
            'status' => 'fertilized',
            'fertilizer_description' => $this->fertilizerDescriptionFor($plant),
        ]);

        $plant->forceFill(['last_fertilized_date' => $scheduledDate])->save();

        return response()->json([
            'fertilizing_log' => new FertilizingLogResource($log),
        ], 200);
    }

    private function recordWatering(UserPlant $plant, string $scheduledDate, string $status): WateringLog
    {
        return WateringLog::create([
            'user_plant_id' => $plant->id,
            'phase_at_time' => $plant->current_phase,
            'scheduled_date' => $scheduledDate,
            'actual_date' => today()->toDateString(),
            'status' => $status,
            'delay_streak_at_time' => $plant->delay_streak_days,
            'rain_confirmed' => null,
            'user_moisture_feedback' => null,
        ]);
    }

    private function triggerNeedWater(UserPlant $plant): void
    {

        $exists = $plant->wateringLogs()
            ->whereDate('scheduled_date', today())
            ->where('status', 'need_water')
            ->exists();

        if ($exists) {
            return;
        }

        WateringLog::create([
            'user_plant_id' => $plant->id,
            'phase_at_time' => $plant->current_phase,
            'scheduled_date' => today()->toDateString(),
            'actual_date' => null,
            'status' => 'need_water',
            'delay_streak_at_time' => $plant->delay_streak_days,
        ]);
    }

    private function fertilizerDescriptionFor(UserPlant $plant): ?string
    {
        $schedule = $plant->fertilizing_config['phase_schedule'] ?? [];

        return collect($schedule)->firstWhere('phase', $plant->current_phase)['fertilizer_description'] ?? null;
    }

    private function hasLogToday(UserPlant $plant, array $statuses): bool
    {
        return $plant->wateringLogs()
            ->whereDate('scheduled_date', today())
            ->whereIn('status', $statuses)
            ->exists();
    }

    private function resolveOwnedPlant(Request $request, int $plantId): UserPlant
    {
        $plant = UserPlant::find($plantId);

        if ($plant === null) {
            throw (new ModelNotFoundException)->setModel(UserPlant::class, $plantId);
        }

        if ($plant->user_id !== $request->user()->id) {
            throw new AccessDeniedHttpException;
        }

        if ($plant->status !== 'active') {
            throw new HttpResponseException(response()->json([
                'message' => 'Tanaman ini sudah diarsipkan dan tidak bisa dirawat lagi.',
                'errors' => ['plant' => ['Tanaman sudah diarsipkan.']],
            ], 409));
        }

        return $plant;
    }

    private function resolveOwnedWateringLog(Request $request, int $logId): WateringLog
    {
        $log = WateringLog::with('userPlant')->find($logId);

        if ($log === null) {
            throw (new ModelNotFoundException)->setModel(WateringLog::class, $logId);
        }

        if ($log->userPlant->user_id !== $request->user()->id) {
            throw new AccessDeniedHttpException;
        }

        return $log;
    }
}
