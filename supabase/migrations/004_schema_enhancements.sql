-- =============================================================================
-- Migration 004: Schema Enhancements
-- - Add Title and Employee ID to profiles
-- - Create auto-incrementing Employee ID trigger
-- - Add approval workflow tables (form_approvals, notifications)
-- - Add digital signature tracking fields
-- =============================================================================

-- =============================================================================
-- PART 1: PROFILES ENHANCEMENTS
-- =============================================================================

-- Add new columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS title TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS employee_id TEXT UNIQUE;

-- Add comment for title field
COMMENT ON COLUMN profiles.title IS 'Professional title/designation (e.g., RSW, RPm, RN, MD)';
COMMENT ON COLUMN profiles.employee_id IS 'Auto-generated employee ID in format EMP-001, EMP-002, etc.';

-- Create a sequence for employee IDs
CREATE SEQUENCE IF NOT EXISTS employee_id_seq START WITH 1;

-- Function to generate employee ID
CREATE OR REPLACE FUNCTION generate_employee_id()
RETURNS TRIGGER AS $$
DECLARE
    next_id INTEGER;
    new_employee_id TEXT;
BEGIN
    -- Get next sequence value
    SELECT nextval('employee_id_seq') INTO next_id;
    
    -- Format as EMP-XXX (zero-padded to 3 digits)
    new_employee_id := 'EMP-' || LPAD(next_id::TEXT, 3, '0');
    
    -- Assign to new record
    NEW.employee_id := new_employee_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for auto-generating employee ID on profile creation
DROP TRIGGER IF EXISTS trigger_generate_employee_id ON profiles;
CREATE TRIGGER trigger_generate_employee_id
    BEFORE INSERT ON profiles
    FOR EACH ROW
    WHEN (NEW.employee_id IS NULL)
    EXECUTE FUNCTION generate_employee_id();

-- Update existing profiles without employee_id
DO $$
DECLARE
    profile_record RECORD;
    counter INTEGER := 1;
BEGIN
    FOR profile_record IN 
        SELECT id FROM profiles 
        WHERE employee_id IS NULL 
        ORDER BY created_at ASC
    LOOP
        UPDATE profiles 
        SET employee_id = 'EMP-' || LPAD(counter::TEXT, 3, '0')
        WHERE id = profile_record.id;
        counter := counter + 1;
    END LOOP;
    
    -- Reset sequence to continue from last used number
    PERFORM setval('employee_id_seq', counter);
END $$;

-- =============================================================================
-- PART 2: FORM APPROVALS TABLE (Hierarchical Workflow)
-- =============================================================================

CREATE TABLE IF NOT EXISTS form_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_submission_id UUID NOT NULL REFERENCES form_submissions(id) ON DELETE CASCADE,
    
    -- Sender (who submitted for approval)
    sender_id UUID NOT NULL REFERENCES profiles(id),
    sender_name TEXT NOT NULL,
    
    -- Recipient (who should approve/acknowledge)
    recipient_id UUID NOT NULL REFERENCES profiles(id),
    recipient_name TEXT NOT NULL,
    
    -- Approval details
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending',      -- Awaiting recipient action
        'acknowledged', -- Recipient has seen/acknowledged
        'approved',     -- Recipient has approved (with signature if applicable)
        'returned',     -- Recipient returned for revisions
        'cancelled'     -- Sender cancelled the request
    )),
    
    -- Signature field matching
    -- If recipient's name matches a form field (e.g., "Noted By", "Center Head"),
    -- their signature overlays that field upon approval
    signature_field_name TEXT, -- The field in form_data this approval relates to (e.g., 'noted_by', 'center_head')
    signature_applied BOOLEAN DEFAULT FALSE,
    signature_url TEXT,
    
    -- Action details
    action_at TIMESTAMPTZ,
    comment TEXT,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for form_approvals
CREATE INDEX IF NOT EXISTS idx_form_approvals_form ON form_approvals(form_submission_id);
CREATE INDEX IF NOT EXISTS idx_form_approvals_recipient ON form_approvals(recipient_id);
CREATE INDEX IF NOT EXISTS idx_form_approvals_status ON form_approvals(status);
CREATE INDEX IF NOT EXISTS idx_form_approvals_sender ON form_approvals(sender_id);

