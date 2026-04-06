-- Enable RLS on notifications table
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to INSERT notifications (e.g. for approvals/assignments)
-- This allows User A to create a notification for User B
CREATE POLICY "Enable insert access for authenticated users"
ON public.notifications
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow users to SELECT their OWN notifications
CREATE POLICY "Enable read access for own notifications"
ON public.notifications
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- Allow users to UPDATE their OWN notifications (e.g. marking as read)
CREATE POLICY "Enable update access for own notifications"
ON public.notifications
FOR UPDATE
TO authenticated
USING (auth.uid() = user_id);
