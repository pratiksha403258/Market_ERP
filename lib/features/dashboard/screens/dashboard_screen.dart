import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userName = auth.user?.name ?? 'User';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, ${userName.split(' ').first}! 👋',
                          style: AppTextStyles.headingLarge),
                      const SizedBox(height: 3),
                      Text(
                        _todayLabel(),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                  Row(children: [
                    // Notification bell
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 8, offset: const Offset(0, 2),
                        )],
                      ),
                      child: const Icon(Icons.notifications_none_rounded,
                          color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 10),
                    // Avatar
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.heroGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(auth.user?.initials ?? 'U',
                            style: const TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 14,
                                fontFamily: 'Poppins')),
                      ),
                    ),
                  ]),
                ],
              ),

              const SizedBox(height: 20),

              // ── Hero Banner Card ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                    color: AppColors.primary.withOpacity(0.28),
                    blurRadius: 20, offset: const Offset(0, 6),
                  )],
                ),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Farming Made Simple,',
                          style: TextStyle(color: Colors.white70, fontSize: 12,
                              fontFamily: 'Poppins')),
                      const SizedBox(height: 2),
                      const Text('Smarter & Sustainable',
                          style: TextStyle(color: Colors.white, fontSize: 17,
                              fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Market ERP v1.0',
                            style: TextStyle(color: Colors.white, fontSize: 12,
                                fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
                      ),
                    ],
                  )),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        color: Colors.white, size: 36),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── KPI Stats Grid ────────────────────────────────
              const Text('Today\'s Overview',
                  style: AppTextStyles.headingMedium),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.45,
                children: const [
                  _KpiCard(
                    icon: Icons.local_shipping_rounded,
                    label: "Today's Arrival",
                    value: '2,450 kg',
                    change: '+12%',
                    positive: true,
                  ),
                  _KpiCard(
                    icon: Icons.people_rounded,
                    label: 'Total Farmers',
                    value: '128',
                    change: '+5',
                    positive: true,
                  ),
                  _KpiCard(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'Pending Dues',
                    value: '₹1,45,000',
                    change: '8 entries',
                    positive: false,
                  ),
                  _KpiCard(
                    icon: Icons.trending_up_rounded,
                    label: "Today's Sales",
                    value: '₹78,500',
                    change: '+15%',
                    positive: true,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Quick Actions ─────────────────────────────────
              const Text('Quick Actions', style: AppTextStyles.headingMedium),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _QuickAction(
                  icon: Icons.add_circle_rounded,
                  label: 'New Purchase',
                  color: AppColors.primary,
                  onTap: () {},
                )),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(
                  icon: Icons.person_add_rounded,
                  label: 'Add Farmer',
                  color: AppColors.secondary,
                  onTap: () {},
                )),
                const SizedBox(width: 10),
                Expanded(child: _QuickAction(
                  icon: Icons.payments_rounded,
                  label: 'Payment',
                  color: AppColors.info,
                  onTap: () {},
                )),
              ]),

              const SizedBox(height: 20),

              // ── Weekly Bar Chart ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Weekly Arrivals',
                                style: AppTextStyles.headingSmall),
                            Text('Last 7 days',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textHint)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(children: [
                            Icon(Icons.trending_up_rounded,
                                color: AppColors.success, size: 13),
                            SizedBox(width: 4),
                            Text('+12%', style: TextStyle(
                                color: AppColors.success, fontSize: 11,
                                fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          _Bar(day: 'Mon', pct: 0.65),
                          _Bar(day: 'Tue', pct: 0.72),
                          _Bar(day: 'Wed', pct: 0.80),
                          _Bar(day: 'Thu', pct: 0.78),
                          _Bar(day: 'Fri', pct: 0.85),
                          _Bar(day: 'Sat', pct: 0.92),
                          _Bar(day: 'Sun', pct: 0.70, isToday: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total this week',
                            style: TextStyle(fontSize: 12,
                                color: AppColors.textHint, fontFamily: 'Poppins')),
                        Text('8,200 kg',
                            style: AppTextStyles.numberSmall.copyWith(
                                color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Recent Purchases ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Purchases',
                      style: AppTextStyles.headingMedium),
                  TextButton(
                    onPressed: () {},
                    child: const Text('View All',
                        style: TextStyle(color: AppColors.primary,
                            fontSize: 13, fontFamily: 'Poppins')),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...List.generate(3, (i) => _PurchaseTile(index: i)),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _todayLabel() {
    final d = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days   = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── KPI Card ──────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final bool positive;

  const _KpiCard({
    required this.icon, required this.label,
    required this.value, required this.change, required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = positive ? AppColors.successSurface : AppColors.warningSurface;
    final textColor  = positive ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(
          color: AppColors.shadowLight, blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(change, style: TextStyle(
                    color: textColor, fontSize: 10,
                    fontWeight: FontWeight.w600, fontFamily: 'Poppins')),
              ),
            ],
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: AppTextStyles.numberSmall),
            Text(label, style: AppTextStyles.labelSmall),
          ]),
        ],
      ),
    );
  }
}

