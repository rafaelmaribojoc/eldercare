-- Migration: 018_relax_form_update_rls.sql
-- Description: Allow authors to update their forms even after they have been 
-- "Saved for Signing" (status = 'submitted'). This enables fixing typos or 
-- missing fields before a reviewer has started the approval process.

DROP POLICY IF EXISTS "Recipients can update forms they are reviewing" ON form_submissions;

CREATE POLICY "Recipients can update forms they are reviewing"
    ON form_submissions FOR UPDATE
    USING (
        -- User is the original submitter AND the form is in an editable state.
        -- We now include 'submitted' to allow re-saves under the "For Signing" list.
        (submitted_by = auth.uid() AND status IN ('draft', 'returned', 'submitted'))
        OR
        -- User is currently reviewing the form (has an active pending approval recipient slot).
        EXISTS (
            SELECT 1 FROM form_approvals fa
            WHERE fa.form_submission_id = form_submissions.id
            AND fa.recipient_id = auth.uid()
            AND fa.status = 'pending'
        )
    );

COMMENT ON POLICY "Recipients can update forms they are reviewing" ON form_submissions 
    IS 'Allows authors to edit drafts, returned, and initially submitted forms, as well as current reviewers.';
