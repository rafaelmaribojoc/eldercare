-- Migration: Digital Filing Cabinet - Archive support for case files
-- Adds soft-delete (archive) columns and RPC function for case completeness

-- 1. Add archive columns to form_submissions
ALTER TABLE form_submissions
  ADD COLUMN IF NOT EXISTS is_archived BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS archived_by UUID REFERENCES auth.users(id),
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_form_submissions_archived ON form_submissions(is_archived);

-- 2. Update existing RLS SELECT policy to exclude archived forms by default
-- Drop and recreate the main SELECT policy
DROP POLICY IF EXISTS "Users can view relevant forms" ON form_submissions;

CREATE POLICY "Users can view relevant active forms"
ON form_submissions FOR SELECT
USING (
    is_archived = false AND (
        submitted_by = auth.uid() OR
        (auth.jwt() -> 'user_metadata' ->> 'role') IN ('super_admin', 'center_head') OR
        (
            (auth.jwt() -> 'user_metadata' ->> 'role') LIKE '%_head' AND
            (auth.jwt() -> 'user_metadata' ->> 'unit') = form_submissions.unit
        ) OR
        (
            (auth.jwt() -> 'user_metadata' ->> 'unit') = form_submissions.unit
        )
    )
);

-- Separate policy for viewing archived forms (same visibility rules)
CREATE POLICY "Users can view archived forms"
ON form_submissions FOR SELECT
USING (
    is_archived = true AND (
        submitted_by = auth.uid() OR
        (auth.jwt() -> 'user_metadata' ->> 'role') IN ('super_admin', 'center_head') OR
        (
            (auth.jwt() -> 'user_metadata' ->> 'role') LIKE '%_head' AND
            (auth.jwt() -> 'user_metadata' ->> 'unit') = form_submissions.unit
        ) OR
        (
            (auth.jwt() -> 'user_metadata' ->> 'unit') = form_submissions.unit
        )
    )
);

-- 3. RPC function for case completeness dashboard
-- Returns aggregated completion data per resident for a given unit/status filter
CREATE OR REPLACE FUNCTION get_case_completeness(
    p_unit TEXT DEFAULT NULL,
    p_status TEXT DEFAULT NULL
)
RETURNS TABLE (
    resident_id UUID,
    resident_name TEXT,
    resident_status TEXT,
    form_count BIGINT,
    template_ids TEXT[]
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        r.id AS resident_id,
        (r.first_name || ' ' || r.last_name)::TEXT AS resident_name,
        r.status::TEXT AS resident_status,
        COUNT(fs.id) AS form_count,
        ARRAY_AGG(DISTINCT fs.template_id) FILTER (WHERE fs.template_id IS NOT NULL) AS template_ids
    FROM residents r
    LEFT JOIN form_submissions fs
        ON fs.resident_id = r.id
        AND fs.is_archived = false
    WHERE r.is_active = true
        AND (p_status IS NULL OR r.status = p_status)
        AND (p_unit IS NULL OR EXISTS (
            SELECT 1 FROM form_submissions fs2
            WHERE fs2.resident_id = r.id AND fs2.unit = p_unit AND fs2.is_archived = false
        ) OR NOT EXISTS (
            SELECT 1 FROM form_submissions fs3
            WHERE fs3.resident_id = r.id AND fs3.is_archived = false
        ))
    GROUP BY r.id, r.first_name, r.last_name, r.status
    ORDER BY resident_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
