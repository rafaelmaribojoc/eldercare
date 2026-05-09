import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/moca_assessment_bloc.dart';
import '../constants/moca_constants.dart';
import '../constants/moca_colors.dart';
import '../widgets/section_header.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  int _currentTrial = 1;
  final List<List<bool>> _trialResults = [
    [false, false, false, false, false],
    [false, false, false, false, false],
  ];
  bool _wordsShown = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Memory / Memorya',
            subtitle: 'Pag-aaral ng listahan ng salita - 2 pagsubok',
            currentSection: 3,
            totalSections: 8,
            color: MocaColors.memoryColor,
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
                              'Basahin nang malakas ang mga salita sa pasyente, isang salita bawat segundo. Kailangan nilang ulitin ang lahat ng salita. Gawin ng 2 beses.',
                              style: TextStyle(color: MocaColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Mga Salitang Tatandaan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (!_wordsShown)
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _wordsShown = true),
                        icon: const Icon(Icons.visibility),
                        label: const Text('Ipakita ang mga Salita'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MocaColors.memoryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    )
                  else
                    _buildWordsList(),
                  if (_wordsShown) ...[
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Text(
                          'Pagsubok $_currentTrial ng 2',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (_currentTrial == 1)
                          TextButton(
                            onPressed: () => setState(() => _currentTrial = 2),
                            child: const Text('Pumunta sa Pagsubok 2'),
                          ),
                        if (_currentTrial == 2)
                          TextButton(
                            onPressed: () => setState(() => _currentTrial = 1),
                            child: const Text('Bumalik sa Pagsubok 1'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTrialChecklist(),
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
                                'Walang puntos na ibibigay ngayon. Ang mga salitang ito ay itatanong ulit sa seksyon ng Delayed Recall.',
                                style: TextStyle(color: Colors.orange[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildWordsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: MocaConstants.memoryWords.asMap().entries.map((entry) {
            final index = entry.key;
            final word = entry.value;
            return Container(
              margin: EdgeInsets.only(bottom: index < 4 ? 12 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: MocaColors.memoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: MocaColors.memoryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    word,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: MocaColors.memoryColor,
                        ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTrialChecklist() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Markahan ang mga salitang naalala:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...MocaConstants.memoryWords.asMap().entries.map((entry) {
              final index = entry.key;
              final word = entry.value;
              final isRecalled = _trialResults[_currentTrial - 1][index];
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _trialResults[_currentTrial - 1][index] = !isRecalled;
                    });
                  },
                  splashColor: MocaColors.memoryColor.withOpacity(0.15),
                  highlightColor: MocaColors.memoryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isRecalled
                          ? MocaColors.memoryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isRecalled
                            ? MocaColors.memoryColor
                            : MocaColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isRecalled
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: isRecalled
                              ? MocaColors.memoryColor
                              : MocaColors.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            word,
                            style: TextStyle(
                              fontFamily: MocaColors.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isRecalled
                                  ? MocaColors.textSecondary
                                  : MocaColors.textPrimary,
                              // Strikethrough effect for recalled words
                              decoration: isRecalled
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: MocaColors.memoryColor,
                              decorationThickness: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final trial1Count = _trialResults[0].where((r) => r).length;
    final trial2Count = _trialResults[1].where((r) => r).length;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Score info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: MocaColors.memoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Pagsubok 1: $trial1Count/5 | Pagsubok 2: $trial2Count/5',
                    style: TextStyle(
                      fontFamily: MocaColors.fontFamily,
                      fontWeight: FontWeight.bold,
                      color: MocaColors.memoryColor,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Walang puntos - susubukin ulit mamaya',
                    style: TextStyle(
                      fontFamily: MocaColors.fontFamily,
                      fontSize: 11,
                      color: MocaColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onBack,
                    child: Text(
                      'Back',
                      style: TextStyle(
                        fontFamily: MocaColors.fontFamily,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MocaColors.memoryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        fontFamily: MocaColors.fontFamily,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onContinue() {
    // Store words for delayed recall
    context.read<MocaAssessmentBloc>().add(
          MocaSetMemoryWords(MocaConstants.memoryWords),
        );
    context.read<MocaAssessmentBloc>().add(
          MocaSaveSectionResult(
            section: 'memory',
            score: 0,
            maxScore: 0,
            details: {'trial1': _trialResults[0], 'trial2': _trialResults[1]},
          ),
        );
    context.read<MocaAssessmentBloc>().add(MocaNextSection());
    context.go('/moca/attention');
  }

  void _onBack() {
    context.go('/moca/naming');
  }
}
