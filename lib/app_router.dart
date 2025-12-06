import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Pages
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/add_dog_page.dart';
import 'pages/scan_page.dart';
import 'pages/match_result_page.dart';
import 'pages/lost_map_page.dart';
import 'pages/dog_detail_page.dart';
import 'pages/profile_page.dart';
import 'pages/edit_dog_page.dart';

import 'main_shell.dart';

// Models
import 'models/dog.dart';

final appRouter = GoRouter(
  debugLogDiagnostics: true,

  routes: [
    // LOGIN (default)
    GoRoute(
      path: '/',
      builder: (context, state) => const LoginPage(),
    ),

    // REGISTER
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),

    // SHELL ROUTE (Bottom Nav Bar)
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),

      routes: [
        // HOME
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),

        // SCAN
        GoRoute(
          path: '/scan',
          builder: (context, state) => const ScanPage(),
        ),

         GoRoute(
      path: '/add-dog',                         // ⭐ BUNU EKLEDİK!
      builder: (context, state) => const AddDogPage(),
    ),

        // MAP (dogId gerekli!)
        GoRoute(
          path: '/map',
          builder: (context, state) {
            final dogId = state.extra as String;
            return LostMapPage(dogId: dogId);
          },
        ),

        // PROFILE
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),

        // DOG DETAIL
        GoRoute(
          path: '/dog-detail',
          builder: (context, state) {
            final dog = state.extra as Dog;
            return DogDetailPage(dog: dog);
          },
        ),

        // EDIT DOG
        GoRoute(
          path: '/edit-dog',
          builder: (context, state) {
            final dog = state.extra as Dog;
            return EditDogPage(dog: dog);
          },
        ),

        // MATCH RESULT
        GoRoute(
          path: '/result',
          builder: (context, state) {
            final map = state.extra as Map<String, dynamic>;
            return MatchResultPage(
              dog: map['dog'],
              score: map['score'],
              image: map['image'],
            );
          },
        ),
      ],
    ),
  ],
);
