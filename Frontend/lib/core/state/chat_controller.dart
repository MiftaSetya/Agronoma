import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/disease_repository.dart';
import 'package:frontend/core/models/chat_message.dart';
import 'package:frontend/core/models/disease.dart';

class ChatController extends ChangeNotifier {
  ChatController({required DiseaseRepository detector})
    : _diseaseRepository = detector;

  final DiseaseRepository _diseaseRepository;

  final List<ChatMessage> _messages = [];
  Disease? _diagnosis;
  bool _diagnosing = false;
  bool _typing = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  Disease? get diagnosis => _diagnosis;
  bool get isDiagnosing => _diagnosing;

  bool get isTyping => _typing;

  void ensureGreeting(ChatMessage greeting) {
    if (_messages.isEmpty) {
      _messages.add(greeting);
      notifyListeners();
    }
  }

  Future<void> send(
    String text, {
    required String Function(String) reply,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _messages.add(ChatMessage(author: ChatAuthor.user, text: trimmed));
    _typing = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 900));

    _messages.add(ChatMessage(author: ChatAuthor.bot, text: reply(trimmed)));
    _typing = false;
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
    notifyListeners();
  }
}
