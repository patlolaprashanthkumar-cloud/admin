import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class PaymentBreakdownChart extends StatelessWidget {
  final Map<String, int> breakdown;

  const PaymentBreakdownChart({
    super.key,
    required this.breakdown,
  });

  static const Map<String, ({String label, Color color})> statusConfig = {
    'verified': (label: 'Verified', color: AppColors.primaryForest),
    'pending': (label: 'Pending', color: AppColors.accentTerracotta),
    'rejected': (label: 'Rejected', color: AppColors.terracottaDark),
    'failed': (label: 'Failed', color: AppColors.error),
    'refunded': (label: 'Refunded', color: AppColors.textMuted),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalTransactions = breakdown.values.fold<int>(0, (sum, count) => sum + count);

    if (totalTransactions == 0) {
      return Container(
        height: 190,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded, size: 36, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              'No fee payment transactions found.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final List<PieChartSectionData> sections = [];
    final List<Widget> legendItems = [];

    statusConfig.forEach((key, config) {
      final count = breakdown[key] ?? 0;
      if (count > 0) {
        final percentage = (count / totalTransactions) * 100;
        sections.add(
          PieChartSectionData(
            color: config.color,
            value: count.toDouble(),
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 36,
            titleStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        );
      }

      legendItems.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.5),
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: config.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  config.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$count',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: config.color,
                ),
              ),
            ],
          ),
        ),
      );
    });

    return Row(
      children: [
        // Donut Pie Chart
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 38,
                sectionsSpace: 3,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend details
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: legendItems,
          ),
        ),
      ],
    );
  }
}
