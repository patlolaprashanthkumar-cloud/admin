import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/dashboard_stats.dart';

class MonthlyTrendsChart extends StatelessWidget {
  final List<MonthlyMetricPoint> metrics;

  const MonthlyTrendsChart({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (metrics.isEmpty) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        child: Text(
          'No enrolment or financial telemetry recorded yet.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Determine max values for scaling
    double maxEnrolments = 1;
    double maxRevenue = 1;
    for (final m in metrics) {
      if (m.enrolments > maxEnrolments) maxEnrolments = m.enrolments.toDouble();
      if (m.revenue > maxRevenue) maxRevenue = m.revenue;
    }

    // Spot coordinates normalized to 0-100 for dual-axis rendering
    final List<FlSpot> enrolmentSpots = [];
    final List<FlSpot> revenueSpots = [];

    for (int i = 0; i < metrics.length; i++) {
      final m = metrics[i];
      final normEnrol = (m.enrolments / maxEnrolments) * 100;
      final normRev = (m.revenue / maxRevenue) * 100;

      enrolmentSpots.add(FlSpot(i.toDouble(), normEnrol));
      revenueSpots.add(FlSpot(i.toDouble(), normRev));
    }

    const tealColor = Color(0xFF028090);
    const peachColor = Color(0xFFFF8E53);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend Row
        Row(
          children: [
            _buildLegendItem('New Students', tealColor),
            const SizedBox(width: 16),
            _buildLegendItem('Revenue (₹)', peachColor),
          ],
        ),
        const SizedBox(height: 16),

        // fl_chart LineChart
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 26,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < metrics.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            metrics[idx].month,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (metrics.length - 1).toDouble(),
              minY: 0,
              maxY: 110,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => isDark ? const Color(0xFF1E293B) : Colors.white,
                  tooltipRoundedRadius: AppConstants.radiusMedium,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final idx = spot.x.toInt();
                      if (idx < 0 || idx >= metrics.length) return null;
                      final m = metrics[idx];

                      if (spot.barIndex == 0) {
                        return LineTooltipItem(
                          '${m.month}: ${m.enrolments} Enrolments',
                          const TextStyle(
                            color: tealColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      } else {
                        return LineTooltipItem(
                          '${m.month}: ${CurrencyFormatter.format(m.revenue)}',
                          const TextStyle(
                            color: peachColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                // Enrolments Bar
                LineChartBarData(
                  spots: enrolmentSpots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: tealColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3.5,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: tealColor,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        tealColor.withValues(alpha: 0.3),
                        tealColor.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Revenue Bar
                LineChartBarData(
                  spots: revenueSpots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: peachColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3.5,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: peachColor,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        peachColor.withValues(alpha: 0.3),
                        peachColor.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

