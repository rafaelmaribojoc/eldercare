-- RCFMS Seed Accounts
-- This file creates test user accounts for development and testing

-- =============================================================================
-- NOTE: For Supabase, users should be created through the Auth API or Dashboard
-- This seed file creates the profile entries directly for testing purposes
-- When using Supabase Dashboard, create users with these emails and the profiles
-- will be auto-created by the trigger, then update the profiles with this data.
-- =============================================================================

-- For local development with Supabase CLI, you can insert directly into auth.users
-- The password for all test accounts is: Test@123456

-- =============================================================================
-- SEED TEST USERS (Run these in Supabase Dashboard SQL Editor)
-- =============================================================================

-- Create test UUIDs for our seed users
DO $$
DECLARE
    v_super_admin_id UUID := '11111111-1111-1111-1111-111111111111';
    v_center_head_id UUID := '22222222-2222-2222-2222-222222222222';
    v_social_head_id UUID := '33333333-3333-3333-3333-333333333333';
    v_social_staff_id UUID := '44444444-4444-4444-4444-444444444444';
    v_homelife_head_id UUID := '55555555-5555-5555-5555-555555555555';
    v_homelife_staff_id UUID := '66666666-6666-6666-6666-666666666666';
    v_psych_head_id UUID := '77777777-7777-7777-7777-777777777777';
    v_psych_staff_id UUID := '88888888-8888-8888-8888-888888888888';
    v_medical_head_id UUID := '99999999-9999-9999-9999-999999999999';
    v_medical_staff_id UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
BEGIN
    -- Insert into auth.users (Supabase managed - needs proper setup)
    -- Note: In production, create users through Supabase Dashboard or Auth API
    
    -- For local Supabase CLI development, insert test users
    INSERT INTO auth.users (
        id,
        instance_id,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        role,
        aud
    ) VALUES
    -- Super Admin
    (
        v_super_admin_id,
        '00000000-0000-0000-0000-000000000000',
        'superadmin@rcfms.local',
        crypt('Test@123456', gen_salt('bf')),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"full_name": "Super Administrator", "work_id": "RCFMS-001", "role": "super_admin"}',
        NOW(),
        NOW(),
        'authenticated',
        'authenticated'
    ),
    -- Center Head
    (
        v_center_head_id,
        '00000000-0000-0000-0000-000000000000',
        'centerhead@rcfms.local',
        crypt('Test@123456', gen_salt('bf')),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"full_name": "Maria Santos", "work_id": "RCFMS-002", "role": "center_head"}',
        NOW(),
        NOW(),
        'authenticated',
        'authenticated'
    ),
    -- Social Head
    (
        v_social_head_id,
        '00000000-0000-0000-0000-000000000000',
        'socialhead@rcfms.local',
        crypt('Test@123456', gen_salt('bf')),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"full_name": "Juan Dela Cruz", "work_id": "RCFMS-003", "role": "social_head"}',
        NOW(),
        NOW(),
        'authenticated',
        'authenticated'
    ),
    -- Social Staff
    (
        v_social_staff_id,
        '00000000-0000-0000-0000-000000000000',
        'socialstaff@rcfms.local',
        crypt('Test@123456', gen_salt('bf')),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"full_name": "Ana Reyes", "work_id": "RCFMS-004", "role": "social_staff"}',
        NOW(),
        NOW(),
        'authenticated',
        'authenticated'
    ),
    -- Homelife Head
    (
        v_homelife_head_id,
        '00000000-0000-0000-0000-000000000000',
        'homelifehead@rcfms.local',
        crypt('Test@123456', gen_salt('bf')),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"full_name": "Roberto Garcia", "work_id": "RCFMS-005", "role": "homelife_head"}',
        NOW(),
        NOW(),
        'authenticated',
        'authenticated'
    ),
    -- Homelife Staff
    (
        v_homelife_staff_id,
        '00000000-0000-0000-0000-000000000000',
        'homelifestaff@rcfms.local',
        crypt('Test@123456', gen_salt('bf')),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"full_name": "Carmen Lim", "work_id": "RCFMS-006", "role": "homelife_staff"}',
        NOW(),
        NOW(),
        'authenticated',
        'authenticated'
    ),
    -- Psych Head
    (
        v_psych_head_id,
        '00000000-0000-0000-0000-000000000000',
        'psychhead@rcfms.local',
        crypt('Test@123456', gen_salt('bf')),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"full_name": "Dr. Elena Torres", "work_id": "RCFMS-007", "role": "psych_head"}',
        NOW(),
        NOW(),
        'authenticated',
        'authenticated'
    ),
    -- Psych Staff
    (
        v_psych_staff_id,
        '00000000-0000-0000-0000-000000000000',
        'psychstaff@rcfms.local',
        crypt('Test@123456', gen_salt('bf')),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"full_name": "Michael Tan", "work_id": "RCFMS-008", "role": "psych_staff"}',
        NOW(),
        NOW(),
        'authenticated',
        'authenticated'
    ),
    -- Medical Head
    (
        v_medical_head_id,
        '00000000-0000-0000-0000-000000000000',
        'medicalhead@rcfms.local',
        crypt('Test@123456', gen_salt('bf')),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"full_name": "Dr. Ricardo Mendoza", "work_id": "RCFMS-009", "role": "medical_head"}',
        NOW(),
        NOW(),
        'authenticated',
        'authenticated'
    ),
    -- Medical Staff
    (
        v_medical_staff_id,
        '00000000-0000-0000-0000-000000000000',
        'medicalstaff@rcfms.local',
        crypt('Test@123456', gen_salt('bf')),
        NOW(),
        '{"provider": "email", "providers": ["email"]}',
        '{"full_name": "Nurse Patricia Yu", "work_id": "RCFMS-010", "role": "medical_staff"}',
        NOW(),
        NOW(),
        'authenticated',
        'authenticated'
    )
    ON CONFLICT (id) DO NOTHING;

    -- The trigger should auto-create profiles, but let's ensure they exist with correct data
    -- Update profiles with unit assignments
    UPDATE profiles SET unit = NULL WHERE id = v_super_admin_id;
    UPDATE profiles SET unit = NULL WHERE id = v_center_head_id;
    UPDATE profiles SET unit = 'social' WHERE id IN (v_social_head_id, v_social_staff_id);
    UPDATE profiles SET unit = 'homelife' WHERE id IN (v_homelife_head_id, v_homelife_staff_id);
    UPDATE profiles SET unit = 'psych' WHERE id IN (v_psych_head_id, v_psych_staff_id);
    UPDATE profiles SET unit = 'medical' WHERE id IN (v_medical_head_id, v_medical_staff_id);

