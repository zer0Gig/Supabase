-- Migration: 006_agent_skills.sql
-- Description: Creates the agent_skills junction table for agent-skill relationships
-- Created: 2026-04-11

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: agent_skills
-- Junction table linking agents to their skills.
-- Each agent can have multiple skills with individual configuration.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE agent_skills (
  id          bigserial PRIMARY KEY,
  agent_id    bigint NOT NULL,
  skill_id    text NOT NULL REFERENCES skills(id) ON DELETE CASCADE,
  is_active   boolean NOT NULL DEFAULT true,
  config      jsonb NOT NULL DEFAULT '{}',
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (agent_id, skill_id)
);

-- Index for fast lookups by agent_id
CREATE INDEX idx_agent_skills_agent_id ON agent_skills (agent_id);

-- Index for fast lookups by skill_id
CREATE INDEX idx_agent_skills_skill_id ON agent_skills (skill_id);

-- Index for active skills filtering
CREATE INDEX idx_agent_skills_is_active ON agent_skills (is_active) WHERE is_active = true;

-- ─────────────────────────────────────────────────────────────────────────────
-- Row Level Security (RLS)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE agent_skills ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view skills for agents they own
CREATE POLICY ""agent_skills_select_policy""
  ON agent_skills FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.agents
      WHERE agents.id = agent_skills.agent_id
      AND agents.owner = auth.uid()::text
    )
  );

-- Policy: Users can add skills to agents they own
CREATE POLICY ""agent_skills_insert_policy""
  ON agent_skills FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.agents
      WHERE agents.id = agent_skills.agent_id
      AND agents.owner = auth.uid()::text
    )
  );

-- Policy: Users can update skills for agents they own
CREATE POLICY ""agent_skills_update_policy""
  ON agent_skills FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.agents
      WHERE agents.id = agent_skills.agent_id
      AND agents.owner = auth.uid()::text
    )
  );

-- Policy: Users can delete skills from agents they own
CREATE POLICY ""agent_skills_delete_policy""
  ON agent_skills FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.agents
      WHERE agents.id = agent_skills.agent_id
      AND agents.owner = auth.uid()::text
    )
  );

COMMENT ON TABLE agent_skills IS 'Junction table linking agents to their skills. Each agent-skill relationship has its own configuration and active status.';

-- ─────────────────────────────────────────────────────────────────────────────
-- Trigger: Auto-update updated_at timestamp
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS 
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
 LANGUAGE plpgsql;

CREATE TRIGGER update_agent_skills_updated_at
  BEFORE UPDATE ON agent_skills
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
