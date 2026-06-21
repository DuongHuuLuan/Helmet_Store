import 'dart:async';
import 'dart:convert';

import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/storage/secure_storage.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/cubit/chat_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_conversation.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_read_result.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/add_to_cart_action_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/create_or_get_conversation_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/get_conversations_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/get_messages_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/mark_conversation_read_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/recall_message_usecase.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/chat/send_message_usecase.dart';
import 'package:bloc/bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatCubit extends Cubit<ChatState> {
  final GetConversationsUseCase _getConversations;
  final CreateOrGetConversationUseCase _createOrGetConversation;
  final GetMessagesUseCase _getMessages;
  final SendMessageUseCase _sendMessage;
  final RecallMessageUseCase _recallMessage;
  final MarkConversationReadUseCase _markConversationRead;
  final AddToCartActionUseCase _addToCartAction;
  final SecureStorageService _storage = di.getIt<SecureStorageService>();

  ChatCubit(
    this._getConversations,
    this._createOrGetConversation,
    this._getMessages,
    this._sendMessage,
    this._recallMessage,
    this._markConversationRead,
    this._addToCartAction,
  ) : super(const ChatState());

  final List<ChatConversation> _conversations = [];
  final List<ChatMessage> _messages = [];

  ChatConversation? _activeConversation;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  bool _isLoadingConversations = false;
  bool _isOpeningConversation = false;
  bool _isLoadingMessages = false;
  bool _isSending = false;
  bool _isSocketConnected = false;
  String? _errorMessage;
  int? _nextCursor;
  int _clientSeed = 0;

  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatConversation? get activeConversation => _activeConversation;
  bool get isSocketConnected => _isSocketConnected;
  int get unreadTotal =>
      _conversations.fold(0, (total, item) => total + item.unreadCount);
  int? get counterpartLastReadMessageId =>
      _activeConversation?.lastReadAdminMessageId;

  void _emitState() {
    emit(ChatState(
      conversations: List.unmodifiable(_conversations),
      messages: List.unmodifiable(_messages),
      activeConversation: _activeConversation,
      isLoadingConversations: _isLoadingConversations,
      isOpeningConversation: _isOpeningConversation,
      isLoadingMessages: _isLoadingMessages,
      isSending: _isSending,
      isSocketConnected: _isSocketConnected,
      errorMessage: _errorMessage,
      nextCursor: _nextCursor,
    ));
  }

  Future<void> loadConversations({bool silent = false}) async {
    if (_isLoadingConversations) return;
    if (!silent) {
      _isLoadingConversations = true;
      _errorMessage = null;
      _emitState();
    }

    final result = await _getConversations();
    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (items) {
        _conversations
          ..clear()
          ..addAll(items);
        if (_activeConversation != null) {
          final current = _findConversation(_activeConversation!.id);
          if (current != null) {
            _activeConversation = current;
          }
        }
      },
    );
    _isLoadingConversations = false;
    _emitState();
  }

  Future<void> openSupportConversation() async {
    if (_isOpeningConversation) return;
    _isOpeningConversation = true;
    _errorMessage = null;
    _emitState();

    final result = await _createOrGetConversation();
    await result.fold(
      (failure) async {
        _errorMessage = failure.message;
      },
      (conversation) async {
        _replaceConversation(conversation, moveToTop: true);
        _activeConversation = _findConversation(conversation.id) ?? conversation;
        await loadMessages(conversation.id);
        await _connectSocket(conversation.id);
        await markConversationRead();
        await loadConversations(silent: true);
      },
    );
    _isOpeningConversation = false;
    _emitState();
  }

  Future<void> loadMessages(int conversationId) async {
    _isLoadingMessages = true;
    _errorMessage = null;
    _emitState();

    final result = await _getMessages(conversationId);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (page) {
        _messages
          ..clear()
          ..addAll(page.items);
        _nextCursor = page.nextCursor;
      },
    );
    _isLoadingMessages = false;
    _emitState();
  }

  Future<void> sendMessage({
    String? content,
    List<String> filePaths = const [],
  }) async {
    final conversation = _activeConversation;
    if (conversation == null || _isSending) return;
    if ((content == null || content.trim().isEmpty) && filePaths.isEmpty) return;

    _isSending = true;
    _errorMessage = null;
    _emitState();

    final clientMsgId = _createClientMsgId();
    final sendResult = await _sendMessage(
      conversation.id,
      content: content,
      clientMsgId: clientMsgId,
      filePaths: filePaths,
    );
    await sendResult.fold(
      (failure) async {
        _errorMessage = failure.message;
        _isSending = false;
        _emitState();
        throw failure;
      },
      (message) async {
        _upsertMessage(message);
        _touchConversationAfterMessage(message, isIncoming: false);
        await markConversationRead();
        _isSending = false;
        _emitState();
      },
    );
  }

  Future<void> recallMessage(int messageId) async {
    final conversation = _activeConversation;
    if (conversation == null) return;

    _errorMessage = null;
    _emitState();

    final result = await _recallMessage(conversation.id, messageId);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _emitState();
      },
      (_) {
        _emitState();
      },
    );
  }

  Future<void> markConversationRead({int? messageId}) async {
    final conversation = _activeConversation;
    if (conversation == null) return;

    final readResult = await _markConversationRead(
      conversation.id,
      messageId: messageId,
    );
    readResult.fold(
      (failure) {
        _errorMessage = failure.message;
        _emitState();
      },
      (readResult) {
        _applyReadResult(readResult, actorUserId: conversation.userId);
      },
    );
  }

  Future<void> addToCartAction({
    required int productDetailId,
    int quantity = 1,
  }) async {
    final conversation = _activeConversation;
    if (conversation == null) {
      _errorMessage = "Chưa có cuộc trò chuyện đang mở";
      _emitState();
      return;
    }

    _errorMessage = null;
    _emitState();

    final result = await _addToCartAction(
      conversation.id,
      productDetailId: productDetailId,
      quantity: quantity,
    );
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _emitState();
      },
      (_) {
        _emitState();
      },
    );
  }

  Future<void> leaveConversation() async {
    _activeConversation = null;
    _messages.clear();
    _nextCursor = null;
    await _disconnectSocket();
    _emitState();
  }

  Future<void> _connectSocket(int conversationId) async {
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) return;

    final uri = _buildSocketUri(conversationId, token);
    await _disconnectSocket();

    final channel = WebSocketChannel.connect(uri);
    _channel = channel;
    _isSocketConnected = true;
    _emitState();

    _channelSubscription = channel.stream.listen(
      _handleSocketPayload,
      onError: (_) {
        _isSocketConnected = false;
        _emitState();
      },
      onDone: () {
        _isSocketConnected = false;
        _emitState();
      },
      cancelOnError: true,
    );
  }

  Future<void> _disconnectSocket() async {
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    await _channel?.sink.close();
    _channel = null;
    _isSocketConnected = false;
  }

  Uri _buildSocketUri(int conversationId, String token) {
    final baseUri = Uri.parse(AppConstants.baseUrl);
    final scheme = baseUri.scheme == "https" ? "wss" : "ws";
    final segments = [
      ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
      "chat",
      "ws",
      "conversations",
      "$conversationId",
    ];
    return baseUri.replace(
      scheme: scheme,
      pathSegments: segments,
      queryParameters: {"token": token},
    );
  }

  void _handleSocketPayload(dynamic raw) {
    try {
      final payload = raw is String ? jsonDecode(raw) : raw;
      if (payload is! Map) return;
      final map = Map<String, dynamic>.from(payload);
      final event = map["event"]?.toString();

      if (event == "message:new") {
        final data = map["data"];
        if (data is Map) {
          final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
          final isIncoming =
              message.userId != (_activeConversation?.userId ?? -1);
          _upsertMessage(message);
          _touchConversationAfterMessage(message, isIncoming: isIncoming);
          if (_activeConversation?.id == message.conversationId && isIncoming) {
            unawaited(markConversationRead(messageId: message.id));
          } else {
            _emitState();
          }
        }
        return;
      }

      if (event == "message:read") {
        final data = map["data"];
        final actorUserId = _parseInt(map["user_id"]);
        if (data is Map && actorUserId != null) {
          _applyReadResult(
            ChatReadResult.fromJson(Map<String, dynamic>.from(data)),
            actorUserId: actorUserId,
          );
        }
        return;
      }

      if (event == "message:recalled") {
        final data = map["data"];
        if (data is Map) {
          final message = ChatMessage.fromJson(Map<String, dynamic>.from(data));
          _upsertMessage(message);
          _emitState();
        }
      }
    } catch (_) {}
  }

  void _applyReadResult(ChatReadResult result, {required int actorUserId}) {
    final conversation = _findConversation(result.conversationId);
    if (conversation == null) return;

    final updated = actorUserId == conversation.adminId
        ? conversation.copyWith(
            lastReadAdminMessageId: result.lastReadMessageId,
          )
        : conversation.copyWith(
            lastReadUserMessageId: result.lastReadMessageId,
            lastReadMessageId: result.lastReadMessageId,
            unreadCount: result.unreadCount,
          );

    _replaceConversation(updated);
    if (_activeConversation?.id == updated.id) {
      _activeConversation = updated;
    }
    _emitState();
  }

  void _touchConversationAfterMessage(
    ChatMessage message, {
    required bool isIncoming,
  }) {
    final conversation = _findConversation(message.conversationId);
    if (conversation == null) return;

    final unreadCount = _activeConversation?.id == message.conversationId
        ? 0
        : (isIncoming ? conversation.unreadCount + 1 : conversation.unreadCount);

    final updated = conversation.copyWith(
      lastMessageId: message.id,
      lastMessageAt: message.createdAt ?? DateTime.now(),
      unreadCount: unreadCount,
    );
    _replaceConversation(updated, moveToTop: true);
    if (_activeConversation?.id == updated.id) {
      _activeConversation = updated;
    }
  }

  void _upsertMessage(ChatMessage message) {
    final index = _messages.indexWhere(
      (item) =>
          item.id == message.id ||
          (item.clientMsgId != null && item.clientMsgId == message.clientMsgId),
    );
    if (index >= 0) {
      _messages[index] = message;
    } else {
      _messages.add(message);
      _messages.sort(
        (a, b) => (a.createdAt ?? DateTime(1970)).compareTo(
          b.createdAt ?? DateTime(1970),
        ),
      );
    }
  }

  ChatConversation? _findConversation(int conversationId) {
    for (final item in _conversations) {
      if (item.id == conversationId) return item;
    }
    return null;
  }

  void _replaceConversation(
    ChatConversation conversation, {
    bool moveToTop = false,
  }) {
    final index = _conversations.indexWhere(
      (item) => item.id == conversation.id,
    );
    if (index >= 0) {
      _conversations.removeAt(index);
    }

    if (moveToTop) {
      _conversations.insert(0, conversation);
      return;
    }

    _conversations.add(conversation);
    _conversations.sort(
      (a, b) => (b.lastMessageAt ?? b.createdAt).compareTo(
        a.lastMessageAt ?? a.createdAt,
      ),
    );
  }

  String _createClientMsgId() {
    _clientSeed += 1;
    return "app-${DateTime.now().millisecondsSinceEpoch}-$_clientSeed";
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  @override
  Future<void> close() async {
    await _disconnectSocket();
    return super.close();
  }
}
