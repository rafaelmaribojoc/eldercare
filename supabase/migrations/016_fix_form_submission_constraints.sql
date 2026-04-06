-- Migration: Fix form submission constraints for all form types
-- 1. Update template_type CHECK to include all 51 template types from form_templates.dart
-- 2. Revert RLS SELECT policies to JWT-based (per 009 guidance) + form_approvals clause (from 012)
-- 3. Add pending_medical_review to status CHECK

-- =============================================================================
-- SECTION 1: Update template_type CHECK constraint
-- The original constraint (migration 001) only had ~25 types. 24 types added
-- since then (social, medical, nutrition) were never added to the constraint.
-- =============================================================================

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
    -- Nutrition Service
    'nt_screening',
    'nt_meal_plan',
    'nt_ncp_biannual',
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

-- =============================================================================
-- SECTION 2: Fix RLS SELECT policies
-- Revert from profiles-based subqueries (migration 015) back to JWT metadata
-- (as recommended by migration 009) while keeping:
--   - form_approvals clause (from migration 012)
--   - is_archived split (from migration 014)
--   - same-unit visibility clause
-- =============================================================================

DROP POLICY IF EXISTS "Users can view relevant active forms" ON form_submissions;
DROP POLICY IF EXISTS "Users can view archived forms" ON form_submissions;
DROP POLICY IF EXISTS "Users can view relevant forms" ON form_submissions;

CREATE POLICY "Users can view relevant active forms"
ON form_submissions FOR SELECT
USING (
    is_archived = false AND (
        submitted_by = auth.uid() OR
        (auth.jwt() -> 'user_metadata' ->> 'role') IN ('super_admin', 'center_head') OR
        (
            (auth.jwt() -> 'user_metadata' ->> 'role') LIKE '%_head' AND
            (auth.jwt() -> 'user_metadata' ->> 'unit') = form_submissions.unit
        ) OR
        (auth.jwt() -> 'user_metadata' ->> 'unit') = form_submissions.unit OR
        EXISTS (
            SELECT 1 FROM form_approvals fa
            WHERE fa.form_submission_id = form_submissions.id
            AND fa.recipient_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can view archived forms"
ON form_submissions FOR SELECT
USING (
    is_archived = true AND (
        submitted_by = auth.uid() OR
        (auth.jwt() -> 'user_metadata' ->> 'role') IN ('super_admin', 'center_head') OR
        (
            (auth.jwt() -> 'user_metadata' ->> 'role') LIKE '%_head' AND
            (auth.jwt() -> 'user_metadata' ->> 'unit') = form_submissions.unit
        ) OR
        (auth.jwt() -> 'user_metadata' ->> 'unit') = form_submissions.unit OR
        EXISTS (
            SELECT 1 FROM form_approvals fa
            WHERE fa.form_submission_id = form_submissions.id
            AND fa.recipient_id = auth.uid()
        )
    )
);

-- =============================================================================
-- SECTION 3: Update status CHECK constraint
-- Add pending_medical_review (used in AppConstants and UI but missing from 008)
-- =============================================================================

ALTER TABLE form_submissions DROP CONSTRAINT IF EXISTS form_submissions_status_check;

ALTER TABLE form_submissions ADD CONSTRAINT form_submissions_status_check CHECK (status IN (
    'draft',
    'submitted',
    'pending_review',
    'pending_supervisor',
    'pending_multi_approval',
    'pending_final_approval',
    'pending_head_approval',
    'pending_doctor_review',
    'pending_social_worker',
    'pending_medical_review',
    'approved',
    'returned'
));
