import 'dart:async';
import 'dart:convert';

import 'package:b2205946_duonghuuluan_luanvan/core/notifications/push_notification_api.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

const AndroidNotificationChannel _chatNotificationChannel =
    AndroidNotificationChannel(
      "chat_messages",
      "Chat messages",
      description: "Notifications for support chat messages",
      importance: Importance.high,
    );

@pragma("vm:entry-point")
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final PushNotificationApi _api = PushNotificationApi();
  final SharedPreferences _prefs = di.getIt<SharedPreferences>();

  GoRouter? _router;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _isBootstrapped = false;
  bool _isAvailable = false;
  bool _navigationReady = false;
  String? _pendingNavigationPath;
  bool _isSyncing = false;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<void> bootstrap() async {
    if (_isBootstrapped) return;
    _isBootstrapped = true;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _initializeLocalNotifications();
      await _configureForegroundPresentation();
      _listenForNotificationEvents();

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationNavigation(initialMessage.data);
      }

      _isAvailable = true;
    } catch (e) {
      debugPrint("Push bootstrap skipped: $e");
      _isAvailable = false;
    }
  }

  void attachRouter(GoRouter router) {
    _router = router;
    _flushPendingNavigation();
  }

  void setNavigationReady(bool ready) {
    _navigationReady = ready;
    _flushPendingNavigation();
  }

  Future<void> syncDeviceRegistration() async {
    if (!_isAvailable || _isSyncing) return;

    _isSyncing = true;
    try {
      final accessToken = _prefs.getString("access_token");
      if (accessToken == null || accessToken.isEmpty) {
        return;
      }

      final permission = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (!_isPermissionGranted(permission)) {
        return;
      }

      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      final oldToken = _prefs.getString("push_token");
      if (oldToken != null && oldToken.isNotEmpty && oldToken != token) {
        try {
          await _api.deactivateDevice(oldToken);
        } catch (_) {}
      }

      await _api.registerDevice(
        platform: _resolvePlatformName(),
        pushToken: token,
      );
      await _prefs.setString("push_token", token);
    } catch (e) {
      debugPrint("Push sync failed: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> deactivateCurrentDevice() async {
    final pushToken = _prefs.getString("push_token");
    if (pushToken == null || pushToken.isEmpty) {
      return;
    }

    final accessToken = _prefs.getString("access_token");
    if (accessToken == null || accessToken.isEmpty) {
      await _prefs.remove("push_token");
      return;
    }

    try {
      await _api.deactivateDevice(pushToken);
    } catch (e) {
      debugPrint("Push deactivate failed: $e");
    } finally {
      await _prefs.remove("push_token");
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          _openRouteOrDefer("/chat");
          return;
        }

        try {
          final data = jsonDecode(payload);
          if (data is Map) {
            _handleNotificationNavigation(Map<String, dynamic>.from(data));
            return;
          }
        } catch (_) {}

        _openRouteOrDefer("/chat");
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_chatNotificationChannel);
  }

  Future<void> _configureForegroundPresentation() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: true,
    );
  }

  void _listenForNotificationEvents() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationNavigation(message.data);
    });

    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((
      token,
    ) async {
      if (token.isEmpty) return;
      await syncDeviceRegistration();
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final title =
        notification?.title ??
        message.data["title"]?.toString() ??
        "Tin nhắn mới";
    final body =
        notification?.body ??
        message.data["body"]?.toString() ??
        "Bạn có tin nhắn mới";

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          "chat_messages",
          "Chat messages",
          channelDescription: "Notifications for support chat messages",
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    final event = data["event"]?.toString();
    if (event == "chat.message.created") {
      _openRouteOrDefer("/chat");
      return;
    }

    if (event == "order.review.rejected") {
      final orderId = int.tryParse(data["order_id"]?.toString() ?? "");
      if (orderId != null && orderId > 0) {
        _openRouteOrDefer("/orders/$orderId");
        return;
      }

      final refundSupportStatus =
          data["refund_support_status"]?.toString().trim().toLowerCase() ?? "";
      if (refundSupportStatus == "contact_required") {
        _openRouteOrDefer("/chat");
      }
    }
  }

  void _openRouteOrDefer(String path) {
    if (_router == null || !_navigationReady) {
      _pendingNavigationPath = path;
      return;
    }

    _pendingNavigationPath = null;
    _router!.go(path);
  }

  void _flushPendingNavigation() {
    if (_pendingNavigationPath != null && _router != null && _navigationReady) {
      final path = _pendingNavigationPath!;
      _pendingNavigationPath = null;
      _router!.go(path);
    }
  }

  bool _isPermissionGranted(NotificationSettings settings) {
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  String _resolvePlatformName() {
    if (kIsWeb) {
      return "web";
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return "ios";
    }
    return "android";
  }
}
