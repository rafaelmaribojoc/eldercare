import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/workflow_models.dart';
import 'social_service_forms.dart';
import 'homelife_service_forms.dart';
import 'psychological_service_forms.dart';
import 'medical_service_forms.dart';
import 'nutrition_service_forms.dart';
import '../../../core/constants/app_constants.dart';

export 'social_service_forms.dart';
export 'homelife_service_forms.dart';
export 'psychological_service_forms.dart';
export 'medical_service_forms.dart';
export 'nutrition_service_forms.dart';
export 'form_field_builders.dart';
export '../models/workflow_models.dart';

/// Lifecycle categories for the digital filing cabinet
enum CaseFileCategory {
  admission('Admission', 1),
  ongoingCare('Ongoing Care', 2),
  incidentsSpecial('Incidents & Special Events', 3),
  medicalNutritionReports('Medical & Nutrition Reports', 4),
  dischargeTermination('Discharge & Termination', 5),
  inventory('Inventory', 6),
  uploadedScanned('Uploaded / Scanned', 7);

  final String displayName;
  final int sortOrder;
  const CaseFileCategory(this.displayName, this.sortOrder);
}

/// Service unit types
enum ServiceUnit {
  socialService('Social Service'),
  homeLifeService('Home Life Service'),
  psychologicalService('Psychological Service'),
  medicalService('Medical Service'),
  nutritionService('Nutrition and Dietetics');

  final String displayName;
  const ServiceUnit(this.displayName);
}

/// Form template definition
class FormTemplate {
  final String id;
  final String name;
  final String description;
  final ServiceUnit serviceUnit;
  final String templateType;
  final bool requiresSignature;
  final List<String> requiredSignatories;
  final List<String> allowedResidentStatuses;
  final IconData icon;
  final WorkflowConfig? workflowConfig;
  final String? preparerSignatureField;
  final CaseFileCategory category;

  const FormTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.serviceUnit,
    required this.templateType,
    this.requiresSignature = true,
    this.requiredSignatories = const [],
    this.allowedResidentStatuses = const ['admitted'],
    this.icon = LucideIcons.fileText,
    this.workflowConfig,
    this.preparerSignatureField,
    this.category = CaseFileCategory.ongoingCare,
  });
}

/// Form Templates Registry
class FormTemplatesRegistry {
  FormTemplatesRegistry._();

  /// Form data keys that are populated from resident (Add Residents) data.
  /// When a form is opened with resident data, these fields should be read-only.
  static const Set<String> residentSourcedFieldKeys = {
    // Main block (getDefaultData when residentData != null)
    'client_name',
    'resident_name',
    'name',
    'applicant_name',
    'resident_code',
    'case_no',
    'age',
    'client_age',
    'gender',
    'sex',
    'date_of_birth',
    'dob',
    'birthdate',
    'birthday',
    'age_sex',
    'condition',
    'length_of_stay',
    'date_admitted',
    'admission_date',
    'ward',
    'current_ward',
    'room_no',
    'bed_no',
    'diagnosis',
    'primary_diagnosis',
    'contact_person',
    'contact_number',
    'relationship',
    'place_of_birth',
    'birthplace',
    'referred_by',
    'referral_source',
    'source_of_referral',
    'referring_party',
    'referring_party_address',
    'religion',
    'religious_affiliation',
    'civil_status',
    'status',
    'educational_attainment',
    'educ_attainment',
    'address',
    'applicant_address',
    'complete_address',
    'provincial_address',
    'case_category',
    'category',
    'endorsed_by',
    'endorsed_by_designation',
    'family_composition',
    'nearest_relative_name',
    'nearest_relative_address',
    'nearest_relative',
    'disability_nature',
    'custodian_name',
    'referring_contact_person',
    'referring_contact_designation',
    'witnesses',
    // Template-specific (discharge_slip, kasunduan, admission_slip, etc.)
    'custodian_relationship',
    'custodian_address',
    'resident_of',
    'client_relative_name',
    'client_address',
    'case_control_no',
    'assigned_room',
    'admission_time',
    // nt_progress_notes
    'height',
    'weight',
    'cc',
    // nt_ncp_mnt, intervention_plan, etc.
    'client_no',
    'date_admission',
    'medical_diagnosis',
    'nickname',
    'date_of_admission',
    // social_case_study / updated_social_case_study
    'year_admitted',
    'birth_date',
    'birth_place',
    'ward_room',
  };

