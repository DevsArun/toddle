import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 550),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, Animation<double> a, __, Widget child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlayfulBackground(
      seed: 3,
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (BuildContext context, Widget? child) {
            final double pop = Curves.elasticOut.transform(_c.value.clamp(0, 1));
            return Transform.scale(scale: 0.6 + pop * 0.4, child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Color(0xFFFFB74D), Color(0xFFFF7043)],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppTheme.brand.withOpacity(0.45),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: const Icon(Icons.palette_rounded,
                    size: 100, color: Colors.white),
              ),
              const SizedBox(height: 28),
              const Text(
                'Baby Coloring',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Toddler games made for little hands',
                style: TextStyle(fontSize: 19, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
