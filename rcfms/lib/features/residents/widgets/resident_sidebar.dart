import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/ward_model.dart';

class ResidentSidebar extends StatelessWidget {
  final Map<String, dynamic> selectedFilter;
  final Function(Map<String, dynamic>) onFilterSelected;
  final List<WardModel> wards;
  final bool canAddResident;
  final VoidCallback? onAddResident; // New callback

  const ResidentSidebar({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.wards,
    this.canAddResident = false,
    this.onAddResident, // Optional
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'Resident Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (canAddResident)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddResident, // Use callback
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Add Resident'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildSectionHeader(context, 'OVERVIEW'),
                _buildNavItem(
                  context,
                  'All Residents',
                  LucideIcons.users,
                  {'type': 'all', 'value': 'All'},
                ),
                _buildNavItem(
                  context,
                  'Admitted',
                  LucideIcons.circleCheck,
                  {'type': 'status', 'value': 'admitted'},
                ),
                _buildNavItem(
                  context,
                  'Applications',
                  LucideIcons.fileUp,
                  {'type': 'status', 'value': 'pre_admission'},
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(context, 'WARDS'),
                ...wards.map((ward) => _buildNavItem(
                      context,
                      ward.name,
                      LucideIcons.doorOpen,
                      {'type': 'ward', 'value': ward.name},
                    )),
                if (wards.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'No wards available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildSectionHeader(context, 'ARCHIVE'),
                _buildNavItem(
                  context,
                  'Discharged',
                  LucideIcons.logOut,
                  {'type': 'status', 'value': 'discharged'},
                ),
                _buildNavItem(
                  context,
                  'Deceased',
                  LucideIcons.heartCrack,
                  {'type': 'status', 'value': 'deceased'},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String label, IconData icon,
      Map<String, dynamic> filter) {
    // Determine selection based on type and value
    final isSelected = selectedFilter['type'] == filter['type'] &&
        selectedFilter['value'] == filter['value'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AppColors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: InkWell(
          onTap: () => onFilterSelected(filter),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : Theme.of(context).iconTheme.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
