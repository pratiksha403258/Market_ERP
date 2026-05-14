import 'package:agr_market/models/buyer_model.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class BuyerCard extends StatelessWidget {
  final Buyer buyer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BuyerCard({
    super.key,
    required this.buyer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Business Name + Status Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    buyer.businessName,
                    style: AppTextStyles.headingSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!buyer.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Inactive',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // Display Name (Business + Person)
            Text(
              buyer.displayName,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 8),
            // Contact Info Row - Wrap with Flexible
            Row(
              children: [
                Icon(Icons.phone_outlined, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    buyer.mobile,
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.email_outlined, size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    buyer.email,
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Stats Row - Wrap with SingleChildScrollView for horizontal scrolling if needed
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatChip(
                    icon: Icons.account_balance_wallet_outlined,
                    label: '₹${buyer.totalPurchaseValue.toStringAsFixed(0)}',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.attach_money,
                    label: 'Limit: ₹${buyer.creditLimit.toStringAsFixed(0)}',
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.calendar_today,
                    label: '${buyer.creditDays} days',
                  ),
                  const SizedBox(width: 8),
                  // Action buttons as part of the scrollable row
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                    onPressed: onEdit,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    Color color = AppColors.textSecondary,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}