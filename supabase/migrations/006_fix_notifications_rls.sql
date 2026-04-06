-- =============================================================================
-- Migration: 006_fix_notifications_rls.sql
-- Description: Add INSERT policy for notifications table
-- Issue: Users cannot create notifications for other users due to missing RLS policy
-- =============================================================================

-- Drop existing policies to recreate them properly
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;

-- Recreate SELECT policy - users can view their own notifications
CREATE POLICY "Users can view their own notifications"
    ON notifications FOR SELECT
    USING (user_id = auth.uid());

-- Recreate UPDATE policy - users can update (mark read) their own notifications
CREATE POLICY "Users can update their own notifications"
    ON notifications FOR UPDATE
    USING (user_id = auth.uid());

-- Add INSERT policy - authenticated users can create notifications for any user
-- This is needed because when User A submits a form to User B, User A creates
-- a notification record with user_id = User B's ID
CREATE POLICY "Authenticated users can create notifications"
    ON notifications FOR INSERT
    WITH CHECK (auth.uid() IS NOT NULL);

-- Add DELETE policy for cleanup (optional, for admin use)
CREATE POLICY "Users can delete their own notifications"
    ON notifications FOR DELETE
    USING (user_id = auth.uid());

-- =============================================================================
-- Also fix form_approvals INSERT policy if it's too restrictive
-- The sender creates the approval but needs to set recipient_id
-- =============================================================================

-- Check if the approval INSERT policy exists and works correctly
-- The current policy: WITH CHECK (sender_id = auth.uid())
-- This should work since the sender creates the approval with their own ID

-- Verify no issues with form_submissions access for approval workflow
-- Add policy for updating forms during approval process
DROP POLICY IF EXISTS "Recipients can update forms they are reviewing" ON form_submissions;

CREATE POLICY "Recipients can update forms they are reviewing"
    ON form_submissions FOR UPDATE
    USING (
        -- User is the submitter
        submitted_by = auth.uid()
        OR
        -- User is reviewing the form (has a pending approval)
        EXISTS (
            SELECT 1 FROM form_approvals fa
            WHERE fa.form_submission_id = form_submissions.id
            AND fa.recipient_id = auth.uid()
        )
    );

-- =============================================================================
-- COMMENTS
-- ======================================a=======================================
COMMENT ON POLICY "Authenticated users can create notifications" ON notifications 
    IS 'Allows any authenticated user to create notifications for other users (e.g., when submitting forms for approval)';
