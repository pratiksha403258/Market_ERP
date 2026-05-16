

import 'package:agr_market/providers/language_provider.dart';
import 'package:agr_market/purchase/purchase_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../models/farmer_model.dart';
import '../../../models/purchase_model.dart';
import '../models/deduction_model.dart';

class NewPurchaseScreen extends StatefulWidget {
  final bool isEditMode;
  final String? purchaseId;
  final FarmerModel? existingFarmer;
  final List<PurchaseLine>? existingLines;
  final DeductionData? existingDeductions;

  const NewPurchaseScreen({
    super.key,
    this.isEditMode = false,
    this.purchaseId,
    this.existingFarmer,
    this.existingLines,
    this.existingDeductions,
  });

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  bool _isEditModeInitialized = false;
  static const _stepLabels = ['Farmer', 'Products', 'Deductions', 'Summary'];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  void _initializeEditMode(PurchaseController controller) {
    if (!widget.isEditMode || _isEditModeInitialized) return;
    if (widget.existingFarmer != null &&
        widget.existingLines != null &&
        widget.existingDeductions != null) {
      _isEditModeInitialized = true;
      controller.initForEdit(
        purchaseId: widget.purchaseId!,
        farmer: widget.existingFarmer!,
        existingLines: widget.existingLines!,
        existingDeductions: widget.existingDeductions!,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.setCurrentStep(1);
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    
    return ChangeNotifierProvider(
      create: (_) => PurchaseController(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Consumer<PurchaseController>(
          builder: (context, controller, child) {
            _initializeEditMode(controller);
            return Column(
              children: [
                _buildHeader(controller, lang),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
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
                              child: _buildCurrentStep(controller, lang),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildActionButton(controller, lang),
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

  Widget _buildHeader(PurchaseController controller, LanguageProvider lang) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.22,
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
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  widget.isEditMode ? lang.t('edit_purchase') : lang.t('new_purchase'),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
                ),
              ]),
              const SizedBox(height: 16),
              _buildStepIndicator(controller),
            ],
          ),
        ),
      ),
    );
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
                          fontSize: 9, fontFamily: 'Poppins', fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (i < _stepLabels.length - 1)
                Container(width: 20, height: 1, color: Colors.white.withOpacity(0.35)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionButton(PurchaseController controller, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: controller.isSaving ? null : () => _handleNext(controller, lang),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: controller.isSaving
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(
                    controller.currentStep < 3 
                        ? lang.t('continue_btn') 
                        : (widget.isEditMode ? lang.t('update_purchase') : lang.t('confirm_save')),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
                  ),
                  const SizedBox(width: 8),
                  Icon(controller.currentStep < 3 ? Icons.arrow_forward_rounded : Icons.check_rounded, size: 18),
                ]),
        ),
      ),
    );
  }

  void _handleNext(PurchaseController controller, LanguageProvider lang) async {
    if (widget.isEditMode && controller.currentStep == 0) {
      if (controller.currentStep < 3) {
        _animCtrl.reset();
        _animCtrl.forward();
        controller.nextStep();
      }
      return;
    }

    if (controller.currentStep == 0 && controller.selectedFarmer != null &&
        controller.selectedFarmer!.advanceBalance > 0) {
      _showAdvanceAlert(context, controller, lang);
      return;
    }

    if (controller.currentStep < 3) {
      _animCtrl.reset();
      _animCtrl.forward();
      controller.nextStep();
    } else {
      final success = await controller.savePurchase();
      if (success && mounted) {
        _showSnack(context, widget.isEditMode ? lang.t('purchase_updated') : lang.t('purchase_saved'), success: true);
        Navigator.pushNamedAndRemoveUntil(context, '/purchases', (route) => false);
      } else if (controller.errorMessage != null && mounted) {
        _showSnack(context, lang.t(controller.errorMessage!), success: false);
      }
    }
  }

  void _showAdvanceAlert(BuildContext context, PurchaseController controller, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Text(lang.t('advance_alert'), style: const TextStyle(fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        ]),
        content: Text(
          '${controller.selectedFarmer!.name} ${lang.t('has_pending_advance')} '
          '₹${controller.selectedFarmer!.advanceBalance.toStringAsFixed(2)}.\n\n${lang.t('auto_adjusted')}',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t('cancel'))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _animCtrl.reset();
              _animCtrl.forward();
              controller.nextStep();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(lang.t('continue_btn'), style: const TextStyle(fontFamily: 'Inter')),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: success ? AppColors.success : AppColors.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _buildCurrentStep(PurchaseController controller, LanguageProvider lang) {
    switch (controller.currentStep) {
      case 0: return _buildStep0Farmer(controller, lang);
      case 1: return _buildStep1Products(controller, lang);
      case 2: return _buildStep2Deductions(controller, lang);
      case 3: return _buildStep3Summary(controller, lang);
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildStep0Farmer(PurchaseController controller, LanguageProvider lang) {
    final isEditMode = widget.isEditMode;
    return Column(
      key: const ValueKey('s0'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(lang.t('select_farmer'), isEditMode ? lang.t('farmer_locked') : lang.t('choose_farmer')),
        const SizedBox(height: 20),
        if (isEditMode && controller.selectedFarmer != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
                child: Center(child: Text(controller.selectedFarmer!.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Poppins')))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(controller.selectedFarmer!.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Poppins')),
                Text(controller.selectedFarmer!.mobile, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Poppins')),
                Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.infoSurface, borderRadius: BorderRadius.circular(6)),
                  child: const Text('Locked (edit mode)', style: TextStyle(color: AppColors.info, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w500))),
              ])),
              const Icon(Icons.lock_rounded, color: AppColors.textHint, size: 18),
            ]),
          )
        else if (!isEditMode)
          Column(children: [
            Padding(padding: const EdgeInsets.only(bottom: 16),
              child: TextField(decoration: InputDecoration(hintText: lang.t('search_by_name_mobile'), prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: controller.searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: () => controller.clearFarmerSearch()) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                filled: true, fillColor: AppColors.surface, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                onChanged: (value) => controller.searchFarmers(value),
              ),
            ),
            if (controller.loadingFarmers) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primary)))
            else if (controller.farmers.isEmpty) Center(child: Column(children: [
              const Icon(Icons.people_outline, size: 48, color: AppColors.textHint),
              const SizedBox(height: 8),
              Text(lang.t('no_farmers_found_add_first'), style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins', fontSize: 13)),
            ]))
            else ...controller.farmers.map((f) => _FarmerSelectTile(farmer: f, isSelected: controller.selectedFarmer?.id == f.id, onTap: () => controller.selectFarmer(f))),
          ]),
        if (controller.errorMessage != null && controller.currentStep == 0)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(lang.t(controller.errorMessage!), style: const TextStyle(color: AppColors.error, fontSize: 12))),
      ],
    );
  }

  Widget _buildStep1Products(PurchaseController controller, LanguageProvider lang) {
    return Column(
      key: const ValueKey('s1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(lang.t('add_products'), lang.t('add_one_or_more')),
        const SizedBox(height: 16),
        ...controller.lines.map((line) => _ProductLineCard(line: line, canRemove: controller.lines.length > 1,
          onRemove: () => controller.removeLine(line.id), onChanged: (updatedLine) => controller.updateLine(line.id, updatedLine))),
        const SizedBox(height: 8),
        GestureDetector(onTap: controller.addLine,
          child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: AppColors.primary, width: 1.5), borderRadius: BorderRadius.circular(12), color: AppColors.primarySurface),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 18),
              SizedBox(width: 8),
              Text('Add Another Product', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'Poppins')),
            ]),
          ),
        ),
        if (controller.lines.isNotEmpty && controller.grossTotal > 0) ...[
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Gross Total', style: TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'Poppins')),
              Text('₹${controller.grossTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
            ]),
          ),
        ],
        if (controller.errorMessage != null && controller.currentStep == 1)
          Padding(padding: const EdgeInsets.only(top: 12), child: Text(lang.t(controller.errorMessage!), style: const TextStyle(color: AppColors.error, fontSize: 12))),
      ],
    );
  }

  Widget _buildStep2Deductions(PurchaseController controller, LanguageProvider lang) {
    return Column(
      key: const ValueKey('s2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(lang.t('deductions'), lang.t('apply_charges')),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Gross Total', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Poppins')),
            Text('₹${controller.grossTotal.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Poppins')),
          ]),
        ),
        const SizedBox(height: 16),
        _DeductionField(label: lang.t('transport'), icon: Icons.local_shipping_outlined, value: controller.deductions.transport, onChanged: (v) => controller.updateDeduction(transport: v)),
        _DeductionField(label: lang.t('labour'), icon: Icons.people_outline_rounded, value: controller.deductions.labour, onChanged: (v) => controller.updateDeduction(labour: v)),
        _CommissionField(value: controller.deductions.commission, type: controller.deductions.commissionType, grossTotal: controller.grossTotal,
          onValueChanged: (v) => controller.updateDeduction(commission: v), onTypeChanged: (t) => controller.updateDeduction(commissionType: t)),
        _DeductionField(label: lang.t('storage_misc'), icon: Icons.warehouse_outlined, value: controller.deductions.storage, onChanged: (v) => controller.updateDeduction(storage: v)),
        _DeductionField(label: lang.t('return_deduction'), icon: Icons.assignment_return_outlined, value: controller.deductions.returnDeduction, onChanged: (v) => controller.updateDeduction(returnDeduction: v)),
        _DeductionField(label: lang.t('advance_adjusted'), icon: Icons.account_balance_wallet_outlined, value: controller.deductions.advanceAdjusted, hint: lang.t('auto_filled_advance'), onChanged: controller.updateAdvanceAdjusted),
        _DeductionField(label: lang.t('other'), icon: Icons.more_horiz_rounded, value: controller.deductions.other, onChanged: (v) => controller.updateDeduction(other: v)),
        const SizedBox(height: 20),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 12),
        _FinalPayableCard(grossTotal: controller.grossTotal, totalDeductions: controller.totalDeductions, finalPayable: controller.finalPayable),
      ],
    );
  }

  Widget _buildStep3Summary(PurchaseController controller, LanguageProvider lang) {
    return Column(
      key: const ValueKey('s3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: _stepHeader(lang.t('summary'), lang.t('review_confirm'))),
          if (controller.isEditMode)
            GestureDetector(onTap: () => _confirmDelete(controller, lang),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.error.withOpacity(0.4))),
                child: controller.isDeleting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.error, strokeWidth: 2))
                    : const Row(children: [Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16), SizedBox(width: 4), Text('Delete', style: TextStyle(color: AppColors.error, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w600))]),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
              child: Center(child: Text(controller.selectedFarmer?.initials ?? 'F', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16, fontFamily: 'Poppins')))),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(controller.selectedFarmer?.name ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: AppColors.textPrimary)),
              Text(controller.selectedFarmer?.mobile ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Poppins')),
            ]),
          ]),
        ),
        const SizedBox(height: 14),
        const Text('Product Lines', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 8),
        ...controller.lines.map((l) => _SummaryLineRow(line: l, onRateLockToggle: (locked) {
          if (!locked) _confirmUnlockRate(context, controller, l, lang);
          else controller.toggleRateLock(l.id, true);
        })),
        const SizedBox(height: 14),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 10),
        _SummaryRow(lang.t('transport'), controller.deductions.transport),
        _SummaryRow(lang.t('labour'), controller.deductions.labour),
        _SummaryRow('Commission (${controller.deductions.commissionType == 'percent' ? '${controller.deductions.commission}%' : 'fixed'})', controller.commissionAmount),
        if (controller.deductions.storage > 0) _SummaryRow(lang.t('storage'), controller.deductions.storage),
        if (controller.deductions.returnDeduction > 0) _SummaryRow(lang.t('return_deduction'), controller.deductions.returnDeduction),
        if (controller.deductions.advanceAdjusted > 0) _SummaryRow(lang.t('advance_adjusted'), controller.deductions.advanceAdjusted),
        if (controller.deductions.other > 0) _SummaryRow(lang.t('other'), controller.deductions.other),
        const Divider(color: AppColors.divider),
        const SizedBox(height: 6),
        _SummaryRow(lang.t('gross_total'), controller.grossTotal, bold: true, primary: false),
        _SummaryRow(lang.t('total_deductions'), controller.totalDeductions, bold: true, primary: false),
        const SizedBox(height: 4),
        _FinalPayableCard(grossTotal: controller.grossTotal, totalDeductions: controller.totalDeductions, finalPayable: controller.finalPayable),
      ],
    );
  }

  void _confirmDelete(PurchaseController controller, LanguageProvider lang) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22), const SizedBox(width: 10),
        Text(lang.t('delete_purchase'), style: const TextStyle(fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600))]),
      content: Text(lang.t('delete_warning'), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t('cancel'))),
        ElevatedButton(onPressed: () async {
          Navigator.pop(context);
          final success = await controller.deletePurchase();
          if (success && mounted) {
            _showSnack(context, lang.t('purchase_deleted'), success: false);
            await Future.delayed(const Duration(milliseconds: 600));
            if (mounted) Navigator.pop(context, 'deleted');
          } else if (controller.errorMessage != null && mounted) _confirmForceDelete(controller, lang);
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(lang.t('delete'), style: const TextStyle(fontFamily: 'Poppins'))),
      ],
    ));
  }

  void _confirmForceDelete(PurchaseController controller, LanguageProvider lang) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(lang.t('force_delete'), style: const TextStyle(fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.error)),
      content: Text('${lang.t('delete_failed')}: ${controller.errorMessage}\n\n${lang.t('force_delete_warning')}',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t('cancel'))),
        ElevatedButton(onPressed: () async {
          Navigator.pop(context);
          final success = await controller.deletePurchase(force: true);
          if (success && mounted) {
            _showSnack(context, lang.t('force_deleted'), success: false);
            await Future.delayed(const Duration(milliseconds: 600));
            if (mounted) Navigator.pop(context, 'deleted');
          } else if (mounted) _showSnack(context, controller.errorMessage ?? lang.t('delete_failed'), success: false);
        }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(lang.t('force_delete'), style: const TextStyle(fontFamily: 'Poppins'))),
      ],
    ));
  }

  void _confirmUnlockRate(BuildContext context, PurchaseController controller, PurchaseLine line, LanguageProvider lang) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(lang.t('unlock_rate'), style: const TextStyle(fontSize: 16, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      content: Text(lang.t('unlock_warning'), style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.t('cancel'))),
        ElevatedButton(onPressed: () { controller.toggleRateLock(line.id, false); Navigator.pop(context); },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(lang.t('unlock_btn'), style: const TextStyle(fontFamily: 'Inter'))),
      ],
    ));
  }

  Widget _stepHeader(String title, String sub) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Poppins')),
    const SizedBox(height: 4),
    Text(sub, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Poppins')),
  ]);

  Widget _SummaryRow(String label, double value, {bool bold = false, bool primary = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, fontFamily: 'Poppins', fontWeight: bold ? FontWeight.w600 : FontWeight.w400, color: primary ? AppColors.primary : AppColors.textSecondary)),
      Text('₹${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontFamily: 'Poppins', fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: primary ? AppColors.primary : AppColors.textPrimary)),
    ]),
  );
}

