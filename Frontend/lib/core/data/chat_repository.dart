import 'package:frontend/core/data/api/api_client.dart';
import 'package:frontend/core/data/api/api_exception.dart';

abstract class ChatRepository {
  Future<int> createSession({String? plantId});

  Future<int?> findSession({String? plantId});

  Future<List<Map<String, String>>> getMessages(int sessionId);

  Future<Map<String, String>> sendMessage(int sessionId, String content);
}

class HttpChatRepository implements ChatRepository {
  HttpChatRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  @override
  Future<int> createSession({String? plantId}) async {
    final body = await _api.post(
      'chat-sessions',
      body: {
        'context_plant_id': plantId == null || plantId.isEmpty
            ? null
            : int.tryParse(plantId),
      },
    );

    final session = body is Map<String, dynamic> ? body['chat_session'] : null;
    final id = session is Map<String, dynamic> ? session['id'] : null;
    if (id is! int) {
      throw const ApiException(
        message: 'Sesi obrolan gagal dibuat.',
        statusCode: 500,
      );
    }
    return id;
  }

  @override
  Future<int?> findSession({String? plantId}) async {
    final query = plantId == null || plantId.isEmpty
        ? ''
        : '?plant_id=${Uri.encodeQueryComponent(plantId)}';
    final body = await _api.get('chat-sessions$query');
    final session = body is Map<String, dynamic> ? body['chat_session'] : null;
    if (session == null) return null;
    final id = session is Map<String, dynamic> ? session['id'] : null;
    return id is int ? id : null;
  }

  @override
  Future<List<Map<String, String>>> getMessages(int sessionId) async {
    final body = await _api.get('chat-sessions/$sessionId/messages');
    final raw = body is Map<String, dynamic> ? body['data'] : null;
    if (raw is! List) return const [];

    return [
      for (final item in raw)
        if (item is Map<String, dynamic> && item['content'] is String)
          {
            'role': '${item['role'] ?? 'ai'}',
            'content': item['content'] as String,
          },
    ];
  }

  @override
  Future<Map<String, String>> sendMessage(int sessionId, String content) async {
    final body = await _api.post(
      'chat-sessions/$sessionId/messages',
      body: {'content': content.trim()},
    );

    final ai = body is Map<String, dynamic> ? body['ai_message'] : null;
    final text = ai is Map<String, dynamic> ? ai['content'] : null;
    if (text is! String) {
      throw const ApiException(
        message: 'Balasan asisten tidak dikenali.',
        statusCode: 500,
      );
    }
    return {'role': 'ai', 'content': text};
  }
}

class SampleChatRepository implements ChatRepository {
  static const String _echo =
      'Ini mode contoh, jadi saya belum terhubung ke asisten AI. '
      'Coba jalankan aplikasi dengan server asli.';

  int _nextId = 1;

  @override
  Future<int> createSession({String? plantId}) async => _nextId++;

  @override
  Future<int?> findSession({String? plantId}) async => null;

  @override
  Future<List<Map<String, String>>> getMessages(int sessionId) async =>
      const [];

  @override
  Future<Map<String, String>> sendMessage(int sessionId, String content) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const {'role': 'ai', 'content': _echo};
  }
}
