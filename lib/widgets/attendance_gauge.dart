import 'package:attendx/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class AttendanceGauge extends StatelessWidget {
  final double percentage;
  final double radius;
  final double lineWidth;

  const AttendanceGauge({
    super.key,
    required this.percentage,
    this.radius = 78,
    this.lineWidth = 14,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forPercentage(percentage);
    final label = AppColors.labelForPercentage(percentage);

    return CircularPercentIndicator(
      radius: radius,
      lineWidth: lineWidth,
      percent: (percentage / 100).clamp(0.0, 1.0),
      animation: true,
      animationDuration: 900,
      circularStrokeCap: CircularStrokeCap.round,
      backgroundColor: color.withOpacity(0.12),
      progressColor: color,
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
