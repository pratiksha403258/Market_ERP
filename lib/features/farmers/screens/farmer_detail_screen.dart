import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../models/farmer_model.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';

class FarmerDetailScreen extends StatefulWidget {
  final String farmerId;
  final String farmerName;

  const FarmerDetailScreen({
    super.key,
    required this.farmerId,
    required this.farmerName,
  });

  @override
  State<FarmerDetailScreen> createState() => _FarmerDetailScreenState();
}

class _FarmerDetailScreenState extends State<FarmerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  FarmerModel? _farmer;
  bool _loadingFarmer = true;
  String? _farmerError;

  List<Map<String, dynamic>> _dues = [];
  bool _loadingDues = false;

  List<Map<String, dynamic>> _advances = [];
  bool _loadingAdvances = false;

  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadFarmer();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 1:
        if (_dues.isEmpty) _loadDues();
        break;
      case 2:
        if (_advances.isEmpty) _loadAdvances();
        break;
    }
  }

  // ── FIXED: _loadFarmer ────────────────────────────────────────
  // Backend response shape:
  //   { success: true, data: { farmer: { _id, name, mobile, ... ,
  //     totalPurchases, totalPaid, pendingDues, advanceBalance } } }
  Future<void> _loadFarmer() async {
    setState(() {
      _loadingFarmer = true;
      _farmerError = null;
    });

    try {
      final url = ApiRoutes.farmerById(widget.farmerId);
      debugPrint('📡 [loadFarmer] GET $url');

      final res = await DioClient.instance.dio.get(
        url,
        options: Options(validateStatus: (s) => true),
      );

      debugPrint('📥 [loadFarmer] status=${res.statusCode}');
      debugPrint('📥 [loadFarmer] body=${res.data}');

      if (res.statusCode == 200) {
        final body = res.data as Map<String, dynamic>;

        // ── Step 1: find the raw farmer map ──────────────────
        Map<String, dynamic>? rawFarmer;

        // Pattern A: { success, data: { farmer: {...} } }
        if (body['data'] is Map<String, dynamic>) {
          final data = body['data'] as Map<String, dynamic>;
          if (data['farmer'] is Map<String, dynamic>) {
            rawFarmer = data['farmer'] as Map<String, dynamic>;
            debugPrint('✅ [loadFarmer] found via body.data.farmer');
          } else {
            // Pattern B: { success, data: { _id, name, ... } }
            rawFarmer = data;
            debugPrint('✅ [loadFarmer] found via body.data (flat)');
          }
        }
        // Pattern C: { farmer: {...} }
        else if (body['farmer'] is Map<String, dynamic>) {
          rawFarmer = body['farmer'] as Map<String, dynamic>;
          debugPrint('✅ [loadFarmer] found via body.farmer');
        }
        // Pattern D: { _id, name, ... } (farmer object at root)
        else if (body.containsKey('_id') || body.containsKey('name')) {
          rawFarmer = body;
          debugPrint('✅ [loadFarmer] found at root');
        }

        if (rawFarmer == null) {
          throw Exception('Farmer data not found in response: $body');
        }

        debugPrint('🧪 [loadFarmer] rawFarmer keys: ${rawFarmer.keys.toList()}');
        debugPrint('🧪 [loadFarmer] totalPurchases=${rawFarmer['totalPurchases']}');
        debugPrint('🧪 [loadFarmer] totalPaid=${rawFarmer['totalPaid']}');
        debugPrint('🧪 [loadFarmer] pendingDues=${rawFarmer['pendingDues']}');
        debugPrint('🧪 [loadFarmer] advanceBalance=${rawFarmer['advanceBalance']}');

        // ── Step 2: parse into FarmerModel ───────────────────
        final farmer = FarmerModel.fromJson(rawFarmer);
        farmer.debugPrint();

        setState(() => _farmer = farmer);
      } else {
        final errMsg = _extractError(res.data) ?? 'Failed to load farmer (${res.statusCode})';
        setState(() => _farmerError = errMsg);
        _showError(errMsg);
      }
    } catch (e, st) {
      debugPrint('❌ [loadFarmer] exception: $e\n$st');
      final msg = 'Failed to load farmer: $e';
      setState(() => _farmerError = msg);
      _showError(msg);
    } finally {
      setState(() => _loadingFarmer = false);
    }
  }

  // ── _loadAdvances ─────────────────────────────────────────────
  Future<void> _loadAdvances() async {
    setState(() => _loadingAdvances = true);
    try {
      final url =
          '${ApiRoutes.farmerById(widget.farmerId)}/advance?page=1&limit=50';
      debugPrint('📡 [loadAdvances] GET $url');

      final res = await DioClient.instance.dio.get(
        url,
        options: Options(validateStatus: (s) => true),
      );

      debugPrint('📥 [loadAdvances] status=${res.statusCode}');

      if (res.statusCode == 200) {
        final body = res.data as Map<String, dynamic>;
        List<Map<String, dynamic>> transactions = [];

        // Pattern A: { data: { transactions: [...] } }
        if (body['data'] is Map<String, dynamic>) {
          final inner = body['data'] as Map<String, dynamic>;
          if (inner['transactions'] is List) {
            transactions = (inner['transactions'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          } else if (inner['advances'] is List) {
            transactions = (inner['advances'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          }
        }
        // Pattern B: { transactions: [...] }
        else if (body['transactions'] is List) {
          transactions = (body['transactions'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
        // Pattern C: { data: [...] }
        else if (body['data'] is List) {
          transactions = (body['data'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }

        setState(() => _advances = transactions);
        debugPrint('✅ [loadAdvances] count=${transactions.length}');
      } else {
        _showError('Failed to load advances (${res.statusCode})');
      }
    } catch (e, st) {
      debugPrint('❌ [loadAdvances] $e\n$st');
      _showError('Failed to load advances: $e');
    } finally {
      setState(() => _loadingAdvances = false);
    }
  }

  // ── _loadDues ─────────────────────────────────────────────────
  Future<void> _loadDues() async {
    setState(() => _loadingDues = true);
    try {
      final url = '${ApiRoutes.farmerById(widget.farmerId)}/dues';
      debugPrint('📡 [loadDues] GET $url');

      final res = await DioClient.instance.dio.get(
        url,
        options: Options(validateStatus: (s) => true),
      );

      debugPrint('📥 [loadDues] status=${res.statusCode}');

      if (res.statusCode == 200) {
        final body = res.data as Map<String, dynamic>;
        List<Map<String, dynamic>> pendingPurchases = [];

        // Pattern A: { data: { pendingPurchases: [...] } }
        if (body['data'] is Map<String, dynamic>) {
          final inner = body['data'] as Map<String, dynamic>;
          if (inner['pendingPurchases'] is List) {
            pendingPurchases = (inner['pendingPurchases'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          } else if (inner['dues'] is List) {
            pendingPurchases = (inner['dues'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          } else if (inner['purchases'] is List) {
            pendingPurchases = (inner['purchases'] as List)
                .map((e) => e as Map<String, dynamic>)
                .toList();
          }
        }
        // Pattern B: { pendingPurchases: [...] }
        else if (body['pendingPurchases'] is List) {
          pendingPurchases = (body['pendingPurchases'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }
        // Pattern C: { data: [...] }
        else if (body['data'] is List) {
          pendingPurchases = (body['data'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
        }

        setState(() => _dues = pendingPurchases);
        debugPrint('✅ [loadDues] count=${pendingPurchases.length}');
      } else {
        _showError('Failed to load dues (${res.statusCode})');
      }
    } catch (e, st) {
      debugPrint('❌ [loadDues] $e\n$st');
      _showError('Failed to load dues: $e');
    } finally {
      setState(() => _loadingDues = false);
    }
  }

  // ── _giveAdvance ──────────────────────────────────────────────
  Future<void> _giveAdvance(double amount, String note) async {
    try {
      final url = '${ApiRoutes.farmerById(widget.farmerId)}/advance';
      final payload = {
        'amount': amount,
        'paymentMode': 'cash',
        'notes': note,
      };

      debugPrint('📡 [giveAdvance] POST $url');

      final res = await DioClient.instance.dio.post(
        url,
        data: payload,
        options: Options(validateStatus: (s) => true),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _changed = true;
        await _loadFarmer();
        _advances.clear();
        await _loadAdvances();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Advance given successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ));
        }
      } else {
        _showError('Failed to give advance (${res.statusCode}): ${_extractError(res.data)}');
      }
    } catch (e, st) {
      debugPrint('❌ [giveAdvance] $e\n$st');
      _showError('Failed to give advance: $e');
    }
  }

  // ── _deactivateFarmer ─────────────────────────────────────────
  Future<void> _deactivateFarmer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Deactivate Farmer?',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        content: Text(
          'This will deactivate ${_farmer?.name ?? 'this farmer'}. '
          'They will no longer appear in active purchase flows.',
          style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Deactivate',
                style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final url = '${ApiRoutes.farmerById(widget.farmerId)}/deactivate';
      final res = await DioClient.instance.dio.patch(
        url,
        options: Options(validateStatus: (s) => true),
      );

      if (res.statusCode == 200) {
        _changed = true;
        await _loadFarmer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Farmer deactivated'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      } else {
        _showError('Failed to deactivate (${res.statusCode})');
      }
    } catch (e) {
      _showError('Failed to deactivate: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Edit sheet ────────────────────────────────────────────────
  void _showEditSheet() {
    if (_farmer == null) {
      _showError('Farmer data not loaded yet');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditFarmerSheet(
        farmer: _farmer!,
        onSave: (updates) async {
          try {
            final url = ApiRoutes.farmerById(widget.farmerId);
            debugPrint('📡 [editFarmer] PUT $url data=$updates');

            final res = await DioClient.instance.dio.put(
              url,
              data: updates,
              options: Options(validateStatus: (s) => true),
            );

            debugPrint('📥 [editFarmer] status=${res.statusCode}');

            if (res.statusCode == 200) {
              _changed = true;
              if (mounted) Navigator.pop(context);
              await _loadFarmer();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Farmer updated successfully'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ));
              }
            } else {
              _showError(
                  'Failed to update farmer (${res.statusCode}): ${_extractError(res.data)}');
            }
          } catch (e) {
            _showError('Failed to update farmer: $e');
          }
        },
      ),
    );
  }

  void _showAdvanceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GiveAdvanceSheet(
        farmerName: _farmer?.name ?? '',
        currentBalance: _farmer?.advanceBalance ?? 0,
        onGive: _giveAdvance,
      ),
    );
  }

  String? _extractError(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    return null;
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            _buildSliverAppBar(innerBoxIsScrolled),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(
                farmer: _farmer,
                loading: _loadingFarmer,
                error: _farmerError,
                onEdit: _showEditSheet,
                onDeactivate: _deactivateFarmer,
                onGiveAdvance: _showAdvanceSheet,
                onRetry: _loadFarmer,
              ),
              _DuesTab(dues: _dues, loading: _loadingDues),
              _AdvanceTab(
                advances: _advances,
                loading: _loadingAdvances,
                currentBalance: _farmer?.advanceBalance ?? 0,
                onGiveAdvance: _showAdvanceSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

Widget _buildSliverAppBar(bool innerBoxIsScrolled) {
  final farmer = _farmer;
  return SliverAppBar(
    expandedHeight: 200,
    pinned: true,
    backgroundColor: AppColors.primary,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      onPressed: () => Navigator.pop(context, _changed),
    ),
    actions: [
      if (farmer != null && farmer.isActive)
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (v) {
            if (v == 'edit') _showEditSheet();
            if (v == 'deactivate') _deactivateFarmer();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(children: [
                Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textPrimary),
                SizedBox(width: 10),
                Text('Edit Farmer',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              ]),
            ),
            const PopupMenuItem(
              value: 'deactivate',
              child: Row(children: [
                Icon(Icons.block_rounded, size: 18, color: AppColors.error),
                SizedBox(width: 10),
                Text('Deactivate',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.error)),
              ]),
            ),
          ],
        ),
    ],
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: _loadingFarmer
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            farmer?.initials ?? '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Only showing the name now - removed mobile number and status badge
                      Text(
                        farmer?.name ?? widget.farmerName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins'),
                        textAlign: TextAlign.center,
                      ),
                      // Removed the Row with mobile number and status badge
                    ],
                  ),
                ),
        ),
      ),
    ),
    bottom: TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      indicatorColor: Colors.white,
      indicatorWeight: 2.5,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white60,
      labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          const TextStyle(fontFamily: 'Poppins', fontSize: 13),
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'Dues'),
        Tab(text: 'Advances'),
      ],
    ),
  );
}
}

