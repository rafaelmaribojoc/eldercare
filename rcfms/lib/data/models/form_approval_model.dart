import 'package:equatable/equatable.dart';

/// Represents an approval request for a form submission
class FormApprovalModel extends Equatable {
  final String id;
  final String formSubmissionId;

  // Sender info
  final String senderId;
  final String senderName;

  // Recipient info
  final String recipientId;
  final String recipientName;

  // Status
  final String status; // pending, acknowledged, approved, returned, cancelled

  // Signature field matching
  final String? signatureFieldName;
  final bool signatureApplied;
  final String? signatureUrl;

  // Action details
  final DateTime? actionAt;
  final String? comment;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FormApprovalModel({
    required this.id,
    required this.formSubmissionId,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.status,
    this.signatureFieldName,
    this.signatureApplied = false,
    this.signatureUrl,
    this.actionAt,
    this.comment,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPending => status == 'pending';
  bool get isAcknowledged => status == 'acknowledged';
  bool get isApproved => status == 'approved';
  bool get isReturned => status == 'returned';
  bool get isCancelled => status == 'cancelled';

  /// Whether this approval requires a signature overlay
  bool get requiresSignature => signatureFieldName != null;

  factory FormApprovalModel.fromJson(Map<String, dynamic> json) {
    return FormApprovalModel(
      id: json['id'] as String,
      formSubmissionId: json['form_submission_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      recipientId: json['recipient_id'] as String,
      recipientName: json['recipient_name'] as String,
      status: json['status'] as String? ?? 'pending',
      signatureFieldName: json['signature_field_name'] as String?,
      signatureApplied: json['signature_applied'] as bool? ?? false,
      signatureUrl: json['signature_url'] as String?,
      actionAt: json['action_at'] != null
          ? DateTime.parse(json['action_at'] as String)
          : null,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'form_submission_id': formSubmissionId,
      'sender_id': senderId,
      'sender_name': senderName,
      'recipient_id': recipientId,
      'recipient_name': recipientName,
      'status': status,
      'signature_field_name': signatureFieldName,
      'signature_applied': signatureApplied,
      'signature_url': signatureUrl,
      'action_at': actionAt?.toIso8601String(),
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  FormApprovalModel copyWith({
    String? id,
    String? formSubmissionId,
    String? senderId,
    String? senderName,
    String? recipientId,
    String? recipientName,
    String? status,
    String? signatureFieldName,
    bool? signatureApplied,
    String? signatureUrl,
    DateTime? actionAt,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FormApprovalModel(
      id: id ?? this.id,
      formSubmissionId: formSubmissionId ?? this.formSubmissionId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      status: status ?? this.status,
      signatureFieldName: signatureFieldName ?? this.signatureFieldName,
      signatureApplied: signatureApplied ?? this.signatureApplied,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      actionAt: actionAt ?? this.actionAt,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        formSubmissionId,
        senderId,
        senderName,
        recipientId,
        recipientName,
        status,
        signatureFieldName,
        signatureApplied,
        signatureUrl,
        actionAt,
        comment,
        createdAt,
        updatedAt,
      ];
}
