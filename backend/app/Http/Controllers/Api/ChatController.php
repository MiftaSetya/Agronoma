<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ChatMessageResource;
use App\Models\ChatMessage;
use App\Models\ChatSession;
use App\Models\UserPlant;
use App\Services\GeminiService;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Throwable;

class ChatController extends Controller
{
    private const SYSTEM_INSTRUCTION = <<<'PROMPT'
Kamu adalah AI Agronomist di aplikasi Agronoma, asisten cerdas untuk membantu petani rumahan/perkarangan merawat tanaman mereka.

TUGAS:
- Jawab pertanyaan seputar perawatan tanaman, hama & penyakit, pupuk, penyiraman, dan kondisi agronomis lainnya.
- Utamakan jawaban praktis, ringkas, dan mudah dipahami pengguna awam dalam Bahasa Indonesia.
- Jika konteks tanaman tertentu diberikan, gunakan informasi tersebut untuk jawaban yang lebih personal.
PROMPT;

    public function __construct(private readonly GeminiService $gemini) {}

    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'plant_id' => ['nullable', 'integer'],
        ]);

        $query = $request->user()->chatSessions()->newQuery();

        $plantId = $validated['plant_id'] ?? null;
        if ($plantId !== null) {
            $query->where('context_plant_id', (int) $plantId);
        }

        $session = $query->latest('id')->first();

        if ($session === null) {
            return response()->json(['chat_session' => null], 200);
        }

        return response()->json([
            'chat_session' => [
                'id' => $session->id,
                'context_plant_id' => $session->context_plant_id,
                'created_at' => $session->created_at,
            ],
        ], 200);
    }

    public function createSession(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'context_plant_id' => ['nullable', 'integer', 'exists:user_plants,id'],
        ]);

        $contextPlantId = $validated['context_plant_id'] ?? null;

        if ($contextPlantId !== null && ! $this->ownsPlant($request, (int) $contextPlantId)) {
            throw new AccessDeniedHttpException;
        }

        $session = $request->user()->chatSessions()->create([
            'context_plant_id' => $contextPlantId,
        ]);

        return response()->json([
            'chat_session' => [
                'id' => $session->id,
                'context_plant_id' => $session->context_plant_id,
                'created_at' => $session->created_at,
            ],
        ], 201);
    }

    public function getMessages(Request $request, int $id): JsonResponse
    {
        $session = $this->resolveOwnedSession($request, $id);

        $messages = $session->messages()->orderBy('created_at')->get();

        return response()->json([
            'data' => ChatMessageResource::collection($messages),
        ], 200);
    }

    public function sendMessage(Request $request, int $id): JsonResponse
    {
        $session = $this->resolveOwnedSession($request, $id);

        $validated = $request->validate([
            'content' => ['required', 'string', 'max:4000'],
        ]);

        $history = $session->messages()
            ->orderBy('created_at')
            ->get()
            ->map(fn (ChatMessage $message): array => [
                'role' => $message->role,
                'parts' => $message->content,
            ])
            ->all();

        $history[] = [
            'role' => 'user',
            'parts' => $validated['content'],
        ];

        try {
            $reply = $this->gemini->chat($this->buildSystemInstruction($session), $history);
        } catch (Throwable $e) {
            throw new RuntimeException('Gagal mendapatkan respons dari asisten.', 0, $e);
        }

        $userMessage = ChatMessage::create([
            'session_id' => $session->id,
            'role' => 'user',
            'content' => $validated['content'],
        ]);

        $aiMessage = ChatMessage::create([
            'session_id' => $session->id,
            'role' => 'ai',
            'content' => $reply,
        ]);

        return response()->json([
            'user_message' => new ChatMessageResource($userMessage),
            'ai_message' => new ChatMessageResource($aiMessage),
        ], 201);
    }

    private function buildSystemInstruction(ChatSession $session): string
    {
        $contextPlant = $session->contextPlant;

        if ($contextPlant === null) {
            return self::SYSTEM_INSTRUCTION;
        }

        return self::SYSTEM_INSTRUCTION."\n\n"
            .'KONTEKS TANAMAN PENGGUNA SAAT INI:'."\n"
            ."- Nama tanaman: {$contextPlant->plant_name}\n"
            ."- Media tanam: {$contextPlant->planting_medium}\n"
            ."- Jenis tanah: {$contextPlant->soil_type}\n"
            ."- Fase pertumbuhan: {$contextPlant->current_phase}\n"
            .'- Tanggal tanam: '.$contextPlant->planting_date?->toDateString();
    }

    private function ownsPlant(Request $request, int $plantId): bool
    {
        return UserPlant::where('id', $plantId)
            ->where('user_id', $request->user()->id)
            ->exists();
    }

    private function resolveOwnedSession(Request $request, int $id): ChatSession
    {
        $session = ChatSession::with('contextPlant')->find($id);

        if ($session === null) {
            throw (new ModelNotFoundException)->setModel(ChatSession::class, $id);
        }

        if ($session->user_id !== $request->user()->id) {
            throw new AccessDeniedHttpException;
        }

        return $session;
    }
}
