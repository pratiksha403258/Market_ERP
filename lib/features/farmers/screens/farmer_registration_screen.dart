// import 'package:agr_market/services/constant_service.dart';
// import 'package:agr_market/services/dio_client.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import '../../../core/constants/colors.dart';
// import '../../../providers/language_provider.dart';

// class FarmerRegistrationScreen extends StatefulWidget {
//   const FarmerRegistrationScreen({super.key});

//   @override
//   State<FarmerRegistrationScreen> createState() =>
//       _FarmerRegistrationScreenState();
// }

// class _FarmerRegistrationScreenState extends State<FarmerRegistrationScreen>
//     with SingleTickerProviderStateMixin {
//   final _formKey = GlobalKey<FormState>();

//   // Controllers — map to farmers table columns
//   final _nameCtrl    = TextEditingController();
//   final _mobileCtrl  = TextEditingController();
//   final _addressCtrl = TextEditingController();
//   final _villageCtrl = TextEditingController();
//   final _cityCtrl    = TextEditingController();
//   final _bankAccCtrl = TextEditingController();
//   final _ifscCtrl    = TextEditingController();
//   final _bankNameCtrl= TextEditingController();
//   final _gstCtrl     = TextEditingController();

//   bool _isSaving = false;
//   int  _currentStep = 0; // 0 = Basic, 1 = Address, 2 = Banking

//   late AnimationController _animController;
//   late Animation<double>   _fadeAnim;

//   @override
//   void initState() {
//     super.initState();
//     _animController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
//     _animController.forward();
//   }

//   @override
//   void dispose() {
//     _animController.dispose();
//     _nameCtrl.dispose();    _mobileCtrl.dispose();
//     _addressCtrl.dispose(); _villageCtrl.dispose();
//     _cityCtrl.dispose();    _bankAccCtrl.dispose();
//     _ifscCtrl.dispose();    _bankNameCtrl.dispose();
//     _gstCtrl.dispose();
//     super.dispose();
//   }

// // ── Save farmer with API ───────────────────────────
// Future<void> _saveFarmer() async {
//   if (!_formKey.currentState!.validate()) return;
//   FocusScope.of(context).unfocus();
//   setState(() => _isSaving = true);

//   final lang = context.read<LanguageProvider>();

//   try {
//     // Prepare farmer data (matching backend schema)
//     final farmerData = {
//       'name': _nameCtrl.text.trim(),
//       'mobile': _mobileCtrl.text.trim(),
//       if (_addressCtrl.text.trim().isNotEmpty) 
//         'address': _addressCtrl.text.trim(),
//       if (_villageCtrl.text.trim().isNotEmpty) 
//         'village': _villageCtrl.text.trim(),
//       if (_cityCtrl.text.trim().isNotEmpty) 
//         'city': _cityCtrl.text.trim(),
//       if (_bankAccCtrl.text.trim().isNotEmpty) 
//         'bankAccountNumber': _bankAccCtrl.text.trim(),
//       if (_ifscCtrl.text.trim().isNotEmpty) 
//         'ifscCode': _ifscCtrl.text.trim().toUpperCase(),
//       if (_bankNameCtrl.text.trim().isNotEmpty) 
//         'bankName': _bankNameCtrl.text.trim(),
//       if (_gstCtrl.text.trim().isNotEmpty) 
//         'gstNumber': _gstCtrl.text.trim().toUpperCase(),
//     };

