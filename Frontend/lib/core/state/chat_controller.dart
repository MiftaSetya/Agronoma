import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/chat_repository.dart';
import 'package:frontend/core/data/disease_repository.dart';
import 'package:frontend/core/models/chat_message.dart';
import 'package:frontend/core/models/disease.dart';

class ChatController extends ChangeNotifier {
  ChatController({required this.chatSource, required DiseaseRepository detector})
    : _diseaseRepository = detector;

  final ChatRepository chatSource;
  final DiseaseRepository _diseaseRepository;

  final List<ChatMessage> _messages = [];
  bool _typing = false;
  bool _sending = false;
  Object? _error;
  int? _sessionId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _typing;
  bool get isSending => _sending;
  Object? get error => _error;

  static ChatMessage get _greeting {
    return const ChatMessage(
      author: ChatAuthor.bot,
      text:
          'Halo! Saya Agronoma AI. Tanya apa saja soal tanamanmu — penyiraman, '
          'pupuk, hama, atau kondisi daun.',
    );
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _sending) return;

    _messages.add(ChatMessage(author: ChatAuthor.user, text: trimmed));
    _typing = true;
    _sending = true;
    _error = null;
    notifyListeners();

    try {
      _sessionId ??= await chatSource.createSession(plantId: _contextPlantId);
      if (_contextPlantId != null) {
        _sessionByPlant[_contextPlantId!] = _sessionId!;
      }
      final reply = await chatSource.sendMessage(_sessionId!, trimmed);
      _messages.add(ChatMessage(author: ChatAuthor.bot, text: reply['content']!));
    } catch (e) {
      _error = e;
      _messages.add(
        const ChatMessage(
          author: ChatAuthor.bot,
          text:
              'Maaf, saya gagal menjawab karena masalah koneksi. '
              'Coba kirim ulang pesanmu.',
        ),
      );
    } finally {
      _typing = false;
      _sending = false;
      notifyListeners();
    }
  }

  String? _contextPlantId;
  final Map<String, int> _sessionByPlant = {};
  bool _restoring = false;

  bool get isRestoring => _restoring;

  Future<void> restorePlantChat(String? plantId) async {
    if (_contextPlantId != plantId) {
      bindPlant(plantId);
    }
    if (_messages.isNotEmpty) return;
    if (plantId == null || plantId.isEmpty) return;

    _restoring = true;
    notifyListeners();
    try {
      final cached = _sessionByPlant[plantId];
      final sessionId =
          cached ?? await chatSource.findSession(plantId: plantId);
      if (sessionId == null) {
        if (_messages.isEmpty) {
          _messages.add(_greeting);
        }
        return;
      }
      _sessionByPlant[plantId] = sessionId;
      final history = await chatSource.getMessages(sessionId);
      if (_messages.isNotEmpty) return;
      _sessionId = sessionId;
      _messages.add(_greeting);
      _messages.addAll([
        for (final m in history)
          ChatMessage(
            author: m['role'] == 'user' ? ChatAuthor.user : ChatAuthor.bot,
            text: m['content'] ?? '',
          ),
      ]);
    } catch (_) {
      _sessionId = null;
      if (_messages.isEmpty) {
        _messages.add(_greeting);
      }
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  void bindPlant(String? plantId) {
    if (_contextPlantId == plantId) return;
    _contextPlantId = plantId;
    _sessionId = plantId == null ? null : _sessionByPlant[plantId];
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  Future<Disease> diagnose({String? imagePath, String? plantId}) async {
    return _diseaseRepository.detect(imagePath: imagePath, plantId: plantId);
  }

  void reset() {
    _messages.clear();
    _typing = false;
    _sending = false;
    _error = null;
    _sessionId = null;
    _contextPlantId = null;
    _sessionByPlant.clear();
    _restoring = false;
    notifyListeners();
  }
}
