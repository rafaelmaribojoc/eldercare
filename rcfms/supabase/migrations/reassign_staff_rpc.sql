// NOTE: This SQL needs to be executed on the Supabase project
// It creates a function to bypass RLS for reassigning staff since Center Heads
// lack the REPLACE/UPDATE permission on the residents table for this specific action.

/*
CREATE OR REPLACE FUNCTION reassign_resident_staff(
  p_resident_id UUID,
  p_staff_id UUID,
  p_role TEXT 
) RETURNS void AS $$
BEGIN
  IF p_role = 'social_worker' THEN
    UPDATE public.residents SET social_worker_id = p_staff_id WHERE id = p_resident_id;
  ELSIF p_role = 'houseparent' THEN
    UPDATE public.residents SET houseparent_id = p_staff_id WHERE id = p_resident_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
*/
