<?php

namespace App\Console\Commands;

use App\Models\Notification;
use App\Models\User;
use App\Models\UserPlant;
use App\Models\WateringLog;
use App\Services\FcmService;
use App\Services\WeatherApiService;
use Carbon\Carbon;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Collection;

#[Signature('agronoma:daily-processing')]
#[Description('Cronjob harian: fetch cuaca 7 hari, finalisasi konfirmasi, mesin keputusan penyiraman, kirim notifikasi gabungan.')]
class AgronomaDailyProcessing extends Command
{
    private const PHASES = ['seedling', 'early_vegetative', 'late_vegetative', 'generative'];

    public function __construct(
        private readonly WeatherApiService $weatherApiService,
        private readonly FcmService $fcmService,
    ) {
        parent::__construct();
    }

    public function handle(): int
    {
        $plants = UserPlant::with('location')
            ->where('status', 'active')
            ->orderBy('id')
            ->get();

        $this->fetchAndStoreWeather($plants);

        $this->finalizePendingConfirmations();

        $plantNotifications = $this->processPlants($plants);

        $this->sendNotifications($plantNotifications);

        $this->info('Agronoma daily processing selesai.');

        return self::SUCCESS;
    }

    private function fetchAndStoreWeather(Collection $plants): void
    {
        $groups = $plants->groupBy(fn (UserPlant $plant) => $plant->location->city.'|'.$plant->location->province);

        foreach ($groups as $group) {
            $location = $group->first()->location;
            $city = $location->city;
            $province = $location->province;

            try {
                $forecast = $this->weatherApiService->forecast7Days($city);
                $this->weatherApiService->upsertCache($city, $province, $forecast);
            } catch (\Throwable $e) {
                $this->warn("Gagal memperbarui cuaca untuk {$city}: {$e->getMessage()}");
            }
        }
    }

    private function finalizePendingConfirmations(): void
    {
        $yesterday = now()->subDay()->toDateString();

        $pendingRain = WateringLog::with('userPlant')
            ->where('status', 'skip_rain')
            ->where('rain_confirmed', 'not_answered')
            ->whereDate('scheduled_date', $yesterday)
            ->get();

        foreach ($pendingRain as $log) {
            $log->update(['rain_confirmed' => 'yes']);

            if ($log->userPlant !== null) {
                $log->userPlant->forceFill([
                    'last_watered_date' => $log->scheduled_date->toDateString(),
                ])->save();
            }
        }

        $pendingMoisture = WateringLog::where('status', 'partial_rain')
            ->where('user_moisture_feedback', 'not_answered')
            ->whereDate('scheduled_date', $yesterday)
            ->get();

        foreach ($pendingMoisture as $log) {
            $log->update(['user_moisture_feedback' => 'moist']);
        }
    }

    private function processPlants(Collection $plants): array
    {
        $result = [];

        foreach ($plants as $plant) {
            $this->checkPhaseTransition($plant, $result);

            $phaseConfig = $plant->phaseConfig();

            if ($phaseConfig === null) {
                continue;
            }

            $effectiveDueDate = $plant->effectiveWateringDueDate();

            if ($effectiveDueDate === null || Carbon::today()->lessThan($effectiveDueDate)) {
                continue;
            }

            if ($this->alreadyLoggedToday($plant)) {
                continue;
            }

            $this->makeWateringDecision($plant, $phaseConfig, $result);
        }

        return $result;
    }

    private function alreadyLoggedToday(UserPlant $plant): bool
    {
        return $plant->wateringLogs()
            ->whereDate('scheduled_date', Carbon::today())
            ->exists();
    }

    private function checkPhaseTransition(UserPlant $plant, array &$result): void
    {
        $phaseConfig = $plant->phaseConfig();

        if ($phaseConfig === null || ($phaseConfig['duration_days'] ?? null) === null) {
            return;
        }

        $elapsed = (int) Carbon::parse($plant->phase_start_date)->diffInDays(Carbon::today());

        if ($elapsed >= (int) $phaseConfig['duration_days']) {
            $index = array_search($plant->current_phase, self::PHASES, true);

            if ($index !== false && isset(self::PHASES[$index + 1])) {
                $nextPhase = self::PHASES[$index + 1];

                $plant->forceFill([
                    'current_phase' => $nextPhase,
                    'phase_start_date' => Carbon::today()->toDateString(),
                ])->save();

                $result[$plant->user_id]['phase_changes'][] = [
                    'plant_id' => $plant->id,
                    'plant_name' => $plant->plant_name,
                    'message' => "{$plant->plant_name} memasuki fase {$nextPhase}.",
                ];
            }
        }
    }

