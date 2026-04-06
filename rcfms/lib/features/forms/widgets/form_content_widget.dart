import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/models/form_submission_model.dart';
import '../templates/form_templates.dart';

/// A shared widget that displays form content.
/// Can be used in both create mode (editable) and view mode (read-only).
class FormContentWidget extends StatelessWidget {
  /// The form template
  final FormTemplate template;

  /// The form data (current values)
  final Map<String, dynamic> formData;

  /// Callback when a field value changes (null for read-only mode)
  final void Function(String key, dynamic value)? onFieldChanged;

  /// Whether the form is read-only
  final bool isReadOnly;

  /// Optional resident name to display
  final String? residentName;

  /// Optional resident case number
  final String? caseNumber;

  /// Existing form submission data (for view mode with signatures)
  final FormSubmissionModel? existingSubmission;

  /// Whether to show the signature section
  final bool showSignatures;

  const FormContentWidget({
    super.key,
    required this.template,
    required this.formData,
    this.onFieldChanged,
    this.isReadOnly = false,
    this.residentName,
    this.caseNumber,
    this.existingSubmission,
    this.showSignatures = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screen) {
        return ResponsiveContainer(
          maxWidth: screen.value(
            mobile: double.infinity,
            tablet: 800.0,
            desktop: 900.0,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screen.horizontalPadding,
            vertical: screen.value(mobile: 16.0, tablet: 20.0, desktop: 24.0),
          ),
          child: SingleChildScrollView(
            child: ResponsiveCard(
              padding: EdgeInsets.all(
                screen.value(mobile: 16.0, tablet: 20.0, desktop: 24.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form header
                  _buildFormHeader(context, screen),
                  const Divider(height: 32),

                  // Form fields
                  ..._buildFormFields(context, screen),

                  // Signatures section (only if template requires signatures and in view mode)
                  // Forms without signatures (requiresSignature: false) don't show any signatures section
                  if (showSignatures &&
                      existingSubmission != null &&
                      template.requiresSignature) ...[
                    const SizedBox(height: 24),
                    _buildSignaturesSection(context, screen),
                  ],

                  SizedBox(
                    height:
                        screen.value(mobile: 16.0, tablet: 20.0, desktop: 24.0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormHeader(BuildContext context, ScreenInfo screen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(
                screen.value(mobile: 8.0, tablet: 10.0, desktop: 12.0),
              ),
              decoration: BoxDecoration(
                color: AppColors.getServiceUnitColor(template.serviceUnit.name)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                template.icon,
                color: AppColors.getServiceUnitColor(template.serviceUnit.name),
                size: screen.value(mobile: 24.0, tablet: 28.0, desktop: 32.0),
              ),
            ),
            SizedBox(
              width: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: TextStyle(
                      fontSize: screen.value(
                          mobile: 18.0, tablet: 20.0, desktop: 22.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ],
        ),
        if (residentName != null) ...[
          SizedBox(
            height: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          Row(
            children: [
              const Icon(Icons.person,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                residentName!,
                style: TextStyle(
                  fontSize:
                      screen.value(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (caseNumber != null) ...[
                const SizedBox(width: 16),
                const Icon(Icons.folder,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Text(
                  'Case #: $caseNumber',
                  style: TextStyle(
                    fontSize:
                        screen.value(mobile: 13.0, tablet: 14.0, desktop: 15.0),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (template.description.isNotEmpty) ...[
          SizedBox(
            height: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0),
          ),
          Text(
            template.description,
            style: TextStyle(
              fontSize: screen.value(mobile: 13.0, tablet: 14.0, desktop: 15.0),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildFormFields(BuildContext context, ScreenInfo screen) {
    // Get form fields from template
    final formFields = FormTemplatesRegistry.getFormFields(
      template,
      formData,
      onFieldChanged ?? (_, __) {},
      readOnly: isReadOnly,
    );

    if (isReadOnly) {
      // View mode: Use actual form template but wrap in IgnorePointer
      // This provides UI parity with create form view while disabling all interactions
      return [
        IgnorePointer(
          ignoring: true,
          child: Opacity(
            opacity: 0.9, // Slightly dimmed to indicate read-only
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: formFields,
            ),
          ),
        ),
      ];
    } else {
      // Edit mode: Use form template's field builders
      return formFields;
    }
  }

  Widget _buildSignaturesSection(BuildContext context, ScreenInfo screen) {
    final form = existingSubmission!;

    // Get Prepared By info from form data
    final preparedByName = formData['prepared_by']?.toString();
    final preparedByTitle =
        formData['prepared_by_title']?.toString(); // e.g., "RPm"
    final preparedByPosition =
        formData['prepared_by_position']?.toString(); // e.g., "Psychometrician"
    final notedByName = formData['noted_by']?.toString();
    final notedByPosition = formData['noted_by_position']?.toString();

    // Format Prepared By name with title: "John Doe, RPm"
    String formattedPreparedByName =
        preparedByName ?? form.submitterName ?? 'Unknown';
    if (preparedByTitle != null && preparedByTitle.isNotEmpty) {
      formattedPreparedByName = '$formattedPreparedByName, $preparedByTitle';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signatures',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Divider(height: 24),

        // Prepared By signature (from form data) - with timestamp
        _buildPreparedBySignatureBlock(
          context,
          'Prepared By',
          formattedPreparedByName,
          preparedByPosition,
          form.submitterSignatureUrl,
          form.submittedAt, // Use submission timestamp
        ),

        // Noted By / Reviewer signature
        if (form.reviewedBy != null ||
            (notedByName != null && notedByName.isNotEmpty)) ...[
          const SizedBox(height: 16),
          _buildSignatureBlock(
            context,
            notedByName != null
                ? 'Noted By'
                : (form.isApproved ? 'Approved by' : 'Reviewed by'),
            form.reviewerName ?? notedByName ?? 'Unknown',
            form.reviewerSignatureUrl,
            form.reviewedAt,
            subtitle: notedByPosition ??
                (form.reviewedBy != null ? null : notedByPosition),
          ),
        ],
      ],
    );
  }

  /// Build signature block for Prepared By with timestamp
  Widget _buildPreparedBySignatureBlock(
    BuildContext context,
    String label,
    String name,
    String? position,
    String? signatureUrl,
    DateTime? timestamp,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (position != null && position.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  position,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
              if (timestamp != null) ...[
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(timestamp),
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildSignatureImage(signatureUrl),
      ],
    );
  }

  Widget _buildSignatureBlock(
    BuildContext context,
    String label,
    String name,
    String? signatureUrl,
    DateTime? timestamp, {
    String? subtitle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
              if (timestamp != null) ...[
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(timestamp),
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildSignatureImage(signatureUrl),
      ],
    );
  }

  /// Build signature image widget with proper error handling
  /// Shows the actual signature image, or a pending placeholder if no URL
  Widget _buildSignatureImage(String? signatureUrl) {
    // Check if we have a valid signature URL
    final hasValidUrl = signatureUrl != null &&
        signatureUrl.isNotEmpty &&
        (signatureUrl.startsWith('http://') ||
            signatureUrl.startsWith('https://'));

    if (hasValidUrl) {
      return Container(
        width: 120,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: signatureUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, url, error) {
              debugPrint('Signature load error: $error for URL: $url');
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image,
                        size: 20, color: AppColors.textSecondaryLight),
                    Text('Load failed',
                        style: TextStyle(
                            fontSize: 8, color: AppColors.textSecondaryLight)),
                  ],
                ),
              );
            },
          ),
        ),
      );
    } else {
      // No signature URL - show pending placeholder
      return Container(
        width: 120,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Text(
            'Pending',
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
  }
}
