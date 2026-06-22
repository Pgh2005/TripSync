import 'package:go_router/go_router.dart';
import 'package:tripsync/features/auth/presentation/screens/login_screen.dart';
import 'package:tripsync/features/auth/presentation/screens/register_screen.dart';
import 'package:tripsync/features/auth/presentation/screens/splash_screen.dart';
import 'package:tripsync/features/expenses/data/models/expense_model.dart';
import 'package:tripsync/features/expenses/presentation/screens/add_expenses_screen.dart';
import 'package:tripsync/features/expenses/presentation/screens/trip_expenses_screen.dart';
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
    // register & login
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    // Trip
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
        final trip = state.extra as TripModel;
        return EditTripScreen(trip: trip);
      },
    ),
    GoRoute(
      path: '/join-trip',
      builder: (context, state) {
        return const JoinTripScreen();
      },
    ),
    // Profile
    GoRoute(
      path: '/profile',
      builder: (context, state) {
        return const ProfileScreen();
      },
    ),
    // Expenses
    GoRoute(
      path: '/trip-expenses',
      builder: (context, state) {
        final tripId = state.extra as String;
        return TripExpensesScreen(tripId: tripId);
      },
    ),
    GoRoute(
      path: '/add-expense',
      builder: (context, state) {
        final tripId = state.extra as String;
        return AddExpenseScreen(tripId: tripId);
      },
    ),
    GoRoute(
      path: '/trips/:tripId/edit-expense',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;
        final expense = state.extra as ExpenseModel;

        return AddExpenseScreen(tripId: tripId, expense: expense);
      },
    ),
  ],
);
