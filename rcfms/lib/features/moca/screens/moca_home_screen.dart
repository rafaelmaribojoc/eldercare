import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/resident_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/moca_assessment_bloc.dart';
import '../constants/moca_colors.dart';

class MocaHomeScreen extends StatelessWidget {
  final String? residentId;
  final ResidentModel? resident;

  const MocaHomeScreen({super.key, this.residentId, this.resident});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final mocaState = context.watch<MocaAssessmentBloc>().state;
    final assessment = mocaState.assessment;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),

                      // Resident info from assessment (auto-filled)
                      if (assessment?.residentName != null) ...[
                        const SizedBox(height: 24),
                        _buildResidentInfoCard(context, assessment!),
                      ] else if (resident != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: MocaColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.user,
                                color: MocaColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Resident',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: MocaColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${resident!.firstName} ${resident!.lastName}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: MocaColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tungkol sa MoCA-P Test',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                LucideIcons.timer,
                                '10-15 minuto',
                                'Tinatayang tagal',
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                LucideIcons.listOrdered,
                                '8 seksyon',
                                'Mga cognitive domain na sinusubok',
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                LucideIcons.gauge,
                                '30 puntos',
                                'Pinakamataas na iskor (≥26 normal)',
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sections Overview
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mga Seksyon ng Pagtatasa',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSectionItem(
                                '1. Visuospatial/Executive',
                                '5 pts',
                                MocaColors.visuospatialColor,
                              ),
                              _buildSectionItem(
                                '2. Naming / Pagpapangalan',
                                '3 pts',
                                MocaColors.namingColor,
                              ),
                              _buildSectionItem(
                                '3. Memory / Memorya',
                                'Walang pts',
                                MocaColors.memoryColor,
                              ),
                              _buildSectionItem(
                                '4. Attention / Atensyon',
                                '6 pts',
                                MocaColors.attentionColor,
                              ),
                              _buildSectionItem(
                                '5. Language / Wika',
                                '3 pts',
                                MocaColors.languageColor,
                              ),
                              _buildSectionItem(
                                '6. Abstraction / Abstraksiyon',
                                '2 pts',
                                MocaColors.abstractionColor,
                              ),
                              _buildSectionItem(
                                '7. Delayed Recall / Pag-alala',
                                '5 pts',
                                MocaColors.recallColor,
                              ),
                              _buildSectionItem(
                                '8. Orientation / Oryentasyon',
                                '6 pts',
                                MocaColors.orientationColor,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FloatingActionButton.extended(
            onPressed: () {
              // Only start a new assessment if one doesn't already exist with resident data
              // This preserves the assessment created from resident detail screen
              if (assessment == null || assessment.residentId == null) {
                final clinicianId = user?.id;
                // Use resident parameter if available for resident details
                context.read<MocaAssessmentBloc>().add(
                      MocaStartAssessment(
                        residentId: residentId ?? resident?.id,
                        clinicianId: clinicianId,
                        residentName: resident?.fullName,
                        residentSex: resident?.gender,
                        residentBirthday: resident?.dateOfBirth,
                        educationYears: 0,
                        educationAdjustment: false,
                      ),
                    );
              }
              context.go('/moca/visuospatial');
            },
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            label: Text(
              'Simulan ang Pagtatasa',
              style: TextStyle(
                fontFamily: MocaColors.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: MocaColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: MocaColors.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: MocaColors.textSecondary,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionItem(String name, String points, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text(
            points,
            style: TextStyle(
              color: MocaColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build resident info card with auto-filled details
  Widget _buildResidentInfoCard(BuildContext context, assessment) {
    final birthday = assessment.residentBirthday;
    final age = birthday != null
        ? DateTime.now().difference(birthday).inDays ~/ 365
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MocaColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MocaColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.user, color: MocaColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Residente',
                      style: TextStyle(
                        fontSize: 12,
                        color: MocaColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${resident!.firstName} ${resident!.lastName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: MocaColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (assessment.educationAdjustment)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: MocaColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+1 pt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: MocaColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Sex',
                  assessment.residentSex ?? 'N/A',
                  LucideIcons.toilet,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Age',
                  age != null ? '$age years' : 'N/A',
                  LucideIcons.cake,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Date',
                  DateFormat('MMM d, y').format(DateTime.now()),
                  LucideIcons.calendar,
                ),
              ),
            ],
          ),
          if (assessment.educationYears > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(LucideIcons.graduationCap,
                    size: 16, color: MocaColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Edukasyon: ${assessment.educationYears} taon',
                  style: const TextStyle(
                    fontSize: 12,
                    color: MocaColors.textSecondary,
                  ),
                ),
                if (assessment.educationYears < 12) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '(+1 puntos na pagsasaayos)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: MocaColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: MocaColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: MocaColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
