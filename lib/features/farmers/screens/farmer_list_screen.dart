import 'package:agr_market/core/constants/colors.dart';
import 'package:agr_market/services/constant_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agr_market/services/dio_client.dart';
import 'package:agr_market/models/farmer_model.dart';
import 'package:agr_market/providers/language_provider.dart';
import 'farmer_registration_screen.dart';

class FarmerListScreen extends StatefulWidget {
  const FarmerListScreen({super.key});

  @override
  State<FarmerListScreen> createState() => _FarmerListScreenState();
}

class _FarmerListScreenState extends State<FarmerListScreen> {
  List<FarmerModel> _farmers = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchFarmers();
  }

  Future<void> _fetchFarmers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await DioClient.instance.dio.get(ApiRoutes.farmers);
      
      if (response.statusCode == 200) {
        // Handle both array response and paginated response
        if (response.data is List) {
          _farmers = (response.data as List)
              .map((json) => FarmerModel.fromJson(json))
              .toList();
        } else if (response.data is Map && response.data['data'] is List) {
          _farmers = (response.data['data'] as List)
              .map((json) => FarmerModel.fromJson(json))
              .toList();
        } else if (response.data is Map && response.data['farmers'] is List) {
          _farmers = (response.data['farmers'] as List)
              .map((json) => FarmerModel.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
      print('Error fetching farmers: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFarmer(String id, String name) async {
    final lang = context.read<LanguageProvider>();
    
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('delete_farmer')),
        content: Text('${lang.t('delete_confirmation')} "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(lang.t('delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DioClient.instance.dio.delete(ApiRoutes.farmerById(id));
      _fetchFarmers(); // Refresh list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lang.t('farmer_deleted')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${lang.t('error')}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(lang.t('farmers_list')),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter
            },
          ),
        ],
      ),
      body: _buildBody(lang),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FarmerRegistrationScreen(),
            ),
          );
          // Refresh list if farmer was added successfully
          if (result == true) {
            _fetchFarmers();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(lang.t('add_farmer')),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody(LanguageProvider lang) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchFarmers,
              child: Text(lang.t('retry')),
            ),
          ],
        ),
      );
    }

    if (_farmers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              lang.t('no_farmers_found'),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FarmerRegistrationScreen(),
                  ),
                );
                if (result == true) _fetchFarmers();
              },
              icon: const Icon(Icons.add),
              label: Text(lang.t('add_first_farmer')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFarmers,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _farmers.length,
        itemBuilder: (context, index) {
          final farmer = _farmers[index];
          return _FarmerCard(
            farmer: farmer,
            onDelete: () => _deleteFarmer(farmer.id, farmer.name),
            onTap: () {
              // TODO: Navigate to farmer details
              print('View farmer: ${farmer.name}');
            },
          );
        },
      ),
    );
  }
}

// Farmer Card Widget
class _FarmerCard extends StatelessWidget {
  final FarmerModel farmer;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _FarmerCard({
    required this.farmer,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Farmer Initials Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        farmer.initials,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmer.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              farmer.mobile,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (farmer.displayLocation != '—') ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(
                                farmer.displayLocation,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: farmer.isActive 
                          ? AppColors.successSurface 
                          : AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      farmer.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: farmer.isActive ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.border.withOpacity(0.5)),
              const SizedBox(height: 8),
              // Financial Summary
              Row(
                children: [
                  _FinancialChip(
                    label: lang.t('total_purchases'),
                    value: '₹${farmer.totalPurchases.toStringAsFixed(2)}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _FinancialChip(
                    label: lang.t('pending_dues'),
                    value: '₹${farmer.pendingDues.toStringAsFixed(2)}',
                    color: farmer.hasPendingDues ? Colors.orange : AppColors.success,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    color: AppColors.error,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FinancialChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}