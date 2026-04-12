-- Migration: 007_agent_memory.sql
-- Description: Creates the agent_memory table for storing agent execution memories
-- Created: 2026-04-11

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: agent_memory
-- Stores agent execution memories including job context, outcomes, and feedback.
-- Used for agent learning and performance tracking.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE agent_memory (
  id              uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  agent_id        bigint NOT NULL,
  client_address  text,
  job_id          text,
  job_type        text,
  memory_data     jsonb NOT NULL DEFAULT '{}',
  outcome_score   integer,
  chat_feedback   text,
  output_summary  text,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Index for fast lookups by agent_id (primary query pattern)
CREATE INDEX idx_agent_memory_agent_id ON agent_memory (agent_id);

-- Index for job-based queries
CREATE INDEX idx_agent_memory_job_id ON agent_memory (job_id);

-- Composite index for agent_id + created_at (common query pattern)
CREATE INDEX idx_agent_memory_agent_created ON agent_memory (agent_id, created_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- Row Level Security (RLS)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE agent_memory ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view memory for agents they own
CREATE POLICY ""agent_memory_select_policy""
  ON agent_memory FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.agents
      WHERE agents.id = agent_memory.agent_id
      AND agents.owner = auth.uid()::text
    )
  );

-- Policy: Users can insert memory for agents they own
CREATE POLICY ""agent_memory_insert_policy""
  ON agent_memory FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.agents
      WHERE agents.id = agent_memory.agent_id
      AND agents.owner = auth.uid()::text
    )
  );

-- Policy: Users can update memory for agents they own
CREATE POLICY ""agent_memory_update_policy""
  ON agent_memory FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.agents
      WHERE agents.id = agent_memory.agent_id
      AND agents.owner = auth.uid()::text
    )
  );

-- Policy: Users can delete memory for agents they own
CREATE POLICY ""agent_memory_delete_policy""
  ON agent_memory FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.agents
      WHERE agents.id = agent_memory.agent_id
      AND agents.owner = auth.uid()::text
    )
  );

COMMENT ON TABLE agent_memory IS 'Stores agent execution memories including job context, outcomes, feedback, and output summaries. Used for agent learning and performance tracking.';
