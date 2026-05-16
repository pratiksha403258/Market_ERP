import 'package:agr_market/expense/add_expense_screen.dart';
import 'package:agr_market/expense/edit_expense_screen.dart';
import 'package:agr_market/services/expense_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final List<ExpenseModel> _expenses = [];
  ExpenseSummaryResponse? _summary;
  bool _loading = false;
  bool _summaryLoading = false;
  bool _hasMore = true;
  int _page = 1;

  String _statusFilter = 'all';    // 'all', 'created', 'cancelled'
  String _categoryFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _searchQuery = '';

  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetchExpenses(reset: true);
    _fetchSummary();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
        !_loading && _hasMore) {
      _fetchExpenses();
    }
  }

  Future<void> _fetchExpenses({bool reset = false}) async {
    if (_loading) return;
    if (reset) {
      setState(() {
        _expenses.clear();
        _page = 1;
        _hasMore = true;
      });
    }
    if (!_hasMore && !reset) return;

    setState(() => _loading = true);

    final result = await ExpenseService.instance.getExpenses(
      page: _page,
      limit: 20,
      category: _categoryFilter == 'all' ? null : _categoryFilter,
      status: _statusFilter == 'all' ? null : _statusFilter,
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() => _loading = false);

    if (result.isSuccess && result.data != null) {
      setState(() {
        _expenses.addAll(result.data!.expenses);
        _page++;
        _hasMore = _page <= result.data!.totalPages;
      });
    } else if (mounted) {
      _snack(result.message ?? 'Failed to load expenses', isError: true);
    }
  }

  Future<void> _fetchSummary() async {
    setState(() => _summaryLoading = true);
    final result = await ExpenseService.instance.getSummary(
      startDate: _startDate,
      endDate: _endDate,
    );
    setState(() => _summaryLoading = false);
    if (result.isSuccess) setState(() => _summary = result.data);
  }

  Future<void> _refresh() async {
    await Future.wait([
      _fetchExpenses(reset: true),
      _fetchSummary(),
    ]);
  }

  Future<void> _cancelExpense(ExpenseModel expense) async {
    final reason = await _showReasonDialog('Cancel Expense', 'Cancel Reason');
    if (reason == null) return;
    final result = await ExpenseService.instance.cancelExpense(expense.id, reason: reason);
    if (result.isSuccess) {
      _snack('Expense cancelled', isError: false);
      _refresh();
    } else {
      _snack(result.message ?? 'Cancel failed', isError: true);
    }
  }

  Future<String?> _showReasonDialog(String title, String hint) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'Poppins', color: AppColors.textHint),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context, ctrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
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
      _refresh();
    }
  }

  List<ExpenseModel> get _filtered {
    if (_searchQuery.isEmpty) return _expenses;
    final q = _searchQuery.toLowerCase();
    return _expenses.where((e) =>
        e.description.toLowerCase().contains(q) ||
        e.categoryLabel.toLowerCase().contains(q) ||
        e.paidTo.toLowerCase().contains(q)).toList();
  }

  String _fmtAmount(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d.toLocal());

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(left: 6, right: 6, bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (added == true) _refresh();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(children: [
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.34,
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.receipt_outlined, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Text('Expenses', style: TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                    const Spacer(),
                    GestureDetector(
                      onTap: _pickDateRange,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.date_range_rounded, color: Colors.white, size: 15),
                          const SizedBox(width: 5),
                          Text(
                            _startDate != null
                                ? '${DateFormat('dd/MM').format(_startDate!)} – ${DateFormat('dd/MM').format(_endDate!)}'
                                : 'Date',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'Poppins'),
                          ),
                          if (_startDate != null) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _startDate = null;
                                  _endDate = null;
                                });
                                _refresh();
                              },
                              child: const Icon(Icons.close_rounded, color: Colors.white70, size: 13),
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSummaryRow(),
                ]),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: AppColors.primary.withOpacity(0.10),
                        blurRadius: 24, offset: const Offset(0, 6),
                      )],
                    ),
                    child: Column(children: [
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search by description or category...',
                          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textHint),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(Icons.close_rounded, color: AppColors.textHint, size: 18),
                                )
                              : null,
                          filled: true, fillColor: AppColors.surfaceVariant,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _StatusChip(label: 'All', value: 'all', active: _statusFilter == 'all', onTap: () => _setStatus('all')),
                            const SizedBox(width: 6),
                            _StatusChip(label: 'Created', value: 'created', active: _statusFilter == 'created', color: AppColors.primary, bg: AppColors.primarySurface, onTap: () => _setStatus('created')),
                            const SizedBox(width: 6),
                            _StatusChip(label: 'Cancelled', value: 'cancelled', active: _statusFilter == 'cancelled', color: AppColors.textHint, bg: AppColors.surfaceVariant, onTap: () => _setStatus('cancelled')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _categoryFilter,
                            isExpanded: true,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _categoryFilter = v);
                                _fetchExpenses(reset: true);
                              }
                            },
                            items: [
                              const DropdownMenuItem(value: 'all',
                                  child: Text('All Categories', style: TextStyle(fontFamily: 'Poppins'))),
                              ...ExpenseCategory.all.map((c) => DropdownMenuItem(
                                value: c['value']!,
                                child: Text(c['label']!, style: const TextStyle(fontFamily: 'Poppins')),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                if (!_loading && _filtered.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyState())
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          if (i == _filtered.length) {
                            return _loading
                                ? const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
                                  )
                                : const SizedBox(height: 100);
                          }
                          return _ExpenseCard(
                            expense: _filtered[i],
                            fmtAmount: _fmtAmount,
                            fmtDate: _fmtDate,
                            onCancel: () => _cancelExpense(_filtered[i]),
                            onEdit: () => _openEditScreen(_filtered[i]),
                            onTap: () => _showDetail(_filtered[i]),
                          );
                        },
                        childCount: _filtered.length + 1,
                      ),
                    ),
                  ),
                if (_loading && _expenses.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => _buildShimmer(),
                        childCount: 5,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  void _setStatus(String s) {
    if (_statusFilter == s) return;
    setState(() => _statusFilter = s);
    _fetchExpenses(reset: true);
  }

  Widget _buildSummaryRow() {
    if (_summaryLoading) {
      return Row(children: List.generate(3, (_) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      )));
    }

    final grandTotal = _summary?.grandTotal ?? 0;
    final topCategory = (_summary?.byCategory.isNotEmpty == true)
        ? _summary!.byCategory.reduce((a, b) => a.total > b.total ? a : b)
        : null;
    final createdCount = _expenses.where((e) => e.isCreated).length;

    return Row(children: [
      _SummaryBadge(
        label: 'Total Expenses',
        value: _fmtAmount(grandTotal),
        icon: Icons.attach_money_rounded,
      ),
      const SizedBox(width: 8),
      _SummaryBadge(
        label: topCategory != null ? topCategory.label : 'Top Category',
        value: topCategory != null ? _fmtAmount(topCategory.total) : '₹0',
        icon: Icons.category_outlined,
      ),
      const SizedBox(width: 8),
      _SummaryBadge(
        label: 'Created',
        value: '$createdCount expenses',
        icon: Icons.create_rounded,
        isWarning: createdCount > 0,
      ),
    ]);
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
          child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 34),
        ),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty ? 'No expenses match "$_searchQuery"' :
          _statusFilter != 'all' ? 'No $_statusFilter expenses' : 'No expenses yet',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15,
              fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text('Tap + to log a new expense', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _buildShimmer() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    height: 100,
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
  );

  void _openEditScreen(ExpenseModel expense) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditExpenseScreen(expense: expense)),
    );
    if (updated == true) _refresh();
  }

  void _showDetail(ExpenseModel expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExpenseDetailSheet(
        expense: expense,
        fmtAmount: _fmtAmount,
        fmtDate: _fmtDate,
        onCancel: expense.canCancel ? () { Navigator.pop(context); _cancelExpense(expense); } : null,
        onEdit: () { Navigator.pop(context); _openEditScreen(expense); },
      ),
    );
  }
}

