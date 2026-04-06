import 'package:equatable/equatable.dart';

/// Represents a notification for a user
class NotificationModel extends Equatable {
  final String id;
  final String userId;

  /// Type of notification
  final String
      type; // approval_request, form_approved, form_returned, form_acknowledged, system_alert, reminder

  /// Content
  final String title;
  final String message;

  /// Related entities
  final String? formSubmissionId;
  final String? formApprovalId;

  /// Status
  final bool isRead;
  final DateTime? readAt;

  /// Additional data
  final Map<String, dynamic>? metadata;

  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.formSubmissionId,
    this.formApprovalId,
    this.isRead = false,
    this.readAt,
    this.metadata,
    required this.createdAt,
  });

  bool get isApprovalRequest => type == 'approval_request';
  bool get isFormApproved => type == 'form_approved';
  bool get isFormReturned => type == 'form_returned';
  bool get isFormAcknowledged => type == 'form_acknowledged';
  bool get isSystemAlert => type == 'system_alert';
  bool get isReminder => type == 'reminder';

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      formSubmissionId: json['form_submission_id'] as String?,
      formApprovalId: json['form_approval_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'message': message,
      'form_submission_id': formSubmissionId,
      'form_approval_id': formApprovalId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? title,
    String? message,
    String? formSubmissionId,
    String? formApprovalId,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      formSubmissionId: formSubmissionId ?? this.formSubmissionId,
      formApprovalId: formApprovalId ?? this.formApprovalId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        title,
        message,
        formSubmissionId,
        formApprovalId,
        isRead,
        readAt,
        metadata,
        createdAt,
      ];
}
