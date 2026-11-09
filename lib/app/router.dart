import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/splash/presentation/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Onboarding Screen'),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Login / Sign Up'),
      ),
      GoRoute(
        path: '/customer/home',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Customer Home & Feed'),
      ),
      GoRoute(
        path: '/restaurant/dashboard',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Restaurant Dashboard'),
      ),
      GoRoute(
        path: '/profile/setup',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Complete Your Profile'),
      ),
    ],
  );
});

/// Temporary placeholder widget to test route navigation
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: Text(title), backgroundColor: Colors.black),
      body: Center(
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
