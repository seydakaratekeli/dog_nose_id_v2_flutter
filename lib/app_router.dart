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
import 'pages/edit_profile_page.dart';

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

    // STATEFUL SHELL ROUTE (Bottom Nav Bar) - Sayfalar cache'leniyor
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // Branch 0: HOME
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        
        // Branch 1: SCAN
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/scan',
              builder: (context, state) => const ScanPage(),
            ),
          ],
        ),
        
        // Branch 2: MAP/KAYIP
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/map',
              builder: (context, state) => const LostMapPage(dogId: ''),
            ),
          ],
        ),
        
        // Branch 3: PROFILE
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),

    // DİĞER ROUTE'LAR (Shell dışında)
    
    // Kayıp köpek rapor haritası (shell dışında full-screen)
    GoRoute(
      path: '/map/report/:dogId',
      builder: (context, state) {
        final dogId = state.pathParameters['dogId'] ?? '';
        return LostMapPage(dogId: dogId);
      },
    ),

    GoRoute(
      path: '/add-dog',
      builder: (context, state) => const AddDogPage(),
    ),

    // SCAN (shell dışında, kayıp köpek için)
    GoRoute(
      path: '/scan-for-found',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ScanPage(
          lostDogId: extra?['lostDogId'],
          lostRecordId: extra?['lostRecordId'],
        );
      },
    ),

    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),

    GoRoute(
      path: '/my-dogs',
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
);
