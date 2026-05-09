import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/custom_error_dialog.dart';
import '../../../data/models/form_submission_model.dart';
import '../../../data/models/form_approval_model.dart';
import '../../../data/repositories/form_repository.dart';
import '../../../data/repositories/approval_repository.dart';
import '../../../features/auth/bloc/auth_bloc.dart';
import '../templates/form_templates.dart';
import '../widgets/form_content_widget.dart';
import 'form_pdf_preview_screen.dart';
import '../pdf/pdf_generator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class FormViewScreen extends StatefulWidget {
  final String formId;
  final bool reviewMode;

  const FormViewScreen({
    super.key,
    required this.formId,
    this.reviewMode = false,
  });

  @override
  State<FormViewScreen> createState() => _FormViewScreenState();
}

class _FormViewScreenState extends State<FormViewScreen> {
  FormSubmissionModel? _form;
  bool _isLoading = true;
  bool _isActioning = false;

  // Action info
  bool _canAct = false;
  String? _actionType;
  FormApprovalModel? _pendingApproval;
  String? _signatureFieldName;

  final ApprovalRepository _approvalRepository = ApprovalRepository();

  // Editable fields support
  Map<String, dynamic> _editableData = {};
  bool _hasEditableFields = false;
  Set<String> _editableFieldNames = {};
  final Map<String, TextEditingController> _editableControllers = {};

  // History for continuous forms
  // List<FormSubmissionModel> _history = [];
  // bool _loadingHistory = false;

  /// Medical staff editable fields for Admission/Discharge Slip
  static const _medicalEditableFields = {
    'medical_findings',
    'recommendations',
    'medical_diagnosis',
    'physicians_order',
  };

  /// Supervisory remarks field for Progress/Running Notes
  static const _supervisoryRemarksFields = {
    'supervisory_remarks',
    'supervisor_remarks',
    'remarks',
  };

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  @override
  void dispose() {
    for (final c in _editableControllers.values) {
      c.dispose();
    }
    _editableControllers.clear();
    super.dispose();
  }

  Future<void> _loadForm() async {
    setState(() => _isLoading = true);
    try {
      final formRepo = context.read<FormRepository>();
      final form = await formRepo.getFormById(widget.formId);

      if (form.isArchived) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This form has been archived')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // Check if current user can take action on this form
      final actionInfo =
          await _approvalRepository.getFormActionInfo(widget.formId);

      var canAct = actionInfo['canAct'] as bool;
      var actionType = actionInfo['actionType'] as String?;
      var approval = actionInfo['approval'] as FormApprovalModel?;
      var signatureFieldName = actionInfo['signatureFieldName'] as String?;

      if (!mounted) return;

      // Retrieve template to get workflow config
      final template = FormTemplatesRegistry.getByTypeAndUnit(
              form.templateType, form.unit) ??
          FormTemplatesRegistry.getByType(form.templateType);

      // Fallback: Check Workflow Config if explicit approval not found
      if (!canAct && template?.workflowConfig != null) {
        // For Admission/Discharge Slip, enforce explicit recipient routing via form_approvals.
        // Do not allow role-based action without a pending approval row.
        if (form.templateType == 'admission_slip' ||
            form.templateType == 'discharge_slip') {
          // Leave canAct = false here; Center Head compatibility is handled below.
        } else {
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            final userRole = authState.user.role;
            final currentStepId = form.status; // status matches step ID usually
            final step = template!.workflowConfig!.getStep(currentStepId);

            if (step != null && step.requiredRoles.contains(userRole)) {
              canAct = true;
              actionType = 'approve';
              // No explicit approval object needed for direct workflow action
            }
          }
        }
      }
      // Compatibility for statuses where Center Head can act
      else if (!canAct &&
          (form.status == AppConstants.statusPendingFinalApproval ||
              form.status == AppConstants.statusPendingHeadApproval)) {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated &&
            authState.user.role == AppConstants.roleCenterHead) {
          canAct = true;
          actionType = 'approve';
        }
      }

      // 5. If successful, apply "Prepared By" signature automatically
      // NOTE: The original code did not have `signatureUrl` or `isReadOnly` in this context.
      // Assuming this block is intended to be inserted here and `signatureUrl` and `isReadOnly`
      // would be defined elsewhere or are placeholders for future functionality.
      // For now, `signatureUrl` is null and `widget.isReadOnly` is `reviewMode`.
      // This block will effectively not run without `signatureUrl` being set.
      String? signatureUrl; // Placeholder for signature URL
      // ignore: unnecessary_null_comparison
      if (signatureUrl != null && !widget.reviewMode) {
        // Using widget.reviewMode for !widget.isReadOnly
        try {
          final authBloc = context.read<AuthBloc>();
          if (authBloc.state is AuthAuthenticated) {
            final user = (authBloc.state as AuthAuthenticated).user;
            await context.read<ApprovalRepository>().applyPreparedBySignature(
                  formId: form.id, // Using form.id instead of formId
                  userId: user.id,
                  userName: user.fullName,
                  title: user.role, // Or fetch title
                  signatureUrl: signatureUrl,
                );
          }
        } catch (e) {
          debugPrint(
              'WARNING: Failed to apply "Prepared By" signature: $e. Proceeding anyway.');
          // Don't block submission if signature fails (RLS, etc.)
        }
      }

