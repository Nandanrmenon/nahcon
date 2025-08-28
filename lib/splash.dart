import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nahcon/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 2), () {
      // Navigate to your next screen here
      // Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 24,
          children: [
            // ScaleTransition(
            //   scale: _animation,
            //   child: const Text(
            //     'nahCon',
            //     style: TextStyle(
            //       fontSize: 48,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
            SizedBox(
              height: 128,
              width: 128,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: Image.asset('assets/nahCon.png')),
            )
                .animate()
                .untint(color: Colors.white)
                .blurXY(begin: 12, duration: Duration(milliseconds: 400))
                .scaleXY(begin: 1.5, duration: Duration(milliseconds: 400)),

            const Text(
              kAppName,
              style: TextStyle(
                fontSize: 48,
              ),
            )
                .animate()
                .untint(color: Colors.white)
                .blurXY(begin: 12, duration: Duration(milliseconds: 400))
                .scaleXY(begin: 1.5, duration: Duration(milliseconds: 400)),
          ],
        ),
      ),
    );
  }
}
