
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/language_provider.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});
  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selected;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    final lang = context.read<LanguageProvider>();
    _selected  = lang.locale.languageCode;

    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  void _confirm() {
    if (_selected == null) return;
    context.read<LanguageProvider>().setLanguage(_selected!);
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: size.height * 0.42,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(44),
                  bottomRight: Radius.circular(44),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ── Header area
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(children: [
                      // Skip row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: _confirm,
                            child: const Text('Skip',
                                style: TextStyle(color: Colors.white70, fontSize: 14,
                                    fontFamily: 'Poppins')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Icon
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.translate_rounded,
                            color: Colors.white, size: 38),
                      ),
                      const SizedBox(height: 16),
                      const Text('Choose Your Language',
                          style: TextStyle(color: Colors.white, fontSize: 24,
                              fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      const Text(
                        'Select the language you are most comfortable with',
                        style: TextStyle(color: Colors.white70, fontSize: 14,
                            fontFamily: 'Poppins', height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),
                    ]),
                  ),

                  // ── Language Cards
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: LanguageProvider.supportedLanguages.map((lang) =>
                            _LanguageTile(
                              language:   lang,
                              isSelected: _selected == lang.code,
                              onTap: () => setState(() => _selected = lang.code),
                            ),
                          ).toList(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Continue Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedOpacity(
                      opacity: _selected != null ? 1.0 : 0.45,
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        width: double.infinity, height: 54,
                        child: ElevatedButton(
                          onPressed: _selected != null ? _confirm : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Continue', style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('You can change this anytime in Profile → Settings',
                      style: TextStyle(color: AppColors.textHint, fontSize: 12,
                          fontFamily: 'Poppins'),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Language Tile ─────────────────────────────────────────────
class _LanguageTile extends StatelessWidget {
  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;
  const _LanguageTile({required this.language,
      required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(
            color: AppColors.primary.withOpacity(0.15),
            blurRadius: 14, offset: const Offset(0, 4),
          )] : [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          )],
        ),
        child: Row(children: [
          // Flag
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.12) : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(language.flag,
                style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 16),
          // Names
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(language.nativeName, style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              )),
              const SizedBox(height: 2),
              Text(language.name, style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Poppins',
              )),
            ],
          )),
          // Radio
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                : null,
          ),
        ]),
      ),
    );
  }
}