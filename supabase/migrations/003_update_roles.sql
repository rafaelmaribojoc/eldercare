-- Migration: Update user roles to simplified structure
-- Based on Blueprint.md User Roles & Permissions

-- Drop the existing role constraint
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;

-- Add new simplified role constraint
-- Roles:
-- - super_admin: System Owner & Security, Exclusive User Provisioning
-- - center_head: Operational Oversight, View Global Digital Timeline
-- - head: Service Unit Heads (Reviewers) - associated with a unit
-- - staff: Service Staff (Frontline) - associated with a unit
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check CHECK (role IN (
    'super_admin',
    'center_head',
    'head',
    'staff',
    -- Legacy roles for backwards compatibility
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
));

-- Update existing users with legacy roles to new simplified roles
-- Convert *_head roles to 'head'
UPDATE profiles SET role = 'head' WHERE role IN (
    'social_head',
    'medical_head',
    'psych_head',
    'rehab_head',
    'homelife_head'
);

-- Convert *_staff roles to 'staff'
UPDATE profiles SET role = 'staff' WHERE role IN (
    'social_staff',
    'medical_staff',
    'psych_staff',
    'rehab_staff',
    'homelife_staff'
);

-- Update default role
ALTER TABLE profiles ALTER COLUMN role SET DEFAULT 'staff';

-- Comment on role column for documentation
COMMENT ON COLUMN profiles.role IS 'User role: super_admin (system owner), center_head (admin oversight), head (unit reviewer), staff (frontline worker)';
