import 'package:agr_market/buyer/add_edit_buyer_screen.dart';
import 'package:agr_market/buyer/buyer_card.dart';
import 'package:agr_market/buyer/buyer_summary_card.dart';
import 'package:agr_market/models/buyer_model.dart';
import 'package:agr_market/services/buyer_service.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class BuyerListScreen extends StatefulWidget {
  const BuyerListScreen({super.key});

  @override
  State<BuyerListScreen> createState() => _BuyerListScreenState();
}

class _BuyerListScreenState extends State<BuyerListScreen> {
  final BuyerService _buyerService = BuyerService.instance;
  List<Buyer> _buyers = [];
  BuyerSummary? _summary;
  bool _loading = true;
  bool _loadingSummary = true;
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  final ScrollController _scrollController = ScrollController();
  bool _isActiveFilter = true;
  String _sortBy = 'createdAt';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loading && _currentPage < _totalPages) {
        _loadBuyers();
      }
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadBuyers(reset: true),
      _loadSummary(),
    ]);
  }

Future<void> _loadBuyers({bool reset = false}) async {
  if (!reset && _loading) return;
  if (!reset && _currentPage >= _totalPages) return; // ← also prevent over-fetching

  setState(() {
    _loading = true;
    if (reset) {
      _currentPage = 1;
      _buyers = [];
    }
  });

  try {
    final result = await _buyerService.getBuyers(
      page: _currentPage,
      limit: 20,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
      isActive: _isActiveFilter,
    );

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      setState(() {
        if (reset) {
          _buyers = result.data!.buyers;
        } else {
          _buyers.addAll(result.data!.buyers);
        }
        _totalPages = result.data!.pages;
        _currentPage++; // ← increment here, not missing from your original
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to load buyers')),
        );
      }
    }
  } catch (e) {
    if (mounted) setState(() => _loading = false); // ← was missing mounted check
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load buyers')),
      );
    }
  }
}

Future<void> _loadSummary() async {
  if (!mounted) return; // ← add this
  setState(() => _loadingSummary = true);
  try {
    final result = await _buyerService.getBuyerSummary();
    if (!mounted) return; // ← add this
    if (result.isSuccess && result.data != null) {
      setState(() {
        _summary = result.data;
        _loadingSummary = false;
      });
    } else {
      setState(() => _loadingSummary = false);
    }
  } catch (e) {
    if (mounted) setState(() => _loadingSummary = false); // ← was missing mounted check
  }
}

  void _onSearchChanged(String value) {
    _searchQuery = value;
    _loadBuyers(reset: true);
  }

  void _toggleActiveFilter() {
    setState(() {
      _isActiveFilter = !_isActiveFilter;
    });
    _loadBuyers(reset: true);
  }

  Future<void> _deleteBuyer(Buyer buyer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Buyer'),
        content: Text('Are you sure you want to delete ${buyer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final result = await _buyerService.deleteBuyer(buyer.id);
        if (result.isSuccess) {
          _loadBuyers(reset: true);
          _loadSummary();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Buyer deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.message ?? 'Failed to delete buyer')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete buyer')),
          );
        }
      }
    }
  }

  void _editBuyer(Buyer buyer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditBuyerScreen(buyer: buyer),
      ),
    );
    if (result == true) {
      _loadBuyers(reset: true);
      _loadSummary();
    }
  }

  void _addBuyer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddEditBuyerScreen(),
      ),
    );
    if (result == true) {
      _loadBuyers(reset: true);
      _loadSummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Buyers',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: _isActiveFilter ? AppColors.primary : AppColors.textHint),
            onPressed: _toggleActiveFilter,
            tooltip: _isActiveFilter ? 'Showing Active' : 'Showing Inactive',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by name, mobile, business or email...',
                prefixIcon: Icon(Icons.search, color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.textHint),
                        onPressed: () {
                          _searchQuery = '';
                          _loadBuyers(reset: true);
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Summary Section
          if (_summary != null || _loadingSummary)
            BuyerSummaryCard(
              summary: _summary,
              loading: _loadingSummary,
            ),
          // Buyer List
          Expanded(
            child: _buildBuyerList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBuyer,
        icon: const Icon(Icons.add),
        label: const Text('Add Buyer'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildBuyerList() {
    if (_loading && _buyers.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_buyers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No buyers found'
                  : 'No buyers match your search',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  _searchQuery = '';
                  _loadBuyers(reset: true);
                },
                child: const Text('Clear Search'),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadData(),
      color: AppColors.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _buyers.length + (_loading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _buyers.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          }
          final buyer = _buyers[index];
          return BuyerCard(
            buyer: buyer,
            onEdit: () => _editBuyer(buyer),
            onDelete: () => _deleteBuyer(buyer),
          );
        },
      ),
    );
  }
}