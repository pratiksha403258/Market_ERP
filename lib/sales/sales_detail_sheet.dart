// sale_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';
import '../../../providers/language_provider.dart';

class SaleDetailScreen extends StatefulWidget {
  final String saleId;
  
  const SaleDetailScreen({super.key, required this.saleId});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  Map<String, dynamic>? _sale;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSaleDetail();
  }

  Future<void> _loadSaleDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await DioClient.instance.dio.get(
        ApiRoutes.saleById(widget.saleId),
      );

      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Failed to load sale');
      }

      setState(() {
        _sale = responseData['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatCurrency(dynamic amount) {
    final value = (amount as num?)?.toDouble() ?? 0;
    final formatter = NumberFormat('#,##,##0', 'en_IN');
    return '₹${formatter.format(value)}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Sale Invoice',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildErrorWidget()
              : _sale == null
                  ? _buildEmptyWidget()
                  : _buildSaleDetail(),
    );
  }

  Widget _buildSaleDetail() {
    final lines = _sale!['lines'] as List? ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'INVOICE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 2,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _sale!['invoiceNumber'] ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_sale!['saleDate']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Grand Total',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(_sale!['grandTotal']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Buyer Information
          _buildSection(
            title: 'Buyer Details',
            icon: Icons.person_outline,
            child: Column(
              children: [
                _infoRow('Name', _sale!['buyerName'] ?? 'N/A'),
                _infoRow('Mobile', _sale!['buyerMobile'] ?? 'N/A'),
                if (_sale!['buyerGst'] != null && _sale!['buyerGst'].toString().isNotEmpty)
                  _infoRow('GST', _sale!['buyerGst']),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Products Section
          _buildSection(
            title: 'Products',
            icon: Icons.shopping_bag_outlined,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Expanded(flex: 3, child: Text('Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Rate', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                      Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ...lines.map((line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          line['productName'] ?? 'N/A',
                          style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${line['qty']} ${line['unit']}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatCurrency(line['sellingPrice']),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatCurrency(line['lineTotal']),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Payment Summary
          _buildSection(
            title: 'Payment Summary',
            icon: Icons.payment_outlined,
            child: Column(
              children: [
                _infoRow('Sub Total', _formatCurrency(_sale!['subTotal']), isBold: true),
                if ((_sale!['gstPercent'] ?? 0) > 0) ...[
                  _infoRow('GST (${_sale!['gstPercent']}%)', _formatCurrency(_sale!['gstAmount'])),
                ],
                const Divider(height: 16),
                _infoRow('Grand Total', _formatCurrency(_sale!['grandTotal']), isBold: true, isHighlight: true),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Mode: ${(_sale!['paymentMode'] ?? 'N/A').toString().toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      if (_sale!['referenceNumber'] != null && _sale!['referenceNumber'].toString().isNotEmpty)
                        Text(
                          'Ref: ${_sale!['referenceNumber']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_sale!['notes'] != null && _sale!['notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection(
              title: 'Notes',
              icon: Icons.note_outlined,
              child: Text(
                _sale!['notes'],
                style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isHighlight ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isHighlight ? AppColors.success : AppColors.textPrimary,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
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
              onPressed: _loadSaleDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Text('Sale not found'),
    );
  }
}