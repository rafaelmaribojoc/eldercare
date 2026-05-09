import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/moca_assessment_bloc.dart';
import '../constants/moca_constants.dart';
import '../constants/moca_colors.dart';
import '../widgets/section_header.dart';

class DelayedRecallScreen extends StatefulWidget {
  const DelayedRecallScreen({super.key});

  @override
  State<DelayedRecallScreen> createState() => _DelayedRecallScreenState();
}

class _DelayedRecallScreenState extends State<DelayedRecallScreen> {
  final List<bool> _uncuedRecall = [false, false, false, false, false];
  final List<bool> _categoryRecall = [false, false, false, false, false];
  final List<bool> _multipleChoiceRecall = [false, false, false, false, false];

  List<String> get _categoryHints => MocaConstants.memoryCategoryHints;

  int get totalScore => _uncuedRecall.where((r) => r).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Delayed Recall / Naantalang Pag-alala',
            subtitle: 'Alalahanin ang mga salita mula kanina nang walang tulong',
            currentSection: 7,
            totalSections: 8,
            color: MocaColors.recallColor,
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
                              'Hilingin sa pasyente na alalahanin ang mga salita mula sa seksyon ng memorya. Ang LIBRENG pag-alala LAMANG ang may puntos.',
                              style: TextStyle(color: MocaColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Libreng Pag-alala (5 puntos)',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Itanong: "Ano ang 5 salitang pinaaalala ko sa iyo kanina?"',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: MocaConstants.memoryWords.asMap().entries.map(
                          (entry) {
                            final index = entry.key;
                            final word = entry.value;
                            return _buildWordRow(index, word);
                          },
                        ).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildCategoryExpansionTile(),
                  const SizedBox(height: 16),
                  _buildMultipleChoiceExpansionTile(),
                  const SizedBox(height: 24),
                  Card(
                    color: MocaColors.warningLight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: MocaColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ang LIBRENG pag-alala lamang ang may puntos. Ang mga pahiwatig at multiple choice ay para sa klinikal na impormasyon lamang.',
                              style: TextStyle(color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildWordRow(int index, String word) {
    final isRecalled = _uncuedRecall[index];
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          setState(() {
            _uncuedRecall[index] = !isRecalled;
            if (!isRecalled) {
              // If marking as recalled, clear cues
              _categoryRecall[index] = false;
              _multipleChoiceRecall[index] = false;
            }
          });
        },
        splashColor: MocaColors.success.withOpacity(0.15),
        highlightColor: MocaColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isRecalled
                ? MocaColors.success.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isRecalled ? MocaColors.success : MocaColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isRecalled
                      ? MocaColors.success
                      : MocaColors.recallColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: isRecalled
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: MocaColors.fontFamily,
                            fontWeight: FontWeight.bold,
                            color: MocaColors.recallColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  word,
                  style: TextStyle(
                    fontFamily: MocaColors.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isRecalled
                        ? MocaColors.textSecondary
                        : MocaColors.textPrimary,
                    // Strikethrough for recalled words
                    decoration: isRecalled ? TextDecoration.lineThrough : null,
                    decorationColor: MocaColors.success,
                    decorationThickness: 2,
                  ),
                ),
              ),
              Icon(
                isRecalled ? Icons.check_circle : Icons.circle_outlined,
                color:
                    isRecalled ? MocaColors.success : MocaColors.textSecondary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryExpansionTile() {
    return Card(
      child: ExpansionTile(
        title: Text(
          'Mga Pahiwatig ng Kategorya (opsyonal)',
          style: TextStyle(fontFamily: MocaColors.fontFamily),
        ),
        subtitle: Text(
          'Gamitin kung hindi naalala nang malaya',
          style: TextStyle(fontFamily: MocaColors.fontFamily, fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: MocaConstants.memoryWords.asMap().entries.map((entry) {
                final index = entry.key;
                final word = entry.value;
                final hint = _categoryHints[index];
                final isDisabled = _uncuedRecall[index];
                final isSelected = _categoryRecall[index];
                return InkWell(
                  onTap: isDisabled
                      ? null
                      : () => setState(
                            () => _categoryRecall[index] = !isSelected,
                          ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MocaColors.recallColor.withOpacity(0.1)
                          : (isDisabled
                              ? Colors.grey.withOpacity(0.1)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? MocaColors.recallColor
                            : (isDisabled
                                ? Colors.grey.shade300
                                : MocaColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isDisabled
                              ? Colors.grey.shade400
                              : (isSelected
                                  ? MocaColors.recallColor
                                  : MocaColors.textSecondary),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                word,
                                style: TextStyle(
                                  fontFamily: MocaColors.fontFamily,
                                  fontWeight: FontWeight.w500,
                                  color: isDisabled
                                      ? Colors.grey
                                      : MocaColors.textPrimary,
                                  decoration: isDisabled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              Text(
                                'Pahiwatig: $hint',
                                style: TextStyle(
                                  fontFamily: MocaColors.fontFamily,
                                  fontSize: 12,
                                  color: MocaColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleChoiceExpansionTile() {
    return Card(
      child: ExpansionTile(
        title: Text(
          'Multiple Choice (opsyonal)',
          style: TextStyle(fontFamily: MocaColors.fontFamily),
        ),
        subtitle: Text(
          'Gamitin kung hindi gumana ang pahiwatig',
          style: TextStyle(fontFamily: MocaColors.fontFamily, fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: MocaConstants.memoryWords.asMap().entries.map((entry) {
                final index = entry.key;
                final word = entry.value;
                final isDisabled =
                    _uncuedRecall[index] || _categoryRecall[index];
                final isSelected = _multipleChoiceRecall[index];
                return InkWell(
                  onTap: isDisabled
                      ? null
                      : () => setState(
                            () => _multipleChoiceRecall[index] = !isSelected,
                          ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? MocaColors.recallColor.withOpacity(0.1)
                          : (isDisabled
                              ? Colors.grey.withOpacity(0.1)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? MocaColors.recallColor
                            : (isDisabled
                                ? Colors.grey.shade300
                                : MocaColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isDisabled
                              ? Colors.grey.shade400
                              : (isSelected
                                  ? MocaColors.recallColor
                                  : MocaColors.textSecondary),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            word,
                            style: TextStyle(
                              fontFamily: MocaColors.fontFamily,
                              fontWeight: FontWeight.w500,
                              color: isDisabled
                                  ? Colors.grey
                                  : MocaColors.textPrimary,
                              decoration: isDisabled
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
                      color: MocaColors.recallColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Score: $totalScore/5 (uncued only)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: MocaColors.fontFamily,
                        fontWeight: FontWeight.bold,
                        color: MocaColors.recallColor,
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
                            backgroundColor: MocaColors.recallColor,
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
                        color: MocaColors.recallColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Score: $totalScore/5 (uncued only)',
                        style: TextStyle(
                          fontFamily: MocaColors.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: MocaColors.recallColor,
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
                      backgroundColor: MocaColors.recallColor,
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
    context.go('/moca/abstraction');
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
            section: 'delayedRecall',
            score: totalScore,
            maxScore: 5,
            details: {
              'uncued': _uncuedRecall,
              'category': _categoryRecall,
              'multiple_choice': _multipleChoiceRecall,
            },
          ),
        );
    context.read<MocaAssessmentBloc>().add(MocaNextSection());
    context.go('/moca/orientation');
  }
}
