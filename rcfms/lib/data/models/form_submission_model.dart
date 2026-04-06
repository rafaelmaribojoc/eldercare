import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Form submission model representing a submitted form
class FormSubmissionModel extends Equatable {
  final String id;
  final String residentId;
  final String? residentName;
  final String templateId;
  final String templateType;
  final String unit;
  final Map<String, dynamic> formData;
  final String status;
  final String submittedBy;
  final String? submitterName;
  final String? submitterSignatureUrl;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final String? reviewerName;
  final String? reviewerSignatureUrl;
  final DateTime? reviewedAt;
  final String? reviewComment;
  final int version;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isArchived;
  final String? archivedBy;
  final DateTime? archivedAt;

  const FormSubmissionModel({
    required this.id,
    required this.residentId,
    this.residentName,
    required this.templateId,
    required this.templateType,
    required this.unit,
    required this.formData,
    required this.status,
    required this.submittedBy,
    this.submitterName,
    this.submitterSignatureUrl,
    this.submittedAt,
    this.reviewedBy,
    this.reviewerName,
    this.reviewerSignatureUrl,
    this.reviewedAt,
    this.reviewComment,
    this.version = 1,
    required this.createdAt,
    this.updatedAt,
    this.isArchived = false,
    this.archivedBy,
    this.archivedAt,
  });

  /// Check if form is in draft status
  bool get isDraft => status == AppConstants.statusDraft;

  /// Check if form is submitted and awaiting review
  bool get isPendingReview =>
      status == AppConstants.statusPendingReview ||
      status == AppConstants.statusPendingSupervisor ||
      status == AppConstants.statusPendingMultiApproval ||
      status == AppConstants.statusPendingHeadApproval ||
      status == AppConstants.statusPendingDoctorReview ||
      status == AppConstants.statusPendingSocialWorker ||
      status == AppConstants.statusPendingMedicalReview ||
      status == AppConstants.statusPendingFinalApproval;

  /// Check if form is approved
  bool get isApproved => status == AppConstants.statusApproved;

  /// Check if form was returned
  bool get isReturned => status == AppConstants.statusReturned;

  /// Check if form can be edited
  bool get canEdit => isDraft || isReturned;

  /// Get status color
  Color get statusColor {
    switch (status) {
      case AppConstants.statusDraft:
        return AppColors.statusDraft;
      case AppConstants.statusSubmitted:
      case AppConstants.statusPendingReview:
      case AppConstants.statusPendingSupervisor:
      case AppConstants.statusPendingHeadApproval:
      case AppConstants.statusPendingFinalApproval:
      case AppConstants.statusPendingSocialWorker:
        return AppColors.statusPendingReview;
      case AppConstants.statusPendingMultiApproval:
        return AppColors.statusPendingReview;
      case AppConstants.statusPendingMedicalReview:
      case AppConstants.statusPendingDoctorReview:
        return AppColors.statusPendingReview;
      case AppConstants.statusApproved:
        return AppColors.statusApproved;
      case AppConstants.statusReturned:
        return AppColors.statusReturned;
      default:
        return AppColors.statusDraft;
    }
  }

  /// Get status display text
  String get statusDisplayText {
    switch (status) {
      case AppConstants.statusDraft:
        return 'Draft';
      case AppConstants.statusSubmitted:
        return 'For Signing';
      case AppConstants.statusPendingReview:
        if (templateType == 'admission_slip' ||
            templateType == 'discharge_slip') {
          return 'Pending - Medical Staff';
        }
        return 'Pending Review';
      case AppConstants.statusPendingSupervisor:
        return 'Pending - Supervisor';
      case AppConstants.statusPendingMultiApproval:
        return 'Pending - Multi-Unit Approval';
      case AppConstants.statusPendingHeadApproval:
        return 'Pending - Center Head';
      case 'pending_doctor_review':
        return 'Pending - Doctor';
      case 'pending_social_worker':
        return 'Pending - Social Worker';
      case AppConstants.statusPendingFinalApproval:
        return 'Pending - Center Head';
      case AppConstants.statusApproved:
        return 'Approved';
      case AppConstants.statusReturned:
        return 'Returned';
      default:
        return 'Unknown';
    }
  }

