import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/moca_assessment_bloc.dart';
import '../constants/moca_constants.dart';
import '../constants/moca_colors.dart';
import '../widgets/section_header.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _sentence1Correct = false;
  bool _sentence2Correct = false;

  int _wordCount = 0;
  bool _timerStarted = false;
  bool _timerCompleted = false;
  int _remainingSeconds = MocaConstants.fluencyDurationSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  int get totalScore {
    int score = 0;
    if (_sentence1Correct) score++;
    if (_sentence2Correct) score++;
    if (_wordCount >= MocaConstants.fluencyMinimumWords) score++;
    return score;
  }

  void _startTimer() {
    setState(() {
      _timerStarted = true;
      _remainingSeconds = MocaConstants.fluencyDurationSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        setState(() => _timerCompleted = true);
      }
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timerStarted = false;
      _timerCompleted = false;
      _remainingSeconds = MocaConstants.fluencyDurationSeconds;
      _wordCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Language / Wika',
            subtitle: 'Pag-uulit ng pangungusap at verbal fluency',
            currentSection: 5,
            totalSections: 8,
            color: MocaColors.languageColor,
          ),
          TabBar(
            controller: _tabController,
            labelColor: MocaColors.languageColor,
            unselectedLabelColor: MocaColors.textSecondary,
            indicatorColor: MocaColors.languageColor,
            tabs: const [
              Tab(text: 'Pag-uulit'),
              Tab(text: 'Fluency'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildRepetition(), _buildFluency()],
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildRepetition() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pag-uulit ng Pangungusap (2 puntos)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
              'Basahin ang bawat pangungusap nang isang beses. Kailangang ulitin nang eksakto ng pasyente.'),
          const SizedBox(height: 24),
          _buildSentenceCard(
            1,
            MocaConstants.repetitionSentences[0],
            _sentence1Correct,
            (v) => setState(() => _sentence1Correct = v),
          ),
          const SizedBox(height: 16),
          _buildSentenceCard(
            2,
            MocaConstants.repetitionSentences[1],
            _sentence2Correct,
            (v) => setState(() => _sentence2Correct = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceCard(
    int index,
    String sentence,
    bool isCorrect,
    Function(bool) onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: MocaColors.languageColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Pangungusap $index',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: MocaColors.languageColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '"$sentence"',
                style: const TextStyle(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildScoreToggle('Naulit nang tama', isCorrect, onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildFluency() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verbal Fluency (1 puntos)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: MocaColors.fontFamily,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Magbanggit ng pinakamaraming salitang nagsisimula sa letrang "${MocaConstants.fluencyLetter}" sa loob ng 60 segundo.',
          ),
          const SizedBox(height: 24),
          // Timer card - centered
          Center(
            child: Card(
              color: _timerCompleted
                  ? MocaColors.successLight
                  : MocaColors.languageColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _timerStarted
                          ? '${_remainingSeconds}s'
                          : '${MocaConstants.fluencyDurationSeconds}s',
                      style: TextStyle(
                        fontFamily: MocaColors.fontFamily,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _timerCompleted
                            ? MocaColors.success
                            : MocaColors.languageColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_timerStarted)
                      ElevatedButton.icon(
                        onPressed: _startTimer,
                        icon: const Icon(LucideIcons.play),
                        label: Text(
                          'Simulan ang Timer',
                          style: TextStyle(fontFamily: MocaColors.fontFamily),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MocaColors.languageColor,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else if (!_timerCompleted)
                      ElevatedButton.icon(
                        onPressed: _resetTimer,
                        icon: const Icon(LucideIcons.refreshCw),
                        label: Text(
                          'Reset',
                          style: TextStyle(fontFamily: MocaColors.fontFamily),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MocaColors.error,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      Text(
                        'Tapos na ang oras!',
                        style: TextStyle(
                          fontFamily: MocaColors.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: MocaColors.success,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Word Count - centered and responsive
          Center(
            child: Text(
              'Bilang ng Salita:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: MocaColors.fontFamily,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _wordCount > 0
                      ? () => setState(() => _wordCount--)
                      : null,
                  icon: const Icon(LucideIcons.circleMinus),
                  iconSize: 32,
                  color: MocaColors.languageColor,
                ),
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: MocaColors.languageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$_wordCount',
                      style: TextStyle(
                        fontFamily: MocaColors.fontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: MocaColors.languageColor,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _wordCount++),
                  icon: const Icon(LucideIcons.circlePlus),
                  iconSize: 32,
                  color: MocaColors.languageColor,
                ),
              ],
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
                  const Icon(LucideIcons.info, color: MocaColors.info),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '1 puntos kung ≥${MocaConstants.fluencyMinimumWords} salita. Kasalukuyan: ${_wordCount >= MocaConstants.fluencyMinimumWords ? "Pasado ✓" : "Kailangan pa ng salita"}',
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
                  value ? LucideIcons.circleCheck : LucideIcons.circle,
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
                      color: MocaColors.languageColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Score: $totalScore/3',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: MocaColors.fontFamily,
                        fontWeight: FontWeight.bold,
                        color: MocaColors.languageColor,
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
                            backgroundColor: MocaColors.languageColor,
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
                        color: MocaColors.languageColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Score: $totalScore/3',
                        style: TextStyle(
                          fontFamily: MocaColors.fontFamily,
                          fontWeight: FontWeight.bold,
                          color: MocaColors.languageColor,
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
                      backgroundColor: MocaColors.languageColor,
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
            section: 'language',
            score: totalScore,
            maxScore: 3,
            details: {
              'sentence1': _sentence1Correct,
              'sentence2': _sentence2Correct,
              'fluency_count': _wordCount,
            },
          ),
        );
    context.read<MocaAssessmentBloc>().add(MocaNextSection());
    context.go('/moca/abstraction');
  }

  void _onBack() {
    // If section has tabs, Back goes to the previous tab first.
    if (_tabController.index > 0) {
      _tabController.animateTo(_tabController.index - 1);
      return;
    }

    // Previous section.
    context.go('/moca/attention');
  }
}
