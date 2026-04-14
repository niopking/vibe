import 'package:flutter/material.dart';
import 'models.dart';

const kOrange = Color(0xFFF99427);
const kDark = Color(0xFF161616);
const kGrey = Color(0xFF2A2A2A);

class LoadingScreen extends StatefulWidget {
  final String nextRoute;
  const LoadingScreen({super.key, required this.nextRoute});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _barController;
  late final AnimationController _fadeController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _barWidth;
  late final Animation<double> _screenFade;

  @override
  void initState() {
    super.initState();

    // Logo pop-in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);

    // Progress bar — bounce naprijed-nazad dok traje učitavanje
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _barWidth = CurvedAnimation(
      parent: _barController,
      curve: Curves.easeInOut,
    );

    // Fade out whole screen
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _screenFade = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _startSequence();
  }

  void _startSequence() async {
    // Startuj fetch odmah paralelno sa animacijom
    final fetchFuture = fetchArticles();

    await Future.delayed(const Duration(milliseconds: 200));
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _barController.repeat(reverse: true); // neprestano dok ne učita

    // Čekaj minimalno trajanje I kraj fetcha
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2000)),
      fetchFuture,
    ]);

    _barController.stop();
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 420));
    if (mounted) Navigator.pushReplacementNamed(context, widget.nextRoute);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _barController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _screenFade,
      child: Scaffold(
        backgroundColor: kDark,
        body: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Logo + tagline
              Center(
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: Image.asset(
                          'images/logobeztr.png',
                          width: 130,
                          height: 130,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: const Text(
                          'Pripremamo tvoj Vibe...',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        height: 3,
                        color: kGrey,
                        child: AnimatedBuilder(
                          animation: _barWidth,
                          builder: (context, _) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _barWidth.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kOrange,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _logoFade,
                      child: const Text(
                        'Učitavanje...',
                        style: TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 12,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
