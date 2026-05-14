// import 'package:agr_market/models/buyer_model.dart';
// import 'package:agr_market/services/buyer_service.dart';
// import 'package:flutter/material.dart';

// class AddEditBuyerScreen extends StatefulWidget {
//   final Buyer? buyer;

//   const AddEditBuyerScreen({super.key, this.buyer});

//   @override
//   State<AddEditBuyerScreen> createState() => _AddEditBuyerScreenState();
// }

// class _AddEditBuyerScreenState extends State<AddEditBuyerScreen> {
//   final _formKey = GlobalKey<FormState>();
//   // Use singleton instance instead of constructor
//   final BuyerService _buyerService = BuyerService.instance;
//   bool _loading = false;

//   // Form controllers
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _mobileController = TextEditingController();
//   final _alternateMobileController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _cityController = TextEditingController();
//   final _stateController = TextEditingController();
//   final _pincodeController = TextEditingController();
//   final _gstController = TextEditingController();
//   final _panController = TextEditingController();
//   final _businessNameController = TextEditingController();
//   final _creditLimitController = TextEditingController();
//   final _creditDaysController = TextEditingController();
//   final _notesController = TextEditingController();

//   String _businessType = 'individual';
//   String _defaultPaymentMode = 'cash';

//   final List<String> _businessTypes = ['individual', 'company', 'partnership'];
//   final List<String> _paymentModes = ['cash', 'bank_transfer', 'cheque', 'upi'];

//   @override
//   void initState() {
//     super.initState();
//     if (widget.buyer != null) {
//       _populateForm();
//     }
//   }

//   void _populateForm() {
//     final buyer = widget.buyer!;
//     _nameController.text = buyer.name;
//     _emailController.text = buyer.email;
//     _mobileController.text = buyer.mobile;
//     _alternateMobileController.text = buyer.alternateMobile ?? '';
//     _addressController.text = buyer.address;
//     _cityController.text = buyer.city;
//     _stateController.text = buyer.state;
//     _pincodeController.text = buyer.pincode;
//     _gstController.text = buyer.gstNumber ?? '';
//     _panController.text = buyer.panNumber ?? '';
//     _businessNameController.text = buyer.businessName;
//     _creditLimitController.text = buyer.creditLimit.toString();
//     _creditDaysController.text = buyer.creditDays.toString();
//     _notesController.text = buyer.notes ?? '';
//     _businessType = buyer.businessType;
//     _defaultPaymentMode = buyer.defaultPaymentMode;
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _mobileController.dispose();
//     _alternateMobileController.dispose();
//     _addressController.dispose();
//     _cityController.dispose();
//     _stateController.dispose();
//     _pincodeController.dispose();
//     _gstController.dispose();
//     _panController.dispose();
//     _businessNameController.dispose();
//     _creditLimitController.dispose();
//     _creditDaysController.dispose();
//     _notesController.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _loading = true);

//     try {
//       final String alternateMobile = _alternateMobileController.text.trim();
//       final String gstNumber = _gstController.text.trim();
//       final String panNumber = _panController.text.trim();
//       final String notes = _notesController.text.trim();

//       final Map<String, dynamic> buyerData = {
//         'name': _nameController.text.trim(),
//         'email': _emailController.text.trim(),
//         'mobile': _mobileController.text.trim(),
//         'alternateMobile': alternateMobile.isEmpty ? null : alternateMobile,
//         'address': _addressController.text.trim(),
//         'city': _cityController.text.trim(),
//         'state': _stateController.text.trim(),
//         'pincode': _pincodeController.text.trim(),
//         'gstNumber': gstNumber.isEmpty ? null : gstNumber,
//         'panNumber': panNumber.isEmpty ? null : panNumber,
//         'businessName': _businessNameController.text.trim(),
//         'businessType': _businessType,
//         'creditLimit': double.parse(_creditLimitController.text.trim()),
//         'creditDays': int.parse(_creditDaysController.text.trim()),
//         'defaultPaymentMode': _defaultPaymentMode,
//         'notes': notes.isEmpty ? null : notes,
//       };

//       BuyerResult result;
      
//       if (widget.buyer != null) {
//         // Update existing buyer
//         result = await _buyerService.updateBuyer(widget.buyer!.id, buyerData);
//       } else {
//         // Create new buyer
//         result = await _buyerService.createBuyer(buyerData);
//       }

