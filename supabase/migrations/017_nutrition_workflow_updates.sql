-- Migration: Remove nt_ncp_biannual from template_type CHECK constraint
-- The NCP Bi-Annual Report form has been removed from the application.
-- All other nutrition workflow changes are handled in the Flutter app layer.

ALTER TABLE form_submissions DROP CONSTRAINT IF EXISTS form_submissions_template_type_check;

ALTER TABLE form_submissions ADD CONSTRAINT form_submissions_template_type_check
CHECK (template_type IN (
    -- Social Service (original)
    'pre_admission_checklist',
    'requirements_checklist',
    'general_intake_sheet',
    'admission_case_conference',
    'clients_contract',
    'admission_slip',
    'progress_notes',
    'running_notes',
    'intervention_plan',
    'social_case_study',
    'case_conference',
    'termination_report',
    'closing_summary',
    'quarterly_narrative',
    -- Social Service (added)
    'updated_social_case_study',
    'pre_termination_plan',
    'after_care_plan',
    'case_transfer_summary',
    'client_photo',
    'pre_admission_conference',
    'kasunduan',
    'pre_discharge_conference',
    'discharge_slip',
    -- Home Life Service
    'inventory_admission',
    'inventory_discharge',
    'inventory_monthly',
    'incident_report',
    'out_on_pass',
    -- Psychological Service
    'group_sessions',
    'individual_sessions',
    'inter_service_referral',
    'initial_assessment',
    'psychometrician_report',
    -- Medical Service (original)
    'daily_vitals',
    'medical_abstract',
    -- Medical Service (added)
    'md_nursing_care_service',
    'md_special_events',
    'md_quarterly_report',
    'md_monthly_accomplishment_report',
    -- Nutrition Service (nt_ncp_biannual removed)
    'nt_screening',
    'nt_meal_plan',
    'nt_diet_diary',
    'nt_diet_orders',
    'nt_malnourished_list',
    'nt_ncp_mnt',
    'nt_progress_notes',
    'nt_bmi_summary',
    'nt_status_summary',
    'nt_dietary_kardex',
    -- Other / legacy
    'moca_p_scoring',
    'behavior_log',
    'therapy_session_notes',
    'daily_activity_log'
));
