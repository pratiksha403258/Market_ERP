// ─────────────────────────────────────────────────────────────
// NEW PURCHASE SCREEN — 4-Step Flow
// Step 1: Select Farmer (+ advance alert)
// Step 2: Add Product Lines (dynamic pricing types)
// Step 3: Deductions (live final payable calc)
// Step 4: Summary + Rate Lock + Confirm
// ─────────────────────────────────────────────────────────────

import 'package:agr_market/purchase/purchase_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../models/farmer_model.dart';
import '../../../models/purchase_model.dart';

// ─────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────

class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  static const _stepLabels = ['Farmer', 'Products', 'Deductions', 'Summary'];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PurchaseController(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<PurchaseController>(
          builder: (context, controller, child) {
            return Stack(
              children: [
                // Header gradient
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.30,
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
                                onTap: () {
                                  if (controller.currentStep > 0) {
                                    _animCtrl.reset();
                                    _animCtrl.forward();
                                    controller.previousStep();
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
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
                              const Text('New Purchase',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins')),
                            ]),
                            const SizedBox(height: 16),
                            // Step indicator
                            _buildStepIndicator(controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Scrollable form
                Positioned.fill(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
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
                              child: _buildCurrentStep(controller),
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
                              onPressed: controller.isSaving ? null : () => _handleNext(controller),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: controller.isSaving
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          controller.currentStep < 3 ? 'Continue' : 'Confirm & Save',
                                          style: const TextStyle(fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Poppins'),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(controller.currentStep < 3
                                            ? Icons.arrow_forward_rounded
                                            : Icons.check_rounded,
                                            size: 18),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleNext(PurchaseController controller) async {
    if (controller.currentStep == 0 && controller.selectedFarmer != null && 
        controller.selectedFarmer!.advanceBalance > 0) {
      _showAdvanceAlert(context, controller);
      return;
    }
    
    if (controller.currentStep < 3) {
      _animCtrl.reset();
      _animCtrl.forward();
      controller.nextStep();
    } else {
      final success = await controller.savePurchase();
      if (success && mounted) {
        _showSnack(context, 'Purchase saved! 🎉', success: true);
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) Navigator.pop(context, true);
      } else if (controller.errorMessage != null && mounted) {
        _showSnack(context, controller.errorMessage!, success: false);
      }
    }
  }

  void _showAdvanceAlert(BuildContext context, PurchaseController controller) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 22),
          SizedBox(width: 10),
          Text('Advance Alert',
              style: TextStyle(fontSize: 16, fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600)),
        ]),
        content: Text(
          '${controller.selectedFarmer!.name} has a pending advance of '
          '₹${controller.selectedFarmer!.advanceBalance.toStringAsFixed(2)}.\n\n'
          'This will be auto-adjusted in deductions.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _animCtrl.reset();
              _animCtrl.forward();
              controller.nextStep();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Continue', style: TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _buildStepIndicator(PurchaseController controller) {
    return Row(
      children: List.generate(_stepLabels.length, (i) {
        final active = i == controller.currentStep;
        final done = i < controller.currentStep;
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

  Widget _buildCurrentStep(PurchaseController controller) {
    switch (controller.currentStep) {
      case 0:
        return _buildStep0Farmer(controller);
      case 1:
        return _buildStep1Products(controller);
      case 2:
        return _buildStep2Deductions(controller);
      case 3:
        return _buildStep3Summary(controller);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── STEP 0 — Select Farmer ────────────────────────────────

  Widget _buildStep0Farmer(PurchaseController controller) {
    return Column(
      key: const ValueKey('s0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('👨‍🌾 Select Farmer', 'Choose the farmer for this purchase'),
        const SizedBox(height: 20),
        if (controller.loadingFarmers)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppColors.primary),
          ))
        else if (controller.farmers.isEmpty)
          Center(child: Column(children: [
            const Icon(Icons.people_outline,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 8),
            const Text('No farmers found. Add a farmer first.',
                style: TextStyle(color: AppColors.textSecondary,
                    fontFamily: 'Poppins', fontSize: 13)),
          ]))
        else
          ...controller.farmers.map((f) => _FarmerSelectTile(
            farmer: f,
            isSelected: controller.selectedFarmer?.id == f.id,
            onTap: () => controller.selectFarmer(f),
          )),
        if (controller.errorMessage != null && controller.currentStep == 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              controller.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // ── STEP 1 — Product Lines ────────────────────────────────

  Widget _buildStep1Products(PurchaseController controller) {
    return Column(
      key: const ValueKey('s1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('📦 Add Products', 'Add one or more product lines'),
        const SizedBox(height: 16),
        ...controller.lines.map((line) => _ProductLineCard(
          line: line,
          canRemove: controller.lines.length > 1,
          onRemove: () => controller.removeLine(line.id),
          onChanged: (updatedLine) => controller.updateLine(line.id, updatedLine),
        )),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: controller.addLine,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 1.5),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primarySurface,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Text('Add Another Product',
                    style: TextStyle(color: AppColors.primary,
                        fontWeight: FontWeight.w600, fontSize: 13,
                        fontFamily: 'Poppins')),
              ],
            ),
          ),
        ),
        if (controller.lines.isNotEmpty && controller.grossTotal > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gross Total',
                    style: TextStyle(color: Colors.white70, fontSize: 13,
                        fontFamily: 'Poppins')),
                Text('₹${controller.grossTotal.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
              ],
            ),
          ),
        ],
        if (controller.errorMessage != null && controller.currentStep == 1)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              controller.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  // ── STEP 2 — Deductions ───────────────────────────────────

  Widget _buildStep2Deductions(PurchaseController controller) {
    return Column(
      key: const ValueKey('s2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('📊 Deductions', 'Apply charges to calculate final payable'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Gross Total',
                  style: TextStyle(color: AppColors.textSecondary,
                      fontSize: 13, fontFamily: 'Poppins')),
              Text('₹${controller.grossTotal.toStringAsFixed(2)}',
                  style: const TextStyle(color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700, fontSize: 14,
                      fontFamily: 'Poppins')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _DeductionField(
          label: 'Transport',
          icon: Icons.local_shipping_outlined,
          value: controller.deductions.transport,
          onChanged: (v) => controller.updateDeduction(transport: v),
        ),
        _DeductionField(
          label: 'Labour',
          icon: Icons.people_outline_rounded,
          value: controller.deductions.labour,
          onChanged: (v) => controller.updateDeduction(labour: v),
        ),
        _CommissionField(
          value: controller.deductions.commission,
          type: controller.deductions.commissionType,
          grossTotal: controller.grossTotal,
          onValueChanged: (v) => controller.updateDeduction(commission: v),
          onTypeChanged: (t) => controller.updateDeduction(commissionType: t),
        ),
        _DeductionField(
          label: 'Storage / Misc',
          icon: Icons.warehouse_outlined,
          value: controller.deductions.storage,
          onChanged: (v) => controller.updateDeduction(storage: v),
        ),
        _DeductionField(
          label: 'Return Deduction',
          icon: Icons.assignment_return_outlined,
          value: controller.deductions.returnDeduction,
          onChanged: (v) => controller.updateDeduction(returnDeduction: v),
        ),
        _DeductionField(
          label: 'Advance Adjusted',
          icon: Icons.account_balance_wallet_outlined,
          value: controller.deductions.advanceAdjusted,
          hint: 'Auto-filled from farmer advance',
          onChanged: controller.updateAdvanceAdjusted,
        ),
        _DeductionField(
          label: 'Other',
          icon: Icons.more_horiz_rounded,
          value: controller.deductions.other,
          onChanged: (v) => controller.updateDeduction(other: v),
        ),
        const SizedBox(height: 20),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 12),
        _FinalPayableCard(
          grossTotal: controller.grossTotal,
          totalDeductions: controller.totalDeductions,
          finalPayable: controller.finalPayable,
        ),
      ],
    );
  }

  // ── STEP 3 — Summary + Rate Lock + Confirm ────────────────

  Widget _buildStep3Summary(PurchaseController controller) {
    return Column(
      key: const ValueKey('s3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader('✅ Summary', 'Review and confirm purchase'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(controller.selectedFarmer?.initials ?? 'F',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700, fontSize: 16,
                        fontFamily: 'Poppins')),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(controller.selectedFarmer?.name ?? '',
                  style: const TextStyle(fontSize: 15,
                      fontWeight: FontWeight.w600, fontFamily: 'Poppins',
                      color: AppColors.textPrimary)),
              Text(controller.selectedFarmer?.mobile ?? '',
                  style: const TextStyle(fontSize: 12,
                      color: AppColors.textSecondary, fontFamily: 'Poppins')),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        const Text('Product Lines',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        ...controller.lines.map((l) => _SummaryLineRow(
          line: l,
          onRateLockToggle: (locked) {
            if (!locked) {
              _confirmUnlockRate(context, controller, l);
            } else {
              controller.toggleRateLock(l.id, true);
            }
          },
        )),
        const SizedBox(height: 14),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 10),
        _SummaryRow('Transport', controller.deductions.transport),
        _SummaryRow('Labour', controller.deductions.labour),
        _SummaryRow(
          'Commission (${controller.deductions.commissionType == 'percent' ? '${controller.deductions.commission}%' : 'fixed'})',
          controller.commissionAmount,
        ),
        if (controller.deductions.storage > 0) 
          _SummaryRow('Storage', controller.deductions.storage),
        if (controller.deductions.returnDeduction > 0)
          _SummaryRow('Return Deduction', controller.deductions.returnDeduction),
        if (controller.deductions.advanceAdjusted > 0)
          _SummaryRow('Advance Adjusted', controller.deductions.advanceAdjusted),
        if (controller.deductions.other > 0) 
          _SummaryRow('Other', controller.deductions.other),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 6),
        _SummaryRow('Gross Total', controller.grossTotal, bold: true, primary: false),
        _SummaryRow('Total Deductions', controller.totalDeductions, bold: true, primary: false),
        const SizedBox(height: 4),
        _FinalPayableCard(
          grossTotal: controller.grossTotal,
          totalDeductions: controller.totalDeductions,
          finalPayable: controller.finalPayable,
        ),
      ],
    );
  }

  void _confirmUnlockRate(BuildContext context, PurchaseController controller, PurchaseLine line) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Unlock Rate?',
            style: TextStyle(fontSize: 16, fontFamily: 'Poppins',
                fontWeight: FontWeight.w600)),
        content: Text(
          'The rate for "${line.productName}" is locked.\n'
          'Unlocking will allow editing. Do you want to proceed?',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.toggleRateLock(line.id, false);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Unlock', style: TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

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

  Widget _SummaryRow(String label, double value,
      {bool bold = false, bool primary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: primary ? AppColors.primary : AppColors.textSecondary)),
        Text('₹${value.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: primary ? AppColors.primary : AppColors.textPrimary)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────

// ── Farmer Select Tile ────────────────────────────────────────

class _FarmerSelectTile extends StatelessWidget {
  final FarmerModel farmer;
  final bool isSelected;
  final VoidCallback onTap;

  const _FarmerSelectTile({
    required this.farmer,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: isSelected
                  ? AppColors.heroGradient
                  : const LinearGradient(
                      colors: [Color(0xFFD5E8B0), Color(0xFFD5E8B0)]),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(farmer.initials,
                  style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins')),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(farmer.name,
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary)),
                Text(farmer.mobile,
                    style: const TextStyle(fontSize: 12,
                        color: AppColors.textSecondary, fontFamily: 'Poppins')),
                if (farmer.advanceBalance > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Advance: ₹${farmer.advanceBalance.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.warning, fontSize: 10,
                          fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 13)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ── Product Line Card ─────────────────────────────────────────

class _ProductLineCard extends StatefulWidget {
  final PurchaseLine line;
  final bool canRemove;
  final VoidCallback onRemove;
  final Function(PurchaseLine) onChanged;

  const _ProductLineCard({
    required this.line,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ProductLineCard> createState() => _ProductLineCardState();
}

class _ProductLineCardState extends State<_ProductLineCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _rateCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _bagsCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _qualCtrl;

  static const _pricingTypes = [
    ('kg', 'KG'),
    ('quintal', 'Quintal'),
    ('piece', 'Piece'),
    ('bunch', 'Bunch'),
    ('crate', 'Crate'),
    ('dozen', 'Dozen'),
    ('flat', 'Flat'),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.line.productName);
    _rateCtrl = TextEditingController(
        text: widget.line.rate > 0 ? widget.line.rate.toString() : '');
    _qtyCtrl = TextEditingController(
        text: widget.line.actualQty > 0 ? widget.line.actualQty.toString() : '');
    _bagsCtrl = TextEditingController(
        text: widget.line.bags > 0 ? widget.line.bags.toString() : '');
    _weightCtrl = TextEditingController(
        text: widget.line.weightPerBag > 0 ? widget.line.weightPerBag.toString() : '');
    _qualCtrl = TextEditingController(
        text: widget.line.qualityDeduction > 0
            ? widget.line.qualityDeduction.toString()
            : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    _qtyCtrl.dispose();
    _bagsCtrl.dispose();
    _weightCtrl.dispose();
    _qualCtrl.dispose();
    super.dispose();
  }

  void _update() {
    final updatedLine = widget.line.copyWith(
      productName: _nameCtrl.text,
      rate: double.tryParse(_rateCtrl.text) ?? 0,
      actualQty: double.tryParse(_qtyCtrl.text) ?? 0,
      bags: double.tryParse(_bagsCtrl.text) ?? 0,
      weightPerBag: double.tryParse(_weightCtrl.text) ?? 0,
      qualityDeduction: double.tryParse(_qualCtrl.text) ?? 0,
    );
    widget.onChanged(updatedLine);
  }

  @override
  Widget build(BuildContext context) {
    final isKg = widget.line.pricingType == 'kg';
    final isFlat = widget.line.pricingType == 'flat';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Product Line',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary, fontFamily: 'Poppins')),
          if (widget.canRemove)
            GestureDetector(
              onTap: widget.onRemove,
              child: const Icon(Icons.remove_circle_outline_rounded,
                  color: AppColors.error, size: 18),
            ),
        ]),
        const SizedBox(height: 10),
        _inputField(
          ctrl: _nameCtrl,
          label: 'Product Name *',
          hint: 'e.g. Onion',
          icon: Icons.eco_outlined,
          caps: TextCapitalization.words,
          onChanged: (_) => _update(),
        ),
        const SizedBox(height: 10),
        const Text('Pricing Type *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6, runSpacing: 6,
          children: _pricingTypes.map((pt) {
            final selected = widget.line.pricingType == pt.$1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  final updatedLine = widget.line.copyWith(pricingType: pt.$1);
                  widget.onChanged(updatedLine);
                });
                _update();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border),
                ),
                child: Text(pt.$2,
                    style: TextStyle(
                        color: selected ? Colors.white : AppColors.textSecondary,
                        fontSize: 12, fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (isKg) ...[
          Row(children: [
            Expanded(
              child: _inputField(
                ctrl: _bagsCtrl,
                label: 'Bags',
                hint: '0',
                icon: Icons.inventory_2_outlined,
                inputType: TextInputType.number,
                onChanged: (_) => _update(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _inputField(
                ctrl: _weightCtrl,
                label: 'kg / Bag',
                hint: '0.0',
                icon: Icons.scale_outlined,
                inputType: TextInputType.number,
                onChanged: (_) => _update(),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          if ((double.tryParse(_bagsCtrl.text) ?? 0) > 0 &&
              (double.tryParse(_weightCtrl.text) ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Gross qty: ${widget.line.grossQty.toStringAsFixed(2)} kg',
                style: const TextStyle(
                    color: AppColors.primaryDark, fontSize: 12,
                    fontFamily: 'Poppins', fontWeight: FontWeight.w500),
              ),
            ),
        ] else if (!isFlat) ...[
          _inputField(
            ctrl: _qtyCtrl,
            label: 'Quantity (${widget.line.unit})',
            hint: '0',
            icon: Icons.straighten_outlined,
            inputType: TextInputType.number,
            onChanged: (_) => _update(),
          ),
        ],
        if (!isFlat) ...[
          const SizedBox(height: 10),
          _inputField(
            ctrl: _qualCtrl,
            label: 'Quality Deduction (${widget.line.unit})',
            hint: '0',
            icon: Icons.remove_circle_outline,
            inputType: TextInputType.number,
            onChanged: (_) => _update(),
          ),
        ],
        const SizedBox(height: 10),
        _inputField(
          ctrl: _rateCtrl,
          label: isFlat ? 'Fixed Price (₹) *' : 'Rate per ${widget.line.unit} (₹) *',
          hint: '0.00',
          icon: Icons.currency_rupee_rounded,
          inputType: TextInputType.number,
          onChanged: (_) => _update(),
        ),
        if (widget.line.lineTotal > 0) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Line Total',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary,
                    fontFamily: 'Poppins')),
            Text('₹${widget.line.lineTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark, fontFamily: 'Poppins')),
          ]),
        ],
      ]),
    );
  }

  Widget _inputField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    required ValueChanged<String> onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary, fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      TextFormField(
        controller: ctrl,
        keyboardType: inputType,
        textCapitalization: caps,
        inputFormatters: inputType == TextInputType.number
            ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
            : null,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary,
            fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          prefixIcon: Icon(icon, color: AppColors.textHint, size: 18),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    ]);
  }
}

// ── Deduction Field ───────────────────────────────────────────

class _DeductionField extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final String? hint;
  final ValueChanged<double> onChanged;

  const _DeductionField({
    required this.label,
    required this.icon,
    required this.value,
    this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(
        text: value > 0 ? value.toStringAsFixed(2) : '');
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: AppColors.textHint, size: 18),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary,
                  fontFamily: 'Poppins')),
        ),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary,
                fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint ?? '0.00',
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
              prefixText: '₹ ',
              prefixStyle: const TextStyle(color: AppColors.textSecondary,
                  fontSize: 13, fontFamily: 'Poppins'),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Commission Field ──────────────────────────────────────────

class _CommissionField extends StatelessWidget {
  final double value;
  final String type;
  final double grossTotal;
  final ValueChanged<double> onValueChanged;
  final ValueChanged<String> onTypeChanged;

  const _CommissionField({
    required this.value,
    required this.type,
    required this.grossTotal,
    required this.onValueChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final commAmt = type == 'percent' ? (value / 100) * grossTotal : value;
    final ctrl = TextEditingController(
        text: value > 0 ? value.toStringAsFixed(type == 'percent' ? 1 : 2) : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.handshake_outlined, color: AppColors.textHint, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Commission',
                style: TextStyle(fontSize: 13, color: AppColors.textPrimary,
                    fontFamily: 'Poppins')),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _toggleChip('₹', type == 'fixed', () => onTypeChanged('fixed')),
              _toggleChip('%', type == 'percent', () => onTypeChanged('percent')),
            ]),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: TextFormField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              onChanged: (v) => onValueChanged(double.tryParse(v) ?? 0),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary,
                  fontFamily: 'Poppins', fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
                suffixText: type == 'percent' ? '%' : '₹',
                suffixStyle: const TextStyle(color: AppColors.textSecondary,
                    fontSize: 12, fontFamily: 'Poppins'),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ),
        ]),
        if (type == 'percent' && commAmt > 0)
          Padding(
            padding: const EdgeInsets.only(left: 28, top: 4),
            child: Text('= ₹${commAmt.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.textHint, fontSize: 11,
                    fontFamily: 'Poppins')),
          ),
      ]),
    );
  }

  Widget _toggleChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 12, fontFamily: 'Poppins',
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// ── Final Payable Card ────────────────────────────────────────

