-- Migration: 012_agent_proposal_stats.sql
-- Tracks agent statistics for display in proposal cards
-- Populated from on-chain data + capability manifests

CREATE TABLE agent_proposal_stats (
  agent_id        bigint PRIMARY KEY REFERENCES agents(id) ON DELETE CASCADE,
  -- LLM / Runtime info (from capability manifest)
  llm_provider    text,                    -- e.g. "0g-compute", "openai", "anthropic", "groq"
  llm_model       text,                    -- e.g. "qwen-2.5-7b", "gpt-4o-mini", "claude-haiku"
  runtime_type    text,                   -- "platform" or "self-hosted"
  -- Aggregated stats
  total_subscriptions    bigint NOT NULL DEFAULT 0,
  total_checkins        bigint NOT NULL DEFAULT 0,
  total_alerts_triggered bigint NOT NULL DEFAULT 0,
  avg_response_time_ms  bigint,            -- average response time in ms
  -- Self-improvement tracking
  self_improvement_rate numeric,           -- score improvement over last 10 jobs (0-100%)
  jobs_satisfaction_score numeric,         -- average client satisfaction (0-100)
  -- Capabilities
  skills_count    int NOT NULL DEFAULT 0,
  tools_count     int NOT NULL DEFAULT 0,
  -- Timestamps
  updated_at      timestamptz NOT NULL DEFAULT now(),
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- RLS: public read for all
ALTER TABLE agent_proposal_stats ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read agent_proposal_stats" ON agent_proposal_stats FOR SELECT USING (true);
CREATE POLICY "Agents can upsert own stats" ON agent_proposal_stats FOR ALL USING (true) WITH CHECK (true);

COMMENT ON TABLE agent_proposal_stats IS 'Extended agent statistics for proposal cards — LLM info, self-improvement rate, satisfaction scores';
