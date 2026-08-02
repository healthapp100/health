import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../theme/app_theme.dart';

/// Shared visual primitives introduced in the world-class-redesign pass: skeleton loaders
/// (replacing bare spinners), status chips (color-coded state at a glance — appointment/lab
/// order status, medicine adherence), a reusable section header, and a compact sparkline for
/// vitals trends. Every feature screen should build from these rather than one-off widgets, so
/// the app reads as one coherent design system instead of six differently-styled tabs.

/// A single shimmering placeholder bar — the building block for skeleton loading states.
class SkeletonLine extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry borderRadius;

  const SkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  State<SkeletonLine> createState() => _SkeletonLineState();
}

class _SkeletonLineState extends State<SkeletonLine> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final highlight = Theme.of(context).colorScheme.surface;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          color: Color.lerp(base, highlight, _controller.value),
        ),
      ),
    );
  }
}

/// A card-shaped skeleton matching the app's standard `ListTile`-in-`Card` rhythm, so loading
/// states preview the shape of the content that's about to arrive instead of a spinner that
/// tells the user nothing about what to expect.
class SkeletonCard extends StatelessWidget {
  final bool withLeadingCircle;
  const SkeletonCard({super.key, this.withLeadingCircle = true});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (withLeadingCircle) ...[
              const SkeletonLine(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              const SizedBox(width: 16),
            ],
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLine(width: 160),
                  SizedBox(height: 8),
                  SkeletonLine(width: 100, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A short vertical list of [SkeletonCard]s — drop-in replacement for `LoadingState()` on any
/// list-shaped screen (appointments, articles, lab orders).
class SkeletonList extends StatelessWidget {
  final int count;
  const SkeletonList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonCard(),
        ),
      ),
    );
  }
}

enum StatusTone { success, warning, danger, info, neutral }

/// Central status→tone mapping so every screen colors the same status the same way, instead of
/// each screen inventing its own color logic (or, as before, no color logic at all).
StatusTone appointmentStatusTone(AppointmentStatus status) => switch (status) {
      AppointmentStatus.requested => StatusTone.warning,
      AppointmentStatus.confirmed => StatusTone.info,
      AppointmentStatus.inProgress => StatusTone.info,
      AppointmentStatus.completed => StatusTone.success,
      AppointmentStatus.cancelled => StatusTone.neutral,
      AppointmentStatus.noShow => StatusTone.danger,
    };

String appointmentStatusLabel(AppointmentStatus status) => switch (status) {
      AppointmentStatus.requested => 'Requested',
      AppointmentStatus.confirmed => 'Confirmed',
      AppointmentStatus.inProgress => 'In progress',
      AppointmentStatus.completed => 'Completed',
      AppointmentStatus.cancelled => 'Cancelled',
      AppointmentStatus.noShow => 'No-show',
    };

StatusTone labOrderStatusTone(LabOrderStatus status) => switch (status) {
      LabOrderStatus.ordered => StatusTone.warning,
      LabOrderStatus.sampleCollected => StatusTone.info,
      LabOrderStatus.inLab => StatusTone.info,
      LabOrderStatus.reported => StatusTone.success,
      LabOrderStatus.cancelled => StatusTone.neutral,
    };

String labOrderStatusLabel(LabOrderStatus status) => switch (status) {
      LabOrderStatus.ordered => 'Ordered',
      LabOrderStatus.sampleCollected => 'Sample collected',
      LabOrderStatus.inLab => 'In lab',
      LabOrderStatus.reported => 'Reported',
      LabOrderStatus.cancelled => 'Cancelled',
    };

/// Color-coded status-at-a-glance chip. Colors are drawn from the theme's semantic slots
/// (error/tertiary/[SemanticColors]) rather than hardcoded hex, so this stays correct — and
/// keeps passing WCAG AA contrast — in dark mode automatically. Never relies on color alone:
/// the text label always ships alongside the color, so color-blind users aren't excluded
/// (WCAG 1.4.1).
class StatusChip extends StatelessWidget {
  final String label;
  final StatusTone tone;
  const StatusChip({super.key, required this.label, this.tone = StatusTone.neutral});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<SemanticColors>();
    final (bg, fg) = switch (tone) {
      StatusTone.success => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      StatusTone.warning => (
          semantic?.warningContainer ?? scheme.surfaceContainerHighest,
          semantic?.onWarningContainer ?? scheme.onSurfaceVariant,
        ),
      StatusTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
      StatusTone.info => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      StatusTone.neutral => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: fg, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Reusable "Title … See all" row used at the top of every dashboard section, replacing the
/// per-screen private `_SectionHeader` copies that existed on Home only.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.subtitle, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (subtitle != null)
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}

/// Minimal axis-free line chart for a compact trend indicator inside a stat card — distinct from
/// the full [LineChart] on the Track screen's expanded view, which keeps its own axes/legend.
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  const Sparkline({super.key, required this.values, required this.color});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return const SizedBox.shrink();
    }
    final spots = values.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            color: color,
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
      ),
    );
  }
}

/// A compact stat tile — icon, value + unit, an optional sparkline, and a status chip. This is
/// the core "glanceable health metric" pattern used on Home and the Track summary row, replacing
/// bare `ListTile`s for anything numeric.
class MetricSummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final List<double>? trend;
  final Color accentColor;
  final StatusTone? statusTone;
  final String? statusLabel;
  final VoidCallback? onTap;

  const MetricSummaryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
    this.trend,
    this.statusTone,
    this.statusLabel,
    this.onTap,
  });

  /// A trend sparkline conveys "rising/falling" visually, which a screen-reader user can't see —
  /// so the merged semantic label spells that out in words instead of leaving the metric mute.
  String? get _trendDirection {
    if (trend == null || trend!.length < 2) return null;
    final delta = trend!.last - trend!.first;
    if (delta.abs() < 0.01) return 'steady over recent readings';
    return delta > 0 ? 'trending up over recent readings' : 'trending down over recent readings';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semanticLabel = [
      label,
      '$value $unit',
      if (statusLabel != null) statusLabel!,
      if (_trendDirection != null) _trendDirection!,
    ].join(', ');

    return Card(
      child: Semantics(
        label: semanticLabel,
        button: onTap != null,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: accentColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (statusLabel != null)
                      StatusChip(label: statusLabel!, tone: statusTone ?? StatusTone.neutral),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: theme.textTheme.headlineMedium),
                    const SizedBox(width: 4),
                    Text(unit, style: theme.textTheme.bodyMedium),
                  ],
                ),
                if (trend != null && trend!.length >= 2) ...[
                  const SizedBox(height: 8),
                  SizedBox(height: 32, child: Sparkline(values: trend!, color: accentColor)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Richer empty state with an optional primary action — used where an empty list is an
/// invitation to act (log a vital, book a call) rather than a dead end.
class ActionableEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ActionableEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
