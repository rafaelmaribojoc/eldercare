import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../bloc/moca_assessment_bloc.dart';
import '../constants/moca_colors.dart';
import '../widgets/section_header.dart';

class OrientationScreen extends StatefulWidget {
  const OrientationScreen({super.key});

  @override
  State<OrientationScreen> createState() => _OrientationScreenState();
}

class _OrientationScreenState extends State<OrientationScreen> {
  bool _dateCorrect = false;
  bool _monthCorrect = false;
  bool _yearCorrect = false;
  bool _dayCorrect = false;
  bool _placeCorrect = false;
  bool _cityCorrect = false;

  int get totalScore {
    int score = 0;
    if (_dateCorrect) score++;
    if (_monthCorrect) score++;
    if (_yearCorrect) score++;
    if (_dayCorrect) score++;
    if (_placeCorrect) score++;
    if (_cityCorrect) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Orientation / Oryentasyon',
            subtitle: 'Pagtatasa ng kamalayan sa oras at lugar',
            currentSection: 8,
            totalSections: 8,
            color: MocaColors.orientationColor,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current date reference
                  Card(
                    color: MocaColors.orientationColor.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: MocaColors.orientationColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Petsa Ngayon (para sa sanggunian)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: MocaColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('EEEE, MMMM d, yyyy').format(now),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: MocaColors.orientationColor,
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

                  Text(
                    'Oryentasyon sa Oras (4 na puntos)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  _buildOrientationItem(
                    label: 'Petsa',
                    hint: 'Ano ang petsa ngayon?',
                    correctAnswer: now.day.toString(),
                    isCorrect: _dateCorrect,
                    onChanged: (v) => setState(() => _dateCorrect = v),
                  ),
                  _buildOrientationItem(
                    label: 'Buwan',
                    hint: 'Anong buwan ngayon?',
                    correctAnswer: DateFormat('MMMM').format(now),
                    isCorrect: _monthCorrect,
                    onChanged: (v) => setState(() => _monthCorrect = v),
                  ),
                  _buildOrientationItem(
                    label: 'Taon',
                    hint: 'Anong taon ngayon?',
                    correctAnswer: now.year.toString(),
                    isCorrect: _yearCorrect,
                    onChanged: (v) => setState(() => _yearCorrect = v),
                  ),
                  _buildOrientationItem(
                    label: 'Araw ng Linggo',
                    hint: 'Anong araw ng linggo ngayon?',
                    correctAnswer: DateFormat('EEEE').format(now),
                    isCorrect: _dayCorrect,
                    onChanged: (v) => setState(() => _dayCorrect = v),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Oryentasyon sa Lugar (2 puntos)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  _buildOrientationItem(
                    label: 'Lugar',
                    hint: 'Saan tayo ngayon? (gusali/lokasyon)',
                    correctAnswer: 'Varies',
                    isCorrect: _placeCorrect,
                    onChanged: (v) => setState(() => _placeCorrect = v),
                  ),
                  _buildOrientationItem(
                    label: 'Lungsod',
                    hint: 'Anong lungsod/bayan tayo ngayon?',
                    correctAnswer: 'Varies',
                    isCorrect: _cityCorrect,
                    onChanged: (v) => setState(() => _cityCorrect = v),
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

  Widget _buildOrientationItem({
    required String label,
    required String hint,
    required String correctAnswer,
    required bool isCorrect,
    required Function(bool) onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hint,
                        style: const TextStyle(
                          color: MocaColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (correctAnswer != 'Varies')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: MocaColors.orientationColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      correctAnswer,
                      style: TextStyle(
                        color: MocaColors.orientationColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildScoreToggle('Nasagot nang tama', isCorrect, onChanged),
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
                      color: MocaColors.orientationColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Score: $totalScore/6',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: MocaColors.fontFamily,
                        fontWeight: FontWeight.bold,
                        color: MocaColors.orientationColor,
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
                          onPressed: _onComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MocaColors.orientationColor,
                          ),
                          child: Text(
                            'Complete',
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
                        color: MocaColors.orientationColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Score: $totalScore/6',
                        style: TextStyle(
                          fontFamily: MocaColors.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: MocaColors.orientationColor,
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
                    onPressed: _onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MocaColors.orientationColor,
                    ),
                    child: Text(
                      'Complete',
                      style: TextStyle(fontFamily: MocaColors.fontFamily),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _onBack() {
    context.go('/moca/delayed-recall');
  }

  Future<void> _onComplete() async {
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
            section: 'orientation',
            score: totalScore,
            maxScore: 6,
            details: {
              'date': _dateCorrect,
              'month': _monthCorrect,
              'year': _yearCorrect,
              'day': _dayCorrect,
              'place': _placeCorrect,
              'city': _cityCorrect,
            },
          ),
        );
    context.read<MocaAssessmentBloc>().add(MocaCompleteAssessment());
    context.go('/moca/complete');
  }
}
