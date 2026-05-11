import 'package:agr_market/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agr_market/models/farmer_model.dart';
import 'package:agr_market/providers/language_provider.dart';
import 'package:agr_market/providers/farmer_provider.dart';
import 'farmer_registration_screen.dart';
import 'farmer_detail_screen.dart';

class FarmerListScreen extends StatefulWidget {
  const FarmerListScreen({super.key});

  @override
  State<FarmerListScreen> createState() => _FarmerListScreenState();
}

class _FarmerListScreenState extends State<FarmerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FarmerProvider>().loadFarmers();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text);
    _debounceSearch();
  }

  void _debounceSearch() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == _searchController.text) {
        context.read<FarmerProvider>().loadFarmers(search: _searchQuery);
      }
    });
  }

  void _openFarmerDetail(FarmerModel farmer) async {
    final provider = context.read<FarmerProvider>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FarmerDetailScreen(
          farmerId: farmer.id,
          farmerName: farmer.name,
        ),
      ),
    );
    if (result == true) {
      provider.loadFarmers(search: _searchQuery.isNotEmpty ? _searchQuery : null);
    }
  }

  void _deleteFarmer(String id, String name) async {
    final lang = context.read<LanguageProvider>();
    final provider = context.read<FarmerProvider>();

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

    final success = await provider.deleteFarmer(id);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('farmer_deleted')),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final provider = context.watch<FarmerProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
  appBar: AppBar(
  title: _searchQuery.isEmpty
      ? Text(lang.t('farmers_list'))
      : TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: lang.t('search_farmers'),
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            filled: true,
            fillColor: Colors.white, // Solid white background
          ),
          style: const TextStyle(color: Colors.black), // Black text
        ),
  backgroundColor: AppColors.surface,
  elevation: 0,
  centerTitle: false,
  actions: [
    if (_searchQuery.isEmpty)
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          setState(() {
            _searchQuery = ' ';
          });
          Future.delayed(const Duration(milliseconds: 100), () {
            FocusScope.of(context).requestFocus(FocusNode());
          });
        },
      )
    else
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () {
          setState(() {
            _searchController.clear();
            _searchQuery = '';
          });
          provider.loadFarmers();
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
          if (result == true) {
            provider.loadFarmers();
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
    final provider = context.watch<FarmerProvider>();

    if (provider.isLoading && provider.farmers.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (provider.error != null && provider.farmers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(provider.error!,
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => provider.loadFarmers(),
              child: Text(lang.t('retry')),
            ),
          ],
        ),
      );
    }

    if (provider.farmers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? lang.t('no_farmers_found')
                  : lang.t('no_matching_farmers'),
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textSecondary),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                  provider.loadFarmers();
                },
                child: Text(lang.t('clear_search')),
              ),
            ],
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FarmerRegistrationScreen()),
                  );
                  if (result == true) provider.loadFarmers();
                },
                icon: const Icon(Icons.add),
                label: Text(lang.t('add_first_farmer')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final farmers = provider.farmers.where((farmer) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return farmer.name.toLowerCase().contains(query) ||
          farmer.mobile.contains(query) ||
          (farmer.village?.toLowerCase().contains(query) ?? false) ||
          (farmer.city?.toLowerCase().contains(query) ?? false);
    }).toList();

    return RefreshIndicator(
      onRefresh: () => provider.loadFarmers(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (!provider.isLoading &&
              provider.hasMore &&
              scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
            provider.loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: farmers.length + (provider.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == farmers.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary)),
              );
            }
            final farmer = farmers[index];
            return _FarmerCard(
              farmer: farmer,
              onDelete: () => _deleteFarmer(farmer.id, farmer.name),
              onTap: () => _openFarmerDetail(farmer),
            );
          },
        ),
      ),
    );
  }
}

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
              Row(children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(farmer.initials,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(farmer.name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.phone,
                            size: 14, color: AppColors.textHint),
                        const SizedBox(width: 4),
                        Text(farmer.mobile,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ]),
                      if (farmer.displayLocation != '—') ...[
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(Icons.location_on,
                              size: 14, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(farmer.displayLocation,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ]),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
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
                            color: farmer.isActive
                                ? AppColors.success
                                : AppColors.error),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.textHint),
                  ],
                ),
              ]),
              const SizedBox(height: 12),
              Divider(color: AppColors.border.withOpacity(0.5)),
              const SizedBox(height: 8),
              Row(children: [
                _FinancialChip(
                  label: lang.t('total_purchases'),
                  value: '₹${farmer.totalPurchases.toStringAsFixed(2)}',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                _FinancialChip(
                  label: lang.t('pending_dues'),
                  value: '₹${farmer.pendingDues.toStringAsFixed(2)}',
                  color: farmer.hasPendingDues
                      ? Colors.orange
                      : AppColors.success,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  color: AppColors.error,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: color)),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}