// ── Farmer Select Tile ────────────────────────────────────────
class _FarmerSelectTile extends StatelessWidget {
  final FarmerModel farmer; final bool isSelected; final VoidCallback onTap;
  const _FarmerSelectTile({required this.farmer, required this.isSelected, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isSelected ? AppColors.primarySurface : AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: isSelected ? 2 : 1)),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(gradient: isSelected ? AppColors.heroGradient : const LinearGradient(colors: [Color(0xFFD5E8B0), Color(0xFFD5E8B0)]), shape: BoxShape.circle),
          child: Center(child: Text(farmer.initials, style: TextStyle(color: isSelected ? Colors.white : AppColors.primary, fontWeight: FontWeight.w700, fontFamily: 'Poppins')))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(farmer.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: isSelected ? AppColors.primary : AppColors.textPrimary)),
          Text(farmer.mobile, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Poppins')),
          if (farmer.advanceBalance > 0) Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.warningSurface, borderRadius: BorderRadius.circular(6)),
            child: Text('Advance: ₹${farmer.advanceBalance.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.warning, fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w500))),
        ])),
        AnimatedContainer(duration: const Duration(milliseconds: 200), width: 22, height: 22,
          decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? AppColors.primary : Colors.transparent,
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border, width: 2)),
          child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 13) : null),
      ]),
    ),
  );
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

  bool _showDropdown = false;
  List<ProductModel> _filteredProducts = [];
  int _visibleCount = 5;
  static const int _initialVisibleCount = 5;
  final TextEditingController _searchController = TextEditingController();

  static const _pricingTypes = [
    ('kg', 'KG'), ('quintal', 'Quintal'), ('piece', 'Piece'),
    ('bunch', 'Bunch'), ('crate', 'Crate'), ('dozen', 'Dozen'), ('flat', 'Flat'),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.line.productName);
    _rateCtrl = TextEditingController(text: widget.line.rate > 0 ? widget.line.rate.toString() : '');
    _qtyCtrl = TextEditingController(text: widget.line.actualQty > 0 ? widget.line.actualQty.toString() : '');
    _bagsCtrl = TextEditingController(text: widget.line.bags > 0 ? widget.line.bags.toString() : '');
    _weightCtrl = TextEditingController(text: widget.line.weightPerBag > 0 ? widget.line.weightPerBag.toString() : '');
    _qualCtrl = TextEditingController(text: widget.line.qualityDeduction > 0 ? widget.line.qualityDeduction.toString() : '');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _rateCtrl.dispose(); _qtyCtrl.dispose();
    _bagsCtrl.dispose(); _weightCtrl.dispose(); _qualCtrl.dispose();
    _searchController.dispose();
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

  void _showProductDropdown(BuildContext context) {
    setState(() => _showDropdown = true);
    final controller = Provider.of<PurchaseController>(context, listen: false);
    if (controller.availableProducts.isEmpty && !controller.loadingProducts) {
      controller.fetchProducts();
    }
  }

  void _hideDropdown() => setState(() => _showDropdown = false);

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _showDropdown = true;
      _visibleCount = _initialVisibleCount;
      final controller = Provider.of<PurchaseController>(context, listen: false);
      if (query.isEmpty) {
        _filteredProducts = List.from(controller.availableProducts);
      } else {
        _filteredProducts = controller.availableProducts
            .where((p) => p.productName.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final isKg = widget.line.pricingType == 'kg';
    final isFlat = widget.line.pricingType == 'flat';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(lang.t('product_line'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontFamily: 'Poppins')),
          if (widget.canRemove) GestureDetector(onTap: widget.onRemove, child: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 18)),
        ]),
        const SizedBox(height: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lang.t('product_name'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Poppins')),
          const SizedBox(height: 4),
          TextFormField(
            controller: _searchController,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Poppins'),
            decoration: InputDecoration(
              hintText: lang.t('search_products'),
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 18),
              suffixIcon: _nameCtrl.text.isNotEmpty ? GestureDetector(onTap: () { _searchController.clear(); _nameCtrl.clear(); _update(); _hideDropdown(); }, child: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18)) : null,
              filled: true, fillColor: AppColors.surfaceVariant,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            ),
            onTap: () => _showProductDropdown(context),
            onChanged: (_) => _showProductDropdown(context),
          ),
          if (_showDropdown)
            Consumer<PurchaseController>(
              builder: (context, controller, child) {
                if (_filteredProducts.isEmpty && controller.availableProducts.isNotEmpty) {
                  _filteredProducts = List.from(controller.availableProducts);
                }
                return Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: _filteredProducts.isEmpty
                      ? const Padding(padding: EdgeInsets.all(14), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                      : Column(children: _filteredProducts.take(_visibleCount).map((p) => InkWell(
                          onTap: () { _nameCtrl.text = p.productName; _update(); controller.onProductSelected(p, widget.line.id); _hideDropdown(); },
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(children: [
                              Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
                                child: Center(child: Text(p.productName.isNotEmpty ? p.productName[0].toUpperCase() : '?', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14)))),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(p.productName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                                if (p.description.isNotEmpty) Text(p.description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Poppins'), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ])),
                            ]),
                          ),
                        )).toList()),
                );
              },
            ),
        ]),
        const SizedBox(height: 10),
        Text(lang.t('pricing_type'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6,
          children: _pricingTypes.map((pt) {
            final selected = widget.line.pricingType == pt.$1;
            return GestureDetector(
              onTap: () {
                if (pt.$1 != widget.line.pricingType) {
                  _qtyCtrl.clear(); _bagsCtrl.clear(); _weightCtrl.clear(); _qualCtrl.clear();
                }
                widget.onChanged(widget.line.copyWith(pricingType: pt.$1, productName: _nameCtrl.text, rate: double.tryParse(_rateCtrl.text) ?? 0, actualQty: 0, bags: 0, weightPerBag: 0, qualityDeduction: 0));
              },
              child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: selected ? AppColors.primary : AppColors.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? AppColors.primary : AppColors.border)),
                child: Text(pt.$2, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (isKg) ...[
          Row(children: [
            Expanded(child: _inputField(ctrl: _bagsCtrl, label: 'Bags', hint: '0', icon: Icons.inventory_2_outlined, inputType: TextInputType.number, onChanged: (_) => _update())),
            const SizedBox(width: 10),
            Expanded(child: _inputField(ctrl: _weightCtrl, label: 'kg / Bag', hint: '0.0', icon: Icons.scale_outlined, inputType: TextInputType.number, onChanged: (_) => _update())),
          ]),
          const SizedBox(height: 8),
          if ((double.tryParse(_bagsCtrl.text) ?? 0) > 0 && (double.tryParse(_weightCtrl.text) ?? 0) > 0)
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
              child: Text('Gross qty: ${widget.line.grossQty.toStringAsFixed(2)} kg', style: const TextStyle(color: AppColors.primaryDark, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500))),
        ] else if (!isFlat) ...[
          _inputField(ctrl: _qtyCtrl, label: 'Quantity (${widget.line.unit})', hint: '0', icon: Icons.straighten_outlined, inputType: TextInputType.number, onChanged: (_) => _update()),
        ],
        if (!isFlat) ...[
          const SizedBox(height: 10),
          _inputField(ctrl: _qualCtrl, label: 'Quality Deduction (${widget.line.unit})', hint: '0', icon: Icons.remove_circle_outline, inputType: TextInputType.number, onChanged: (_) => _update()),
        ],
        const SizedBox(height: 10),
        _inputField(ctrl: _rateCtrl, label: isFlat ? 'Fixed Price (₹) *' : 'Rate per ${widget.line.unit} (₹) *', hint: '0.00', icon: Icons.currency_rupee_rounded, inputType: TextInputType.number, onChanged: (_) => _update()),
        if (widget.line.lineTotal > 0) ...[
          const SizedBox(height: 10),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Line Total', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Poppins')),
            Text('₹${widget.line.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark, fontFamily: 'Poppins')),
          ]),
        ],
      ]),
    );
  }

  Widget _inputField({required TextEditingController ctrl, required String label, required String hint, required IconData icon, TextInputType inputType = TextInputType.text, required ValueChanged<String> onChanged}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Poppins')),
      const SizedBox(height: 4),
      TextFormField(controller: ctrl, keyboardType: inputType, inputFormatters: inputType == TextInputType.number ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null, onChanged: onChanged,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Poppins'),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13), prefixIcon: Icon(icon, color: AppColors.textHint, size: 18),
          filled: true, fillColor: AppColors.surface, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    ]);
  }
}