//     // Make API call
//     final response = await DioClient.instance.dio.post(
//       ApiRoutes.farmers,
//       data: farmerData,
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       if (!mounted) return;
      
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               const Icon(Icons.check_circle_outline,
//                   color: Colors.white, size: 18),
//               const SizedBox(width: 10),
//               Text(lang.t('farmer_saved'),
//                   style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
//             ],
//           ),
//           backgroundColor: AppColors.success,
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.all(16),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//           duration: const Duration(seconds: 2),
//         ),
//       );
      
//       // Return success to refresh list
//       Navigator.pop(context, true);
//     } else {
//       throw Exception('Failed to save farmer');
//     }
//   } catch (e) {
//     if (!mounted) return;
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           '${lang.t('error')}: ${e.toString()}',
//           style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
//         ),
//         backgroundColor: AppColors.error,
//         behavior: SnackBarBehavior.floating,
//         margin: const EdgeInsets.all(16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   } finally {
//     if (mounted) {
//       setState(() => _isSaving = false);
//     }
//   }
// }

//   void _nextStep() {
//     if (_currentStep < 2) {
//       setState(() => _currentStep++);
//     } else {
//       _saveFarmer();
//     }
//   }

//   void _prevStep() {
//     if (_currentStep > 0) {
//       setState(() => _currentStep--);
//     } else {
//       Navigator.pop(context);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final lang = context.watch<LanguageProvider>();
//     final size = MediaQuery.of(context).size;

//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: Stack(
//         children: [
//           // ── Header ──────────────────────────
//           Positioned(
//             top: 0, left: 0, right: 0,
//             child: Container(
//               height: size.height * 0.28,
//               decoration: const BoxDecoration(
//                 gradient: AppColors.primaryGradient,
//                 borderRadius: BorderRadius.only(
//                   bottomLeft:  Radius.circular(40),
//                   bottomRight: Radius.circular(40),
//                 ),
//               ),
//               child: SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 20, vertical: 16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       GestureDetector(
//                         onTap: _prevStep,
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: const Icon(Icons.arrow_back_rounded,
//                               color: Colors.white, size: 20),
//                         ),
//                       ),
//                       const Spacer(),
//                       Text(
//                         lang.t('add_farmer'),
//                         style: const TextStyle(
//                           fontFamily: 'Poppins',
//                           color: Colors.white,
//                           fontSize: 24,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Step ${_currentStep + 1} of 3',
//                         style: const TextStyle(
//                           fontFamily: 'Poppins',
//                           color: Colors.white70,
//                           fontSize: 13,
//                         ),
//                       ),
//                       const SizedBox(height: 14),
//                       _buildStepDots(),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // ── Form ────────────────────────────
//           Positioned.fill(
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   SizedBox(height: size.height * 0.24),

//                   FadeTransition(
//                     opacity: _fadeAnim,
//                     child: Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 20),
//                       padding: const EdgeInsets.all(22),
//                       decoration: BoxDecoration(
//                         color: AppColors.surface,
//                         borderRadius: BorderRadius.circular(24),
//                         boxShadow: [
//                           BoxShadow(
//                             color: AppColors.primary.withOpacity(0.10),
//                             blurRadius: 30,
//                             offset: const Offset(0, 8),
//                           ),
//                         ],
//                       ),
//                       child: Form(
//                         key: _formKey,
//                         child: AnimatedSwitcher(
//                           duration: const Duration(milliseconds: 300),
//                           transitionBuilder: (child, anim) => FadeTransition(
//                             opacity: anim,
//                             child: SlideTransition(
//                               position: Tween<Offset>(
//                                 begin: const Offset(0.06, 0),
//                                 end: Offset.zero,
//                               ).animate(anim),
//                               child: child,
//                             ),
//                           ),
//                           child: _buildCurrentStep(lang),
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 24),

//                   // ── Action button ──────────────────
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: SizedBox(
//                       width: double.infinity,
//                       height: 52,
//                       child: ElevatedButton(
//                         onPressed: _isSaving ? null : _nextStep,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primary,
//                           foregroundColor: Colors.white,
//                           disabledBackgroundColor:
//                               AppColors.primary.withOpacity(0.6),
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                         ),
//                         child: _isSaving
//                             ? const SizedBox(
//                                 width: 22, height: 22,
//                                 child: CircularProgressIndicator(
//                                     color: Colors.white, strokeWidth: 2.5),
//                               )
//                             : Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Text(
//                                     _currentStep < 2
//                                         ? 'Continue'
//                                         : lang.t('save'),
//                                     style: const TextStyle(
//                                       fontFamily: 'Poppins',
//                                       fontSize: 15,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 8),
//                                   Icon(
//                                     _currentStep < 2
//                                         ? Icons.arrow_forward_rounded
//                                         : Icons.check_rounded,
//                                     size: 18,
//                                   ),
//                                 ],
//                               ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 40),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Step dots indicator ───────────────────
//   Widget _buildStepDots() {
//     return Row(
//       children: List.generate(3, (i) {
//         final active = i == _currentStep;
//         final done   = i < _currentStep;
//         return Row(
//           children: [
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               width: active ? 28 : 8,
//               height: 8,
//               decoration: BoxDecoration(
//                 color: active || done
//                     ? Colors.white
//                     : Colors.white.withOpacity(0.35),
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ),
//             if (i < 2) const SizedBox(width: 6),
//           ],
//         );
//       }),
//     );
//   }

