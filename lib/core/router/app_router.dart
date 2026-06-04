import 'package:go_router/go_router.dart';
import 'package:tripsync/features/auth/presentation/screens/login_screen.dart';
import 'package:tripsync/features/auth/presentation/screens/register_screen.dart';
import 'package:tripsync/features/auth/presentation/screens/splash_screen.dart';
import 'package:tripsync/features/trip/presentation/screens/home_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
  ],
);
