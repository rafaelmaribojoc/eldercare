import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/approval_repository.dart';

class ReviewerSelectionDialog extends StatefulWidget {
  final String serviceUnit;
  final String? currentUserId;
  final bool useUnitUsers;
  final String? recommendedReviewerName;

  const ReviewerSelectionDialog({
    super.key,
    required this.serviceUnit,
    this.currentUserId,
    this.useUnitUsers = false,
    this.recommendedReviewerName,
  });

  @override
  State<ReviewerSelectionDialog> createState() =>
      _ReviewerSelectionDialogState();
}

class _ReviewerSelectionDialogState extends State<ReviewerSelectionDialog> {
  final ApprovalRepository _approvalRepository = ApprovalRepository();
  List<UserModel> _approvers = [];
  bool _isLoading = true;
  String? _selectedApproverId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchApprovers();
  }

  Future<void> _fetchApprovers() async {
    try {
      final approvers = widget.useUnitUsers
          ? await _approvalRepository.getUsersByUnit(widget.serviceUnit)
          : await _approvalRepository.getApprovalRecipients(
              excludeUserId: widget.currentUserId,
              serviceUnit: widget.serviceUnit,
            );

      if (mounted) {
        setState(() {
          _approvers = widget.currentUserId == null
              ? approvers
              : approvers.where((u) => u.id != widget.currentUserId).toList();
          _isLoading = false;
          _autoSelectApprover();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load approvers: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _autoSelectApprover() {
    if (_approvers.isEmpty) return;

    // 0. Prioritize explicitly recommended reviewer by name
    if (widget.recommendedReviewerName != null) {
      final explicit = _approvers
          .where((u) => u.fullName == widget.recommendedReviewerName)
          .firstOrNull;
      if (explicit != null) {
        _selectedApproverId = explicit.id;
        return;
      }
    }

    // 1. Try to find Unit Head for this specific service unit
    final unitHead = _approvers.where((u) {
      // Logic: unit name matches and role indicates head
      // Note: serviceUnit might be 'Social Service' while DB unit is 'social'
      // We should probably rely on the unit slug passed in or normalize it.
      // Assuming 'serviceUnit' passed here is the cleaned slug (e.g. 'social')
      return u.unit == widget.serviceUnit && u.role.endsWith('head');
    }).firstOrNull;

    if (unitHead != null) {
      _selectedApproverId = unitHead.id;
      return;
    }

    // 2. Fallback to Center Head if no unit head found
    final centerHead =
        _approvers.where((u) => u.role == 'center_head').firstOrNull;
    if (centerHead != null) {
      _selectedApproverId = centerHead.id;
    }

    // 3. Otherwise select first available
    _selectedApproverId ??= _approvers.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit for Review'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select the person who should review/approve this form.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error))
            else if (_approvers.isEmpty)
              const Text('No eligible approvers found.')
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _approvers.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final approver = _approvers[index];

                    bool isRecommended = false;
                    if (widget.recommendedReviewerName != null &&
                        approver.fullName == widget.recommendedReviewerName) {
                      isRecommended = true;
                    } else if (widget.recommendedReviewerName == null) {
                      isRecommended = (approver.unit == widget.serviceUnit &&
                              approver.role.endsWith('head')) ||
                          approver.role == 'center_head';
                    }

                    return RadioListTile<String>(
                      value: approver.id,
                      groupValue: _selectedApproverId,
                      onChanged: (value) {
                        setState(() => _selectedApproverId = value);
                      },
                      title: Text(
                        approver.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        _formatRole(approver.role),
                        style: const TextStyle(fontSize: 12),
                      ),
                      secondary: isRecommended
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 0),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedApproverId == null
              ? null
              : () {
                  final selected =
                      _approvers.firstWhere((u) => u.id == _selectedApproverId);
                  Navigator.pop(context, selected);
                },
          child: const Text('Submit'),
        ),
      ],
    );
  }

  String _formatRole(String role) {
    return role
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
