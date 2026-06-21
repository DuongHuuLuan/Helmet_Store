import 'package:b2205946_duonghuuluan_luanvan/app.dart';
import 'package:b2205946_duonghuuluan_luanvan/provider.dart';
import 'package:b2205946_duonghuuluan_luanvan/core/notifications/push_notification_service.dart';
import 'package:b2205946_duonghuuluan_luanvan/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  await di.init();
  await PushNotificationService.instance.bootstrap();
  runApp(MultiProvider(providers: Providers, child: const MyApp()));
}
