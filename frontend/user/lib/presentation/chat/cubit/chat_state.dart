import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_conversation.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message.dart';
import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  final List<ChatConversation> conversations;
  final List<ChatMessage> messages;
  final ChatConversation? activeConversation;
  final bool isLoadingConversations;
  final bool isOpeningConversation;
  final bool isLoadingMessages;
  final bool isSending;
  final bool isSocketConnected;
  final String? errorMessage;
  final int? nextCursor;

  const ChatState({
    this.conversations = const [],
    this.messages = const [],
    this.activeConversation,
    this.isLoadingConversations = false,
    this.isOpeningConversation = false,
    this.isLoadingMessages = false,
    this.isSending = false,
    this.isSocketConnected = false,
    this.errorMessage,
    this.nextCursor,
  });

  ChatState copyWith({
    List<ChatConversation>? conversations,
    List<ChatMessage>? messages,
    ChatConversation? activeConversation,
    bool? isLoadingConversations,
    bool? isOpeningConversation,
    bool? isLoadingMessages,
    bool? isSending,
    bool? isSocketConnected,
    String? errorMessage,
    int? nextCursor,
    bool clearActiveConversation = false,
    bool clearMessages = false,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      messages: clearMessages ? const [] : (messages ?? this.messages),
      activeConversation: clearActiveConversation ? null : (activeConversation ?? this.activeConversation),
      isLoadingConversations: isLoadingConversations ?? this.isLoadingConversations,
      isOpeningConversation: isOpeningConversation ?? this.isOpeningConversation,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isSending: isSending ?? this.isSending,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      errorMessage: errorMessage,
      nextCursor: nextCursor,
    );
  }

  @override
  List<Object?> get props => [
    conversations,
    messages,
    activeConversation,
    isLoadingConversations,
    isOpeningConversation,
    isLoadingMessages,
    isSending,
    isSocketConnected,
    errorMessage,
    nextCursor,
  ];
}