//   // ── Route to current step ─────────────────
//   Widget _buildCurrentStep(LanguageProvider lang) {
//     switch (_currentStep) {
//       case 0: return _buildStep0Basic(lang);
//       case 1: return _buildStep1Address(lang);
//       case 2: return _buildStep2Banking(lang);
//       default: return const SizedBox.shrink();
//     }
//   }

//   // ─────────────────────────────────────────
//   // Step 0 — Basic Info
//   // ─────────────────────────────────────────
//   Widget _buildStep0Basic(LanguageProvider lang) {
//     return Column(
//       key: const ValueKey('step0'),
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//       _stepHeader('👨‍🌾  ${lang.t('basic_information')}', lang.t('farmer_name_contact')),
//         const SizedBox(height: 20),

//         _fieldLabel('${lang.t("farmer_name")} *'),
//         const SizedBox(height: 6),
//         _textField(
//           controller: _nameCtrl,
//           hint: 'e.g. Ramesh Patil',
//           icon: Icons.person_outline_rounded,
//           caps: TextCapitalization.words,
//           validator: (v) {
//             if (v == null || v.trim().isEmpty) {
//               return '${lang.t("farmer_name")} ${lang.t("required")}';
//             }
//             if (v.trim().length < 3) return 'Name too short';
//             return null;
//           },
//         ),

//         const SizedBox(height: 14),

//         _fieldLabel('${lang.t("mobile")} *'),
//         const SizedBox(height: 6),
//         TextFormField(
//           controller: _mobileCtrl,
//           keyboardType: TextInputType.phone,
//           maxLength: 10,
//           inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//           style: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
//               color: AppColors.textPrimary),
//           decoration: _decor(
//             hint: '9876543210',
//             icon: Icons.phone_outlined,
//             prefix: _prefix91(),
//             counterText: '',
//           ),
//           validator: (v) {
//             if (v == null || v.isEmpty) {
//               return '${lang.t("mobile")} ${lang.t("required")}';
//             }
//             if (v.length != 10) return 'Enter valid 10-digit number';
//             return null;
//           },
//         ),
//       ],
//     );
//   }

//   // ─────────────────────────────────────────
//   // Step 1 — Address Info
//   // ─────────────────────────────────────────
//   Widget _buildStep1Address(LanguageProvider lang) {
//     return Column(
//       key: const ValueKey('step1'),
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//       _stepHeader('📍  ${lang.t('address_details')}', lang.t('village_city_info')),
//         const SizedBox(height: 20),

//         _fieldLabel(lang.t('village')),
//         const SizedBox(height: 6),
//         _textField(
//           controller: _villageCtrl,
//           hint: 'e.g. Dhamangaon',
//           icon: Icons.location_city_outlined,
//           caps: TextCapitalization.words,
//         ),

//         const SizedBox(height: 14),

//         _fieldLabel(lang.t('city')),
//         const SizedBox(height: 6),
//         _textField(
//           controller: _cityCtrl,
//           hint: 'e.g. Nagpur',
//           icon: Icons.apartment_outlined,
//           caps: TextCapitalization.words,
//         ),

//         const SizedBox(height: 14),

//         _fieldLabel('${lang.t("address")} ${lang.t("optional")}'),
//         const SizedBox(height: 6),
//         TextFormField(
//           controller: _addressCtrl,
//           maxLines: 3,
//           textCapitalization: TextCapitalization.sentences,
//           style: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
//               color: AppColors.textPrimary),
//           decoration: InputDecoration(
//             hintText: 'Full address…',
//             hintStyle: TextStyle(
//                 fontFamily: 'Poppins', color: AppColors.textHint, fontSize: 14),
//             filled: true,
//             fillColor: AppColors.surfaceVariant,
//             contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: const BorderSide(color: AppColors.border)),
//             enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide: const BorderSide(color: AppColors.border)),
//             focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12),
//                 borderSide:
//                     const BorderSide(color: AppColors.primary, width: 1.5)),
//           ),
//         ),
//       ],
//     );
//   }

