-- =============================================================================
-- Migration: 012_fix_parallel_approvals_rls.sql
-- Description: Update SELECT policy for form_submissions to allow parallel approvers
-- to view the forms routed to them across units.
-- =============================================================================

DROP POLICY IF EXISTS "Users can view relevant forms" ON form_submissions;

CREATE POLICY "Users can view relevant forms"
ON form_submissions FOR SELECT
USING (
    submitted_by = auth.uid() OR
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('super_admin', 'center_head') OR
    (
        (auth.jwt() -> 'user_metadata' ->> 'role') LIKE '%_head' AND 
        (auth.jwt() -> 'user_metadata' ->> 'unit') = form_submissions.unit
    ) OR
    EXISTS (
        SELECT 1 FROM form_approvals fa
        WHERE fa.form_submission_id = form_submissions.id
        AND fa.recipient_id = auth.uid()
    )
);

-- Note: UPDATE policy ("Recipients can update forms they are reviewing")
-- already exists from Migration 006 and covers cross-unit updates via form_approvals.
