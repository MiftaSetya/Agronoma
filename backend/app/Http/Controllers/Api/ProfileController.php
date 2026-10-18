<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\WateringLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        $totalPlants = $user->userPlants()->where('status', 'active')->count();
        $harvestedCount = $user->userPlants()->where('status', 'archived')->count();

        $careScorePercent = $this->careScorePercent($user);

        return response()->json([
            'total_plants' => $totalPlants,
            'harvested_count' => $harvestedCount,
            'care_score_percent' => $careScorePercent,
            'preferences' => $user->preferences ?? $this->defaultPreferences(),
        ], 200);
    }

    public function updatePreferences(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'watering_reminder_enabled' => ['required', 'boolean'],
        ]);

        $preferences = array_merge(
            $request->user()->preferences ?? $this->defaultPreferences(),
            ['watering_reminder_enabled' => $validated['watering_reminder_enabled']],
        );

        $request->user()->update(['preferences' => $preferences]);

        return response()->json([
            'preferences' => $preferences,
        ], 200);
    }

    public function uploadPhoto(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'image' => ['required', 'image', 'max:5120'],
        ]);

        $user = $request->user();
        $oldPhoto = $user->photo;
        $image = $validated['image'];

        $path = $image->store('photos/profile', 'public');

        $user->update(['photo' => $path]);

        if ($oldPhoto !== null) {
            Storage::disk('public')->delete($oldPhoto);
        }

        return response()->json([
            'photo_url' => $user->photoUrl(),
        ], 200);
    }

    private function defaultPreferences(): array
    {
        return ['watering_reminder_enabled' => true];
    }

    private function careScoreCounts(User $user): array
    {
        $logs = WateringLog::query()
            ->whereIn('user_plant_id', $user->userPlants()->select('id'))
            ->get(['scheduled_date', 'status', 'rain_confirmed', 'user_moisture_feedback']);

        $perDay = [];

        foreach ($logs as $log) {
            $date = $log->scheduled_date?->toDateString();

            if ($date === null) {
                continue;
            }

            $entry = $perDay[$date] ?? ['done' => false, 'owed' => false];

            if ($log->status === 'watered') {
                $entry['done'] = true;
                $entry['owed'] = true;
            } elseif ($log->status === 'need_water') {
                $entry['owed'] = true;
            } elseif (
                $log->rain_confirmed === 'yes'
                || $log->user_moisture_feedback === 'moist'
            ) {

                $entry['done'] = true;
            }

            $perDay[$date] = $entry;
        }

        $owed = 0;
        $done = 0;

        foreach ($perDay as $entry) {
            if (! $entry['owed']) {
                continue;
            }

            $owed++;

            if ($entry['done']) {
                $done++;
            }
        }

        return [$done, $owed];
    }

    private function careScorePercent(User $user): int
    {
        [$done, $owed] = $this->careScoreCounts($user);

        if ($owed === 0) {
            return 100;
        }

        return (int) round(($done / $owed) * 100);
    }
}
