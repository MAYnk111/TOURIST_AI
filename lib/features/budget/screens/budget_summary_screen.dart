import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/providers/app_state_provider.dart';
import '../../../shared/models/budget_breakdown.dart';

class BudgetSummaryScreen extends StatelessWidget {
  const BudgetSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final trip = appState.currentTrip;
    final budget = trip.budget;
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Budget',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${trip.destination.split(',').first} • ${trip.days.length} Days • ${trip.travelersCount} People',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary Reference Card: User's Group Budget & Optimized Trip Cost
            Builder(
              builder: (context) {
                final isWithin = budget.totalEstimated <= trip.totalBudget;
                final diff = (trip.totalBudget - budget.totalEstimated).abs();
                final diffPerPerson = trip.travelersCount > 0 ? diff / trip.travelersCount : diff;
                final statusBg = isWithin ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
                final statusBorder = isWithin ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5);
                final statusColor = isWithin ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
                final statusIcon = isWithin ? Icons.check_circle_rounded : Icons.warning_amber_rounded;
                final statusHeadline = isWithin
                    ? 'Budget Remaining: ${currencyFormatter.format(diff)}'
                    : 'Budget Shortfall: ${currencyFormatter.format(diff)}';
                final statusSubtext = isWithin
                    ? '${currencyFormatter.format(diffPerPerson)} per person under budget'
                    : '${currencyFormatter.format(diffPerPerson)} per person over budget';

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Your Group Budget (Primary Reference Point)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'YOUR GROUP BUDGET',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter.format(trip.totalBudget),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${currencyFormatter.format(trip.budgetPerPerson)} / person · ${trip.travelersCount} travelers',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tune_rounded, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '${trip.travelersCount} Travelers',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),

                      // Side-by-side: Estimated Trip Cost & Per-Person Cost
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estimated Trip Cost',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  currencyFormatter.format(budget.totalEstimated),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Optimized itinerary',
                                  style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 40, color: AppColors.border),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Cost Per Person',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  currencyFormatter.format(trip.travelersCount > 0 ? budget.totalEstimated / trip.travelersCount : budget.totalEstimated),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Target: ${currencyFormatter.format(trip.budgetPerPerson)}',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status Badge (Green Remaining or Warning Shortfall)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: statusBorder),
                        ),
                        child: Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statusHeadline,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    statusSubtext,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: statusColor.withOpacity(0.85),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Quick Budget Adjustment Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Change Per-Person Budget',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Updates plan instantly',
                        style: TextStyle(fontSize: 10, color: AppColors.primary.withOpacity(0.8), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildQuickBudgetChip(context, label: '₹2,000 (Econ)', value: 2000.0, currentVal: trip.budgetPerPerson),
                      const SizedBox(width: 8),
                      _buildQuickBudgetChip(context, label: '₹5,000 (Mod)', value: 5000.0, currentVal: trip.budgetPerPerson),
                      const SizedBox(width: 8),
                      _buildQuickBudgetChip(context, label: '₹15,000 (Prem)', value: 15000.0, currentVal: trip.budgetPerPerson),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Transparent Estimation Methodology Disclosure
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF475569)),
                      SizedBox(width: 8),
                      Text(
                        'Estimation Methodology & Grounded Units',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Budget-driven calculation based on scheduled itinerary stops, OpenStreetMap municipal entry fees, local public transit/cabs, and room occupancy (2 travelers per room). Category breakdown sums strictly to the displayed total.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.35),
                  ),
                  if (budget.knownFeesTotal > 0 || budget.unknownFeesCount > 0) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (budget.knownFeesTotal > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Known Entry Fees: ₹${budget.knownFeesTotal.toInt()}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0369A1)),
                            ),
                          ),
                        if (budget.unknownFeesCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${budget.unknownFeesCount} Unstated / Free Places',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Breakdown Title
            const Text(
              'Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Donut Chart & Legend Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Donut Chart
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CustomPaint(
                      painter: _DonutChartPainter(budget: budget),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currencyFormatter.format(budget.totalEstimated),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Legend
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Accommodation', budget.accommodation, budget.accommodationPct, const Color(0xFF0284C7)),
                        _buildLegendItem('Food & Drinks', budget.foodDrinks, budget.foodDrinksPct, const Color(0xFFEA580C)),
                        _buildLegendItem('Transport', budget.transport, budget.transportPct, const Color(0xFF10B981)),
                        _buildLegendItem('Activities', budget.activities, budget.activitiesPct, const Color(0xFF4F46E5)),
                        _buildLegendItem('Miscellaneous', budget.miscellaneous, budget.miscellaneousPct, const Color(0xFF8B5CF6)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Expandable Category Rows
            _buildCategoryAccordion(
              icon: Icons.hotel_rounded,
              title: 'Accommodation',
              amount: budget.accommodation,
              currencyFormatter: currencyFormatter,
              details: 'Hotel or homestay in ${trip.destination.split(',').first} for ${budget.nights} night(s) across ${(trip.travelersCount + 1) ~/ 2} room(s).',
            ),
            const SizedBox(height: 10),
            _buildCategoryAccordion(
              icon: Icons.restaurant_rounded,
              title: 'Food & Drinks',
              amount: budget.foodDrinks,
              currencyFormatter: currencyFormatter,
              details: 'Regional specialties, breakfasts, dining, and cafes for ${trip.travelersCount} travelers across ${trip.days.length} days.',
            ),
            const SizedBox(height: 10),
            _buildCategoryAccordion(
              icon: Icons.directions_car_rounded,
              title: 'Transport',
              amount: budget.transport,
              currencyFormatter: currencyFormatter,
              details: 'Local transit, shared/private rides, fuel, and connections between scheduled sights in ${trip.destination.split(',').first}.',
            ),
            const SizedBox(height: 10),
            _buildCategoryAccordion(
              icon: Icons.confirmation_number_rounded,
              title: 'Activities',
              amount: budget.activities,
              currencyFormatter: currencyFormatter,
              details: 'Attraction tickets, monument entry permits, audio guides, and excursions.',
            ),
            const SizedBox(height: 10),
            _buildCategoryAccordion(
              icon: Icons.shopping_bag_rounded,
              title: 'Miscellaneous',
              amount: budget.miscellaneous,
              currencyFormatter: currencyFormatter,
              details: 'Discretionary buffer, local crafts, emergency funds, and incidentals.',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, double amount, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBudgetChip(
    BuildContext context, {
    required String label,
    required double value,
    required double currentVal,
  }) {
    final isSelected = (value - currentVal).abs() < 1.0;
    return Expanded(
      child: InkWell(
        onTap: () {
          final appState = Provider.of<AppStateProvider>(context, listen: false);
          appState.updateTripBudget(value);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryAccordion({
    required IconData icon,
    required String title,
    required double amount,
    required NumberFormat currencyFormatter,
    required String details,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ExpansionTile(
        shape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textPrimary, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        trailing: Text(
          currencyFormatter.format(amount),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              details,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final BudgetBreakdown budget;

  _DonutChartPainter({required this.budget});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    final slices = [
      {'val': budget.accommodation, 'color': const Color(0xFF0284C7)},
      {'val': budget.foodDrinks, 'color': const Color(0xFFEA580C)},
      {'val': budget.transport, 'color': const Color(0xFF10B981)},
      {'val': budget.activities, 'color': const Color(0xFF4F46E5)},
      {'val': budget.miscellaneous, 'color': const Color(0xFF8B5CF6)},
    ];

    final total = budget.totalEstimated > 0 ? budget.totalEstimated : 1.0;
    double startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweep = ((slice['val'] as double) / total) * 2 * math.pi;
      final paint = Paint()
        ..color = slice['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
