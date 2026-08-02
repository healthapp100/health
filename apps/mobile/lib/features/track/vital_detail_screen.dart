import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/state_widgets.dart';
import 'track_providers.dart';

/// Full trend + history for one vital, reached by tapping its summary card on Track — mirrors
/// Apple Health's metric detail pattern (glanceable summary on the dashboard, full history one
/// tap away) instead of showing every metric's full chart on the dashboard at once.
class VitalDetailScreen extends ConsumerWidget {
  final String metricType;
  final String label;
  final Color color;

  const VitalDetailScreen({
    super.key,
    required this.metricType,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(vitalTrendProvider(metricType));

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: trendAsync.when(
        data: (points) {
          if (points.isEmpty) {
            return const EmptyState(icon: Icons.show_chart, title: 'No readings yet');
          }
          final spots =
              points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true, drawVerticalLine: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                          ),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            dotData: const FlDotData(show: true),
                            color: color,
                            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.1)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('History', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...points.reversed.map(
                (v) => Card(
                  child: ListTile(
                    title: Text('${v.value.toStringAsFixed(1)} ${v.unit}'),
                    subtitle: Text(DateFormat('EEE, d MMM · h:mm a').format(v.recordedAt)),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }
}
