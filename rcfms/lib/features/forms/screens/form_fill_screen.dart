import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../templates/form_templates.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/responsive.dart';
import '../../../data/repositories/form_repository.dart';
import '../../../data/repositories/approval_repository.dart';
import '../../../data/repositories/resident_repository.dart'; // Added
import '../../../data/models/form_submission_model.dart';
import '../../../data/models/user_model.dart';
import '../../auth/bloc/auth_bloc.dart';
import 'form_pdf_preview_screen.dart';
import '../widgets/notes_sidecar_widget.dart';
import '../widgets/reviewer_selection_dialog.dart';
import '../widgets/manual_text_dialog.dart';

/// Responsive form filling screen
class FormFillScreen extends StatefulWidget {
  final FormTemplate template;
  final String residentId;
  final String residentName;
  final String? caseNumber;
  final Map<String, dynamic>? initialData;
  final String? existingSubmissionId;
  final bool isEditing;

  /// Resident data for smart defaults (auto-population)
  final Map<String, dynamic>? residentData;

  const FormFillScreen({
    super.key,
    required this.template,
    required this.residentId,
    required this.residentName,
    this.caseNumber,
    this.initialData,
    this.existingSubmissionId,
    this.isEditing = false,
    this.residentData,
  });

  @override
  State<FormFillScreen> createState() => _FormFillScreenState();
}

class _FormFillScreenState extends State<FormFillScreen> {
  Future<String?> _freezeSignatureToSubmissionStorage({
    required String submissionId,
    required String fieldName,
    required String userId,
    required String signatureUrl,
  }) async {
    try {
      final client = Supabase.instance.client;
      final bytes = await client.storage.from('signatures').download(
            '$userId/signature.png',
          );
      if (bytes.isEmpty) return null;

      final ts = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '$userId/frozen_signatures/$submissionId/$fieldName-$ts.png';

      await client.storage.from('signatures').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: false,
            ),
          );

