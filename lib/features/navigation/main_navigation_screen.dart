import 'package:agr_market/expense/expense_list_screen.dart';
import 'package:agr_market/purchase/purchase_list_screen.dart';
import 'package:agr_market/warehouse/warehouse_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/language_provider.dart';  
import '../dashboard/screens/dashboard_screen.dart';
import '../farmers/screens/farmer_list_screen.dart';

// MAIN NAVIGATION SCREEN — floating bottom nav
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Remove the static _NavItem list - will create dynamically with translations
  List<_NavItem> _getNavItems(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return [
      _NavItem(icon: Icons.home_rounded, label: lang.t('nav_home')),
      _NavItem(icon: Icons.people_rounded, label: lang.t('nav_farmers')),
      _NavItem(icon: Icons.add_box_rounded, label: lang.t('nav_purchase')),
      _NavItem(icon: Icons.receipt_rounded, label: lang.t('nav_expense')),
      _NavItem(icon: Icons.warehouse_rounded, label: lang.t('nav_warehouse')),
    ];
  }

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const FarmerListScreen();
      case 2:
        return const PurchaseListScreen();
      case 3:
        return const ExpenseListScreen();
      case 4:
        return const WarehouseListScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _getNavItems(context);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildScreen(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
          children: List.generate(items.length, (i) {
            final isSelected = _currentIndex == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, 
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].icon,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textHint,
                        size: 22, 
                      ),
                      const SizedBox(height: 2), 
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 9, 
                          fontFamily: 'Poppins',
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                        child: Text(items[i].label),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  
  const _NavItem({
    required this.icon,
    required this.label,
  });
}