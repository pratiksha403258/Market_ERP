
import 'package:agr_market/payment/payment_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';

class PaymentSelectionScreen extends StatefulWidget {
  const PaymentSelectionScreen({super.key});

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  List<Map<String, dynamic>> _duePurchases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDuePurchases();
  }

  Future<void> _loadDuePurchases() async {
    setState(() => _loading = true);
    try {
      final response = await DioClient.instance.dio.get(
  ApiRoutes.purchases,
  queryParameters: {
    'page': 1,
    'limit': 100,
    'sortOrder': 'desc',
    'status': 'saved,partial',
  },

      );

      final data = response.data;
   List purchases = [];
final pData = response.data;
if (pData is Map && pData['data'] is List) {
  purchases = pData['data'] as List;
} else if (pData is List) {
  purchases = pData;
}
      _duePurchases = purchases.where((p) {
        final amountDue = (p['amountDue'] as num?)?.toDouble() ?? 0.0;
        return amountDue > 0;
      }).map((p) {
        final farmer = p['farmer'];
        final finalPayable = (p['finalPayable'] as num?)?.toDouble() ?? 0.0;
        final amountPaid = (p['amountPaid'] as num?)?.toDouble() ?? 0.0;
        final amountDue = (p['amountDue'] as num?)?.toDouble() ?? 0.0;
        return {
          'id': p['_id']?.toString() ?? p['id']?.toString() ?? '',
          'receiptNumber': p['receiptNumber']?.toString() ?? '',
          'farmerName': farmer is Map ? farmer['name']?.toString() ?? 'Unknown' : 'Unknown',
          'farmerId': farmer is Map ? farmer['_id']?.toString() ?? farmer['id']?.toString() ?? '' : '',
          'farmerMobile': farmer is Map ? farmer['mobile']?.toString() ?? '' : '',
          'finalPayable': finalPayable,
          'amountPaid': amountPaid,
          'amountDue': amountDue,
          'purchaseDate': p['purchaseDate']?.toString() ?? '',
        };
      }).toList();

      setState(() => _loading = false);
    } catch (e) {
      print('Error: $e');
      setState(() => _loading = false);
    }
  }

  void _makePayment(Map<String, dynamic> purchase) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          purchaseId: purchase['id'],
          farmerId: purchase['farmerId'],
          farmerName: purchase['farmerName'],
          finalPayable: purchase['finalPayable'],
          amountPaid: purchase['amountPaid'],
          amountDue: purchase['amountDue'],
          receiptNumber: purchase['receiptNumber'],
        ),
      ),
    ).then((paid) {
      if (paid == true) _loadDuePurchases();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Payment'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _duePurchases.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success),
                      SizedBox(height: 16),
                      Text('No pending dues!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text('All purchases are fully paid.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _duePurchases.length,
                  itemBuilder: (context, index) {
                    final p = _duePurchases[index];
                    final payable = p['finalPayable'] as double;
                    final paid = p['amountPaid'] as double;
                    final pct = payable > 0 ? (paid / payable).clamp(0.0, 1.0) : 0.0;

                    return GestureDetector(
                      onTap: () => _makePayment(p),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.heroGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(child: Icon(Icons.payment, color: Colors.white, size: 24)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['receiptNumber'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(p['farmerName'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Due: ₹${(p['amountDue'] as double).toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.warning)),
                                    Text('Payable: ₹${(p['finalPayable'] as double).toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                  ],
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: AppColors.warningSurface,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}