    private function makeWateringDecision(UserPlant $plant, array $phaseConfig, array &$result): void
    {
        $location = $plant->location;
        $city = $location->city;
        $province = $location->province;
        $today = Carbon::today();

        $weatherToday = $this->weatherApiService->getCacheForDate($city, $province, $today->toDateString());

        $lookaheadDays = (int) ($phaseConfig['lookahead_days'] ?? 2);

        $weatherLookahead = $this->weatherApiService->getCacheForRange(
            $city,
            $province,
            $today->copy()->addDay()->toDateString(),
            $today->copy()->addDays($lookaheadDays)->toDateString(),
        );

        $todayRainfall = $weatherToday?->rainfall_mm ?? 0;
        $minSignificant = (float) ($phaseConfig['min_significant_rain_mm'] ?? 5);
        $rainEquivalent = (float) ($phaseConfig['rain_equivalent_full_mm'] ?? 10);
        $probThreshold = (int) ($phaseConfig['rain_prob_threshold'] ?? 40);
        $maxDelay = (int) ($phaseConfig['max_delay_days'] ?? 1);

        $streakAtTime = (int) $plant->delay_streak_days;

        $status = 'need_water';
        $rainConfirmed = null;
        $moistureFeedback = null;
        $delayMessage = null;

        if ($todayRainfall >= $rainEquivalent) {

            $status = 'skip_rain';
            $rainConfirmed = 'not_answered';
            $result[$plant->user_id]['rain_confirm_plants'][] = $plant->id;
            $result[$plant->user_id]['notification_lines'][] = "Diperkirakan hujan cukup untuk {$plant->plant_name} hari ini. Benar terjadi hujan?";
        } elseif ($todayRainfall >= $minSignificant) {

            $status = 'partial_rain';
            $moistureFeedback = 'not_answered';
            $plant->forceFill(['adjusted_due_date' => $today->copy()->addDay()->toDateString()])->save();
            $result[$plant->user_id]['partial_plants'][] = $plant->id;
            $result[$plant->user_id]['notification_lines'][] = "Hujan membantu sebagian untuk {$plant->plant_name}, kami cek kondisi tanahnya besok pagi.";
        } else {
            $rainExpected = $weatherLookahead->first(function ($day) use ($probThreshold, $minSignificant) {
                return $day->rain_probability_percent >= $probThreshold || $day->rainfall_mm >= $minSignificant;
            });

            if ($rainExpected !== null && $streakAtTime < $maxDelay) {

                $status = 'delayed_rain_expected';
                $plant->forceFill([
                    'adjusted_due_date' => $today->copy()->addDay()->toDateString(),
                    'delay_streak_days' => $streakAtTime + 1,
                ])->save();
                $result[$plant->user_id]['delayed_plants'][] = $plant->id;
                $result[$plant->user_id]['notification_lines'][] = sprintf(
                    'Penyiraman %s ditunda, hujan diprediksi %s (%d%% / %.1fmm).',
                    $plant->plant_name,
                    $rainExpected->date->toDateString(),
                    $rainExpected->rain_probability_percent,
                    $rainExpected->rainfall_mm,
                );
            } else {

                $status = 'need_water';
                $plant->forceFill(['delay_streak_days' => 0])->save();
                $result[$plant->user_id]['need_water_plants'][] = $plant->id;
                $result[$plant->user_id]['notification_lines'][] = $streakAtTime > 0
                    ? "Prediksi hujan meleset, saatnya siram {$plant->plant_name} sekarang."
                    : "Saatnya siram {$plant->plant_name} hari ini.";
            }
        }

        WateringLog::create([
            'user_plant_id' => $plant->id,
            'phase_at_time' => $plant->current_phase,
            'scheduled_date' => $today->toDateString(),
            'actual_date' => null,
            'status' => $status,
            'delay_streak_at_time' => $streakAtTime,
            'rain_confirmed' => $rainConfirmed,
            'user_moisture_feedback' => $moistureFeedback,
            'weather_snapshot' => [
                'today' => [
                    'condition' => $weatherToday?->condition,
                    'rainfall_mm' => $weatherToday?->rainfall_mm,
                    'rain_probability_percent' => $weatherToday?->rain_probability_percent,
                    'temp_min' => $weatherToday?->temp_min,
                    'temp_max' => $weatherToday?->temp_max,
                ],
            ],
        ]);
    }

    private function sendNotifications(array $result): void
    {
        foreach ($result as $userId => $data) {
            $user = User::find($userId);

            if ($user === null) {
                continue;
            }

            $phaseChanges = $data['phase_changes'] ?? [];
            $lines = $data['notification_lines'] ?? [];
            $reminderEnabled = ($user->preferences['watering_reminder_enabled'] ?? true) !== false;

            if ($lines !== [] && $reminderEnabled) {
                $relatedPlantIds = array_values(array_unique(array_merge(
                    $data['need_water_plants'] ?? [],
                    $data['delayed_plants'] ?? [],
                    $data['partial_plants'] ?? [],
                    $data['rain_confirm_plants'] ?? [],
                )));

                Notification::create([
                    'user_id' => $userId,
                    'type' => 'watering',
                    'related_plant_ids' => $relatedPlantIds,
                    'message' => $lines[0].(count($lines) > 1 ? ' ('.count($lines).' tanaman)' : ''),
                    'sent_at' => now(),
                    'is_read' => false,
                ]);

                $this->fcmService->send($user->push_token, 'Agronoma', $lines[0]);
            }

            foreach ($phaseChanges as $phaseChange) {
                Notification::create([
                    'user_id' => $userId,
                    'type' => 'phase_change',
                    'related_plant_ids' => [$phaseChange['plant_id']],
                    'message' => $phaseChange['message'],
                    'sent_at' => now(),
                    'is_read' => false,
                ]);

                $this->fcmService->send($user->push_token, 'Agronoma', $phaseChange['message']);
            }
        }
    }
}
