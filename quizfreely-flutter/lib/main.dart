import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quizfreely_flutter/screens/dashboard_screen.dart';
import 'package:quizfreely_flutter/screens/studyset_screen.dart';
import 'package:quizfreely_flutter/screens/edit_screen.dart';
import 'package:quizfreely_flutter/screens/flashcards_screen.dart';
import 'package:quizfreely_flutter/screens/practice_screen.dart';
import 'package:quizfreely_flutter/screens/match_screen.dart';
import 'package:quizfreely_flutter/screens/explore_screen.dart';
import 'package:quizfreely_flutter/screens/account_screen.dart';
import 'package:quizfreely_flutter/screens/settings_screen.dart';
import 'package:quizfreely_flutter/services/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings().load();
  runApp(const QuizFreelyApp());
}

final GoRouter _router = GoRouter(
  routes: [
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: '/account',
          builder: (context, state) => const AccountScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/studyset/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return StudysetScreen(studysetId: id);
      },
    ),
    GoRoute(
      path: '/edit',
      builder: (context, state) => const EditScreen(),
    ),
    GoRoute(
      path: '/edit/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return EditScreen(studysetId: id);
      },
    ),
    GoRoute(
      path: '/flashcards/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return FlashcardsScreen(studysetId: id);
      },
    ),
    GoRoute(
      path: '/practice/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PracticeScreen(studysetId: id);
      },
    ),
    GoRoute(
      path: '/match/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return MatchScreen(studysetId: id);
      },
    ),
  ],
);

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/explore')) return 1;
    if (location.startsWith('/account')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/explore');
              break;
            case 2:
              context.go('/account');
              break;
            case 3:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'My Sets',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_outlined),
            selectedIcon: Icon(Icons.sync_rounded),
            label: 'Sync',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class QuizFreelyApp extends StatelessWidget {
  const QuizFreelyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QuizFreely',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system,
    );
  }

  ThemeData _buildLightTheme() {
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF03DAC6);
    const bg = Color(0xFFF7F7F9);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        secondary: secondary,
        brightness: Brightness.light,
        surface: bg,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme(),
      cardTheme: CardThemeData(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: const Color(0xFF1A1A2E),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A2E),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF03DAC6);
    const bg = Color(0xFF0F0F1A);
    const card = Color(0xFF1E1E35);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        secondary: secondary,
        brightness: Brightness.dark,
        surface: bg,
      ).copyWith(
        surface: bg,
        surfaceContainerHighest: card,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardThemeData(
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: card,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: bg,
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 8,
      ),
      dividerColor: const Color(0xFF2A2A45),
    );
  }
}