  /// All available form templates
  static const List<FormTemplate> templates = [
    // ============ SOCIAL SERVICE ============
    FormTemplate(
      id: 'ss_pre_admission_checklist',
      name: 'Pre-Admission Checklist',
      description: 'Initial checklist for client pre-admission screening',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'pre_admission_checklist',
      requiresSignature: false, // No Prepared By/Noted By - just acknowledge
      allowedResidentStatuses: ['pre_admission'],
      icon: LucideIcons.listChecks,
      category: CaseFileCategory.admission,
    ),
    FormTemplate(
      id: 'ss_requirements_checklist',
      name: 'Requirements Checklist',
      description: 'Document requirements verification checklist',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'requirements_checklist',
      requiresSignature: false, // No Prepared By/Noted By - just acknowledge
      allowedResidentStatuses: ['pre_admission'],
      icon: LucideIcons.listChecks,
      category: CaseFileCategory.admission,
    ),
    FormTemplate(
      id: 'ss_general_intake',
      name: 'General Intake Sheet',
      description: 'Initial client intake and assessment form',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'general_intake_sheet',
      requiresSignature: false,
      requiredSignatories: [],
      allowedResidentStatuses: ['admitted'],
      icon: LucideIcons.userPlus,
      category: CaseFileCategory.admission,
    ),
    FormTemplate(
      id: 'ss_admission_conference',
      name: 'Admission Case Conference',
      description: 'Case conference for client admission',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'admission_case_conference',
      requiredSignatories: ['Social Worker', 'Center Head'],
      allowedResidentStatuses: ['admitted'],
      icon: LucideIcons.users,
      category: CaseFileCategory.admission,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_admission_conference',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_clients_contract',
      name: 'Client\'s Contract',
      description: 'Agreement contract with client and custodian',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'clients_contract',
      requiredSignatories: ['Witness', 'Center Head'],
      allowedResidentStatuses: ['admitted'],
      icon: LucideIcons.handshake,
      category: CaseFileCategory.admission,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_clients_contract',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_admission_slip',
      name: 'Admission Slip',
      description: 'Official admission record slip',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'admission_slip',
      requiredSignatories: ['Medical Staff', 'Social Worker', 'Center Head'],
      allowedResidentStatuses: ['admitted'],
      icon: LucideIcons.badge,
      category: CaseFileCategory.admission,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_admission_slip',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Medical Assessment',
            description: 'Review by Medical Staff',
            requiredRoles: ['nurse', 'medical_staff', 'head'],
            nextStepId: 'pending_final_approval',
            signatureFieldName: 'medical_staff_name',
          ),
          'pending_final_approval': WorkflowStep(
            id: 'pending_final_approval',
            label: 'Center Head Approval',
            description: 'Final approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'center_head_name',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_progress_notes',
      name: 'Progress Notes',
      description: 'Regular client progress documentation',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'progress_notes',
      requiredSignatories: ['Social Worker', 'Center Head'],
      icon: LucideIcons.filePenLine,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_progress_notes',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_running_notes',
      name: 'Running Notes',
      description: 'Continuous running notes for client',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'running_notes',
      requiredSignatories: ['Social Worker', 'Center Head'],
      icon: LucideIcons.notebookTabs,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_running_notes',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_intervention_plan',
      name: 'Modified Intervention Plan',
      description: 'Client intervention plan with objectives and activities',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'intervention_plan',
      requiredSignatories: ['Social Worker', 'Center Head'],
      icon: LucideIcons.clipboardList,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_intervention_plan',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_updated_social_case_study',
      name: 'Updated Social Case Study Report',
      description: 'Comprehensive social case study report update',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'updated_social_case_study',
      requiredSignatories: ['Social Worker', 'Center Head'],
      allowedResidentStatuses: ['admitted'],
      icon: LucideIcons.refreshCw,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_updated_social_case_study',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_social_case_study',
      name: 'Social Case Study Report',
      description: 'Initial social case study report',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'social_case_study',
      requiredSignatories: ['Social Worker', 'Center Head'],
      allowedResidentStatuses: ['admitted'],
      icon: LucideIcons.newspaper,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_social_case_study',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_case_conference',
      name: 'Case Conference',
      description: 'Regular/Emergency/Pre-Discharge/Discharge case conference',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'case_conference',
      requiredSignatories: ['Social Worker', 'Center Head'],
      icon: LucideIcons.doorOpen,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_case_conference',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_termination_report',
      name: 'Termination Report',
      description: 'Case termination documentation',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'termination_report',
      requiredSignatories: ['Social Worker', 'Center Head'],
      icon: LucideIcons.logOut,
      category: CaseFileCategory.dischargeTermination,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_termination_report',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_closing_summary',
      name: 'Closing Summary',
      description: 'Case closing summary report',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'closing_summary',
      requiredSignatories: ['Social Worker', 'Center Head'],
      icon: LucideIcons.clipboardList,
      category: CaseFileCategory.dischargeTermination,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_closing_summary',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_quarterly_narrative',
      name: 'Quarterly Progress Narrative Report',
      description: 'Quarterly progress report covering all services',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'quarterly_narrative',
      requiredSignatories: ['Social Worker', 'Center Head'],
      icon: LucideIcons.calendarDays,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_quarterly_narrative',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_pre_termination_plan',
      name: 'Pre-Termination/Pre-Discharge Plan',
      description: 'Plan for client termination activities',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'pre_termination_plan',
      requiredSignatories: ['Social Worker', 'Center Head'],
      allowedResidentStatuses: ['admitted'],
      icon: LucideIcons.calendarPlus,
      category: CaseFileCategory.dischargeTermination,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_pre_termination_plan',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),

    FormTemplate(
      id: 'ss_after_care_plan',
      name: 'After Care Plan',
      description: 'Post-discharge care plan',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'after_care_plan',
      requiredSignatories: [
        'Social Worker',
        'Homelife Head',
        'Medical Head',
        'Psych Head',
        'C/MSWDO',
        'Center Head'
      ],
      allowedResidentStatuses: ['admitted', 'discharged'],
      icon: LucideIcons.heartPulse,
      category: CaseFileCategory.dischargeTermination,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_after_care_plan',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Social Head Review',
            description: 'Review by Social Service Head',
            requiredRoles: ['social_head', 'head'],
            nextStepId: 'pending_multi_approval',
            signatureFieldName: 'confirmed_social',
          ),
          'pending_multi_approval': WorkflowStep(
            id: 'pending_multi_approval',
            label: 'Multi-Department Review',
            description:
                'Review by Homelife, Medical, and Psych heads (any order)',
            requiredRoles: [
              'homelife_head',
              'medical_head',
              'psych_head',
              'head'
            ],
            nextStepId: 'pending_head_approval',
            signatureFieldName: 'noted_by',
          ),
          'pending_head_approval': WorkflowStep(
            id: 'pending_head_approval',
            label: 'Center Head Approval',
            description: 'Final approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_case_transfer',
      name: 'Case Transfer Summary',
      description: 'Summary for case turnover',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'case_transfer_summary',
      requiredSignatories: ['Social Worker', 'Center Head'],
      allowedResidentStatuses: ['admitted', 'discharged'],
      icon: LucideIcons.archiveRestore,
      category: CaseFileCategory.dischargeTermination,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_case_transfer',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_client_photo',
      name: 'Client\'s Photo',
      description: 'Printable client photo page',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'client_photo',
      requiresSignature: false,
      requiredSignatories: [],
      allowedResidentStatuses: ['admitted'],
      icon: LucideIcons.camera,
      category: CaseFileCategory.admission,
    ),
    FormTemplate(
      id: 'ss_pre_admission_conference',
      name: 'Pre-Admission Case Conference',
      description: 'Case conference prior to admission',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'pre_admission_conference',
      requiredSignatories: ['Social Worker', 'Center Head'],
      allowedResidentStatuses: ['pre_admission'],
      icon: LucideIcons.users,
      category: CaseFileCategory.admission,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_pre_admission_conference',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_kasunduan',
      name: 'Client\'s Kasunduan',
      description: 'Agreement/Kasunduan (Tagalog)',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'kasunduan',
      requiredSignatories: ['Witness', 'Center Head'],
      allowedResidentStatuses: ['admitted'],
      icon: LucideIcons.handshake,
      category: CaseFileCategory.admission,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_kasunduan',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ss_pre_discharge_conference',
      name: 'Pre-Discharge Case Conference',
      description: 'Conference prior to discharge',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'pre_discharge_conference',
      requiredSignatories: ['Social Worker', 'Center Head'],
      allowedResidentStatuses: ['admitted'],
      icon: LucideIcons.doorOpen,
      category: CaseFileCategory.dischargeTermination,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_pre_discharge_conference',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),

    FormTemplate(
      id: 'ss_discharge_slip',
      name: 'Discharged Slip',
      description: 'Official discharge record slip',
      serviceUnit: ServiceUnit.socialService,
      templateType: 'discharge_slip',
      requiredSignatories: ['Medical Staff', 'Social Worker', 'Center Head'],
      allowedResidentStatuses: ['discharged'],
      icon: LucideIcons.logOut,
      category: CaseFileCategory.dischargeTermination,
      workflowConfig: WorkflowConfig(
        templateId: 'ss_discharge_slip',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Medical Assessment',
            description: 'Review by Medical Staff',
            requiredRoles: ['nurse', 'medical_staff', 'head'],
            nextStepId: 'pending_final_approval',
            signatureFieldName: 'medical_staff_name',
          ),
          'pending_final_approval': WorkflowStep(
            id: 'pending_final_approval',
            label: 'Center Head Approval',
            description: 'Final approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'center_head_name',
          ),
        },
      ),
    ),

    FormTemplate(
      id: 'hl_inventory_admission',
      name: 'Inventory Upon Admission',
      description: 'Client belongings inventory at admission',
      serviceUnit: ServiceUnit.homeLifeService,
      templateType: 'inventory_admission',
      preparerSignatureField: 'inspected_by',
      requiredSignatories: ['HP on Duty', 'Supervising HP', 'Center Head'],
      icon: LucideIcons.package,
      category: CaseFileCategory.inventory,
      workflowConfig: WorkflowConfig(
        templateId: 'hl_inventory_admission',
        initialStepId: 'pending_supervisor',
        steps: {
          'pending_supervisor': WorkflowStep(
            id: 'pending_supervisor',
            label: 'Supervising HP Review',
            description: 'Review by Supervising Houseparent',
            requiredRoles: ['homelife_head', 'head'],
            nextStepId: 'pending_head_approval',
            signatureFieldName: 'attested_by',
          ),
          'pending_head_approval': WorkflowStep(
            id: 'pending_head_approval',
            label: 'Center Head Approval',
            description: 'Final approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'hl_inventory_discharge',
      name: 'Inventory Upon Discharge',
      description: 'Client belongings inventory at discharge',
      serviceUnit: ServiceUnit.homeLifeService,
      templateType: 'inventory_discharge',
      preparerSignatureField: 'inspected_by',
      requiredSignatories: ['HP on Duty', 'Supervising HP', 'Center Head'],
      icon: LucideIcons.packageOpen,
      category: CaseFileCategory.inventory,
      workflowConfig: WorkflowConfig(
        templateId: 'hl_inventory_discharge',
        initialStepId: 'pending_supervisor',
        steps: {
          'pending_supervisor': WorkflowStep(
            id: 'pending_supervisor',
            label: 'Supervising HP Review',
            description: 'Review by Supervising Houseparent',
            requiredRoles: ['homelife_head', 'head'],
            nextStepId: 'pending_head_approval',
            signatureFieldName: 'attested_by',
          ),
          'pending_head_approval': WorkflowStep(
            id: 'pending_head_approval',
            label: 'Center Head Approval',
            description: 'Final approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'hl_inventory_monthly',
      name: 'Monthly Inventory Report',
      description: 'Regular monthly inventory of client belongings',
      serviceUnit: ServiceUnit.homeLifeService,
      templateType: 'inventory_monthly',
      preparerSignatureField: 'prepared_by',
      requiredSignatories: ['HP II', 'Supervising HP III', 'Center Head'],
      icon: LucideIcons.packageOpen,
      category: CaseFileCategory.inventory,
      workflowConfig: WorkflowConfig(
        templateId: 'hl_inventory_monthly',
        initialStepId: 'pending_supervisor',
        steps: {
          'pending_supervisor': WorkflowStep(
            id: 'pending_supervisor',
            label: 'Supervising HP Review',
            description: 'Review by Supervising Houseparent',
            requiredRoles: ['homelife_head', 'head'],
            nextStepId: 'pending_head_approval',
            signatureFieldName: 'submitted_by',
          ),
          'pending_head_approval': WorkflowStep(
            id: 'pending_head_approval',
            label: 'Center Head Approval',
            description: 'Final approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'hl_progress_notes',
      name: 'Progress Notes',
      description: 'Home life service progress documentation',
      serviceUnit: ServiceUnit.homeLifeService,
      templateType: 'progress_notes',
      preparerSignatureField: 'prepared_by',
      requiredSignatories: ['Houseparent I', 'Homelife Head', 'Center Head'],
      icon: LucideIcons.filePenLine,
      workflowConfig: WorkflowConfig(
        templateId: 'hl_progress_notes',
        initialStepId: 'pending_supervisor',
        steps: {
          'pending_supervisor': WorkflowStep(
            id: 'pending_supervisor',
            label: 'Homelife Head Review',
            description: 'Review and supervisory remarks by Homelife Head',
            requiredRoles: ['homelife_head', 'head'],
            nextStepId: 'pending_head_approval',
            signatureFieldName: 'attested_by',
          ),
          'pending_head_approval': WorkflowStep(
            id: 'pending_head_approval',
            label: 'Center Head Approval',
            description: 'Final approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'hl_incident_report',
      name: 'Incident Report',
      description: 'Documentation of incidents and actions taken',
      serviceUnit: ServiceUnit.homeLifeService,
      templateType: 'incident_report',
      preparerSignatureField: 'prepared_by',
      requiredSignatories: [
        'HP on Duty',
        'Social Worker Head',
        'Medical Head',
        'Psych Head',
        'Homelife Head',
        'Center Head'
      ],
      icon: LucideIcons.triangleAlert,
      category: CaseFileCategory.incidentsSpecial,
      workflowConfig: WorkflowConfig(
        templateId: 'hl_incident_report',
        initialStepId: 'pending_supervisor',
        steps: {
          'pending_supervisor': WorkflowStep(
            id: 'pending_supervisor',
            label: 'Supervising HP Review',
            description: 'Review by Supervising Houseparent',
            requiredRoles: ['homelife_head', 'head'],
            nextStepId: 'pending_multi_approval',
            signatureFieldName: 'attested_by',
          ),
          'pending_multi_approval': WorkflowStep(
            id: 'pending_multi_approval',
            label: 'All Unit Heads Review',
            description:
                'Review by Social, Psych, and Medical heads (any order)',
            requiredRoles: [
              'social_head',
              'medical_head',
              'psych_head',
              'head'
            ],
            nextStepId: 'pending_head_approval',
            signatureFieldName: 'received_unit_head', // Heuristic for multi
          ),
          'pending_head_approval': WorkflowStep(
            id: 'pending_head_approval',
            label: 'Center Head Approval',
            description: 'Final approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'hl_out_on_pass',
      name: 'Out on Pass',
      description: 'Client out-pass request and approval',
      serviceUnit: ServiceUnit.homeLifeService,
      templateType: 'out_on_pass',
      requiredSignatories: [
        'Supervising HP',
        'Center Doctor',
        'Social Worker',
        'Center Head'
      ],
      icon: LucideIcons.doorOpen,
      category: CaseFileCategory.incidentsSpecial,
      workflowConfig: WorkflowConfig(
        templateId: 'hl_out_on_pass',
        initialStepId: 'pending_supervisor',
        steps: {
          'pending_supervisor': WorkflowStep(
            id: 'pending_supervisor',
            label: 'Supervising HP Review',
            description: 'Review by Supervising Houseparent',
            requiredRoles: ['homelife_head', 'head'],
            nextStepId: 'pending_doctor_review',
            signatureFieldName: 'supervising_hp',
          ),
          'pending_doctor_review': WorkflowStep(
            id: 'pending_doctor_review',
            label: 'Center Doctor Review',
            description: 'Medical clearance by Center Doctor',
            requiredRoles: ['medical_head', 'head'],
            nextStepId: 'pending_social_worker',
            signatureFieldName: 'center_doctor',
          ),
          'pending_social_worker': WorkflowStep(
            id: 'pending_social_worker',
            label: 'Social Worker Review',
            description: 'Review by Social Worker',
            requiredRoles: ['social_head', 'head', 'staff'],
            nextStepId: 'pending_head_approval',
            signatureFieldName: 'social_worker',
          ),
          'pending_head_approval': WorkflowStep(
            id: 'pending_head_approval',
            label: 'Center Head Approval',
            description: 'Final approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'approved_by',
          ),
        },
      ),
    ),

    // ============ PSYCHOLOGICAL SERVICE ============
    FormTemplate(
      id: 'ps_progress_notes',
      name: 'Progress Notes',
      description: 'Monthly psychological progress report',
      serviceUnit: ServiceUnit.psychologicalService,
      templateType: 'progress_notes',
      requiredSignatories: ['Psychometrician', 'Center Head'],
      preparerSignatureField: 'prepared_by',
      icon: LucideIcons.brain,
      workflowConfig: WorkflowConfig(
        templateId: 'ps_progress_notes',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ps_group_sessions',
      name: 'Group Sessions Report',
      description: 'Group therapy/activity session documentation',
      serviceUnit: ServiceUnit.psychologicalService,
      templateType: 'group_sessions',
      requiredSignatories: ['Psychometrician', 'Center Head'],
      preparerSignatureField: 'prepared_by',
      icon: LucideIcons.usersRound,
      workflowConfig: WorkflowConfig(
        templateId: 'ps_group_sessions',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ps_individual_sessions',
      name: 'Individual Sessions Report',
      description: 'Individual therapy session documentation',
      serviceUnit: ServiceUnit.psychologicalService,
      templateType: 'individual_sessions',
      requiredSignatories: ['Psychometrician', 'Center Head'],
      preparerSignatureField: 'prepared_by',
      icon: LucideIcons.user,
      workflowConfig: WorkflowConfig(
        templateId: 'ps_individual_sessions',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ps_inter_service_referral',
      name: 'Inter-Service Referral',
      description: 'Referral form to psychological service',
      serviceUnit: ServiceUnit.psychologicalService,
      templateType: 'inter_service_referral',
      requiredSignatories: ['Referring Staff', 'Psych Head'],
      icon: LucideIcons.send,
      category: CaseFileCategory.incidentsSpecial,
      workflowConfig: WorkflowConfig(
        templateId: 'ps_inter_service_referral',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Psych Service Receipt',
            description: 'Received and acknowledged by Psych unit head',
            requiredRoles: ['psych_head', 'head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ps_initial_assessment',
      name: 'Initial Psychological Assessment',
      description: 'Initial psychological assessment for new clients',
      serviceUnit: ServiceUnit.psychologicalService,
      templateType: 'initial_assessment',
      requiredSignatories: ['Psychometrician', 'Center Head'],
      preparerSignatureField: 'prepared_by',
      icon: LucideIcons.clipboardList,
      workflowConfig: WorkflowConfig(
        templateId: 'ps_initial_assessment',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'ps_psychometrician_report',
      name: 'Psychometrician\'s Report',
      description: 'Comprehensive psychometrician evaluation report',
      serviceUnit: ServiceUnit.psychologicalService,
      templateType: 'psychometrician_report',
      requiredSignatories: ['Psychometrician', 'Center Head'],
      preparerSignatureField: 'prepared_by',
      icon: LucideIcons.chartColumn,
      workflowConfig: WorkflowConfig(
        templateId: 'ps_psychometrician_report',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),

    // ============ MEDICAL SERVICE ============
    FormTemplate(
      id: 'md_nursing_care_service',
      name: 'Medical Nursing Care Service',
      description: 'Medical and physical assessment of resident',
      serviceUnit: ServiceUnit.medicalService,
      templateType: 'md_nursing_care_service',
      requiredSignatories: ['Nurse', 'Center Head'],
      icon: LucideIcons.stethoscope,
      workflowConfig: WorkflowConfig(
        templateId: 'md_nursing_care_service',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'md_special_events',
      name: 'Report on Special Events',
      description: 'Report on medical procedures or special events',
      serviceUnit: ServiceUnit.medicalService,
      templateType: 'md_special_events',
      requiredSignatories: ['Nurse', 'Medical Officer', 'Center Head'],
      icon: LucideIcons.calendarCheck,
      category: CaseFileCategory.incidentsSpecial,
      workflowConfig: WorkflowConfig(
        templateId: 'md_special_events',
        initialStepId: 'pending_supervisor',
        steps: {
          'pending_supervisor': WorkflowStep(
            id: 'pending_supervisor',
            label: 'Medical Officer Review',
            description: 'Review by Medical Officer',
            requiredRoles: ['medical_head', 'head'],
            nextStepId: 'pending_head_approval',
            signatureFieldName: 'noted_by',
          ),
          'pending_head_approval': WorkflowStep(
            id: 'pending_head_approval',
            label: 'Center Head Approval',
            description: 'Final approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'md_quarterly_report',
      name: 'Quarterly Report re: Medical Service Report',
      description: 'Quarterly medical service accomplishment report',
      serviceUnit: ServiceUnit.medicalService,
      templateType: 'md_quarterly_report',
      requiredSignatories: ['Nurse', 'Center Head'],
      icon: LucideIcons.chartColumn,
      category: CaseFileCategory.medicalNutritionReports,
      workflowConfig: WorkflowConfig(
        templateId: 'md_quarterly_report',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'md_monthly_accomplishment_report',
      name: 'Monthly Accomplishment Report',
      description: 'Monthly medical service accomplishment report',
      serviceUnit: ServiceUnit.medicalService,
      templateType: 'md_monthly_accomplishment_report',
      requiredSignatories: ['Nurse', 'Center Head'],
      icon: LucideIcons.clipboardList,
      category: CaseFileCategory.medicalNutritionReports,
      workflowConfig: WorkflowConfig(
        templateId: 'md_monthly_accomplishment_report',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Center Head Approval',
            description: 'Approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),

    // ============ NUTRITION SERVICE ============
    FormTemplate(
      id: 'nt_screening',
      name: 'Nutrition Screening Form',
      description: 'Initial nutrition screening and assessment',
      serviceUnit: ServiceUnit.nutritionService,
      templateType: 'nt_screening',
      requiresSignature: false,
      requiredSignatories: [],
      allowedResidentStatuses: ['pre_admission', 'admitted'],
      icon: LucideIcons.scale,
    ),
    FormTemplate(
      id: 'nt_meal_plan',
      name: 'Meal Plan',
      description: 'Weekly meal plan and menu',
      serviceUnit: ServiceUnit.nutritionService,
      templateType: 'nt_meal_plan',
      requiredSignatories: ['Nutritionist/Dietitian'],
      icon: LucideIcons.utensils,
      workflowConfig: WorkflowConfig(
        templateId: 'nt_meal_plan',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Nutrition Head Review',
            description: 'Review by Nutrition Unit Head',
            requiredRoles: ['nutrition_head', 'head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'nt_diet_diary',
      name: 'Diet Diary',
      description: 'Daily diet diary and intake record',
      serviceUnit: ServiceUnit.nutritionService,
      templateType: 'nt_diet_diary',
      requiredSignatories: ['Nutritionist/Dietitian'],
      icon: LucideIcons.bookOpen,
      workflowConfig: WorkflowConfig(
        templateId: 'nt_diet_diary',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Nutrition Head Review',
            description: 'Review by Nutrition Unit Head',
            requiredRoles: ['nutrition_head', 'head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'nt_diet_orders',
      name: 'List of Diet Orders',
      description: 'List of client diet orders',
      serviceUnit: ServiceUnit.nutritionService,
      templateType: 'nt_diet_orders',
      requiredSignatories: ['Nutritionist/Dietitian'],
      icon: LucideIcons.list,
      workflowConfig: WorkflowConfig(
        templateId: 'nt_diet_orders',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Nutrition Head Review',
            description: 'Review by Nutrition Unit Head',
            requiredRoles: ['nutrition_head', 'head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'nt_malnourished_list',
      name: 'List of Malnourished Clients',
      description: 'List of malnourished clients and status',
      serviceUnit: ServiceUnit.nutritionService,
      templateType: 'nt_malnourished_list',
      requiredSignatories: [
        'Nutritionist/Dietitian',
        'Center Doctor',
        'Center Head'
      ],
      icon: LucideIcons.triangleAlert,
      category: CaseFileCategory.medicalNutritionReports,
      workflowConfig: WorkflowConfig(
        templateId: 'nt_malnourished_list',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Nutrition Head Review',
            description: 'Review by Nutrition Unit Head',
            requiredRoles: ['nutrition_head', 'head'],
            nextStepId: 'pending_doctor_review',
            signatureFieldName: 'noted_by',
          ),
          'pending_doctor_review': WorkflowStep(
            id: 'pending_doctor_review',
            label: 'Center Doctor Review',
            description: 'Medical review by Center Doctor',
            requiredRoles: ['medical_head', 'head'],
            nextStepId: 'pending_head_approval',
            signatureFieldName: 'mnl_noted_by',
          ),
          'pending_head_approval': WorkflowStep(
            id: 'pending_head_approval',
            label: 'Center Head Approval',
            description: 'Final approval by Center Head',
            requiredRoles: ['center_head'],
            signatureFieldName: 'approved_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'nt_ncp_mnt',
      name: 'Nutrition Care Plan (MNT)',
      description: 'Medical Nutrition Therapy Care Plan',
      serviceUnit: ServiceUnit.nutritionService,
      templateType: 'nt_ncp_mnt',
      requiredSignatories: ['Nutritionist/Dietitian', 'Center Doctor'],
      icon: LucideIcons.heartPulse,
      workflowConfig: WorkflowConfig(
        templateId: 'nt_ncp_mnt',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Nutrition Head Review',
            description: 'Review by Nutrition Unit Head',
            requiredRoles: ['nutrition_head', 'head'],
            nextStepId: 'pending_doctor_review',
            signatureFieldName: 'noted_by',
          ),
          'pending_doctor_review': WorkflowStep(
            id: 'pending_doctor_review',
            label: 'Center Doctor Review',
            description: 'Medical review by Center Doctor',
            requiredRoles: ['medical_head', 'head'],
            signatureFieldName: 'conforme_physician',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'nt_progress_notes',
      name: 'Nutrition Progress Notes',
      description: 'Nutrition service progress notes',
      serviceUnit: ServiceUnit.nutritionService,
      templateType: 'nt_progress_notes',
      requiresSignature: false,
      requiredSignatories: [],
      icon: LucideIcons.filePlus,
    ),
    FormTemplate(
      id: 'nt_bmi_summary',
      name: 'Summary of Nutrition Status (BMI)',
      description: 'Summary of client nutrition status based on BMI',
      serviceUnit: ServiceUnit.nutritionService,
      templateType: 'nt_bmi_summary',
      requiredSignatories: ['Nutritionist/Dietitian'],
      icon: LucideIcons.chartColumn,
      category: CaseFileCategory.medicalNutritionReports,
      workflowConfig: WorkflowConfig(
        templateId: 'nt_bmi_summary',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Nutrition Head Review',
            description: 'Review by Nutrition Unit Head',
            requiredRoles: ['nutrition_head', 'head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'nt_status_summary',
      name: 'Summary of Client Nutrition Status',
      description: 'Summary report of client nutritional status',
      serviceUnit: ServiceUnit.nutritionService,
      templateType: 'nt_status_summary',
      requiredSignatories: ['Nutritionist/Dietitian'],
      icon: LucideIcons.chartPie,
      category: CaseFileCategory.medicalNutritionReports,
      workflowConfig: WorkflowConfig(
        templateId: 'nt_status_summary',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Nutrition Head Review',
            description: 'Review by Nutrition Unit Head',
            requiredRoles: ['nutrition_head', 'head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
    FormTemplate(
      id: 'nt_dietary_kardex',
      name: 'Dietary Kardex and Meal Distribution Plan',
      description: 'Exchange-based diet planning and meal distribution',
      serviceUnit: ServiceUnit.nutritionService,
      templateType: 'nt_dietary_kardex',
      requiredSignatories: ['Nutritionist/Dietitian'],
      icon: LucideIcons.grid2x2,
      workflowConfig: WorkflowConfig(
        templateId: 'nt_dietary_kardex',
        initialStepId: 'pending_review',
        steps: {
          'pending_review': WorkflowStep(
            id: 'pending_review',
            label: 'Nutrition Head Review',
            description: 'Review by Nutrition Unit Head',
            requiredRoles: ['nutrition_head', 'head'],
            signatureFieldName: 'noted_by',
          ),
        },
      ),
    ),
  ];

  /// Get templates by service unit
  static List<FormTemplate> getByServiceUnit(ServiceUnit unit) {
    return templates.where((t) => t.serviceUnit == unit).toList();
  }

  /// Get template by ID
  static FormTemplate? getById(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get template by templateType and unit
  static FormTemplate? getByTypeAndUnit(String templateType, String unit) {
    try {
      return templates.firstWhere((t) =>
          t.templateType == templateType && _unitMatches(t.serviceUnit, unit));
    } catch (e) {
      return null;
    }
  }

  /// Get template by templateType only (returns first match)
  static FormTemplate? getByType(String templateType) {
    try {
      return templates.firstWhere((t) => t.templateType == templateType);
    } catch (e) {
      return null;
    }
  }

  static bool _unitMatches(ServiceUnit serviceUnit, String unit) {
    switch (serviceUnit) {
      case ServiceUnit.socialService:
        return unit == 'social';
      case ServiceUnit.homeLifeService:
        return unit == 'homelife';
      case ServiceUnit.psychologicalService:
        return unit == 'psych';
      case ServiceUnit.medicalService:
        return unit == 'medical';
      case ServiceUnit.nutritionService:
        return unit == 'nutrition';
    }
  }

  /// Get form fields for a template
  /// [readOnly] - If true, all fields will be disabled (for approval view)
  /// [readOnlyFieldKeys] - When non-null, fields whose key is in this set are read-only (e.g. resident-sourced fields).
  static List<Widget> getFormFields(
    FormTemplate template,
    Map<String, dynamic> data,
    void Function(String, dynamic) onChanged, {
    bool readOnly = false,
    Set<String>? readOnlyFieldKeys,
    List<String>? residentNames,
    List<dynamic>? residents,
  }) {
    switch (template.serviceUnit) {
      case ServiceUnit.socialService:
        return SocialServiceForms.getFormFields(
          template.templateType,
          data,
          onChanged,
          readOnly: readOnly,
          readOnlyFieldKeys: readOnlyFieldKeys,
        );
      case ServiceUnit.homeLifeService:
        return HomeLifeServiceForms.getFormFields(
          template.templateType,
          data,
          onChanged,
          readOnly: readOnly,
          readOnlyFieldKeys: readOnlyFieldKeys,
          residentNames: residentNames,
          residents: residents, // Pass it down
        );
      case ServiceUnit.psychologicalService:
        return PsychologicalServiceForms.getFormFields(
          template.templateType,
          data,
          onChanged,
          readOnly: readOnly,
          readOnlyFieldKeys: readOnlyFieldKeys,
          residentNames: residentNames,
          residents: residents,
        );
      case ServiceUnit.medicalService:
        return MedicalServiceForms.getFormFields(
          template.templateType,
          data,
          onChanged,
          readOnly: readOnly,
          readOnlyFieldKeys: readOnlyFieldKeys,
        );
      case ServiceUnit.nutritionService:
        return NutritionServiceForms.getFormFields(
          template.templateType,
          data,
          onChanged,
          readOnly: readOnly,
          readOnlyFieldKeys: readOnlyFieldKeys,
          residentNames: residentNames,
          residents: residents,
        );
    }
  }

  /// Validate form data for a template
  static List<String> validateFormData(
    FormTemplate template,
    Map<String, dynamic> data,
  ) {
    final errors = <String>[];

    // Add template-specific validation here
    // This can be expanded based on required fields per template

    return errors;
  }

  /// Get initial/default data for a form with optional resident data for smart defaults
  static Map<String, dynamic> getDefaultData(
    FormTemplate template, {
    Map<String, dynamic>? residentData,
  }) {
    final now = DateTime.now();

    // Common default data with current date/time
    final defaults = <String, dynamic>{
      'created_at': now.toIso8601String(),
      'template_id': template.id,
      'service_unit': template.serviceUnit.name,
      // Pre-fill current date and time fields (editable)
      'date': now.toIso8601String().split('T')[0],
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'date_prepared': now.toIso8601String().split('T')[0],
      'date_accomplished': now.toIso8601String().split('T')[0],
      'date_submitted': now.toIso8601String(),

      // Auto-generate specific date fields
      'checklist_date': now.toIso8601String(),
      'intake_date': now.toIso8601String(),
      'conference_date': now.toIso8601String(),
      'contract_date': now.toIso8601String(),
      'admission_date': now.toIso8601String(),
      'progress_date': now.toIso8601String(),
      'running_date': now.toIso8601String(),
      'report_date': now.toIso8601String(),
      'session_date': now.toIso8601String(),
      'referral_date': now.toIso8601String(),
      'interview_date': now.toIso8601String(),
      'termination_date': now.toIso8601String(),
      'transfer_date': now.toIso8601String(),
      'date_discharged': now.toIso8601String(),
    };

    // Smart defaults from resident data
    if (residentData != null) {
      // Compute Full Name if missing
      String fullName =
          residentData['full_name'] ?? residentData['fullName'] ?? '';
      if (fullName.isEmpty) {
        final fname =
            residentData['first_name'] ?? residentData['firstName'] ?? '';
        final mname =
            residentData['middle_name'] ?? residentData['middleName'] ?? '';
        final lname =
            residentData['last_name'] ?? residentData['lastName'] ?? '';
        final suffix = residentData['suffix'] ?? '';
        fullName = [fname, mname, lname, suffix]
            .where((s) => s != null && s.toString().isNotEmpty)
            .join(' ');
      }

      defaults['client_name'] = fullName;
      defaults['resident_name'] = fullName;
      defaults['name'] = fullName;

      defaults['resident_code'] = residentData['resident_code'] ??
          residentData['residentCode'] ??
          residentData['case_number'] ??
          '';
      defaults['case_no'] = residentData['resident_code'] ??
          residentData['residentCode'] ??
          residentData['case_number'] ??
          '';

      // Compute Age if missing
      String age = residentData['age']?.toString() ?? '';
      if (age.isEmpty) {
        final dobStr =
            residentData['date_of_birth'] ?? residentData['dateOfBirth'];
        if (dobStr != null) {
          final dob = DateTime.tryParse(dobStr.toString());
          if (dob != null) {
            final today = DateTime.now();
            int ageVal = today.year - dob.year;
            if (today.month < dob.month ||
                (today.month == dob.month && today.day < dob.day)) {
              ageVal--;
            }
            age = ageVal.toString();
          }
        }
      }
      defaults['age'] = age;

      defaults['gender'] =
          residentData['gender']?.toString().toUpperCase() ?? '';
      defaults['sex'] = residentData['gender']?.toString().toUpperCase() ?? '';
      defaults['date_of_birth'] =
          residentData['date_of_birth'] ?? residentData['dateOfBirth'] ?? '';
      defaults['dob'] =
          residentData['date_of_birth'] ?? residentData['dateOfBirth'] ?? '';
      defaults['birthdate'] =
          residentData['date_of_birth'] ?? residentData['dateOfBirth'] ?? '';

      // Composite fields
      if (defaults['age'] != '' && defaults['sex'] != '') {
        defaults['age_sex'] = '${defaults['age']} / ${defaults['sex']}';
      }
      defaults['client_age'] = defaults['age'];
      defaults['condition'] = residentData['condition'] ?? '';

      defaults['length_of_stay'] = calculateLengthOfStay(
          residentData['date_admitted'] ?? residentData['admission_date']);
      defaults['date_admitted'] =
          residentData['admission_date'] ?? residentData['admissionDate'] ?? '';
      defaults['ward'] =
          residentData['ward_name'] ?? residentData['wardName'] ?? '';
      defaults['current_ward'] =
          residentData['ward_name'] ?? residentData['wardName'] ?? '';
      defaults['room_no'] =
          residentData['room_number'] ?? residentData['roomNumber'] ?? '';
      defaults['bed_no'] =
          residentData['bed_number'] ?? residentData['bedNumber'] ?? '';
      defaults['diagnosis'] = residentData['primary_diagnosis'] ??
          residentData['primaryDiagnosis'] ??
          '';
      defaults['primary_diagnosis'] = residentData['primary_diagnosis'] ??
          residentData['primaryDiagnosis'] ??
          '';
      defaults['contact_person'] = residentData['emergency_contact_name'] ??
          residentData['emergencyContactName'] ??
          '';
      defaults['contact_number'] = residentData['emergency_contact_phone'] ??
          residentData['emergencyContactPhone'] ??
          '';
      defaults['relationship'] = residentData['emergency_contact_relation'] ??
          residentData['emergencyContactRelation'] ??
          '';

      // Auto-populate: Place of Birth
      defaults['place_of_birth'] =
          residentData['place_of_birth'] ?? residentData['placeOfBirth'] ?? '';
      defaults['birthplace'] =
          residentData['place_of_birth'] ?? residentData['placeOfBirth'] ?? '';

      // Auto-populate: Referral
      defaults['referred_by'] =
          residentData['referred_by'] ?? residentData['referredBy'] ?? '';
      defaults['referral_source'] =
          residentData['referred_by'] ?? residentData['referredBy'] ?? '';
      defaults['referring_party'] = residentData['referring_contact_person'] ??
          residentData['referringContactPerson'] ??
          residentData['referred_by'] ??
          residentData['referredBy'] ??
          '';
      defaults['referring_party_address'] =
          residentData['referring_party_address'] ??
              residentData['referringPartyAddress'] ??
              '';

      // Auto-populate: Religion & Civil Status
      defaults['religion'] = residentData['religion'] ?? '';
      defaults['religious_affiliation'] = residentData['religion'] ?? '';
      defaults['civil_status'] =
          (residentData['civil_status'] ?? residentData['civilStatus'] ?? '')
              .toString()
              .toUpperCase();
      defaults['status'] = defaults['civil_status'];

      // Auto-populate: Education
      defaults['educational_attainment'] =
          (residentData['educational_attainment'] ??
                  residentData['educationalAttainment'] ??
                  '')
              .toString()
              .toUpperCase();
      defaults['educ_attainment'] = defaults['educational_attainment'];

      // Auto-populate: Address
      if (residentData['address'] != null &&
          residentData['address'].toString().isNotEmpty) {
        defaults['address'] = residentData['address'];
      } else {
        // Construct address from components
        final parts = [
          residentData['street_address'] ?? residentData['streetAddress'],
          residentData['barangay'],
          residentData['city'],
          residentData['province'],
        ].where((s) => s != null && s.toString().trim().isNotEmpty).join(', ');
        defaults['address'] = parts;
      }

      // Fallback for "Resident of" if address is empty (common for abandoned/homeless)
      if (defaults['address'] == null ||
          defaults['address'].toString().isEmpty) {
        // Use a placeholder or the facility location as a fallback, or leave empty but allow editing
        defaults['address'] =
            'Tagum City, Davao del Norte'; // Default to generic location if unknown
      }
      defaults['applicant_address'] = defaults['address'];
      defaults['complete_address'] = defaults['address'];
      defaults['provincial_address'] = residentData['province'] ?? '';

      // Auto-populate: Case Category
      defaults['case_category'] =
          residentData['case_category'] ?? residentData['caseCategory'] ?? '';

      // Auto-populate: Source of Referral
      defaults['source_of_referral'] =
          residentData['referred_by'] ?? residentData['referredBy'] ?? '';

      // Map auto-population for signatures
      defaults['endorsed_by'] = residentData['referring_contact_person'] ?? '';
      defaults['endorsed_by_designation'] =
          residentData['referring_contact_designation'] ?? '';

      // Don't auto-populate 'received_by' for Homelife inventories to avoid conflicts with 'receiving_party'
      if (template.serviceUnit != ServiceUnit.homeLifeService ||
          !template.templateType.contains('inventory')) {
        defaults['received_by'] = residentData['current_user_name'] ?? '';
        defaults['received_by_designation'] =
            residentData['current_user_designation'] ?? '';
      }

      // Default Witnesses for Client's Contract
      if (template.templateType == 'clients_contract') {
        defaults['witnesses'] = <Map<String, dynamic>>[];

        // Witness 1: Current User (The one preparing the form)
        if (residentData['current_user_name'] != null) {
          (defaults['witnesses'] as List).add({
            'name': residentData['current_user_name'],
            'designation': residentData['current_user_designation']
                    ?.toString()
                    .toUpperCase() ??
                'SOCIAL WORKER',
          });
        }

        // Witness 2: Referring Person (CSWDO/Referrer)
        if (defaults['endorsed_by'] != null &&
            defaults['endorsed_by'].toString().isNotEmpty) {
          (defaults['witnesses'] as List).add({
            'name': defaults['endorsed_by'],
            'designation':
                defaults['endorsed_by_designation']?.toString().toUpperCase() ??
                    'OTHERS',
          });
        }
      }

      // Auto-populate: Relative & Disability
      defaults['family_composition'] = residentData['family_composition'] ??
          residentData['familyComposition'] ??
          [];
      defaults['nearest_relative_name'] =
          residentData['nearest_relative_name'] ??
              residentData['nearestRelativeName'] ??
              '';
      defaults['nearest_relative_address'] =
          residentData['nearest_relative_address'] ??
              residentData['nearestRelativeAddress'] ??
              '';
      defaults['disability_nature'] = residentData['nature_of_disability'] ??
          residentData['natureOfDisability'] ??
          '';
      defaults['custodian_name'] = residentData['custodian_name'] ??
          residentData['custodianName'] ??
          defaults['nearest_relative_name'];

      // Auto-populate Status with Custodian's Civil Status
      if (defaults['custodian_name'] != null &&
          defaults['family_composition'] is List) {
        final family = defaults['family_composition'] as List;
        final targetName =
            defaults['custodian_name'].toString().trim().toLowerCase();

        Map<String, dynamic>? custodian;

        for (final m in family) {
          if ((m['name'] ?? '').toString().trim().toLowerCase() == targetName) {
            custodian = m as Map<String, dynamic>;
            break;
          }
        }

        if (custodian != null) {
          defaults['status'] = custodian['civil_status'] ?? '';
          if (custodian['address'] != null &&
              custodian['address'].toString().isNotEmpty) {
            defaults['address'] = custodian['address'];
          }
        } else {
          defaults['status'] = ''; // Clear if not found, don't use client's
        }
      }

      defaults['condition'] = residentData['condition'] ?? '';
      defaults['length_of_stay'] =
          calculateLengthOfStay(defaults['date_admitted']);

      // Maps for specific forms (General Intake)
      defaults['applicant_name'] =
          residentData['full_name'] ?? residentData['fullName'] ?? '';
      defaults['age'] = residentData['age']?.toString() ?? '';
      defaults['client_age'] = residentData['age']?.toString() ?? '';
      defaults['birthday'] =
          residentData['date_of_birth'] ?? residentData['dateOfBirth'] ?? '';

      // Auto-populate: Category
      if (residentData['case_category'] != null ||
          residentData['caseCategory'] != null) {
        defaults['category'] =
            residentData['case_category'] ?? residentData['caseCategory'];
        defaults['case_category'] =
            residentData['case_category'] ?? residentData['caseCategory'];
      }

      // Referral Info
      defaults['referring_contact_person'] =
          residentData['referring_contact_person'] ?? '';
      defaults['referring_contact_designation'] =
          residentData['referring_contact_designation'] ?? '';
    }

    // Default Facility info
    defaults['region'] = AppConstants.defaultRegion;
    defaults['center'] = AppConstants.defaultCenterName;

    // Template-specific defaults
    switch (template.templateType) {
      case 'case_transfer_summary':
        defaults['turned_over_by'] = residentData?['current_user_name'] ?? '';
        defaults['received_by'] = ''; // Should be blank for C/MSWDO signature
        break;
      case 'discharge_slip':
        defaults['resident_name'] = defaults['client_name'];
        defaults['case_no'] = residentData?['case_number'] ??
            residentData?['case_status']?['case_number'] ??
            '';
        defaults['discharge_date'] = now.toIso8601String();
        // defaults['discharge_time'] =
        //     'TimeOfDay(${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')})';
        defaults['custodian_name'] = defaults['nearest_relative_name'];
        defaults['custodian_relationship'] =
            residentData?['nearest_relative_relation'] ??
                residentData?['emergency_contact_relation'] ??
                '';
        defaults['custodian_address'] = defaults['nearest_relative_address'];

        // Signatory defaults
        defaults['social_worker'] = residentData?['current_user_name'] ?? '';
        defaults['center_head'] = 'CANDELARIA C. TINGSON, RSW';
        defaults['cmswdo'] =
            ''; // Blank for wet signature or manual entry if needed (but field matches hardcopy)
        defaults['medical_staff'] = '';
        break;
      case 'nt_malnourished_list':
        defaults['approved_by'] = 'CANDELARIA C. TINGSON, RSW';
        defaults['approved_by_designation'] = 'SWO IV / CENTER HEAD';
        defaults['mnl_noted_by_designation'] = 'Physician';
        break;
      case 'nt_progress_notes':
        defaults['age'] = residentData?['age'] ?? '';
        defaults['sex'] = residentData?['gender'] ?? 'Male';
        defaults['height'] = residentData?['height'] ?? '';
        defaults['weight'] = residentData?['weight'] ?? '';
        defaults['cc'] = residentData?['cc'] ?? '';
        break;
      case 'kasunduan':
        defaults['client_name'] =
            residentData?['full_name'] ?? residentData?['fullName'] ?? '';
        defaults['status'] = (residentData?['civil_status'] ??
                residentData?['civilStatus'] ??
                '')
            .toString()
            .toUpperCase();
        defaults['resident_of'] = defaults['address'];
        defaults['date_signed'] = now.toIso8601String();
        // Relationship/relative defaults
        defaults['client_relative_name'] = defaults['nearest_relative_name'];
        defaults['client_address'] = defaults['nearest_relative_address'];
        break;
      case 'admission_slip':
        // Auto-populate Admission Date/Time (default to now if not admitted yet)
        if (defaults['date_admitted'] != null) {
          defaults['admission_date'] = defaults['date_admitted'];
          try {
            // Extract time from date_admitted if possible, or use current time
            final d = DateTime.parse(defaults['date_admitted']);
            defaults['admission_time'] =
                "${d.hour > 12 ? d.hour - 12 : (d.hour == 0 ? 12 : d.hour)}:${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}";
          } catch (_) {}
        } else {
          defaults['admission_date'] = now.toIso8601String();
          defaults['admission_time'] =
              "${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
        }

        // Fix: Check multiple possible keys for case number and ensure it's not null
        final caseNo = residentData?['caseNumber'] ??
            residentData?['case_number'] ??
            residentData?['id'] ?? // Fallback to ID if really needed
            '';
        defaults['case_control_no'] = caseNo.toString();

        // Auto-populate Civil Status with safe UPPERCASE to match dropdowns
        final civilStatus =
            residentData?['civilStatus'] ?? residentData?['civil_status'] ?? '';
        if (civilStatus != null && civilStatus.toString().isNotEmpty) {
          defaults['civil_status'] = civilStatus.toString().toUpperCase();
        } else {
          defaults['civil_status'] = 'SINGLE'; // Default fallback
        }

        defaults['religion'] = residentData?['religion'] ?? '';
        defaults['educational_attainment'] =
            residentData?['educationalAttainment'] ??
                residentData?['educational_attainment'] ??
                '';

        // Nearest Relative Name & Address
        final nrName = defaults['nearest_relative_name'] ?? '';
        final nrAddress = defaults['nearest_relative_address'] ?? '';
        if (nrName.isNotEmpty || nrAddress.isNotEmpty) {
          defaults['nearest_relative'] = '$nrName\n$nrAddress'.trim();
        }

        // Assigned Room (combine room/ward info)
        final List<String> roomParts = [];
        // Fix: prioritiy to ward_name in JSON (added to model), then wardName, then nested
        final wardName = residentData?['ward_name'] ??
            residentData?['wardName'] ??
            residentData?['ward']?['name'];

        if (wardName != null && wardName.toString().isNotEmpty) {
          roomParts.add('Ward: $wardName');
        }

        final roomNum = residentData?['room_number'];
        if (roomNum != null && roomNum.toString().isNotEmpty) {
          roomParts.add('Room: $roomNum');
        }

        final bedNum = residentData?['bed_number'];
        if (bedNum != null && bedNum.toString().isNotEmpty) {
          roomParts.add('Bed: $bedNum');
        }
        defaults['assigned_room'] = roomParts.join(', ');

        // Default Center Head Name
        defaults['center_head_name'] = AppConstants.defaultCenterHeadName;
        break;
      case 'inventory_admission':
      case 'inventory_discharge':
        defaults['admission_items'] = <Map<String, dynamic>>[];
        defaults['discharge_items'] = <Map<String, dynamic>>[];
        defaults['inventory_date'] = now.toIso8601String();
        defaults['client_name'] = residentData?['full_name'] ?? '';
        break;
      case 'inventory_monthly':
        defaults['clothing_items'] = <Map<String, dynamic>>[];
        defaults['toiletries_items'] = <Map<String, dynamic>>[];
        defaults['linen_items'] = <Map<String, dynamic>>[];
        defaults['others_items'] = <Map<String, dynamic>>[];
        defaults['month'] = _getMonthName(now.month);
        defaults['year'] = now.year.toString();
        break;
      case 'nt_bmi_summary':
        defaults['date'] = now.toIso8601String();
        defaults['clients_list'] = <Map<String, dynamic>>[];
        defaults['total_malnourished'] = '0';
        defaults['total_overweight'] = '0';
        defaults['total_obese'] = '0';
        defaults['prepared_by'] = residentData?['current_user_name'] ?? '';
        defaults['prepared_by_designation'] = 'Nutritionist-Dietitian II';
        break;
      case 'progress_notes':
        defaults['progress_entries'] = <Map<String, dynamic>>[];
        break;
      case 'nt_ncp_mnt':
        defaults['client_no'] = residentData?['case_number'] ??
            residentData?['caseNumber'] ??
            residentData?['resident_code'] ??
            '';
        defaults['cb_age_yrs'] = true; // Most residents are measured in years
        defaults['dob'] = defaults['date_of_birth'];

        // Auto-populate admission date safely
        if (defaults['date_admitted'] != null) {
          defaults['date_admission'] = defaults['date_admitted'];
        } else if (residentData?['admission_date'] != null) {
          defaults['date_admission'] = residentData!['admission_date'];
        } else if (residentData?['admissionDate'] != null) {
          defaults['date_admission'] = residentData!['admissionDate'];
        }

        defaults['date_assessed'] = now.toIso8601String();
        defaults['medical_diagnosis'] = residentData?['primary_diagnosis'] ??
            residentData?['primaryDiagnosis'] ??
            defaults['diagnosis'] ??
            '';
        break;
      case 'incident_report':
        defaults['action_items'] = <Map<String, dynamic>>[];
        defaults['when_date'] = now.toIso8601String();
        break;
      case 'group_sessions':
        defaults['participant_details'] = <Map<String, dynamic>>[];
        defaults['session_date'] = now.toIso8601String();
        break;
      case 'out_on_pass':
        defaults['pass_date'] = now.toIso8601String();
        break;
      case 'initial_assessment':
        defaults['intervention_items'] = <Map<String, dynamic>>[];
        defaults['date_of_assessment'] = now.toIso8601String();
        defaults['date_of_report'] = now.toIso8601String();

        // Auto-populate Nickname from resident data
        defaults['nickname'] = residentData?['nickname'] ?? '';

        // Auto-populate Admission Date
        if (residentData?['admissionDate'] != null) {
          defaults['date_of_admission'] = residentData!['admissionDate'];
        } else if (residentData?['admission_date'] != null) {
          defaults['date_of_admission'] = residentData!['admission_date'];
        }
        break;

      case 'psychometrician_report':
        defaults['intervention_items'] = <Map<String, dynamic>>[];
        defaults['date_of_assessment'] = now.toIso8601String();
        defaults['date_of_report'] = now.toIso8601String();

        // Auto-populate Nickname from resident data
        defaults['nickname'] = residentData?['nickname'] ?? '';

        // Auto-populate Admission Date
        if (residentData?['admissionDate'] != null) {
          defaults['date_of_admission'] = residentData!['admissionDate'];
        } else if (residentData?['admission_date'] != null) {
          defaults['date_of_admission'] = residentData!['admission_date'];
        }
        break;
      case 'quarterly_narrative':
        defaults['quarter'] = _getQuarter(now.month);
        break;
      // Medical Service Defaults
      case 'md_quarterly_report':
        defaults['census_items'] = <Map<String, dynamic>>[];
        defaults['referrals_items'] = <Map<String, dynamic>>[];
        defaults['morbidity_items'] = <Map<String, dynamic>>[];
        defaults['operations_items'] = <Map<String, dynamic>>[];
        defaults['mortality_items'] = <Map<String, dynamic>>[];
        defaults['covid_vaccination_items'] = <Map<String, dynamic>>[];
        break;
      case 'md_monthly_accomplishment_report':
        defaults['accomplishments_items'] = <Map<String, dynamic>>[];
        defaults['month'] = _getMonthName(now.month);
        defaults['year'] = now.year.toString();
        break;
      case 'intervention_plan':
        defaults['client_name'] = residentData?['full_name'] ?? '';
        // Auto-populate Case Control No
        final caseNo = residentData?['caseNumber'] ??
            residentData?['case_number'] ??
            residentData?['id'] ??
            '';
        defaults['case_control_no'] = caseNo.toString();
        defaults['date_prepared'] = now.toIso8601String();
        // Initialize empty activities list ONLY for intervention_plan
        defaults['activities'] = <Map<String, dynamic>>[];
        break;

      case 'inter_service_referral':
        // Auto-populate Nickname
        defaults['nickname'] = residentData?['nickname'] ?? '';

        // Auto-populate Ward/Room (logic reused from admission_slip)
        final List<String> roomParts = [];
        final wardName = residentData?['ward_name'] ??
            residentData?['wardName'] ??
            residentData?['ward']?['name'];

        if (wardName != null && wardName.toString().isNotEmpty) {
          roomParts.add('Ward: $wardName');
        }

        final roomNum = residentData?['room_number'];
        if (roomNum != null && roomNum.toString().isNotEmpty) {
          roomParts.add('Room: $roomNum');
        }

        final bedNum = residentData?['bed_number'];
        if (bedNum != null && bedNum.toString().isNotEmpty) {
          roomParts.add('Bed: $bedNum');
        }
        defaults['ward_room'] = roomParts.join(', ');

        break;

      case 'updated_social_case_study':
      case 'social_case_study':
        // Auto-populate from resident data
        defaults['name'] = residentData?['full_name'] ?? '';

        // Year admitted from admission date
        if (residentData?['admissionDate'] != null) {
          try {
            final admissionDate =
                DateTime.parse(residentData!['admissionDate']);
            defaults['year_admitted'] = admissionDate.year.toString();
          } catch (e) {
            defaults['year_admitted'] = '';
          }
        } else {
          defaults['year_admitted'] = '';
        }

        // Birth date and place
        defaults['birth_date'] = residentData?['dateOfBirth'] ??
            residentData?['date_of_birth'] ??
            residentData?['birthDate'] ??
            residentData?['birth_date'] ??
            '';
        defaults['birth_place'] = residentData?['placeOfBirth'] ??
            residentData?['placeOf_birth'] ??
            residentData?['birthPlace'] ??
            residentData?['birth_place'] ??
            '';

        // Referring party
        defaults['referral_source'] =
            residentData?['referredBy'] ?? residentData?['referred_by'] ?? '';
        defaults['referring_party'] =
            residentData?['referring_contact_person'] ??
                residentData?['referringContactPerson'] ??
                '';

        // New: Auto-calculate and capitalize Length of Stay
        defaults['length_of_stay'] =
            calculateLengthOfStay(residentData?['admissionDate']).toUpperCase();

        // Parse address to get only city and province
        final city = residentData?['city'] ?? '';
        final province = residentData?['province'] ?? '';
        defaults['address'] =
            [city, province].where((s) => s.toString().isNotEmpty).join(', ');

        // Auto-populate age, sex, civil status
        defaults['age'] = residentData?['age']?.toString() ?? '';
        defaults['sex'] = (residentData?['gender'] ??
                    residentData?['Gender'] ??
                    residentData?['sex'] ??
                    residentData?['Sex'])
                ?.toString()
                .toUpperCase() ??
            '';
        defaults['civil_status'] = (residentData?['civilStatus'] ??
                residentData?['civil_status'] ??
                residentData?['status'] ??
                'SINGLE')
            .toString()
            .toUpperCase();

        defaults['religion'] = residentData?['religion'] ?? '';
        defaults['educational_attainment'] =
            residentData?['educational_attainment'] ??
                residentData?['educationalAttainment'] ??
                '';

        // Auto-populate category (default to 'ABANDONED')
        defaults['category'] =
            residentData?['caseCategory']?.toString().toUpperCase() ??
                'ABANDONED';

        // Initialize family composition from resident data
        if (residentData?['familyComposition'] is List) {
          final familyComp = residentData!['familyComposition'] as List;
          defaults['family_composition'] = familyComp.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            }
            return <String, dynamic>{};
          }).toList();
        } else {
          defaults['family_composition'] = <Map<String, dynamic>>[];
        }

        // Auto-populate signatures (will be filled by _autoPopulateSignatures)
        defaults['prepared_by'] = '';
        defaults['center_head'] = '';

        defaults['report_date'] = now.toIso8601String();
        break;
      case 'nt_dietary_kardex':
        final prefixes = [
          'veg',
          'fru',
          'milk',
          'rice_l',
          'rice_m',
          'rice_h',
          'meat_l',
          'meat_m',
          'meat_h',
          'fat',
          'sugar'
        ];
        final cols = [
          'ex',
          'hhm',
          'cho',
          'chon',
          'fat',
          'cal',
          'b',
          'l',
          's',
          'am',
          'pm',
          'mn',
          'notes'
        ];
        for (var p in prefixes) {
          for (var c in cols) {
            defaults['${p}_$c'] = '';
          }
        }

        final totals = [
          'total_cho',
          'total_chon',
          'total_fat',
          'total_cal',
          'total_b',
          'total_l',
          'total_s',
          'total_am',
          'total_pm',
          'total_mn'
        ];
        for (var t in totals) {
          defaults[t] = '0.0';
        }
        break;
      case 'nt_meal_plan':
        final prefixes = ['bf', 'am', 'lun', 'pm', 'din', 'bed'];
        final fields = ['food', 'amount', 'cho', 'chon', 'fat', 'cal'];
        for (var p in prefixes) {
          for (var f in fields) {
            defaults['${p}_$f'] = '';
          }
        }
        defaults['cho_adequacy'] = '';
        defaults['chon_adequacy'] = '';
        defaults['fat_adequacy'] = '';
        defaults['cal_adequacy'] = '';
        break;
    }

    return defaults;
  }

  static String _getMonthName(int month) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER'
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  static String _getQuarter(int month) {
    if (month <= 3) return '1st';
    if (month <= 6) return '2nd';
    if (month <= 9) return '3rd';
    return '4th';
  }

  /// Returns the list of form_data field names that must have a captured
  /// digital signature before the form can be submitted.
  static List<String> getRequiredSignatureFields(String templateType) {
    switch (templateType) {
      case 'requirements_checklist':
        return ['endorsed_by_signature_url'];
      case 'general_intake_sheet':
        return ['applicant_signature_url'];
      case 'clients_contract':
        return [
          'custodian_signature_url',
          'witness1_signature_url',
          'witness2_signature_url',
        ];
      case 'intervention_plan':
        return ['client_signature_url'];
      case 'termination_report':
        return [
          'division_chief_signature_url',
          'regional_director_signature_url',
        ];
      case 'after_care_plan':
        return ['cmswdo_signature_url'];
      case 'case_transfer_summary':
        return ['received_by_signature_url'];
      case 'kasunduan':
        return ['client_signature_url'];
      case 'pre_discharge_conference':
        return ['receiving_party_signature_url', 'cmswdo_signature_url'];
      case 'inventory_admission':
        return ['referring_party_signature_url', 'client_signature_url'];
      case 'inventory_discharge':
        return ['receiving_party_signature_url', 'client_signature_url'];
      case 'out_on_pass':
        return ['client_signature_url'];
      default:
        return [];
    }
  }

  static String calculateLengthOfStay(String? dateAdmittedStr,
      {String? dateDischargedStr}) {
    if (dateAdmittedStr == null || dateAdmittedStr.isEmpty) return '';
    try {
      final admissionDate = DateTime.parse(dateAdmittedStr);
      // If discharge date is provided, use it as the end date. Otherwise use now.
      final endDate =
          (dateDischargedStr != null && dateDischargedStr.isNotEmpty)
              ? DateTime.parse(dateDischargedStr)
              : DateTime.now();

      final difference = endDate.difference(admissionDate).inDays;

      if (difference < 0) return '0 days';

      final years = difference ~/ 365;
      final remainingDaysAfterYears = difference % 365;
      final months = remainingDaysAfterYears ~/ 30;
      final days = remainingDaysAfterYears % 30;

      final parts = <String>[];
      if (years > 0) parts.add('$years year${years > 1 ? "s" : ""}');
      if (months > 0) parts.add('$months month${months > 1 ? "s" : ""}');
      if (days > 0) parts.add('$days day${days > 1 ? "s" : ""}');

      if (parts.isEmpty) return '0 days';
      return parts.join(', ');
    } catch (e) {
      return '';
    }
  }
}

/// Form status enum for the approval workflow
enum FormStatus {
  draft('Draft', 'Form is being filled out'),
  signedSubmitted('Signed & Submitted', 'Form has been signed and submitted'),
  pendingReview('Pending Review', 'Form is awaiting reviewer approval'),
  finalRecord('Final Record', 'Form has been approved and finalized'),
  returned('Returned', 'Form has been returned for corrections');

  final String label;
  final String description;
  const FormStatus(this.label, this.description);
}
