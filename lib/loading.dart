import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'models.dart';

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
  late final Animation<double> _screenFade;

  @override
  void initState() {
    super.initState();

    // Logo pop-in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _logoScale = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut);
    _logoFade  = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);

    // Progress bar — bez fiksne krive, kontrolišemo ručno
    _barController = AnimationController(vsync: this);

    // Fade out samo sadržaja (ne cijelog Scaffolda!)
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _screenFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _startSequence();
  }

  void _startSequence() async {
    final fetchFuture = fetchArticles();

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Bar ide do 85% u 2.5s s easeOut — kreće brzo, usporava pri kraju
    _barController.animateTo(
      0.85,
      duration: const Duration(milliseconds: 2500),
      curve: Curves.easeOut,
    );

    // Čekaj minimalno 2s I kraj fetcha
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2000)),
      fetchFuture,
    ]);
    if (!mounted) return;

    // Glatko popuni zadnjih 15% do 100%
    await _barController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
    if (!mounted) return;

    // Fade out sadržaja, Scaffold ostaje taman
    await _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 80));
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
    return Scaffold(
      // Uvijek tamna — loading screen je branded, ne mijenja se s temom
      backgroundColor: const Color(0xFF161616),
      body: SafeArea(
        child: FadeTransition(
          // Samo sadržaj fades, Scaffold pozadina ostaje tamna → nema bijelog flasha
          opacity: _screenFade,
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
                        color: const Color(0xFF2A2A2A),
                        child: AnimatedBuilder(
                          animation: _barController,
                          builder: (context, _) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _barController.value,
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
