class ChatReadResult {
  final int conversationId;
  final int? lastReadMessageId;
  final int unreadCount;
  final bool changed;

  const ChatReadResult({
    required this.conversationId,
    required this.lastReadMessageId,
    required this.unreadCount,
    required this.changed,
  });

  factory ChatReadResult.fromJson(Map<String, dynamic> json) {
    return ChatReadResult(
      conversationId: _parseInt(json["conversation_id"]) ?? 0,
      lastReadMessageId: _parseInt(json["last_read_message_id"]),
      unreadCount: _parseInt(json["unread_count"]) ?? 0,
      changed: json["changed"] == true,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
