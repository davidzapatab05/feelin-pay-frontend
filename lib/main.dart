import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';
import 'views/login_screen_improved.dart';
import 'views/dashboard_improved.dart';
import 'views/password_recovery_screen.dart';
import 'views/otp_verification_screen.dart';
import 'views/system_check_screen.dart';
import 'views/permissions_management_screen.dart';
import 'views/login_otp_verification_screen.dart';
import 'views/user_management_screen.dart';
import 'controllers/auth_controller.dart';
import 'controllers/dashboard_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/system_controller.dart';
import 'widgets/route_guard.dart';
import 'services/yape_notification_service.dart';
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
  await YapeNotificationService.startListening();
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
          // Rutas protegidas (requieren autenticación y verificación)
          '/dashboard': (context) =>
              RouteGuard(route: '/dashboard', child: const DashboardScreen()),
          '/password-recovery': (context) => const PasswordRecoveryScreen(),
          '/system-check': (context) => RouteGuard(
            route: '/system-check',
            child: const SystemCheckScreen(),
          ),
          '/permissions': (context) => RouteGuard(
            route: '/permissions',
            child: const PermissionsManagementScreen(),
          ),

          // Rutas de super admin
          '/user-management': (context) => RouteGuard(
            route: '/user-management',
            child: const UserManagementScreen(),
          ),

          '/login-otp': (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as Map<String, dynamic>;
            return LoginOTPVerificationScreen(email: args['email']);
          },
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/otp-verification') {
            final args = settings.arguments as Map<String, dynamic>?;
            if (args != null) {
              return MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(
                  email: args['email'] ?? '',
                  userId: args['userId'] ?? '',
                ),
              );
            }
          }
          return null;
        },
        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSystemAndAuth();
    });
  }

  Future<void> _checkSystemAndAuth() async {
    final systemController = context.read<SystemController>();
    final authController = context.read<AuthController>();

    // Iniciar listener de conectividad
    systemController.startConnectivityListener();

    // Verificar autenticación
    await authController.checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthController, SystemController>(
      builder: (context, authController, systemController, child) {
        if (authController.isLoading ||
            systemController.isCheckingConnectivity ||
            systemController.isCheckingPermissions) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return authController.isLoggedIn
            ? const DashboardScreen()
            : const LoginScreen();
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
