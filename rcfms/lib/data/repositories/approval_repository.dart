import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/form_approval_model.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/supabase_config.dart';
import '../../core/utils/backend_config.dart';
import 'form_repository.dart';

/// Helper function to convert empty strings to null for UUID fields
String? _nullIfEmpty(String? value) => (value?.isEmpty ?? true) ? null : value;

/// Repository for managing form approvals and notifications
class ApprovalRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> _freezeSignatureToSubmissionStorage({
    required String submissionId,
    required String fieldName,
    required String userId,
    required String signatureUrl,
  }) async {
    try {
      // Prefer Storage download because the signatures bucket may be private.
      // Canonical signature path is '$userId/signature.png' (see uploadSignature).
      final bytes = await _supabase.storage
          .from(SupabaseConfig.signaturesBucket)
          .download('$userId/signature.png');
      if (bytes.isEmpty) return null;

      final ts = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '$userId/frozen_signatures/$submissionId/$fieldName-$ts.png';

      await _supabase.storage
          .from(SupabaseConfig.signaturesBucket)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: false,
            ),
          );

      return _supabase.storage
          .from(SupabaseConfig.signaturesBucket)
          .getPublicUrl(filePath);
    } catch (e) {
      debugPrint('[ApprovalRepo] Failed to freeze signature: $e');
      return null;
    }
  }

  /// Helper to fetch signature with backend fallback
  Future<String?> _fetchSignatureWithFallback(String userId) async {
    try {
      // 1. Try local RLS fetch
      final profile = await _supabase
          .from('profiles')
          .select('signature_url')
          .eq('id', userId)
          .single();

      final sig = profile['signature_url'] as String?;
      if (sig != null && sig.isNotEmpty) return sig;

      // 2. If empty/null, try backend (Service Role)
      throw Exception('Signature empty locally');
    } catch (e) {
      debugPrint(
          '[ApprovalRepo] Local signature fetch failed/empty: $e. Trying backend...');
      try {
        final response = await http.get(
          Uri.parse('http://127.0.0.1:5000/api/get-signature?user_id=$userId'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final backendSig = data['signature_url'] as String?;
          debugPrint(
              '[ApprovalRepo] Backend returned signature: ${backendSig != null ? "YES" : "NO"}');
          return backendSig;
        }
      } catch (backendErr) {
        debugPrint(
            '[ApprovalRepo] Backend signature fetch failed: $backendErr');
      }
    }
    return null;
  }

  /// Advance form status via the backend workflow engine.
  /// Returns the new status string, or 'approved' as fallback.
  Future<String> _advanceFormStatusViaBackend(
      String formId, String userId) async {
    // 1. Fetch form details to check for special workflow rules (e.g. Admission Slip)
    String? templateType;
    try {
      final form = await _supabase
          .from('form_submissions')
          .select('template_type')
          .eq('id', formId)
          .single();
      templateType = form['template_type'] as String?;
    } catch (e) {
      debugPrint('[ApprovalRepo] Failed to fetch form template type: $e');
    }

    String? resultStatus;

    // 2. Try backend workflow engine
    try {
      final resolvedUrl = await BackendConfig.getBackendUrl();
      final backendUrl = '$resolvedUrl/approve-form';
      final httpResponse = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'form_id': formId, 'user_id': userId}),
      );

      if (httpResponse.statusCode == 200) {
        final responseData = jsonDecode(httpResponse.body);
        resultStatus = responseData['data']?['status'] as String?;
        debugPrint('[ApprovalRepo] Backend advanced status to: $resultStatus');
      } else {
        debugPrint(
            '[ApprovalRepo] Backend approve failed: ${httpResponse.body}');
      }
    } catch (e) {
      debugPrint('[ApprovalRepo] Backend call failed: $e');
    }

    // 3. Apply manual overrides and fallbacks for specific forms (e.g. Admission Slip)
    // This is CRITICAL if the backend is down or doesn't have the latest workflow logic.
    final bool isHomelifeWorkflow = templateType != null &&
        (templateType.startsWith('inventory_') ||
            templateType == 'progress_notes');

    if (templateType == 'admission_slip' ||
        templateType == 'discharge_slip' ||
        isHomelifeWorkflow) {
      try {
        final profile = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();
        final userRole = profile['role'] as String;

        if (userRole != AppConstants.roleCenterHead) {
          // If NOT Center Head, force transition to next approval step
          String nextStatusForOverride =
              AppConstants.statusPendingFinalApproval;
          if (isHomelifeWorkflow) {
            nextStatusForOverride = AppConstants.statusPendingHeadApproval;
          }

          debugPrint(
              '[ApprovalRepo] Forcing $templateType to $nextStatusForOverride (signer: $userRole)');
          await _supabase.from('form_submissions').update({
            'status': nextStatusForOverride,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', formId);

          // Ensure auto-routing to Center Head
          await _routeToCenterHead(formId);
          return nextStatusForOverride;
        } else {
          // If Center Head, finish the form
          debugPrint('[ApprovalRepo] Center Head approved $templateType');
          await _supabase.from('form_submissions').update({
            'status': AppConstants.statusApproved,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', formId);
          return AppConstants.statusApproved;
        }
      } catch (e) {
        debugPrint('[ApprovalRepo] Error in manual status override: $e');
      }
    }

    // 4. Default Fallback: if no custom logic and backend failed, default to 'approved'
    if (resultStatus == null) {
      debugPrint(
          '[ApprovalRepo] Falling back to direct status update: approved');
      await _supabase.from('form_submissions').update({
        'status': AppConstants.statusApproved,
        'reviewed_by': userId,
        'reviewed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', formId);
      return AppConstants.statusApproved;
    }

    return resultStatus;
  }

  /// Helper to auto-route a form to the center head if needed
  Future<void> _routeToCenterHead(String formId) async {
    try {
      final centerHeadProfile = await _supabase
          .from('profiles')
          .select('id, full_name')
          .eq('role', 'center_head')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (centerHeadProfile != null) {
        final centerHeadId = centerHeadProfile['id'] as String;
        final centerHeadName = centerHeadProfile['full_name'] as String;

        // Check for existing pending request to avoid duplicates
        final existing = await _supabase
            .from('form_approvals')
            .select('id')
            .eq('form_submission_id', formId)
            .eq('recipient_id', centerHeadId)
            .eq('status', 'pending')
            .maybeSingle();

        if (existing == null) {
          await createApprovalRequest(
            formId: formId,
            recipientId: centerHeadId,
            recipientName: centerHeadName,
            signatureFieldName: 'center_head_name',
          );
          debugPrint('[ApprovalRepo] Auto-routed form $formId to Center Head');
        }
      }
    } catch (e) {
      debugPrint('[ApprovalRepo] Failed to route to Center Head: $e');
    }
  }

  // ============================================================================
  // APPROVAL REQUESTS
  // ============================================================================

  /// Get all pending approvals for the current user
  Future<List<FormApprovalModel>> getPendingApprovals() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('form_approvals')
        .select()
        .eq('recipient_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FormApprovalModel.fromJson(json))
        .toList();
  }

  /// Get all approvals sent by the current user
  Future<List<FormApprovalModel>> getSentApprovals() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('form_approvals')
        .select()
        .eq('sender_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FormApprovalModel.fromJson(json))
        .toList();
  }

  /// Get approvals for a specific form
  Future<List<FormApprovalModel>> getFormApprovals(String formId) async {
    final response = await _supabase
        .from('form_approvals')
        .select()
        .eq('form_submission_id', formId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => FormApprovalModel.fromJson(json))
        .toList();
  }

  /// Create an approval request
  Future<FormApprovalModel> createApprovalRequest({
    required String formId,
    required String recipientId,
    required String recipientName,
    String? signatureFieldName,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Validate required UUID fields - convert empty strings to null and check
    final safeFormId = _nullIfEmpty(formId);
    final safeRecipientId = _nullIfEmpty(recipientId);

    if (safeFormId == null) {
      throw Exception('Invalid form ID: cannot be empty');
    }
    if (safeRecipientId == null) {
      throw Exception('Invalid recipient ID: cannot be empty');
    }

    // Get sender's name
    final senderProfile = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .single();

    final senderName = senderProfile['full_name'] as String;

    // Create approval request
    final response = await _supabase
        .from('form_approvals')
        .insert({
          'form_submission_id': safeFormId,
          'sender_id': userId,
          'sender_name': senderName,
          'recipient_id': safeRecipientId,
          'recipient_name': recipientName,
          'signature_field_name': _nullIfEmpty(signatureFieldName),
          'status': 'pending',
        })
        .select()
        .single();

    // NOTE: Form status is already set by formRepository.submitForm() with the
    // correct initial status from the workflow config. Do NOT override it here.

    // Create notification for recipient
    await createNotification(
      userId: recipientId,
      type: 'approval_request',
      title: 'New Form Approval Request',
      message: '$senderName has submitted a form for your review.',
      formSubmissionId: formId,
      formApprovalId: response['id'] as String,
    );

    return FormApprovalModel.fromJson(response);
  }

  /// Approve a form
  Future<void> approveForm({
    required String approvalId,
    String? signatureUrl,
    String? comment,
  }) async {
    final approval = await _supabase
        .from('form_approvals')
        .select()
        .eq('id', approvalId)
        .single();

    // Update approval
    await _supabase.from('form_approvals').update({
      'status': 'approved',
      'action_at': DateTime.now().toIso8601String(),
      'signature_url': signatureUrl,
      'signature_applied':
          signatureUrl != null || approval['signature_field_name'] != null,
      'comment': comment,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', approvalId);

    // Update form
    final formId = approval['form_submission_id'] as String;
    final recipientId = approval['recipient_id'] as String;
    final recipientName = approval['recipient_name'] as String;

    // Determine next status using the backend workflow engine
    final newStatus = await _advanceFormStatusViaBackend(formId, recipientId);
    debugPrint('[ApprovalRepo] Form $formId advanced to status: $newStatus');

    // If signature field is specified, add to form_signatures
    final signatureFieldName = approval['signature_field_name'] as String?;
    if (signatureFieldName != null && signatureUrl != null) {
      try {
        await _supabase.from('form_signatures').upsert({
          'form_submission_id': formId,
          'signer_id': recipientId,
          'signer_name': recipientName,
          'field_name': signatureFieldName,
          'signature_url': signatureUrl,
          'signed_at': DateTime.now().toIso8601String(),
          'is_auto_applied': false,
        }, onConflict: 'form_submission_id, field_name');
      } catch (e) {
        debugPrint(
            'WARNING: Failed to save signature (likely RLS), but proceeding with approval: $e');
      }
    }

    // Notify sender
    final senderId = approval['sender_id'] as String;
    await createNotification(
      userId: senderId,
      type: 'form_approved',
      title: 'Form Approved',
      message: '$recipientName has approved your form submission.',
      formSubmissionId: formId,
      formApprovalId: approvalId,
    );
  }

  /// Acknowledge a form (without signature)
  Future<void> acknowledgeForm({
    required String approvalId,
    String? comment,
  }) async {
    final approval = await _supabase
        .from('form_approvals')
        .select()
        .eq('id', approvalId)
        .single();

    // Update approval
    await _supabase.from('form_approvals').update({
      'status': 'acknowledged',
      'action_at': DateTime.now().toIso8601String(),
      'comment': comment,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', approvalId);

    // Notify sender
    final senderId = approval['sender_id'] as String;
    final recipientName = approval['recipient_name'] as String;
    final formId = approval['form_submission_id'] as String;

    await createNotification(
      userId: senderId,
      type: 'form_acknowledged',
      title: 'Form Acknowledged',
      message: '$recipientName has acknowledged your form submission.',
      formSubmissionId: formId,
      formApprovalId: approvalId,
    );
  }

  /// Return a form for revisions
  Future<void> returnForm({
    required String approvalId,
    required String comment,
  }) async {
    final approval = await _supabase
        .from('form_approvals')
        .select()
        .eq('id', approvalId)
        .single();

    final formId = approval['form_submission_id'] as String;

    // Delegate the actual return logic to FormRepository
    // This ensures we hit the backend '/return-form' endpoint
    // which handles clearing ALL parallel approvals and signatures properly.
    final formRepo = FormRepository();
    await formRepo.returnForm(id: formId, comment: comment);
  }

  // ============================================================================
  // NOTIFICATIONS
  // ============================================================================

  /// Get all notifications for the current user
  Future<List<NotificationModel>> getNotifications({int limit = 50}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((json) => NotificationModel.fromJson(json))
        .toList();
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return 0;

    final response = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _supabase.from('notifications').update({
      'is_read': true,
      'read_at': DateTime.now().toIso8601String(),
    }).eq('id', notificationId);
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from('notifications')
        .update({
          'is_read': true,
          'read_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  /// Create a notification
  Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? formSubmissionId,
    String? formApprovalId,
    Map<String, dynamic>? metadata,
  }) async {
    // Convert empty strings to null for UUID fields
    final safeFormSubmissionId =
        (formSubmissionId?.isEmpty ?? true) ? null : formSubmissionId;
    final safeFormApprovalId =
        (formApprovalId?.isEmpty ?? true) ? null : formApprovalId;
    final safeUserId = userId.isEmpty ? null : userId;

    if (safeUserId == null) {
      debugPrint('Cannot create notification: userId is empty');
      return;
    }

    try {
      debugPrint('Creating notification for user: $safeUserId, type: $type');
      await _supabase.from('notifications').insert({
        'user_id': safeUserId,
        'type': type,
        'title': title,
        'message': message,
        'form_submission_id': safeFormSubmissionId,
        'form_approval_id': safeFormApprovalId,
        'metadata': metadata ?? {},
      });
      debugPrint('Notification created successfully for user: $safeUserId');
    } catch (e) {
      debugPrint('ERROR creating notification: $e');
      // Do not rethrow - notification failure should not block the main action
      // rethrow;
    }
  }

  /// Subscribe to realtime notification updates
  RealtimeChannel subscribeToNotifications({
    required void Function() onUpdate,
  }) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _supabase
        .channel('user_notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
                '[ApprovalRepo] Realtime notification update received: ${payload.eventType}');
            onUpdate();
          },
        )
        .subscribe();
  }

  // ============================================================================
  // USERS (for recipient selection)
  // ============================================================================

  /// Get users that can be selected as recipients for a form.
  /// When [serviceUnit] is provided, only shows the matching unit head + center head.
  Future<List<UserModel>> getApprovalRecipients({
    String? excludeUserId,
    String? serviceUnit,
  }) async {
    // Build the list of roles to fetch based on service unit
    List<String> roles;
    if (serviceUnit != null && serviceUnit.isNotEmpty) {
      // Map service unit slug to the specific head role
      final unitHeadRole = '${serviceUnit}_head'; // e.g. 'social_head'
      roles = [
        unitHeadRole,
        'center_head',
        'head', // legacy generic head role
      ];
    } else {
      // Fallback: fetch all heads
      roles = [
        'head',
        'center_head',
        'social_head',
        'medical_head',
        'psych_head',
        'rehab_head',
        'homelife_head',
        'nutrition_head',
      ];
    }

    var query = _supabase
        .from('profiles')
        .select()
        .eq('is_active', true)
        .inFilter('role', roles);

    final response = await query.order('full_name');

    var users = (response as List)
        .map((json) => UserModel.fromJson(json))
        .where((user) => excludeUserId == null || user.id != excludeUserId);

    // If filtering by unit, also filter generic 'head' role to only matching unit
    if (serviceUnit != null && serviceUnit.isNotEmpty) {
      users = users.where((user) =>
          user.role == 'center_head' ||
          user.role == '${serviceUnit}_head' ||
          (user.role == 'head' && user.unit == serviceUnit));
    }

    return users.toList();
  }

  /// Get users in a specific unit
  Future<List<UserModel>> getUsersByUnit(String unit) async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('is_active', true)
        .eq('unit', unit)
        .order('full_name');

    return (response as List).map((json) => UserModel.fromJson(json)).toList();
  }

  // ============================================================================
  // SIGNATURES
  // ============================================================================

  /// Auto-apply creator's signature to "Prepared By" field
  Future<void> applyPreparedBySignature({
    required String formId,
    required String userId,
    required String userName,
    required String signatureUrl,
    String? title,
    String? employeeId,
  }) async {
    await _supabase.from('form_signatures').upsert({
      'form_submission_id': formId,
      'signer_id': userId,
      'signer_name': userName,
      'signer_title': title,
      'signer_employee_id': employeeId,
      'field_name': 'prepared_by',
      'field_label': 'Prepared By',
      'signature_url': signatureUrl,
      'is_auto_applied': true,
    }, onConflict: 'form_submission_id, field_name');

    // Also update the form submission
    await _supabase.from('form_submissions').update({
      'prepared_by_id': userId,
      'prepared_by_name': userName,
      'prepared_by_signature_url': signatureUrl,
      'prepared_at': DateTime.now().toIso8601String(),
    }).eq('id', formId);
  }

  /// Get all signatures for a form
  Future<List<Map<String, dynamic>>> getFormSignatures(String formId) async {
    final response = await _supabase
        .from('form_signatures')
        .select()
        .eq('form_submission_id', formId)
        .order('signed_at');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get pending approval for a specific form and recipient
  Future<FormApprovalModel?> getPendingApprovalForForm(String formId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('form_approvals')
          .select()
          .eq('form_submission_id', formId)
          .eq('recipient_id', userId)
          .eq('status', 'pending')
          .maybeSingle();

      if (response == null) return null;
      return FormApprovalModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting pending approval: $e');
      return null;
    }
  }

  /// Check if user can take action on a form
  Future<Map<String, dynamic>> getFormActionInfo(String formId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return {'canAct': false, 'actionType': null, 'approval': null};
    }

    // Check if there's a pending approval for this user
    final approval = await getPendingApprovalForForm(formId);
    if (approval == null) {
      return {'canAct': false, 'actionType': null, 'approval': null};
    }

    // Determine action type based on signature field
    final actionType = approval.signatureFieldName != null
        ? 'approve' // Requires signature
        : 'acknowledge'; // Just acknowledge

    return {
      'canAct': true,
      'actionType': actionType,
      'approval': approval,
      'signatureFieldName': approval.signatureFieldName,
    };
  }

  /// Approve form with auto-signature
  /// Returns a map with the signature info for immediate UI update
  Future<Map<String, dynamic>> approveFormWithAutoSignature({
    required String approvalId,
    String? comment,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get user's signature URL from profile (with fallback)
    final signatureUrl = await _fetchSignatureWithFallback(userId);

    // Fetch name separately (usually safe)
    final profile = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .single();

    final userName = profile['full_name'] as String;
    final userTitle = null;
    final employeeId = null;

    if (signatureUrl == null || signatureUrl.isEmpty) {
      throw Exception(
          'You must set up your digital signature before approving forms. Please go to Settings > Profile to add your signature.');
    }

    // Get approval details
    final approval = await _supabase
        .from('form_approvals')
        .select()
        .eq('id', approvalId)
        .single();

    final formId = approval['form_submission_id'] as String;
    final signatureFieldName = approval['signature_field_name'] as String?;

    final fieldNameForFreeze = signatureFieldName ?? 'approved_by';
    final frozenSignatureUrl = await _freezeSignatureToSubmissionStorage(
          submissionId: formId,
          fieldName: fieldNameForFreeze,
          userId: userId,
          signatureUrl: signatureUrl,
        ) ??
        signatureUrl;

    // Update approval
    await _supabase.from('form_approvals').update({
      'status': 'approved',
      'action_at': DateTime.now().toIso8601String(),
      'signature_url': frozenSignatureUrl,
      'signature_applied': true,
      'comment': comment,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', approvalId);

    // Advance form status (handles P2/P3/P4 transitions and Admission Slip forcing)
    String newStatus = await _advanceFormStatusViaBackend(formId, userId);

    // Add to form_signatures table
    final fieldName = signatureFieldName ?? 'approved_by';
    final fieldLabel = signatureFieldName != null
        ? signatureFieldName
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) =>
                w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ')
        : 'Approved By';

    await _supabase.from('form_signatures').upsert({
      'form_submission_id': formId,
      'signer_id': userId,
      'signer_name': userName,
      'signer_title': userTitle,
      'signer_employee_id': employeeId,
      'field_name': fieldName,
      'field_label': fieldLabel,
      'signature_url': frozenSignatureUrl,
      'signed_at': DateTime.now().toIso8601String(),
      'is_auto_applied': true,
    }, onConflict: 'form_submission_id, field_name');

    // Notify sender
    final senderId = approval['sender_id'] as String;
    await createNotification(
      userId: senderId,
      type: 'form_approved',
      title: 'Form Approved',
      message: '$userName has approved your form submission.',
      formSubmissionId: formId,
      formApprovalId: approvalId,
    );

    // Return signature info for immediate UI update
    return {
      'signerId': userId,
      'signerName': userName,
      'signatureUrl': frozenSignatureUrl,
      'signedAt': DateTime.now(),
      'fieldName': fieldName,
      'fieldLabel': fieldLabel,
      'newStatus': newStatus,
    };
  }

  /// Note/Acknowledge form with auto-signature (for forms that need "Noted By")
  /// Returns a map with the signature info for immediate UI update
  Future<Map<String, dynamic>> noteFormWithAutoSignature({
    required String approvalId,
    String? comment,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get user's signature URL from profile (with fallback)
    final signatureUrl = await _fetchSignatureWithFallback(userId);

    // Fetch name separately (usually safe)
    final profile = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .single();

    final userName = profile['full_name'] as String;
    final userTitle = null;
    final employeeId = null;

    if (signatureUrl == null || signatureUrl.isEmpty) {
      debugPrint(
          '[ApprovalRepo] Signature validation failed. URL: $signatureUrl');
      throw Exception(
          'You must set up your digital signature before noting forms. Please go to Settings > Profile to add your signature.');
    }

    // Get approval details
    final approval = await _supabase
        .from('form_approvals')
        .select()
        .eq('id', approvalId)
        .single();

    final formId = approval['form_submission_id'] as String;
    final signatureFieldName = approval['signature_field_name'] as String?;
    final now = DateTime.now();

    final fieldNameForFreeze = signatureFieldName ?? 'noted_by';
    final frozenSignatureUrl = await _freezeSignatureToSubmissionStorage(
          submissionId: formId,
          fieldName: fieldNameForFreeze,
          userId: userId,
          signatureUrl: signatureUrl,
        ) ??
        signatureUrl;

    // Update approval - use 'approved' status (database constraint doesn't allow 'noted')
    await _supabase.from('form_approvals').update({
      'status': 'approved',
      'action_at': now.toIso8601String(),
      'signature_url': frozenSignatureUrl,
      'signature_applied': true,
      'comment': comment,
      'updated_at': now.toIso8601String(),
    }).eq('id', approvalId);

    // Advance form status via backend workflow engine (handles P2/P3/P4 transitions)
    final newStatus = await _advanceFormStatusViaBackend(formId, userId);

    // Add to form_signatures table
    final fieldName = signatureFieldName ?? 'noted_by';
    final fieldLabel = signatureFieldName != null
        ? signatureFieldName
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) =>
                w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ')
        : 'Noted By';

    await _supabase.from('form_signatures').upsert({
      'form_submission_id': formId,
      'signer_id': userId,
      'signer_name': userName,
      'signer_title': userTitle,
      'signer_employee_id': employeeId,
      'field_name': fieldName,
      'field_label': fieldLabel,
      'signature_url': frozenSignatureUrl,
      'signed_at': now.toIso8601String(),
      'is_auto_applied': true,
    }, onConflict: 'form_submission_id, field_name');

    // Notify sender - use 'form_approved' since 'form_noted' is not in allowed types
    final senderId = approval['sender_id'] as String;
    await createNotification(
      userId: senderId,
      type: 'form_approved',
      title: 'Form Noted',
      message: '$userName has noted your form submission.',
      formSubmissionId: formId,
      formApprovalId: approvalId,
    );

    // Return signature info for immediate UI update
    return {
      'signerId': userId,
      'signerName': userName,
      'signatureUrl': signatureUrl,
      'signedAt': DateTime.now(),
      'fieldName': fieldName,
      'fieldLabel': fieldLabel,
      'newStatus': newStatus,
    };
  }

  /// Acknowledge form without signature
  /// Returns a map with the acknowledger info for immediate UI update
  Future<Map<String, dynamic>> acknowledgeFormSimple({
    required String approvalId,
    String? comment,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Get user's name from profile
    final profile = await _supabase
        .from('profiles')
        .select('full_name')
        .eq('id', userId)
        .single();

    final userName = profile['full_name'] as String;
    final now = DateTime.now();

    // Get approval details
    final approval = await _supabase
        .from('form_approvals')
        .select()
        .eq('id', approvalId)
        .single();

    final formId = approval['form_submission_id'] as String;

    // Update approval
    await _supabase.from('form_approvals').update({
      'status': 'acknowledged',
      'action_at': now.toIso8601String(),
      'comment': comment,
      'updated_at': now.toIso8601String(),
    }).eq('id', approvalId);

    // Advance form status via backend workflow engine (handles P2/P3/P4 transitions)
    await _advanceFormStatusViaBackend(formId, userId);

    // Notify sender
    final senderId = approval['sender_id'] as String;
    await createNotification(
      userId: senderId,
      type: 'form_acknowledged',
      title: 'Form Acknowledged',
      message: '$userName has acknowledged your form submission.',
      formSubmissionId: formId,
      formApprovalId: approvalId,
    );

    // Return info for immediate UI update
    return {
      'acknowledgedBy': userId,
      'acknowledgerName': userName,
      'acknowledgedAt': now,
    };
  }

  /// Get current user's profile with signature
  Future<UserModel?> getCurrentUserProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response =
          await _supabase.from('profiles').select().eq('id', userId).single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }
}
