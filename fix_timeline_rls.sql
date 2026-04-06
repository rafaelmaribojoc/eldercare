-- Enable RLS on timeline_entries if not already enabled (good practice)
ALTER TABLE timeline_entries ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view ALL timeline entries
-- (Or you can restrict it further, but for now let's ensure they can see them)
CREATE POLICY "Enable read access for authenticated users"
ON public.timeline_entries
FOR SELECT
TO authenticated
USING (true);

-- Allow authenticated users to INSERT timeline entries (needed for Resident Admissions from frontend)
CREATE POLICY "Enable insert access for authenticated users"
ON public.timeline_entries
FOR INSERT
TO authenticated
WITH CHECK (true);


