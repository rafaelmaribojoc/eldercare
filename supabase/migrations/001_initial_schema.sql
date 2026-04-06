-- RCFMS Database Schema
-- Resident Care & Facility Management System

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

-- =============================================================================
-- PROFILES TABLE (Linked to Supabase Auth)
-- =============================================================================
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    work_id TEXT UNIQUE NOT NULL,
    username TEXT UNIQUE,
    role TEXT NOT NULL DEFAULT 'social_staff' CHECK (role IN (
        'super_admin',
        'center_head',
        'social_head',
        'medical_head',
        'psych_head',
        'rehab_head',
        'homelife_head',
        'social_staff',
        'medical_staff',
        'psych_staff',
        'rehab_staff',
        'homelife_staff'
    )),
    unit TEXT CHECK (unit IN ('social', 'medical', 'psych', 'rehab', 'homelife') OR unit IS NULL),
    signature_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_unit ON profiles(unit);
CREATE INDEX idx_profiles_work_id ON profiles(work_id);

-- =============================================================================
-- WARDS TABLE
-- =============================================================================
CREATE TABLE wards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    nfc_tag_id TEXT UNIQUE,
    capacity INTEGER DEFAULT 0,
    current_occupancy INTEGER DEFAULT 0,
    floor TEXT,
    building TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for NFC lookup
CREATE INDEX idx_wards_nfc_tag ON wards(nfc_tag_id);

-- =============================================================================
-- RESIDENTS TABLE
-- =============================================================================
CREATE TABLE residents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    middle_name TEXT,
    date_of_birth DATE NOT NULL,
    gender TEXT NOT NULL CHECK (gender IN ('male', 'female', 'other')),
    photo_url TEXT,
    ward_id UUID NOT NULL REFERENCES wards(id),
    room_number TEXT,
    bed_number TEXT,
    admission_date DATE NOT NULL,
    emergency_contact_name TEXT,
    emergency_contact_phone TEXT,
    emergency_contact_relation TEXT,
    medical_notes TEXT,
    allergies TEXT,
    primary_diagnosis TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id),
    
    -- Full text search column
    fts tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('english', coalesce(first_name, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(last_name, '')), 'A') ||
        setweight(to_tsvector('english', coalesce(middle_name, '')), 'B') ||
        setweight(to_tsvector('english', coalesce(primary_diagnosis, '')), 'C')
    ) STORED
);

-- Indexes
CREATE INDEX idx_residents_ward ON residents(ward_id);
CREATE INDEX idx_residents_active ON residents(is_active);
CREATE INDEX idx_residents_fts ON residents USING GIN(fts);

-- =============================================================================
-- FORM SUBMISSIONS TABLE
-- =============================================================================
CREATE TABLE form_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resident_id UUID NOT NULL REFERENCES residents(id),
    template_id TEXT NOT NULL,
    template_type TEXT NOT NULL CHECK (template_type IN (
        -- Social Service forms
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
        -- Home Life Service forms
        'inventory_admission',
        'inventory_discharge',
        'inventory_monthly',
        'incident_report',
        'out_on_pass',
        -- Psychological Service forms
        'group_sessions',
        'individual_sessions',
        'inter_service_referral',
        'initial_assessment',
        'psychometrician_report',
        -- Medical Service forms (future)
        'daily_vitals',
        'medical_abstract',
        -- Other forms
        'moca_p_scoring',
        'behavior_log',
        'therapy_session_notes',
        'daily_activity_log'
    )),
    unit TEXT NOT NULL CHECK (unit IN ('social', 'medical', 'psych', 'rehab', 'homelife')),
    form_data JSONB NOT NULL DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
        'draft',
        'submitted',
        'pending_review',
        'approved',
        'returned'
    )),
    submitted_by UUID NOT NULL REFERENCES profiles(id),
    submitted_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES profiles(id),
    reviewed_at TIMESTAMPTZ,
    review_comment TEXT,
    version INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_form_submissions_resident ON form_submissions(resident_id);
CREATE INDEX idx_form_submissions_status ON form_submissions(status);
CREATE INDEX idx_form_submissions_unit ON form_submissions(unit);
CREATE INDEX idx_form_submissions_submitted_by ON form_submissions(submitted_by);

-- =============================================================================
-- TIMELINE ENTRIES TABLE (Realtime Feed)
-- =============================================================================
CREATE TABLE timeline_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    resident_id UUID NOT NULL REFERENCES residents(id),
    entry_type TEXT NOT NULL CHECK (entry_type IN ('form', 'note', 'alert', 'milestone')),
    form_submission_id UUID REFERENCES form_submissions(id),
    form_template_type TEXT,
    unit TEXT NOT NULL CHECK (unit IN ('social', 'medical', 'psych', 'rehab', 'homelife')),
    title TEXT NOT NULL,
    description TEXT,
    metadata JSONB,
    created_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_timeline_entries_resident ON timeline_entries(resident_id);
CREATE INDEX idx_timeline_entries_unit ON timeline_entries(unit);
CREATE INDEX idx_timeline_entries_created_at ON timeline_entries(created_at DESC);

-- =============================================================================
-- AUDIT LOGS TABLE
-- =============================================================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id),
    action TEXT NOT NULL,
    table_name TEXT NOT NULL,
    record_id UUID,
    old_data JSONB,
    new_data JSONB,
    ip_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);

-- =============================================================================
-- FUNCTIONS
-- =============================================================================

