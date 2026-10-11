import 'package:flutter/material.dart';

/// Pengirim sebuah pesan di AI Chatbot.
enum ChatAuthor { user, bot }

/// Satu gelembung percakapan di layar "Plant Detail - AI Chatbot".
@immutable
class ChatMessage {
  const ChatMessage({required this.author, required this.text});

  final ChatAuthor author;
  final String text;

  bool get isUser => author == ChatAuthor.user;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    author: ChatAuthor.values.byName(json['author'] as String),
    text: json['text'] as String,
  );

  Map<String, dynamic> toJson() => {'author': author.name, 'text': text};
}
