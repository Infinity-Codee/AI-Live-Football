/// FootAI Insight — Main App Entry Point

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'config/app_strings.dart';
import 'models/match.dart';
import 'providers/matches_provider.dart';
import 'providers/prediction_provider.dart';
import 'services/storage_service.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/match_insights/match_insights_screen.dart';
import 'screens/standings/standings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize services
  await StorageService().init();

  // Load the saved UI language (English / Turkish)
  LocaleController.instance.load();

  runApp(const FootAIApp());
}

class FootAIApp extends StatelessWidget {
  const FootAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MatchesProvider()),
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
        ChangeNotifierProvider<LocaleController>.value(
          value: LocaleController.instance,
        ),
      ],
      child: ListenableBuilder(
        listenable: LocaleController.instance,
        builder: (context, _) => MaterialApp(
        title: 'FootAI Insight',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return _fadeRoute(const SplashScreen());
            case '/onboarding':
              return _fadeRoute(const OnboardingScreen());
            case '/main':
              return _fadeRoute(const MainScreen());
            case '/home':
              return _fadeRoute(const HomeScreen());
            case '/match':
              final match = settings.arguments as MatchModel;
              return _slideRoute(MatchInsightsScreen(match: match));
            case '/standings':
              return _slideRoute(const StandingsScreen());
            default:
              return _fadeRoute(const MainScreen());
          }
        },
        ),
      ),
    );
  }

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