EXCEPTION
    WHEN others THEN
        -- If auth.users insertion fails (common in hosted Supabase), 
        -- just log and continue - users should be created via Dashboard
        RAISE NOTICE 'Could not insert into auth.users directly. Please create users via Supabase Dashboard.';
END $$;

-- =============================================================================
-- SEED TEST RESIDENTS
-- =============================================================================

-- Insert test residents (linked to Ward A by default)
INSERT INTO residents (
    id,
    first_name,
    last_name,
    middle_name,
    date_of_birth,
    gender,
    ward_id,
    room_number,
    bed_number,
    admission_date,
    emergency_contact_name,
    emergency_contact_phone,
    emergency_contact_relation,
    medical_notes,
    allergies,
    primary_diagnosis,
    is_active
) VALUES
(
    'a1111111-1111-1111-1111-111111111111',
    'Lola',
    'Fernandez',
    'Santos',
    '1945-03-15',
    'female',
    (SELECT id FROM wards WHERE name = 'Ward A' LIMIT 1),
    '101',
    'A',
    '2024-01-15',
    'Maria Fernandez',
    '+63 912 345 6789',
    'Daughter',
    'Mild hypertension, controlled with medication',
    'Penicillin',
    'Age-related cognitive decline',
    true
),
(
    'a2222222-2222-2222-2222-222222222222',
    'Lolo',
    'Reyes',
    'Cruz',
    '1940-07-22',
    'male',
    (SELECT id FROM wards WHERE name = 'Ward A' LIMIT 1),
    '102',
    'A',
    '2024-02-20',
    'Pedro Reyes Jr.',
    '+63 917 654 3210',
    'Son',
    'Diabetes Type 2, insulin dependent',
    'Sulfa drugs',
    'Stroke recovery',
    true
),
(
    'a3333333-3333-3333-3333-333333333333',
    'Nanay',
    'Garcia',
    'Lim',
    '1948-11-08',
    'female',
    (SELECT id FROM wards WHERE name = 'Ward B' LIMIT 1),
    '201',
    'B',
    '2024-03-10',
    'Jose Garcia',
    '+63 918 765 4321',
    'Son',
    'Arthritis, requires wheelchair assistance',
    'None known',
    'Osteoarthritis',
    true
),
(
    'a4444444-4444-4444-4444-444444444444',
    'Tatay',
    'Santos',
    'Dela Cruz',
    '1942-05-30',
    'male',
    (SELECT id FROM wards WHERE name = 'Ward B' LIMIT 1),
    '202',
    'A',
    '2024-04-05',
    'Carmen Santos',
    '+63 919 876 5432',
    'Wife',
    'Heart condition, pacemaker installed',
    'Aspirin',
    'Cardiac arrhythmia',
    true
),
(
    'a5555555-5555-5555-5555-555555555555',
    'Aling',
    'Torres',
    'Mendoza',
    '1950-09-12',
    'female',
    (SELECT id FROM wards WHERE name = 'Ward C' LIMIT 1),
    '301',
    'A',
    '2024-05-18',
    'Elena Torres',
    '+63 920 987 6543',
    'Daughter',
    'Early stage dementia, requires supervision',
    'Shellfish',
    'Alzheimer''s disease - early onset',
    true
)
ON CONFLICT (id) DO NOTHING;

