import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/moca_assessment_bloc.dart';
import '../constants/moca_constants.dart';
import '../constants/moca_colors.dart';
import '../widgets/section_header.dart';

class AttentionScreen extends StatefulWidget {
  const AttentionScreen({super.key});

  @override
  State<AttentionScreen> createState() => _AttentionScreenState();
}

class _AttentionScreenState extends State<AttentionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _digitForwardCorrect = false;
  bool _digitBackwardCorrect = false;
  bool _vigilanceCorrect = false;
  int _serial7Score = 0;

  final List<bool> _serial7Answers = [false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get totalScore {
    int score = 0;
    if (_digitForwardCorrect) score++;
    if (_digitBackwardCorrect) score++;
    if (_vigilanceCorrect) score++;
    // Serial 7s: 3 points for 4-5 correct, 2 for 2-3, 1 for 1
    int correct = _serial7Answers.where((a) => a).length;
    if (correct >= 4) {
      score += 3;
    } else if (correct >= 2) {
      score += 2;
    } else if (correct >= 1) {
      score += 1;
    }
    _serial7Score =
        correct >= 4 ? 3 : (correct >= 2 ? 2 : (correct >= 1 ? 1 : 0));
    return score;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Attention / Atensyon',
            subtitle: 'Pagbabanggit ng numero, pagmamasid, at serial 7s',
            currentSection: 4,
            totalSections: 8,
            color: MocaColors.attentionColor,
          ),
          TabBar(
            controller: _tabController,
            labelColor: MocaColors.attentionColor,
            unselectedLabelColor: MocaColors.textSecondary,
            indicatorColor: MocaColors.attentionColor,
            tabs: const [
              Tab(text: 'Digits'),
              Tab(text: 'Vigilance'),
              Tab(text: 'Serial 7s'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDigitSpan(),
                _buildVigilance(),
                _buildSerial7s(),
              ],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildDigitSpan() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pasulong na Pagbanggit ng Numero (1 puntos)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: MocaColors.fontFamily,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Basahin ang mga numero, isa bawat segundo. Uulitin ng pasyente sa parehong pagkakasunod.',
          ),
          const SizedBox(height: 16),
          Card(
            color: MocaColors.attentionColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              // Use Wrap to prevent overflow on small screens
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: MocaConstants.digitSpanForward
                      .map((d) => _buildDigitCircle(d.toString()))
                      .toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildScoreToggle(
            'Naulit nang tama: 2-1-8-5-4',
            _digitForwardCorrect,
            (value) => setState(() => _digitForwardCorrect = value),
          ),
          const Divider(height: 40),
          Text(
            'Pabaliktad na Pagbanggit ng Numero (1 puntos)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: MocaColors.fontFamily,
                ),
          ),
          const SizedBox(height: 8),
          const Text('Uulitin ng pasyente ang mga numero sa PABALIKTAD na pagkakasunod.'),
          const SizedBox(height: 16),
          Card(
            color: MocaColors.attentionColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Use Wrap to prevent overflow on small screens
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: MocaConstants.digitSpanBackward
                        .map((d) => _buildDigitCircle(d.toString()))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tamang sagot: ${MocaConstants.digitSpanBackward.reversed.join('-')}',
                    style: TextStyle(
                      fontFamily: MocaColors.fontFamily,
                      color: MocaColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildScoreToggle(
            'Naulit nang tama nang pabaliktad: 2-4-7',
            _digitBackwardCorrect,
            (value) => setState(() => _digitBackwardCorrect = value),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitCircle(String digit) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: MocaColors.attentionColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          digit,
          style: const TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildVigilance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gawain sa Pagmamasid (1 puntos)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: MocaColors.fontFamily,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Basahin ang mga letra. Ang pasyente ay tatapik sa kamay tuwing maririnig ang letrang "A".',
          ),
          const SizedBox(height: 24),
          // MoCA-P style: centered, bold letters in bordered boxes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: MocaConstants.vigilanceLetters.split('').map((
                    letter,
                  ) {
                    final isTarget = letter == 'A';
                    return Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isTarget
                            ? MocaColors.attentionColor.withOpacity(0.15)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isTarget
                              ? MocaColors.attentionColor
                              : MocaColors.border,
                          width: isTarget ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          letter,
                          style: TextStyle(
                            fontFamily: MocaColors.fontFamily,
                            fontSize: 16,
                            // All letters are bold as per MoCA-P style
                            fontWeight: FontWeight.bold,
                            color: isTarget
                                ? MocaColors.attentionColor
                                : MocaColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: MocaColors.infoLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: MocaColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dapat tumapik ang pasyente ng 11 beses (isa bawat "A"). 1 puntos kung ≤2 mali.',
                      style: TextStyle(
                        fontFamily: MocaColors.fontFamily,
                        color: MocaColors.info,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildScoreToggle(
            'Natapos na may ≤2 mali',
            _vigilanceCorrect,
            (value) => setState(() => _vigilanceCorrect = value),
          ),
        ],
      ),
    );
  }

  Widget _buildSerial7s() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Serial 7 na Pagbabawas (3 puntos)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: MocaColors.fontFamily,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Simula sa 100, paulit-ulit na magbawas ng 7: 100, 93, 86, 79, 72, 65',
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...MocaConstants.serial7Answers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final answer = entry.value;
                    final previous = index == 0
                        ? 100
                        : MocaConstants.serial7Answers[index - 1];
                    final isCorrect = _serial7Answers[index];
                    return Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          setState(() => _serial7Answers[index] = !isCorrect);
                        },
                        splashColor:
                            MocaColors.attentionColor.withOpacity(0.15),
                        highlightColor:
                            MocaColors.attentionColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? MocaColors.attentionColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isCorrect
                                  ? MocaColors.attentionColor
                                  : MocaColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isCorrect
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: isCorrect
                                    ? MocaColors.attentionColor
                                    : MocaColors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '$previous - 7 = $answer',
                                  style: TextStyle(
                                    fontFamily: MocaColors.fontFamily,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: isCorrect
                                        ? MocaColors.textSecondary
                                        : MocaColors.textPrimary,
                                    // Strikethrough for correct answers
                                    decoration: isCorrect
                                        ? TextDecoration.lineThrough
                                        : null,
                                    decorationColor: MocaColors.attentionColor,
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
          ),
          const SizedBox(height: 16),
          // Scoring guide - centered and responsive
          Card(
            color: MocaColors.infoLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Pagmamarka:',
                    style: TextStyle(
                      fontFamily: MocaColors.fontFamily,
                      fontWeight: FontWeight.bold,
                      color: MocaColors.info,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '4-5 tama = 3 puntos\n2-3 tama = 2 puntos\n1 tama = 1 puntos\n0 tama = 0 puntos',
                    style: TextStyle(
                      fontFamily: MocaColors.fontFamily,
                      color: MocaColors.info,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: MocaColors.attentionColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Score: $totalScore/6',
                style: TextStyle(
                  fontFamily: MocaColors.fontFamily,
                  fontWeight: FontWeight.bold,
                  color: MocaColors.attentionColor,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
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
                      backgroundColor: MocaColors.attentionColor,
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

  Future<void> _onContinue() async {
    // If section has tabs, Continue advances through tabs first.
    if (_tabController.index < _tabController.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
      return;
    }

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
            section: 'attention',
            score: totalScore,
            maxScore: 6,
            details: {
              'digit_forward': _digitForwardCorrect,
              'digit_backward': _digitBackwardCorrect,
              'vigilance': _vigilanceCorrect,
              'serial7': _serial7Score,
            },
          ),
        );
    context.read<MocaAssessmentBloc>().add(MocaNextSection());
    context.go('/moca/language');
  }

  void _onBack() {
    // If section has tabs, Back goes to the previous tab first.
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
      return;
    }

    // Previous section.
    context.go('/moca/memory');
  }
}
