import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _buttonFade;

  @override
  void initState() {
    super.initState();

    // Make status bar transparent
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Logo pop-in
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    // Text slide up
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    // Button fade
    _buttonFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Image ──────────────────
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/onion.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),

          // ── Gradient Overlay ──────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.25),
                  const Color(0xFF3D1A00).withOpacity(0.65),
                  const Color(0xFF1A0800).withOpacity(0.88),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── Decorative Circle (top-right) ─────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
              ),
            ),
          ),

          // ── Decorative Circle (bottom-left) ───
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withOpacity(0.1),
              ),
            ),
          ),

          // ── Main Content ──────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // ── Top badge ──────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryLight.withOpacity(0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, color: Colors.white70, size: 12),
                       // SizedBox(width: 6),
                        // Text(
                        //   'Trusted by 500+ Mandis',
                        //   style: TextStyle(
                        //     color: Colors.white70,
                        //     fontSize: 11,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Logo + App Name ───────────
                  Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _logoFade,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          // Logo Container
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.45),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // App Name
                          const Text(
                            'Market ERP',
                            //agri broker
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Tagline
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'स्मार्ट मंडी व्यवस्थापन',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Bottom Section ────────────
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _textFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Feature pills row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _featurePill(Icons.agriculture_rounded, 'Procurement'),
                            _featurePill(Icons.people_rounded, 'Farmers'),
                            _featurePill(Icons.inventory_2_rounded, 'Inventory'),
                            _featurePill(Icons.receipt_long_rounded, 'Payments'),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'Manage procurement, payments &\nfarm operations — all in one place.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Get Started Button ────────
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return FadeTransition(opacity: _buttonFade, child: child);
                    },
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _onGetStarted,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Already have account
                        GestureDetector(
                          onTap: _onGetStarted,
                          child: const Text(
                            'Already have an account? Sign in',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primaryLight, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


// import 'dart:async';
// import 'package:agr_market/core/constants/colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import '../../providers/auth_provider.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _ctrl;
//   late Animation<double>   _scaleFade;
//   late Animation<double>   _textFade;
//   late Animation<Offset>   _textSlide;

//   @override
//   void initState() {
//     super.initState();
//     SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.light,
//     ));
//     _ctrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 1600));
//     _scaleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
//         CurvedAnimation(parent: _ctrl,
//             curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));
//     _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
//         CurvedAnimation(parent: _ctrl,
//             curve: const Interval(0.4, 0.8, curve: Curves.easeIn)));
//     _textSlide = Tween<Offset>(
//         begin: const Offset(0, 0.3), end: Offset.zero).animate(
//         CurvedAnimation(parent: _ctrl,
//             curve: const Interval(0.4, 0.8, curve: Curves.easeOut)));
//     _ctrl.forward();
//     _navigate();
//   }

//   Future<void> _navigate() async {
//     await Future.delayed(const Duration(milliseconds: 2200));
//     if (!mounted) return;
//     final auth    = context.read<AuthProvider>();
//     final hasSession = await auth.checkSession();
//     if (!mounted) return;
//     if (hasSession) {
//       Navigator.pushReplacementNamed(context, '/language');
//     } else {
//       Navigator.pushReplacementNamed(context, '/login');
//     }
//   }

//   @override
//   void dispose() { _ctrl.dispose(); super.dispose(); }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           // ── Background Image
//           Container(
//             decoration: const BoxDecoration(
//               image: DecorationImage(
//                 image: AssetImage('assets/images/onion.png'),
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//           // ── Gradient Overlay (matches lime/green theme)
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Colors.black.withOpacity(0.20),
//                   const Color(0xFF2A4D08).withOpacity(0.72),
//                   const Color(0xFF1A3005).withOpacity(0.90),
//                 ],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 stops: const [0.0, 0.55, 1.0],
//               ),
//             ),
//           ),
//           // ── Decorative circles
//           Positioned(top: -50, right: -50,
//             child: _decorCircle(180, 0.08)),
//           Positioned(bottom: MediaQuery.of(context).size.height * 0.35,
//               left: -40, child: _decorCircle(130, 0.06)),

//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 28),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 20),
//                   // Badge
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.18),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(color: Colors.white.withOpacity(0.3)),
//                     ),
//                     child: const Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.verified_rounded, color: Colors.white70, size: 12),
//                         SizedBox(width: 6),
//                         Text('Trusted by 500+ Mandis',
//                             style: TextStyle(color: Colors.white70, fontSize: 11,
//                                 fontWeight: FontWeight.w500)),
//                       ],
//                     ),
//                   ),
//                   const Spacer(flex: 2),
//                   // Logo
//                   Center(
//                     child: AnimatedBuilder(
//                       animation: _ctrl,
//                       builder: (_, child) => FadeTransition(
//                           opacity: _scaleFade,
//                           child: ScaleTransition(
//                               scale: _scaleFade, child: child)),
//                       child: Column(children: [
//                         Container(
//                           width: 96, height: 96,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient: AppColors.heroGradient,
//                             boxShadow: [BoxShadow(
//                               color: AppColors.primary.withOpacity(0.45),
//                               blurRadius: 30, spreadRadius: 4,
//                             )],
//                           ),
//                           child: const Icon(Icons.storefront_rounded,
//                               size: 48, color: Colors.white),
//                         ),
//                         const SizedBox(height: 18),
//                         const Text('Market ERP', style: TextStyle(
//                           fontSize: 34, fontWeight: FontWeight.w700,
//                           color: Colors.white, letterSpacing: 0.5,
//                           fontFamily: 'Poppins',
//                         )),
//                         const SizedBox(height: 6),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.18),
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: const Text('स्मार्ट मंडी व्यवस्थापन',
//                               style: TextStyle(fontSize: 13, color: Colors.white,
//                                   fontWeight: FontWeight.w500)),
//                         ),
//                       ]),
//                     ),
//                   ),
//                   const Spacer(flex: 3),
//                   // Bottom content
//                   AnimatedBuilder(
//                     animation: _ctrl,
//                     builder: (_, child) => FadeTransition(
//                         opacity: _textFade,
//                         child: SlideTransition(position: _textSlide, child: child)),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Wrap(spacing: 8, runSpacing: 8, children: [
//                           _pill(Icons.agriculture_rounded, 'Procurement'),
//                           _pill(Icons.people_rounded, 'Farmers'),
//                           _pill(Icons.inventory_2_rounded, 'Inventory'),
//                           _pill(Icons.receipt_long_rounded, 'Payments'),
//                         ]),
//                         const SizedBox(height: 18),
//                         const Text(
//                           'Manage procurement, payments &\nfarm operations — all in one place.',
//                           style: TextStyle(color: Colors.white70, fontSize: 14,
//                               height: 1.6, fontFamily: 'Poppins'),
//                         ),
//                         const SizedBox(height: 28),
//                         // Loading indicator
//                         Center(child: SizedBox(
//                           width: 24, height: 24,
//                           child: CircularProgressIndicator(
//                             color: AppColors.primaryLight,
//                             strokeWidth: 2,
//                           ),
//                         )),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 36),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _decorCircle(double size, double opacity) => Container(
//     width: size, height: size,
//     decoration: BoxDecoration(
//       shape: BoxShape.circle,
//       color: AppColors.primary.withOpacity(opacity),
//     ),
//   );

//   Widget _pill(IconData icon, String label) => Container(
//     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//     decoration: BoxDecoration(
//       color: Colors.white.withOpacity(0.12),
//       borderRadius: BorderRadius.circular(20),
//       border: Border.all(color: Colors.white.withOpacity(0.2)),
//     ),
//     child: Row(mainAxisSize: MainAxisSize.min, children: [
//       Icon(icon, color: AppColors.primaryLight, size: 13),
//       const SizedBox(width: 5),
//       Text(label, style: const TextStyle(color: Colors.white, fontSize: 11,
//           fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
//     ]),
//   );
// }