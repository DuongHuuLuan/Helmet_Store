class ChatConversation {
  final int id;
  final int userId;
  final int adminId;
  final String status;
  final int? lastMessageId;
  final int? lastReadUserMessageId;
  final int? lastReadAdminMessageId;
  final int? lastReadMessageId;
  final int unreadCount;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChatConversation({
    required this.id,
    required this.userId,
    required this.adminId,
    required this.status,
    required this.lastMessageId,
    required this.lastReadUserMessageId,
    required this.lastReadAdminMessageId,
    required this.lastReadMessageId,
    required this.unreadCount,
    required this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: _parseInt(json["id"]) ?? 0,
      userId: _parseInt(json["user_id"]) ?? 0,
      adminId: _parseInt(json["admin_id"]) ?? 0,
      status: (json["status"] ?? "open").toString(),
      lastMessageId: _parseInt(json["last_message_id"]),
      lastReadUserMessageId: _parseInt(json["last_read_user_message_id"]),
      lastReadAdminMessageId: _parseInt(json["last_read_admin_message_id"]),
      lastReadMessageId: _parseInt(json["last_read_message_id"]),
      unreadCount: _parseInt(json["unread_count"]) ?? 0,
      lastMessageAt: _parseDate(json["last_message_at"]),
      createdAt: _parseDate(json["created_at"]) ?? DateTime.now(),
      updatedAt: _parseDate(json["updated_at"]),
    );
  }

  ChatConversation copyWith({
    int? lastMessageId,
    int? lastReadUserMessageId,
    int? lastReadAdminMessageId,
    int? lastReadMessageId,
    int? unreadCount,
    DateTime? lastMessageAt,
  }) {
    return ChatConversation(
      id: id,
      userId: userId,
      adminId: adminId,
      status: status,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastReadUserMessageId:
          lastReadUserMessageId ?? this.lastReadUserMessageId,
      lastReadAdminMessageId:
          lastReadAdminMessageId ?? this.lastReadAdminMessageId,
      lastReadMessageId: lastReadMessageId ?? this.lastReadMessageId,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
