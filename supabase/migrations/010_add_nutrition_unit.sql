-- Migration: Add Nutrition and Dietetics Service support
-- This migration updates the CHECK constraints for profiles, form_submissions, and timeline_entries

-- 1. Update profiles table constraints
ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_role_check CHECK (role IN (
    'super_admin',
    'center_head',
    'social_head',
    'medical_head',
    'psych_head',
    'rehab_head',
    'homelife_head',
    'nutrition_head',
    'social_staff',
    'medical_staff',
    'psych_staff',
    'rehab_staff',
    'homelife_staff',
    'nutrition_staff'
));

ALTER TABLE profiles DROP CONSTRAINT IF EXISTS profiles_unit_check;
ALTER TABLE profiles ADD CONSTRAINT profiles_unit_check CHECK (unit IN ('social', 'medical', 'psych', 'rehab', 'homelife', 'nutrition') OR unit IS NULL);

-- 2. Update form_submissions table constraints
ALTER TABLE form_submissions DROP CONSTRAINT IF EXISTS form_submissions_unit_check;
ALTER TABLE form_submissions ADD CONSTRAINT form_submissions_unit_check CHECK (unit IN ('social', 'medical', 'psych', 'rehab', 'homelife', 'nutrition'));

-- 3. Update timeline_entries table constraints
ALTER TABLE timeline_entries DROP CONSTRAINT IF EXISTS timeline_entries_unit_check;
ALTER TABLE timeline_entries ADD CONSTRAINT timeline_entries_unit_check CHECK (unit IN ('social', 'medical', 'psych', 'rehab', 'homelife', 'nutrition'));
