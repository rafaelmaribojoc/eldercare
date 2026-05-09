import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/repositories/resident_repository.dart';

/// Dialog for reassigning a social worker or houseparent to a resident.
/// [fieldType] is either 'social_worker' or 'houseparent'.
class ReassignStaffDialog extends StatefulWidget {
  final String residentId;
  final String residentName;
  final String fieldType; // 'social_worker' or 'houseparent'
  final String? currentStaffId;
  final String? currentStaffName;

  const ReassignStaffDialog({
    super.key,
    required this.residentId,
    required this.residentName,
    required this.fieldType,
    this.currentStaffId,
    this.currentStaffName,
  });

  @override
  State<ReassignStaffDialog> createState() => _ReassignStaffDialogState();
}

class _ReassignStaffDialogState extends State<ReassignStaffDialog> {
  List<Map<String, dynamic>> _staffList = [];
  String? _selectedStaffId;
  bool _isLoading = true;
  bool _isSaving = false;

  String get _unitFilter =>
      widget.fieldType == 'social_worker' ? 'social' : 'homelife';

  String get _label =>
      widget.fieldType == 'social_worker' ? 'Social Worker' : 'Houseparent';

  @override
  void initState() {
    super.initState();
    _selectedStaffId = widget.currentStaffId;
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    try {
      final repo = context.read<ResidentRepository>();
      final staff = await repo.getStaffByUnit(_unitFilter);
      if (!mounted) return;
      setState(() {
        _staffList = staff;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_selectedStaffId == null) return;
    if (_selectedStaffId == widget.currentStaffId) {
      Navigator.of(context).pop(false);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = context.read<ResidentRepository>();

      if (widget.fieldType == 'social_worker') {
        await repo.updateResident(
          id: widget.residentId,
          socialWorkerId: _selectedStaffId,
        );
      } else {
        await repo.updateResident(
          id: widget.residentId,
          houseparentId: _selectedStaffId,
        );
      }

      if (mounted) {
        final selectedName = _staffList.firstWhere(
            (s) => s['id'] == _selectedStaffId,
            orElse: () => {'full_name': 'Unknown'})['full_name'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_label reassigned to $selectedName'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reassign $_label: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reassign $_label'),
      content: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: Breakpoints.tablet, minHeight: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign a new $_label to ${widget.residentName}.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            if (widget.currentStaffName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(
                      'Current: ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                    Text(
                      widget.currentStaffName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_staffList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No $_label staff found in $_unitFilter unit.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedStaffId,
                decoration: InputDecoration(
                  labelText: 'Select $_label',
                  prefixIcon: const Icon(LucideIcons.user),
                ),
                items: _staffList
                    .map((s) => DropdownMenuItem<String>(
                          value: s['id'] as String,
                          child: Text(
                            '${s['full_name']}${s['role'] != null ? ' (${_formatRole(s['role'])})' : ''}',
                          ),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedStaffId = value),
                validator: (value) =>
                    value == null ? 'Please select a staff member' : null,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving || _selectedStaffId == null ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  String _formatRole(String role) {
    return role
        .replaceAll('_', ' ')
        .split(' ')
        .map(
            (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }
}
