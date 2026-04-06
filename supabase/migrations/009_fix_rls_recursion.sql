-- Description: Fix RLS recursion and optimize role checks using JWT metadata
-- This migration replaces expensive and potentially recursive EXISTS(SELECT 1 FROM profiles...) checks
-- with direct JWT metadata inspection.

-- 1. Profiles Table Policies
DROP POLICY IF EXISTS "Super admin can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Super admin can update any profile" ON profiles;

CREATE POLICY "Super admin can view all profiles"
ON profiles FOR SELECT
USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'super_admin');

CREATE POLICY "Super admin can update any profile"
ON profiles FOR UPDATE
USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'super_admin');

-- 2. Wards Table Policies
DROP POLICY IF EXISTS "Admins can manage wards" ON wards;

CREATE POLICY "Admins can manage wards"
ON wards FOR ALL
USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('super_admin', 'center_head')
);

-- 3. Residents Table Policies
DROP POLICY IF EXISTS "Social head can add residents" ON residents;
DROP POLICY IF EXISTS "Authorized users can update residents" ON residents;

CREATE POLICY "Social head can add residents"
ON residents FOR INSERT
WITH CHECK ((auth.jwt() -> 'user_metadata' ->> 'role') = 'social_head');

CREATE POLICY "Authorized users can update residents"
ON residents FOR UPDATE
USING ((auth.jwt() -> 'user_metadata' ->> 'role') IN ('super_admin', 'social_head'));

-- 4. Form Submissions Table Policies
DROP POLICY IF EXISTS "Users can view relevant forms" ON form_submissions;
DROP POLICY IF EXISTS "Unit heads can review forms" ON form_submissions;

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

-- 5. Audit Logs Table Policies
DROP POLICY IF EXISTS "Super admin can view audit logs" ON audit_logs;

CREATE POLICY "Super admin can view audit logs"
ON audit_logs FOR SELECT
USING ((auth.jwt() -> 'user_metadata' ->> 'role') = 'super_admin');