-- =============================================================================
-- PART 3: NOTIFICATIONS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    
    -- Notification type
    type TEXT NOT NULL CHECK (type IN (
        'approval_request',    -- Someone sent you a form for approval
        'form_approved',       -- Your form was approved
        'form_returned',       -- Your form was returned for revisions
        'form_acknowledged',   -- Your form was acknowledged
        'system_alert',        -- System notification
        'reminder'             -- Reminder notification
    )),
    
    -- Content
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    
    -- Related entities
    form_submission_id UUID REFERENCES form_submissions(id) ON DELETE CASCADE,
    form_approval_id UUID REFERENCES form_approvals(id) ON DELETE CASCADE,
    
    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created ON notifications(created_at DESC);

-- =============================================================================
-- PART 4: FORM SIGNATURES TABLE (Track all signatures on a form)
-- =============================================================================

CREATE TABLE IF NOT EXISTS form_signatures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_submission_id UUID NOT NULL REFERENCES form_submissions(id) ON DELETE CASCADE,
    
    -- Signer details
    signer_id UUID NOT NULL REFERENCES profiles(id),
    signer_name TEXT NOT NULL,
    signer_title TEXT, -- e.g., RSW, RPm
    signer_employee_id TEXT,
    
    -- Field this signature applies to
    field_name TEXT NOT NULL, -- e.g., 'prepared_by', 'noted_by', 'approved_by', 'center_head'
    field_label TEXT, -- Display label e.g., 'Prepared By', 'Noted By'
    
    -- Signature data
    signature_url TEXT NOT NULL,
    signed_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Auto-applied means it was applied automatically (e.g., creator's signature on 'prepared_by')
    is_auto_applied BOOLEAN DEFAULT FALSE,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint: one signature per field per form
    UNIQUE (form_submission_id, field_name)
);

-- Indexes for form_signatures
CREATE INDEX IF NOT EXISTS idx_form_signatures_form ON form_signatures(form_submission_id);
CREATE INDEX IF NOT EXISTS idx_form_signatures_signer ON form_signatures(signer_id);

-- =============================================================================
-- PART 5: UPDATE form_submissions TABLE
-- =============================================================================

-- Add column for tracking prepared_by signature (auto-applied on creation)
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS prepared_by_id UUID REFERENCES profiles(id);
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS prepared_by_name TEXT;
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS prepared_by_signature_url TEXT;
ALTER TABLE form_submissions ADD COLUMN IF NOT EXISTS prepared_at TIMESTAMPTZ;

-- =============================================================================
-- PART 6: HELPER FUNCTIONS
-- =============================================================================

