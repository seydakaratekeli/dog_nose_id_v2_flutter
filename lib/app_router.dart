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
import 'pages/lost_dog_list_page.dart';
import 'pages/found_status_page.dart';
import 'pages/not_found_page.dart';
import 'pages/my_dogs_page.dart';
import 'main_shell.dart';
import 'pages/report_found_dog_page.dart';
import 'pages/my_reports_page.dart';
import 'pages/found_dog_detail_page.dart';
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

GoRoute(
  path: '/map',
  builder: (context, state) {
    // Eğer extra null ise boş string ata, çökmesini engelle
    final dogId = (state.extra as String?) ?? ''; 
    return LostMapPage(dogId: dogId);
  },
),

        // PROFILE
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),

         GoRoute(
          path: '/my-dogs', // Yeni rota adresimiz
          builder: (context, state) => const MyDogsPage(),
        ),

        GoRoute(
  path: '/my-reports',
  builder: (context, state) => const MyReportsPage(),
),

        // DOG DETAIL
        GoRoute(
          path: '/dog-detail',
          builder: (context, state) {
            final dog = state.extra as Dog;
            return DogDetailPage(dog: dog);
          },
        ),

        GoRoute(
  path: '/lost-dogs',
  builder: (context, state) => const LostDogListPage(),
),

GoRoute(
  path: '/found',
  builder: (context, state) {
    final dog = state.extra as Dog;
    return FoundDogPage(dog: dog);
  },
),

// FOUND DOG DETAIL
    GoRoute(
      path: '/found-dog-detail',
      builder: (context, state) {
        // Veriyi Map olarak alıyoruz
        final data = state.extra as Map<String, dynamic>;
        return FoundDogDetailPage(data: data);
      },
    ),
    
GoRoute(
  path: '/not-found',
  builder: (context, state) => const NotFoundPage(),
),

GoRoute(
      path: '/report-found',
      builder: (context, state) => const ReportFoundDogPage(),
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
