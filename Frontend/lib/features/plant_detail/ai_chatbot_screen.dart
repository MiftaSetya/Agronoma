import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/core/assets/app_assets.dart';
import 'package:frontend/core/models/chat_message.dart';
import 'package:frontend/core/state/chat_controller.dart';
import 'package:frontend/core/theme/theme.dart';
import 'package:frontend/core/widgets/agro_icon.dart';

class PlantChatScreen extends StatefulWidget {
  const PlantChatScreen({super.key, this.plantId});

  final String? plantId;

  @override
  State<PlantChatScreen> createState() => _PlantChatScreenState();
}

class _PlantChatScreenState extends State<PlantChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  static const _greeting = ChatMessage(
    author: ChatAuthor.bot,
    text:
        'Halo! Saya Agronoma AI. Tanya apa saja soal tanamanmu — penyiraman, '
        'pupuk, hama, atau kondisi daun.',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final chat = context.read<ChatController>();
      chat.bindPlant(widget.plantId);
      chat.ensureGreeting(_greeting);
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await context.read<ChatController>().send(text);
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_scroll.hasClients) {
      await _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const AgroIcon(AppAssets.chevronLeft, size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Agronoma AI'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: chat.messages.length + (chat.isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= chat.messages.length) {
                  return const _TypingBubble();
                }
                return _MessageBubble(message: chat.messages[index]);
              },
            ),
          ),
          if (chat.messages.length <= 1)
            _SuggestionRow(onPick: (text) => _send(text)),
          _InputBar(controller: _input, onSend: _send, enabled: !chat.isSending),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(isUser ? AppRadius.lg : AppRadius.xs),
            bottomRight: Radius.circular(isUser ? AppRadius.xs : AppRadius.lg),
          ),
          border: Border.all(
            color: isUser ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          message.text,
          style: AppTextStyles.bodyLarge.copyWith(
            color: isUser ? AppColors.onPrimary : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Sedang menulis…',
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.grey),
        ),
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow({required this.onPick});

  final ValueChanged<String> onPick;

  static const _suggestions = [
    'Daunku menguning, kenapa ya?',
    'Kapan sebaiknya dipupuk?',
    'Cara mengatasi kutu daun?',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: _suggestions.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final text = _suggestions[i];
          return GestureDetector(
            onTap: () => onPick(text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppRadius.chipAll,
                border: Border.all(color: AppColors.primaryTint),
              ),
              child: Text(
                text,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  final TextEditingController controller;
  final Future<void> Function([String? preset]) onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: AppTextStyles.bodyLarge,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                enabled: enabled,
                decoration: const InputDecoration(
                  hintText: 'Tanya tentang tanamanmu…',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: enabled ? () => onSend() : null,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(44, 44),
              ),
              icon: const Icon(Icons.send_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