-- Function to get all pending approvals for a user
CREATE OR REPLACE FUNCTION get_pending_approvals(p_user_id UUID)
RETURNS TABLE (
    approval_id UUID,
    form_id UUID,
    template_type TEXT,
    resident_name TEXT,
    sender_name TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        fa.id AS approval_id,
        fa.form_submission_id AS form_id,
        fs.template_type,
        r.first_name || ' ' || r.last_name AS resident_name,
        fa.sender_name,
        fa.created_at
    FROM form_approvals fa
    JOIN form_submissions fs ON fa.form_submission_id = fs.id
    JOIN residents r ON fs.resident_id = r.id
    WHERE fa.recipient_id = p_user_id
    AND fa.status = 'pending'
    ORDER BY fa.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- Function to create an approval request
CREATE OR REPLACE FUNCTION create_approval_request(
    p_form_id UUID,
    p_sender_id UUID,
    p_recipient_id UUID,
    p_signature_field TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_sender_name TEXT;
    v_recipient_name TEXT;
    v_approval_id UUID;
    v_form_template TEXT;
    v_resident_name TEXT;
BEGIN
    -- Get sender and recipient names
    SELECT full_name INTO v_sender_name FROM profiles WHERE id = p_sender_id;
    SELECT full_name INTO v_recipient_name FROM profiles WHERE id = p_recipient_id;
    
    -- Get form details for notification
    SELECT fs.template_type, r.first_name || ' ' || r.last_name
    INTO v_form_template, v_resident_name
    FROM form_submissions fs
    JOIN residents r ON fs.resident_id = r.id
    WHERE fs.id = p_form_id;
    
    -- Create approval request
    INSERT INTO form_approvals (
        form_submission_id,
        sender_id,
        sender_name,
        recipient_id,
        recipient_name,
        signature_field_name
    ) VALUES (
        p_form_id,
        p_sender_id,
        v_sender_name,
        p_recipient_id,
        v_recipient_name,
        p_signature_field
    ) RETURNING id INTO v_approval_id;
    
    -- Update form status
    UPDATE form_submissions 
    SET status = 'pending_review', 
        submitted_at = NOW(),
        updated_at = NOW()
    WHERE id = p_form_id;
    
    -- Create notification for recipient
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        form_submission_id,
        form_approval_id
    ) VALUES (
        p_recipient_id,
        'approval_request',
        'New Form Approval Request',
        v_sender_name || ' submitted a ' || REPLACE(v_form_template, '_', ' ') || ' for ' || v_resident_name || ' and needs your review.',
        p_form_id,
        v_approval_id
    );
    
    RETURN v_approval_id;
END;
$$ LANGUAGE plpgsql;

-- Function to approve a form
CREATE OR REPLACE FUNCTION approve_form(
    p_approval_id UUID,
    p_signature_url TEXT DEFAULT NULL,
    p_comment TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    v_approval RECORD;
    v_form_id UUID;
    v_sender_id UUID;
    v_recipient_name TEXT;
BEGIN
    -- Get approval details
    SELECT * INTO v_approval FROM form_approvals WHERE id = p_approval_id;
    
    IF v_approval IS NULL THEN
        RAISE EXCEPTION 'Approval request not found';
    END IF;
    
    -- Update approval
    UPDATE form_approvals SET
        status = 'approved',
        action_at = NOW(),
        comment = p_comment,
        signature_url = COALESCE(p_signature_url, signature_url),
        signature_applied = (p_signature_url IS NOT NULL OR signature_field_name IS NOT NULL),
        updated_at = NOW()
    WHERE id = p_approval_id
    RETURNING form_submission_id, sender_id, recipient_name INTO v_form_id, v_sender_id, v_recipient_name;
    
    -- Update form status
    UPDATE form_submissions SET
        status = 'approved',
        reviewed_by = v_approval.recipient_id,
        reviewed_at = NOW(),
        review_comment = p_comment,
        updated_at = NOW()
    WHERE id = v_form_id;
    
    -- If signature field specified, add to form_signatures
    IF v_approval.signature_field_name IS NOT NULL AND p_signature_url IS NOT NULL THEN
        INSERT INTO form_signatures (
            form_submission_id,
            signer_id,
            signer_name,
            field_name,
            signature_url,
            is_auto_applied
        ) VALUES (
            v_form_id,
            v_approval.recipient_id,
            v_approval.recipient_name,
            v_approval.signature_field_name,
            p_signature_url,
            FALSE
        ) ON CONFLICT (form_submission_id, field_name) 
        DO UPDATE SET
            signer_id = EXCLUDED.signer_id,
            signer_name = EXCLUDED.signer_name,
            signature_url = EXCLUDED.signature_url,
            signed_at = NOW();
    END IF;
    
    -- Notify sender
    INSERT INTO notifications (
        user_id,
        type,
        title,
        message,
        form_submission_id,
        form_approval_id
    ) VALUES (
        v_sender_id,
        'form_approved',
        'Form Approved',
        v_recipient_name || ' has approved your form submission.',
        v_form_id,
        p_approval_id
    );
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- PART 7: ROW LEVEL SECURITY POLICIES
-- =============================================================================

-- Enable RLS on new tables
ALTER TABLE form_approvals ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_signatures ENABLE ROW LEVEL SECURITY;

-- Policies for form_approvals
CREATE POLICY "Users can view approvals they sent or received"
    ON form_approvals FOR SELECT
    USING (sender_id = auth.uid() OR recipient_id = auth.uid());

CREATE POLICY "Users can create approval requests for forms they submitted"
    ON form_approvals FOR INSERT
    WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Recipients can update their approval requests"
    ON form_approvals FOR UPDATE
    USING (recipient_id = auth.uid());

-- Policies for notifications
CREATE POLICY "Users can view their own notifications"
    ON notifications FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications"
    ON notifications FOR UPDATE
    USING (user_id = auth.uid());

-- Policies for form_signatures
CREATE POLICY "Users can view signatures on forms they have access to"
    ON form_signatures FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM form_submissions fs
            WHERE fs.id = form_signatures.form_submission_id
            AND (fs.submitted_by = auth.uid() OR fs.reviewed_by = auth.uid())
        )
    );