      return client.storage.from('signatures').getPublicUrl(filePath);
    } catch (e) {
      debugPrint(
          '[FormFillScreen] Failed to freeze signature for $fieldName on $submissionId: $e');
      return null;
    }
  }

  Future<void> _upsertSignatorySignature({
    required String submissionId,
    required String fieldName,
    required String fieldLabel,
  }) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    final signatureUrl = user.signatureUrl;
    if (signatureUrl == null || signatureUrl.isEmpty) {
      debugPrint(
          '[FormFillScreen] Skipping signature upsert for $fieldName: user has no signature URL');
      return;
    }

    final frozenUrl = await _freezeSignatureToSubmissionStorage(
          submissionId: submissionId,
          fieldName: fieldName,
          userId: user.id,
          signatureUrl: signatureUrl,
        ) ??
        signatureUrl;

    if (!frozenUrl.contains('/frozen_signatures/')) {
      debugPrint(
          '[FormFillScreen] WARNING: $fieldName signature not frozen (falling back to mutable signature.png). submissionId=$submissionId userId=${user.id}');
    }

    final now = DateTime.now();
    await Supabase.instance.client.from('form_signatures').upsert({
      'form_submission_id': submissionId,
      'signer_id': user.id,
      'signer_name': user.fullName,
      'signer_title': user.title,
      'signer_employee_id': user.employeeId,
      'field_name': fieldName,
      'field_label': fieldLabel,
      'signature_url': frozenUrl,
      'signed_at': now.toIso8601String(),
      'is_auto_applied': true,
    }, onConflict: 'form_submission_id, field_name');
  }

  Future<void> _upsertPreparedBySignature({
    required String submissionId,
  }) async {
    final fieldName = widget.template.preparerSignatureField ?? 'prepared_by';
    String fieldLabel = 'Prepared By';

    // Customize label based on common fields for better UI/audit trail
    if (fieldName == 'received_by') fieldLabel = 'Received By';
    if (fieldName == 'inspected_by') fieldLabel = 'Inspected By';
    if (fieldName == 'submitted_by') fieldLabel = 'Submitted By';

    await _upsertSignatorySignature(
      submissionId: submissionId,
      fieldName: fieldName,
      fieldLabel: fieldLabel,
    );
  }

  late Map<String, dynamic> _formData;
  final _formKey = GlobalKey<FormState>();
  Key _fieldsKey = UniqueKey(); // To force rebuild of fields when bulk updating
  bool _isDirty = false;
  bool _isSaving = false;
  String? _submissionId;
  List<String> _residentNames = []; // Cache for resident autocomplete

  @override
  void initState() {
    super.initState();
    _formData = widget.initialData != null
        ? Map<String, dynamic>.from(widget.initialData!)
        : FormTemplatesRegistry.getDefaultData(
            widget.template,
            residentData: widget.residentData,
          );

    // FIX: Sanitize 'status' field if it contains Civil Status (Legacy Data)
    // This prevents the "MARRIED", "SINGLE" etc. badge from appearing
    final currentStatus = _formData['status']?.toString().toUpperCase();
    if (currentStatus != null &&
        ['MARRIED', 'SINGLE', 'WIDOWED', 'SEPARATED', 'DIVORCED']
            .contains(currentStatus)) {
      _formData['civil_status'] = _formData['status'];
      _formData['status'] = widget.existingSubmissionId != null
          ? AppConstants.statusDraft
          : AppConstants.statusDraft; // Default to draft if corrupted
    }

    // Fetch residents for auto-complete (Incident Report, etc.)
    _fetchResidentNames();

    // Data sanitization: Handle type mismatches between form types
    // This prevents crashes when switching between form types with different data structures
    if (widget.template.templateType != 'intervention_plan') {
      // Check if 'activities' is a List (from Intervention Plan) when it shouldn't be
      if (_formData['activities'] is List) {
        final activitiesList = _formData['activities'] as List;
        if (activitiesList.isNotEmpty) {
          // Convert List to String format for compatibility
          final stringValue = activitiesList
              .map((item) {
                if (item is Map) {
                  // Extract text from map structure
                  return [item['objective'], item['activity'], item['output']]
                      .where((s) => s != null && s.toString().isNotEmpty)
                      .join(' - ');
                }
                return item.toString();
              })
              .where((s) => s.isNotEmpty)
              .join('\n');

          _formData['activities'] = stringValue.isNotEmpty ? stringValue : null;

          // Log for debugging
          print(
              '[FormFillScreen] Converted activities from List to String: $stringValue');
        } else {
          _formData.remove('activities');
        }
      }

      // Check for other potential List fields that should be Strings
      final fieldsToCheck = [
        'objectives',
        'time_frame',
        'responsible_person',
        'output'
      ];
      for (final field in fieldsToCheck) {
        if (_formData[field] is List) {
          final listValue = _formData[field] as List;
          if (listValue.isNotEmpty) {
            _formData[field] = listValue.join(', ');
            print('[FormFillScreen] Converted $field from List to String');
          } else {
            _formData.remove(field);
          }
        }
      }
    }

    _submissionId = widget.existingSubmissionId;

    // Safety check for residentId
    if (widget.residentId.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Error: No resident selected. Form cannot be saved.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 5),
            ),
          );
        }
      });
    } else {
      // Guard: Homelife and social staff can only create forms for residents assigned to them
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkAssignedResidentRestriction());
    }

    // Auto-populate Prepared By with current user
    _autoPopulateSignatures();

    // Force update Custodian Info for Client's Contract
    // This ensures even drafts reflect the current resident profile's custodian/status
    if (widget.template.templateType == 'clients_contract' &&
        widget.residentData != null) {
      _forceUpdateCustodianInfo(widget.residentData!);
    }
  }

  /// Enforce that homelife personnel and social workers can only create forms
  /// for residents assigned to them. Unit heads and others are not restricted.
  Future<void> _checkAssignedResidentRestriction() async {
    if (widget.residentId.isEmpty) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated || !authState.user.isStaff) return;

    final user = authState.user;
    final isSocialWorker =
        user.unit == AppConstants.unitSocial || user.role == 'social_worker';
    final isHouseparent = user.unit == AppConstants.unitHomelife ||
        user.role.startsWith('homelife');
    if (!isSocialWorker && !isHouseparent) return;

    try {
      final resident =
          await ResidentRepository().getResidentById(widget.residentId);
      if (!mounted) return;
      final allowed = (isSocialWorker && resident.socialWorkerId == user.id) ||
          (isHouseparent && resident.houseparentId == user.id);
      if (!allowed) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Access Denied'),
              content: const Text(
                'You can only create forms for residents assigned to you.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          ).then((_) {
            if (mounted) Navigator.of(context).pop();
          });
        }
      }
    } catch (_) {
      // If resident fetch fails (e.g. no access), allow screen to show; RLS may block save
    }
  }

  void _forceUpdateCustodianInfo(Map<String, dynamic> residentData) {
    final custodianName = residentData['custodian_name'] ??
        residentData['custodianName'] ??
        residentData['nearest_relative_name'] ??
        residentData['nearestRelativeName'];

    if (custodianName == null) return;

    final family =
        residentData['family_composition'] ?? residentData['familyComposition'];

    String status = '';

    Map<String, dynamic>? member;

    if (family is List) {
      final targetName = custodianName.toString().trim().toLowerCase();

      for (final m in family) {
        if ((m['name'] ?? '').toString().trim().toLowerCase() == targetName) {
          member = m as Map<String, dynamic>;
          break;
        }
      }

      if (member != null) {
        status = member['civil_status'] ?? '';
      }
    }

    setState(() {
      _formData['custodian_name'] = custodianName;
      // Only update status if we found one, or strictly clear it?
      // User wants it based on custodian. If custodian has no status, it should be empty.
      // But if we fail to match, maybe keep existing? No, likely existing is wrong (client's).
      // Safest is to set it.
      if (status.isNotEmpty) {
        _formData['civil_status'] = status;
      } else if (family is List) {
        // If we have family data but found no match/status, clear it to avoid showing Client's status
        _formData['civil_status'] = '';
      }

      // Logic for Address
      if (member != null &&
          member['address'] != null &&
          member['address'].toString().isNotEmpty) {
        _formData['address'] = member['address'];
      }
    });
  }

  /// Auto-populate Prepared By, Noted By, and Unit Head fields
  Future<void> _autoPopulateSignatures() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final currentUser = authState.user;

      // Only set if not already set (don't override existing data when editing)
      if (_formData['prepared_by'] == null ||
          _formData['prepared_by'].toString().isEmpty) {
        setState(() {
          _formData['prepared_by'] = currentUser.fullName;
          // Use job title based on unit (not license suffix like RPm)
          _formData['prepared_by_position'] = _getJobTitle(currentUser);
          _formData['license_no'] =
              currentUser.licenseNo; // Auto-populate license
          _formData['prepared_by_id'] = currentUser.id;

          // Auto-populate the template-specific preparer name field if defined
          final preparerFieldName = widget.template.preparerSignatureField;
          if (preparerFieldName != null &&
              (_formData[preparerFieldName] == null ||
                  _formData[preparerFieldName].toString().isEmpty)) {
            _formData[preparerFieldName] = currentUser.fullName;
          }

          // Homelife specific: "inspected_by" is the preparer
          if (widget.template.serviceUnit.name == 'homeLifeService') {
            if (_formData['inspected_by'] == null ||
                _formData['inspected_by'].toString().isEmpty) {
              _formData['inspected_by'] = currentUser.fullName;
            }
          }

          // Auto-populate 'user_name' and 'user_title' for forms using this generic key (like Admission Slip)
          if (_formData['user_name'] == null ||
              _formData['user_name'].toString().isEmpty) {
            _formData['user_name'] = currentUser.fullName;
          }

          if (_formData['user_title'] == null ||
              _formData['user_title'].toString().isEmpty) {
            _formData['user_title'] = _getJobTitle(currentUser);
          }

          // Homelife specific designation fields
          if (widget.template.serviceUnit.name == 'homeLifeService') {
            final title = _getJobTitle(currentUser);
            if (_formData['inspected_by_designation'] == null ||
                _formData['inspected_by_designation'].toString().isEmpty) {
              _formData['inspected_by_designation'] = title;
            }
            if (_formData['prepared_by_designation'] == null ||
                _formData['prepared_by_designation'].toString().isEmpty) {
              _formData['prepared_by_designation'] = title;
            }
            if (_formData['receiving_party_designation'] == null ||
                _formData['receiving_party_designation'].toString().isEmpty) {
              _formData['receiving_party_designation'] = title;
            }
          }

          // Inter-Service Referral: auto-populate referring party from current user
          if (widget.template.templateType == 'inter_service_referral') {
            if (_formData['referring_person'] == null ||
                _formData['referring_person'].toString().isEmpty) {
              _formData['referring_person'] = currentUser.fullName;
            }
            if (_formData['referring_unit'] == null ||
                _formData['referring_unit'].toString().isEmpty) {
              _formData['referring_unit'] = currentUser.unit ?? '';
            }
            if (_formData['referring_position'] == null ||
                _formData['referring_position'].toString().isEmpty) {
              _formData['referring_position'] = _getJobTitle(currentUser);
            }
          }

          _fieldsKey = UniqueKey(); // Force rebuild to show populated values
        });
      }
    }

    // Fetch Recipients (Unit Head & Center Head)
    try {
      final approvalRepo = ApprovalRepository();
      // Fetch all potential recipients to avoid multiple calls
      final recipients = await approvalRepo.getApprovalRecipients();

      if (mounted) {
        setState(() {
          // 0. Validation: Clear existing auto-populated signatories if they are no longer active
          // This handles the case where a staff member was deactivated after being saved in a draft
          final activeIds = recipients.map((u) => u.id).toSet();

          // Validate Noted By (Center Head)
          if (_formData['noted_by_id'] != null &&
              !activeIds.contains(_formData['noted_by_id'])) {
            _formData.remove('noted_by');
            _formData.remove('noted_by_position');
            _formData.remove('noted_by_id');
            _formData.remove('center_head'); // Generic key
            debugPrint('[FormFillScreen] Cleared inactive Center Head');
          }

          // Validate Attested By / Unit Heads
          final attestedById = _formData['attested_by_id'];
          if (attestedById != null && !activeIds.contains(attestedById)) {
            _formData.remove('attested_by');
            _formData.remove('attested_by_id');
            debugPrint('[FormFillScreen] Cleared inactive Unit Head');
          }

          final centerHead = recipients
              .where((u) => u.role == 'center_head' || u.role == 'super_admin')
              .firstOrNull;

          // Homelife Head (Supervising HP)
          final homelifeHead = recipients
              .where((u) =>
                  u.role == 'homelife_head' ||
                  u.unit == 'homelife' && u.role == 'head')
              .firstOrNull;

          // Social Head
          final socialHead = recipients
              .where((u) =>
                  u.role == 'social_head' ||
                  u.unit == 'social' && u.role == 'head')
              .firstOrNull;

          // Psych Head
          final psychHead = recipients
              .where((u) =>
                  u.role == 'psych_head' ||
                  u.unit == 'psych' && u.role == 'head')
              .firstOrNull;

          // Medical Head
          final medicalHead = recipients
              .where((u) =>
                  u.role == 'medical_head' ||
                  u.unit == 'medical' && u.role == 'head')
              .firstOrNull;

          // Nutrition Head
          final nutritionHead = recipients
              .where((u) =>
                  u.role == 'nutrition_head' ||
                  u.unit == 'nutrition' && u.role == 'head')
              .firstOrNull;

          // 1. Center Head population
          if (centerHead != null) {
            // Only set if not already set
            if (_formData['noted_by'] == null ||
                _formData['noted_by'].toString().isEmpty) {
              _formData['noted_by'] = centerHead.fullName;
              _formData['noted_by_position'] = 'Center Head';
              _formData['noted_by_id'] = centerHead.id;

              // Ensure noted_by_designation is also set for Word templates
              if (_formData['noted_by_designation'] == null ||
                  _formData['noted_by_designation'].toString().isEmpty) {
                _formData['noted_by_designation'] = 'CENTER HEAD';
              }
            }

            // Also set 'center_head' field for forms that use this specific key
            if (_formData['center_head'] == null ||
                _formData['center_head'].toString().isEmpty) {
              _formData['center_head'] = centerHead.fullName;
            }
          }

          // 2. Homelife Unit Head (Supervising HP) population
          if (homelifeHead != null &&
              widget.template.serviceUnit.name == 'homeLifeService') {
            // "attested_by" and "submitted_by" are the Unit Head
            if (_formData['attested_by'] == null ||
                _formData['attested_by'].toString().isEmpty) {
              _formData['attested_by'] = homelifeHead.fullName;
              _formData['attested_by_id'] = homelifeHead.id;

              // Set specific designation fields for Homelife
              final title = _getJobTitle(homelifeHead);
              _formData['attested_by_designation'] = title;
              _formData['supervising_hp'] = homelifeHead.fullName;
              _formData['supervising_hp_designation'] = title;
              _formData['supervising_hp_id'] = homelifeHead.id;
            }
            if (_formData['submitted_by_name'] == null ||
                _formData['submitted_by_name'].toString().isEmpty) {
              _formData['submitted_by_name'] = homelifeHead.fullName;
            }
            // Some forms might use "submitted_by" as a string name field
            // but we must be careful because "submitted_by" is also the UUID in form_submissions table
            // In form_data, it's safer to use template-specific keys or "noted_by" logic
          }

          // 3. Incident Report specified Service Heads
          if (widget.template.templateType == 'incident_report') {
            if (socialHead != null &&
                (_formData['received_social'] == null ||
                    _formData['received_social'].toString().isEmpty)) {
              _formData['received_social'] = socialHead.fullName.toUpperCase();
            }
            if (psychHead != null &&
                (_formData['received_psych'] == null ||
                    _formData['received_psych'].toString().isEmpty)) {
              _formData['received_psych'] = psychHead.fullName.toUpperCase();
            }
            if (medicalHead != null &&
                (_formData['received_medical'] == null ||
                    _formData['received_medical'].toString().isEmpty)) {
              _formData['received_medical'] =
                  medicalHead.fullName.toUpperCase();
            }
          }

          // 4. Nutrition Service: auto-populate nutrition head name for banner display
          if (nutritionHead != null &&
              widget.template.serviceUnit == ServiceUnit.nutritionService) {
            if (_formData['nutrition_head_name'] == null ||
                _formData['nutrition_head_name'].toString().isEmpty) {
              _formData['nutrition_head_name'] = nutritionHead.fullName;
              _formData['nutrition_head_id'] = nutritionHead.id;
              _formData['nutrition_head_designation'] =
                  _getJobTitle(nutritionHead);
            }
          }

          // 5. Populate center_head_name (used by social forms like admission_slip, social_case_study)
          if (centerHead != null) {
            final currentCH = _formData['center_head_name']?.toString() ?? '';
            if (currentCH.isEmpty ||
                currentCH == AppConstants.defaultCenterHeadName) {
              _formData['center_head_name'] = centerHead.fullName;
            }
            final currentCHField = _formData['center_head']?.toString() ?? '';
            if (currentCHField.isEmpty ||
                currentCHField == AppConstants.defaultCenterHeadName) {
              _formData['center_head'] = centerHead.fullName;
            }
          }

          // 6. Social Service: populate social head name for banner display
          if (socialHead != null &&
              widget.template.serviceUnit == ServiceUnit.socialService) {
            if (_formData['social_head_name'] == null ||
                _formData['social_head_name'].toString().isEmpty) {
              _formData['social_head_name'] = socialHead.fullName;
            }
          }

          // 7. Medical Service: populate medical head name for banner display
          if (medicalHead != null &&
              widget.template.serviceUnit == ServiceUnit.medicalService) {
            if (_formData['medical_head_name'] == null ||
                _formData['medical_head_name'].toString().isEmpty) {
              _formData['medical_head_name'] = medicalHead.fullName;
            }
          }

          // 8. Psych Service: populate psych head name for banner display
          if (psychHead != null &&
              widget.template.serviceUnit == ServiceUnit.psychologicalService) {
            if (_formData['psych_head_name'] == null ||
                _formData['psych_head_name'].toString().isEmpty) {
              _formData['psych_head_name'] = psychHead.fullName;
            }
          }

          // 9. After Care Plan: auto-populate multi-unit heads (no manual selection needed)
          if (widget.template.templateType == 'after_care_plan') {
            if (homelifeHead != null &&
                (_formData['confirmed_homelife'] == null ||
                    _formData['confirmed_homelife'].toString().isEmpty)) {
              _formData['confirmed_homelife'] = homelifeHead.fullName;
            }
            if (medicalHead != null &&
                (_formData['confirmed_medical'] == null ||
                    _formData['confirmed_medical'].toString().isEmpty)) {
              _formData['confirmed_medical'] = medicalHead.fullName;
            }
            if (psychHead != null &&
                (_formData['confirmed_psych'] == null ||
                    _formData['confirmed_psych'].toString().isEmpty)) {
              _formData['confirmed_psych'] = psychHead.fullName;
            }
          }

          _fieldsKey = UniqueKey(); // Force rebuild
        });
      }

      // Pre-fill Referring Party from resident data for Homelife Admission Inventory
      if (widget.template.templateType == 'inventory_admission' &&
          widget.residentData != null) {
        final referringParty = (widget.residentData!['referring_party'] ??
                widget.residentData!['referringParty'] ??
                '')
            .toString();
        if (referringParty.isNotEmpty &&
            (_formData['referring_party'] == null ||
                _formData['referring_party'].toString().isEmpty)) {
          setState(() {
            _formData['referring_party'] = referringParty.toUpperCase();
            _fieldsKey = UniqueKey();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching signatories: $e');
    }
  }

  /// Get the database unit from the service unit
  String get _databaseUnit => AppConstants.getUnitFromServiceUnit(
        widget.template.serviceUnit.name,
      );

  void _updateField(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
      _isDirty = true;

      // Handle dependent fields
      if (key == 'date_admitted' || key == 'date_discharged') {
        final dateAdmitted = _formData['date_admitted'] as String?;
        final dateDischarged = _formData['date_discharged'] as String?;
        if (dateAdmitted != null && dateAdmitted.isNotEmpty) {
          _formData['length_of_stay'] =
              FormTemplatesRegistry.calculateLengthOfStay(
            dateAdmitted,
            dateDischargedStr: dateDischarged,
          );
        }
      }
    });
  }

  bool get _isReadOnly =>
      (_formData['status'] == AppConstants.statusApproved ||
          _formData['status'] == AppConstants.statusPendingFinalApproval) &&
      !widget.isEditing; // Simplified read-only check

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, screen) {
        return PopScope(
          canPop: !_isDirty,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _showExitConfirmation(context);
            if (shouldPop && context.mounted) {
              // Mark as clean so the pop is allowed
              setState(() => _isDirty = false);
              // Wait for the state update to propagate?
              // Usually WidgetsBinding.instance.addPostFrameCallback is safer,
              // but Navigator.pop inside async callback might be tricky.
              // Actually, simply calling pop() after setState might trigger rebuild first?
              // No, better to verify.
              // If we use clean boolean, PopScope re-evaluates.

              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            appBar: _buildAppBar(screen),
            body: _buildBody(screen),
            bottomNavigationBar: _buildBottomBar(screen),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ScreenInfo screen) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.template.name,
            style: TextStyle(
              fontSize: screen.value(mobile: 16.0, tablet: 18.0, desktop: 20.0),
            ),
          ),
          Text(
            widget.residentName,
            style: TextStyle(
              fontSize: screen.value(mobile: 12.0, tablet: 13.0, desktop: 14.0),
              fontWeight: FontWeight.normal,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.getServiceUnitColor(widget.template.serviceUnit.name),
      foregroundColor: AppColors.textInverse,
      toolbarHeight: screen.value(mobile: 64.0, tablet: 68.0, desktop: 72.0),
      actions: _buildAppBarActions(screen),
    );
  }

  List<Widget> _buildAppBarActions(ScreenInfo screen) {
    if (screen.isMobile) {
      return [
        PopupMenuButton<String>(
          icon: const Icon(LucideIcons.ellipsisVertical),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'preview',
              child: ListTile(
                leading: Icon(LucideIcons.eye),
                title: Text('Preview PDF'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'save_draft',
              child: ListTile(
                leading: Icon(LucideIcons.save),
                title: Text('Save Draft'),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (_isDirty)
              const PopupMenuItem(
                value: 'discard',
                child: ListTile(
                  leading: Icon(LucideIcons.rotateCcw, color: Colors.red),
                  title: Text('Discard Changes',
                      style: TextStyle(color: Colors.red)),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ];
    }

    return [
      TextButton.icon(
        onPressed: () => _saveDraft(shouldPop: true, finalize: false),
        icon: const Icon(LucideIcons.save, color: Colors.white),
        label: Text(
          _isSigned ? 'Save Changes' : 'Save Draft',
          style: TextStyle(
            color: Colors.white,
            fontSize: screen.value(mobile: 13.0, tablet: 14.0, desktop: 15.0),
          ),
        ),
      ),
      const SizedBox(width: 16),
    ];
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'preview':
        _previewPdf();
        break;
      case 'save_draft':
        _saveDraft();
        break;
      case 'discard':
        _discardChanges();
        break;
    }
  }

  Widget _buildBody(ScreenInfo screen) {
    if (screen.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildFormContent(screen),
          ),
          NotesSidecarWidget(residentId: widget.residentId),
        ],
      );
    }
    return _buildFormContent(screen);
  }

  Widget _buildFormContent(ScreenInfo screen) {
    return Form(
      key: _formKey,
      child: ResponsiveContainer(
        maxWidth: screen.value(
            mobile: double.infinity, tablet: 800.0, desktop: 900.0),
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
              key: _fieldsKey,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Auto-fill banner
                if (widget.template.templateType == 'md_nursing_care_service' &&
                    !widget.isEditing)
                  _buildCopyDataBanner(screen),

                // Form header
                _buildFormHeader(screen),
                const Divider(height: 32),

                // Signatory Banner for auto-populated Homelife forms
                // Ultra-Minimalist (Inside the card)
                if (widget.template.serviceUnit == ServiceUnit.homeLifeService)
                  // For incident reports, we also show the other service heads at the top
                  if (widget.template.templateType == 'incident_report')
                    Wrap(
                      spacing: 8,
                      runSpacing: 0,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName: null,
                          names: [
                            _formData['inspected_by']?.toString() ?? '',
                            _formData['attested_by']?.toString() ?? '',
                            _formData['prepared_by']?.toString() ?? '',
                            _formData['submitted_by_name']?.toString() ?? '',
                            _formData['supervising_hp']?.toString() ?? '',
                          ],
                        ),
                        if ((_formData['received_social']?.toString() ?? '')
                            .isNotEmpty)
                          FormFieldBuilders.signatoryBanner(
                              serviceColor:
                                  AppColors.getServiceUnitColor('social'),
                              names: [_formData['received_social'].toString()]),
                        if ((_formData['received_psych']?.toString() ?? '')
                            .isNotEmpty)
                          FormFieldBuilders.signatoryBanner(
                              serviceColor:
                                  AppColors.getServiceUnitColor('psych'),
                              names: [_formData['received_psych'].toString()]),
                        if ((_formData['received_medical']?.toString() ?? '')
                            .isNotEmpty)
                          FormFieldBuilders.signatoryBanner(
                              serviceColor:
                                  AppColors.getServiceUnitColor('medical'),
                              names: [
                                _formData['received_medical'].toString()
                              ]),
                        if ((_formData['center_head']?.toString() ??
                                _formData['noted_by']?.toString() ??
                                '')
                            .isNotEmpty)
                          FormFieldBuilders.signatoryBanner(
                            serviceColor: AppColors.primary,
                            centerHeadName:
                                _formData['center_head']?.toString() ??
                                    _formData['noted_by']?.toString() ??
                                    '',
                            names: [],
                          ),
                      ],
                    )
                  else if (widget.template.templateType == 'out_on_pass')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName:
                              _formData['center_head']?.toString() ??
                                  _formData['noted_by']?.toString() ??
                                  '',
                          disablePadding: true,
                          names: [
                            _formData['inspected_by']?.toString() ?? '',
                            _formData['attested_by']?.toString() ?? '',
                            _formData['prepared_by']?.toString() ?? '',
                            _formData['submitted_by_name']?.toString() ?? '',
                            _formData['supervising_hp']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Center Doctor',
                          value: _formData['center_doctor']?.toString() ?? '',
                          serviceColor:
                              AppColors.getServiceUnitColor('medical'),
                          filterUnit: 'medical',
                          onChanged: (v) {
                            _updateField('center_doctor', v);
                            setState(() {}); // Force rebuild of the header
                          },
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Social Worker',
                          value: _formData['social_worker']?.toString() ?? '',
                          serviceColor: AppColors.getServiceUnitColor('social'),
                          filterUnit: 'social',
                          onChanged: (v) {
                            _updateField('social_worker', v);
                            setState(() {}); // Force rebuild of the header
                          },
                        ),
                      ],
                    )
                  else if (widget.template.templateType ==
                      'inventory_admission')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName:
                              _formData['center_head']?.toString() ??
                                  _formData['noted_by']?.toString() ??
                                  '',
                          disablePadding: true,
                          names: [
                            _formData['inspected_by']?.toString() ?? '',
                            _formData['attested_by']?.toString() ?? '',
                            _formData['prepared_by']?.toString() ?? '',
                            _formData['submitted_by_name']?.toString() ?? '',
                            _formData['supervising_hp']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Referring Party',
                          value: _formData['referring_party']?.toString() ?? '',
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          onManualTap: () async {
                            final result = await ManualTextDialog.show(
                              context,
                              title: 'Referring Party',
                              label: 'Name',
                              initialValue:
                                  _formData['referring_party']?.toString() ??
                                      '',
                            );
                            if (result != null) {
                              _updateField('referring_party', result);
                              setState(() {});
                            }
                          },
                          onChanged: (v) {
                            _updateField('referring_party', v);
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  else if (widget.template.templateType ==
                      'inventory_discharge')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName:
                              _formData['center_head']?.toString() ??
                                  _formData['noted_by']?.toString() ??
                                  '',
                          disablePadding: true,
                          names: [
                            _formData['inspected_by']?.toString() ?? '',
                            _formData['attested_by']?.toString() ?? '',
                            _formData['prepared_by']?.toString() ?? '',
                            _formData['submitted_by_name']?.toString() ?? '',
                            _formData['supervising_hp']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Receiving Party',
                          value: _formData['receiving_party']?.toString() ?? '',
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          onManualTap: () async {
                            final result = await ManualTextDialog.show(
                              context,
                              title: 'Receiving Party',
                              label: 'Name',
                              initialValue:
                                  _formData['receiving_party']?.toString() ??
                                      '',
                            );
                            if (result != null) {
                              _updateField('receiving_party', result);
                              setState(() {});
                            }
                          },
                          onChanged: (v) {
                            _updateField('receiving_party', v);
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  else
                    FormFieldBuilders.signatoryBanner(
                      serviceColor: AppColors.getServiceUnitColor(
                          widget.template.serviceUnit.name),
                      centerHeadName: _formData['center_head']?.toString() ??
                          _formData['noted_by']?.toString() ??
                          '',
                      names: [
                        _formData['inspected_by']?.toString() ?? '',
                        _formData['attested_by']?.toString() ?? '',
                        _formData['prepared_by']?.toString() ?? '',
                        _formData['submitted_by_name']?.toString() ?? '',
                        _formData['supervising_hp']?.toString() ?? '',
                      ],
                    ),

                // Signatory Banner for Nutrition Service forms
                if (widget.template.serviceUnit == ServiceUnit.nutritionService)
                  if (widget.template.templateType == 'nt_malnourished_list')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName:
                              _formData['center_head']?.toString() ??
                                  _formData['noted_by']?.toString() ??
                                  '',
                          disablePadding: true,
                          names: [
                            _formData['prepared_by']?.toString() ?? '',
                            _formData['nutrition_head_name']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Center Doctor',
                          value: _formData['center_doctor']?.toString() ?? '',
                          serviceColor:
                              AppColors.getServiceUnitColor('medical'),
                          filterUnit: 'medical',
                          onChanged: (v) {
                            _updateField('center_doctor', v);
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  else if (widget.template.templateType == 'nt_ncp_mnt')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName: null,
                          disablePadding: true,
                          names: [
                            _formData['prepared_by']?.toString() ?? '',
                            _formData['nutrition_head_name']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Center Doctor',
                          value: _formData['center_doctor']?.toString() ?? '',
                          serviceColor:
                              AppColors.getServiceUnitColor('medical'),
                          filterUnit: 'medical',
                          onChanged: (v) {
                            _updateField('center_doctor', v);
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  else if (!_isSaveOnly)
                    FormFieldBuilders.signatoryBanner(
                      serviceColor: AppColors.getServiceUnitColor(
                          widget.template.serviceUnit.name),
                      centerHeadName: null,
                      names: [
                        _formData['prepared_by']?.toString() ?? '',
                        _formData['nutrition_head_name']?.toString() ?? '',
                      ],
                    )
                  else
                    FormFieldBuilders.signatoryBanner(
                      serviceColor: AppColors.getServiceUnitColor(
                          widget.template.serviceUnit.name),
                      centerHeadName: null,
                      names: [
                        _formData['prepared_by']?.toString() ?? '',
                      ],
                    ),

                // Signatory Banner for Social Service forms
                if (widget.template.serviceUnit == ServiceUnit.socialService)
                  if (widget.template.templateType == 'admission_slip')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName:
                              _formData['center_head_name']?.toString() ??
                                  _formData['center_head']?.toString() ??
                                  _formData['noted_by']?.toString() ??
                                  '',
                          disablePadding: true,
                          names: [
                            _formData['user_name']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Medical Staff',
                          value:
                              _formData['medical_staff_name']?.toString() ?? '',
                          serviceColor:
                              AppColors.getServiceUnitColor('medical'),
                          filterUnit: 'medical',
                          onChanged: (v) {
                            _updateField('medical_staff_name', v);
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  else if (widget.template.templateType == 'discharge_slip')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName:
                              _formData['center_head']?.toString() ??
                                  _formData['noted_by']?.toString() ??
                                  '',
                          disablePadding: true,
                          names: [
                            _formData['social_worker']?.toString() ??
                                _formData['user_name']?.toString() ??
                                '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Medical Staff',
                          value: _formData['medical_staff']?.toString() ?? '',
                          serviceColor:
                              AppColors.getServiceUnitColor('medical'),
                          filterUnit: 'medical',
                          onChanged: (v) {
                            _updateField('medical_staff', v);
                            setState(() {});
                          },
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'C/MSWDO',
                          value: _formData['cmswdo_name']?.toString() ?? '',
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          onManualTap: () async {
                            final result = await ManualTextDialog.show(
                              context,
                              title: 'C/MSWDO',
                              label: 'Name',
                              initialValue:
                                  _formData['cmswdo_name']?.toString() ?? '',
                            );
                            if (result != null) {
                              _updateField('cmswdo_name', result);
                              setState(() {});
                            }
                          },
                          onChanged: (v) {
                            _updateField('cmswdo_name', v);
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  else if (widget.template.templateType == 'termination_report')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName:
                              _formData['center_head_name']?.toString() ??
                                  _formData['center_head']?.toString() ??
                                  _formData['noted_by']?.toString() ??
                                  '',
                          disablePadding: true,
                          names: [
                            _formData['prepared_by']?.toString() ??
                                _formData['user_name']?.toString() ??
                                '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Division Chief',
                          value: _formData['division_chief_name']?.toString() ??
                              '',
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          onManualTap: () async {
                            final result = await ManualTextDialog.show(
                              context,
                              title: 'Protective Services Division Chief',
                              label: 'Name',
                              initialValue: _formData['division_chief_name']
                                      ?.toString() ??
                                  '',
                            );
                            if (result != null) {
                              _updateField('division_chief_name', result);
                              setState(() {});
                            }
                          },
                          onChanged: (v) {
                            _updateField('division_chief_name', v);
                            setState(() {});
                          },
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Regional Director',
                          value:
                              _formData['regional_director_name']?.toString() ??
                                  '',
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          onManualTap: () async {
                            final result = await ManualTextDialog.show(
                              context,
                              title: 'Regional Director',
                              label: 'Name',
                              initialValue: _formData['regional_director_name']
                                      ?.toString() ??
                                  '',
                            );
                            if (result != null) {
                              _updateField('regional_director_name', result);
                              setState(() {});
                            }
                          },
                          onChanged: (v) {
                            _updateField('regional_director_name', v);
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  else if (widget.template.templateType ==
                      'case_transfer_summary')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName:
                              _formData['center_head']?.toString() ??
                                  _formData['noted_by']?.toString() ??
                                  '',
                          disablePadding: true,
                          names: [
                            _formData['user_name']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'C/MSWDO Received By',
                          value: _formData['received_by']?.toString() ?? '',
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          onManualTap: () async {
                            final result = await ManualTextDialog.show(
                              context,
                              title: 'C/MSWDO Received By',
                              label: 'Name',
                              initialValue:
                                  _formData['received_by']?.toString() ?? '',
                            );
                            if (result != null) {
                              _updateField('received_by', result);
                              setState(() {});
                            }
                          },
                          onChanged: (v) {
                            _updateField('received_by', v);
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  else if (widget.template.templateType == 'client_photo')
                    FormFieldBuilders.signatoryBanner(
                      serviceColor: AppColors.getServiceUnitColor(
                          widget.template.serviceUnit.name),
                      centerHeadName: null,
                      disablePadding: true,
                      names: [
                        _formData['user_name']?.toString() ?? '',
                      ],
                    )
                  else if (widget.template.templateType ==
                      'requirements_checklist')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName: null,
                          disablePadding: true,
                          names: [
                            _formData['user_name']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Endorsed By',
                          value: _formData['endorsed_by']?.toString() ?? '',
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          onManualTap: () async {
                            final result = await ManualTextDialog.show(
                              context,
                              title: 'Endorsed By',
                              label: 'Name',
                              initialValue:
                                  _formData['endorsed_by']?.toString() ?? '',
                            );
                            if (result != null) {
                              _updateField('endorsed_by', result);
                              setState(() {});
                            }
                          },
                          onChanged: (v) {
                            _updateField('endorsed_by', v);
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  else if (widget.template.templateType == 'clients_contract')
                    FormFieldBuilders.signatoryBanner(
                      serviceColor: AppColors.getServiceUnitColor(
                          widget.template.serviceUnit.name),
                      centerHeadName:
                          _formData['center_head_name']?.toString() ?? '',
                      disablePadding: true,
                      names: [
                        _formData['prepared_by']?.toString() ??
                            _formData['user_name']?.toString() ??
                            '',
                      ],
                    )
                  else if (widget.template.templateType == 'admission_slip' ||
                      widget.template.templateType == 'discharge_slip')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName:
                              _formData['center_head_name']?.toString() ?? '',
                          disablePadding: true,
                          names: [
                            _formData['prepared_by']?.toString() ??
                                _formData['user_name']?.toString() ??
                                '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'Medical Staff',
                          value:
                              _formData['medical_staff_name']?.toString() ?? '',
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          onChanged: (v) {
                            _updateField('medical_staff_name', v);
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  else if (widget.template.templateType == 'after_care_plan')
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          centerHeadName:
                              _formData['center_head_name']?.toString() ?? '',
                          disablePadding: true,
                          names: [
                            _formData['prepared_by']?.toString() ??
                                _formData['user_name']?.toString() ??
                                '',
                            _formData['social_head_name']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.signatoryBanner(
                          serviceColor:
                              AppColors.getServiceUnitColor('homeLifeService'),
                          disablePadding: true,
                          names: [
                            _formData['confirmed_homelife']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.signatoryBanner(
                          serviceColor:
                              AppColors.getServiceUnitColor('medicalService'),
                          disablePadding: true,
                          names: [
                            _formData['confirmed_medical']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.signatoryBanner(
                          serviceColor: AppColors.getServiceUnitColor(
                              'psychologicalService'),
                          disablePadding: true,
                          names: [
                            _formData['confirmed_psych']?.toString() ?? '',
                          ],
                        ),
                        FormFieldBuilders.selectableSignatoryTag(
                          context: context,
                          label: 'C/MSWDO',
                          value: _formData['cmswdo_name']?.toString() ?? '',
                          serviceColor: AppColors.getServiceUnitColor(
                              widget.template.serviceUnit.name),
                          onManualTap: () async {
                            final result = await ManualTextDialog.show(
                              context,
                              title: 'C/MSWDO',
                              label: 'Name',
                              initialValue:
                                  _formData['cmswdo_name']?.toString() ?? '',
                            );
                            if (result != null) {
                              _updateField('cmswdo_name', result);
                              setState(() {});
                            }
                          },
                          onChanged: (v) {
                            _updateField('cmswdo_name', v);
                            setState(() {});
                          },
                        ),
                      ],
                    )
                  else
                    FormFieldBuilders.signatoryBanner(
                      serviceColor: AppColors.getServiceUnitColor(
                          widget.template.serviceUnit.name),
                      centerHeadName:
                          _formData['center_head_name']?.toString() ??
                              _formData['center_head']?.toString() ??
                              _formData['noted_by']?.toString() ??
                              '',
                      names: [
                        _formData['prepared_by']?.toString() ??
                            _formData['user_name']?.toString() ??
                            '',
                      ],
                    ),

                // Signatory Banner for Medical Service forms
                if (widget.template.serviceUnit == ServiceUnit.medicalService)
                  if (widget.template.templateType == 'md_special_events')
                    FormFieldBuilders.signatoryBanner(
                      serviceColor: AppColors.getServiceUnitColor(
                          widget.template.serviceUnit.name),
                      centerHeadName: _formData['approved_by']?.toString() ??
                          _formData['center_head']?.toString() ??
                          _formData['noted_by']?.toString() ??
                          '',
                      names: [
                        _formData['prepared_by']?.toString() ?? '',
                        _formData['medical_head_name']?.toString() ??
                            _formData['noted_by']?.toString() ??
                            '',
                      ],
                    )
                  else
                    FormFieldBuilders.signatoryBanner(
                      serviceColor: AppColors.getServiceUnitColor(
                          widget.template.serviceUnit.name),
                      centerHeadName: _formData['center_head']?.toString() ??
                          _formData['noted_by']?.toString() ??
                          '',
                      names: [
                        _formData['prepared_by']?.toString() ?? '',
                      ],
                    ),

                // Signatory Banner for Psychological Service forms
                if (widget.template.serviceUnit ==
                    ServiceUnit.psychologicalService)
                  if (widget.template.templateType == 'inter_service_referral')
                    FormFieldBuilders.signatoryBanner(
                      serviceColor: AppColors.getServiceUnitColor(
                          widget.template.serviceUnit.name),
                      centerHeadName: null,
                      names: [
                        _formData['referring_person']?.toString() ?? '',
                        _formData['psych_head_name']?.toString() ?? '',
                      ],
                    )
                  else
                    FormFieldBuilders.signatoryBanner(
                      serviceColor: AppColors.getServiceUnitColor(
                          widget.template.serviceUnit.name),
                      centerHeadName: _formData['center_head']?.toString() ??
                          _formData['noted_by']?.toString() ??
                          '',
                      names: [
                        _formData['prepared_by']?.toString() ??
                            _formData['user_name']?.toString() ??
                            '',
                      ],
                    ),

                // Form fields
                ...(() {
                  try {
                    // Inject submission ID so digitalSignature fields can upload
                    if (_submissionId != null) {
                      _formData['_submission_id'] = _submissionId;
                    }
                    return FormTemplatesRegistry.getFormFields(
                      widget.template,
                      _formData,
                      _updateField,
                      readOnlyFieldKeys: widget.residentData != null
                          ? FormTemplatesRegistry.residentSourcedFieldKeys
                          : null,
                      residentNames: _residentNames, // Pass cached residents
                    );
                  } catch (e, stackTrace) {
                    print('[FormFillScreen] Error building form fields: $e');
                    print('[FormFillScreen] Stack trace: $stackTrace');

                    return [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Error Loading Form',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type mismatch error: $e',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Go Back'),
                            ),
                          ],
                        ),
                      ),
                    ];
                  }
                })(),
                SizedBox(
                    height: screen.value(
                        mobile: 16.0, tablet: 20.0, desktop: 24.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchResidentNames() async {
    try {
      // Only fetch for relevant forms to save resources
      if (widget.template.templateType != 'incident_report' &&
          widget.template.templateType != 'group_sessions') {
        return;
      }

      // Lazy load repository
      final repo = context.read<ResidentRepository>();
      final residents = await repo.getResidents(status: 'admitted');

      if (mounted) {
        setState(() {
          _residentNames = residents
              .map((r) => '${r.firstName} ${r.lastName}'.trim())
              .where((n) => n.isNotEmpty)
              .toSet() // deduplicate
              .toList()
            ..sort();
        });
      }
    } catch (e) {
      print('Error fetching resident names: $e');
    }
  }

  Widget _buildFormHeader(ScreenInfo screen) {
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
                color: AppColors.getServiceUnitColor(
                        widget.template.serviceUnit.name)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.template.icon,
                color: AppColors.getServiceUnitColor(
                    widget.template.serviceUnit.name),
                size: screen.value(mobile: 24.0, tablet: 28.0, desktop: 32.0),
              ),
            ),
            SizedBox(
                width: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.template.name,
                    style: TextStyle(
                      fontSize: screen.value(
                          mobile: 18.0, tablet: 20.0, desktop: 22.0),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_formData['status'] != null &&
                      _getStatusLabel(_formData['status']).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_formData['status'])
                            .withOpacity(0.1),
                        border: Border.all(
                            color: _getStatusColor(_formData['status'])),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusLabel(_formData['status']).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(_formData['status']),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (widget.template.description.isNotEmpty) ...[
          SizedBox(
              height: screen.value(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
          Text(
            widget.template.description,
            style: TextStyle(
              fontSize: screen.value(mobile: 13.0, tablet: 14.0, desktop: 15.0),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(ScreenInfo screen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        screen.value(mobile: 16, tablet: 24, desktop: 32),
        12,
        screen.value(mobile: 16, tablet: 24, desktop: 32),
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.backgroundDark
            : AppColors.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: SafeArea(
        child: screen.isMobile
            ? _buildMobileBottomBar(screen)
            : _buildDesktopBottomBar(screen),
      ),
    );
  }

  Widget _buildMobileBottomBar(ScreenInfo screen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status indicator
        if (_isDirty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.pencil, size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                Text(
                  'Unsaved changes',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
        // Action buttons
        if (!_isSigned && !_isMedicalReview && _requiresApproval)
          // Forms requiring approval (P2/P3/P4): 2-row layout
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previewPdf,
                      icon: const Icon(LucideIcons.printer, size: 18),
                      label:
                          const Text('Print', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _saveDraft(shouldPop: true, finalize: true),
                      icon: const Icon(LucideIcons.clipboardCheck, size: 18),
                      label:
                          const Text('Save', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitForm,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.send),
                  label: const Text('Submit for Approval'),
                ),
              ),
            ],
          )
        else if (!_isSigned && !_isMedicalReview && _isSaveOnly)
          // Save-only forms: Print + Save & Complete (no submit button)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previewPdf,
                  icon: const Icon(LucideIcons.printer),
                  label: const Text('Print / Preview',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => _saveDraft(shouldPop: true, finalize: true),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.circleCheck),
                  label: const Text('Save & Complete'),
                ),
              ),
            ],
          )
        else if (!_isSigned && !_isMedicalReview)
          // Other non-approval forms: 2-row layout
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previewPdf,
                      icon: const Icon(LucideIcons.printer, size: 18),
                      label:
                          const Text('Print', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _saveDraft(shouldPop: true, finalize: true),
                      icon: const Icon(LucideIcons.clipboardCheck, size: 18),
                      label: const Text('Save for Signing',
                          overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _submitForm,
                  icon: const Icon(LucideIcons.send),
                  label: const Text('Submit'),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _previewPdf,
                  child: const Text('Preview'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submitForm,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.isEditing ? 'Update & Resubmit' : 'Submit'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDesktopBottomBar(ScreenInfo screen) {
    return Row(
      children: [
        // Status
        if (_isDirty)
          Row(
            children: [
              Icon(LucideIcons.pencil, size: 16, color: AppColors.warning),
              const SizedBox(width: 6),
              Text(
                'Unsaved changes',
                style: TextStyle(color: AppColors.warning),
              ),
            ],
          ),
        const Spacer(),
        // Actions
        const Spacer(),
        // Actions
        // Always show Preview/Print and Save Draft options logic
        // User wants: "Save form... have option to view it again then print it"
        // "Whenever user prints... viewable again"

        // Print/Preview Button
        OutlinedButton.icon(
          onPressed: _previewPdf,
          icon: const Icon(LucideIcons.printer),
          label: const Text('Print / Preview'),
        ),
        const SizedBox(width: 12),

        // Save for Signing Button (Replaces Save Draft)

        // Save for Signing Button (Replaces Save Draft)
        if (!_isReadOnly)
          OutlinedButton.icon(
            onPressed: () => _saveDraft(shouldPop: true, finalize: true),
            icon: Icon(
                _isSigned ? LucideIcons.refreshCw : LucideIcons.clipboardCheck),
            label: Text(_isSigned ? 'Update Submission' : 'Save for Signing'),
          ),

        const SizedBox(width: 12),

        // Submit for Approval button for forms with approval workflows (P2/P3/P4)
        if (!_isReadOnly && _requiresApproval && !_isMedicalReview)
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _submitForm,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.send),
            label: const Text('Submit for Approval'),
          ),

        if (_isMedicalReview) ...[
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: _isSaving ? null : _approveMedicalReview,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(LucideIcons.badgeCheck),
            label: const Text('Approve Medical Review'),
          ),
        ],
      ],
    );
  }

  Future<void> _previewPdf() async {
    // Removed auto-save to prevents creating unwanted drafts
    // if (_isDirty) {
    //   await _saveDraft(shouldPop: false);
    // }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FormPdfPreviewScreen(
          template: widget.template,
          formData: _formData,
          residentName: widget.residentName,
          residentId: widget.residentId,
          submissionId: _submissionId,
          caseNumber: widget.caseNumber,
        ),
      ),
    );
  }

  bool get _isMedicalReview {
    final status = _formData['status'];
    if (status != AppConstants.statusPendingMedicalReview) return false;

    // Check if current user is medical staff
    final state = context.read<AuthBloc>().state;
    if (state is AuthAuthenticated) {
      return state.user.unit == AppConstants.unitMedical;
    }
    return false;
  }

  Future<void> _approveMedicalReview() async {
    setState(() => _isSaving = true);
    try {
      final formRepository = context.read<FormRepository>();

      // First save any changes (findings/recommendations)
      if (_submissionId != null) {
        await formRepository.updateDraft(
          id: _submissionId!,
          formData: _formData,
        );
      }

      // Then approve
      await formRepository.approveForm(_submissionId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medical Review Completed'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(ErrorHandler.getUserFriendlyMessage(e)),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _saveDraft(
      {bool shouldPop = true, bool finalize = false}) async {
    setState(() => _isSaving = true);
    // Save-only forms go directly to 'approved' (completed) on finalize
    final targetStatus = finalize
        ? (_isSaveOnly
            ? AppConstants.statusApproved
            : AppConstants.statusSubmitted)
        : AppConstants.statusDraft;

    try {
      final formRepository = context.read<FormRepository>();
      FormSubmissionModel submission;

      if (_submissionId != null) {
        // Update existing draft
        submission = await formRepository.updateDraft(
          id: _submissionId!,
          formData: _formData,
          status: targetStatus,
        );
      } else {
        // Create new draft
        submission = await formRepository.createDraft(
          residentId: widget.residentId,
          templateId: widget.template.id,
          templateType: widget.template.templateType,
          unit: _databaseUnit,
          formData: _formData,
          status: targetStatus,
        );
        _submissionId = submission.id;
      }

      // Option B: freeze preparer signature per submission.
      // When the form is finalized/signed, store the current user's signature
      // into form_signatures under field_name='prepared_by'.
      if (targetStatus == AppConstants.statusSubmitted) {
        if (_submissionId != null) {
          await _upsertPreparedBySignature(submissionId: _submissionId!);
        }
      }

      setState(() {
        _isDirty = false;
        _isSaving = false;
      });

      if (mounted) {
        if (shouldPop) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Form saved successfully.'),
            backgroundColor: AppColors.success,
          ));
          Navigator.of(context).pop(true); // Go back to forms list
        } else {
          // If not popping (e.g. before preview), just show small toast or nothing?
          // Maybe nothing to avoid clutter if going to preview.
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool get _isSigned => _formData['status'] == AppConstants.statusSubmitted;

  /// Whether this form requires approval (P2/P3/P4 forms with approval signatories)
  /// Forms with Center Head or workflow configs need the Submit for Approval flow.
  bool get _requiresApproval {
    if (_isSaveOnly) return false;
    final signatories = widget.template.requiredSignatories;
    if (widget.template.workflowConfig != null) return true;
    // If signatories include Center Head or any head/supervisor role, approval is needed
    return signatories.any((s) =>
        s.contains('Center Head') ||
        s.contains('Supervising') ||
        s.contains('Medical Officer'));
  }

  /// Save-only forms: no approval workflow, save marks as completed (approved)
  bool get _isSaveOnly {
    return !widget.template.requiresSignature &&
        widget.template.requiredSignatories.isEmpty &&
        widget.template.workflowConfig == null;
  }

  /// Forms where the medical staff is selected via banner tag (not dialog)
  static const _bannerMedicalStaffRouting = {
    'admission_slip',
    'discharge_slip',
  };

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fix the errors before submitting')),
      );
      return;
    }

    final templateType = widget.template.templateType;

    // Custom Validation for Top-Level Signatory Tags on Specific Forms
    if (templateType == 'out_on_pass') {
      final centerDoctor = _formData['center_doctor']?.toString().trim() ?? '';
      final socialWorker = _formData['social_worker']?.toString().trim() ?? '';

      if (centerDoctor.isEmpty || socialWorker.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Please select the Center Doctor and Social Worker at the top of the form before submitting.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    if (templateType == 'nt_malnourished_list' ||
        templateType == 'nt_ncp_mnt') {
      final centerDoctor = _formData['center_doctor']?.toString().trim() ?? '';
      if (centerDoctor.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Please select the Center Doctor at the top of the form before submitting.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    // ── Required digital signature validation ──
    final requiredSigFields =
        FormTemplatesRegistry.getRequiredSignatureFields(templateType);
    if (requiredSigFields.isNotEmpty) {
      final missingLabels = <String>[];
      for (final field in requiredSigFields) {
        final val = _formData[field]?.toString().trim() ?? '';
        if (val.isEmpty) {
          // Convert field name to human-readable label
          final label = field
              .replaceAll('_signature_url', '')
              .replaceAll('_', ' ')
              .split(' ')
              .map((w) =>
                  w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
              .join(' ');
          missingLabels.add(label);
        }
      }
      if (missingLabels.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Please capture the following required signature(s) before submitting: ${missingLabels.join(', ')}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    }

    final approvalRepo = ApprovalRepository();
    final currentUserId = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
        : null;

    // ── A. Medical staff routing via banner tag (Admission/Discharge Slip) ──
    if (_bannerMedicalStaffRouting.contains(templateType)) {
      final medicalStaffName =
          _formData['medical_staff_name']?.toString().trim() ?? '';
      if (medicalStaffName.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Please select a Medical Staff at the top of the form before submitting.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Use all medical unit users (nurses, medical_staff, heads) so any selected name resolves
      final medicalUsers = await approvalRepo.getUsersByUnit('medical');
      final target = medicalUsers
          .where((u) =>
              (currentUserId == null || u.id != currentUserId) &&
              u.fullName.trim().toUpperCase() == medicalStaffName.toUpperCase())
          .firstOrNull;

      if (target != null) {
        debugPrint(
            '[Submit] Route A: Banner medical staff ${target.fullName} for $templateType');
        await _performSubmission(target.id, target.fullName);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Could not find medical staff "$medicalStaffName". Please select a valid staff member from the medical unit.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
      return;
    }

    // ── C. Primary path: auto-route via workflowConfig ──
    // All forms now have workflowConfig. Route to the first step's required role.
    final wfConfig = widget.template.workflowConfig;
    if (wfConfig != null && wfConfig.steps.isNotEmpty) {
      final firstStep = wfConfig.steps[wfConfig.initialStepId];
      if (firstStep != null && firstStep.requiredRoles.isNotEmpty) {
        // Path B: Check if current user is already the Unit Head / Approver for this step
        final authState = context.read<AuthBloc>().state;
        final currentUser =
            authState is AuthAuthenticated ? authState.user : null;

        bool canSkipFirstStep = false;
        if (currentUser != null) {
          // Check if current user role matches step requirements
          canSkipFirstStep = firstStep.requiredRoles
                  .contains(currentUser.role) ||
              (currentUser.role == 'head' && currentUser.unit == _databaseUnit);
        }

        if (canSkipFirstStep) {
          debugPrint(
              '[Submit] Path B: Unit Head creating form. Skipping first step: ${firstStep.id}');

          final nextStepId = firstStep.nextStepId;
          if (nextStepId == null) {
            // No next step? Go straight to approved
            await _performSubmission(null, null,
                skipToStatus: AppConstants.statusApproved);
            return;
          }

          final nextStep = wfConfig.steps[nextStepId];
          if (nextStep != null) {
            // Find recipients for the NEXT step
            final recipients = await approvalRepo.getApprovalRecipients(
              excludeUserId: currentUserId,
            );

            // Find user matching any required role or generic 'head' in same unit (for that next step)
            final target = recipients
                .where((u) =>
                    nextStep.requiredRoles.contains(u.role) ||
                    (u.role == 'head' && u.unit == _databaseUnit))
                .firstOrNull;

            if (target != null) {
              debugPrint(
                  '[Submit] Path B: Auto-routing to next step ($nextStepId) recipient: ${target.fullName}');
              await _performSubmission(target.id, target.fullName,
                  skipToStatus: nextStepId);
              return;
            }
          }
        }

        // Standard Path A: Route to the first step's required role
        final recipients = await approvalRepo.getApprovalRecipients(
          excludeUserId: currentUserId,
        );

        // Find user matching any required role or generic 'head' in same unit
        final target = recipients
            .where((u) =>
                firstStep.requiredRoles.contains(u.role) ||
                (u.role == 'head' && u.unit == _databaseUnit))
            .firstOrNull;

        if (target != null) {
          debugPrint(
              '[Submit] Route C: workflowConfig auto-route to ${target.fullName} (${target.role}) for $templateType');
          await _performSubmission(target.id, target.fullName);
          return;
        }
        // If no matching user found, fall through to fallback
        debugPrint(
            '[Submit] No matching user for roles ${firstStep.requiredRoles} — falling through to fallback');
      }
    }

    // ── D. Fallback: show reviewer dialog ──
    if (!mounted) return;

    final selectedReviewer = await showDialog<UserModel>(
      context: context,
      builder: (context) => ReviewerSelectionDialog(
        serviceUnit: _databaseUnit,
        currentUserId: currentUserId,
      ),
    );
    if (selectedReviewer != null) {
      await _performSubmission(selectedReviewer.id, selectedReviewer.fullName);
    }
  }

  Widget _buildCopyDataBanner(ScreenInfo screen) {
    return FutureBuilder<FormSubmissionModel?>(
      future: context.read<FormRepository>().getLatestForm(
            residentId: widget.residentId,
            templateType: widget.template.templateType,
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final previousForm = snapshot.data!;
        // Don't show if this is the same form (shouldn't happen in create mode) or very old?
        // Actually, always showing implies utility.

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.history, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Previous Assessment Found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Date: ${DateTime.parse(previousForm.createdAt.toIso8601String()).toLocal().toString().split(' ')[0]}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _copyPreviousData(previousForm.formData),
                icon: const Icon(LucideIcons.copy, size: 16),
                label: const Text('Copy Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _copyPreviousData(Map<String, dynamic> previousData) {
    // Fields to copy for Nursing Care
    final fieldsToCopy = [
      'weight',
      'height',
      'bmi',
      'skin',
      'hair',
      'eyes',
      'ears',
      'mouth',
      'nails',
      'chest_lungs',
      'cardio',
      'abdomen',
      'genitals',
      'extremities',
      'body_map_description',
      'assessment', // Includes diet now
    ];

    setState(() {
      for (final key in fieldsToCopy) {
        if (previousData.containsKey(key)) {
          _formData[key] = previousData[key];
        }
      }
      _isDirty = true;
      _fieldsKey = UniqueKey(); // Force rebuild to show copied values
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data copied from previous assessment'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  /// Helper to convert empty strings to null for UUID fields
  String? _nullIfEmpty(String? value) =>
      (value?.isEmpty ?? true) ? null : value;

  Future<void> _performSubmission(String? recipientId, String? recipientName,
      {String? skipToStatus}) async {
    setState(() => _isSaving = true);

    try {
      final formRepository = context.read<FormRepository>();
      final approvalRepository = ApprovalRepository();

      // Get current user
      final authState = context.read<AuthBloc>().state;
      final currentUser =
          authState is AuthAuthenticated ? authState.user : null;

      // Validate resident ID
      if (widget.residentId.isEmpty) {
        throw Exception('Resident ID is missing. Cannot submit form.');
      }

      // Validate recipient - ensure we have valid data or null
      final safeRecipientId = _nullIfEmpty(recipientId);
      final safeRecipientName = _nullIfEmpty(recipientName);

      // If no submission exists yet, create a draft first
      if (_submissionId == null) {
        final draft = await formRepository.createDraft(
          residentId: widget.residentId,
          templateId: widget.template.id,
          templateType: widget.template.templateType,
          unit: _databaseUnit,
          formData: _formData,
        );
        _submissionId = draft.id;
      }

      if (_submissionId != null) {
        try {
          await _upsertPreparedBySignature(submissionId: _submissionId!);
        } catch (_) {}
      }

      // Add recipient info and prepared by info to form data
      // Only add if they have actual values (not empty strings)
      final submissionData = Map<String, dynamic>.from(_formData);
      if (safeRecipientId != null) {
        submissionData['submitted_to_id'] = safeRecipientId;
        submissionData['submitted_to_name'] = safeRecipientName;
      }

      // Auto-populate "Prepared By" with current user info
      if (currentUser != null) {
        submissionData['prepared_by_id'] = _nullIfEmpty(currentUser.id);
        submissionData['prepared_by_name'] = _nullIfEmpty(currentUser.fullName);
        submissionData['prepared_by_title'] = _nullIfEmpty(currentUser.title);
        submissionData['prepared_by_employee_id'] =
            _nullIfEmpty(currentUser.employeeId);

        // Also populate the template-specific name field if defined (e.g., inspected_by, received_by)
        final preparerNameField =
            widget.template.preparerSignatureField ?? 'prepared_by';
        submissionData[preparerNameField] = currentUser.fullName.toUpperCase();
      }

      // Determine the correct initial status from workflow config or template type
      // For Path B, if skipToStatus is provided, we use it directly.
      String? workflowInitialStatus =
          skipToStatus ?? widget.template.workflowConfig?.initialStepId;

      // If we skipped a step (Path B), apply the signature for that step automatically
      if (skipToStatus != null && widget.template.workflowConfig != null) {
        final wfConfig = widget.template.workflowConfig!;
        final firstStepId = wfConfig.initialStepId;
        final firstStep = wfConfig.steps[firstStepId];

        if (firstStep != null && firstStep.signatureFieldName != null) {
          try {
            await _upsertSignatorySignature(
              submissionId: _submissionId!,
              fieldName: firstStep.signatureFieldName!,
              fieldLabel: firstStep.label,
            );
            debugPrint(
                '[Submit] Auto-applied signature for skipped step: ${firstStep.id}');
          } catch (e) {
            debugPrint('[Submit] Failed to auto-apply skip signature: $e');
          }
        }
      }

      // Submit the form for review
      await formRepository.submitForm(
        id: _submissionId!,
        formData: submissionData,
        initialStatus: workflowInitialStatus,
      );

      // Create an approval request if recipient is specified
      if (safeRecipientId != null &&
          safeRecipientName != null &&
          currentUser != null) {
        try {
          // Use the appropriate workflow step's signatureFieldName, or default to 'noted_by'
          String? signatureFieldForRecipient;
          if (widget.template.requiresSignature) {
            final wfConfig = widget.template.workflowConfig;
            if (wfConfig != null) {
              // If we skipped to a specific status, get signature for THAT step
              final currentStepId = skipToStatus ?? wfConfig.initialStepId;
              final currentStep = wfConfig.steps[currentStepId];
              signatureFieldForRecipient =
                  currentStep?.signatureFieldName ?? 'noted_by';
            } else {
              signatureFieldForRecipient = 'noted_by';
            }
          }

          // Only pass signatureFieldName if the form requires signatures
          // Forms without signatures will just be acknowledged/received
          await approvalRepository.createApprovalRequest(
            formId: _submissionId!,
            recipientId: safeRecipientId,
            recipientName: safeRecipientName,
            signatureFieldName: signatureFieldForRecipient,
          );
        } catch (e) {
          // Log but don't fail the submission if approval request fails
          debugPrint('Failed to create approval request: $e');
        }
      }

      setState(() => _isSaving = false);

      if (mounted) {
        // Show confirmation dialog telling user where the form was sent
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(LucideIcons.circleCheck,
                color: AppColors.success, size: 48),
            title: const Text('Form Submitted'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (safeRecipientName != null) ...[
                  const Text('Your form has been sent to:'),
                  const SizedBox(height: 8),
                  Text(
                    safeRecipientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'for review and approval',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ] else
                  const Text('Your form has been submitted successfully.'),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getUserFriendlyMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _discardChanges() {
    setState(() {
      _formData = widget.initialData != null
          ? Map<String, dynamic>.from(widget.initialData!)
          : FormTemplatesRegistry.getDefaultData(widget.template);
      _isDirty = false;
    });
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to leave?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Discard'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Get job title based on user's unit
  /// Returns the human-readable job title (not license suffix)
  String _getJobTitle(UserModel user) {
    // 1. Prioritize official title from profile
    if (user.title != null && user.title!.trim().isNotEmpty) {
      return user.title!.trim();
    }

    // 2. Legacy derive job title from unit (Fallbacks)
    switch (user.unit?.toLowerCase()) {
      case 'psych':
        return 'Psychometrician';
      case 'social':
        return 'Social Worker';
      case 'homelife':
        // Fix: Use Houseparent as a better default than Housekeeper
        return user.isUnitHead ? 'Supervising Houseparent I' : 'Houseparent I';
      case 'medical':
        if (user.role == 'medical_center_doctor' ||
            user.role == 'center_doctor') {
          return 'Center Doctor';
        }
        return 'Nurse';
      default:
        // Fall back to role-based title
        if (user.isCenterHead) return 'Center Head';
        if (user.isSuperAdmin) return 'Administrator';
        if (user.isUnitHead) return 'Unit Head';
        return user.role.replaceAll('_', ' ');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.statusDraft:
        return Colors.grey;
      case AppConstants.statusSubmitted:
        return AppColors.info;
      case AppConstants.statusPendingReview:
      case AppConstants.statusPendingSupervisor:
      case AppConstants.statusPendingHeadApproval:
      case AppConstants.statusPendingFinalApproval:
      case AppConstants.statusPendingSocialWorker:
      case AppConstants.statusPendingMultiApproval:
        return AppColors.warning;
      case AppConstants.statusPendingMedicalReview:
      case AppConstants.statusPendingDoctorReview:
        return Colors.purple;
      case AppConstants.statusApproved:
        return AppColors.success;
      case AppConstants.statusReturned:
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case AppConstants.statusDraft:
        return 'Draft';
      case AppConstants.statusSubmitted:
        return 'Signed / Submitted';
      case AppConstants.statusPendingReview:
        return 'Pending Review';
      case AppConstants.statusPendingSupervisor:
        return 'Pending Supervisor';
      case AppConstants.statusPendingMultiApproval:
        return 'Pending Multi-Dept Approval';
      case AppConstants.statusPendingHeadApproval:
        return 'Pending Center Head';
      case AppConstants.statusPendingMedicalReview:
        return 'Medical Review';
      case AppConstants.statusPendingDoctorReview:
        return 'Doctor Review';
      case AppConstants.statusPendingSocialWorker:
        return 'Pending Social Worker';
      case AppConstants.statusPendingFinalApproval:
        return 'Pending Final Approval';
      case AppConstants.statusApproved:
        return 'Approved';
      case AppConstants.statusReturned:
        return 'Returned';
      default:
        return status.replaceAll('_', ' ');
    }
  }
}
