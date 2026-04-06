import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/resident_model.dart';
import '../../moca/bloc/moca_assessment_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../moca/constants/moca_colors.dart';
import 'modern_notes/modern_resident_notes_sheet.dart';

class ResidentActionSheet extends StatelessWidget {
  final ResidentModel resident;

  const ResidentActionSheet({super.key, required this.resident});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isPsych = user?.unit == 'psych';
    final canMakeNotes = AppConstants.canMakeNotesForResident(
      role: user?.role,
      unit: user?.unit,
      userId: user?.id,
      residentSocialWorkerId: resident.socialWorkerId,
      residentHouseparentId: resident.houseparentId,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                backgroundImage: resident.photoUrl != null
                    ? CachedNetworkImageProvider(resident.photoUrl!)
                    : null,
                child: resident.photoUrl == null
                    ? Text(
                        resident.firstName[0],
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resident.fullName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      resident.displayLocation,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Actions Grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5, // Wide buttons
            physics: const NeverScrollableScrollPhysics(),
            children: [
              if (canMakeNotes)
                _ActionButton(
                  icon: Icons.note_add,
                  label: 'Quick Note',
                  color: AppColors.warning,
                  onTap: () {
                    Navigator.pop(context); // Close sheet first
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => ModernResidentNotesSheet(
                        residentId: resident.id,
                        residentName: resident.fullName,
                      ),
                    );
                  },
                ),
              _ActionButton(
                icon: Icons.person,
                label: 'View Profile',
                color: AppColors.primary,
                onTap: () {
                  Navigator.pop(context);
                  context.push('/residents/${resident.id}');
                },
              ),
              _ActionButton(
                icon: Icons.local_hospital,
                label: 'Vitals / Meds',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to vitals/forms - For now go to profile
                  context.push('/residents/${resident.id}');
                },
              ),
              if (isPsych)
                _ActionButton(
                  icon: Icons.psychology,
                  label: 'MoCA Test',
                  color: MocaColors.primary,
                  onTap: () {
                    Navigator.pop(context);
                    _startMoca(context);
                  },
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _startMoca(BuildContext context) {
    // Logic similar to ResidentDetailScreen
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    context.read<MocaAssessmentBloc>().add(
          MocaStartAssessment(
            residentId: resident.id,
            clinicianId: user?.id,
            residentName: resident.fullName,
            residentSex: resident.gender,
            residentBirthday: resident.dateOfBirth,
            educationYears: 0,
            educationAdjustment: true,
          ),
        );
    context.go('/moca/visuospatial');
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