CREATE POLICY "Users can add their own signature"
    ON form_signatures FOR INSERT
    WITH CHECK (signer_id = auth.uid());

-- =============================================================================
-- PART 8: UPDATE EXISTING SEED DATA WITH TITLES
-- =============================================================================

-- Update titles for existing users based on their roles
UPDATE profiles SET title = 'Admin' WHERE role = 'super_admin' AND title IS NULL;
UPDATE profiles SET title = 'Center Head' WHERE role = 'center_head' AND title IS NULL;
UPDATE profiles SET title = 'RSW' WHERE role = 'head' AND unit = 'social' AND title IS NULL;
UPDATE profiles SET title = 'RSW' WHERE role = 'staff' AND unit = 'social' AND title IS NULL;
UPDATE profiles SET title = 'MD' WHERE role = 'head' AND unit = 'medical' AND title IS NULL;
UPDATE profiles SET title = 'RN' WHERE role = 'staff' AND unit = 'medical' AND title IS NULL;
UPDATE profiles SET title = 'RPm' WHERE role = 'head' AND unit = 'psych' AND title IS NULL;
UPDATE profiles SET title = 'RPm' WHERE role = 'staff' AND unit = 'psych' AND title IS NULL;
UPDATE profiles SET title = 'RPT' WHERE role = 'head' AND unit = 'rehab' AND title IS NULL;
UPDATE profiles SET title = 'RPT' WHERE role = 'staff' AND unit = 'rehab' AND title IS NULL;
UPDATE profiles SET title = 'HLA' WHERE role = 'head' AND unit = 'homelife' AND title IS NULL;
UPDATE profiles SET title = 'HLA' WHERE role = 'staff' AND unit = 'homelife' AND title IS NULL;

-- =============================================================================
-- PART 9: COMMENTS AND DOCUMENTATION
-- =============================================================================

COMMENT ON TABLE form_approvals IS 'Tracks approval workflow for form submissions';
COMMENT ON TABLE notifications IS 'User notifications for approval requests and status updates';
COMMENT ON TABLE form_signatures IS 'Digital signatures applied to form fields';

COMMENT ON FUNCTION generate_employee_id() IS 'Auto-generates employee ID in format EMP-XXX on profile creation';
COMMENT ON FUNCTION get_pending_approvals(UUID) IS 'Returns all pending approval requests for a user';
COMMENT ON FUNCTION create_approval_request(UUID, UUID, UUID, TEXT) IS 'Creates an approval request and notifies the recipient';
COMMENT ON FUNCTION approve_form(UUID, TEXT, TEXT) IS 'Approves a form, applies signature if applicable, and notifies sender';

-- Print success message
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Migration 004 completed successfully!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'New features:';
    RAISE NOTICE '  - Title field added to profiles';
    RAISE NOTICE '  - Auto-incrementing Employee ID (EMP-XXX)';
    RAISE NOTICE '  - form_approvals table for workflow';
    RAISE NOTICE '  - notifications table for alerts';
    RAISE NOTICE '  - form_signatures table for digital sigs';
    RAISE NOTICE '  - Helper functions for approval workflow';
    RAISE NOTICE '==============================================';
END $$;
