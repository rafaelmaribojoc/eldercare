import 'package:equatable/equatable.dart';

/// Resident model representing an elderly resident
class ResidentModel extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String? middleName;
  final DateTime dateOfBirth;
  final String gender;
  final String? photoUrl;
  final String? nfcTagId; // Added
  final String? caseNumber; // Added for Case Control Number
  final String? wardId; // Changed to nullable
  final String? wardName;
  final String? roomNumber;
  final String? bedNumber;
  final DateTime? admissionDate; // Changed to nullable
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;
  final String? medicalNotes;
  final String? allergies;
  final String? primaryDiagnosis;
  final bool isActive;
  final String status; // Added
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  // Houseparent Linked Field
  final String? houseparentId;
  final String? houseparentName; // For display only
  // Social Worker Linked Field
  final String? socialWorkerId;
  final String? socialWorkerName;
  final String? mentalHealthCondition; // Added

  // New Fields 2025
  final DateTime? applicationDate;
  final String? suffix;
  final String? nickname;
  final String? placeOfBirth;
  final String? referredBy;
  final String? referringContactPerson; // Added
  final String? referringPartyAddress;
  final String? caseCategory;
  final String? condition;
  final String? natureOfDisability; // Added
  final String? province;
  final String? city;
  final String? barangay;
  final String? streetAddress;
  final String? civilStatus;
  final String? educationalAttainment;
  final String? yearsOfEducation;
  final String? religion;
  final String? nearestRelativeName;
  final String? nearestRelativeAddress;
  final String? nearestRelativeContactNumber; // Added
  final String? nearestRelativeRelation; // Added
  final String? custodianName;
  final List<Map<String, dynamic>>? familyComposition;

  const ResidentModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.dateOfBirth,
    required this.gender,
    this.photoUrl,
    this.nfcTagId,
    this.caseNumber,
    this.wardId,
    this.wardName,
    this.roomNumber,
    this.bedNumber,
    this.admissionDate,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.medicalNotes,
    this.allergies,
    this.primaryDiagnosis,
    this.isActive = true,
    required this.status, // Added
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.houseparentId,
    this.houseparentName,
    this.socialWorkerId,
    this.socialWorkerName,
    this.mentalHealthCondition, // Added
    // New Fields 2025
    this.applicationDate,
    this.suffix,
    this.nickname,
    this.placeOfBirth,
    this.referredBy,
    this.referringContactPerson,
    this.referringPartyAddress,
    this.caseCategory,
    this.condition,
    this.natureOfDisability,
    this.province,
    this.city,
    this.barangay,
    this.streetAddress,
    this.civilStatus,
    this.educationalAttainment,
    this.yearsOfEducation,
    this.religion,
    this.nearestRelativeName,
    this.nearestRelativeAddress,
    this.nearestRelativeContactNumber,
    this.nearestRelativeRelation,
    this.custodianName,
    this.familyComposition,
  });

  String get fullName {
    final buffer = StringBuffer();
    buffer.write(firstName);
    if (middleName != null && middleName!.isNotEmpty) {
      buffer.write(' $middleName');
    }
    buffer.write(' $lastName');
    if (suffix != null && suffix!.isNotEmpty) {
      buffer.write(' $suffix');
    }
    return buffer.toString();
  }

  /// First Last format (Display)
  String get displayName => '$firstName $lastName';

  /// Last, First format (Sorting)
  String get sortName => '$lastName, $firstName';

  /// Get age
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Display location (Ward - Bed)
  String get displayLocation {
    if (wardName == null) return 'Unassigned';
    if (bedNumber != null) return '$wardName • Bed $bedNumber';
    return wardName!;
  }

  /// Alias for wardId (backward compatibility)
  String? get currentWardId => wardId;

  // Resident Code for Case Reference (e.g., Use Case Number or ID segment)
  String get residentCode =>
      caseNumber ?? 'REF-${id.substring(0, 6).toUpperCase()}';

  /// Get status display
  // String get status => isActive ? 'active' : 'discharged';
  // Replaced with actual status field

  factory ResidentModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse List<Map>
    List<Map<String, dynamic>>? parseFamily(dynamic fam) {
      if (fam == null) return null;
      if (fam is List) {
        return fam.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      return null;
    }

    return ResidentModel(
      id: json['id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      middleName: json['middle_name'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : DateTime(1900),
      gender: json['gender'] as String? ?? 'male',
      photoUrl: json['photo_url'] as String?,
      nfcTagId: json['nfc_tag_id'] as String?, // Added
      caseNumber: json['case_number'] as String?,
      wardId: json['ward_id'] as String?,
      wardName: json['ward'] != null ? json['ward']['name'] as String? : null,
      roomNumber: json['room_number'] as String?,
      bedNumber: json['bed_number'] as String?,
      admissionDate: json['admission_date'] != null
          ? DateTime.parse(json['admission_date'] as String)
          : null,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      emergencyContactRelation: json['emergency_contact_relation'] as String?,
      medicalNotes: json['medical_notes'] as String?,
      allergies: json['allergies'] as String?,
      primaryDiagnosis: json['primary_diagnosis'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      status: json['status'] as String? ?? 'admitted',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      houseparentId: json['houseparent_id'] as String?,
      houseparentName: json['houseparent'] != null
          ? json['houseparent']['full_name'] as String?
          : null,
      socialWorkerId: json['social_worker_id'] as String?,
      socialWorkerName: json['social_worker'] != null
          ? json['social_worker']['full_name'] as String?
          : null,
      mentalHealthCondition:
          json['mental_health_condition'] as String?, // Added
      // New
      applicationDate: json['application_date'] != null
          ? DateTime.parse(json['application_date'] as String)
          : null,
      suffix: json['suffix'] as String?,
      nickname: json['nickname'] as String?,
      placeOfBirth: json['place_of_birth'] as String?,
      referredBy: json['referred_by'] as String?,
      referringContactPerson:
          json['referring_contact_person'] as String?, // Added
      referringPartyAddress: json['referring_party_address'] as String?,
      caseCategory: json['case_category'] as String?,
      condition: json['condition'] as String?,
      natureOfDisability: json['nature_of_disability'] as String?, // Added
      province: json['province'] as String?,
      city: json['city'] as String?,
      barangay: json['barangay'] as String?,
      streetAddress: json['street_address'] as String?,
      civilStatus: json['civil_status'] as String?,
      educationalAttainment: json['educational_attainment'] as String?,
      yearsOfEducation: json['years_of_education'] as String?,
      religion: json['religion'] as String?,
      nearestRelativeName: json['nearest_relative_name'] as String?,
      nearestRelativeAddress: json['nearest_relative_address'] as String?,
      nearestRelativeContactNumber:
          json['nearest_relative_contact_number'] as String?, // Added
      nearestRelativeRelation:
          json['nearest_relative_relation'] as String?, // Added
      custodianName: json['custodian_name'] as String?,
      familyComposition: parseFamily(json['family_composition']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'gender': gender,
      'photo_url': photoUrl,
      'nfc_tag_id': nfcTagId,
      'case_number': caseNumber,
      'ward_id': wardId,
      'ward_name': wardName, // Added to ensure availability in forms
      'room_number': roomNumber,
      'bed_number': bedNumber,
      'admission_date': admissionDate?.toIso8601String().split('T').first,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relation': emergencyContactRelation,
      'medical_notes': medicalNotes,
      'allergies': allergies,
      'primary_diagnosis': primaryDiagnosis,
      'is_active': isActive,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'houseparent_id': houseparentId,
      'social_worker_id': socialWorkerId,
      'mental_health_condition': mentalHealthCondition, // Added
      'application_date': applicationDate?.toIso8601String().split('T').first,
      'suffix': suffix,
      'nickname': nickname,
      'place_of_birth': placeOfBirth,
      'referred_by': referredBy,
      'referring_contact_person': referringContactPerson,
      'referring_party_address': referringPartyAddress,
      'case_category': caseCategory,
      'condition': condition,
      'nature_of_disability': natureOfDisability, // Added
      'province': province,
      'city': city,
      'barangay': barangay,
      'street_address': streetAddress,
      'civil_status': civilStatus,
      'educational_attainment': educationalAttainment,
      'years_of_education': yearsOfEducation,
      'religion': religion,
      'nearest_relative_name': nearestRelativeName,
      'nearest_relative_address': nearestRelativeAddress,
      'nearest_relative_contact_number': nearestRelativeContactNumber,
      'nearest_relative_relation': nearestRelativeRelation,
      'custodian_name': custodianName,
      'family_composition': familyComposition,
    };
  }

  ResidentModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? middleName,
    DateTime? dateOfBirth,
    String? gender,
    String? photoUrl,
    String? nfcTagId,
    String? caseNumber,
    String? wardId,
    String? wardName,
    String? roomNumber,
    String? bedNumber,
    DateTime? admissionDate,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    String? medicalNotes,
    String? allergies,
    String? primaryDiagnosis,
    bool? isActive,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? houseparentId,
    String? socialWorkerId,
    String? mentalHealthCondition, // Added
    DateTime? applicationDate,
    String? suffix,
    String? nickname,
    String? placeOfBirth,
    String? referredBy,
    String? referringContactPerson,
    String? referringPartyAddress,
    String? caseCategory,
    String? condition,
    String? natureOfDisability, // Added
    String? province,
    String? city,
    String? barangay,
    String? streetAddress,
    String? civilStatus,
    String? educationalAttainment,
    String? yearsOfEducation,
    String? religion,
    String? nearestRelativeName,
    String? nearestRelativeAddress,
    String? nearestRelativeContactNumber,
    String? nearestRelativeRelation,
    String? custodianName,
    List<Map<String, dynamic>>? familyComposition,
  }) {
    return ResidentModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      nfcTagId: nfcTagId ?? this.nfcTagId,
      caseNumber: caseNumber ?? this.caseNumber,
      wardId: wardId ?? this.wardId,
      wardName: wardName ?? this.wardName,
      roomNumber: roomNumber ?? this.roomNumber,
      bedNumber: bedNumber ?? this.bedNumber,
      admissionDate: admissionDate ?? this.admissionDate,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      allergies: allergies ?? this.allergies,
      primaryDiagnosis: primaryDiagnosis ?? this.primaryDiagnosis,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      houseparentId: houseparentId ?? this.houseparentId,
      socialWorkerId: socialWorkerId ?? this.socialWorkerId,
      mentalHealthCondition:
          mentalHealthCondition ?? this.mentalHealthCondition, // Added
      applicationDate: applicationDate ?? this.applicationDate,
      suffix: suffix ?? this.suffix,
      nickname: nickname ?? this.nickname,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      referredBy: referredBy ?? this.referredBy,
      referringContactPerson:
          referringContactPerson ?? this.referringContactPerson,
      referringPartyAddress:
          referringPartyAddress ?? this.referringPartyAddress,
      caseCategory: caseCategory ?? this.caseCategory,
      condition: condition ?? this.condition,
      natureOfDisability:
          natureOfDisability ?? this.natureOfDisability, // Added
      province: province ?? this.province,
      city: city ?? this.city,
      barangay: barangay ?? this.barangay,
      streetAddress: streetAddress ?? this.streetAddress,
      civilStatus: civilStatus ?? this.civilStatus,
      educationalAttainment:
          educationalAttainment ?? this.educationalAttainment,
      yearsOfEducation: yearsOfEducation ?? this.yearsOfEducation,
      religion: religion ?? this.religion,
      nearestRelativeName: nearestRelativeName ?? this.nearestRelativeName,
      nearestRelativeAddress:
          nearestRelativeAddress ?? this.nearestRelativeAddress,
      nearestRelativeContactNumber:
          nearestRelativeContactNumber ?? this.nearestRelativeContactNumber,
      nearestRelativeRelation:
          nearestRelativeRelation ?? this.nearestRelativeRelation,
      custodianName: custodianName ?? this.custodianName,
      familyComposition: familyComposition ?? this.familyComposition,
    );
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        middleName,
        dateOfBirth,
        gender,
        photoUrl,
        nfcTagId,
        caseNumber,
        wardId,
        wardName,
        roomNumber,
        bedNumber,
        admissionDate,
        emergencyContactName,
        emergencyContactPhone,
        emergencyContactRelation,
        medicalNotes,
        allergies,
        primaryDiagnosis,
        isActive,
        status,
        createdAt,
        updatedAt,
        createdBy,
        houseparentId,
        houseparentName,
        socialWorkerId,
        socialWorkerName,
        applicationDate,
        suffix,
        nickname,
        placeOfBirth,
        referredBy,
        referringContactPerson,
        referringPartyAddress,
        caseCategory,
        condition,
        natureOfDisability,
        mentalHealthCondition, // Added
        province,
        city,
        barangay,
        streetAddress,
        civilStatus,
        educationalAttainment,
        yearsOfEducation,
        religion,
        nearestRelativeName,
        nearestRelativeAddress,
        nearestRelativeContactNumber,
        nearestRelativeRelation,
        custodianName,
        familyComposition,
      ];
}
