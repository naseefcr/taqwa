import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';
import 'package:taqwa/providers/habit_data_provider.dart';
import 'package:taqwa/providers/theme_provider.dart';
import 'package:taqwa/screens/analytics_screen.dart';
import 'package:taqwa/screens/auth/auth_screens.dart';
import 'package:taqwa/screens/settings_screen.dart';
import 'package:taqwa/screens/weekly_screen.dart';
import 'package:taqwa/services/firebase_auth_service.dart';
import 'package:taqwa/services/firestore_sync_service.dart';

import 'firebase_options.dart';
// Import the new DailyScreen instead of TodayScreen
import 'screens/daily_screen.dart'; // Updated import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  runApp(const TaqwaApp());
}

class TaqwaApp extends StatelessWidget {
  const TaqwaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FirebaseAuthService()),
        ChangeNotifierProvider(create: (_) => FirestoreSyncService()),
        ChangeNotifierProxyProvider2<
          FirebaseAuthService,
          FirestoreSyncService,
          HabitDataProvider
        >(
          create: (context) => HabitDataProvider(),
          update: (context, authService, syncService, habitDataProvider) {
            // Initialize sync service with current user
            if (authService.isAuthenticated &&
                authService.currentUser != null) {
              syncService.initialize(authService.currentUser!.uid);
              habitDataProvider?.setSyncService(syncService);
            }
            return habitDataProvider ?? HabitDataProvider();
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Taqwa - Islamic Habit Tracker',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/auth': (context) => const WelcomeScreen(),
              '/main': (context) => const MainScreen(),
            },
            // Add route for navigating to specific dates
            onGenerateRoute: (settings) {
              if (settings.name == '/daily') {
                final DateTime? date = settings.arguments as DateTime?;
                return MaterialPageRoute(
                  builder: (_) => DailyScreen(initialDate: date),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

// Enhanced Splash Screen with Firebase initialization
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Show splash for minimum time
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Navigate to auth wrapper which will determine the appropriate screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder:
                (_) => AuthWrapper(
                  authenticatedWidget: const AuthenticatedSplashScreen(),
                  unauthenticatedWidget: const WelcomeScreen(),
                ),
          ),
        );
      }
    } catch (e) {
      print('Initialization error: $e');
      // Show error and navigate to welcome screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.mosque, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'تقوى',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Taqwa - Build God-Consciousness',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// Authenticated user initialization screen
class AuthenticatedSplashScreen extends StatefulWidget {
  const AuthenticatedSplashScreen({super.key});

  @override
  State<AuthenticatedSplashScreen> createState() =>
      _AuthenticatedSplashScreenState();
}

class _AuthenticatedSplashScreenState extends State<AuthenticatedSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  Future<void> _initializeUserData() async {
    try {
      final habitProvider = Provider.of<HabitDataProvider>(
        context,
        listen: false,
      );
      final authService = Provider.of<FirebaseAuthService>(
        context,
        listen: false,
      );
      final syncService = Provider.of<FirestoreSyncService>(
        context,
        listen: false,
      );

      if (authService.currentUser != null) {
        // Initialize sync service
        syncService.initialize(authService.currentUser!.uid);
        habitProvider.setSyncService(syncService);

        // Initialize Hive and load local data
        await habitProvider.initializeHive();

        // Try to sync with Firestore
        try {
          final hasInternet = await syncService.hasInternetConnection();
          if (hasInternet) {
            await habitProvider.syncWithFirestore();
          }
        } catch (e) {
          print('Sync error during initialization: $e');
          // Continue with local data if sync fails
        }

        // If no data exists, initialize with default data
        if (habitProvider.entries.isEmpty && habitProvider.categories.isEmpty) {
          habitProvider.initializeDefaultData();
        }
      }

      // Navigate to main screen
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      print('User data initialization error: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<FirebaseAuthService>(context);
    final syncService = Provider.of<FirestoreSyncService>(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mosque, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'تقوى',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome back, ${authService.currentUser?.displayName ?? 'User'}',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 48),
              if (syncService.isSyncing)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Syncing your data...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                )
              else
                const CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// Main Screen with Bottom Navigation (updated to use DailyScreen)
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const DailyScreen(), // Updated to use DailyScreen instead of TodayScreen
    const WeeklyScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today),
            selectedIcon: Icon(Icons.today),
            label: 'Daily', // Updated label from 'Today' to 'Daily'
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Weekly',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
