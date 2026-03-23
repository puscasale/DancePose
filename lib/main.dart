import 'package:flutter/material.dart';
import 'screens/welcome/welcome_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const DancePoseApp());
}

class DancePoseApp extends StatelessWidget {
  const DancePoseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DancePose',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const WelcomeScreen(),
    );
  }
}