// ── Quick Action ──────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11,
            fontWeight: FontWeight.w600, color: AppColors.textPrimary,
            fontFamily: 'Poppins'),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ── Bar Chart ─────────────────────────────────────────────────
class _Bar extends StatelessWidget {
  final String day;
  final double pct;
  final bool isToday;
  const _Bar({required this.day, required this.pct, this.isToday = false});

  @override
  Widget build(BuildContext context) => Column(children: [
    if (isToday)
      Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('Now', style: TextStyle(color: Colors.white,
            fontSize: 8, fontFamily: 'Poppins')),
      )
    else const SizedBox(height: 18),
    Flexible(
      child: Container(
        width: 34,
        height: 120 * pct,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isToday
                ? [AppColors.secondary, AppColors.primary]
                : [AppColors.primaryLight, AppColors.primary],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    const SizedBox(height: 6),
    Text(day, style: const TextStyle(fontSize: 10,
        color: AppColors.textHint, fontFamily: 'Poppins')),
  ]);
}

// ── Purchase Tile ─────────────────────────────────────────────
class _PurchaseTile extends StatelessWidget {
  final int index;
  const _PurchaseTile({required this.index});

  static const _data = [
    ['Onion', 'Ram Singh',   '₹24,500', 'Just now'],
    ['Tomato','Suresh Patil','₹18,200', '2h ago'],
    ['Potato','Laxman Jadhav','₹31,000','5h ago'],
  ];

  @override
  Widget build(BuildContext context) {
    final d = _data[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.agriculture_rounded,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d[0], style: AppTextStyles.labelLarge),
            const SizedBox(height: 2),
            Text('Farmer: ${d[1]}', style: AppTextStyles.bodySmall),
          ],
        )),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(d[2], style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.primaryDark)),
          const SizedBox(height: 2),
          Text(d[3], style: AppTextStyles.bodySmall),
        ]),
      ]),
    );
  }
}


// import 'package:flutter/material.dart';
// import '../../../core/constants//colors.dart';

// class DashboardScreen extends StatelessWidget {
//   const DashboardScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(AppSpacing.lg),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header with Date
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Hello Rajesh,',
//                         style: AppTextStyles.headingLarge,
//                       ),
//                       const SizedBox(height: AppSpacing.xs),
//                       Text(
//                         'Monday, 05 MAY 2026',
//                         style: AppTextStyles.bodyMedium,
//                       ),
//                     ],
//                   ),
//                   Container(
//                     padding: const EdgeInsets.all(AppSpacing.sm),
//                     decoration: BoxDecoration(
//                       color: AppColors.primary.withOpacity(0.1),
//                       borderRadius: AppRadius.radiusMD,
//                     ),
//                     child: Icon(
//                       Icons.notifications_none,
//                       color: AppColors.primary,
//                       size: 20,
//                     ),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: AppSpacing.xl),
              
//               // Hero Card - Primary Gradient
//               Container(
//                 padding: const EdgeInsets.all(AppSpacing.lg),
//                 decoration: BoxDecoration(
//                   gradient: AppColors.primaryGradient,
//                   borderRadius: AppRadius.radiusMD,
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Farming Made Simple,',
//                           style: AppTextStyles.bodySmall.copyWith(
//                             color: Colors.white70,
//                           ),
//                         ),
//                         Text(
//                           'Smarter, and Sustainable',
//                           style: AppTextStyles.headingSmall.copyWith(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: AppSpacing.md),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: AppSpacing.md,
//                             vertical: AppSpacing.xs,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: AppRadius.radiusFull,
//                           ),
//                           child: Row(
//                             children: [
//                               const Icon(
//                                 Icons.search,
//                                 color: Colors.white,
//                                 size: 16,
//                               ),
//                               const SizedBox(width: AppSpacing.sm),
//                               Text(
//                                 'Search places',
//                                 style: AppTextStyles.bodySmall.copyWith(
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     Column(
//                       children: [
//                         const Icon(
//                           Icons.wb_sunny,
//                           color: Colors.white,
//                           size: 50,
//                         ),
//                         const SizedBox(height: AppSpacing.xs),
//                         Text(
//                           'Bright and Sunny',
//                           style: AppTextStyles.bodySmall.copyWith(
//                             color: Colors.white,
//                           ),
//                         ),
//                         Text(
//                           'Stable for plant growth',
//                           style: AppTextStyles.labelSmall.copyWith(
//                             color: Colors.white.withOpacity(0.8),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
              
//               const SizedBox(height: AppSpacing.xl),
              
//               // My Fields Section
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'My Fields',
//                     style: AppTextStyles.headingMedium,
//                   ),
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.star,
//                         color: AppColors.secondary,
//                         size: 16,
//                       ),
//                       const SizedBox(width: AppSpacing.xs),
//                       Text(
//                         '4.5',
//                         style: AppTextStyles.bodySmall,
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: AppSpacing.md),
              
