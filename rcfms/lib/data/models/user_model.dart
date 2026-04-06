import 'package:equatable/equatable.dart';

/// User model representing a staff member
class UserModel extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String workId;
  final String? username;
  final String role;
  final String? unit;
  final String? signatureUrl;
  final String? avatarUrl; // Added
  final String? nfcCardId; // Added
  final bool isActive;
  final bool profileCompleted; // Added
  final DateTime createdAt;
  final DateTime? updatedAt;

  final String? title;
  final String? licenseNo; // Added licenseNo
  final DateTime? licenseExpiryDate; // Added licenseExpiryDate

  /// Auto-generated employee ID (e.g., EMP-001)
  final String? employeeId;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.workId,
    this.username,
    required this.role,
    this.unit,
    this.signatureUrl,
    this.avatarUrl,
    this.nfcCardId,
    this.isActive = true,
    this.profileCompleted = false,
    required this.createdAt,
    this.updatedAt,
    this.title,
    this.licenseNo,
    this.employeeId,
    this.licenseExpiryDate,
  });

  /// Check if user is a super admin
  bool get isSuperAdmin => role == 'super_admin';

  /// Check if user is a center head
  bool get isCenterHead => role == 'center_head';

  /// Check if user is a unit head
  bool get isUnitHead =>
      role == 'head' ||
      (role.endsWith('_head') && !isCenterHead) ||
      role == 'medical_center_doctor';

  /// Check if user is staff
  bool get isStaff => role == 'staff' || role.endsWith('_staff');

  /// Check if user has completed their initial profile review
  bool get isProfileComplete =>
      profileCompleted &&
      (title != null && title!.isNotEmpty) &&
      (signatureUrl != null && signatureUrl!.isNotEmpty);

  /// Check if user can add residents (Social Head Only)
  bool get canAddResidents =>
      role == 'social_head' ||
      (role == 'head' && unit == 'social');

  /// Check if user can administer MOCA-P (Psych Head only)
  bool get canAdministerMocaP =>
      (role == 'head' && unit == 'psych') || role == 'psych_head';

  /// Display name with title (e.g., "Juan Dela Cruz, RSW")
  String get displayNameWithTitle =>
      title != null ? '$fullName, $title' : fullName;

  /// Display employee ID with name (e.g., "EMP-001 - Juan Dela Cruz")
  String get displayWithEmployeeId =>
      employeeId != null ? '$employeeId - $fullName' : fullName;

  /// Check if user can provision users (Super Admin only)
  bool get canProvisionUsers => isSuperAdmin;

  /// Check if user can approve forms
  bool get canApprove => isUnitHead || isCenterHead || isSuperAdmin;

  /// Get the computed job title/designation based on profile data or unit fallback
  String get jobTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!;
    }
    switch (unit?.toLowerCase()) {
      case 'psych':
        return 'Psychometrician';
      case 'social':
        return 'Social Worker';
      case 'homelife':
        return 'Housekeeper';
      case 'medical':
        // Differentiate based on role
        if (role == 'medical_center_doctor' || role == 'center_doctor') {
          return 'Center Doctor';
        }
        return role.contains('nutrition') ? 'Nutritionist-Dietitian' : 'Nurse';
      case 'nutrition':
        return 'Nutritionist-Dietitian';
      default:
        if (isCenterHead) return 'Center Head';
        if (isSuperAdmin) return 'Administrator';
        if (isUnitHead) return 'Unit Head';
        return role.replaceAll('_', ' ');
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Unknown',
      workId: json['work_id'] as String? ?? '',
      username: json['username'] as String?,
      role: json['role'] as String? ?? 'staff',
      unit: json['unit'] as String?,
      signatureUrl: json['signature_url'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      nfcCardId: json['nfc_card_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      profileCompleted: json['profile_completed'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      title: json['title'] as String?,
      licenseNo: json['license_no'] as String?,
      employeeId: json['employee_id'] as String?,
      licenseExpiryDate: json['license_expiry_date'] != null
          ? DateTime.parse(json['license_expiry_date'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'work_id': workId,
      'username': username,
      'role': role,
      'unit': unit,
      'signature_url': signatureUrl,
      'avatar_url': avatarUrl,
      'nfc_card_id': nfcCardId,
      'is_active': isActive,
      'profile_completed': profileCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'title': title,
      'license_no': licenseNo,
      'employee_id': employeeId,
      'license_expiry_date': licenseExpiryDate?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? workId,
    String? username,
    String? role,
    String? unit,
    String? signatureUrl,
    String? avatarUrl,
    String? nfcCardId,
    bool? isActive,
    bool? profileCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    String? licenseNo,
    String? employeeId,
    DateTime? licenseExpiryDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      workId: workId ?? this.workId,
      username: username ?? this.username,
      role: role ?? this.role,
      unit: unit ?? this.unit,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      nfcCardId: nfcCardId ?? this.nfcCardId,
      isActive: isActive ?? this.isActive,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      licenseNo: licenseNo ?? this.licenseNo,
      licenseExpiryDate: licenseExpiryDate ?? this.licenseExpiryDate,
      employeeId: employeeId ?? this.employeeId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        workId,
        username,
        role,
        unit,
        signatureUrl,
        avatarUrl,
        nfcCardId,
        isActive,
        profileCompleted,
        createdAt,
        updatedAt,
        title,
        licenseNo,
        employeeId,
        licenseExpiryDate,
      ];
}
