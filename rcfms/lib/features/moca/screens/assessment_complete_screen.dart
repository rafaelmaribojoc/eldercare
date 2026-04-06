import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/moca_assessment_bloc.dart';
import '../constants/moca_constants.dart';
import '../constants/moca_colors.dart';
import '../services/dementia_probability_calculator.dart';
import '../widgets/score_indicator.dart';

class AssessmentCompleteScreen extends StatefulWidget {
  const AssessmentCompleteScreen({super.key});

  @override
  State<AssessmentCompleteScreen> createState() =>
      _AssessmentCompleteScreenState();
}

class _AssessmentCompleteScreenState extends State<AssessmentCompleteScreen> {
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    // Trigger save when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveAssessment();
    });
  }

  void _saveAssessment() {
    if (!_hasSaved) {
      _hasSaved = true;
      // Complete and save the assessment
      context.read<MocaAssessmentBloc>().add(MocaCompleteAssessment());
      context.read<MocaAssessmentBloc>().add(MocaSaveAssessment());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MocaAssessmentBloc, MocaAssessmentState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: MocaColors.error,
            ),
          );
        }
        if (state.isSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Matagumpay na na-save ang pagtatasa'),
              backgroundColor: MocaColors.success,
            ),
          );
        }
      },
      builder: (context, state) {
        final assessment = state.assessment;

        if (assessment == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: MocaColors.error,
                  ),
                  const SizedBox(height: 16),
                  const Text('Walang nahanap na datos ng pagtatasa'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    child: const Text('Umuwi'),
                  ),
                ],
              ),
            ),
          );
        }

        final totalScore = assessment.totalScore;
        final adjustedScore = assessment.adjustedScore;
        final isNormal = adjustedScore >= MocaConstants.normalThreshold;

        // Calculate dementia probability
        final probabilityResult = DementiaProbabilityCalculator.calculate(
          adjustedScore,
        );

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // Success Icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isNormal
                            ? MocaColors.successLight
                            : MocaColors.warningLight,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isNormal ? Icons.check_circle : Icons.info,
                        size: 60,
                        color:
                            isNormal ? MocaColors.success : MocaColors.warning,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Tapos na ang Pagtatasa',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      isNormal
                          ? 'Ang iskor ay nasa normal na saklaw'
                          : 'Ang iskor ay nagpapahiwatig ng posibleng kapansanan',
                      style: TextStyle(
                        color:
                            isNormal ? MocaColors.success : MocaColors.warning,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Score Display
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ScoreIndicator(
                                  score: adjustedScore,
                                  maxScore: MocaConstants.totalPoints,
                                  size: 100,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (assessment.educationAdjustment) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: MocaColors.successLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_circle,
                                      size: 14,
                                      color: MocaColors.success,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      '+1 (≤12 taon edu)',
                                      style: TextStyle(
                                        color: MocaColors.success,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Orihinal na iskor: $totalScore',
                                style: const TextStyle(
                                  color: MocaColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isNormal
                                    ? MocaColors.successLight
                                    : MocaColors.warningLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isNormal ? Icons.check : Icons.warning,
                                    color: isNormal
                                        ? MocaColors.success
                                        : MocaColors.warning,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isNormal
                                        ? 'Normal (≥26/30)'
                                        : 'Mababa sa threshold (<26/30)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isNormal
                                          ? MocaColors.success
                                          : MocaColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Risk Assessment Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.analytics_outlined,
                                  color: MocaColors.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Pagsusuri ng Panganib',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Risk Level Badge
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getRiskColor(
                                  probabilityResult.riskLevel,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getRiskColor(
                                    probabilityResult.riskLevel,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    probabilityResult.riskLevel,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _getRiskColor(
                                        probabilityResult.riskLevel,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    probabilityResult.riskDescription,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: MocaColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Probability Bars
                            _buildProbabilityBar(
                              'Normal',
                              probabilityResult.normalProbability,
                              MocaColors.success,
                            ),
                            const SizedBox(height: 8),
                            _buildProbabilityBar(
                              'MCI',
                              probabilityResult.mciProbability,
                              MocaColors.warning,
                            ),
                            const SizedBox(height: 8),
                            _buildProbabilityBar(
                              'Dementia',
                              probabilityResult.dementiaProbability,
                              MocaColors.error,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tandaan: Ang mga probabilidad na ito ay mga tantiya batay sa MoCA scores. Ang pormal na diagnosis ay nangangailangan ng komprehensibong klinikal na ebalwasyon.',
                              style: TextStyle(
                                fontSize: 10,
                                color: MocaColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Section Breakdown
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detalye ng Bawat Seksyon',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSectionRow(
                              'Visuospatial/Executive',
                              assessment
                                      .sectionResults['visuospatial']?.score ??
                                  0,
                              5,
                              MocaColors.visuospatialColor,
                            ),
                            _buildSectionRow(
                              'Naming / Pagpapangalan',
                              assessment.sectionResults['naming']?.score ?? 0,
                              3,
                              MocaColors.namingColor,
                            ),
                            _buildSectionRow(
                              'Attention / Atensyon',
                              assessment.sectionResults['attention']?.score ??
                                  0,
                              6,
                              MocaColors.attentionColor,
                            ),
                            _buildSectionRow(
                              'Language / Wika',
                              assessment.sectionResults['language']?.score ?? 0,
                              3,
                              MocaColors.languageColor,
                            ),
                            _buildSectionRow(
                              'Abstraction / Abstraksiyon',
                              assessment.sectionResults['abstraction']?.score ??
                                  0,
                              2,
                              MocaColors.abstractionColor,
                            ),
                            _buildSectionRow(
                              'Delayed Recall / Pag-alala',
                              assessment
                                      .sectionResults['delayedRecall']?.score ??
                                  0,
                              5,
                              MocaColors.recallColor,
                            ),
                            _buildSectionRow(
                              'Orientation / Oryentasyon',
                              assessment.sectionResults['orientation']?.score ??
                                  0,
                              6,
                              MocaColors.orientationColor,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Saving indicator
                    if (state.isSaving)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: MocaColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Sine-save ang pagtatasa...'),
                          ],
                        ),
                      )
                    else if (state.isSaved)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: MocaColors.successLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: MocaColors.success),
                            const SizedBox(width: 12),
                            const Text(
                              'Matagumpay na na-save ang pagtatasa',
                              style: TextStyle(color: MocaColors.success),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: state.isSaving
                                ? null
                                : () {
                                    context.read<MocaAssessmentBloc>().add(
                                          MocaResetAssessment(),
                                        );
                                    context.go('/residents');
                                  },
                            icon: const Icon(Icons.people),
                            label: const Text('Bumalik sa Residente'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: state.isSaving
                                ? null
                                : () {
                                    context.read<MocaAssessmentBloc>().add(
                                          MocaResetAssessment(),
                                        );
                                    context.go('/dashboard');
                                  },
                            icon: const Icon(Icons.home),
                            label: const Text('Umuwi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionRow(String name, int score, int maxScore, Color color) {
    final percentage = maxScore > 0 ? score / maxScore : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                '$score/$maxScore',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityBar(String label, double probability, Color color) {
    final percentage = (probability * 100).toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: probability,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'Low Risk':
        return MocaColors.success;
      case 'Low-Moderate Risk':
        return const Color(0xFF8BC34A); // Light green
      case 'Moderate Risk':
        return MocaColors.warning;
      case 'High Risk':
        return const Color(0xFFFF5722); // Deep orange
      case 'Very High Risk':
        return MocaColors.error;
      default:
        return MocaColors.textSecondary;
    }
  }
}