// ── Deduction Field ───────────────────────────────────────────
class _DeductionField extends StatefulWidget {
  final String label; final IconData icon; final double value; final String? hint; final ValueChanged<double> onChanged;
  const _DeductionField({required this.label, required this.icon, required this.value, this.hint, required this.onChanged});
  @override State<_DeductionField> createState() => _DeductionFieldState();
}

class _DeductionFieldState extends State<_DeductionField> {
  late final TextEditingController _ctrl;
  bool _hasFocus = false;
  @override void initState() { super.initState(); _ctrl = TextEditingController(text: widget.value > 0 ? widget.value.toStringAsFixed(2) : ''); }
  @override void didUpdateWidget(_DeductionField old) { super.didUpdateWidget(old); if (!_hasFocus && old.value != widget.value) { _ctrl.text = widget.value > 0 ? widget.value.toStringAsFixed(2) : ''; } }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
    Icon(widget.icon, color: AppColors.textHint, size: 18), const SizedBox(width: 10),
    Expanded(flex: 2, child: Text(widget.label, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Poppins'))),
    Expanded(flex: 2, child: Focus(onFocusChange: (focused) => setState(() => _hasFocus = focused),
      child: TextFormField(controller: _ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        onChanged: (v) => widget.onChanged(double.tryParse(v) ?? 0), textAlign: TextAlign.right,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        decoration: InputDecoration(hintText: widget.hint ?? '0', hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12), prefixText: '₹ ', prefixStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontFamily: 'Poppins'),
          filled: true, fillColor: AppColors.surfaceVariant, contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    )),
  ]));
}