//               // Field Performance Graph Card
//               Container(
//                 padding: const EdgeInsets.all(AppSpacing.lg),
//                 decoration: BoxDecoration(
//                   color: AppColors.surface,
//                   borderRadius: AppRadius.radiusLG,
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppColors.shadowLight,
//                       blurRadius: 10,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(AppSpacing.sm),
//                           decoration: BoxDecoration(
//                             color: AppColors.primary.withOpacity(0.1),
//                             borderRadius: AppRadius.radiusMD,
//                           ),
//                           child: Icon(
//                             Icons.show_chart,
//                             color: AppColors.primary,
//                             size: 20,
//                           ),
//                         ),
//                         const SizedBox(width: AppSpacing.md),
//                         const Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Field Performance',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               Text(
//                                 'Last 7 days yield analysis',
//                                 style: TextStyle(color: Colors.grey, fontSize: 11),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const Icon(Icons.more_vert, color: Colors.grey),
//                       ],
//                     ),
//                     const SizedBox(height: AppSpacing.xl),
                    
//                     // Graph Bars
//                     SizedBox(
//                       height: 150,
//                       child: Row(
//                         crossAxisAlignment: CrossAxisAlignment.end,
//                         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                         children: [
//                           _buildGraphBar('Mon', 65, AppColors.primary),
//                           _buildGraphBar('Tue', 72, AppColors.primary),
//                           _buildGraphBar('Wed', 80, AppColors.primary),
//                           _buildGraphBar('Thu', 78, AppColors.primary),
//                           _buildGraphBar('Fri', 85, AppColors.secondary),
//                           _buildGraphBar('Sat', 88, AppColors.primary),
//                           _buildGraphBar('Sun', 92, AppColors.primary),
//                         ],
//                       ),
//                     ),
//                     const Divider(height: AppSpacing.xxl),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           'Total Yield',
//                           style: AppTextStyles.bodySmall,
//                         ),
//                         Text(
//                           '8,200 Kg/ha',
//                           style: AppTextStyles.numberSmall,
//                         ),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: AppSpacing.sm,
//                             vertical: AppSpacing.xs,
//                           ),
//                           decoration: BoxDecoration(
//                             color: AppColors.success.withOpacity(0.1),
//                             borderRadius: AppRadius.radiusMD,
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.trending_up,
//                                 color: AppColors.success,
//                                 size: 12,
//                               ),
//                               const SizedBox(width: AppSpacing.xs),
//                               Text(
//                                 '+12%',
//                                 style: AppTextStyles.labelSmall.copyWith(
//                                   color: AppColors.success,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
              
//               const SizedBox(height: AppSpacing.md),
              
//               // Field Details Card
//               Container(
//                 padding: const EdgeInsets.all(AppSpacing.lg),
//                 decoration: BoxDecoration(
//                   color: AppColors.surface,
//                   borderRadius: AppRadius.radiusLG,
//                   boxShadow: [
//                     BoxShadow(
//                       color: AppColors.shadowLight,
//                       blurRadius: 10,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(AppSpacing.sm),
//                           decoration: BoxDecoration(
//                             color: AppColors.primary.withOpacity(0.1),
//                             borderRadius: AppRadius.radiusMD,
//                           ),
//                           child: Icon(
//                             Icons.terrain,
//                             color: AppColors.primary,
//                             size: 20,
//                           ),
//                         ),
//                         const SizedBox(width: AppSpacing.md),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Emerald Valley Plot F5',
//                                 style: AppTextStyles.labelLarge,
//                               ),
//                               Text(
//                                 '40.7128° N | 74.0060° W',
//                                 style: AppTextStyles.bodySmall,
//                               ),
//                             ],
//                           ),
//                         ),
//                         const Icon(Icons.more_vert, color: Colors.grey),
//                       ],
//                     ),
//                     const SizedBox(height: AppSpacing.lg),
//                     Divider(color: AppColors.divider),
//                     const SizedBox(height: AppSpacing.md),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         _buildDetailColumn('Crop Type', 'Onion'),
//                         _buildDetailColumn('Location', 'Punjab Valley'),
//                         _buildDetailColumn('Yield', '8200 Kg/ha', isHighlighted: true),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
              
//               const SizedBox(height: AppSpacing.md),
              
