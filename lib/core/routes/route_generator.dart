import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/trips/screens/create_trip.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/trips/screens/trip_dashboard_screen.dart';
import '../../features/trips/screens/trip_settings.dart';
import '../../features/members/screens/invite_members.dart';
import '../../features/itinerary/screens/itinerary_screen.dart';
import '../../features/tasks/screens/tasks_screen.dart';
import '../../features/budget/screens/add_expenses_screen.dart';

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

      case AppRoutes.notifications:
        return _buildRoute(NotificationsScreen());

      case AppRoutes.createTrip:
        return _buildRoute(const CreateTripScreen());

      case AppRoutes.tripDashboard:
        return _buildRoute(
          TripDashboardScreen(tripId: settings.arguments as String?),
        );

      case AppRoutes.tripSettings:
        return _buildRoute(const TripSettingsScreen());

      case AppRoutes.inviteMembers:
        return _buildRoute(const InviteMembersScreen());

      case AppRoutes.itinerary:
        return _buildRoute(const ItineraryScreen());

      case AppRoutes.tasks:
        return _buildRoute(const TasksScreen());

      case AppRoutes.addExpenses:
        return _buildRoute(const AddExpensesScreen());

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
