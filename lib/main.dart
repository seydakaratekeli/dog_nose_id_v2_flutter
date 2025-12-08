import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 📦 Provider paketi gerekli
import 'app_router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart'; // Yeni oluşturduğumuz dosya

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ThemeProvider'ı başlat ve yükle
  final themeProvider = ThemeProvider();
  await themeProvider.loadTheme();

  runApp(
    ChangeNotifierProvider(
      create: (_) => themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider'dan tema modunu dinle
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp.router(
      title: 'Pati İzi',
      debugShowCheckedModeBanner: false,
      
      // Tema Ayarları
      themeMode: themeProvider.themeMode, 
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      routerConfig: appRouter,
    );
  }
}