  /// Get template display name
  String get templateDisplayName {
    switch (templateType) {
      case 'intake_form':
        return 'Intake Form';
      case 'family_conference_log':
        return 'Family Conference Log';
      case 'daily_vitals':
        return 'Daily Vitals Sheet';
      case 'incident_report':
        return 'Incident Report';
      case 'medical_abstract':
        return 'Medical Abstract';
      case 'moca_p_scoring':
        return 'MOCA-P Scoring Sheet';
      case 'behavior_log':
        return 'Behavior Log';
      case 'therapy_session_notes':
        return 'Therapy Session Notes';
      case 'daily_activity_log':
        return 'Daily Activity Log';
      default:
        return templateType.replaceAll('_', ' ').split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
    }
  }

  /// Get unit color
  Color get unitColor {
    switch (unit) {
      case AppConstants.unitSocial:
        return AppColors.unitSocial;
      case AppConstants.unitMedical:
        return AppColors.unitMedical;
      case AppConstants.unitPsych:
        return AppColors.unitPsych;
      case AppConstants.unitRehab:
        return AppColors.unitRehab;
      case AppConstants.unitHomelife:
        return AppColors.unitHomelife;
      default:
        return AppColors.primary;
    }
  }

  factory FormSubmissionModel.fromJson(Map<String, dynamic> json) {
    return FormSubmissionModel(
      id: json['id'] as String,
      residentId: json['resident_id'] as String? ?? '',
      residentName: json['resident']?['first_name'] != null
          ? '${json['resident']['first_name']} ${json['resident']['last_name']}'
          : json['resident_name'] as String?,
      templateId:
          json['template_id'] as String? ?? json['template_type'] as String,
      templateType: json['template_type'] as String,
      unit: json['unit'] as String,
      formData: Map<String, dynamic>.from(json['form_data'] as Map),
      status: json['status'] as String,
      submittedBy: json['submitted_by'] as String,
      submitterName: json['submitter']?['full_name'] as String? ??
          json['submitter_name'] as String?,
      submitterSignatureUrl: json['submitter']?['signature_url'] as String? ??
          json['submitter_signature_url'] as String?,
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewerName: json['reviewer']?['full_name'] as String? ??
          json['reviewer_name'] as String?,
      reviewerSignatureUrl: json['reviewer']?['signature_url'] as String? ??
          json['reviewer_signature_url'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewComment: json['review_comment'] as String?,
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isArchived: json['is_archived'] as bool? ?? false,
      archivedBy: json['archived_by'] as String?,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resident_id': residentId,
      'template_id': templateId,
      'template_type': templateType,
      'unit': unit,
      'form_data': formData,
      'status': status,
      'submitted_by': submittedBy,
      'submitted_at': submittedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'review_comment': reviewComment,
      'version': version,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_archived': isArchived,
      'archived_by': archivedBy,
      'archived_at': archivedAt?.toIso8601String(),
    };
  }

  FormSubmissionModel copyWith({
    String? id,
    String? residentId,
    String? residentName,
    String? templateId,
    String? templateType,
    String? unit,
    Map<String, dynamic>? formData,
    String? status,
    String? submittedBy,
    String? submitterName,
    String? submitterSignatureUrl,
    DateTime? submittedAt,
    String? reviewedBy,
    String? reviewerName,
    String? reviewerSignatureUrl,
    DateTime? reviewedAt,
    String? reviewComment,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    String? archivedBy,
    DateTime? archivedAt,
  }) {
    return FormSubmissionModel(
      id: id ?? this.id,
      residentId: residentId ?? this.residentId,
      residentName: residentName ?? this.residentName,
      templateId: templateId ?? this.templateId,
      templateType: templateType ?? this.templateType,
      unit: unit ?? this.unit,
      formData: formData ?? this.formData,
      status: status ?? this.status,
      submittedBy: submittedBy ?? this.submittedBy,
      submitterName: submitterName ?? this.submitterName,
      submitterSignatureUrl:
          submitterSignatureUrl ?? this.submitterSignatureUrl,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewerSignatureUrl: reviewerSignatureUrl ?? this.reviewerSignatureUrl,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewComment: reviewComment ?? this.reviewComment,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      archivedBy: archivedBy ?? this.archivedBy,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        residentId,
        residentName,
        templateId,
        templateType,
        unit,
        formData,
        status,
        submittedBy,
        submitterName,
        submitterSignatureUrl,
        submittedAt,
        reviewedBy,
        reviewerName,
        reviewerSignatureUrl,
        reviewedAt,
        reviewComment,
        version,
        createdAt,
        updatedAt,
        isArchived,
        archivedBy,
        archivedAt,
      ];
}
