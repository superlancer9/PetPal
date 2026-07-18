import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'ui/screens/home.dart';
import 'ui/screens/login.dart';
import 'viewmodels/auth_vm.dart';
import 'viewmodels/pet_vm.dart';
import 'viewmodels/reminder_vm.dart';
import 'viewmodels/health_vm.dart';
import 'viewmodels/navigation_vm.dart';
import 'viewmodels/vets_vm.dart';
import 'viewmodels/admin_vm.dart';
import 'viewmodels/articles_vm.dart';
import 'ui/screens/admin_articles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up global error handling to catch crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('❌ Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Initialize Firebase - this must succeed for the app to work
  bool firebaseInitialized = false;
  String? firebaseError;
  
  try {
    await Firebase.initializeApp();
    firebaseInitialized = true;
    debugPrint('✅ Firebase initialized successfully');
  } catch (e, stackTrace) {
    firebaseInitialized = false;
    firebaseError = e.toString();
    debugPrint('❌ Firebase initialization failed: $e');
    debugPrint('Stack trace: $stackTrace');
  }
  
  // Run app - it will handle Firebase errors gracefully
  runApp(PetPalApp(firebaseInitialized: firebaseInitialized, firebaseError: firebaseError));
}

class PetPalApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? firebaseError;
  
  const PetPalApp({
    super.key,
    required this.firebaseInitialized,
    this.firebaseError,
  });

  @override
  Widget build(BuildContext context) {
    // Show error screen if Firebase failed to initialize
    if (!firebaseInitialized) {
      return MaterialApp(
        title: 'PetPal',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Firebase Configuration Error',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    firebaseError ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'To fix this:\n1. Open Xcode\n2. Add GoogleService-Info.plist to Runner target\n3. Rebuild the app',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthVM()),
        ChangeNotifierProvider(create: (_) => PetVM()),
        ChangeNotifierProvider(create: (_) => ReminderVM()),
        ChangeNotifierProvider(create: (_) => HealthVM()),
        ChangeNotifierProvider(create: (_) => NavigationVM()),
        ChangeNotifierProvider(create: (_) => VetsVM()),
        ChangeNotifierProvider(create: (_) => AdminVM()),
        ChangeNotifierProvider(create: (_) => ArticlesVM()),
      ],
      child: MaterialApp(
        title: 'PetPal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Arimo',
        ),
        home: const AuthWrapper(),
        builder: (context, child) {
          // Error boundary to catch any widget errors
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child ?? const Scaffold(
              body: Center(
                child: Text('Loading...'),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper widget that observes authentication state
/// View: Only handles UI based on AuthVM state
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final authVM = context.watch<AuthVM>();
      final adminVM = context.watch<AdminVM>();
      
      if (authVM.isAuthenticated) {
        // Check if user is admin and route accordingly
        if (adminVM.isAdmin) {
          return const AdminArticlesScreen();
        } else {
          return const PetContainer();
        }
      } else {
        return const LoginScreen();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in AuthWrapper: $e');
      debugPrint('Stack trace: $stackTrace');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Try to show login screen directly
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Show Login Screen'),
              ),
            ],
          ),
        ),
      );
    }
  }
}
