-- Migration: Fix form_submissions RLS to use profiles table instead of JWT metadata
-- The JWT user_metadata may not have role/unit for users created before metadata sync.
-- Using profiles ensures RLS works regardless of JWT state.
-- Also restores the form_approvals clause from migration 012 (recipients can see routed forms).

DROP POLICY IF EXISTS "Users can view relevant active forms" ON form_submissions;
DROP POLICY IF EXISTS "Users can view archived forms" ON form_submissions;

CREATE POLICY "Users can view relevant active forms"
ON form_submissions FOR SELECT
USING (
    is_archived = false AND (
        submitted_by = auth.uid() OR
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.is_active = true
            AND (
                p.role IN ('super_admin', 'center_head')
                OR (p.role LIKE '%_head' AND p.unit = form_submissions.unit)
                OR p.unit = form_submissions.unit
            )
        ) OR
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
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid() AND p.is_active = true
            AND (
                p.role IN ('super_admin', 'center_head')
                OR (p.role LIKE '%_head' AND p.unit = form_submissions.unit)
                OR p.unit = form_submissions.unit
            )
        ) OR
        EXISTS (
            SELECT 1 FROM form_approvals fa
            WHERE fa.form_submission_id = form_submissions.id
            AND fa.recipient_id = auth.uid()
        )
    )
);