// ── Summary Badge ─────────────────────────────────────────────
class _SummaryBadge extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isWarning;
  const _SummaryBadge({required this.label, required this.value, required this.icon, this.isWarning = false});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: isWarning ? Colors.orangeAccent : Colors.white70, size: 12),
          const SizedBox(width: 4),
          Flexible(child: Text(label, style: TextStyle(color: isWarning ? Colors.orangeAccent : Colors.white70,
              fontSize: 9, fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13,
            fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
            overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

// ── Status Chip ───────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final Color? color;
  final Color? bg;
  final VoidCallback onTap;

  const _StatusChip({required this.label, required this.value, required this.active,
    required this.onTap, this.color, this.bg});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    final b = bg ?? AppColors.primarySurface;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? c : b,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? c : AppColors.border, width: 1.5),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : c,
            fontSize: 12, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Expense Card (with Edit & Cancel, no Approve/Reject) ─────────
class _ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String Function(double) fmtAmount;
  final String Function(DateTime) fmtDate;
  final VoidCallback onCancel;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _ExpenseCard({
    required this.expense, required this.fmtAmount, required this.fmtDate,
    required this.onCancel, required this.onEdit, required this.onTap,
  });

  Color get _statusColor => expense.isCreated ? AppColors.primary : AppColors.textHint;
  Color get _statusBg => expense.isCreated ? AppColors.primarySurface : AppColors.surfaceVariant;
  String get _statusLabel => expense.isCreated ? 'Created' : 'Cancelled';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(expense.description,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary, fontFamily: 'Poppins'),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(expense.categoryLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary,
                        fontFamily: 'Poppins')),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(fmtAmount(expense.amount),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, fontFamily: 'Poppins')),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel, style: TextStyle(color: _statusColor,
                    fontSize: 10, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            ]),
          ]),
          const SizedBox(height: 10),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(fmtDate(expense.expenseDate),
                style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Poppins')),
            const SizedBox(width: 12),
            Icon(Icons.payments_outlined, size: 12, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(_paidByLabel(expense.paidBy),
                style: const TextStyle(fontSize: 11, color: AppColors.textHint, fontFamily: 'Poppins')),
            if (expense.paidTo.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(child: Text('→ ${expense.paidTo}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary,
                      fontFamily: 'Poppins'), overflow: TextOverflow.ellipsis)),
            ],
          ]),
          if (expense.isCreated) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.edit_rounded, color: AppColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text('Edit', style: TextStyle(color: AppColors.primary, fontSize: 12,
                          fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.cancel_outlined, color: AppColors.error, size: 16),
                      SizedBox(width: 6),
                      Text('Cancel', style: TextStyle(color: AppColors.error, fontSize: 12,
                          fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }

  String _paidByLabel(String v) {
    switch (v) {
      case 'cash': return 'Cash';
      case 'upi': return 'UPI';
      case 'bank': return 'Bank';
      case 'cheque': return 'Cheque';
      default: return v;
    }
  }
}

// ── Expense Detail Bottom Sheet (No Approve/Reject, Edit + Cancel) ──
class _ExpenseDetailSheet extends StatelessWidget {
  final ExpenseModel expense;
  final String Function(double) fmtAmount;
  final String Function(DateTime) fmtDate;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;

  const _ExpenseDetailSheet({
    required this.expense, required this.fmtAmount, required this.fmtDate,
    this.onCancel, this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4,
            decoration: BoxDecoration(color: AppColors.border,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 4),
        Container(
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(expense.categoryLabel,
                  style: const TextStyle(color: Colors.white70, fontSize: 12,
                      fontFamily: 'Poppins')),
              Text(fmtAmount(expense.amount),
                  style: const TextStyle(color: Colors.white, fontSize: 24,
                      fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
            ]),
            _statusBadge(),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _detailCard([
                _row('Description', expense.description),
                _row('Date', fmtDate(expense.expenseDate)),
                _row('Paid By', _paidByLabel(expense.paidBy)),
                if (expense.paidTo.isNotEmpty) _row('Paid To', expense.paidTo),
                if (expense.referenceNumber.isNotEmpty) _row('Reference', expense.referenceNumber),
                if (expense.notes.isNotEmpty) _row('Notes', expense.notes),
              ]),
              const SizedBox(height: 12),
              _detailCard([
                _row('Status', expense.isCreated ? 'Created' : 'Cancelled'),
                if (expense.createdByName.isNotEmpty) _row('Created By', expense.createdByName),
                _row('Created At', fmtDate(expense.createdAt)),
                if (expense.isCancelled && expense.cancellationReason.isNotEmpty)
                  _row('Cancel Reason', expense.cancellationReason, color: AppColors.error),
              ]),
              const SizedBox(height: 20),
              if (expense.isCreated && onEdit != null)
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 16),
                      label: const Text('Edit Expense', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                          elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ]),
              if (expense.isCreated && onCancel != null) ...[
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel Expense', style: TextStyle(fontFamily: 'Poppins',
                      color: AppColors.textSecondary, fontSize: 13)),
                )),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _detailCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: children),
  );

  Widget _row(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 110, child: Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Poppins'))),
      Expanded(child: Text(value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
              color: color ?? AppColors.textPrimary, fontFamily: 'Poppins'))),
    ]),
  );

  Widget _statusBadge() {
    final color = expense.isCreated ? AppColors.success : AppColors.textHint;
    final bg = expense.isCreated ? AppColors.successSurface : AppColors.surfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg.withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
      child: Text(expense.isCreated ? 'Created' : 'Cancelled', style: TextStyle(color: color, fontSize: 12,
          fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
    );
  }

  String _paidByLabel(String v) {
    switch (v) {
      case 'cash': return 'Cash';
      case 'upi': return 'UPI';
      case 'bank': return 'Bank Transfer';
      case 'cheque': return 'Cheque';
      default: return v;
    }
  }
}