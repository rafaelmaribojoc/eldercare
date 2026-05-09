import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/error_handler.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/approval_repository.dart';

/// Modal for selecting a recipient when submitting a form for approval
class SubmitApprovalModal extends StatefulWidget {
  final String formId;
  final String? currentUserUnit;
  final List<String>?
      signatureFields; // Fields that can have signatures applied
  final Function(
          String recipientId, String recipientName, String? signatureField)
      onSubmit;

  const SubmitApprovalModal({
    super.key,
    required this.formId,
    this.currentUserUnit,
    this.signatureFields,
    required this.onSubmit,
  });

  @override
  State<SubmitApprovalModal> createState() => _SubmitApprovalModalState();
}

class _SubmitApprovalModalState extends State<SubmitApprovalModal> {
  final ApprovalRepository _approvalRepo = ApprovalRepository();

  List<UserModel> _recipients = [];
  bool _isLoading = true;
  String? _error;

  UserModel? _selectedRecipient;
  String? _selectedSignatureField;

  final _signatureFieldLabels = {
    'noted_by': 'Noted By',
    'approved_by': 'Approved By',
    'center_head': 'Center Head',
    'unit_head': 'Unit Head',
    'supervisor': 'Supervisor',
  };

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  Future<void> _loadRecipients() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final recipients = await _approvalRepo.getApprovalRecipients();

      setState(() {
        _recipients = recipients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = ErrorHandler.getUserFriendlyMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: const Icon(
                      LucideIcons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submit for Approval',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select who should review this form',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x),
                    iconSize: 20,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: _buildContent(),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _selectedRecipient != null ? _handleSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.circleAlert,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load recipients',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadRecipients,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_recipients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.users,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No reviewers available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Recipient',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 12),

          // Recipient list
          ...(_recipients.map((user) => _buildRecipientTile(user))),

          // Signature field selection (if applicable)
          if (widget.signatureFields != null &&
              widget.signatureFields!.isNotEmpty &&
              _selectedRecipient != null) ...[
            const SizedBox(height: 24),
            Text(
              'Signature Field (Optional)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'If selected, the recipient\'s signature will overlay this field upon approval.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSignatureFieldChip(null, 'None'),
                ...widget.signatureFields!.map((field) =>
                    _buildSignatureFieldChip(
                        field, _signatureFieldLabels[field] ?? field)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipientTile(UserModel user) {
    final isSelected = _selectedRecipient?.id == user.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color:
            isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedRecipient = user;
            });
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor:
                      AppColors.getServiceUnitColor(user.unit ?? 'social'),
                  radius: 20,
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayNameWithTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (user.employeeId != null) ...[
                            Text(
                              user.employeeId!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Text('•',
                                style:
                                    TextStyle(color: AppColors.textTertiary)),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            _getRoleLabel(user.role),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Check icon
                if (isSelected)
                  Icon(
                    LucideIcons.circleCheck,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureFieldChip(String? field, String label) {
    final isSelected = _selectedSignatureField == field;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedSignatureField = selected ? field : null;
        });
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'center_head':
        return 'Center Head';
      case 'head':
        return 'Unit Head';
      case 'staff':
        return 'Staff';
      default:
        if (role.endsWith('_head')) {
          return '${_capitalize(role.replaceAll('_head', ''))} Head';
        } else if (role.endsWith('_staff')) {
          return '${_capitalize(role.replaceAll('_staff', ''))} Staff';
        }
        return role;
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _handleSubmit() {
    if (_selectedRecipient == null) return;

    widget.onSubmit(
      _selectedRecipient!.id,
      _selectedRecipient!.fullName,
      _selectedSignatureField,
    );
    Navigator.pop(context);
  }
}

/// Show the submit approval modal
Future<void> showSubmitApprovalModal({
  required BuildContext context,
  required String formId,
  String? currentUserUnit,
  List<String>? signatureFields,
  required Function(
          String recipientId, String recipientName, String? signatureField)
      onSubmit,
}) {
  return showDialog(
    context: context,
    builder: (context) => SubmitApprovalModal(
      formId: formId,
      currentUserUnit: currentUserUnit,
      signatureFields: signatureFields,
      onSubmit: onSubmit,
    ),
  );
}
