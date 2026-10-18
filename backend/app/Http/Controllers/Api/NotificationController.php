<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Models\Notification;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = $request->user()->notifications();

        if ($request->has('is_read')) {
            $query->where('is_read', filter_var($request->query('is_read'), FILTER_VALIDATE_BOOLEAN));
        }

        $notifications = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'data' => NotificationResource::collection($notifications),
        ], 200);
    }

    public function markAsRead(Request $request, int $id): JsonResponse
    {
        $notification = Notification::find($id);

        if ($notification === null) {
            throw (new ModelNotFoundException)->setModel(Notification::class, $id);
        }

        if ($notification->user_id !== $request->user()->id) {
            throw new AccessDeniedHttpException;
        }

        $notification->update(['is_read' => true]);

        return response()->json([
            'notification' => new NotificationResource($notification),
        ], 200);
    }

    public function readAll(Request $request): JsonResponse
    {
        $request->user()->notifications()
            ->where('is_read', false)
            ->update(['is_read' => true]);

        return response()->json(['message' => 'Semua notifikasi ditandai sudah dibaca.'], 200);
    }
}