// ── Commission Field ──────────────────────────────────────────
class _CommissionField extends StatelessWidget {
  final double value; final String type; final double grossTotal;
  final ValueChanged<double> onValueChanged; final ValueChanged<String> onTypeChanged;
  const _CommissionField({required this.value, required this.type, required this.grossTotal, required this.onValueChanged, required this.onTypeChanged});
  @override Widget build(BuildContext context) {
    final commAmt = type == 'percent' ? (value / 100) * grossTotal : value;
    final ctrl = TextEditingController(text: value > 0 ? value.toStringAsFixed(type == 'percent' ? 1 : 2) : '');
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.handshake_outlined, color: AppColors.textHint, size: 18), const SizedBox(width: 10),
        const Expanded(child: Text('Commission', style: TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Poppins'))),
        Container(decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _toggleChip('₹', type == 'fixed', () => onTypeChanged('fixed')),
            _toggleChip('%', type == 'percent', () => onTypeChanged('percent')),
          ]),
        ),
        const SizedBox(width: 8),
        SizedBox(width: 90, child: TextFormField(controller: ctrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          onChanged: (v) => onValueChanged(double.tryParse(v) ?? 0), textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
          decoration: InputDecoration(hintText: '0', hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 12), suffixText: type == 'percent' ? '%' : '₹',
            suffixStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins'), filled: true, fillColor: AppColors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        )),
      ]),
      if (type == 'percent' && commAmt > 0) Padding(padding: const EdgeInsets.only(left: 28, top: 4), child: Text('= ₹${commAmt.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.textHint, fontSize: 11, fontFamily: 'Poppins'))),
    ]));
  }
  Widget _toggleChip(String label, bool active, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: active ? AppColors.primary : Colors.transparent, borderRadius: BorderRadius.circular(6)),
    child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
  ));
}

