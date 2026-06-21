import 'dart:async';

import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:b2205946_duonghuuluan_luanvan/domain/usecase/order/get_order_detail_usecase.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderResultPage extends StatefulWidget {
  final int orderId;
  final String paymentUrl;
  final String callbackStatus;
  final String callbackValid;

  const OrderResultPage({
    super.key,
    required this.orderId,
    required this.paymentUrl,
    this.callbackStatus = "",
    this.callbackValid = "",
  });

  @override
  State<OrderResultPage> createState() => _OrderResultPageState();
}

class _OrderResultPageState extends State<OrderResultPage>
    with WidgetsBindingObserver {
  bool _isLaunching = false;
  bool _isChecking = false;
  String? _error;
  OrderOut? _order;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.paymentUrl.isNotEmpty) {
      Future.microtask(_launchPayment);
    }
    Future.microtask(_checkStatus);
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatus();
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted) {
        _checkStatus();
      }
    });
  }

  Future<void> _launchPayment() async {
    if (widget.paymentUrl.trim().isEmpty || _isLaunching) return;
    _isLaunching = true;

    final uri = Uri.parse(widget.paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      setState(() => _error = "Không thể mở liên kết thanh toán");
    }

    _isLaunching = false;
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
      _error = null;
    });

    final result = await di.getIt<GetOrderDetailUseCase>()(widget.orderId);
    result.fold(
      (failure) {
        if (!mounted) return;
        setState(() => _error = failure.message);
      },
      (order) {
        if (!mounted) return;
        setState(() => _order = order);
        if (_shouldStopPolling(order)) {
          _pollTimer?.cancel();
        }
      },
    );
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  bool _shouldStopPolling(OrderOut order) {
    return order.isCancelled ||
        order.normalizedStatus == "shipping" ||
        order.normalizedStatus == "completed" ||
        order.isPendingReview;
  }

  bool get _hasFailedCallback {
    if (widget.callbackValid == "0") return true;
    return widget.callbackStatus == "failed";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final order = _order;

    final isRejected = order?.isCancelled == true;
    final isPendingReview = order?.isPendingReview == true;
    final isApproved =
        order != null &&
        (order.normalizedStatus == "shipping" ||
            order.normalizedStatus == "completed");
    final isPaymentFailed =
        order != null &&
        order.normalizedPaymentStatus == "unpaid" &&
        !isApproved &&
        !isPendingReview &&
        _hasFailedCallback;
    final isWaiting =
        !isRejected && !isPendingReview && !isApproved && !isPaymentFailed;

    final titleText = isRejected
        ? "Đơn hàng đã bị từ chối"
        : isPendingReview
        ? "Đã thanh toán, đơn đang chờ duyệt"
        : isApproved
        ? "Đơn hàng đã được duyệt"
        : isPaymentFailed
        ? "Thanh toán thất bại"
        : "Đang chờ xác nhận thanh toán";

    final subtitleText = isRejected
        ? (order?.rejectionReason?.trim().isNotEmpty == true
              ? order!.rejectionReason!.trim()
              : "Quản trị viên đã từ chối đơn hàng này.")
        : isPendingReview
        ? "Thanh toán VNPAY đã được ghi nhận. Đơn hàng sẽ được quản trị viên xem và duyệt."
        : isApproved
        ? "Bạn có thể mở chi tiết đơn hàng để xem trạng thái mới nhất."
        : isPaymentFailed
        ? "VNPAY chưa ghi nhận thanh toán thành công cho đơn hàng này."
        : "Hệ thống đang đồng bộ kết quả thanh toán. Bạn có thể kiểm tra lại sau.";

    final icon = isRejected
        ? Icons.cancel
        : isPendingReview || isApproved
        ? Icons.check_circle
        : isPaymentFailed
        ? Icons.error
        : Icons.hourglass_top;
    final iconColor = isRejected
        ? Colors.red
        : isPendingReview || isApproved
        ? Colors.green
        : isPaymentFailed
        ? Colors.red
        : colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Thanh toán"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.go("/"),
          icon: const Icon(Icons.close),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: isWaiting
                        ? Center(
                            child: SizedBox(
                              width: 42,
                              height: 42,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                color: colorScheme.secondary,
                              ),
                            ),
                          )
                        : Icon(icon, size: 72, color: iconColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    titleText,
                    style: textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Mã đơn hàng: #DH-${widget.orderId}",
                    style: textTheme.bodySmall,
                  ),
                  if (order != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _ResultTag(
                          label: _paymentStatusLabel(order.paymentStatus),
                        ),
                        _ResultTag(label: _orderStatusLabel(order.status)),
                        if (order.needsRefundChat)
                          const _ResultTag(label: "Liên hệ chat để hoàn tiền"),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    subtitleText,
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (isWaiting)
                    ElevatedButton.icon(
                      onPressed: _isChecking ? null : _checkStatus,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        _isChecking ? "Đang kiểm tra..." : "Kiểm tra lại",
                      ),
                    ),
                  if (order?.needsRefundChat == true) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push("/chat"),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Liên hệ chat hỗ trợ"),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.go("/orders/${widget.orderId}"),
                    child: Text(
                      "Xem đơn hàng",
                      style: TextStyle(color: colorScheme.secondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _paymentStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case "paid":
      return "Đã thanh toán";
    case "unpaid":
      return "Chưa thanh toán";
    default:
      return "Không rõ";
  }
}

String _orderStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case "pending":
      return "Đang chờ duyệt";
    case "shipping":
      return "Đang giao";
    case "completed":
      return "Hoàn thành";
    case "cancelled":
      return "Đã hủy";
    default:
      return status;
  }
}

class _ResultTag extends StatelessWidget {
  final String label;

  const _ResultTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