// ─────────────────────────────────────────────────────────────
//  TAB 1 — OVERVIEW
// ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final FarmerModel? farmer;
  final bool loading;
  final String? error;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onGiveAdvance;
  final VoidCallback onRetry;

  const _OverviewTab({
    required this.farmer,
    required this.loading,
    this.error,
    required this.onEdit,
    required this.onDeactivate,
    required this.onGiveAdvance,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    // Show error with retry button
    if (farmer == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: AppColors.textHint),
              const SizedBox(height: 16),
              Text(
                error ?? 'Failed to load farmer details.',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontFamily: 'Poppins'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry',
                    style: TextStyle(fontFamily: 'Poppins')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Grid ───────────────────────────────────────
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _KpiTile(
                icon: Icons.shopping_bag_outlined,
                label: 'Total Purchases',
                value: _fmt(farmer!.totalPurchases),
                color: AppColors.primary,
              ),
              _KpiTile(
                icon: Icons.check_circle_outline_rounded,
                label: 'Total Paid',
                value: _fmt(farmer!.totalPaid),
                color: AppColors.success,
              ),
              _KpiTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Pending Dues',
                value: _fmt(farmer!.pendingDues),
                color: farmer!.hasPendingDues
                    ? AppColors.warning
                    : AppColors.success,
              ),
              _KpiTile(
                icon: Icons.currency_rupee_rounded,
                label: 'Advance Balance',
                value: _fmt(farmer!.advanceBalance),
                color: farmer!.hasAdvanceBalance
                    ? AppColors.info
                    : AppColors.textHint,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Give Advance button ─────────────────────────────
          if (farmer!.isActive)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onGiveAdvance,
                icon: const Icon(Icons.add_card_rounded, size: 18),
                label: const Text('Give Advance',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // ── Personal Info ───────────────────────────────────
          _SectionCard(
            title: 'Personal Information',
            icon: Icons.person_outline_rounded,
            children: [
              _InfoRow('Name', farmer!.name),
              _InfoRow('Mobile', farmer!.mobile),
              if (farmer!.village != null && farmer!.village!.isNotEmpty)
                _InfoRow('Village', farmer!.village!),
              if (farmer!.city != null && farmer!.city!.isNotEmpty)
                _InfoRow('City', farmer!.city!),
              if (farmer!.address != null && farmer!.address!.isNotEmpty)
                _InfoRow('Address', farmer!.address!),
            ],
          ),

          // ── Banking Details ─────────────────────────────────
          if (farmer!.bankAccountNumber != null ||
              farmer!.bankName != null ||
              farmer!.ifscCode != null ||
              farmer!.gstNumber != null) ...[
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Banking Details',
              icon: Icons.account_balance_outlined,
              children: [
                if (farmer!.bankName != null && farmer!.bankName!.isNotEmpty)
                  _InfoRow('Bank Name', farmer!.bankName!),
                if (farmer!.bankAccountNumber != null &&
                    farmer!.bankAccountNumber!.isNotEmpty)
                  _InfoRow('Account No.', farmer!.bankAccountNumber!),
                if (farmer!.ifscCode != null && farmer!.ifscCode!.isNotEmpty)
                  _InfoRow('IFSC Code', farmer!.ifscCode!),
                if (farmer!.gstNumber != null && farmer!.gstNumber!.isNotEmpty)
                  _InfoRow('GST Number', farmer!.gstNumber!),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // ── Action buttons ──────────────────────────────────
          if (farmer!.isActive)
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Details',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDeactivate,
                  icon: const Icon(Icons.block_rounded, size: 16),
                  label: const Text('Deactivate',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(2)}';
  }
}

// ─────────────────────────────────────────────────────────────
//  TAB 2 — DUES
// ─────────────────────────────────────────────────────────────

class _DuesTab extends StatelessWidget {
  final List<Map<String, dynamic>> dues;
  final bool loading;

  const _DuesTab({required this.dues, required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (dues.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 48, color: AppColors.success),
          SizedBox(height: 12),
          Text('No pending dues',
              style: TextStyle(
                  color: AppColors.textSecondary, fontFamily: 'Poppins')),
        ]),
      );
    }

    final totalDue = dues.fold<double>(
        0, (s, d) => s + ((d['amountDue'] as num?)?.toDouble() ?? 0));

    return Column(children: [
      Container(
        margin: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.warningSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total Pending',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: AppColors.warning)),
            Text('₹${totalDue.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning)),
          ],
        ),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: dues.length,
          itemBuilder: (context, i) {
            final d = dues[i];
            final receiptNo = d['receiptNumber']?.toString() ??
                d['purchaseId']?.toString() ??
                'Purchase #${i + 1}';
            final due = (d['amountDue'] as num?)?.toDouble() ??
                (d['dueAmount'] as num?)?.toDouble() ??
                0;
            final gross = (d['grossTotal'] as num?)?.toDouble() ??
                (d['finalPayable'] as num?)?.toDouble() ??
                (d['totalAmount'] as num?)?.toDouble() ??
                0;
            final date = _fmtDate(d['purchaseDate']?.toString() ??
                d['date']?.toString() ??
                d['createdAt']?.toString() ??
                '');

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(receiptNo,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'Poppins'),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('Due: ₹${due.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                              fontFamily: 'Poppins')),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('Total: ₹${gross.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Poppins')),
                    const SizedBox(width: 10),
                    Text(date,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                            fontFamily: 'Poppins')),
                  ]),
                ],
              ),
            );
          },
        ),
      ),
    ]);
  }

  String _fmtDate(String dateStr) {
    if (dateStr.isEmpty) return '—';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────
//  TAB 3 — ADVANCES
// ─────────────────────────────────────────────────────────────

class _AdvanceTab extends StatelessWidget {
  final List<Map<String, dynamic>> advances;
  final bool loading;
  final double currentBalance;
  final VoidCallback onGiveAdvance;

  const _AdvanceTab({
    required this.advances,
    required this.loading,
    required this.currentBalance,
    required this.onGiveAdvance,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Column(children: [
      Container(
        margin: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Current Balance',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 4),
              Text('₹${currentBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins')),
            ]),
            ElevatedButton.icon(
              onPressed: onGiveAdvance,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Give Advance',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      if (advances.isEmpty)
        const Expanded(
          child: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 48, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('No advance history',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Poppins')),
                ]),
          ),
        )
      else
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: advances.length,
            itemBuilder: (context, i) {
              final a = advances[i];
              final amount = (a['debit'] as num?)?.toDouble() ??
                  (a['amount'] as num?)?.toDouble() ??
                  0;
              final date = _fmtDate(a['entryDate']?.toString() ??
                  a['date']?.toString() ??
                  a['givenAt']?.toString() ??
                  a['createdAt']?.toString() ??
                  '');
              final note = a['description']?.toString() ??
                  a['note']?.toString() ??
                  a['notes']?.toString() ??
                  'Advance given';
              final status = a['entryType']?.toString() ??
                  a['status']?.toString() ??
                  'given';

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.infoSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.currency_rupee_rounded,
                        color: AppColors.info, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(note,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Poppins'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Row(children: [
                            Text(date,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                    fontFamily: 'Poppins')),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(status,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primaryDark,
                                      fontFamily: 'Poppins')),
                            ),
                          ]),
                        ]),
                  ),
                  Text('₹${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          fontFamily: 'Poppins')),
                ]),
              );
            },
          ),
        ),
    ]);
  }

  String _fmtDate(String dateStr) {
    if (dateStr.isEmpty) return '—';
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    return '${d.day}/${d.month}/${d.year}';
  }
}