// ── Final Payable Card ────────────────────────────────────────
class _FinalPayableCard extends StatelessWidget {
  final double grossTotal; final double totalDeductions; final double finalPayable;
  const _FinalPayableCard({required this.grossTotal, required this.totalDeductions, required this.finalPayable});
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Gross Total', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')), Text('₹${grossTotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w600))]),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Deductions', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins')), Text('- ₹${totalDeductions.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Poppins', fontWeight: FontWeight.w600))]),
      const SizedBox(height: 8), const Divider(color: Colors.white30), const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Final Payable', style: TextStyle(color: Colors.white, fontSize: 15, fontFamily: 'Poppins', fontWeight: FontWeight.w600)), Text('₹${finalPayable.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 22, fontFamily: 'Poppins', fontWeight: FontWeight.w700))]),
    ]),
  );
}

// ── Summary Line Row ──────────────────────────────────────────
class _SummaryLineRow extends StatelessWidget {
  final PurchaseLine line; final ValueChanged<bool> onRateLockToggle;
  const _SummaryLineRow({required this.line, required this.onRateLockToggle});
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(line.productName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Poppins'))),
        GestureDetector(onTap: () => onRateLockToggle(!line.rateLocked),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: line.rateLocked ? AppColors.warningSurface : AppColors.successSurface, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: line.rateLocked ? AppColors.warning : AppColors.success)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(line.rateLocked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 12, color: line.rateLocked ? AppColors.warning : AppColors.success),
              const SizedBox(width: 4),
              Text(line.rateLocked ? 'Rate Locked' : 'Lock Rate', style: TextStyle(fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: line.rateLocked ? AppColors.warning : AppColors.success)),
            ]),
          ),
        ),
      ]),
      const SizedBox(height: 6),
      Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        _chip('${line.pricingType.toUpperCase()}'),
        _chip('${line.billedQty.toStringAsFixed(2)} ${line.unit}'),
        _chip('₹${line.rate.toStringAsFixed(2)}/${line.unit}'),
        Text('₹${line.lineTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryDark, fontFamily: 'Poppins')),
      ]),
    ]),
  );
  Widget _chip(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: const TextStyle(fontSize: 10, color: AppColors.primaryDark, fontFamily: 'Poppins', fontWeight: FontWeight.w500)));
}