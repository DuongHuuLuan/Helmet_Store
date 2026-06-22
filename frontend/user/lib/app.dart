import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/notifications/push_notification_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/auth_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/auth/cubit/auth_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/cubit/chat_cubit.dart';
import 'package:b2205946_duonghuuluan_luanvan/presentation/chat/cubit/chat_state.dart';
import 'package:b2205946_duonghuuluan_luanvan/routing/app_router.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final GoRouter _router;
  late final AuthCubit _authCubit;
  late final ChatCubit _chatCubit;
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<ChatState>? _chatSub;
  final PushNotificationService _pushService = PushNotificationService.instance;
  final AppLinks _appLinks = AppLinks();

  StreamSubscription<Uri>? _deepLinkSub;
  Timer? _chatBadgeTimer;
  _PendingPaymentNavigation? _pendingPaymentNavigation;
  bool _isFlushingPendingPaymentNavigation = false;
  bool _hasQueuedPendingPaymentFlush = false;

  // Trạng thái cục bộ để quản lý UI mượt mà hơn
  int _unreadTotal = 0;
  String _currentLocation = "/";

  // Vị trí của nút Chat (tính từ góc dưới bên phải)
  Offset _buttonOffset = const Offset(18, 18);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Khởi tạo các Cubit
    _authCubit = context.read<AuthCubit>();
    _chatCubit = context.read<ChatCubit>();
    _router = AppRouter.createRouter(_authCubit);

    _pushService.attachRouter(_router);

    // Đăng ký lắng nghe thay đổi
    _authSub = _authCubit.stream.listen((_) => _handleAuthStateChanged());
    _chatSub = _chatCubit.stream.listen((_) => _handleChatStateChanged());
    _router.routerDelegate.addListener(_handleRouteChanged);

    // Cập nhật trạng thái ban đầu
    _handleChatStateChanged();
    _handleRouteChanged();

    unawaited(_syncPushState());
    _initDeepLinks();
    _queuePendingPaymentNavigationFlush();
  }

  // --- LOGIC XỬ LÝ TRẠNG THÁI ---

  void _handleAuthStateChanged() {
    if (!mounted) return;
    setState(() {}); // Rebuild để cập nhật shouldShowSupportChat
    unawaited(_syncPushState());
    _queuePendingPaymentNavigationFlush();
  }

  void _handleChatStateChanged() {
    if (!mounted) return;
    final nextUnreadTotal = _chatCubit.unreadTotal;
    if (nextUnreadTotal == _unreadTotal) return;
    setState(() {
      _unreadTotal = nextUnreadTotal;
    });
  }

  void _handleRouteChanged() {
    if (!mounted) return;
    final nextLocation = _safeCurrentLocation();
    final hasPendingPaymentNavigation = _pendingPaymentNavigation != null;

    if (hasPendingPaymentNavigation && nextLocation == "/order-result") {
      _pendingPaymentNavigation = null;
    } else if (hasPendingPaymentNavigation &&
        nextLocation != "/splash" &&
        nextLocation != "/order-result") {
      _queuePendingPaymentNavigationFlush();
    }

    if (nextLocation == _currentLocation) return;
    setState(() {
      _currentLocation = nextLocation;
    });
  }

  // --- LOGIC ĐẨY THÔNG BÁO & BADGE ---

  Future<void> _syncPushState() async {
    if (!mounted) return;
    if (!_authCubit.state.isInitialized) {
      _pushService.setNavigationReady(false);
      _stopChatBadgeRefresh();
      return;
    }

    final isAuthenticated = _authCubit.state.isAuthenticated;
    _pushService.setNavigationReady(isAuthenticated);

    if (isAuthenticated) {
      await _pushService.syncDeviceRegistration();
      await _refreshChatBadge();
      _startChatBadgeRefresh();
    } else {
      _stopChatBadgeRefresh();
    }
  }

  Future<void> _refreshChatBadge() async {
    if (!mounted || !_authCubit.state.isAuthenticated) return;
    try {
      if (mounted) {
        await _chatCubit.loadConversations(silent: true);
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật badge: $e");
    }
  }

  void _startChatBadgeRefresh() {
    _chatBadgeTimer ??= Timer.periodic(
      const Duration(seconds: 20),
      (_) => unawaited(_refreshChatBadge()),
    );
  }

  void _stopChatBadgeRefresh() {
    _chatBadgeTimer?.cancel();
    _chatBadgeTimer = null;
  }

  // --- DEEP LINK ---

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (_) {}

    _deepLinkSub = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  void _handleDeepLink(Uri uri) {
    if (!mounted) return;
    final bool isPaymentResult =
        uri.host == "payment-result" ||
        uri.path == "/payment-result" ||
        uri.path == "/order-result";
    if (!isPaymentResult) return;

    final orderId = int.tryParse(uri.queryParameters["orderId"] ?? "") ?? 0;
    if (orderId <= 0) return;

    setState(() {
      _pendingPaymentNavigation = _PendingPaymentNavigation(
        orderId: orderId,
        status: uri.queryParameters["status"] ?? "",
        valid: uri.queryParameters["valid"] ?? "",
      );
    });
    _queuePendingPaymentNavigationFlush();
  }

  void _queuePendingPaymentNavigationFlush() {
    if (!mounted || _hasQueuedPendingPaymentFlush) return;
    _hasQueuedPendingPaymentFlush = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hasQueuedPendingPaymentFlush = false;
      if (!mounted) return;
      unawaited(_flushPendingPaymentNavigation());
    });
  }

  Future<void> _flushPendingPaymentNavigation() async {
    if (!mounted || _isFlushingPendingPaymentNavigation) return;

    final pending = _pendingPaymentNavigation;
    if (pending == null || !_authCubit.state.isInitialized) return;

    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null && lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final currentLocation = _safeCurrentLocation();
    if (currentLocation == "/order-result") {
      _pendingPaymentNavigation = null;
      return;
    }
    if (currentLocation == "/splash") return;

    _isFlushingPendingPaymentNavigation = true;
    try {
      _router.go("/order-result", extra: pending.toExtra());
    } finally {
      _isFlushingPendingPaymentNavigation = false;
    }
  }

  String _safeCurrentLocation() {
    try {
      final path = _router.state.uri.path;
      return path.isEmpty ? "/" : path;
    } catch (_) {
      return "/";
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncPushState());
      _queuePendingPaymentNavigationFlush();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    _chatSub?.cancel();
    _router.routerDelegate.removeListener(_handleRouteChanged);
    _deepLinkSub?.cancel();
    _stopChatBadgeRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showPendingPaymentOverlay =
        _pendingPaymentNavigation != null &&
        _currentLocation != "/order-result";

    // Điều kiện hiển thị nút Chat
    final shouldShowSupportChat =
        _authCubit.state.isAuthenticated &&
        _currentLocation != "/login" &&
        _currentLocation != "/register" &&
        _currentLocation != "/chat" &&
        _currentLocation != "/splash" &&
        !showPendingPaymentOverlay;

    return MaterialApp.router(
      title: 'Helmet App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (showPendingPaymentOverlay) const _PendingPaymentOverlay(),
            if (shouldShowSupportChat)
              Positioned(
                right: _buttonOffset.dx,
                bottom:
                    _buttonOffset.dy + MediaQuery.of(context).padding.bottom,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      // Cập nhật vị trí khi kéo
                      _buttonOffset = Offset(
                        _buttonOffset.dx - details.delta.dx,
                        _buttonOffset.dy - details.delta.dy,
                      );

                      // Giới hạn trong màn hình để không bị mất nút
                      final size = MediaQuery.of(context).size;
                      _buttonOffset = Offset(
                        _buttonOffset.dx.clamp(0, size.width - 60),
                        _buttonOffset.dy.clamp(0, size.height - 150),
                      );
                    });
                  },
                  child: _SupportChatButton(
                    onTap: () => _router.push('/chat'),
                    unreadTotal: _unreadTotal,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SupportChatButton extends StatefulWidget {
  final VoidCallback onTap;
  final int unreadTotal;

  const _SupportChatButton({required this.onTap, required this.unreadTotal});

  @override
  State<_SupportChatButton> createState() => _SupportChatButtonState();
}

class _PendingPaymentNavigation {
  final int orderId;
  final String status;
  final String valid;

  const _PendingPaymentNavigation({
    required this.orderId,
    required this.status,
    required this.valid,
  });

  Map<String, dynamic> toExtra() {
    return {
      "orderId": orderId,
      "paymentUrl": "",
      "status": status,
      "valid": valid,
    };
  }
}

class _PendingPaymentOverlay extends StatelessWidget {
  const _PendingPaymentOverlay();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: colorScheme.surface.withValues(alpha: 0.96),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Đang mở kết quả thanh toán",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Vui lòng chờ trong giây lát.",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportChatButtonState extends State<_SupportChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Tốc độ nhịp thở
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Chạy hiệu ứng lặp lại vô hạn
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.secondary,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.forum_outlined,
                    color: Colors.white,
                    size: 27,
                  ),
                ),
                if (widget.unreadTotal > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 22,
                        minHeight: 22,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        widget.unreadTotal > 99
                            ? '99+'
                            : '${widget.unreadTotal}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
