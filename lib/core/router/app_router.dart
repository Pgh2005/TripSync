import 'package:go_router/go_router.dart';
import 'package:tripsync/features/auth/presentation/screens/login_screen.dart';
import 'package:tripsync/features/auth/presentation/screens/register_screen.dart';
import 'package:tripsync/features/auth/presentation/screens/splash_screen.dart';
import 'package:tripsync/features/profile/presentation/ProfileScreen.dart';
import 'package:tripsync/features/trip/data/models/trip_model.dart';
import 'package:tripsync/features/trip/presentation/screens/EditTripScreen.dart';
import 'package:tripsync/features/trip/presentation/screens/create_trip_screen.dart';
import 'package:tripsync/features/trip/presentation/screens/home_screen.dart';
import 'package:tripsync/features/trip/presentation/screens/join_trip_screen.dart';
import 'package:tripsync/features/trip/presentation/screens/trip_details_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) {
        return const HomeScreen();
      },
    ),
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/create-trip',
      builder: (context, state) => const CreateTripScreen(),
    ),
    GoRoute(
      path: '/trip-detail',
      builder: (context, state) {
        final trip = state.extra as TripModel;
        return TripDetailScreen(trip: trip);
      },
    ),
    GoRoute(
      path: '/edit-trip',
      builder: (context, state) {
        final trip = state.extra as TripModel; // گرفتن آبجکت از extra
        return EditTripScreen(trip: trip);
      },
    ),
    GoRoute(
      path: '/join-trip',
      builder: (context, state) {
        return const JoinTripScreen();
      },
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) {
        return const ProfileScreen();
      },
    ),
  ],
);
