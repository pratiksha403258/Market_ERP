import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Controllers for Step 1 - Basic Info
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  // Controllers for Step 2 - Business Info
  final _businessNameCtrl = TextEditingController();
  final _gstNumberCtrl = TextEditingController();
  final _panNumberCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  // Controllers for Step 3 - Banking Details
  final _bankAccountCtrl = TextEditingController();
  final _ifscCodeCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;

  static const _stepLabels = ['Basic Info', 'Business', 'Banking', 'Summary'];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _businessNameCtrl.dispose();
    _gstNumberCtrl.dispose();
    _panNumberCtrl.dispose();
    _addressCtrl.dispose();
    _bankAccountCtrl.dispose();
    _ifscCodeCtrl.dispose();
    _bankNameCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        setState(() {
          _animCtrl.reset();
          _animCtrl.forward();
          _currentStep++;
        });
      }
    } else {
      _handleRegister();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _animCtrl.reset();
        _animCtrl.forward();
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _validateStep1();
      case 1:
        return true; // Business info is optional
      case 2:
        return true; // Banking info is optional
      default:
        return true;
    }
  }

  bool _validateStep1() {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Please enter your name');
      return false;
    }
    if (_emailCtrl.text.trim().isEmpty) {
      _showError('Please enter your email');
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(_emailCtrl.text.trim())) {
      _showError('Enter a valid email address');
      return false;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      _showError('Please enter your phone number');
      return false;
    }
    if (_phoneCtrl.text.trim().length < 10) {
      _showError('Enter a valid phone number');
      return false;
    }
    if (_passwordCtrl.text.isEmpty) {
      _showError('Please enter a password');
      return false;
    }
    if (_passwordCtrl.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return false;
    }
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      _showError('Passwords do not match');
      return false;
    }
    return true;
  }

  Future<void> _handleRegister() async {
    final auth = context.read<AuthProvider>();

    final success = await auth.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(),
      businessName: _businessNameCtrl.text.trim(),
      address: _addressCtrl.text.trim().isNotEmpty ? _addressCtrl.text.trim() : null,
      city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
      state: _stateCtrl.text.trim().isNotEmpty ? _stateCtrl.text.trim() : null,
      gstNumber: _gstNumberCtrl.text.trim().isNotEmpty ? _gstNumberCtrl.text.trim() : null,
      panNumber: _panNumberCtrl.text.trim().isNotEmpty ? _panNumberCtrl.text.trim() : null,
      bankAccountNumber: _bankAccountCtrl.text.trim().isNotEmpty ? _bankAccountCtrl.text.trim() : null,
      ifscCode: _ifscCodeCtrl.text.trim().isNotEmpty ? _ifscCodeCtrl.text.trim() : null,
      bankName: _bankNameCtrl.text.trim().isNotEmpty ? _bankNameCtrl.text.trim() : null,
    );

    if (!mounted) return;

    if (success) {
      _showSuccess('Registration successful!');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/language');
      }
    } else {
      _showError(auth.error ?? 'Registration failed');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13,
            fontFamily: 'Poppins'))),
      ]),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13,
            fontFamily: 'Poppins'))),
      ]),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header section
          Container(
            height: size.height * 0.30,
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back + title row
                    Row(children: [
                      GestureDetector(
                        onTap: _previousStep,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text('Create Account',
                          style: TextStyle(
                              color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins')),
                    ]),
                    const SizedBox(height: 16),
                    // Step indicator
                    _buildStepIndicator(),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable form section
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(
                          color: AppColors.primary.withOpacity(0.10),
                          blurRadius: 30,
                          offset: const Offset(0, 8),
                        )],
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: _buildCurrentStep(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Action button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentStep < 3 ? 'Continue' : 'Register',
                              style: const TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins'),
                            ),
                            const SizedBox(width: 8),
                            Icon(_currentStep < 3
                                ? Icons.arrow_forward_rounded
                                : Icons.check_rounded,
                                size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Login link
                  if (_currentStep == 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontFamily: 'Poppins'),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                fontFamily: 'Poppins'),
                          ),
                        ),
                      ],
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

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_stepLabels.length, (i) {
        final active = i == _currentStep;
        final done = i < _currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: active ? 24 : 20,
                          height: active ? 24 : 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: done || active
                                ? Colors.white
                                : Colors.white.withOpacity(0.35),
                          ),
                          child: Center(
                            child: done
                                ? const Icon(Icons.check_rounded,
                                color: AppColors.primary, size: 13)
                                : Text('${i + 1}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    color: active
                                        ? AppColors.primary
                                        : Colors.white.withOpacity(0.6))),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepLabels[i],
                      style: TextStyle(
                          color: active || done
                              ? Colors.white
                              : Colors.white.withOpacity(0.55),
                          fontSize: 9,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (i < _stepLabels.length - 1)
                Container(
                  width: 20, height: 1,
                  color: Colors.white.withOpacity(0.35),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1BasicInfo();
      case 1:
        return _buildStep2BusinessInfo();
      case 2:
        return _buildStep3BankingDetails();
      case 3:
        return _buildStep4Summary();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Basic Information
  Widget _buildStep1BasicInfo() {
    return Column(
      key: const ValueKey('s0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Basic Information', 'Required fields to create your account'),
        const SizedBox(height: 20),
        _inputField(
          ctrl: _nameCtrl,
          label: 'Full Name *',
          hint: 'Enter your full name',
          icon: Icons.person_outline,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        _inputField(
          ctrl: _emailCtrl,
          label: 'Email Address *',
          hint: 'you@example.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _inputField(
          ctrl: _phoneCtrl,
          label: 'Phone Number *',
          hint: '+91 98765 43210',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        _passwordField(
          ctrl: _passwordCtrl,
          label: 'Password *',
          hint: '••••••••',
          obscure: _obscurePassword,
          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        const SizedBox(height: 14),
        _passwordField(
          ctrl: _confirmPasswordCtrl,
          label: 'Confirm Password *',
          hint: '••••••••',
          obscure: _obscureConfirmPassword,
          onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
      ],
    );
  }

  // STEP 2: Business Information
  Widget _buildStep2BusinessInfo() {
    return Column(
      key: const ValueKey('s1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Business Information', 'Optional - Add your business details'),
        const SizedBox(height: 20),
        _inputField(
          ctrl: _businessNameCtrl,
          label: 'Business / Farm Name',
          hint: 'e.g. Green Valley Farms',
          icon: Icons.store_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        _inputField(
          ctrl: _gstNumberCtrl,
          label: 'GST Number',
          hint: '27AAAAA0000A1Z',
          icon: Icons.assignment_outlined,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 14),
        _inputField(
          ctrl: _panNumberCtrl,
          label: 'PAN Number',
          hint: 'ABCDE1234F',
          icon: Icons.credit_card_outlined,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 14),
        _inputField(
          ctrl: _addressCtrl,
          label: 'Address',
          hint: 'Enter your complete address',
          icon: Icons.location_on_outlined,
          maxLines: 2,
        ),
      ],
    );
  }

  // STEP 3: Banking Details
  Widget _buildStep3BankingDetails() {
    return Column(
      key: const ValueKey('s2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Banking Details', 'Optional - Add your bank account info'),
        const SizedBox(height: 20),
        _inputField(
          ctrl: _bankAccountCtrl,
          label: 'Bank Account Number',
          hint: '12345678901234',
          icon: Icons.account_balance_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 14),
        _inputField(
          ctrl: _ifscCodeCtrl,
          label: 'IFSC Code',
          hint: 'SBIN0001234',
          icon: Icons.code_outlined,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 14),
        _inputField(
          ctrl: _bankNameCtrl,
          label: 'Bank Name',
          hint: 'State Bank of India',
          icon: Icons.account_balance_wallet_outlined,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _inputField(
                ctrl: _cityCtrl,
                label: 'City',
                hint: 'Mumbai',
                icon: Icons.location_city_outlined,
                textCapitalization: TextCapitalization.words,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _inputField(
                ctrl: _stateCtrl,
                label: 'State',
                hint: 'Maharashtra',
                icon: Icons.map_outlined,
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 4: Summary
  Widget _buildStep4Summary() {
    final hasBusiness = _businessNameCtrl.text.trim().isNotEmpty ||
        _gstNumberCtrl.text.trim().isNotEmpty ||
        _panNumberCtrl.text.trim().isNotEmpty ||
        _addressCtrl.text.trim().isNotEmpty;

    final hasBanking = _bankAccountCtrl.text.trim().isNotEmpty ||
        _ifscCodeCtrl.text.trim().isNotEmpty ||
        _bankNameCtrl.text.trim().isNotEmpty ||
        _cityCtrl.text.trim().isNotEmpty ||
        _stateCtrl.text.trim().isNotEmpty;

    return Column(
      key: const ValueKey('s3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Review Details', 'Please confirm your information'),
        const SizedBox(height: 20),

        // Basic Info Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Basic Information',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, fontFamily: 'Poppins')),
              const SizedBox(height: 8),
              _summaryRow('Name', _nameCtrl.text.trim()),
              _summaryRow('Email', _emailCtrl.text.trim()),
              _summaryRow('Phone', _phoneCtrl.text.trim()),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Business Info Section (if any)
        if (hasBusiness) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Business Information',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, fontFamily: 'Poppins')),
                const SizedBox(height: 8),
                if (_businessNameCtrl.text.trim().isNotEmpty)
                  _summaryRow('Business Name', _businessNameCtrl.text.trim()),
                if (_gstNumberCtrl.text.trim().isNotEmpty)
                  _summaryRow('GST Number', _gstNumberCtrl.text.trim().toUpperCase()),
                if (_panNumberCtrl.text.trim().isNotEmpty)
                  _summaryRow('PAN Number', _panNumberCtrl.text.trim().toUpperCase()),
                if (_addressCtrl.text.trim().isNotEmpty)
                  _summaryRow('Address', _addressCtrl.text.trim()),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Banking Info Section (if any)
        if (hasBanking) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Banking Details',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary, fontFamily: 'Poppins')),
                const SizedBox(height: 8),
                if (_bankAccountCtrl.text.trim().isNotEmpty)
                  _summaryRow('Account Number', _bankAccountCtrl.text.trim()),
                if (_ifscCodeCtrl.text.trim().isNotEmpty)
                  _summaryRow('IFSC Code', _ifscCodeCtrl.text.trim().toUpperCase()),
                if (_bankNameCtrl.text.trim().isNotEmpty)
                  _summaryRow('Bank Name', _bankNameCtrl.text.trim()),
                if (_cityCtrl.text.trim().isNotEmpty)
                  _summaryRow('City', _cityCtrl.text.trim()),
                if (_stateCtrl.text.trim().isNotEmpty)
                  _summaryRow('State', _stateCtrl.text.trim()),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Note about optional fields
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.warning, size: 16),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You can add more details later from your profile settings.',
                  style: TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepHeader(String title, String sub) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      Text(sub,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary,
              fontFamily: 'Poppins')),
    ],
  );

  Widget _inputField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary,
              fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.textHint, size: 18),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _passwordField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary,
              fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textHint, size: 18),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.textHint, size: 18,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
                    fontFamily: 'Poppins')),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}