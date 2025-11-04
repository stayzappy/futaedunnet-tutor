import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Add this import for FlutterQuillLocalizations
import 'package:flutter_quill/flutter_quill.dart';
// Add this import for Flutter's built-in localization delegates
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/app_theme.dart';
import 'config/pocketbase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/course_provider.dart';
import 'providers/unit_provider.dart';
import 'providers/enrollment_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/tutor_dashboard_screen.dart';
import 'services/pocketbase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize PocketBase
  await PocketBaseConfig.initialize();
  
  runApp(const FutaEdunetTutorApp());
}

class FutaEdunetTutorApp extends StatelessWidget {
  const FutaEdunetTutorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(PocketBaseService()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CourseProvider>(
          create: (_) => CourseProvider(PocketBaseService()),
          update: (_, auth, previous) => 
            previous ?? CourseProvider(PocketBaseService()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UnitProvider>(
          create: (_) => UnitProvider(PocketBaseService()),
          update: (_, auth, previous) => 
            previous ?? UnitProvider(PocketBaseService()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EnrollmentProvider>(
          create: (_) => EnrollmentProvider(PocketBaseService()),
          update: (_, auth, previous) => 
            previous ?? EnrollmentProvider(PocketBaseService()),
        ),
      ],
      child: MaterialApp(
        title: 'FutaEdunet Tutor Portal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // Add localizations delegates and supported locales
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate, // Add this line
        ],
        supportedLocales: const [
          Locale('en', 'US'), // Add other locales if needed
          // Add other supported locales for FlutterQuill if required
        ],
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const TutorDashboardScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Check if user is already logged in
        if (authProvider.isAuthenticated) {
          return const TutorDashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}