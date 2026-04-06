/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'RCFMS';
  static const String appFullName =
      'Resident Care & Facility Management System';

  /// Default Facility Details
  static const String defaultRegion = 'Region XI';
  static const String defaultCenterName = 'Home for the Aged';
  static const String defaultCenterHeadName =
      'JUAN DELA CRUZ'; // Placeholder, should be updated with actual data

  /// Form status values
  static const String statusDraft = 'draft';
  static const String statusSubmitted = 'submitted';
  static const String statusPendingReview = 'pending_review';
  static const String statusApproved = 'approved';
  static const String statusReturned = 'returned';
  static const String statusPendingMedicalReview = 'pending_medical_review';
  static const String statusPendingFinalApproval = 'pending_final_approval';
  static const String statusPendingSupervisor = 'pending_supervisor';
  static const String statusPendingMultiApproval = 'pending_multi_approval';
  static const String statusPendingHeadApproval = 'pending_head_approval';
  static const String statusPendingDoctorReview = 'pending_doctor_review';
  static const String statusPendingSocialWorker = 'pending_social_worker';

  /// User roles (simplified per Blueprint)
  /// - Super Admin: System Owner & Security, Exclusive User Provisioning
  /// - Center Head: Operational Oversight, View Global Digital Timeline
  /// - Head: Service Unit Heads (Reviewers) - associated with a unit
  /// - Staff: Service Staff (Frontline) - associated with a unit
  static const String roleSuperAdmin = 'super_admin';
  static const String roleCenterHead = 'center_head';
  static const String roleHead = 'head';
  static const String roleStaff = 'staff';

  /// All available roles for user creation
  static const List<String> availableRoles = [
    roleStaff,
    roleHead,
    roleCenterHead,
    roleSuperAdmin,
  ];

  /// Roles that require a unit assignment
  static const List<String> rolesRequiringUnit = [
    roleStaff,
    roleHead,
  ];

  /// Admin roles (no unit required)
  static const List<String> adminRoles = [
    roleCenterHead,
    roleSuperAdmin,
  ];

  /// Check if role is admin level
  static bool isAdminRole(String role) => adminRoles.contains(role);

  /// Check if role requires unit assignment
  static bool requiresUnit(String role) => rolesRequiringUnit.contains(role);

  /// Check if user can manage residents (add/edit/transfer)
  /// Per User Request: ONLY Social Head can manage residents
  /// Social staff, Super Admin, and Center Head cannot add/edit residents
  static bool canManageResidents(String? role, String? unit) {
    if (role == null) return false;

    // Check for composite roles (new format)
    if (role == 'social_head' || role == 'social_staff') return true;

    // Check for legacy split roles
    if ((role == roleHead || role == roleStaff) && unit == unitSocial) return true;

    return false;
  }

  /// Check if a staff-level social worker or houseparent is assigned to a resident.
  /// Unit heads, admins, center heads, and other units are unrestricted.
  /// Returns true if the user is allowed to create notes for this resident.
  static bool canMakeNotesForResident({
    required String? role,
    required String? unit,
    required String? userId,
    required String? residentSocialWorkerId,
    required String? residentHouseparentId,
  }) {
    if (role == null || userId == null) return false;

    // Admins and center head can always make notes
    if (role == roleSuperAdmin || role == roleCenterHead) return true;

    // Unit heads can always make notes
    if (role == roleHead || role.endsWith('_head')) return true;

    // Staff-level social workers: must be assigned
    if ((role == 'social_staff' || (role == roleStaff && unit == unitSocial))) {
      return userId == residentSocialWorkerId;
    }

    // Staff-level houseparents: must be assigned
    if ((role == 'homelife_staff' || role.contains('houseparent') ||
        (role == roleStaff && unit == unitHomelife))) {
      return userId == residentHouseparentId;
    }

    // Other staff (medical, psych, nutrition) are unrestricted for notes
    return true;
  }

  /// Check if user can approve/review forms
  static bool canApproveforms(String? role) {
    if (role == null) return false;
    return role == roleCenterHead ||
        role == roleHead ||
        role.endsWith('_head') ||
        role.endsWith('_staff') ||
        role == 'medical_staff' ||
        role == 'medical_center_doctor' ||
        role == 'nurse'; // Allows explicit recipient workflows (e.g. slips)
  }

  /// Unit types
  static const String unitSocial = 'social';
  static const String unitMedical = 'medical';
  static const String unitPsych = 'psych';
  static const String unitRehab = 'rehab'; // Legacy, no active forms
  static const String unitHomelife = 'homelife';
  static const String unitNutrition = 'nutrition';

  /// Form template IDs by unit (matches FormTemplatesRegistry.templates)
  static const Map<String, List<String>> formTypesByUnit = {
    unitSocial: [
      'ss_pre_admission_checklist',
      'ss_requirements_checklist',
      'ss_general_intake',
      'ss_admission_conference',
      'ss_clients_contract',
      'ss_admission_slip',
      'ss_progress_notes',
      'ss_running_notes',
      'ss_intervention_plan',
      'ss_updated_social_case_study',
      'ss_social_case_study',
      'ss_case_conference',
      'ss_termination_report',
      'ss_closing_summary',
      'ss_quarterly_narrative',
      'ss_pre_termination_plan',
      'ss_after_care_plan',
      'ss_case_transfer',
      'ss_client_photo',
      'ss_pre_admission_conference',
      'ss_kasunduan',
      'ss_pre_discharge_conference',
      'ss_discharge_slip',
      'ps_inter_service_referral',
    ],
    unitMedical: [
      'md_nursing_care_service',
      'md_special_events',
      'md_quarterly_report',
      'md_monthly_accomplishment_report',
      'ps_inter_service_referral',
    ],
    unitPsych: [
      'ps_progress_notes',
      'ps_group_sessions',
      'ps_individual_sessions',
      'ps_inter_service_referral',
      'ps_initial_assessment',
      'ps_psychometrician_report',
    ],
    unitHomelife: [
      'hl_inventory_admission',
      'hl_inventory_discharge',
      'hl_inventory_monthly',
      'hl_progress_notes',
      'hl_incident_report',
      'hl_out_on_pass',
      'ps_inter_service_referral',
    ],
    unitNutrition: [
      'nt_screening',
      'nt_meal_plan',
      'nt_diet_diary',
      'nt_diet_orders',
      'nt_malnourished_list',
      'nt_ncp_mnt',
      'nt_progress_notes',
      'nt_status_summary',
    ],
  };

  /// Map service unit enum names to database unit values
  static String getUnitFromServiceUnit(String serviceUnitName) {
    switch (serviceUnitName) {
      case 'socialService':
        return unitSocial;
      case 'homeLifeService':
        return unitHomelife;
      case 'psychologicalService':
        return unitPsych;
      case 'medicalService':
        return unitMedical;
      case 'nutritionService':
        return unitNutrition;
      default:
        return unitSocial;
    }
  }

  /// Animation durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 350);
  static const Duration longDuration = Duration(milliseconds: 500);

  /// Pagination
  static const int defaultPageSize = 20;

  /// Validation
  static const int minPasswordLength = 8;
  static const int maxUsernameLength = 30;
}
