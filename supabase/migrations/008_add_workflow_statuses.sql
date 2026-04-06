-- Add workflow statuses to form_submissions status CHECK constraint
-- Required for multi-step approval workflows (P3/P4 forms)

ALTER TABLE form_submissions
  DROP CONSTRAINT IF EXISTS form_submissions_status_check;

ALTER TABLE form_submissions
  ADD CONSTRAINT form_submissions_status_check CHECK (status IN (
    'draft',
    'submitted',
    'pending_review',
    'pending_supervisor',
    'pending_multi_approval',
    'pending_final_approval',
    'pending_head_approval',
    'pending_doctor_review',
    'pending_social_worker',
    'approved',
    'returned'
  ));
