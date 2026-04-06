import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/form_submission_model.dart';
import '../models/timeline_entry_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/supabase_config.dart';
import '../../core/utils/backend_config.dart';

/// Repository for form operations
class FormRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  void _log(String message) {
    if (kDebugMode) {
      print('[FormRepository] $message');
    }
  }

  void _logAudit(String action, {String? details, String? resourceId}) {
    try {
      final user = _supabase.auth.currentUser;
      _supabase.from('audit_logs').insert({
        'action': action,
        'details': details,
        'user_id': user?.id,
        'user_email': user?.email,
        'resource_type': 'form_submission',
        'resource_id': resourceId,
      });
    } catch (_) {}
  }

  bool _isForSigningStatus(String status) {
    return status == AppConstants.statusSubmitted ||
        status == AppConstants.statusPendingReview ||
        status == AppConstants.statusPendingMedicalReview ||
        status == AppConstants.statusPendingFinalApproval ||
        status == AppConstants.statusPendingSupervisor ||
        status == AppConstants.statusPendingMultiApproval ||
        status == AppConstants.statusPendingHeadApproval ||
        status == AppConstants.statusPendingDoctorReview ||
        status == AppConstants.statusPendingSocialWorker;
  }

  /// Get all forms (alias for getMyForms with no filters)
  Future<List<FormSubmissionModel>> getForms() async {
    return getMyForms();
  }

  /// Get forms for current user
  Future<List<FormSubmissionModel>> getMyForms({
    String? status,
    String? unit,
    int page = 0,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Build filter query first, then order and paginate
      var query = _supabase.from('form_submissions').select('''
            *,
            resident:residents(first_name, last_name),
            submitter:profiles!form_submissions_submitted_by_fkey(full_name, signature_url),
            reviewer:profiles!form_submissions_reviewed_by_fkey(full_name, signature_url)
          ''').eq('submitted_by', userId).eq('is_archived', false);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (unit != null) {
        query = query.eq('unit', unit);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return response
          .map((json) => FormSubmissionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch forms: $e');
    }
  }

  /// Get all forms for a specific unit (for history/audit)
  Future<List<FormSubmissionModel>> getUnitForms({
    String? unit,
    int page = 0,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      var query = _supabase.from('form_submissions').select('''
            *,
            resident:residents(first_name, last_name),
            submitter:profiles!form_submissions_submitted_by_fkey(full_name, signature_url),
            reviewer:profiles!form_submissions_reviewed_by_fkey(full_name, signature_url)
          ''').eq('is_archived', false);

      if (unit != null && unit != 'all') {
        query = query.eq('unit', unit);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return response
          .map((json) => FormSubmissionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch unit forms: $e');
    }
  }

  /// Get forms pending approval for the current user.
  /// Uses the form_approvals table to only show forms explicitly sent to this user,
  /// preventing Unit Heads from seeing forms routed to Center Head and vice versa.
  Future<List<FormSubmissionModel>> getPendingApprovals({
    required String unit,
    String? excludeSubmitterId,
    int page = 0,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Step 1: Get form IDs from form_approvals where this user is the recipient
      final approvalRows = await _supabase
          .from('form_approvals')
          .select('form_submission_id')
          .eq('recipient_id', userId)
          .eq('status', 'pending');

      final formIds = (approvalRows as List)
          .map((row) => row['form_submission_id'] as String)
          .toSet()
          .toList();

      if (formIds.isEmpty) return [];

      // Step 2: Fetch the actual form submissions for those IDs
      var query = _supabase
          .from('form_submissions')
          .select('''
            *,
            resident:residents(first_name, last_name),
            submitter:profiles!form_submissions_submitted_by_fkey(full_name, signature_url)
          ''')
          .inFilter('id', formIds)
          .neq('status', AppConstants.statusApproved);

      // Prevent self-approval: exclude forms submitted by the current user
      if (excludeSubmitterId != null) {
        query = query.neq('submitted_by', excludeSubmitterId);
      }

      final response = await query
          .order('submitted_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return response
          .map((json) => FormSubmissionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending approvals: $e');
    }
  }

  /// Get count of forms completed (approved) today
  Future<int> getCompletedFormsCount({String? unit}) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      var query = _supabase
          .from('form_submissions')
          .count(CountOption.exact)
          .eq('status', AppConstants.statusApproved)
          .gte('reviewed_at', startOfDay.toIso8601String())
          .lt('reviewed_at', endOfDay.toIso8601String());

      if (unit != null && unit != 'all') {
        query = query.eq('unit', unit);
      }

      final count = await query;
      return count;
    } catch (e) {
      _log('Error counting completed forms: $e');
      return 0;
    }
  }

  /// Get forms for a specific resident
  Future<List<FormSubmissionModel>> getResidentForms({
    required String residentId,
    String? unit,
    String? status,
    int page = 0,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      var query = _supabase.from('form_submissions').select('''
            *,
            submitter:profiles!form_submissions_submitted_by_fkey(full_name, signature_url),
            reviewer:profiles!form_submissions_reviewed_by_fkey(full_name, signature_url)
          ''').eq('resident_id', residentId).eq('is_archived', false);

      if (unit != null) {
        query = query.eq('unit', unit);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return response
          .map((json) => FormSubmissionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch resident forms: $e');
    }
  }

  /// Get single form by ID
  Future<FormSubmissionModel> getFormById(String id) async {
    try {
      final response = await _supabase.from('form_submissions').select('''
            *,
            resident:residents(first_name, last_name),
            submitter:profiles!form_submissions_submitted_by_fkey(full_name, signature_url),
            reviewer:profiles!form_submissions_reviewed_by_fkey(full_name, signature_url)
          ''').eq('id', id).single();

      return FormSubmissionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch form: $e');
    }
  }

  /// Get the latest form submission for a specific resident and template type
  Future<FormSubmissionModel?> getLatestForm({
    required String residentId,
    required String templateType,
  }) async {
    try {
      final response = await _supabase
          .from('form_submissions')
          .select()
          .eq('resident_id', residentId)
          .eq('template_type', templateType)
          .eq('is_archived', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return FormSubmissionModel.fromJson(response);
    } catch (e) {
      _log('Error fetching latest form: $e');
      return null;
    }
  }

  /// Search forms by resident name or template name
  Future<List<FormSubmissionModel>> searchForms(String query) async {
    try {
      _log('Searching forms with query: $query');

      // We search across:
      // 1. resident:first_name
      // 2. resident:last_name
      // 3. template_type (which is basically the template name/id)
      // Since template_id is a UUID, we usually rely on template_type or joined data.
      // For now, let's search via the joined residents table.

      final response = await _supabase.from('form_submissions').select('''
            *,
            resident:residents(first_name, last_name),
            submitter:profiles!form_submissions_submitted_by_fkey(full_name)
          ''').eq('is_archived', false).or('template_type.ilike.%$query%');

      // Note: Supabase 'or' across joined tables is tricky.
      // Let's filter in memory if result set is manageable, or just search template_type for now.
      // TODO: Improve this to search resident names too if Supabase API allows easily.

      _log('Search results: ${response.length}');
      return response
          .map((json) => FormSubmissionModel.fromJson(json))
          .toList();
    } catch (e) {
      _log('Error searching forms: $e');
      return [];
    }
  }



  /// Create draft form
  Future<FormSubmissionModel> createDraft({
    required String residentId,
    required String templateId,
    required String templateType,
    required String unit,
    required Map<String, dynamic> formData,
    String? status,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      _log(
          'Creating draft - residentId: $residentId, templateId: $templateId, unit: $unit, userId: $userId');

      if (userId == null) {
        _log('ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      final insertData = {
        'resident_id': residentId,
        'template_id': templateId,
        'template_type': templateType,
        'unit': unit,
        'form_data': formData,
        'status': status ?? AppConstants.statusDraft,
        'submitted_by': userId,
      };
      _log('Insert data: $insertData');

      final response = await _supabase
          .from('form_submissions')
          .insert(insertData)
          .select()
          .maybeSingle();

      if (response == null) {
        _log(
            'WARNING: Draft created but no data returned. Possible RLS issue.');
        // If RLS prevents seeing the created draft, we can't properly continue the flow.
        throw Exception(
            'Form draft created, but you do not have permission to view it. Please contact technical support regarding "Row Level Security on form_submissions".');
      }

      _log('Draft created successfully: ${response['id']}');
      return FormSubmissionModel.fromJson(response);
    } on PostgrestException catch (e) {
      _log(
          'PostgrestException creating draft - code: ${e.code}, message: ${e.message}, details: ${e.details}');
      throw Exception('Database error (v2): ${e.message}');
    } catch (e) {
      _log('Error creating draft: $e');
      throw Exception('Failed to create draft: $e');
    }
  }

  Future<FormSubmissionModel> updateDraft({
    required String id,
    required Map<String, dynamic> formData,
    String? status,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updateData = {
        'form_data': formData,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (status != null) {
        updateData['status'] = status;
      }

      final response = await _supabase
          .from('form_submissions')
          .update(updateData)
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response != null) {
        return FormSubmissionModel.fromJson(response);
      }

      // RLS may block updates for approver-recipient edits (e.g., medical staff filling findings).
      // Fallback to backend (Service Role) to persist form_data when user is authorized via form_approvals.
      final resolvedUrl = await BackendConfig.getBackendUrl();
      final urlCandidates = <String>[
        '$resolvedUrl/update-form-data',
      ];

      http.Response? httpResponse;
      Object? lastError;
      for (final url in urlCandidates) {
        try {
          httpResponse = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'form_id': id,
              'user_id': userId,
              'form_data': formData,
              if (status != null) 'status': status,
            }),
          );
          if (httpResponse.statusCode == 200) break;
        } catch (e) {
          lastError = e;
        }
      }

      if (httpResponse != null && httpResponse.statusCode == 200) {
        final data = jsonDecode(httpResponse.body);
        final remote = data['data'] as Map<String, dynamic>?;
        if (remote != null) return FormSubmissionModel.fromJson(remote);
      }

      final body = httpResponse?.body;
      if (body != null && body.isNotEmpty) {
        throw Exception(body);
      }
      throw Exception(
        'Cannot update form. Tried: ${urlCandidates.join(', ')}'
        '${lastError != null ? '\n\nError: $lastError' : ''}',
      );
    } catch (e) {
      throw Exception('Failed to update draft: $e');
    }
  }

  /// Upload signed form image/PDF and attach it to an existing
  /// "For Signing" submission to avoid duplicate form records.
  Future<FormSubmissionModel> uploadSignedForm({
    required String formSubmissionId,
    required Uint8List imageBytes,
    required String fileName,
    String fileType = 'image',
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // 1. Upload image to 'form_attachments' bucket
      final path =
          'signed_forms/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _supabase.storage.from('form_attachments').uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl =
          _supabase.storage.from('form_attachments').getPublicUrl(path);

      // 2. Fetch target form and ensure it is still in For Signing state
      final existingResponse = await _supabase
          .from('form_submissions')
          .select('status, form_data')
          .eq('id', formSubmissionId)
          .eq('is_archived', false)
          .maybeSingle();

      if (existingResponse == null) {
        throw Exception('Selected form was not found.');
      }

      final existingStatus = (existingResponse['status'] as String?) ?? '';
      if (!_isForSigningStatus(existingStatus)) {
        throw Exception(
          'Only forms in "For Signing" can be uploaded as signed forms.',
        );
      }

      final existingFormDataRaw = existingResponse['form_data'];
      final existingFormData = existingFormDataRaw is Map
          ? Map<String, dynamic>.from(existingFormDataRaw)
          : <String, dynamic>{};

      final mergedFormData = {
        ...existingFormData,
        'signed_image_url': imageUrl,
        'uploaded_at': DateTime.now().toIso8601String(),
        'is_uploaded_record': true,
        'file_type': fileType,
      };

      // 3. Primary path: backend endpoint (service-role) to bypass RLS and
      // safely transition For Signing -> Approved on the SAME record.
      final resolvedUrl = await BackendConfig.getBackendUrl();
      final urlCandidates = <String>[
        '$resolvedUrl/upload-signed-form',
      ];

      http.Response? httpResponse;
      Object? lastError;

      for (final url in urlCandidates) {
        try {
          httpResponse = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'form_id': formSubmissionId,
              'user_id': userId,
              'signed_image_url': imageUrl,
              'file_type': fileType,
            }),
          );
          if (httpResponse.statusCode == 200) break;
        } catch (e) {
          lastError = e;
        }
      }

      if (httpResponse != null && httpResponse.statusCode == 200) {
        final data = jsonDecode(httpResponse.body);
        final remote = data['data'] as Map<String, dynamic>?;
        if (remote != null) return FormSubmissionModel.fromJson(remote);
      }

      // 4. Fallback path: direct update (may fail under strict RLS)
      final response = await _supabase
          .from('form_submissions')
          .update({
            'form_data': mergedFormData,
            'status': AppConstants.statusApproved,
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', formSubmissionId)
          .select('''
            *,
            resident:residents(first_name, last_name),
            submitter:profiles!form_submissions_submitted_by_fkey(full_name, signature_url),
            reviewer:profiles!form_submissions_reviewed_by_fkey(full_name, signature_url)
          ''')
          .single();

      // If backend failed but direct succeeded, we still return success.
      if (httpResponse != null && httpResponse.statusCode != 200) {
        _log(
          'WARNING: Backend upload-signed-form failed (${httpResponse.statusCode}), direct fallback succeeded.',
        );
      } else if (httpResponse == null && lastError != null) {
        _log('WARNING: Backend upload-signed-form unreachable: $lastError');
      }

      return FormSubmissionModel.fromJson(response);
    } catch (e) {
      _log('Error uploading signed form: $e');
      throw Exception('Failed to upload signed form: $e');
    }
  }

  /// Submit form for review (with signature)
  /// [initialStatus] - Override for workflow forms (e.g. 'pending_supervisor', 'pending_multi_approval')
  Future<FormSubmissionModel> submitForm({
    required String id,
    required Map<String, dynamic> formData,
    String? initialStatus,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      _log('Submitting form - id: $id, userId: $userId');

      if (userId == null) {
        _log('ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      final updateData = {
        'form_data': formData,
        'status': initialStatus ?? AppConstants.statusPendingReview,
        'submitted_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      _log('Update data: status=${updateData['status']}');

      final response = await _supabase
          .from('form_submissions')
          .update(updateData)
          .eq('id', id)
          .select()
          .maybeSingle();

      if (response == null) {
        _log(
            'WARNING: Form submitted but no data returned. Possible RLS issue.');
        throw Exception(
            'Form submitted successfully, but you do not have permission to view the result. Please contact technical support regarding "Row Level Security on form_submissions".');
      }

      _log('Form submitted successfully: ${response['id']}');
      _logAudit('Form Submitted',
          details:
              'Form ${response['template_type']} submitted (status: ${updateData['status']})',
          resourceId: id);

      // Create timeline entry for submission
      try {
        // Fetch fresh data including template display name if possible,
        // or just use what we have. We need residentId at least.
        // response has resident_id
        final submittedForm = FormSubmissionModel.fromJson(response);

        // Fetch submitter name
        String submitterName = 'Staff';
        try {
          final profile = await _supabase
              .from('profiles')
              .select('full_name')
              .eq('id', userId)
              .single();
          submitterName = profile['full_name'] ?? 'Staff';
        } catch (_) {}

        await _createTimelineEntry(
          residentId: submittedForm.residentId,
          entryType: 'form',
          formSubmissionId: submittedForm.id,
          formTemplateType: submittedForm.templateType,
          unit: submittedForm.unit,
          title: submittedForm.templateDisplayName,
          description: 'Form submitted by $submitterName',
          createdBy: userId,
        );

        // Notify approvers via Backend (Fire and forget from UI perspective, but we await to log errors)
        try {
          final recipientId = submittedForm.formData['submitted_to_id'];
          await _notifyApprovers(
            unit: submittedForm.unit,
            formId: submittedForm.id,
            formTitle: submittedForm.templateDisplayName,
            submitterName: submitterName,
            recipientId: recipientId,
          );
        } catch (e) {
          _log('WARNING: Failed to notify approvers: $e');
        }
      } catch (e) {
        _log('WARNING: Failed to create timeline entry for submission: $e');
      }

      return FormSubmissionModel.fromJson(response);
    } on PostgrestException catch (e) {
      _log(
          'PostgrestException submitting form - code: ${e.code}, message: ${e.message}, details: ${e.details}');
      throw Exception('Database error (v2): ${e.message}');
    } catch (e) {
      _log('Error submitting form: $e');
      throw Exception('Failed to submit form: $e');
    }
  }

  /// Approve form (unit head action)
  Future<FormSubmissionModel> approveForm(String id) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // 1. Primary path: Use backend workflow engine (Service Role)
      // This correctly handles parallel signatures and multi-step workflows.
      try {
        final resolvedUrl = await BackendConfig.getBackendUrl();
        final urlCandidates = <String>[
          '$resolvedUrl/approve-form',
        ];

        http.Response? httpResponse;
        Object? lastError;
        for (final url in urlCandidates) {
          try {
            httpResponse = await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'form_id': id,
                'user_id': userId,
              }),
            );
            if (httpResponse.statusCode == 200) break;
          } catch (e) {
            lastError = e;
          }
        }

        if (httpResponse != null && httpResponse.statusCode == 200) {
          _log('Backend approval successful');

          final responseData = jsonDecode(httpResponse.body);
          final remoteData = responseData['data'];

          // 1b. Ensure any pending form_approvals for this user/form are cleared
          try {
            await _supabase
                .from('form_approvals')
                .update({
                  'status': 'approved',
                  'action_at': DateTime.now().toUtc().toIso8601String(),
                  'updated_at': DateTime.now().toUtc().toIso8601String(),
                })
                .eq('form_submission_id', id)
                .eq('recipient_id', userId)
                .eq('status', 'pending');
          } catch (e) {
            _log('WARNING: Failed to update form_approvals in approveForm: $e');
          }

          final finalStatus =
              remoteData['status'] ?? AppConstants.statusApproved;

          // Reconstruct success model locally using ACTUAL backend status
          final form = FormSubmissionModel(
            id: id,
            residentId: remoteData['resident_id'] ?? '',
            templateId: remoteData['template_id'] ?? '',
            templateType: remoteData['template_type'] ?? '',
            unit: remoteData['unit'] ?? '',
            formData: remoteData['form_data'] ?? {},
            status: finalStatus,
            submittedBy: remoteData['submitted_by'] ?? '',
            createdAt: DateTime.parse(remoteData['created_at']),
            updatedAt: DateTime.parse(remoteData['updated_at']),
          );

          // 3. Try to create timeline entry (best effort)
          try {
            await _createTimelineEntry(
              residentId: form.residentId,
              entryType: 'form',
              formSubmissionId: form.id,
              formTemplateType: form.templateType,
              unit: form.unit,
              title: form.templateDisplayName,
              description:
                  'Form reviewed/approved by ${form.reviewerName ?? 'Unit Head'}',
              createdBy: userId,
            );
          } catch (e) {
            _log('WARNING: Could not fetch details for timeline entry: $e');
          }

          return form;
        } else {
          final body = httpResponse?.body;
          _log('Backend approval failed or unreachable: $body');
          if (lastError != null) _log('Last Error: $lastError');
          // Fall through to legacy direct update if backend fails
        }
      } catch (backendError) {
        _log('Backend attempt encountered exception: $backendError');
        // Fall through
      }

      // 2. Fallback: Perform direct update (legacy/emergency path)
      // This may be blocked by RLS for some users
      _log('Attempting direct status update as fallback');
      final response = await _supabase
          .from('form_submissions')
          .update({
            'status': AppConstants.statusApproved,
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .count(CountOption.exact);

      if (response.count == 0) {
        throw Exception(
            'Permission Error: You could not approve this form via direct or backend paths.');
      }

      // 2b. Cleanup appprovals
      try {
        await _supabase
            .from('form_approvals')
            .update({
              'status': 'approved',
              'action_at': DateTime.now().toUtc().toIso8601String(),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('form_submission_id', id)
            .eq('recipient_id', userId)
            .eq('status', 'pending');
      } catch (_) {}

      final form = FormSubmissionModel(
        id: id,
        residentId: '',
        templateId: '',
        templateType: '',
        unit: '',
        formData: {},
        status: AppConstants.statusApproved,
        submittedBy: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return form;
    } catch (e) {
      throw Exception('Failed to approve form: $e');
    }
  }

  /// Return form (unit head action)
  Future<FormSubmissionModel> returnForm({
    required String id,
    required String comment,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // 1. Primary path: Use backend workflow engine (Service Role)
      // This correctly handles parallel signatures, clearing approvers, and notifications.
      try {
        final resolvedUrl = await BackendConfig.getBackendUrl();
        final urlCandidates = <String>[
          '$resolvedUrl/return-form',
        ];

        http.Response? httpResponse;
        Object? lastError;
        for (final url in urlCandidates) {
          try {
            httpResponse = await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'form_id': id,
                'user_id': userId,
                'comment': comment,
              }),
            );
            if (httpResponse.statusCode == 200) break;
          } catch (e) {
            lastError = e;
          }
        }

        if (httpResponse != null && httpResponse.statusCode == 200) {
          _log('Backend return successful');
          return await getFormById(id); // Fetch the freshly updated form
        } else {
          final body = httpResponse?.body;
          _log('Backend return failed or unreachable: $body');
          if (lastError != null) _log('Last Error: $lastError');
          // Fall through to legacy direct update if backend fails
        }
      } catch (backendError) {
        _log('Backend attempt encountered exception: $backendError');
        // Fall through
      }

      // 2. Fallback: Perform direct update (legacy/emergency path)
      _log('Attempting direct status update for return as fallback...');
      final response = await _supabase
          .from('form_submissions')
          .update({
            'status': AppConstants.statusReturned,
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'review_comment': comment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .select()
          .single();

      // Attempt to clear approvers on fallback (may fail due to RLS)
      try {
        await _supabase
            .from('form_approvals')
            .update({
              'status': 'returned',
              'action_at': DateTime.now().toIso8601String(),
              'comment': comment,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('form_submission_id', id)
            .eq('status', 'pending');
      } catch (_) {}

      return FormSubmissionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to return form: $e');
    }
  }

  /// Create timeline entry (internal)
  Future<void> _createTimelineEntry({
    required String residentId,
    required String entryType,
    String? formSubmissionId,
    String? formTemplateType,
    required String unit,
    required String title,
    String? description,
    Map<String, dynamic>? metadata,
    required String createdBy,
  }) async {
    await _supabase.from('timeline_entries').insert({
      'resident_id': residentId,
      'entry_type': entryType,
      'form_submission_id': formSubmissionId,
      'form_template_type': formTemplateType,
      'unit': unit,
      'title': title,
      'description': description,
      'metadata': metadata,
      'created_by': createdBy,
    });
  }

  /// Get timeline entries for a resident
  Future<List<TimelineEntryModel>> getTimeline({
    required String residentId,
    String? unit,
    int page = 0,
    int pageSize = AppConstants.defaultPageSize,
  }) async {
    try {
      var query = _supabase.from('timeline_entries').select('''
            *,
            creator:profiles(full_name)
          ''').eq('resident_id', residentId);

      if (unit != null) {
        query = query.eq('unit', unit);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      return response.map((json) => TimelineEntryModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch timeline: $e');
    }
  }

  /// Get recent activity for dashboard
  Future<List<TimelineEntryModel>> getRecentActivity({
    String? unit,
    int limit = 10,
  }) async {
    try {
      _log('Fetching recent activity for unit: $unit');

      var query = _supabase.from('timeline_entries').select('''
            *,
            creator:profiles(full_name)
          ''');

      // logic: if unit is specific, show unit's events OR global/admin events?
      // For now, strict filtering as per request, but let's log it.
      if (unit != null && unit != 'all') {
        query = query.eq('unit', unit);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      _log('Fetched ${response.length} recent activities');
      return response.map((json) => TimelineEntryModel.fromJson(json)).toList();
    } catch (e) {
      // Log error but return empty list to avoid breaking dashboard
      _log('Failed to fetch recent activity: $e');
      return [];
    }
  }

  /// Subscribe to realtime timeline updates
  RealtimeChannel subscribeToTimeline(
    String residentId,
    void Function(TimelineEntryModel entry) onNewEntry,
  ) {
    return _supabase
        .channel('timeline:$residentId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'timeline_entries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'resident_id',
            value: residentId,
          ),
          callback: (payload) {
            final entry = TimelineEntryModel.fromJson(payload.newRecord);
            onNewEntry(entry);
          },
        )
        .subscribe();
  }

  /// Get list of users who can approve forms (Heads and Admins)
  Future<List<Map<String, dynamic>>> getApprovers() async {
    try {
      _log('Fetching approvers...');

      final response = await _supabase
          .from('profiles')
          .select('id, full_name, role, unit, email')
          // Fetch any role ending in "head" (head, center_head, social_head, etc.)
          .ilike('role', '%head')
          .eq('is_active', true)
          .order('role')
          .order('full_name');

      _log('Fetched ${response.length} approvers');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _log('Error fetching approvers: $e');
      throw Exception('Failed to fetch approvers: $e');
    }
  }

  /// Get forms for a specific resident
  Future<List<FormSubmissionModel>> getFormsByResident(
      String residentId) async {
    try {
      _log('Fetching forms for resident: $residentId');

      final response = await _supabase
          .from('form_submissions')
          .select('''
            *,
            resident:residents(first_name, last_name),
            submitter:profiles!form_submissions_submitted_by_fkey(full_name, signature_url),
            reviewer:profiles!form_submissions_reviewed_by_fkey(full_name, signature_url)
          ''')
          .eq('resident_id', residentId)
          .eq('is_archived', false)
          .order('created_at', ascending: false);

      _log('Fetched ${response.length} forms for resident');
      return response
          .map((json) => FormSubmissionModel.fromJson(json))
          .toList();
    } catch (e) {
      _log('Error fetching resident forms: $e');
      throw Exception('Failed to fetch resident forms: $e');
    }
  }

  /// Get forms for a specific resident and template type (for continuity)
  Future<List<FormSubmissionModel>> getFormsByResidentAndTemplate({
    required String residentId,
    required String templateType,
  }) async {
    try {
      _log('Fetching $templateType forms for resident: $residentId');

      final response = await _supabase
          .from('form_submissions')
          .select('''
            *,
            resident:residents(first_name, last_name),
            submitter:profiles!form_submissions_submitted_by_fkey(full_name, signature_url),
            reviewer:profiles!form_submissions_reviewed_by_fkey(full_name, signature_url)
          ''')
          .eq('resident_id', residentId)
          .eq('template_type', templateType)
          .eq('is_archived', false)
          .neq('status', 'draft')
          .order('created_at', ascending: false);

      return response
          .map((json) => FormSubmissionModel.fromJson(json))
          .toList();
    } catch (e) {
      _log('Error fetching resident forms by template: $e');
      return [];
    }
  }

  /// Get ALL forms for a resident (including archived) for case files screen
  Future<List<FormSubmissionModel>> getResidentCaseFiles({
    required String residentId,
    bool includeArchived = false,
  }) async {
    try {
      _log('Fetching case files for resident: $residentId (archived=$includeArchived)');

      var query = _supabase
          .from('form_submissions')
          .select('''
            *,
            resident:residents(first_name, last_name),
            submitter:profiles!form_submissions_submitted_by_fkey(full_name, signature_url),
            reviewer:profiles!form_submissions_reviewed_by_fkey(full_name, signature_url)
          ''')
          .eq('resident_id', residentId);

      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }

      final response = await query.order('created_at', ascending: false);

      return response
          .map((json) => FormSubmissionModel.fromJson(json))
          .toList();
    } catch (e) {
      _log('Error fetching case files: $e');
      throw Exception('Failed to fetch case files: $e');
    }
  }

  /// Get archived forms, optionally filtered by unit
  Future<List<FormSubmissionModel>> getArchivedForms({String? unit}) async {
    try {
      var query = _supabase
          .from('form_submissions')
          .select('''
            *,
            resident:residents!resident_id(first_name, last_name),
            submitter:profiles!form_submissions_submitted_by_fkey(full_name, signature_url),
            reviewer:profiles!form_submissions_reviewed_by_fkey(full_name, signature_url)
          ''')
          .eq('is_archived', true);

      if (unit != null) {
        query = query.eq('unit', unit);
      }

      final response = await query.order('archived_at', ascending: false);
      return response
          .map((json) => FormSubmissionModel.fromJson(json))
          .toList();
    } catch (e) {
      _log('Error getting archived forms: $e');
      return [];
    }
  }

  /// Archive a form (soft delete) via backend
  Future<void> archiveForm(String formId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final resolvedUrl = await BackendConfig.getBackendUrl();
      final backendUrl = '$resolvedUrl/archive-form';
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'form_id': formId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        _log('Form archived successfully: $formId');
        return;
      }

      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Archive failed');
    } catch (e) {
      _log('Error archiving form: $e');
      throw Exception('Failed to archive form: $e');
    }
  }

  /// Restore an archived form via backend (with direct Supabase fallback)
  Future<void> restoreForm(String formId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      try {
        final resolvedUrl = await BackendConfig.getBackendUrl();
        final backendUrl = '$resolvedUrl/restore-form';
        final response = await http
            .post(
              Uri.parse(backendUrl),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'form_id': formId, 'user_id': userId}),
            )
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          _log('Form restored via backend: $formId');
          return;
        }
      } catch (_) {
        _log('Backend restore failed, using direct fallback for $formId');
      }

      // Direct Supabase fallback
      await _supabase
          .from('form_submissions')
          .update({
            'is_archived': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', formId);
      _log('Form restored via direct update: $formId');
    } catch (e) {
      _log('Error restoring form: $e');
      throw Exception('Failed to restore form: $e');
    }
  }

  /// Permanently delete an archived form (hard delete — irreversible)
  Future<void> permanentDeleteForm(String formId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final resolvedUrl = await BackendConfig.getBackendUrl();
      final backendUrl = '$resolvedUrl/delete-form';
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'form_id': formId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        _log('Form permanently deleted via backend: $formId');
        _logAudit('Form Permanently Deleted',
            details: 'Permanent delete of archived form',
            resourceId: formId);
        return;
      }

      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Delete failed');
    } catch (e) {
      _log('Error permanently deleting form: $e');
      throw Exception('Failed to permanently delete form: $e');
    }
  }

  /// Notify approvers via Backend
  Future<void> _notifyApprovers({
    required String unit,
    required String formId,
    required String formTitle,
    required String submitterName,
    String? recipientId,
  }) async {
    final resolvedUrl = await BackendConfig.getBackendUrl();
    final backendUrl = '$resolvedUrl/notify-approvers';
    try {
      final response = await http
          .post(
            Uri.parse(backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'unit': unit,
              'form_id': formId,
              'form_title': formTitle,
              'submitter_name': submitterName,
              'recipient_id': recipientId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception(
            'Backend returned ${response.statusCode}: ${response.body}');
      }
      _log('Notification request sent successfully');
    } catch (e) {
      throw Exception('Failed to call notification API: $e');
    }
  }

  /// Upload an external party's signature image and return the public URL.
  /// Stored under: signatures/external/{formId}/{fieldName}.png
  Future<String> uploadExternalSignature({
    required String formId,
    required String fieldName,
    required Uint8List bytes,
  }) async {
    try {
      final path = 'external/$formId/$fieldName.png';
      _log('Uploading external signature: $path (${bytes.length} bytes)');

      await _supabase.storage
          .from(SupabaseConfig.signaturesBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );

      final url = _supabase.storage
          .from(SupabaseConfig.signaturesBucket)
          .getPublicUrl(path);

      _log('External signature uploaded: $url');
      return url;
    } catch (e) {
      _log('Error uploading external signature: $e');
      throw Exception('Failed to upload signature: $e');
    }
  }
}