-- Update ward occupancy based on residents
UPDATE wards w SET current_occupancy = (
    SELECT COUNT(*) FROM residents r WHERE r.ward_id = w.id AND r.is_active = true
);

-- =============================================================================
-- MANUAL SETUP INSTRUCTIONS (for hosted Supabase)
-- =============================================================================
/*
If the automatic user creation above fails (common with hosted Supabase),
create users manually in the Supabase Dashboard with these credentials:

| Email                      | Password     | Role          | Unit      |
|---------------------------|--------------|---------------|-----------|
| superadmin@rcfms.local    | Test@123456  | super_admin   | -         |
| centerhead@rcfms.local    | Test@123456  | center_head   | -         |
| socialhead@rcfms.local    | Test@123456  | social_head   | social    |
| socialstaff@rcfms.local   | Test@123456  | social_staff  | social    |
| homelifehead@rcfms.local  | Test@123456  | homelife_head | homelife  |
| homelifestaff@rcfms.local | Test@123456  | homelife_staff| homelife  |
| psychhead@rcfms.local     | Test@123456  | psych_head    | psych     |
| psychstaff@rcfms.local    | Test@123456  | psych_staff   | psych     |
| medicalhead@rcfms.local   | Test@123456  | medical_head  | medical   |
| medicalstaff@rcfms.local  | Test@123456  | medical_staff | medical   |

After creating users in Dashboard:
1. Go to Authentication > Users
2. Click "Add user" > "Create new user"
3. Enter email and password
4. The trigger will auto-create profiles
5. Run this SQL to update the profiles with correct data:

UPDATE profiles SET 
    full_name = 'Super Administrator',
    work_id = 'RCFMS-001',
    role = 'super_admin'
WHERE email = 'superadmin@rcfms.local';

-- Repeat for other users...
*/

-- =============================================================================
-- CREATE IDENTITIES FOR AUTH USERS (Required for Supabase Auth)
-- =============================================================================
INSERT INTO auth.identities (
    id,
    user_id,
    identity_data,
    provider,
    provider_id,
    last_sign_in_at,
    created_at,
    updated_at
)
SELECT 
    id,
    id,
    jsonb_build_object('sub', id::text, 'email', email),
    'email',
    id::text,
    NOW(),
    NOW(),
    NOW()
FROM auth.users
WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333',
    '44444444-4444-4444-4444-444444444444',
    '55555555-5555-5555-5555-555555555555',
    '66666666-6666-6666-6666-666666666666',
    '77777777-7777-7777-7777-777777777777',
    '88888888-8888-8888-8888-888888888888',
    '99999999-9999-9999-9999-999999999999',
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
)
ON CONFLICT DO NOTHING;

-- Print success message
DO $$
BEGIN
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'RCFMS Seed Data Created Successfully!';
    RAISE NOTICE '==============================================';
    RAISE NOTICE 'Test Accounts (Password: Test@123456):';
    RAISE NOTICE '  - superadmin@rcfms.local (Super Admin)';
    RAISE NOTICE '  - centerhead@rcfms.local (Center Head)';
    RAISE NOTICE '  - socialhead@rcfms.local (Social Head)';
    RAISE NOTICE '  - socialstaff@rcfms.local (Social Staff)';
    RAISE NOTICE '  - homelifehead@rcfms.local (Homelife Head)';
    RAISE NOTICE '  - homelifestaff@rcfms.local (Homelife Staff)';
    RAISE NOTICE '  - psychhead@rcfms.local (Psych Head)';
    RAISE NOTICE '  - psychstaff@rcfms.local (Psych Staff)';
    RAISE NOTICE '  - medicalhead@rcfms.local (Medical Head)';
    RAISE NOTICE '  - medicalstaff@rcfms.local (Medical Staff)';
    RAISE NOTICE '==============================================';
END $$;
