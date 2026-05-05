import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../farmers/screens/farmer_list_screen.dart';

// ─────────────────────────────────────────────────────────────
//  MAIN NAVIGATION SCREEN — floating bottom nav
// ─────────────────────────────────────────────────────────────
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<_NavItem> _items = const [
    _NavItem(icon: Icons.home_rounded,     label: 'Home'),
    _NavItem(icon: Icons.people_rounded,   label: 'Farmers'),
    _NavItem(icon: Icons.add_box_rounded,  label: 'Purchase'),
    _NavItem(icon: Icons.person_rounded,   label: 'Profile'),
  ];

  Widget _buildScreen() {
    switch (_currentIndex) {
      case 0: return const DashboardScreen();
      case 1: return  FarmerListScreen();
      case 2: return const _ComingSoon(icon: Icons.add_shopping_cart_rounded, title: 'Purchase');
      case 3: return const _ComingSoon(icon: Icons.person_rounded, title: 'Profile');
      default: return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildScreen(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final isSelected = _currentIndex == i;
            return GestureDetector(
              onTap: () => setState(() => _currentIndex = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
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
                      _items[i].icon,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textHint,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 10,
                        fontFamily: 'Poppins',
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                      child: Text(_items[i].label),
                    ),
                  ],
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
  const _NavItem({required this.icon, required this.label});
}

// Placeholder for screens not yet built
class _ComingSoon extends StatelessWidget {
  final IconData icon;
  final String title;
  const _ComingSoon({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text('$title Screen',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary, fontFamily: 'Poppins')),
          const SizedBox(height: 8),
          const Text('Coming in Sprint 2',
              style: TextStyle(color: AppColors.textHint, fontSize: 13,
                  fontFamily: 'Poppins')),
        ],
      )),
    );
  }
}