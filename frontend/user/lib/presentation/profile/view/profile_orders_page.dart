import 'package:b2205946_duonghuuluan_luanvan/core/widgets/app_logo_loader.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/constants/app_constants.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/evaluate/evaluate.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/evaluate/view/evaluate_create_page.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/evaluate/cubit/evaluate_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/evaluate/cubit/evaluate_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/domain/entity/order/order_models.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/cubit/profile_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/cubit/profile_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/view/widget/profile_order_card.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/profile/view/widget/profile_order_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfileOrdersPage extends StatefulWidget {
  final String initialFilter;

  const ProfileOrdersPage({super.key, this.initialFilter = "all"});

  @override
  State<ProfileOrdersPage> createState() => _ProfileOrdersPageState();
}

class _ProfileOrdersPageState extends State<ProfileOrdersPage> {
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = _normalizeFilter(widget.initialFilter);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    final evaluateCubit = context.read<EvaluateCubit>();
    final state = context.watch<ProfileCubit>().state;
    final evaluateState = context.watch<EvaluateCubit>().state;
    final completedOrders = state.orders.where((o) => o.normalizedStatus == "completed").toList();

    _scheduleEvaluateStatusSync(completedOrders, evaluateCubit);

    final items = _buildFilters(state, cubit, evaluateCubit, evaluateState);
    final orders = _sortedOrders(
      _filterOrders(state, cubit, evaluateCubit, evaluateState, _selectedFilter),
    );
    final showInitialLoader = state.isLoading && state.orders.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F7),
      appBar: AppBar(
        title: const Text("Đơn đã mua"),
        actions: [
          IconButton(
            tooltip: "Trò chuyện",
            onPressed: () => context.push("/chat"),
            icon: const Icon(Icons.chat_bubble_outline),
          ),
          IconButton(
            tooltip: "Làm mới",
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          ProfileOrderFilterBar(
            items: items,
            selectedKey: _selectedFilter,
            onSelected: (value) => setState(() => _selectedFilter = value),
          ),
          const Divider(height: 1),
          Expanded(
            child: showInitialLoader
                ? const Center(child: AppLogoLoader(size: 80, strokeWidth: 4))
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    child: orders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.55,
                                child: _EmptyOrdersState(
                                  message: _emptyMessageFor(_selectedFilter),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: orders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return ProfileOrderCard(
                                order: order,
                                isEvaluated: evaluateCubit.reviewedOrderIds
                                    .contains(order.id),
                                isConfirming: cubit.confirmingOrderIds.contains(
                                  order.id,
                                ),
                                isCancelling: cubit.cancellingOrderIds.contains(
                                  order.id,
                                ),
                                isEvaluating: evaluateState.creatingOrderIds
                                    .contains(order.id),
                                onOpenDetail: () =>
                                    context.push("/orders/${order.id}"),
                                onConfirmReceived: _confirmOrderReceived,
                                onCancelOrder: _cancelOrder,
                                onCreateEvaluate: _openCreateEvaluate,
                                onViewEvaluate: _openEvaluateDetail,
                                onOpenSupportChat: () => context.push("/chat"),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _ensureLoaded() async {
    final cubit = context.read<ProfileCubit>();
    final evaluateCubit = context.read<EvaluateCubit>();
    if (cubit.state.profile == null && cubit.state.orders.isEmpty && !cubit.state.isLoading) {
      await cubit.load();
    }
    if (!mounted) return;
    await evaluateCubit.load(perPage: 10);
  }

  Future<void> _refreshData() async {
    final profileCubit = context.read<ProfileCubit>();
    final evaluateCubit = context.read<EvaluateCubit>();
    await profileCubit.refresh();
    if (!mounted) return;
    await evaluateCubit.refresh();
  }

  List<ProfileOrderFilterOption> _buildFilters(
    ProfileState state,
    ProfileCubit cubit,
    EvaluateCubit evaluateCubit,
    EvaluateState evaluateState,
  ) {
    final completedOrders = state.orders.where((o) => o.normalizedStatus == "completed").toList();
    final reviewPending = completedOrders
        .where((order) => !evaluateCubit.reviewedOrderIds.contains(order.id))
        .length;

    return [
      ProfileOrderFilterOption(
        key: "all",
        label: "Tất cả",
        count: state.orders.length,
      ),
      ProfileOrderFilterOption(
        key: "pending",
        label: "Chờ xác nhận",
        count: state.pendingCount,
      ),
      ProfileOrderFilterOption(
        key: "shipping",
        label: "Đang giao",
        count: state.shippingCount,
      ),
      ProfileOrderFilterOption(
        key: "completed",
        label: "Đã giao",
        count: state.completedCount,
      ),
      ProfileOrderFilterOption(
        key: "review",
        label: "Cần đánh giá",
        count: reviewPending,
      ),
      ProfileOrderFilterOption(
        key: "cancelled",
        label: "Đã hủy",
        count: state.cancelledCount,
      ),
    ];
  }

  List<OrderOut> _filterOrders(
    ProfileState state,
    ProfileCubit cubit,
    EvaluateCubit evaluateCubit,
    EvaluateState evaluateState,
    String filter,
  ) {
    switch (filter) {
      case "pending":
      case "shipping":
      case "completed":
      case "cancelled":
        return cubit.ordersByStatus(filter);
      case "review":
        final completedOrders = state.orders.where((o) => o.normalizedStatus == "completed").toList();
        return completedOrders
            .where((order) => !evaluateCubit.reviewedOrderIds.contains(order.id))
            .toList();
      case "all":
      default:
        return state.orders;
    }
  }

  List<OrderOut> _sortedOrders(List<OrderOut> source) {
    final orders = List<OrderOut>.from(source);
    orders.sort((a, b) {
      final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return right.compareTo(left);
    });
    return orders;
  }

  String _normalizeFilter(String value) {
    const supported = {
      "all",
      "pending",
      "shipping",
      "completed",
      "review",
      "cancelled",
    };
    final normalized = value.trim().toLowerCase();
    return supported.contains(normalized) ? normalized : "all";
  }

  String _emptyMessageFor(String filter) {
    switch (filter) {
      case "pending":
        return "Bạn chưa có đơn nào đang chờ xác nhận.";
      case "shipping":
        return "Bạn chưa có đơn nào đang giao.";
      case "completed":
        return "Bạn chưa có đơn đã giao.";
      case "review":
        return "Bạn không có đơn nào cần đánh giá.";
      case "cancelled":
        return "Bạn chưa hủy đơn hàng nào.";
      default:
        return "Bạn chưa có đơn hàng nào cả.";
    }
  }

  void _scheduleEvaluateStatusSync(
    List<OrderOut> completedOrders,
    EvaluateCubit evaluateCubit,
  ) {
    final orderIds = completedOrders.map((e) => e.id).toList(growable: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || orderIds.isEmpty) return;
      evaluateCubit.syncEvaluateStatusForOrders(orderIds);
    });
  }

  Future<void> _confirmOrderReceived(OrderOut order) async {
    final cubit = context.read<ProfileCubit>();
    try {
      await cubit.confirmOrderReceived(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xác nhận nhận hàng thành công.")),
      );
    } catch (_) {
      if (!mounted) return;
      final message = cubit.state.errorMessage ?? "Xác nhận nhận hàng thất bại.";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _cancelOrder(OrderOut order) async {
    final cubit = context.read<ProfileCubit>();
    try {
      await cubit.cancelOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Hủy đơn hàng thành công.")));
    } catch (_) {
      if (!mounted) return;
      final message = cubit.state.errorMessage ?? "Hủy đơn hàng thất bại.";
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openCreateEvaluate(OrderOut order) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EvaluateCreatePage(orderId: order.id)),
    );

    if (result == true && mounted) {
      await context.read<EvaluateCubit>().refresh();
    }
  }

  Future<void> _openEvaluateDetail(OrderOut order) async {
    final evaluateCubit = context.read<EvaluateCubit>();
    await evaluateCubit.syncEvaluateStatusForOrders([order.id]);
    final evaluateId = evaluateCubit.evaluateIdForOrder(order.id);
    if (evaluateId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Chưa tìm thấy đánh giá cho đơn hàng này."),
        ),
      );
      return;
    }

    try {
      final evaluate = await evaluateCubit.getEvaluateDetail(evaluateId);
      if (!mounted) return;
      await _showEvaluateDetailDialog(evaluate);
    } catch (_) {
      if (!mounted) return;
      final msg = evaluateCubit.state.errorMessage ?? "Không thể tải chi tiết đánh giá.";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _showEvaluateDetailDialog(EvaluateItem evaluate) async {
    final content = (evaluate.content ?? "").trim();
    final reply = (evaluate.adminReply ?? "").trim();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Đánh giá #EV-${evaluate.id}"),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Đơn hàng #DH-${evaluate.orderId}"),
                  const SizedBox(height: 8),
                  Text("Số sao: ${evaluate.rate}/5"),
                  const SizedBox(height: 8),
                  Text(content.isEmpty ? "(Không có nội dung)" : content),
                  if (evaluate.images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: evaluate.images
                          .map(
                            (img) => ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                _resolveUrl(img.imageUrl),
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.grey.shade200,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (reply.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Phản hồi từ người bán",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(reply),
                        ],
                      ),
                    )
                  else
                    Text(
                      "Chưa có phản hồi từ người bán.",
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Đóng",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _resolveUrl(String raw) {
    if (raw.startsWith("http://") || raw.startsWith("https://")) return raw;
    final base = AppConstants.baseUrl.replaceAll(RegExp(r"/+$"), "");
    return "$base${raw.startsWith("/") ? "" : "/"}$raw";
  }
}

class _EmptyOrdersState extends StatelessWidget {
  final String message;

  const _EmptyOrdersState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2EE),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            size: 54,
            color: Color(0xFFF2593A),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF495468),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
