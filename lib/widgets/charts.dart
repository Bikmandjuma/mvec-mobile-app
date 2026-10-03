import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../core/utils.dart';

/// CSS `.fake-chart` bar chart port — gradient bars with labels underneath.
class FakeBarChart extends StatelessWidget {
  const FakeBarChart({super.key, required this.values, required this.labels, this.height = 260});
  final List<num> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(height: height, child: Center(child: Text('No data', style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor))));
    }
    final maxV = values.fold<num>(0, (m, v) => v > m ? v : m);
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Tooltip(
                        message: '${values[i]}',
                        child: Opacity(
                          opacity: .85,
                          child: Container(
                            height: maxV == 0 ? 3 : (height - 34) * (values[i] / maxV),
                            decoration: BoxDecoration(
                              gradient: MvColors.gradient,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 24,
            child: Row(
              children: [
                for (final l in labels)
                  Expanded(
                    child: Text(
                      l,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 8, color: Theme.of(context).hintColor),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress bar row used by "Category health".
class ProgressRow extends StatelessWidget {
  const ProgressRow({super.key, required this.label, required this.percent, required this.count});
  final String label;
  final double percent;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                height: 7,
                child: Stack(
                  children: [
                    Container(color: isDarkSurface(context) ? MvColors.darkBorder : const Color(0xFFEDF1F3)),
                    FractionallySizedBox(
                      widthFactor: (percent / 100).clamp(0, 1),
                      child: Container(decoration: const BoxDecoration(gradient: MvColors.gradient)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(width: 40, child: Text(count, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

bool isDarkSurface(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.label, required this.value, required this.status});
  final String label;
  final String value;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor(status), shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          Text(value, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}