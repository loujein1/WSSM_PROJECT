import 'package:flutter/material.dart';
import 'services/auth_service.dart';  // Import AuthService
import 'screens/dashboard.dart';
import 'screens/login.dart';
import 'screens/register.dart';
import 'screens/settings.dart';
import 'screens/admin_panel.dart';
import 'package:image_picker/image_picker.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isUserLoggedIn = false;
  Map<String, dynamic>? user;

  try {
    isUserLoggedIn = await AuthService.isLoggedIn();
    if (isUserLoggedIn) {
      user = await AuthService.getCurrentUser();
      print("App starting with logged in user: $user");
    } else {
      print("App starting with no logged in user");
    }
  } catch (e) {
    print("Error checking login status: $e");
    isUserLoggedIn = false;
    user = null;
  }

  runApp(MyApp(isLoggedIn: isUserLoggedIn, user: user));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  final Map<String, dynamic>? user;

  const MyApp({super.key, required this.isLoggedIn, required this.user});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool isLoggedIn;
  Map<String, dynamic>? user;

  @override
  void initState() {
    super.initState();
    isLoggedIn = widget.isLoggedIn;
    user = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    print("Building app with isLoggedIn: $isLoggedIn, user: $user");
    
    return MaterialApp(
      title: 'Water Usage Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: isLoggedIn ? '/dashboard' : '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => DashboardWrapper(),
        '/settings': (context) => SettingsWrapper(),
        '/admin': (context) => AdminWrapper(),
      },
      // Add a navigation observer to debug route changes
      navigatorObservers: [
        RouteObserver(),
      ],
    );
  }
}

// Wrapper classes that check authentication status before rendering screens
class DashboardWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StatefulAuthentication(
      builder: (user) => Dashboard(user: user),
    );
  }
}

class SettingsWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StatefulAuthentication(
      builder: (user) => SettingsScreen(user: user),
    );
  }
}

class AdminWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StatefulAuthentication(
      builder: (user) => AdminPanelScreen(user: user),
    );
  }
}

// Stateful authentication widget that checks login once and doesn't reload
class StatefulAuthentication extends StatefulWidget {
  final Widget Function(Map<String, dynamic>) builder;
  
  const StatefulAuthentication({Key? key, required this.builder}) : super(key: key);
  
  @override
  State<StatefulAuthentication> createState() => _StatefulAuthenticationState();
}

class _StatefulAuthenticationState extends State<StatefulAuthentication> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  Map<String, dynamic> _userData = {};
  bool _redirected = false;
  
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }
  
  Future<void> _checkAuthentication() async {
    bool isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      Map<String, dynamic>? user = await AuthService.getCurrentUser();
      if (user != null) {
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _userData = user;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAuthenticated = false;
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (!_isAuthenticated && !_redirected) {
      _redirected = true;
      // Use Future.microtask to avoid build phase errors
      Future.microtask(() {
        Navigator.of(context).pushReplacementNamed('/login');
      });
    }
    
    return _isAuthenticated ? widget.builder(_userData) : 
      const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
  }
}

// Helper function to check login status and get user
Future<Map<String, dynamic>?> _getUserIfLoggedIn() async {
  bool isLoggedIn = await AuthService.isLoggedIn();
  if (isLoggedIn) {
    return await AuthService.getCurrentUser();
  }
  return null;
}

