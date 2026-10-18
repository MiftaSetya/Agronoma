import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/data/chat_repository.dart';
import 'package:frontend/core/data/mock_disease_repository.dart';
import 'package:frontend/core/models/chat_message.dart';
import 'package:frontend/core/state/chat_controller.dart';

class _MemoryChatRepository implements ChatRepository {
  _MemoryChatRepository({this.sessionId, this.history = const []});

  int? sessionId;
  List<Map<String, String>> history;

  int _createCalls = 0;

  int get createCalls => _createCalls;

  @override
  Future<int> createSession({String? plantId}) async {
    _createCalls++;
    sessionId = 1;
    return sessionId!;
  }

  @override
  Future<int?> findSession({String? plantId}) async => sessionId;

  @override
  Future<List<Map<String, String>>> getMessages(int sessionId) async =>
      history;

  @override
  Future<Map<String, String>> sendMessage(int sessionId, String content) async {
    history = [...history, {'role': 'user', 'content': content}];
    return {'role': 'ai', 'content': 'balasan'};
  }
}

void main() {
  test('restorePlantChat memuat riwayat dari sesi yang sudah ada', () async {
    final repo = _MemoryChatRepository(
      sessionId: 7,
      history: [
        {'role': 'user', 'content': 'Daunku menguning'},
        {'role': 'ai', 'content': 'Cek penyiraman dan sinar matahari.'},
      ],
    );
    final controller = ChatController(
      chatSource: repo,
      detector: const MockDiseaseRepository(),
    );

    await controller.restorePlantChat('4');

    expect(controller.messages, hasLength(3));
    expect(controller.messages.first.author, ChatAuthor.bot);
    expect(controller.messages[1].author, ChatAuthor.user);
    expect(controller.messages[1].text, 'Daunku menguning');
    expect(controller.messages[2].author, ChatAuthor.bot);
    expect(controller.messages[2].text, 'Cek penyiraman dan sinar matahari.');
  });

  test('restorePlantChat tanpa sesi menampilkan greeting saja', () async {
    final controller = ChatController(
      chatSource: _MemoryChatRepository(sessionId: null),
      detector: const MockDiseaseRepository(),
    );

    await controller.restorePlantChat('4');

    expect(controller.messages, hasLength(1));
    expect(controller.messages.single.author, ChatAuthor.bot);
  });

  test('send memakai sesi yang sudah dimuat tanpa membuat baru', () async {
    final repo = _MemoryChatRepository(
      sessionId: 3,
      history: [
        {'role': 'user', 'content': 'halo'},
        {'role': 'ai', 'content': 'Halo juga!'},
      ],
    );
    final controller = ChatController(
      chatSource: repo,
      detector: const MockDiseaseRepository(),
    );
    await controller.restorePlantChat('4');

    await controller.send('kapan disiram?');

    expect(repo.createCalls, 0);
    expect(controller.messages.last.author, ChatAuthor.bot);
    expect(controller.messages.last.text, 'balasan');
  });
}
