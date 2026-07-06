import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/auth_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/chat/chat_message.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/view/widget/chat_cart_action_result_bubble.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/view/widget/chat_discount_list_bubble.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/view/widget/chat_order_summary_bubble.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/view/widget/chat_product_list_bubble.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/cubit/chat_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _selectedImages = [];
  late final ChatCubit _chatVm;

  @override
  void initState() {
    super.initState();
    _chatVm = context.read<ChatCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _chatVm.openSupportConversation();
      if (!mounted) return;
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _chatVm.leaveConversation();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (!mounted || files.isEmpty) return;
    setState(() {
      _selectedImages
        ..clear()
        ..addAll(files.map((file) => file.path));
    });
  }

  Future<void> _send(ChatCubit cubit) async {
    final content = _messageController.text.trim();
    final images = List<String>.from(_selectedImages);
    if (content.isEmpty && images.isEmpty) return;

    _messageController.clear();
    setState(() {
      _selectedImages.clear();
    });

    try {
      await cubit.sendMessage(content: content, filePaths: images);
      if (!mounted) return;
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      if (_messageController.text.trim().isEmpty && _selectedImages.isEmpty) {
        _messageController.text = content;
        _messageController.selection = TextSelection.fromPosition(
          TextPosition(offset: _messageController.text.length),
        );
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
          });
        }
      }
      final message = cubit.state.errorMessage ?? "Không thể gửi tin nhắn.";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmRecall(ChatCubit cubit, ChatMessage message) async {
    final shouldRecall = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Thu hồi tin nhắn?"),
          content: const Text("Bạn có chắc chắn muốn thu hồi tin nhắn?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Hủy"),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Thu hồi"),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldRecall != true) return;

    try {
      await cubit.recallMessage(message.id);
    } catch (_) {
      if (!mounted) return;
      final error = cubit.state.errorMessage ?? "Không thể thu hồi tin nhắn.";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final vm = context.watch<ChatCubit>().state;
    final myUserId = authState.user?.id ?? 0;
    final messages = vm.messages;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Liên hệ hỗ trợ"),
            Text(
              vm.isSocketConnected
                  ? "Đã kết nối trực tuyến"
                  : "Đang đồng bộ...",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: vm.isOpeningConversation || vm.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(
                    child: Text(
                      "Chưa có tin nhắn nào. Hãy bắt đầu cuộc trò chuyện.",
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final senderRole = message.senderRole
                          ?.trim()
                          .toLowerCase();
                      final isMine = senderRole == null || senderRole.isEmpty
                          ? message.userId == myUserId
                          : senderRole == "user" && message.userId == myUserId;
                      final isRead =
                          isMine &&
                          _chatVm.counterpartLastReadMessageId != null &&
                          message.id <= _chatVm.counterpartLastReadMessageId!;
                      return _ChatBubble(
                        message: message,
                        isMine: isMine,
                        isRead: isRead,
                        onRecall: isMine && !message.isRecalled
                            ? () => _confirmRecall(_chatVm, message)
                            : null,
                      );
                    },
                  ),
          ),
          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 92,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final path = _selectedImages[index];
                  return Container(
                    width: 128,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.image_outlined, size: 18),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedImages.removeAt(index);
                                });
                              },
                              child: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          path.split("\\").last.split("/").last,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _selectedImages.length,
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: vm.isSending ? null : _pickImages,
                    icon: const Icon(Icons.image_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: "Nhập tin nhắn...",
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: vm.isSending ? null : () => _send(_chatVm),
                    child: vm.isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool isRead;
  final VoidCallback? onRecall;

  const _ChatBubble({
    required this.message,
    required this.isMine,
    required this.isRead,
    this.onRecall,
  });

  bool get _isImageOnly =>
      message.mediaItems.isNotEmpty &&
      message.mediaItems.every((item) => item.mediaType == "image");

  bool get _hasProductListPayload =>
      message.payload?.kind == "product_list" &&
      (message.payload?.products.isNotEmpty ?? false);

  bool get _hasDiscountListPayload =>
      message.payload?.kind == "discount_list" &&
      (message.payload?.discounts.isNotEmpty ?? false);

  bool get _hasOrderSummaryPayload =>
      message.payload?.kind == "order_summary" &&
      message.payload?.order != null;

  bool get _hasCartActionResultPayload =>
      message.payload?.kind == "cart_action_result" &&
      message.payload?.cartActionResult != null;

  bool get _isHandoffNotice => message.payload?.kind == "handoff_notice";

  bool get _hasStructuredPayload =>
      _hasProductListPayload ||
      _hasDiscountListPayload ||
      _hasOrderSummaryPayload ||
      _hasCartActionResultPayload ||
      _isHandoffNotice;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final align = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMine
        ? scheme.primary
        : scheme.surfaceContainerHighest;
    final textColor = isMine ? scheme.onPrimary : scheme.onSurface;

    return Column(
      crossAxisAlignment: align,
      children: [
        GestureDetector(
          onLongPress: onRecall,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width *
                  (_hasStructuredPayload ? 0.84 : 0.74),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: align,
              children: [
                if (message.isRecalled)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.undo,
                        size: 18,
                        color: textColor.withOpacity(0.9),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message.content ?? "Tin nhắn đã được thu hồi",
                          style: TextStyle(
                            color: textColor.withOpacity(0.92),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (message.mediaItems.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: message.mediaItems.map((item) {
                      if (_isImageOnly) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: item.path,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 150,
                              height: 150,
                              color: Colors.black12,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        );
                      }
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_file, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                item.path.split("/").last,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: textColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                if (!message.isRecalled &&
                    message.mediaItems.isNotEmpty &&
                    (message.content?.isNotEmpty ?? false))
                  const SizedBox(height: 8),
                if (!message.isRecalled &&
                    message.content != null &&
                    message.content!.trim().isNotEmpty)
                  Text(message.content!, style: TextStyle(color: textColor)),
                if (!message.isRecalled &&
                    _hasStructuredPayload &&
                    (message.content?.trim().isNotEmpty ?? false))
                  const SizedBox(height: 10),
                if (!message.isRecalled && _hasProductListPayload)
                  ChatProductListBubble(payload: message.payload!),
                if (!message.isRecalled && _hasDiscountListPayload)
                  ChatDiscountListBubble(payload: message.payload!),
                if (!message.isRecalled && _hasOrderSummaryPayload)
                  ChatOrderSummaryBubble(payload: message.payload!),
                if (!message.isRecalled && _hasCartActionResultPayload)
                  ChatCartActionResultBubble(payload: message.payload!),
                if (!message.isRecalled && _isHandoffNotice)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(isMine ? 0.12 : 0.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.support_agent_outlined,
                          size: 18,
                          color: textColor.withOpacity(0.9),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.payload?.noticeMessage?.trim().isNotEmpty ==
                                    true
                                ? message.payload!.noticeMessage!
                                : "Tư vấn viên sẽ tham gia hỗ trợ bạn trong ít phút nữa.",
                            style: TextStyle(
                              color: textColor.withOpacity(0.94),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6, right: 6, bottom: 8),
          child: Text(
            message.isRecalled
                ? "Đã thu hồi"
                : isRead
                ? "Đã xem"
                : _formatTime(message.createdAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return "";
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, "0");
    final minute = local.minute.toString().padLeft(2, "0");
    return "$hour:$minute";
  }
}
