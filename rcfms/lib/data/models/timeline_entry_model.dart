import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Timeline entry model for resident's digital timeline
class TimelineEntryModel extends Equatable {
  final String id;
  final String residentId;
  final String entryType; // 'form', 'note', 'alert', 'milestone'
  final String? formSubmissionId;
  final String? formTemplateType;
  final String unit;
  final String title;
  final String? description;
  final Map<String, dynamic>? metadata;
  final String createdBy;
  final String? creatorName;
  final DateTime createdAt;

  const TimelineEntryModel({
    required this.id,
    required this.residentId,
    required this.entryType,
    this.formSubmissionId,
    this.formTemplateType,
    required this.unit,
    required this.title,
    this.description,
    this.metadata,
    required this.createdBy,
    this.creatorName,
    required this.createdAt,
  });

  /// Get icon based on entry type
  IconData get icon {
    switch (entryType) {
      case 'form':
        return Icons.description;
      case 'note':
        return Icons.note_alt;
      case 'alert':
        return Icons.warning_amber;
      case 'milestone':
        return Icons.flag;
      default:
        return Icons.circle;
    }
  }

  /// Get color based on unit
  Color get unitColor {
    switch (unit) {
      case 'social':
        return AppColors.unitSocial;
      case 'medical':
        return AppColors.unitMedical;
      case 'psych':
        return AppColors.unitPsych;
      case 'rehab':
        return AppColors.unitRehab;
      case 'homelife':
        return AppColors.unitHomelife;
      default:
        return AppColors.primary;
    }
  }

  /// Get unit display name
  String get unitDisplayName {
    switch (unit) {
      case 'social':
        return 'Social Services';
      case 'medical':
        return 'Medical';
      case 'psych':
        return 'Psychology';
      case 'rehab':
        return 'Rehabilitation';
      case 'homelife':
        return 'Homelife';
      default:
        return unit;
    }
  }

  factory TimelineEntryModel.fromJson(Map<String, dynamic> json) {
    return TimelineEntryModel(
      id: json['id'] as String,
      residentId: json['resident_id'] as String,
      entryType: json['entry_type'] as String,
      formSubmissionId: json['form_submission_id'] as String?,
      formTemplateType: json['form_template_type'] as String?,
      unit: json['unit'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      createdBy: json['created_by'] as String,
      creatorName: json['creator']?['full_name'] as String? ??
          json['creator_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'resident_id': residentId,
      'entry_type': entryType,
      'form_submission_id': formSubmissionId,
      'form_template_type': formTemplateType,
      'unit': unit,
      'title': title,
      'description': description,
      'metadata': metadata,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        residentId,
        entryType,
        formSubmissionId,
        formTemplateType,
        unit,
        title,
        description,
        metadata,
        createdBy,
        creatorName,
        createdAt,
      ];
}
