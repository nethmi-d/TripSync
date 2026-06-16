import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen());

      case AppRoutes.login:
        return _buildRoute(const LoginScreen());

      case AppRoutes.signup:
        return _buildRoute(const SignupScreen());

      case AppRoutes.dashboard:
        return _buildRoute(const DashboardScreen());

      case AppRoutes.profile:
        return _buildRoute(const ProfileScreen());

      default:
        return _buildRoute(
          Scaffold(
            appBar: AppBar(title: const Text('Coming Soon')),
            body: const Center(child: Text('This screen is not created yet.')),
          ),
        );
    }
  }

  static MaterialPageRoute _buildRoute(Widget screen) {
    return MaterialPageRoute(builder: (_) => screen);
  }
}
