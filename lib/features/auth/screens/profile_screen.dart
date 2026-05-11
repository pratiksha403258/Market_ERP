// profile_screen.dart
import 'package:agr_market/core/constants/colors.dart';
import 'package:agr_market/services/constant_service.dart';
import 'package:flutter/material.dart';
import 'package:agr_market/services/auth_service.dart';
import 'package:agr_market/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel _user;
  bool _isEditing = false;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _businessNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _gstController;
  late TextEditingController _panController;
  late TextEditingController _bankAccountController;
  late TextEditingController _ifscController;
  late TextEditingController _bankNameController;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: _user.name);
    _phoneController = TextEditingController(text: _user.phone ?? '');
    _businessNameController = TextEditingController(text: _user.businessName ?? '');
    _addressController = TextEditingController(text: _user.address ?? '');
    _cityController = TextEditingController(text: _user.city ?? '');
    _stateController = TextEditingController(text: _user.state ?? '');
    _gstController = TextEditingController(text: _user.gstNumber ?? '');
    _panController = TextEditingController(text: _user.panNumber ?? '');
    _bankAccountController = TextEditingController(text: _user.bankAccountNumber ?? '');
    _ifscController = TextEditingController(text: _user.ifscCode ?? '');
    _bankNameController = TextEditingController(text: _user.bankName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _gstController.dispose();
    _panController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'businessName': _businessNameController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'gstNumber': _gstController.text.trim(),
      'panNumber': _panController.text.trim(),
      'bankAccountNumber': _bankAccountController.text.trim(),
      'ifscCode': _ifscController.text.trim(),
      'bankName': _bankNameController.text.trim(),
    };

    final result = await AuthService.instance.updateProfile(data);

    setState(() => _isLoading = false);

    if (result.isSuccess && result.user != null) {
      setState(() {
        _user = result.user!;
        _isEditing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Update failed')),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await AuthService.instance.logout();
      
      if (mounted) {
        // Navigate to login and clear all routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppConstants.routeLogin,
          (route) => false,
        );
      }
    }
  }

  Future<void> _refreshProfile() async {
    setState(() => _isLoading = true);
    
    final updatedUser = await AuthService.instance.refreshUserProfile();
    
    setState(() => _isLoading = false);
    
    if (updatedUser != null) {
      setState(() => _user = updatedUser);
      _initControllers(); // Refresh controllers with new data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile refreshed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshProfile,
              tooltip: 'Refresh',
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
          if (_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _initControllers(); // Reset to original values
                });
              },
              child: const Text('Cancel'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: _isLoading && !_isEditing
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Profile Header
                      _buildProfileHeader(),
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Personal Info Section
                      _buildSectionHeader('Personal Information'),
                      const SizedBox(height: AppSpacing.md),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person,
                        enabled: _isEditing,
                        validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        icon: Icons.phone,
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                      ),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Business Info Section
                      if (_user.role == 'superadmin') ...[
                        _buildSectionHeader('Business Information'),
                        const SizedBox(height: AppSpacing.md),
                        _buildTextField(
                          controller: _businessNameController,
                          label: 'Business Name',
                          icon: Icons.business,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Address',
                          icon: Icons.location_on,
                          enabled: _isEditing,
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _cityController,
                                label: 'City',
                                icon: Icons.location_city,
                                enabled: _isEditing,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _buildTextField(
                                controller: _stateController,
                                label: 'State',
                                icon: Icons.map,
                                enabled: _isEditing,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Tax & Banking Section
                        _buildSectionHeader('Tax & Banking Details'),
                        const SizedBox(height: AppSpacing.md),
                        _buildTextField(
                          controller: _gstController,
                          label: 'GST Number',
                          icon: Icons.receipt,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildTextField(
                          controller: _panController,
                          label: 'PAN Number',
                          icon: Icons.assignment_ind,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildTextField(
                          controller: _bankNameController,
                          label: 'Bank Name',
                          icon: Icons.account_balance,
                          enabled: _isEditing,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildTextField(
                          controller: _bankAccountController,
                          label: 'Bank Account Number',
                          icon: Icons.credit_card,
                          enabled: _isEditing,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildTextField(
                          controller: _ifscController,
                          label: 'IFSC Code',
                          icon: Icons.code,
                          enabled: _isEditing,
                        ),
                      ],
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // Account Info Section
                      _buildSectionHeader('Account Information'),
                      const SizedBox(height: AppSpacing.md),
                      _buildInfoTile(Icons.email, 'Email', _user.email),
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoTile(Icons.badge, 'Role', _user.displayRole),
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoTile(
                        Icons.toggle_on,
                        'Status',
                        _user.isActive ? 'Active' : 'Inactive',
                        color: _user.isActive ? AppColors.success : AppColors.error,
                      ),
                      if (_user.lastLoginAt != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _buildInfoTile(
                          Icons.history,
                          'Last Login',
                          _formatDate(_user.lastLoginAt!),
                        ),
                      ],
                      
                      const SizedBox(height: AppSpacing.xxl),
                      
                      // Action Buttons
                      if (_isEditing)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Save Changes'),
                          ),
                        ),
                      
                      const SizedBox(height: AppSpacing.md),
                      
                      // Logout Button
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: Center(
            child: Text(
              _user.initials,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _user.name,
          style: AppTextStyles.headingLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: AppRadius.radiusSM,
          ),
          child: Text(
            _user.displayRole,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.headingMedium,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodyMedium,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: enabled ? AppColors.surface : AppColors.surfaceVariant,
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.radiusSM,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelSmall),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.bodyMedium.copyWith(color: color ?? AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}