class ChatMessageModel {
  final int id;
  final String role; // user, assistant, system
  final String content;
  final int? wordId;
  final String? createdAt;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.content,
    this.wordId,
    this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? 0,
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      wordId: json['word_id'],
      createdAt: json['created_at'],
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