//       if (result.isSuccess && mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(widget.buyer != null ? 'Buyer updated successfully' : 'Buyer created successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//         Navigator.pop(context, true);
//       } else if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(result.message ?? 'Operation failed'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(widget.buyer != null ? 'Failed to update buyer' : 'Failed to create buyer'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F7FA),
//       appBar: AppBar(
//         title: Text(
//           widget.buyer != null ? 'Edit Buyer' : 'Add New Buyer',
//           style: const TextStyle(fontWeight: FontWeight.w600),
//         ),
//         centerTitle: false,
//       ),
//       body: Stack(
//         children: [
//           Form(
//             key: _formKey,
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   _buildSection('Personal Information', [
//                     _buildTextField(
//                       controller: _nameController,
//                       label: 'Full Name',
//                       icon: Icons.person,
//                       validator: (v) =>
//                           v?.isEmpty == true ? 'Name is required' : null,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildTextField(
//                       controller: _emailController,
//                       label: 'Email Address',
//                       icon: Icons.email,
//                       keyboardType: TextInputType.emailAddress,
//                       validator: (v) {
//                         if (v?.isEmpty == true) return 'Email is required';
//                         if (!v!.contains('@')) return 'Invalid email';
//                         return null;
//                       },
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildTextField(
//                             controller: _mobileController,
//                             label: 'Mobile Number',
//                             icon: Icons.phone,
//                             keyboardType: TextInputType.phone,
//                             validator: (v) =>
//                                 v?.isEmpty == true ? 'Mobile is required' : null,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _buildTextField(
//                             controller: _alternateMobileController,
//                             label: 'Alternate Mobile',
//                             icon: Icons.phone_android,
//                             keyboardType: TextInputType.phone,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ]),
//                   const SizedBox(height: 20),
//                   _buildSection('Business Details', [
//                     _buildTextField(
//                       controller: _businessNameController,
//                       label: 'Business Name',
//                       icon: Icons.business,
//                       validator: (v) =>
//                           v?.isEmpty == true ? 'Business name is required' : null,
//                     ),
//                     const SizedBox(height: 12),
//                     _buildDropdown(
//                       label: 'Business Type',
//                       value: _businessType,
//                       items: _businessTypes,
//                       onChanged: (v) => setState(() => _businessType = v!),
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildTextField(
//                             controller: _gstController,
//                             label: 'GST Number',
//                             icon: Icons.receipt,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _buildTextField(
//                             controller: _panController,
//                             label: 'PAN Number',
//                             icon: Icons.credit_card,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ]),
//                   const SizedBox(height: 20),
//                   _buildSection('Address', [
//                     _buildTextField(
//                       controller: _addressController,
//                       label: 'Street Address',
//                       icon: Icons.location_on,
//                       validator: (v) =>
//                           v?.isEmpty == true ? 'Address is required' : null,
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildTextField(
//                             controller: _cityController,
//                             label: 'City',
//                             icon: Icons.location_city,
//                             validator: (v) =>
//                                 v?.isEmpty == true ? 'City is required' : null,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _buildTextField(
//                             controller: _stateController,
//                             label: 'State',
//                             icon: Icons.map,
//                             validator: (v) =>
//                                 v?.isEmpty == true ? 'State is required' : null,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     _buildTextField(
//                       controller: _pincodeController,
//                       label: 'Pincode',
//                       icon: Icons.local_post_office,
//                       keyboardType: TextInputType.number,
//                       validator: (v) =>
//                           v?.isEmpty == true ? 'Pincode is required' : null,
//                     ),
//                   ]),
//                   const SizedBox(height: 20),
//                   _buildSection('Credit Settings', [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: _buildTextField(
//                             controller: _creditLimitController,
//                             label: 'Credit Limit (₹)',
//                             icon: Icons.account_balance_wallet,
//                             keyboardType: TextInputType.number,
//                             validator: (v) {
//                               if (v?.isEmpty == true)
//                                 return 'Credit limit required';
//                               if (double.tryParse(v!) == null)
//                                 return 'Invalid number';
//                               return null;
//                             },
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: _buildTextField(
//                             controller: _creditDaysController,
//                             label: 'Credit Days',
//                             icon: Icons.calendar_today,
//                             keyboardType: TextInputType.number,
//                             validator: (v) {
//                               if (v?.isEmpty == true) return 'Credit days required';
//                               if (int.tryParse(v!) == null) return 'Invalid number';
//                               return null;
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     _buildDropdown(
//                       label: 'Default Payment Mode',
//                       value: _defaultPaymentMode,
//                       items: _paymentModes,
//                       onChanged: (v) => setState(() => _defaultPaymentMode = v!),
//                     ),
//                   ]),
//                   const SizedBox(height: 20),
//                   _buildSection('Additional Notes', [
//                     _buildTextField(
//                       controller: _notesController,
//                       label: 'Notes',
//                       icon: Icons.note,
//                       maxLines: 3,
//                     ),
//                   ]),
//                   const SizedBox(height: 80),
//                 ],
//               ),
//             ),
//           ),
//           if (_loading)
//             Container(
//               color: Colors.black.withOpacity(0.5),
//               child: const Center(
//                 child: CircularProgressIndicator(color: Color(0xFF1B8C4E)),
//               ),
//             ),
//         ],
//       ),
//       bottomNavigationBar: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: ElevatedButton(
//             onPressed: _loading ? null : _submit,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF1B8C4E),
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(vertical: 14),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: Text(
//               widget.buyer != null ? 'Update Buyer' : 'Create Buyer',
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSection(String title, List<Widget> children) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF1F2937),
//               ),
//             ),
//           ),
//           const Divider(height: 1, color: Color(0xFFE5E7EB)),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(children: children),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//     String? Function(String?)? validator,
//     int maxLines = 1,
//   }) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Color(0xFF1B8C4E), width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//       ),
//       keyboardType: keyboardType,
//       validator: validator,
//       maxLines: maxLines,
//     );
//   }

//   Widget _buildDropdown({
//     required String label,
//     required String value,
//     required List<String> items,
//     required void Function(String?) onChanged,
//   }) {
//     return DropdownButtonFormField<String>(
//       value: value,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: const Icon(Icons.category, color: Color(0xFF9CA3AF)),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: const BorderSide(color: Color(0xFF1B8C4E), width: 2),
//         ),
//         filled: true,
//         fillColor: Colors.white,
//       ),
//       items: items.map((item) {
//         return DropdownMenuItem(
//           value: item,
//           child: Text(item.toUpperCase()),
//         );
//       }).toList(),
//       onChanged: onChanged,
//     );
//   }
// }

import 'package:agr_market/models/buyer_model.dart';
import 'package:agr_market/services/buyer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';

class AddEditBuyerScreen extends StatefulWidget {
  final Buyer? buyer;

  const AddEditBuyerScreen({super.key, this.buyer});

  @override
  State<AddEditBuyerScreen> createState() => _AddEditBuyerScreenState();
}

class _AddEditBuyerScreenState extends State<AddEditBuyerScreen>
    with SingleTickerProviderStateMixin {
  // ── Step ──────────────────────────────────────────────────────
  int _step = 0;
  static const _stepLabels = ['Basic', 'Business', 'Address', 'Credit'];

  // ── Step 0: Basic Info ───────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _alternateMobileController = TextEditingController();

  // ── Step 1: Business Details ─────────────────────────────────
  final _businessNameController = TextEditingController();
  String _businessType = 'individual';
  final _gstController = TextEditingController();
  final _panController = TextEditingController();

  // ── Step 2: Address ──────────────────────────────────────────
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  // ── Step 3: Credit Settings ──────────────────────────────────
  final _creditLimitController = TextEditingController();
  final _creditDaysController = TextEditingController();
  String _defaultPaymentMode = 'cash';
  final _notesController = TextEditingController();

  final List<String> _businessTypes = ['individual', 'company', 'partnership'];
  final List<String> _paymentModes = ['cash', 'bank_transfer', 'cheque', 'upi'];

  // ── Misc ──────────────────────────────────────────────────────
  bool _saving = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();

    if (widget.buyer != null) {
      _populateForm();
    }
  }

  void _populateForm() {
    final buyer = widget.buyer!;
    _nameController.text = buyer.name;
    _emailController.text = buyer.email;
    _mobileController.text = buyer.mobile;
    _alternateMobileController.text = buyer.alternateMobile ?? '';
    _addressController.text = buyer.address;
    _cityController.text = buyer.city;
    _stateController.text = buyer.state;
    _pincodeController.text = buyer.pincode;
    _gstController.text = buyer.gstNumber ?? '';
    _panController.text = buyer.panNumber ?? '';
    _businessNameController.text = buyer.businessName;
    _creditLimitController.text = buyer.creditLimit.toString();
    _creditDaysController.text = buyer.creditDays.toString();
    _notesController.text = buyer.notes ?? '';
    _businessType = buyer.businessType;
    _defaultPaymentMode = buyer.defaultPaymentMode;
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _alternateMobileController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _businessNameController.dispose();
    _creditLimitController.dispose();
    _creditDaysController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────────
  void _next() {
    final err = _validateCurrent();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);
    if (_step < 3) {
      _step++;
      _animCtrl.reset();
      _animCtrl.forward();
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() {
        _step--;
        _error = null;
      });
      _animCtrl.reset();
      _animCtrl.forward();
    } else {
      Navigator.pop(context);
    }
  }

  String? _validateCurrent() {
    switch (_step) {
      case 0:
        if (_nameController.text.trim().isEmpty) return 'Please enter buyer name';
        if (_nameController.text.trim().length < 2) {
          return 'Buyer name must be at least 2 characters';
        }
        if (_emailController.text.trim().isEmpty) return 'Please enter email address';
        if (!_emailController.text.contains('@')) return 'Please enter valid email';
        if (_mobileController.text.trim().isEmpty) return 'Please enter mobile number';
        if (_mobileController.text.trim().length != 10) {
          return 'Mobile number must be 10 digits';
        }
        return null;
      case 1:
        if (_businessNameController.text.trim().isEmpty) return 'Please enter business name';
        return null;
      case 2:
        if (_addressController.text.trim().isEmpty) return 'Please enter address';
        if (_cityController.text.trim().isEmpty) return 'Please enter city';
        if (_stateController.text.trim().isEmpty) return 'Please enter state';
        if (_pincodeController.text.trim().isEmpty) return 'Please enter pincode';
        if (_pincodeController.text.trim().length != 6) {
          return 'Pincode must be 6 digits';
        }
        return null;
      case 3:
        if (_creditLimitController.text.trim().isEmpty) return 'Please enter credit limit';
        if (_creditDaysController.text.trim().isEmpty) return 'Please enter credit days';
        return null;
      default:
        return null;
    }
  }

  // ── Submit ────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final String alternateMobile = _alternateMobileController.text.trim();
      final String gstNumber = _gstController.text.trim();
      final String panNumber = _panController.text.trim();
      final String notes = _notesController.text.trim();

      final Map<String, dynamic> buyerData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'alternateMobile': alternateMobile.isEmpty ? null : alternateMobile,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'gstNumber': gstNumber.isEmpty ? null : gstNumber,
        'panNumber': panNumber.isEmpty ? null : panNumber,
        'businessName': _businessNameController.text.trim(),
        'businessType': _businessType,
        'creditLimit': double.parse(_creditLimitController.text.trim()),
        'creditDays': int.parse(_creditDaysController.text.trim()),
        'defaultPaymentMode': _defaultPaymentMode,
        'notes': notes.isEmpty ? null : notes,
      };

      BuyerResult result;

      if (widget.buyer != null) {
        result = await BuyerService.instance.updateBuyer(widget.buyer!.id, buyerData);
      } else {
        result = await BuyerService.instance.createBuyer(buyerData);
      }

      if (!mounted) return;

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Buyer saved successfully!',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ));
        Navigator.pop(context, true);
      } else {
        setState(() => _error = result.message ?? 'Failed to save buyer');
      }
    } catch (e) {
      setState(() => _error = 'Failed to save buyer: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        // Gradient header
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.28,
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
                    Row(children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.buyer != null ? 'Edit Buyer' : 'New Buyer',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildStepIndicator(),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Scrollable body
        Positioned.fill(
          child: SingleChildScrollView(
            child: Column(children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.23),
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

              // Error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                                fontFamily: 'Poppins')),
                      ),
                    ]),
                  ),
                ),

              const SizedBox(height: 20),

              // Continue / Create button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _step < 3 ? 'Continue' : (widget.buyer != null ? 'Update Buyer' : 'Create Buyer'),
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins'),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _step < 3
                                    ? Icons.arrow_forward_rounded
                                    : Icons.person_add_rounded,
                                size: 18),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Step Indicator ────────────────────────────────────────────
  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(_stepLabels.length, (i) {
        final active = i == _step;
        final done = i < _step;
        return Expanded(
          child: Row(children: [
            Expanded(
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                ]),
                const SizedBox(height: 4),
                Text(_stepLabels[i],
                    style: TextStyle(
                        color: active || done
                            ? Colors.white
                            : Colors.white.withOpacity(0.55),
                        fontSize: 9,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500)),
              ]),
            ),
            if (i < _stepLabels.length - 1)
              Container(width: 20, height: 1, color: Colors.white.withOpacity(0.35)),
          ]),
        );
      }),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 0: return _buildStep0BasicInfo();
      case 1: return _buildStep1Business();
      case 2: return _buildStep2Address();
      case 3: return _buildStep3Credit();
      default: return const SizedBox.shrink();
    }
  }

  // ── STEP 0 — Basic Info ───────────────────────────────────────
  Widget _buildStep0BasicInfo() {
    return Column(
      key: const ValueKey('s0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Basic Information', 'Enter personal details'),
        const SizedBox(height: 20),
        _field('Full Name *', _nameController,
            hint: 'e.g. Rajesh Kumar',
            icon: Icons.person_outline_rounded,
            caps: TextCapitalization.words),
        const SizedBox(height: 12),
        _field('Email Address *', _emailController,
            hint: 'buyer@example.com',
            icon: Icons.email_outlined,
            inputType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field('Mobile Number *', _mobileController,
                  hint: '9876543210',
                  icon: Icons.phone_outlined,
                  inputType: TextInputType.phone,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field('Alternate Mobile', _alternateMobileController,
                  hint: 'Optional',
                  icon: Icons.phone_android_outlined,
                  inputType: TextInputType.phone,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10),
            ),
          ],
        ),
      ],
    );
  }

  // ── STEP 1 — Business Details ─────────────────────────────────
  Widget _buildStep1Business() {
    return Column(
      key: const ValueKey('s1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Business Details', 'Enter business information'),
        const SizedBox(height: 20),
        _field('Business Name *', _businessNameController,
            hint: 'e.g. Rajesh Traders',
            icon: Icons.business_outlined,
            caps: TextCapitalization.words),
        const SizedBox(height: 12),
        
        // Business Type Dropdown
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Business Type',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _businessType,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins'),
                items: _businessTypes.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item.toUpperCase()),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _businessType = v!),
              ),
            ),
          ),
        ]),
        
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field('GST Number', _gstController,
                  hint: 'Optional',
                  icon: Icons.receipt_long_outlined,
                  caps: TextCapitalization.characters,
                  maxLength: 15),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field('PAN Number', _panController,
                  hint: 'Optional',
                  icon: Icons.credit_card_outlined,
                  caps: TextCapitalization.characters,
                  maxLength: 10),
            ),
          ],
        ),
      ],
    );
  }

  // ── STEP 2 — Address ──────────────────────────────────────────
  Widget _buildStep2Address() {
    return Column(
      key: const ValueKey('s2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Address Information', 'Enter location details'),
        const SizedBox(height: 20),
        _multiLineField('Street Address *', _addressController,
            hint: 'House/Shop number, street name'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field('City *', _cityController,
                  hint: 'City name',
                  icon: Icons.location_city_outlined,
                  caps: TextCapitalization.words),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field('State *', _stateController,
                  hint: 'State name',
                  icon: Icons.map_outlined,
                  caps: TextCapitalization.words),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field('Pincode *', _pincodeController,
            hint: 'Postal code (6 digits)',
            icon: Icons.local_post_office_outlined,
            inputType: TextInputType.number,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6),
      ],
    );
  }

  // ── STEP 3 — Credit Settings ──────────────────────────────────
  Widget _buildStep3Credit() {
    return Column(
      key: const ValueKey('s3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('Credit Settings', 'Set payment terms'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _field('Credit Limit (₹) *', _creditLimitController,
                  hint: 'e.g. 50000',
                  icon: Icons.account_balance_wallet_outlined,
                  inputType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field('Credit Days *', _creditDaysController,
                  hint: 'e.g. 30',
                  icon: Icons.calendar_today_outlined,
                  inputType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Payment Mode Dropdown
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Default Payment Mode',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _defaultPaymentMode,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins'),
                items: _paymentModes.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(item.toUpperCase().replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _defaultPaymentMode = v!),
              ),
            ),
          ),
        ]),
        
        const SizedBox(height: 12),
        _multiLineField('Additional Notes', _notesController,
            hint: 'Any additional information...'),
      ],
    );
  }

  // ── Shared input widgets ──────────────────────────────────────
  Widget _stepHeader(String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          Text(sub,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'Poppins')),
        ],
      );

  Widget _field(
    String label,
    TextEditingController ctrl, {
    required String hint,
    required IconData icon,
    TextCapitalization caps = TextCapitalization.none,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      TextFormField(
        controller: ctrl,
        keyboardType: inputType,
        textCapitalization: caps,
        inputFormatters: formatters,
        maxLength: maxLength,
        style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
            fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.textHint, size: 18),
          counterText: '',
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
        onChanged: (_) => setState(() {}),
      ),
    ]);
  }

  Widget _multiLineField(String label, TextEditingController ctrl,
      {required String hint}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      TextFormField(
        controller: ctrl,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(
            fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    ]);
  }
}