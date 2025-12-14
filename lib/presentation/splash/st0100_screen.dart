import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class St0100SplashScreen extends StatefulWidget {
  const St0100SplashScreen({super.key});
  @override
  State<St0100SplashScreen> createState() => _St0100SplashScreenState();
}

class _St0100SplashScreenState extends State<St0100SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/to0100');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('ST0100 スプラッシュ（かり）')),
    );
  }
}
