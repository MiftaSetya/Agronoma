<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CareActionController;
use App\Http\Controllers\Api\ChatController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\LocationController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PestScanController;
use App\Http\Controllers\Api\PlantController;
use App\Http\Controllers\Api\PlantWizardController;
use App\Http\Controllers\Api\ProfileController;
use Illuminate\Support\Facades\Route;

Route::post('register', [AuthController::class, 'register']);
Route::post('login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('logout', [AuthController::class, 'logout']);
    Route::get('user', [AuthController::class, 'user']);
    Route::post('device-token', [AuthController::class, 'deviceToken']);

    Route::get('locations', [LocationController::class, 'index']);
    Route::post('locations', [LocationController::class, 'store']);
    Route::patch('locations/{id}', [LocationController::class, 'update'])->whereNumber('id');
    Route::delete('locations/{id}', [LocationController::class, 'destroy'])->whereNumber('id');

    Route::post('soil-scan', [PlantWizardController::class, 'soilScan']);
    Route::post('plant-recommendations', [PlantWizardController::class, 'plantRecommendations']);
    Route::post('plant-suitability', [PlantWizardController::class, 'plantSuitability']);
    Route::post('plants', [PlantWizardController::class, 'store']);

    Route::get('plants', [PlantController::class, 'index']);
    Route::get('plants/{id}', [PlantController::class, 'show'])->whereNumber('id');
    Route::get('plants/{id}/weather', [PlantController::class, 'weather'])->whereNumber('id');
    Route::get('plants/{id}/care-calendar', [PlantController::class, 'careCalendar'])->whereNumber('id');
    Route::patch('plants/{id}', [PlantController::class, 'update'])->whereNumber('id');
    Route::delete('plants/{id}', [PlantController::class, 'destroy'])->whereNumber('id');

    Route::post('plants/{id}/watering/complete', [CareActionController::class, 'completeWatering'])->whereNumber('id');
    Route::post('plants/{id}/watering/postpone', [CareActionController::class, 'postponeWatering'])->whereNumber('id');
    Route::post('watering-logs/{id}/rain-confirm', [CareActionController::class, 'rainConfirm'])->whereNumber('id');
    Route::post('watering-logs/{id}/moisture-feedback', [CareActionController::class, 'moistureFeedback'])->whereNumber('id');
    Route::post('plants/{id}/fertilizing/complete', [CareActionController::class, 'completeFertilizing'])->whereNumber('id');

    Route::post('pest-scans', [PestScanController::class, 'store']);
    Route::get('pest-scans', [PestScanController::class, 'index']);

    Route::get('notifications', [NotificationController::class, 'index']);
    Route::patch('notifications/{id}/read', [NotificationController::class, 'markAsRead'])->whereNumber('id');
    Route::patch('notifications/read-all', [NotificationController::class, 'readAll']);

    Route::post('chat-sessions', [ChatController::class, 'createSession']);
    Route::get('chat-sessions/{id}/messages', [ChatController::class, 'getMessages'])->whereNumber('id');
    Route::post('chat-sessions/{id}/messages', [ChatController::class, 'sendMessage'])->whereNumber('id');

    Route::get('dashboard', [DashboardController::class, 'index']);
    Route::get('profile', [ProfileController::class, 'show']);
    Route::patch('profile/preferences', [ProfileController::class, 'updatePreferences']);
    Route::post('profile/photo', [ProfileController::class, 'uploadPhoto']);
});

Route::get('/', function () {
    return response()->json([
        'status' => 'error',
        'message' => 'Anda tidak berhak mengakses sumber daya ini.',
    ], 401);
});