-- Function to increment ward occupancy
CREATE OR REPLACE FUNCTION increment_ward_occupancy(ward_id_param UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE wards 
    SET current_occupancy = current_occupancy + 1,
        updated_at = NOW()
    WHERE id = ward_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement ward occupancy
CREATE OR REPLACE FUNCTION decrement_ward_occupancy(ward_id_param UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE wards 
    SET current_occupancy = GREATEST(0, current_occupancy - 1),
        updated_at = NOW()
    WHERE id = ward_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- [REMOVED] handle_new_user and on_auth_user_created trigger
-- The application code (AdminRepository) handles profile creation securely.
-- This prevents the "500 Database Error" caused by the trigger failing on simple inserts.

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE wards ENABLE ROW LEVEL SECURITY;
ALTER TABLE residents ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE timeline_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- ----- PROFILES POLICIES -----

-- Everyone can view active profiles
CREATE POLICY "Users can view active profiles"
ON profiles FOR SELECT
USING (is_active = true);

-- Super admin can view all profiles
CREATE POLICY "Super admin can view all profiles"
ON profiles FOR SELECT
USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'super_admin');

-- Users can update their own editable fields (username, signature_url)
CREATE POLICY "Users can update own editable fields"
ON profiles FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
    auth.uid() = id AND
    -- Cannot change locked fields
    full_name = (SELECT full_name FROM profiles WHERE id = auth.uid()) AND
    work_id = (SELECT work_id FROM profiles WHERE id = auth.uid())
);

-- Super admin can update any profile
CREATE POLICY "Super admin can update any profile"
ON profiles FOR UPDATE
USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'super_admin');

-- ----- WARDS POLICIES -----

-- Everyone can view active wards
CREATE POLICY "Everyone can view active wards"
ON wards FOR SELECT
USING (is_active = true);

-- Only super admin and center head can manage wards
CREATE POLICY "Admins can manage wards"
ON wards FOR ALL
USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('super_admin', 'center_head')
);

-- ----- RESIDENTS POLICIES -----

-- All authenticated users can view active residents
CREATE POLICY "Users can view active residents"
ON residents FOR SELECT
USING (is_active = true);

-- Only social head can add residents
CREATE POLICY "Social head can add residents"
ON residents FOR INSERT
WITH CHECK (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'social_head'
);

-- Social head and super admin can update residents
CREATE POLICY "Authorized users can update residents"
ON residents FOR UPDATE
USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('super_admin', 'social_head')
);

-- ----- FORM SUBMISSIONS POLICIES -----

-- Users can view forms they submitted or forms in their unit (for heads)
CREATE POLICY "Users can view relevant forms"
ON form_submissions FOR SELECT
USING (
    submitted_by = auth.uid() OR
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('super_admin', 'center_head') OR
    (
        (auth.jwt() -> 'user_metadata' ->> 'role') LIKE '%_head' AND 
        (auth.jwt() -> 'user_metadata' ->> 'unit') = form_submissions.unit
    )
);

-- Staff can create drafts
CREATE POLICY "Staff can create form drafts"
ON form_submissions FOR INSERT
WITH CHECK (
    submitted_by = auth.uid()
);

-- Staff can update their own drafts or returned forms
CREATE POLICY "Staff can update own drafts or returned forms"
ON form_submissions FOR UPDATE
USING (
    submitted_by = auth.uid() AND status IN ('draft', 'returned')
)
WITH CHECK (
    submitted_by = auth.uid()
);

-- Unit heads can update forms for review (approve/return)
CREATE POLICY "Unit heads can review forms"
ON form_submissions FOR UPDATE
USING (
    (
        (auth.jwt() -> 'user_metadata' ->> 'role') IN ('super_admin', 'center_head') OR
        (
            (auth.jwt() -> 'user_metadata' ->> 'role') LIKE '%_head' AND 
            (auth.jwt() -> 'user_metadata' ->> 'unit') = form_submissions.unit
        )
    ) AND status = 'pending_review'
);

-- ----- TIMELINE ENTRIES POLICIES -----

-- All authenticated users can view timeline entries
CREATE POLICY "Users can view timeline entries"
ON timeline_entries FOR SELECT
USING (true);

-- System/forms can create timeline entries
CREATE POLICY "Authorized users can create timeline entries"
ON timeline_entries FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND role LIKE '%_head'
    )
);

-- ----- AUDIT LOGS POLICIES -----

-- Only super admin can view audit logs
CREATE POLICY "Super admin can view audit logs"
ON audit_logs FOR SELECT
USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'super_admin'
);

-- =============================================================================
-- STORAGE BUCKETS (Run in Supabase Dashboard or via API)
-- =============================================================================
-- Note: These need to be created via Supabase Dashboard or API
-- 1. signatures (private) - for user signatures
-- 2. resident_photos (private) - for resident photos
-- 3. documents (private) - for generated PDFs

-- =============================================================================
-- INITIAL DATA
-- =============================================================================

-- Insert initial wards
INSERT INTO wards (name, description, capacity, floor, building) VALUES
('Ward A', 'General Care Ward', 20, '1', 'Main Building'),
('Ward B', 'Special Care Ward', 15, '1', 'Main Building'),
('Ward C', 'Memory Care Ward', 12, '2', 'Main Building'),
('Ward D', 'Rehabilitation Ward', 18, '2', 'Main Building');

-- Note: The first super admin user needs to be created via Supabase Dashboard
-- or through the backend API with proper authentication
