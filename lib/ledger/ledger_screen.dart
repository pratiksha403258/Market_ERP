import 'dart:io';
import 'package:agr_market/ledger/FarmerLedgerDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/colors.dart';
import '../../../services/dio_client.dart';
import '../../../services/constant_service.dart';
import '../../../providers/language_provider.dart';   

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  List<Map<String, dynamic>> _farmers = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFarmers();
    // Show language popup after first frame if language not set
  //  WidgetsBinding.instance.addPostFrameCallback((_) {
  //   _showLanguageDialog(); // Remove the _checkAndShowLanguagePopup() call
  // });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  //  Show language selection popup only if never selected before
  // ------------------------------------------------------------------
  Future<void> _checkAndShowLanguagePopup() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSelected = prefs.containsKey(AppConstants.keyLanguage);
    if (!hasSelected && mounted) {
      _showLanguageDialog();
    }
  }

  void _showLanguageDialog() {
    final langProv = Provider.of<LanguageProvider>(context, listen: false);
    String? tempSelected = langProv.locale.languageCode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              langProv.t('select_language_title'),
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: LanguageProvider.supportedLanguages.map((lang) {
                return RadioListTile<String>(
                  title: Text(lang.nativeName,
                      style: const TextStyle(fontFamily: 'Poppins')),
                  subtitle: Text(lang.name,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                  secondary: Text(lang.flag, style: const TextStyle(fontSize: 24)),
                  value: lang.code,
                  groupValue: tempSelected,
                  onChanged: (val) => setStateDialog(() => tempSelected = val),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(langProv.t('cancel'), style: const TextStyle(fontFamily: 'Poppins')),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (tempSelected != null) {
                    await langProv.setLanguage(tempSelected!);
                    if (mounted) Navigator.pop(ctx);
                    setState(() {}); // Refresh screen
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(langProv.t('continue'),
                    style: const TextStyle(color: Colors.white, fontFamily: 'Poppins')),
              ),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // Data loading (unchanged)
  // ------------------------------------------------------------------
  Future<void> _loadFarmers() async {
    setState(() => _loading = true);
    try {
      final res = await DioClient.instance.dio.get(
        ApiRoutes.farmers,
        queryParameters: {'limit': 100, 'page': 1},
      );
      final data = res.data;
      List raw = [];
      if (data is List) {
        raw = data;
      } else if (data is Map) {
        raw = data['farmers'] as List? ?? data['data'] as List? ?? [];
      }
      setState(() {
        _farmers = raw.map((f) => f as Map<String, dynamic>).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ LedgerScreen: load farmers failed: $e');
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _farmers;
    final q = _searchQuery.toLowerCase();
    return _farmers.where((f) {
      final name = (f['name'] ?? '').toString().toLowerCase();
      final mobile = (f['mobile'] ?? '').toString();
      return name.contains(q) || mobile.contains(q);
    }).toList();
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'F';
  }

  String _fmtAmount(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, langProv, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(children: [
            // ── Gradient Header (localized) ─────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(langProv.t('ledger_title'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20,
                                fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                        const Spacer(),
                        // tiny language button (optional – remove if you want "nothing extra")
                        GestureDetector(
                          onTap: _showLanguageDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.language, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_farmers.length} ${langProv.t('farmers')}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Poppins'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        langProv.t('ledger_subtitle'),
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Search Bar (localized hint) ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: langProv.t('search_hint_ledger'),
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
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
            ),

            // ── Farmer List (localized labels) ─────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _filtered.isEmpty
                      ? Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            const Icon(Icons.menu_book_outlined, size: 56, color: AppColors.textHint),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? '${langProv.t('no_matching_farmers')} "$_searchQuery"'
                                  : langProv.t('no_farmers_found'),
                              style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins', fontSize: 14),
                            ),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadFarmers,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final f = _filtered[i];
                              final name = f['name']?.toString() ?? 'Unknown';
                              final mobile = f['mobile']?.toString() ?? '';
                              final pendingDues = (f['pendingDues'] as num?)?.toDouble() ?? 0;
                              final farmerId = f['_id']?.toString() ?? f['id']?.toString() ?? '';
                              final isActive = f['isActive'] as bool? ?? true;

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FarmerLedgerDetailScreen(
                                      farmerId: farmerId,
                                      farmerName: name,
                                      farmerMobile: mobile,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.border),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 46, height: 46,
                                      decoration: const BoxDecoration(gradient: AppColors.heroGradient, shape: BoxShape.circle),
                                      child: Center(child: Text(_initials(name), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Poppins'))),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Poppins')),
                                        const SizedBox(height: 2),
                                        Text(mobile, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Poppins')),
                                      ]),
                                    ),
                                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                      if (pendingDues > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: AppColors.warningSurface, borderRadius: BorderRadius.circular(8)),
                                          child: Text(
                                            '${langProv.t('due_short')} ${_fmtAmount(pendingDues)}',
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning, fontFamily: 'Poppins'),
                                          ),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: AppColors.successSurface, borderRadius: BorderRadius.circular(8)),
                                          child: Text(
                                            langProv.t('clear_short'),
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success, fontFamily: 'Poppins'),
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textHint),
                                    ]),
                                  ]),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ]),
        );
      },
    );
  }
}