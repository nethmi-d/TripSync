import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_generator.dart';
import 'core/services/firebase_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const TripSyncApp());
}

class TripSyncApp extends StatelessWidget {
  const TripSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
