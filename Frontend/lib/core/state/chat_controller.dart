import 'package:flutter/foundation.dart';

import 'package:frontend/core/data/disease_repository.dart';
import 'package:frontend/core/models/chat_message.dart';
import 'package:frontend/core/models/disease.dart';

/// Menangani chatbot AI dan diagnosis penyakit. Keduanya digabung karena
/// berbagi layar yang sama (Plant Detail), dan diagnosis bisa langsung
/// "dibicarakan" di chat.
class ChatController extends ChangeNotifier {
  /// Nama parameter dibedakan dari nama field (lihat [PlantController])
  /// supaya tidak memicu `prefer_initializing_formals`.
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

  /// Sedang "menulis" balasan, dipakai untuk menampilkan indikator.
  bool get isTyping => _typing;

  /// Menambahkan pesan pembuka bot sekali saja.
  void ensureGreeting(ChatMessage greeting) {
    if (_messages.isEmpty) {
      _messages.add(greeting);
      notifyListeners();
    }
  }

  /// Mengirim pesan pengguna lalu menambahkan balasan contoh.
  Future<void> send(String text, {required String Function(String) reply}) async {
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

  /// Menjalankan diagnosis penyakit (dipakai layar deteksi).
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

  /// Memasukkan hasil diagnosis ke dalam percakapan supaya pengguna bisa
  /// langsung menanyakan tindak lanjutnya.
  void discussDiagnosis(Disease disease) {
    _messages.add(
      ChatMessage(
        author: ChatAuthor.bot,
        text: 'Hasil pemindaian terakhir: ${disease.name} '
            '(${disease.confidenceLabel} yakin). Mau saya jelaskan cara '
            'penanganannya?',
      ),
    );
    notifyListeners();
  }

  /// Mengosongkan percakapan dan diagnosis milik sesi yang berakhir.
  void reset() {
    _messages.clear();
    _diagnosis = null;
    _diagnosing = false;
    _typing = false;
    notifyListeners();
  }
}
