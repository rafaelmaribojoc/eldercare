import 'package:flutter/material.dart';

import '../constants/moca_colors.dart';

class ScoreIndicator extends StatelessWidget {
  final int score;
  final int maxScore;
  final String? label;
  final double size;

  const ScoreIndicator({
    super.key,
    required this.score,
    required this.maxScore,
    this.label,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxScore > 0 ? score / maxScore : 0.0;
    final color = _getColor(percentage);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 6,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '/ $maxScore',
                  style: TextStyle(
                    fontSize: size * 0.18,
                    color: MocaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }

  Color _getColor(double percentage) {
    if (percentage >= 0.8) return MocaColors.success;
    if (percentage >= 0.5) return MocaColors.warning;
    return MocaColors.error;
  }
}