// ─────────────────────────────────────────────────────────────
//  BOTTOM SHEET — GIVE ADVANCE
// ─────────────────────────────────────────────────────────────

class _GiveAdvanceSheet extends StatefulWidget {
  final String farmerName;
  final double currentBalance;
  final Future<void> Function(double amount, String note) onGive;

  const _GiveAdvanceSheet({
    required this.farmerName,
    required this.currentBalance,
    required this.onGive,
  });

  @override
  State<_GiveAdvanceSheet> createState() => _GiveAdvanceSheetState();
}

class _GiveAdvanceSheetState extends State<_GiveAdvanceSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid amount'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    await widget.onGive(amount, _noteCtrl.text.trim());
    if (mounted) {
      setState(() => _saving = false);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        Text('Give Advance — ${widget.farmerName}',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 4),
        Text('Current balance: ₹${widget.currentBalance.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary,
                fontFamily: 'Poppins')),
        const SizedBox(height: 20),
        const Text('Amount (₹) *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 6),
        TextFormField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
          autofocus: true,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary, fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '₹ ',
            prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                color: AppColors.textSecondary),
            filled: true, fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Note (optional)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 6),
        TextFormField(
          controller: _noteCtrl,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary,
              fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: 'e.g. Festival advance, seed purchase...',
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
            filled: true, fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : const Text('Confirm Advance',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins')),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  BOTTOM SHEET — EDIT FARMER
//  FIXED: controllers now initialized correctly from farmer object
// ─────────────────────────────────────────────────────────────

class _EditFarmerSheet extends StatefulWidget {
  final FarmerModel farmer;
  final Future<void> Function(Map<String, dynamic> updates) onSave;

  const _EditFarmerSheet({required this.farmer, required this.onSave});

  @override
  State<_EditFarmerSheet> createState() => _EditFarmerSheetState();
}

class _EditFarmerSheetState extends State<_EditFarmerSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _villageCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _bankAccCtrl;
  late final TextEditingController _ifscCtrl;
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final f = widget.farmer;

    // ── FIXED: use null-safe getters so fields are pre-filled ──
    _nameCtrl = TextEditingController(text: f.name);
    _mobileCtrl = TextEditingController(text: f.mobile);
    _villageCtrl = TextEditingController(text: f.village ?? '');
    _cityCtrl = TextEditingController(text: f.city ?? '');
    _addressCtrl = TextEditingController(text: f.address ?? '');
    _bankAccCtrl =
        TextEditingController(text: f.bankAccountNumber ?? '');
    _ifscCtrl = TextEditingController(text: f.ifscCode ?? '');
    _bankNameCtrl = TextEditingController(text: f.bankName ?? '');

    debugPrint('🖊️ [EditSheet] Initializing with farmer: '
        'name=${f.name} mobile=${f.mobile} '
        'village=${f.village} city=${f.city} '
        'bank=${f.bankName} ifsc=${f.ifscCode}');
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _mobileCtrl, _villageCtrl, _cityCtrl,
      _addressCtrl, _bankAccCtrl, _ifscCtrl, _bankNameCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Name is required');
      return;
    }
    if (_mobileCtrl.text.trim().length != 10) {
      _snack('Enter valid 10-digit mobile number');
      return;
    }

    setState(() => _saving = true);

    final updates = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'mobile': _mobileCtrl.text.trim(),
      if (_villageCtrl.text.trim().isNotEmpty)
        'village': _villageCtrl.text.trim(),
      if (_cityCtrl.text.trim().isNotEmpty)
        'city': _cityCtrl.text.trim(),
      if (_addressCtrl.text.trim().isNotEmpty)
        'address': _addressCtrl.text.trim(),
      if (_bankAccCtrl.text.trim().isNotEmpty)
        'bankAccountNumber': _bankAccCtrl.text.trim(),
      if (_ifscCtrl.text.trim().isNotEmpty)
        'ifscCode': _ifscCtrl.text.trim().toUpperCase(),
      if (_bankNameCtrl.text.trim().isNotEmpty)
        'bankName': _bankNameCtrl.text.trim(),
    };

    debugPrint('📤 [EditSheet] Submitting updates: $updates');
    await widget.onSave(updates);
    setState(() => _saving = false);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      margin:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Center(
          child: Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2)),
          ),
        ),
        const Text('Edit Farmer',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _field('Farmer Name *', _nameCtrl,
                  caps: TextCapitalization.words),
              _field('Mobile Number *', _mobileCtrl,
                  inputType: TextInputType.phone,
                  formatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 10),
              _field('Village', _villageCtrl,
                  caps: TextCapitalization.words),
              _field('City', _cityCtrl, caps: TextCapitalization.words),
              _field('Address', _addressCtrl,
                  caps: TextCapitalization.sentences),
              _field('Bank Account Number', _bankAccCtrl,
                  inputType: TextInputType.number,
                  formatters: [FilteringTextInputFormatter.digitsOnly]),
              _field('IFSC Code', _ifscCtrl,
                  caps: TextCapitalization.characters, maxLength: 11),
              _field('Bank Name', _bankNameCtrl,
                  caps: TextCapitalization.words),
              const SizedBox(height: 8),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _saving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _saving
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text('Save Changes',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins')),
          ),
        ),
      ]),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    TextCapitalization caps = TextCapitalization.none,
    TextInputType inputType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
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
        inputFormatters: formatters,
        maxLength: maxLength,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary,
            fontFamily: 'Poppins'),
        decoration: InputDecoration(
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
          filled: true, fillColor: AppColors.surfaceVariant,
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
      const SizedBox(height: 10),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────

class _KpiTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: color, fontFamily: 'Poppins')),
            Text(label,
                style: const TextStyle(fontSize: 11,
                    color: AppColors.textSecondary, fontFamily: 'Poppins')),
          ]),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard(
      {required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, fontFamily: 'Poppins')),
        ]),
        const SizedBox(height: 12),
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 12,
                    color: AppColors.textSecondary, fontFamily: 'Poppins')),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}