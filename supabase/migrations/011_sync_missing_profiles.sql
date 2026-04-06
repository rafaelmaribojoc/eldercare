-- Migration: Sync Missing Profiles
-- This script creates profile records for users who exist in auth.users but are missing in public.profiles

INSERT INTO public.profiles (id, email, full_name, work_id, role, unit, is_active, created_at)
SELECT 
    id, 
    email, 
    COALESCE(raw_user_meta_data->>'full_name', 'Unknown User'), 
    COALESCE(raw_user_meta_data->>'work_id', 'REPAIR-' || SUBSTRING(id::text, 1, 8)), 
    COALESCE(raw_user_meta_data->>'role', 'social_staff'), 
    raw_user_meta_data->>'unit',
    true,
    COALESCE(created_at, NOW())
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles);

-- If someone was created manually without metadata, you might need to manually update their role later
-- This script at least makes them visible in the management list.
