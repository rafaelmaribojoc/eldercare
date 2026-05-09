import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/moca_assessment_bloc.dart';
import '../constants/moca_constants.dart';
import '../constants/moca_colors.dart';
import '../widgets/section_header.dart';

class NamingScreen extends StatefulWidget {
  const NamingScreen({super.key});

  @override
  State<NamingScreen> createState() => _NamingScreenState();
}

class _NamingScreenState extends State<NamingScreen> {
  final List<bool> _scores = [false, false, false];

  List<Map<String, String>> get _animals => MocaConstants.namingAnimalsFilipino;

  int get totalScore => _scores.where((s) => s).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SectionHeader(
            title: 'Naming / Pagpapangalan',
            subtitle: 'Tukuyin ang mga hayop na ipinakita sa ibaba',
            currentSection: 2,
            totalSections: 8,
            color: MocaColors.namingColor,
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _animals.length,
              itemBuilder: (context, index) => _buildAnimalCard(index),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(int index) {
    final animal = _animals[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MocaColors.namingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.pets,
                    size: 40,
                    color: MocaColors.namingColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hayop ${index + 1}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        animal['description']!,
                        style: TextStyle(
                          color: MocaColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tamang sagot: ${animal['filipino']} (${animal['english']})',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: MocaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildScoreToggle(
              'Nasagot nang tama',
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
    return Container(
      padding: const EdgeInsets.all(20),
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
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MocaColors.namingColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Score: $totalScore/3',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: MocaColors.namingColor,
                  ),
                ),
              ),
            ),
            OutlinedButton(
              onPressed: _onBack,
              child: const Text('Back'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: MocaColors.namingColor,
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  void _onBack() {
    context.go('/moca/visuospatial');
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
            section: 'naming',
            score: totalScore,
            maxScore: 3,
          ),
        );
    context.read<MocaAssessmentBloc>().add(MocaNextSection());
    context.go('/moca/memory');
  }
}
