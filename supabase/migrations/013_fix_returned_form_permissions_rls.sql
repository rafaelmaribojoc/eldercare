-- =============================================================================
-- Migration: 013_fix_returned_form_permissions_rls.sql
-- Description: Strengthen form_submissions UPDATE policy to prevent
-- non-authors from editing returned forms and restrict recipients
-- to only update when their approval is actually pending.
-- =============================================================================

DROP POLICY IF EXISTS "Recipients can update forms they are reviewing" ON form_submissions;

CREATE POLICY "Recipients can update forms they are reviewing"
    ON form_submissions FOR UPDATE
    USING (
        -- User is the original submitter AND the form is in a state they can edit
        (submitted_by = auth.uid() AND status IN ('draft', 'returned'))
        OR
        -- User is currently reviewing the form (has a PENDING approval)
        EXISTS (
            SELECT 1 FROM form_approvals fa
            WHERE fa.form_submission_id = form_submissions.id
            AND fa.recipient_id = auth.uid()
            AND fa.status = 'pending'
        )
    );

COMMENT ON POLICY "Recipients can update forms they are reviewing" ON form_submissions 
    IS 'Restricts updates to authors (for drafts/returns) and current recipients (for pending reviews).';
