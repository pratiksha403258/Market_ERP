import 'package:agr_market/sales/sales_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';
import '../../../providers/language_provider.dart';


// Sales Model
class SaleModel {
  final String id;
  final String invoiceNumber;
  final String buyerName;
  final String buyerMobile;
  final String buyerGst;
  final DateTime saleDate;
  final List<SaleLine> lines;
  final double subTotal;
  final double gstPercent;
  final double gstAmount;
  final double grandTotal;
  final String paymentMode;
  final String referenceNumber;
  final String notes;
  final CreatedBy createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  SaleModel({
    required this.id,
    required this.invoiceNumber,
    required this.buyerName,
    required this.buyerMobile,
    required this.buyerGst,
    required this.saleDate,
    required this.lines,
    required this.subTotal,
    required this.gstPercent,
    required this.gstAmount,
    required this.grandTotal,
    required this.paymentMode,
    required this.referenceNumber,
    required this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['_id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString() ?? '',
      buyerName: json['buyerName']?.toString() ?? '',
      buyerMobile: json['buyerMobile']?.toString() ?? '',
      buyerGst: json['buyerGst']?.toString() ?? '',
      saleDate: DateTime.tryParse(json['saleDate']?.toString() ?? '') ?? DateTime.now(),
      lines: (json['lines'] as List? ?? [])
          .map((e) => SaleLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      subTotal: (json['subTotal'] as num?)?.toDouble() ?? 0,
      gstPercent: (json['gstPercent'] as num?)?.toDouble() ?? 0,
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0,
      paymentMode: json['paymentMode']?.toString() ?? '',
      referenceNumber: json['referenceNumber']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdBy: CreatedBy.fromJson(json['createdBy'] as Map<String, dynamic>? ?? {}),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class SaleLine {
  final String productName;
  final String warehouse;
  final double qty;
  final String unit;
  final double sellingPrice;
  final double lineTotal;

  SaleLine({
    required this.productName,
    required this.warehouse,
    required this.qty,
    required this.unit,
    required this.sellingPrice,
    required this.lineTotal,
  });

  factory SaleLine.fromJson(Map<String, dynamic> json) {
    return SaleLine(
      productName: json['productName']?.toString() ?? '',
      warehouse: json['warehouse']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toDouble() ?? 0,
      unit: json['unit']?.toString() ?? '',
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class CreatedBy {
  final String id;
  final String name;
  final String email;

  CreatedBy({
    required this.id,
    required this.name,
    required this.email,
  });

  factory CreatedBy.fromJson(Map<String, dynamic> json) {
    return CreatedBy(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }
}

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  List<SaleModel> _sales = [];
  bool _loading = true;
  String? _error;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollCtrl = ScrollController();
  
  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadSales();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _currentPage < _totalPages) {
      _loadMoreSales();
    }
  }

  Future<void> _loadSales({bool reset = true}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _currentPage = 1;
        _sales = [];
      });
    }

    try {
      final params = <String, dynamic>{
        'page': _currentPage,
        'limit': 20,
      };
      
      if (_startDate != null) {
        params['startDate'] = DateFormat('yyyy-MM-dd').format(_startDate!);
      }
      if (_endDate != null) {
        params['endDate'] = DateFormat('yyyy-MM-dd').format(_endDate!);
      }

      debugPrint('🔍 Fetching sales with params: $params');

      final response = await DioClient.instance.dio.get(
        ApiRoutes.sales,
        queryParameters: params,
      );

      debugPrint('✅ Sales response status: ${response.statusCode}');
      
      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['success'] != true) {
        throw Exception('API returned success=false: ${responseData['message']}');
      }

      // Handle the response structure - data is directly an array
      final salesList = responseData['data'] as List? ?? [];
      final pagination = responseData['pagination'] as Map<String, dynamic>? ?? {};
      
      final newSales = salesList
          .map((e) => SaleModel.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        if (reset) {
          _sales = newSales;
        } else {
          _sales = [..._sales, ...newSales];
        }
        _totalPages = (pagination['pages'] as num?)?.toInt() ?? 1;
        _loading = false;
      });
      
      debugPrint('📊 Loaded ${newSales.length} sales, total pages: $_totalPages');
    } catch (e) {
      debugPrint('❌ Error loading sales: $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadMoreSales() async {
    if (_isLoadingMore || _currentPage >= _totalPages) return;
    
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    
    await _loadSales(reset: false);
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    
    if (result != null) {
      setState(() {
        _startDate = result.start;
        _endDate = result.end;
      });
      _loadSales(reset: true);
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadSales(reset: true);
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return '₹${formatter.format(amount)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProv, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Sales Invoices',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_alt_outlined),
                onPressed: _pickDateRange,
                tooltip: 'Filter by date',
              ),
              if (_startDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearDateFilter,
                  tooltip: 'Clear filter',
                ),
            ],
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by invoice number, buyer name, or mobile...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              
              // Date filter indicator
              if (_startDate != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.date_range, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // Sales List
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                        ? _buildErrorWidget()
                        : _getFilteredSales().isEmpty
                            ? _buildEmptyWidget()
                            : RefreshIndicator(
                                onRefresh: () => _loadSales(reset: true),
                                color: AppColors.primary,
                                child: ListView.builder(
                                  controller: _scrollCtrl,
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                  itemCount: _getFilteredSales().length + (_isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _getFilteredSales().length) {
                                      return const Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    final sale = _getFilteredSales()[index];
                                    return _buildSaleCard(sale);
                                  },
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<SaleModel> _getFilteredSales() {
    if (_searchQuery.isEmpty) return _sales;
    return _sales.where((s) {
      return s.invoiceNumber.toLowerCase().contains(_searchQuery) ||
          s.buyerName.toLowerCase().contains(_searchQuery) ||
          s.buyerMobile.contains(_searchQuery);
    }).toList();
  }

  Widget _buildSaleCard(SaleModel sale) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SaleDetailScreen(saleId: sale.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    sale.invoiceNumber,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPaymentModeColor(sale.paymentMode).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getPaymentModeText(sale.paymentMode),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getPaymentModeColor(sale.paymentMode),
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sale.buyerName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            if (sale.buyerMobile.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    sale.buyerMobile,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(sale.saleDate),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatCurrency(sale.grandTotal),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            if (sale.lines.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: sale.lines.take(2).map((line) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${line.productName}: ${line.qty} ${line.unit}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.primaryDark,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (sale.lines.length > 2)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    '+ more items',
                    style: TextStyle(fontSize: 10, color: AppColors.textHint),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getPaymentModeColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return AppColors.success;
      case 'upi':
        return AppColors.primary;
      case 'card':
        return Colors.orange;
      case 'bank_transfer':
        return Colors.purple;
      default:
        return AppColors.textHint;
    }
  }

  String _getPaymentModeText(String mode) {
    switch (mode.toLowerCase()) {
      case 'cash':
        return 'CASH';
      case 'upi':
        return 'UPI';
      case 'card':
        return 'CARD';
      case 'bank_transfer':
        return 'BANK TRANSFER';
      default:
        return mode.toUpperCase();
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadSales(reset: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
          const SizedBox(height: 16),
          const Text(
            'No sales invoices found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _startDate != null ? 'Try changing the date filter' : 'Create a new sale to get started',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textHint,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}