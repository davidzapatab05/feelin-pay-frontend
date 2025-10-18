import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'views/login_screen_improved.dart';
import 'views/dashboard_improved.dart';
import 'views/login_otp_verification_screen.dart';
import 'views/system_permissions_screen.dart';
import 'views/user_management_screen.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/system_controller.dart';
import 'services/payment_notification_service.dart';
import 'services/sms_service.dart';
import 'services/background_service.dart';
import 'database/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar base de datos
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializar base de datos local
  await LocalDatabase.database;

  // Iniciar servicios
  await PaymentNotificationService.startListening();
  await SMSService.procesarSMSPendientes();
  await BackgroundService.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => DashboardController()),
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => SystemController()),
      ],
      child: MaterialApp(
        title: 'Feelin Pay',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const LoginScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/otp-verification': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>?;
            return LoginOTPVerificationScreen(
              email: args?['email'] ?? '',
              type: args?['type'] ?? 'login',
            );
          },
          '/system-permissions': (context) => const SystemPermissionsScreen(),
          '/user-management': (context) => const UserManagementScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