//   // ─────────────────────────────────────────
//   // Step 2 — Banking Info
//   // ─────────────────────────────────────────
//   Widget _buildStep2Banking(LanguageProvider lang) {
//     return Column(
//       key: const ValueKey('step2'),
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//       _stepHeader('🏦  ${lang.t('banking_details')}', lang.t('banking_optional')),
//         const SizedBox(height: 20),

//         // Info banner
//         Container(
//           padding: const EdgeInsets.all(12),
//           margin: const EdgeInsets.only(bottom: 18),
//           decoration: BoxDecoration(
//             color: AppColors.infoSurface,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: AppColors.info.withOpacity(0.2)),
//           ),
//           child: const Row(
//             children: [
//               Icon(Icons.info_outline, color: AppColors.info, size: 16),
//               SizedBox(width: 10),
//               Expanded(
//                 child: Text(
//                   'All banking fields are optional. You can add them later from the farmer profile.',
//                   style: TextStyle(
//                       fontFamily: 'Poppins',
//                       color: AppColors.info, fontSize: 12),
//                 ),
//               ),
//             ],
//           ),
//         ),

//         _fieldLabel('${lang.t("bank_account")} ${lang.t("optional")}'),
//         const SizedBox(height: 6),
//         _textField(
//           controller: _bankAccCtrl,
//           hint: 'e.g. 012345678901',
//           icon: Icons.account_balance_outlined,
//           inputType: TextInputType.number,
//           inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//         ),

//         const SizedBox(height: 14),

//         _fieldLabel('${lang.t("ifsc")} ${lang.t("optional")}'),
//         const SizedBox(height: 6),
//         _textField(
//           controller: _ifscCtrl,
//           hint: 'e.g. SBIN0001234',
//           icon: Icons.code_outlined,
//           caps: TextCapitalization.characters,
//           maxLength: 11,
//         ),

//         const SizedBox(height: 14),

//         _fieldLabel('${lang.t("bank_name")} ${lang.t("optional")}'),
//         const SizedBox(height: 6),
//         _textField(
//           controller: _bankNameCtrl,
//           hint: 'e.g. State Bank of India',
//           icon: Icons.account_balance_wallet_outlined,
//           caps: TextCapitalization.words,
//         ),

//         const SizedBox(height: 14),

//         _fieldLabel('${lang.t("gst_number")} ${lang.t("optional")}'),
//         const SizedBox(height: 6),
//         _textField(
//           controller: _gstCtrl,
//           hint: 'e.g. 27AAPFU0939F1ZV',
//           icon: Icons.receipt_long_outlined,
//           caps: TextCapitalization.characters,
//           maxLength: 15,
//         ),
//       ],
//     );
//   }

//   // ── Helpers ───────────────────────────────
//   Widget _stepHeader(String title, String sub) => Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Text(title, style: const TextStyle(
//           fontFamily: 'Poppins', fontSize: 17,
//           fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
//       const SizedBox(height: 4),
//       Text(sub, style: const TextStyle(
//           fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
//     ],
//   );

//   Widget _fieldLabel(String label) => Text(label,
//       style: const TextStyle(
//           fontFamily: 'Poppins', fontSize: 13,
//           fontWeight: FontWeight.w600, color: AppColors.textPrimary));

//   Widget _textField({
//     required TextEditingController controller,
//     required String hint,
//     required IconData icon,
//     TextCapitalization caps = TextCapitalization.none,
//     TextInputType inputType = TextInputType.text,
//     List<TextInputFormatter>? inputFormatters,
//     int? maxLength,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       keyboardType: inputType,
//       textCapitalization: caps,
//       inputFormatters: inputFormatters,
//       maxLength: maxLength,
//       style: const TextStyle(
//           fontFamily: 'Poppins', fontSize: 14, color: AppColors.textPrimary),
//       decoration: _decor(hint: hint, icon: icon,
//           counterText: maxLength != null ? '' : null),
//       validator: validator,
//     );
//   }

//   InputDecoration _decor({
//     required String hint,
//     required IconData icon,
//     Widget? prefix,
//     String? counterText,
//   }) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: TextStyle(
//           fontFamily: 'Poppins', color: AppColors.textHint, fontSize: 14),
//       prefixIcon: prefix != null
//           ? Row(mainAxisSize: MainAxisSize.min,
//               children: [const SizedBox(width: 16), prefix])
//           : Icon(icon, color: AppColors.textHint, size: 20),
//       counterText: counterText,
//       filled: true,
//       fillColor: AppColors.surfaceVariant,
//       contentPadding:
//           const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.border)),
//       enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.border)),
//       focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
//       errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.error)),
//       focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
//     );
//   }