//               // Stats Row
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildStatCard(
//                       'Today\'s Arrival',
//                       '2,450 kg',
//                       '+12%',
//                       Icons.local_shipping,
//                     ),
//                   ),
//                   const SizedBox(width: AppSpacing.md),
//                   Expanded(
//                     child: _buildStatCard(
//                       'Total Farmers',
//                       '128',
//                       '+5',
//                       Icons.people,
//                     ),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: AppSpacing.md),
              
//               Row(
//                 children: [
//                   Expanded(
//                     child: _buildStatCard(
//                       'Pending Payments',
//                       '₹1,45,000',
//                       '+8%',
//                       Icons.payments,
//                     ),
//                   ),
//                   const SizedBox(width: AppSpacing.md),
//                   Expanded(
//                     child: _buildStatCard(
//                       'Today\'s Sales',
//                       '₹78,500',
//                       '+15%',
//                       Icons.trending_up,
//                     ),
//                   ),
//                 ],
//               ),
              
//               const SizedBox(height: AppSpacing.xl),
              
//               // Recent Purchases
//               Text(
//                 'Recent Purchases',
//                 style: AppTextStyles.headingMedium,
//               ),
              
//               const SizedBox(height: AppSpacing.md),
              
//               ListView.builder(
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 itemCount: 3,
//                 itemBuilder: (context, index) {
//                   return Container(
//                     margin: const EdgeInsets.only(bottom: AppSpacing.sm),
//                     padding: const EdgeInsets.all(AppSpacing.md),
//                     decoration: BoxDecoration(
//                       color: AppColors.surface,
//                       borderRadius: AppRadius.radiusMD,
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.all(AppSpacing.sm),
//                           decoration: BoxDecoration(
//                             color: AppColors.primary.withOpacity(0.1),
//                             borderRadius: AppRadius.radiusMD,
//                           ),
//                           child: Icon(
//                             Icons.agriculture,
//                             color: AppColors.primary,
//                             size: 20,
//                           ),
//                         ),
//                         const SizedBox(width: AppSpacing.md),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Onion',
//                                 style: AppTextStyles.labelLarge,
//                               ),
//                               Text(
//                                 'Farmer: Ram Singh',
//                                 style: AppTextStyles.bodySmall,
//                               ),
//                             ],
//                           ),
//                         ),
//                         Column(
//                           crossAxisAlignment: CrossAxisAlignment.end,
//                           children: [
//                             Text(
//                               '₹24,500',
//                               style: AppTextStyles.labelLarge,
//                             ),
//                             Text(
//                               'Today',
//                               style: AppTextStyles.bodySmall,
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
  
//   Widget _buildGraphBar(String day, double heightPercentage, Color color) {
//     return Column(
//       children: [
//         Container(
//           width: 35,
//           height: heightPercentage,
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.bottomCenter,
//               end: Alignment.topCenter,
//               colors: [color.withOpacity(0.7), color],
//             ),
//             borderRadius: AppRadius.radiusSM,
//           ),
//         ),
//         const SizedBox(height: AppSpacing.sm),
//         Text(
//           day,
//           style: AppTextStyles.labelSmall,
//         ),
//       ],
//     );
//   }
  
//   Widget _buildStatCard(
//     String title,
//     String value,
//     String change,
//     IconData icon,
//   ) {
//     final isPositive = change.startsWith('+');
    
//     return Container(
//       padding: const EdgeInsets.all(AppSpacing.md),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         borderRadius: AppRadius.radiusMD,
//         boxShadow: [
//           BoxShadow(
//             color: AppColors.shadowLight,
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Icon(icon, color: AppColors.primary, size: 20),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: AppSpacing.xs,
//                   vertical: AppSpacing.xxs,
//                 ),
//                 decoration: BoxDecoration(
//                   color: isPositive 
//                       ? AppColors.success.withOpacity(0.1)
//                       : AppColors.warning.withOpacity(0.1),
//                   borderRadius: AppRadius.radiusSM,
//                 ),
//                 child: Text(
//                   change,
//                   style: TextStyle(
//                     color: isPositive ? AppColors.success : AppColors.warning,
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.sm),
//           Text(
//             value,
//             style: AppTextStyles.numberSmall,
//           ),
//           Text(
//             title,
//             style: AppTextStyles.labelSmall,
//           ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildDetailColumn(String label, String value, {bool isHighlighted = false}) {
//     return Column(
//       children: [
//         Text(
//           label,
//           style: AppTextStyles.labelSmall,
//         ),
//         const SizedBox(height: AppSpacing.xs),
//         if (isHighlighted)
//           Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: AppSpacing.sm,
//               vertical: AppSpacing.xxs,
//             ),
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.1),
//               borderRadius: AppRadius.radiusMD,
//             ),
//             child: Text(
//               value,
//               style: AppTextStyles.labelSmall.copyWith(
//                 color: AppColors.primary,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           )
//         else
//           Text(
//             value,
//             style: AppTextStyles.bodyMedium.copyWith(
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//       ],
//     );
//   }
// }