class _FinalPayableCard extends StatelessWidget {
  final double grossTotal;
  final double totalDeductions;
  final double finalPayable;

  const _FinalPayableCard({
    required this.grossTotal,
    required this.totalDeductions,
    required this.finalPayable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Gross Total',
              style: TextStyle(color: Colors.white70, fontSize: 12,
                  fontFamily: 'Poppins')),
          Text('₹${grossTotal.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 14,
                  fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Deductions',
              style: TextStyle(color: Colors.white70, fontSize: 12,
                  fontFamily: 'Poppins')),
          Text('- ₹${totalDeductions.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white70, fontSize: 14,
                  fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),
        const Divider(color: Colors.white30),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Final Payable',
              style: TextStyle(color: Colors.white, fontSize: 15,
                  fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
          Text('₹${finalPayable.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 22,
                  fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

// ── Summary Line Row ──────────────────────────────────────────

class _SummaryLineRow extends StatelessWidget {
  final PurchaseLine line;
  final ValueChanged<bool> onRateLockToggle;

  const _SummaryLineRow({
    required this.line,
    required this.onRateLockToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Text(line.productName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary, fontFamily: 'Poppins')),
          ),
          GestureDetector(
            onTap: () => onRateLockToggle(!line.rateLocked),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: line.rateLocked
                    ? AppColors.warningSurface
                    : AppColors.successSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: line.rateLocked ? AppColors.warning : AppColors.success,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(
                  line.rateLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                  size: 12,
                  color: line.rateLocked ? AppColors.warning : AppColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  line.rateLocked ? 'Rate Locked' : 'Lock Rate',
                  style: TextStyle(
                      fontSize: 10, fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: line.rateLocked
                          ? AppColors.warning
                          : AppColors.success),
                ),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          _chip('${line.pricingType.toUpperCase()}'),
          const SizedBox(width: 6),
          _chip('${line.billedQty.toStringAsFixed(2)} ${line.unit}'),
          const SizedBox(width: 6),
          _chip('₹${line.rate.toStringAsFixed(2)}/${line.unit}'),
          const Spacer(),
          Text('₹${line.lineTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark, fontFamily: 'Poppins')),
        ]),
      ]),
    );
  }

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(text,
        style: const TextStyle(fontSize: 10, color: AppColors.primaryDark,
            fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
  );
}