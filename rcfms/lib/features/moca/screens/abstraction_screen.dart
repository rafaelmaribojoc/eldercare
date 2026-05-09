import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/moca_assessment_bloc.dart';
import '../constants/moca_constants.dart';
import '../constants/moca_colors.dart';
import '../widgets/section_header.dart';

class AbstractionScreen extends StatefulWidget {
  const AbstractionScreen({super.key});

  @override
  State<AbstractionScreen> createState() => _AbstractionScreenState();
}

class _AbstractionScreenState extends State<AbstractionScreen> {
  final List<bool> _scores = [false, false];

  int get totalScore => _scores.where((s) => s).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Abstraction / Abstraksiyon',
            subtitle: 'Hanapin ang pagkakapareho ng mga bagay',
            currentSection: 6,
            totalSections: 8,
            color: MocaColors.abstractionColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: MocaColors.infoLight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: MocaColors.info,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Itanong: "Paano magkapareho ang dalawang ito?" Kailangang magbigay ng pangkategoryang sagot ang pasyente.',
                              style: TextStyle(color: MocaColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Example
                  Card(
                    color: MocaColors.background,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: MocaColors.textSecondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'HALIMBAWA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildItemPair(MocaConstants.abstractionExampleItem1, MocaConstants.abstractionExampleItem2),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check, color: MocaColors.success),
                                const SizedBox(width: 8),
                                Text(
                                  'Tamang sagot: "${MocaConstants.abstractionExampleAnswer}"',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  ...MocaConstants.abstractionPairs.asMap().entries.map((
                    entry,
                  ) {
                    final index = entry.key;
                    final pair = entry.value;
                    return _buildAbstractionCard(
                      index: index,
                      item1: pair['item1'] as String,
                      item2: pair['item2'] as String,
                      acceptedAnswers: List<String>.from(
                        pair['acceptedAnswers'],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildItemPair(String item1, String item2) {
    // Use Wrap to prevent overflow on small screens
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildItemChip(item1),
          Text(
            '&',
            style: TextStyle(
              fontFamily: MocaColors.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          _buildItemChip(item2),
        ],
      ),
    );
  }

  Widget _buildItemChip(String item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      constraints: const BoxConstraints(maxWidth: 140),
      decoration: BoxDecoration(
        color: MocaColors.abstractionColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        item.toUpperCase(),
        style: TextStyle(
          fontFamily: MocaColors.fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildAbstractionCard({
    required int index,
    required String item1,
    required String item2,
    required List<String> acceptedAnswers,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pares ${index + 1} (1 puntos)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildItemPair(item1, item2),
            const SizedBox(height: 16),
            Text(
              'Mga tinatanggap na sagot: ${acceptedAnswers.join(", ")}',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: MocaColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _buildScoreToggle(
              'Nasagot nang tama (pangkategorya)',
              _scores[index],
              (value) => setState(() => _scores[index] = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreToggle(String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: value ? MocaColors.successLight : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          splashColor: (value ? MocaColors.success : MocaColors.primary)
              .withOpacity(0.1),
          highlightColor: (value ? MocaColors.success : MocaColors.primary)
              .withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: value ? MocaColors.success : MocaColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  value ? Icons.check_circle : Icons.circle_outlined,
                  color: value ? MocaColors.success : MocaColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color:
                          value ? MocaColors.success : MocaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: isSmallScreen
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: MocaColors.abstractionColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Score: $totalScore/2',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: MocaColors.fontFamily,
                        fontWeight: FontWeight.bold,
                        color: MocaColors.abstractionColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _onBack,
                          child: Text(
                            'Back',
                            style: TextStyle(fontFamily: MocaColors.fontFamily),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _onContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MocaColors.abstractionColor,
                          ),
                          child: Text(
                            'Continue',
                            style: TextStyle(fontFamily: MocaColors.fontFamily),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: MocaColors.abstractionColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Score: $totalScore/2',
                        style: TextStyle(
                          fontFamily: MocaColors.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: MocaColors.abstractionColor,
                        ),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _onBack,
                    child: Text(
                      'Back',
                      style: TextStyle(fontFamily: MocaColors.fontFamily),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MocaColors.abstractionColor,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(fontFamily: MocaColors.fontFamily),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _onBack() {
    context.go('/moca/language');
  }

  Future<void> _onContinue() async {
    if (totalScore == 0) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Continue'),
          content: const Text(
            'The score for this section is 0. Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (shouldContinue != true || !mounted) return;
    }

    context.read<MocaAssessmentBloc>().add(
          MocaSaveSectionResult(
            section: 'abstraction',
            score: totalScore,
            maxScore: 2,
          ),
        );
    context.read<MocaAssessmentBloc>().add(MocaNextSection());
    context.go('/moca/delayed-recall');
  }
}
