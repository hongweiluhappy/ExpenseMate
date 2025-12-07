import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_state.dart';
import 'core/auth_service.dart';
import 'core/notification_service.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';
import 'features/expense/add_expense_page.dart';
import 'features/charts/charts_page.dart';
import 'features/budget/budget_settings_page.dart';
import 'features/recommendation/budget_recommendation_page.dart';
import 'features/subscription/subscriptions_page.dart';
import 'features/subscription/add_subscription_page.dart';
import 'features/jobs/jobs_page.dart';
import 'features/jobs/add_job_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize notifications
  await NotificationService.I.initialize();

  runApp(const ExpenseMateApp());
}

class ExpenseMateApp extends StatelessWidget {
  const ExpenseMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpenseMate',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
      ],
      home: const AuthWrapper(),
      routes: {
        '/add-expense': (context) => const AddExpensePage(),
        '/charts': (context) => const ChartsPage(),
        '/budget-settings': (context) => const BudgetSettingsPage(),
        '/budget-recommendation': (context) => const BudgetRecommendationPage(),
        '/subscriptions': (context) => const SubscriptionsPage(),
        '/add-subscription': (context) => const AddSubscriptionPage(),
        '/jobs': (context) => const JobsPage(),
        '/add-job': (context) => const AddJobPage(),
      },
    );
  }
}

/// Wrapper to handle authentication state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.I.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder(
            future: AppState.I.load(),
            builder: (context, loadSnapshot) {
              if (loadSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your data...'),
                      ],
                    ),
                  ),
                );
              }

              if (loadSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading data: ${loadSnapshot.error}'),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            // Reload
                            (context as Element).markNeedsBuild();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const HomePage();
            },
          );
        }

        // User is not logged in
        return const LoginPage();
      },
    );
  }
}