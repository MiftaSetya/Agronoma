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
  Disease? _diagnosis;
  bool _diagnosing = false;
  bool _typing = false;
  bool _sending = false;
  Object? _error;
  int? _sessionId;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  Disease? get diagnosis => _diagnosis;
  bool get isDiagnosing => _diagnosing;
  bool get isTyping => _typing;
  bool get isSending => _sending;
  Object? get error => _error;
  bool get hasError => _error != null;

  void ensureGreeting(ChatMessage greeting) {
    if (_messages.isEmpty) {
      _messages.add(greeting);
      notifyListeners();
    }
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

  void bindPlant(String? plantId) {
    if (_contextPlantId == plantId) return;
    _contextPlantId = plantId;
    _sessionId = null;
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  Future<Disease> diagnose({String? imagePath, String? plantId}) async {
    _diagnosing = true;
    notifyListeners();
    try {
      _diagnosis = await _diseaseRepository.detect(
        imagePath: imagePath,
        plantId: plantId,
      );
      return _diagnosis!;
    } finally {
      _diagnosing = false;
      notifyListeners();
    }
  }

  void discussDiagnosis(Disease disease) {
    _messages.add(
      ChatMessage(
        author: ChatAuthor.bot,
        text:
            'Hasil pemindaian terakhir: ${disease.name} '
            '(${disease.confidenceLabel} yakin). Mau saya jelaskan cara '
            'penanganannya?',
      ),
    );
    notifyListeners();
  }

  void reset() {
    _messages.clear();
    _diagnosis = null;
    _diagnosing = false;
    _typing = false;
    _sending = false;
    _error = null;
    _sessionId = null;
    _contextPlantId = null;
    notifyListeners();
  }
}