      // Determine editable fields based on user role and form type
      Set<String> editableFields = {};
      if (canAct) {
        if (!mounted) return;
        final authState2 = context.read<AuthBloc>().state;
        if (authState2 is AuthAuthenticated) {
          final userUnit = authState2.user.unit;
          final formType = form.templateType;

          // Medical staff editing admission/discharge slip
          if (userUnit == 'medical' &&
              (formType == 'admission_slip' || formType == 'discharge_slip') &&
              form.status == AppConstants.statusPendingReview) {
            editableFields = Set.from(_medicalEditableFields);
          }

          // Approver editing supervisory remarks on progress/running notes
          if ((formType == 'progress_notes' || formType == 'running_notes') &&
              (authState2.user.isUnitHead ||
                  authState2.user.role == AppConstants.roleCenterHead)) {
            editableFields = Set.from(_supervisoryRemarksFields);
          }
        }
      }

      setState(() {
        _form = form;
        _canAct = canAct;
        _actionType = actionType;
        _pendingApproval = approval;
        _signatureFieldName = signatureFieldName;
        _hasEditableFields = editableFields.isNotEmpty;
        _editableFieldNames = editableFields;
        _editableData = Map.from(form.formData);
        _editableControllers.clear();
        for (final field in editableFields) {
          _editableControllers[field] = TextEditingController(
            text: (form.formData[field] ?? '').toString(),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading form: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_form == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Form'),
        ),
        body: const Center(child: Text('Form not found')),
      );
    }

    final form = _form!;

    // Try to get the template for consistent UI - use unit to get correct template
    final template =
        FormTemplatesRegistry.getByTypeAndUnit(form.templateType, form.unit) ??
            FormTemplatesRegistry.getByType(form.templateType);

    // Show PDF pane for submitted/pending/signed forms (not draft/returned)
    // Exclude continuous forms like Progress/Running Notes from PDF-only view

    final bool isContinuousForm = form.templateType == 'progress_notes' ||
        form.templateType == 'running_notes' ||
        form.templateType == 'behavior_log' ||
        form.templateType == 'daily_activity_log' ||
        form.templateType == 'daily_vitals';

    final bool isDraft = form.status == AppConstants.statusDraft;

    // We WANT split view if:
    // 1. It is review mode OR
    // 2. Large screen (handled by _showSplitView flag set in build)
    // 3. AND NOT a continuous form, UNLESS it is NOT a draft (so approvers can see PDF)
    // 4. OR it IS a returned form (special case to show return comments + split view)

    // Determine if we should show the split review scaffold
    final showSplitView = widget.reviewMode ||
        (!isDraft &&
            (!isContinuousForm || form.status != AppConstants.statusDraft) &&
            form.status != AppConstants.statusApproved) ||
        form.status == 'returned';

    if (showSplitView && template != null) {
      return _buildReviewScaffold(form: form, template: template);
    }

    // If this is an uploaded signed form (image), show the image viewer instead of PDF
    if (form.formData['is_uploaded_record'] == true) {
      final imageUrl = form.formData['signed_image_url'] as String?;
      return _buildUploadedFormViewer(form: form, imageUrl: imageUrl);
    }

    // Direct to full PDF preview if it's approved
    if (form.status == AppConstants.statusApproved && template != null) {
      return FormPdfPreviewScreen(
        template: template,
        formData: form.formData,
        residentName: form.residentName ?? 'Unknown',
        residentId: form.residentId,
        submissionId: form.id,
        caseNumber: form.formData['case_number'] as String?,
        status: form.status,
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(form.templateDisplayName),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : (template != null
                ? AppColors.getServiceUnitColor(template.serviceUnit.name)
                : Theme.of(context).appBarTheme.backgroundColor),
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.textInverse
            : (template != null
                ? AppColors.textInverse
                : Theme.of(context).appBarTheme.foregroundColor),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.fileText),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FormPdfPreviewScreen(
                    template: template!,
                    formData: form.formData,
                    residentName: form.residentName ?? 'Unknown',
                    residentId: form.residentId,
                    submissionId: form.id,
                    caseNumber: form.formData['case_number'] as String?,
                    status: form.status,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            _buildStatusCard(form),
            const SizedBox(height: 20),

            /*
            // History / Log Book (for continuous forms)
            if (isContinuousForm) ...[
              _buildHistorySection(),
              const SizedBox(height: 20),
            ],
            */

            // Review comment (if returned)
            if (form.isReturned && form.reviewComment != null) ...[
              _buildReturnedSection(form),
              const SizedBox(height: 16),
            ],

            // Use shared form content widget if template is available
            // Editable fields section (above form content)
            if (_hasEditableFields) ...[
              _buildEditableFieldsSection(),
              const SizedBox(height: 16),
            ],

            if (template != null)
              FormContentWidget(
                template: template,
                formData: form.formData,
                isReadOnly: true,
                residentName: form.residentName,
                existingSubmission: form,
                showSignatures: true,
              )
            else ...[
              // Fallback to original layout if template not found
              // Resident info
              _buildSection(
                'Resident',
                [
                  _buildInfoRow('Name', form.residentName ?? 'Unknown'),
                ],
              ),
              const SizedBox(height: 16),

              // Form data
              _buildSection(
                'Form Details',
                _buildFormDataFields(form.formData),
              ),
              const SizedBox(height: 16),

              // Signatures - show if form type requires signatures and has signature data
              if (_formHasSignatureData(form) &&
                  _formTypeRequiresSignatures(form.templateType))
                _buildSignaturesSection(form),
            ],

            const SizedBox(height: 16),

            // Add bottom padding for action buttons
            if (_canAct) const SizedBox(height: 80),
          ],
        ),
      ),
      // Dynamic action buttons
      bottomNavigationBar: _canAct ? _buildActionButtons(form) : null,
      floatingActionButton: isContinuousForm
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push(
                  Uri(
                    path: '/forms/fill/${form.templateId}',
                    queryParameters: {'formId': form.id},
                  ).toString(),
                );
              },
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add Entry'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  /*
  Widget _buildHistorySection() {
    if (_loadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.history, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'Previous Entries',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length > 3
              ? 3
              : _history.length, // Show max 3, maybe add "See All" later
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = _history[index];
            final date = DateFormat('MMM d, yyyy').format(entry.createdAt);
            final time = DateFormat('h:mm a').format(entry.createdAt);

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                onTap: () {
                  // Navigate to this entry (replace current view)
                  context.pushReplacement('/forms/view/${entry.id}');
                },
                leading: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        date.split(',')[0], // MMM d
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      Text(
                        date.split(',')[1].trim(), // yyyy
                        style: TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  entry.templateDisplayName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Passed by: ${entry.reviewerName ?? entry.submitterName ?? 'Unknown'} • $time',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(LucideIcons.chevronRight, size: 16),
              ),
            );
          },
        ),
        if (_history.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () {
                  // Show full history dialog or navigate to history page
                  // For now, just show a snackbar or maybe expand
                },
                child: Text('View all ${_history.length} entries'),
              ),
            ),
          ),
      ],
    );
  }
  */

  Widget _buildReviewScaffold({
    required FormSubmissionModel form,
    required FormTemplate template,
  }) {
    final mergedData = Map<String, dynamic>.from(form.formData);
    for (final f in _editableFieldNames) {
      if (_editableData.containsKey(f)) mergedData[f] = _editableData[f];
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(form.templateDisplayName),
        actions: [
          IconButton(
            tooltip: 'Open full PDF screen',
            icon: const Icon(LucideIcons.maximize2),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FormPdfPreviewScreen(
                    template: template,
                    formData: mergedData,
                    residentName: form.residentName ?? 'Unknown',
                    residentId: form.residentId,
                    submissionId: form.id,
                    caseNumber: form.formData['case_number'] as String?,
                    status: form.status,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          final pdfPane = _buildPdfPane(
            template: template,
            form: form,
            mergedData: mergedData,
          );
          final reviewPane = _buildReviewSidePane(form: form);

          if (!isWide) {
            return Column(
              children: [
                Expanded(child: pdfPane),
                const Divider(height: 1),
                SizedBox(height: 360, child: reviewPane),
              ],
            );
          }

          return Row(
            children: [
              Expanded(flex: 3, child: pdfPane),
              const VerticalDivider(width: 1),
              Expanded(flex: 2, child: reviewPane),
            ],
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchSignaturesForPdf(
      String submissionId, Map<String, dynamic> baseData) async {
    final data = Map<String, dynamic>.from(baseData);
    try {
      final client = Supabase.instance.client;
      final sigsRes = await client
          .from('form_signatures')
          .select(
              'field_name, signature_url, signer_id, profiles(full_name, title)')
          .eq('form_submission_id', submissionId);

      for (var row in sigsRes) {
        if (row['signature_url'] != null) {
          final fieldStr = row['field_name'] as String;
          // Generic: set {field_name}_signature_url for every signature row
          data['${fieldStr}_signature_url'] = row['signature_url'];

          if (row['profiles'] != null) {
            final fullName = row['profiles']['full_name'];
            final title = row['profiles']['title'];

            // Generic: populate the field_name key with the signer's name
            if (fullName != null) data[fieldStr] = fullName;
            if (title != null) {
              // Handle "None" designation
              data['${fieldStr}_designation'] =
                  (title.toString().toLowerCase() == 'none') ? null : title;
            }

            // Handle specific aliases for consistency across templates
            if (fieldStr == 'noted_by') {
              data['noted_by_name'] = fullName;
              data['noted_by_signature_url'] = row['signature_url'];
              data['noted_by_designation'] =
                  (title.toString().toLowerCase() == 'none')
                      ? 'CENTER HEAD'
                      : title;
              // Map noted_by to center_head aliases as well
              data['center_head_name'] = fullName;
              data['center_head'] = fullName;
              data['center_head_signature_url'] = row['signature_url'];
              data['center_head_designation'] = data['noted_by_designation'];
              data['approved_by'] = fullName;
              data['approved_by_designation'] = data['noted_by_designation'];
            } else if (fieldStr == 'center_head_name' ||
                fieldStr == 'approved_by' ||
                fieldStr == 'center_head') {
              data['center_head_name'] = fullName;
              data['center_head_signature_url'] = row['signature_url'];
              data['center_head_designation'] =
                  (title.toString().toLowerCase() == 'none')
                      ? 'CENTER HEAD'
                      : title;
              // Add alias without _name for templates using just center_head
              data['center_head'] = fullName;
              data['noted_by'] = fullName;
              data['noted_by_signature_url'] = row['signature_url'];
              data['noted_by_designation'] = data['center_head_designation'];
              data['approved_by_designation'] = data['center_head_designation'];
            } else if (fieldStr == 'medical_staff_name') {
              data['medical_staff_name'] = fullName;
              data['medical_staff'] = fullName; // Alias
              data['medical_staff_name_signature_url'] = row['signature_url'];
              data['medical_staff_designation'] =
                  (title.toString().toLowerCase() == 'none') ? 'DOCTOR' : title;
            } else if (fieldStr == 'prepared_by') {
              data['prepared_by'] = fullName;
              data['user_name'] = fullName;
              data['prepared_by_name'] = fullName;
              data['prepared_by_signature_url'] = row['signature_url'];
              data['prepared_by_designation'] =
                  (title.toString().toLowerCase() == 'none') ? null : title;
            }

            // Map parallel roles (received_by) for Incident Report
            if (fieldStr == 'received_by' ||
                fieldStr == 'received_social' ||
                fieldStr == 'received_psych' ||
                fieldStr == 'received_medical') {
              final role =
                  row['profiles'] != null ? row['profiles']['role'] : '';

              if (role == 'social_head' || role == 'social_worker') {
                data['received_social'] = fullName;
                data['received_social_signature_url'] = row['signature_url'];
                data['received_social_designation'] = title;
              } else if (role == 'psych_head' || role == 'psych_worker') {
                data['received_psych'] = fullName;
                data['received_psych_signature_url'] = row['signature_url'];
                data['received_psych_designation'] = title;
              } else if (role == 'medical_head' ||
                  role == 'medical_center_doctor') {
                data['received_medical'] = fullName;
                data['received_medical_signature_url'] = row['signature_url'];
                data['received_medical_designation'] = title;
              }
            }

            // Map attested_by for Incident Report (Supervising HP)
            if (fieldStr == 'attested_by') {
              data['attested_by'] = fullName;
              data['attested_by_signature_url'] = row['signature_url'];
              data['attested_by_designation'] = title;
            }
          }
        }
      }

      // Also fetch form_approvals to get designations BEFORE signatures are applied
      try {
        final approvalsRes = await client
            .from('form_approvals')
            .select('signature_field_name, recipient_id, recipient_name')
            .eq('form_submission_id', submissionId);

        if (approvalsRes.isNotEmpty) {
          final recipientIds =
              approvalsRes.map((r) => r['recipient_id'] as String).toList();
          final profilesRes = await client
              .from('profiles')
              .select('id, title, role')
              .inFilter('id', recipientIds);

          final profileMap = {for (var p in profilesRes) p['id']: p};

          for (var row in approvalsRes) {
            final fieldStr = row['signature_field_name'] as String?;
            if (fieldStr != null && fieldStr.isNotEmpty) {
              final fullName = row['recipient_name'];
              final profile = profileMap[row['recipient_id']];
              final title = profile != null ? profile['title'] : null;
              final role = profile != null ? profile['role'] : null;

              if (fullName != null) {
                // Generic name assignment (only if not already set by signatures)
                data[fieldStr] ??= fullName;
              }

              if (title != null) {
                String? designation;
                if (title.toString().trim().isNotEmpty &&
                    title.toString().toLowerCase() != 'none') {
                  designation = title.toString();
                }

                if (designation != null) {
                  data['${fieldStr}_designation'] ??= designation;
                }

                // Handle aliases just like in signatures
                if (fieldStr == 'noted_by') {
                  data['noted_by_name'] ??= fullName;
                  data['noted_by_designation'] ??= designation ?? 'CENTER HEAD';
                  data['center_head_name'] ??= fullName;
                  data['center_head'] ??= fullName;
                  data['center_head_designation'] ??=
                      designation ?? 'CENTER HEAD';
                  data['approved_by'] ??= fullName;
                  data['approved_by_designation'] ??=
                      designation ?? 'CENTER HEAD';
                } else if (fieldStr == 'center_head_name' ||
                    fieldStr == 'approved_by' ||
                    fieldStr == 'center_head') {
                  data['center_head_name'] ??= fullName;
                  data['center_head'] ??= fullName;
                  data['noted_by'] ??= fullName;
                  data['center_head_designation'] ??=
                      designation ?? 'CENTER HEAD';
                  data['noted_by_designation'] ??= designation ?? 'CENTER HEAD';
                  data['approved_by_designation'] ??=
                      designation ?? 'CENTER HEAD';
                } else if (fieldStr == 'medical_staff_name') {
                  data['medical_staff_name'] ??= fullName;
                  data['medical_staff'] ??= fullName;
                  data['medical_staff_designation'] ??= designation ?? 'DOCTOR';
                }

                // Map parallel roles (received_by) for Incident Report based on role
                if (fieldStr == 'received_by' ||
                    fieldStr == 'received_social' ||
                    fieldStr == 'received_psych' ||
                    fieldStr == 'received_medical') {
                  if (role == 'social_head' || role == 'social_worker') {
                    data['received_social'] ??= fullName;
                    if (data['received_social_designation'] == null ||
                        data['received_social_designation']
                            .toString()
                            .trim()
                            .isEmpty) {
                      data['received_social_designation'] =
                          designation ?? 'SOCIAL WORKER';
                    }
                  } else if (role == 'psych_head' || role == 'psych_worker') {
                    data['received_psych'] ??= fullName;
                    if (data['received_psych_designation'] == null ||
                        data['received_psych_designation']
                            .toString()
                            .trim()
                            .isEmpty) {
                      data['received_psych_designation'] =
                          designation ?? 'PSYCHOLOGIST';
                    }
                  } else if (role == 'medical_head' ||
                      role == 'medical_center_doctor') {
                    data['received_medical'] ??= fullName;
                    if (data['received_medical_designation'] == null ||
                        data['received_medical_designation']
                            .toString()
                            .trim()
                            .isEmpty) {
                      data['received_medical_designation'] =
                          designation ?? 'MEDICAL OFFICER';
                    }
                  }
                }

                // Map attested_by for Incident Report
                if (fieldStr == 'attested_by') {
                  data['attested_by'] ??= fullName;
                  data['attested_by_designation'] ??= title;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint(
            '[FormViewScreen] Error fetching approvals for PDF titles: $e');
      }

      // Fallback for preparer
      if (!mounted) return data;
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        if (data['prepared_by_signature_url'] == null) {
          data['prepared_by_signature_url'] = authState.user.signatureUrl;
        }
        if (data['prepared_by_designation'] == null ||
            data['prepared_by_designation'].toString().toLowerCase() ==
                'none') {
          data['prepared_by_designation'] =
              (authState.user.title?.toLowerCase() == 'none')
                  ? 'SOCIAL WORKER'
                  : authState.user.title;
        }
      }

      // Center Head fallback from profiles if not in signatures
      if (data['center_head_name'] == null) {
        try {
          final centerHeadProfile = await client
              .from('profiles')
              .select('full_name, title')
              .eq('role', 'center_head')
              .limit(1)
              .maybeSingle();
          if (centerHeadProfile != null) {
            data['center_head_name'] = centerHeadProfile['full_name'];
            data['cswdo_name'] = centerHeadProfile['full_name'];
            final chTitle = centerHeadProfile['title'];
            data['center_head_designation'] =
                (chTitle?.toString().toLowerCase() == 'none')
                    ? 'CENTER HEAD'
                    : chTitle;
            data['approved_by_designation'] = data['center_head_designation'];
            data['noted_by_designation'] = data['center_head_designation'];
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[FormViewScreen] Error fetching signatures for PDF: $e');
    }
    return data;
  }

  Widget _buildPdfPane({
    required FormTemplate template,
    required FormSubmissionModel form,
    required Map<String, dynamic> mergedData,
  }) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : Colors.grey[100],
      child: PdfPreview(
        build: (format) async {
          final dataWithSigs =
              await _fetchSignaturesForPdf(form.id, mergedData);
          return PdfGenerator.generatePdf(
            template: template,
            data: dataWithSigs,
            residentName: form.residentName ?? 'Unknown',
            caseNumber: dataWithSigs['case_number']?.toString(),
          );
        },
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        useActions: false,
      ),
    );
  }

  Widget _buildReviewSidePane({required FormSubmissionModel form}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (form.isReturned && form.reviewComment != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(LucideIcons.rotateCcw,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Returned by ${form.reviewerName ?? 'Reviewer'}',
                          style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 4),
                    Text(form.reviewComment!,
                        style: const TextStyle(fontSize: 13)),

                    // Only show Edit & Resubmit button for the original author
                    if (form.submittedBy ==
                        (context.read<AuthBloc>().state is AuthAuthenticated
                            ? (context.read<AuthBloc>().state
                                    as AuthAuthenticated)
                                .user
                                .id
                            : null)) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to FormFillScreen for editing
                            context.push(
                              Uri(
                                path: '/forms/fill/${form.templateId}',
                                queryParameters: {'formId': form.id},
                              ).toString(),
                            );
                          },
                          icon: const Icon(LucideIcons.pencil, size: 16),
                          label: const Text('Edit & Resubmit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(LucideIcons.listChecks, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Review & required inputs',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_hasEditableFields) ...[
              Expanded(
                child: ListView(
                  children: _editableFieldNames.map((fieldName) {
                    final label = _fieldLabelFor(fieldName);
                    final controller = _editableControllers[fieldName] ??
                        TextEditingController(
                            text: (_editableData[fieldName] ?? '').toString());
                    _editableControllers[fieldName] = controller;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: controller,
                        onChanged: (v) => _editableData[fieldName] = v,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: label,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'No additional input required for your role on this form.',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        (_canAct && !_isActioning) ? _showReturnDialog : null,
                    icon: const Icon(LucideIcons.rotateCcw),
                    label: const Text('Return'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.warning,
                      side: const BorderSide(color: AppColors.warning),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        (_canAct && !_isActioning) ? _handleAction : null,
                    icon: _isActioning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(LucideIcons.penLine),
                    label:
                        Text(_signatureFieldName != null ? 'Sign' : 'Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  String _fieldLabelFor(String fieldName) {
    switch (fieldName) {
      case 'medical_findings':
        return 'Medical Findings / Clearance';
      case 'recommendations':
        return 'Recommendations';
      case 'medical_diagnosis':
        return 'Medical Diagnosis';
      case 'physicians_order':
        return "Physician's Order";
      default:
        return fieldName.replaceAll('_', ' ');
    }
  }

  /// Build dynamic action buttons based on user role and form type
  Widget _buildActionButtons(FormSubmissionModel form) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Return button
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isActioning ? null : () => _showReturnDialog(),
                icon: const Icon(LucideIcons.rotateCcw),
                label: const Text('Return'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Approve/Acknowledge button
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isActioning ? null : () => _handleAction(),
                icon: _isActioning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_getActionIcon()),
                label: Text(_getActionButtonLabel()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get the appropriate action button label based on action type
  String _getActionButtonLabel() {
    if (_signatureFieldName != null) {
      // Has a specific signature field - determine label from field name
      final fieldLower = _signatureFieldName!.toLowerCase();
      if (fieldLower.contains('noted') || fieldLower.contains('note')) {
        return 'Note';
      } else if (fieldLower.contains('approved') ||
          fieldLower.contains('approve')) {
        return 'Approve';
      } else if (fieldLower.contains('received') ||
          fieldLower.contains('receive')) {
        return 'Receive';
      }
      return 'Sign';
    }

    // Based on action type
    switch (_actionType) {
      case 'approve':
        return 'Approve';
      case 'acknowledge':
        return 'Acknowledge';
      default:
        return 'Confirm';
    }
  }

  /// Get the appropriate action icon
  IconData _getActionIcon() {
    if (_signatureFieldName != null) {
      return LucideIcons.penLine; // Signature required
    }
    switch (_actionType) {
      case 'approve':
        return LucideIcons.circleCheck;
      case 'acknowledge':
        return LucideIcons.thumbsUp;
      default:
        return LucideIcons.check;
    }
  }

  /// Save editable field data before approving
  Future<void> _saveEditableFields() async {
    if (!_hasEditableFields || _form == null) return;
    final formRepo = context.read<FormRepository>();
    // Merge editable data into form data
    final updatedData = Map<String, dynamic>.from(_form!.formData);
    for (final fieldName in _editableFieldNames) {
      if (_editableData.containsKey(fieldName)) {
        updatedData[fieldName] = _editableData[fieldName];
      }
    }
    try {
      await formRepo.updateDraft(id: _form!.id, formData: updatedData);
    } catch (e) {
      debugPrint('Warning: Could not save editable fields before signing: $e');
      // Continue with signing even if save fails — the approval action is more important
    }
  }

  /// Handle the action button press
  Future<void> _handleAction() async {
    // If we have an explicit approval request, OR if we determined we can act via Workflow
    if (!_canAct) return;

    setState(() => _isActioning = true);

    try {
      // Save editable fields (medical findings, supervisory remarks) before approving
      await _saveEditableFields();

      if (_pendingApproval == null) {
        // Direct Workflow Action (No Explicit Request)
        // Use FormRepository to trigger backend approval logic
        if (!mounted) return;
        final formRepo = context.read<FormRepository>();
        // Using existing approveForm which tries RLS then Backend
        // The backend knows how to handle the workflow transition
        final updatedForm = await formRepo.approveForm(_form!.id);

        if (mounted) {
          setState(() {
            _form = updatedForm;
            _canAct = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Form action completed successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop(true);
        }
        return;
      }

      // Existing Flow: Explicit Approval Request
      Map<String, dynamic>? signatureInfo;
      Map<String, dynamic>? acknowledgeInfo;

      if (_signatureFieldName != null) {
        // Requires signature - determine action type from field name
        final fieldLower = _signatureFieldName!.toLowerCase();
        if (fieldLower.contains('noted') || fieldLower.contains('note')) {
          signatureInfo = await _approvalRepository.noteFormWithAutoSignature(
            approvalId: _pendingApproval!.id,
          );
        } else {
          signatureInfo =
              await _approvalRepository.approveFormWithAutoSignature(
            approvalId: _pendingApproval!.id,
          );
        }
      } else if (_actionType == 'approve') {
        signatureInfo = await _approvalRepository.approveFormWithAutoSignature(
          approvalId: _pendingApproval!.id,
        );
      } else {
        // Simple acknowledge without signature
        acknowledgeInfo = await _approvalRepository.acknowledgeFormSimple(
          approvalId: _pendingApproval!.id,
        );
      }

      if (mounted) {
        // Update the local form state
        if (_form != null) {
          if (signatureInfo != null) {
            // Use newStatus from backend workflow engine (may be intermediate, not 'approved')
            final resultStatus =
                signatureInfo['newStatus'] as String? ?? 'approved';
            setState(() {
              _form = _form!.copyWith(
                status: resultStatus,
                reviewedBy: signatureInfo!['signerId'] as String?,
                reviewerName: signatureInfo['signerName'] as String?,
                reviewerSignatureUrl: signatureInfo['signatureUrl'] as String?,
                reviewedAt: signatureInfo['signedAt'] as DateTime?,
              );
              _canAct = false;
              _pendingApproval = null;
            });
          } else if (acknowledgeInfo != null) {
            // Update for simple acknowledge (no signature)
            setState(() {
              _form = _form!.copyWith(
                status: 'approved',
                reviewedBy: acknowledgeInfo!['acknowledgedBy'] as String?,
                reviewerName: acknowledgeInfo['acknowledgerName'] as String?,
                reviewedAt: acknowledgeInfo['acknowledgedAt'] as DateTime?,
              );
              _canAct = false;
              _pendingApproval = null;
            });
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Form ${_getActionButtonLabel().toLowerCase()}d successfully!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate back to previous screen after successful action
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        if (mounted) {
          CustomErrorDialog.show(context,
              title: 'Action Failed',
              error: e,
              message: 'Failed to process form action.');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isActioning = false);
      }
    }
  }

  /// Show return dialog for entering comment
  Future<void> _showReturnDialog() async {
    // Allow return even without an explicit approval row (direct workflow action)
    // if (_pendingApproval == null) return;

    final commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Form'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a reason for returning this form:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your comments...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.trim().isEmpty) {
                CustomErrorDialog.show(context,
                    title: 'Validation Error',
                    message: 'Please enter a comment.');
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Return'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isActioning = true);
      try {
        // Always use backend /api/return-form endpoint.
        // This ensures ALL pending parallel approvals are cleared
        // and the original initiator (submitted_by) is notified.
        final formRepo = context.read<FormRepository>();
        await formRepo.returnForm(
          id: _form!.id,
          comment: commentController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Form returned successfully'),
              backgroundColor: AppColors.warning,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          CustomErrorDialog.show(context,
              title: 'Return Failed',
              error: e,
              message: 'Failed to return form.');
        }
      } finally {
        if (mounted) {
          setState(() => _isActioning = false);
        }
      }
    }
    commentController.dispose();
  }

  /// Build a viewer for uploaded signed form images/PDFs
  Widget _buildUploadedFormViewer({
    required FormSubmissionModel form,
    String? imageUrl,
  }) {
    final fileType = form.formData['file_type']?.toString() ?? 'image';
    final isPdf = fileType == 'pdf' ||
        (imageUrl != null && imageUrl.toLowerCase().endsWith('.pdf'));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(form.templateDisplayName),
        actions: [
          if (imageUrl != null)
            IconButton(
              icon: const Icon(LucideIcons.externalLink),
              tooltip: 'Open in browser',
              onPressed: () async {
                final uri = Uri.parse(imageUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
        ],
      ),
      body: imageUrl == null || imageUrl.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.imageOff, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No file available for this uploaded form.'),
                ],
              ),
            )
          : Column(
              children: [
                // Status card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: AppColors.successSurface,
                  child: Row(
                    children: [
                      Icon(LucideIcons.fileUp,
                          color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Uploaded signed form — ${form.residentName ?? "Unknown"}',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.statusApproved,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Signed',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content: PDF or Image
                Expanded(
                  child: isPdf
                      ? PdfPreview(
                          build: (_) async {
                            final response =
                                await http.get(Uri.parse(imageUrl));
                            return response.bodyBytes;
                          },
                          canChangePageFormat: false,
                          canChangeOrientation: false,
                          canDebug: false,
                          allowPrinting: true,
                          allowSharing: true,
                          pdfFileName: form.templateDisplayName,
                        )
                      : InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: Center(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.circleAlert,
                                        size: 64, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text('Failed to load image: $error'),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  /// Build editable fields section for medical staff or supervisory remarks
  Widget _buildEditableFieldsSection() {
    final fieldLabels = <String, String>{
      'medical_findings': 'Medical Findings',
      'recommendations': 'Recommendations',
      'medical_diagnosis': 'Medical Diagnosis',
      'physicians_order': "Physician's Order",
      'supervisory_remarks': 'Supervisory Remarks',
      'supervisor_remarks': 'Supervisor Remarks',
      'remarks': 'Remarks',
    };

    return Card(
      color: AppColors.infoSurface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.filePenLine, color: AppColors.info, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Fields Requiring Your Input',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.info,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._editableFieldNames.map((fieldName) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: TextEditingController(
                    text: _editableData[fieldName]?.toString() ?? '',
                  ),
                  onChanged: (value) {
                    _editableData[fieldName] = value;
                  },
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: fieldLabels[fieldName] ??
                        fieldName.replaceAll('_', ' '),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(FormSubmissionModel form) {
    return Card(
      color: form.statusColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(form.status),
              color: form.statusColor,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    form.statusDisplayText,
                    style: TextStyle(
                      color: form.statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted ${_formatDate(form.submittedAt ?? form.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: form.unitColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                form.unit.toUpperCase(),
                style: TextStyle(
                  color: form.unitColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return LucideIcons.pencil;
      case 'pending_review':
        return LucideIcons.hourglass;
      case 'approved':
        return LucideIcons.circleCheck;
      case 'returned':
        return LucideIcons.rotateCcw;
      default:
        return LucideIcons.fileText;
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFormDataFields(Map<String, dynamic> formData) {
    final fields = <Widget>[];
    formData.forEach((key, value) {
      if (value == null || key.startsWith('_')) return;

      // Format the key to be more readable
      final label = key
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '')
          .join(' ');

      // Format the value based on type
      String displayValue;
      if (value is List) {
        displayValue = value.isEmpty ? '-' : '${value.length} items';
      } else if (value is Map) {
        displayValue = 'Complex data';
      } else if (value is bool) {
        displayValue = value ? 'Yes' : 'No';
      } else {
        displayValue = value?.toString() ?? '-';
      }

      fields.add(_buildInfoRow(label, displayValue));
    });

    return fields.isEmpty ? [const Text('No data available')] : fields;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Check if form has signature-related data (Prepared By, Noted By, etc.)
  bool _formHasSignatureData(FormSubmissionModel form) {
    final data = form.formData;
    // Check for signature field names in form data
    return data.containsKey('prepared_by') ||
        data.containsKey('noted_by') ||
        data.containsKey('approved_by') ||
        form.submitterSignatureUrl != null ||
        form.reviewerSignatureUrl != null;
  }

  /// Check if form type requires signatures (Prepared By, Noted By, etc.)
  bool _formTypeRequiresSignatures(String templateType) {
    // Templates that don't require signatures
    const noSignatureTypes = [
      'pre_admission_checklist',
      'requirements_checklist',
    ];
    return !noSignatureTypes.contains(templateType);
  }

  Widget _buildSignaturesSection(FormSubmissionModel form) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signatures',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            // Submitter signature
            _buildSignatureBlock(
              'Submitted by',
              form.submitterName ?? 'Unknown',
              form.submitterSignatureUrl,
              form.submittedAt,
            ),
            // Reviewer signature
            if (form.reviewedBy != null) ...[
              const SizedBox(height: 16),
              _buildSignatureBlock(
                form.isApproved ? 'Approved by' : 'Reviewed by',
                form.reviewerName ?? 'Unknown',
                form.reviewerSignatureUrl,
                form.reviewedAt,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureBlock(
    String label,
    String name,
    String? signatureUrl,
    DateTime? timestamp,
  ) {
    // Check if we have a valid signature URL
    final hasValidUrl = signatureUrl != null &&
        signatureUrl.isNotEmpty &&
        (signatureUrl.startsWith('http://') ||
            signatureUrl.startsWith('https://'));

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
              if (timestamp != null) ...[
                const SizedBox(height: 2),
                Text(
                  _formatDate(timestamp),
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Show signature image or pending placeholder
        if (hasValidUrl)
          Container(
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
                        Icon(LucideIcons.imageOff,
                            size: 20, color: AppColors.textSecondaryLight),
                        Text('Load failed',
                            style: TextStyle(
                                fontSize: 8,
                                color: AppColors.textSecondaryLight)),
                      ],
                    ),
                  );
                },
              ),
            ),
          )
        else
          // No signature URL - show pending placeholder
          Container(
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
          ),
      ],
    );
  }

  Widget _buildReturnedSection(FormSubmissionModel form) {
    // Check if current user is the original author
    final authState = context.read<AuthBloc>().state;
    final currentUserId =
        authState is AuthAuthenticated ? authState.user.id : null;
    final isAuthor = currentUserId != null && form.submittedBy == currentUserId;

    return Card(
      color: AppColors.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.triangleAlert, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Returned by ${form.reviewerName ?? 'Reviewer'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              form.reviewComment!,
              style: const TextStyle(color: AppColors.textPrimaryLight),
            ),
            // Only show Edit & Resubmit button for the original author
            if (isAuthor) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push(
                    '/forms/fill/${form.templateType}?formId=${form.id}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: const Text('Edit & Resubmit'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }
}
