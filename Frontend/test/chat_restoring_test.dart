import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/data/chat_repository.dart';
import 'package:frontend/core/data/mock_disease_repository.dart';
import 'package:frontend/core/state/chat_controller.dart';

class _SlowChatRepository implements ChatRepository {
  @override
  Future<int> createSession({String? plantId}) async => 1;

  @override
  Future<int?> findSession({String? plantId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return 7;
  }

  @override
  Future<List<Map<String, String>>> getMessages(int sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const [
      {'role': 'user', 'content': 'Daunku menguning'},
      {'role': 'ai', 'content': 'Cek penyiraman.'},
    ];
  }

  @override
  Future<Map<String, String>> sendMessage(
    int sessionId,
    String content,
  ) async => {'role': 'ai', 'content': 'balasan'};
}

void main() {
  test('controller memakai isRestoring saat memuat riwayat', () async {
    final controller = ChatController(
      chatSource: _SlowChatRepository(),
      detector: const MockDiseaseRepository(),
    );

    expect(controller.isRestoring, isFalse);

    final restoring = controller.restorePlantChat('4');
    expect(controller.isRestoring, isTrue);

    await restoring;

    expect(controller.isRestoring, isFalse);
    expect(controller.messages, hasLength(3));
  });
}
