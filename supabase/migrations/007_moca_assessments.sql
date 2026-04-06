-- =============================================================================
-- Migration 007: MoCA Assessments Table
-- Create table for storing MoCA-P (Montreal Cognitive Assessment - Philippine Version)
-- =============================================================================

-- =============================================================================
-- MOCA ASSESSMENTS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS moca_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Relationships
    resident_id UUID NOT NULL REFERENCES residents(id) ON DELETE CASCADE,
    clinician_id UUID NOT NULL REFERENCES profiles(id),
    
    -- Resident info (denormalized for historical record)
    resident_name TEXT NOT NULL,
    resident_sex TEXT,
    resident_birthday DATE,
    education_years INTEGER DEFAULT 0,
    
    -- Assessment timing
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    -- Scoring
    total_score INTEGER NOT NULL DEFAULT 0,
    max_score INTEGER NOT NULL DEFAULT 30,
    education_adjustment BOOLEAN DEFAULT false,
    adjusted_score INTEGER GENERATED ALWAYS AS (
        CASE WHEN education_adjustment THEN LEAST(total_score + 1, max_score) ELSE total_score END
    ) STORED,
    
    -- Risk assessment
    risk_level TEXT,
    normal_probability DECIMAL(5,4),
    mci_probability DECIMAL(5,4),
    dementia_probability DECIMAL(5,4),
    
    -- Section results stored as JSONB
    section_results JSONB NOT NULL DEFAULT '{}',
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX idx_moca_assessments_resident ON moca_assessments(resident_id);
CREATE INDEX idx_moca_assessments_clinician ON moca_assessments(clinician_id);
CREATE INDEX idx_moca_assessments_completed_at ON moca_assessments(completed_at DESC);
CREATE INDEX idx_moca_assessments_risk_level ON moca_assessments(risk_level);

-- Enable RLS
ALTER TABLE moca_assessments ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- ROW LEVEL SECURITY POLICIES
-- =============================================================================

-- All authenticated psych unit staff can view assessments
CREATE POLICY "Psych staff can view moca assessments"
ON moca_assessments FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND (
            role IN ('super_admin', 'center_head', 'psych_head', 'psych_staff') OR
            unit = 'psych'
        )
    )
);

-- Psych staff can create assessments
CREATE POLICY "Psych staff can create moca assessments"
ON moca_assessments FOR INSERT
WITH CHECK (
    clinician_id = auth.uid() AND
    EXISTS (
        SELECT 1 FROM profiles
        WHERE id = auth.uid() AND (
            role IN ('super_admin', 'psych_head', 'psych_staff') OR
            unit = 'psych'
        )
    )
);

-- Clinicians can update their own assessments
CREATE POLICY "Clinicians can update own moca assessments"
ON moca_assessments FOR UPDATE
USING (clinician_id = auth.uid())
WITH CHECK (clinician_id = auth.uid());

-- =============================================================================
-- TRIGGER FOR UPDATED_AT
-- =============================================================================
CREATE OR REPLACE FUNCTION update_moca_assessment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_moca_assessment_updated
    BEFORE UPDATE ON moca_assessments
    FOR EACH ROW
    EXECUTE FUNCTION update_moca_assessment_timestamp();

-- =============================================================================
-- TIMELINE ENTRY INTEGRATION
-- =============================================================================
-- Function to create timeline entry when assessment is completed
CREATE OR REPLACE FUNCTION create_moca_timeline_entry()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create entry when assessment is completed
    IF NEW.completed_at IS NOT NULL AND OLD.completed_at IS NULL THEN
        INSERT INTO timeline_entries (
            resident_id,
            entry_type,
            unit,
            title,
            description,
            metadata,
            created_by
        ) VALUES (
            NEW.resident_id,
            'milestone',
            'psych',
            'MoCA-P Assessment Completed',
            'Score: ' || NEW.adjusted_score || '/30 - ' || COALESCE(NEW.risk_level, 'Assessment Complete'),
            jsonb_build_object(
                'assessment_id', NEW.id,
                'total_score', NEW.total_score,
                'adjusted_score', NEW.adjusted_score,
                'risk_level', NEW.risk_level,
                'education_adjustment', NEW.education_adjustment
            ),
            NEW.clinician_id
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trigger_moca_timeline_entry
    AFTER UPDATE ON moca_assessments
    FOR EACH ROW
    EXECUTE FUNCTION create_moca_timeline_entry();