//   Widget _prefix91() => Container(
//     padding: const EdgeInsets.only(right: 8),
//     margin: const EdgeInsets.only(right: 4),
//     decoration:
//         const BoxDecoration(border: Border(right: BorderSide(color: AppColors.border))),
//     child: const Text('+91',
//         style: TextStyle(
//             fontFamily: 'Poppins', fontWeight: FontWeight.w600,
//             color: AppColors.textPrimary, fontSize: 14)),
//   );
// }

import 'package:agr_market/services/constant_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/farmer_provider.dart';

class FarmerRegistrationScreen extends StatefulWidget {
  const FarmerRegistrationScreen({super.key});

  @override
  State<FarmerRegistrationScreen> createState() =>
      _FarmerRegistrationScreenState();
}

class _FarmerRegistrationScreenState extends State<FarmerRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers — map to farmers table columns
  final _nameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _bankAccCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();

  int _currentStep = 0; // 0 = Basic, 1 = Address, 2 = Banking

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _villageCtrl.dispose();
    _cityCtrl.dispose();
    _bankAccCtrl.dispose();
    _ifscCtrl.dispose();
    _bankNameCtrl.dispose();
    _gstCtrl.dispose();
    super.dispose();
  }

  // ── Save farmer with Provider ───────────────────────────
  Future<void> _saveFarmer() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final lang = context.read<LanguageProvider>();
    final provider = context.read<FarmerProvider>();

    // Prepare farmer data (matching backend schema)
    final success = await provider.createFarmer(
      name: _nameCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim(),
      village: _villageCtrl.text.trim().isNotEmpty ? _villageCtrl.text.trim() : null,
      city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
      address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
      bankAccountNumber: _bankAccCtrl.text.trim().isNotEmpty ? _bankAccCtrl.text.trim() : null,
      ifscCode: _ifscCtrl.text.trim().isNotEmpty ? _ifscCtrl.text.trim().toUpperCase() : null,
      bankName: _bankNameCtrl.text.trim().isNotEmpty ? _bankNameCtrl.text.trim() : null,
      gstNumber: _gstCtrl.text.trim().isNotEmpty ? _gstCtrl.text.trim().toUpperCase() : null,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                lang.t('farmer_saved'),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${lang.t('error')}: ${provider.error ?? 'Failed to save farmer'}',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _saveFarmer();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final provider = context.watch<FarmerProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Header ──────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.height * 0.28,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: _prevStep,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        lang.t('add_farmer'),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lang.t('step')} ${_currentStep + 1} ${lang.t('of')} 3',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildStepDots(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Form ────────────────────────────
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.24),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.10),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.06, 0),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: _buildCurrentStep(lang),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Action button ──────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: provider.isCreating ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: provider.isCreating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentStep < 2 ? lang.t('continue') : lang.t('save'),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentStep < 2
                                        ? Icons.arrow_forward_rounded
                                        : Icons.check_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Step dots indicator ───────────────────
  Widget _buildStepDots() {
    return Row(
      children: List.generate(3, (i) {
        final active = i == _currentStep;
        final done = i < _currentStep;
        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active || done ? Colors.white : Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (i < 2) const SizedBox(width: 6),
          ],
        );
      }),
    );
  }

  // ── Route to current step ─────────────────
  Widget _buildCurrentStep(LanguageProvider lang) {
    switch (_currentStep) {
      case 0:
        return _buildStep0Basic(lang);
      case 1:
        return _buildStep1Address(lang);
      case 2:
        return _buildStep2Banking(lang);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─────────────────────────────────────────
  // Step 0 — Basic Info
  // ─────────────────────────────────────────
  Widget _buildStep0Basic(LanguageProvider lang) {
    return Column(
      key: const ValueKey('step0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('👨‍🌾  ${lang.t('basic_information')}', lang.t('farmer_name_contact')),
        const SizedBox(height: 20),
        _fieldLabel('${lang.t("farmer_name")} *'),
        const SizedBox(height: 6),
        _textField(
          controller: _nameCtrl,
          hint: 'e.g. Ramesh Patil',
          icon: Icons.person_outline_rounded,
          caps: TextCapitalization.words,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return '${lang.t("farmer_name")} ${lang.t("required")}';
            }
            if (v.trim().length < 3) return lang.t('name_too_short');
            return null;
          },
        ),
        const SizedBox(height: 14),
        _fieldLabel('${lang.t("mobile")} *'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _mobileCtrl,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 14, color: AppColors.textPrimary),
          decoration: _decor(
            hint: '9876543210',
            icon: Icons.phone_outlined,
            prefix: _prefix91(),
            counterText: '',
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return '${lang.t("mobile")} ${lang.t("required")}';
            }
            if (v.length != 10) return lang.t('enter_valid_mobile');
            return null;
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Step 1 — Address Info
  // ─────────────────────────────────────────
  Widget _buildStep1Address(LanguageProvider lang) {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('📍  ${lang.t('address_details')}', lang.t('village_city_info')),
        const SizedBox(height: 20),
        _fieldLabel(lang.t('village')),
        const SizedBox(height: 6),
        _textField(
          controller: _villageCtrl,
          hint: 'e.g. Dhamangaon',
          icon: Icons.location_city_outlined,
          caps: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        _fieldLabel(lang.t('city')),
        const SizedBox(height: 6),
        _textField(
          controller: _cityCtrl,
          hint: 'e.g. Nagpur',
          icon: Icons.apartment_outlined,
          caps: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        _fieldLabel('${lang.t("address")} ${lang.t("optional")}'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _addressCtrl,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Full address…',
            hintStyle: TextStyle(
                fontFamily: 'Poppins', color: AppColors.textHint, fontSize: 14),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Step 2 — Banking Info
  // ─────────────────────────────────────────
  Widget _buildStep2Banking(LanguageProvider lang) {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('🏦  ${lang.t('banking_details')}', lang.t('banking_optional')),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: AppColors.infoSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.info.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.info, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang.t('banking_info_message'),
                  style: const TextStyle(
                      fontFamily: 'Poppins', color: AppColors.info, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        _fieldLabel('${lang.t("bank_account")} ${lang.t("optional")}'),
        const SizedBox(height: 6),
        _textField(
          controller: _bankAccCtrl,
          hint: 'e.g. 012345678901',
          icon: Icons.account_balance_outlined,
          inputType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 14),
        _fieldLabel('${lang.t("ifsc")} ${lang.t("optional")}'),
        const SizedBox(height: 6),
        _textField(
          controller: _ifscCtrl,
          hint: 'e.g. SBIN0001234',
          icon: Icons.code_outlined,
          caps: TextCapitalization.characters,
          maxLength: 11,
        ),
        const SizedBox(height: 14),
        _fieldLabel('${lang.t("bank_name")} ${lang.t("optional")}'),
        const SizedBox(height: 6),
        _textField(
          controller: _bankNameCtrl,
          hint: 'e.g. State Bank of India',
          icon: Icons.account_balance_wallet_outlined,
          caps: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        _fieldLabel('${lang.t("gst_number")} ${lang.t("optional")}'),
        const SizedBox(height: 6),
        _textField(
          controller: _gstCtrl,
          hint: 'e.g. 27AAPFU0939F1ZV',
          icon: Icons.receipt_long_outlined,
          caps: TextCapitalization.characters,
          maxLength: 15,
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────
  Widget _stepHeader(String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      );

  Widget _fieldLabel(String label) => Text(
        label,
        style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextCapitalization caps = TextCapitalization.none,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      textCapitalization: caps,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      style: const TextStyle(
          fontFamily: 'Poppins', fontSize: 14, color: AppColors.textPrimary),
      decoration: _decor(
          hint: hint, icon: icon, counterText: maxLength != null ? '' : null),
      validator: validator,
    );
  }

  InputDecoration _decor({
    required String hint,
    required IconData icon,
    Widget? prefix,
    String? counterText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          fontFamily: 'Poppins', color: AppColors.textHint, fontSize: 14),
      prefixIcon: prefix != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [const SizedBox(width: 16), prefix])
          : Icon(icon, color: AppColors.textHint, size: 20),
      counterText: counterText,
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
    );
  }

  Widget _prefix91() => Container(
        padding: const EdgeInsets.only(right: 8),
        margin: const EdgeInsets.only(right: 4),
        decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppColors.border))),
        child: const Text(
          '+91',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontSize: 14),
        ),
      );
}