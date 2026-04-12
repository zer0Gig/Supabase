-- Migration: 011_subscription_proposals.sql
-- Agents propose subscription terms to clients (off-chain proposal system)
-- After approval, client calls createSubscription on-chain

CREATE TABLE subscription_proposals (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_id        bigint NOT NULL,
  agent_wallet    text NOT NULL,
  client_address   text NOT NULL,          -- client who receives the proposal
  task_description text NOT NULL,          -- what the agent will do
  interval_seconds bigint NOT NULL,         -- check-in frequency
  check_in_rate   numeric NOT NULL,        -- OG per check-in
  alert_rate      numeric NOT NULL,        -- OG per alert
  grace_period    bigint NOT NULL,         -- grace period in seconds
  budget_og       numeric NOT NULL,         -- proposed initial budget
  webhook_url     text,                    -- optional webhook
  status          text NOT NULL DEFAULT 'pending',  -- pending | approved | rejected | expired
  metadata        jsonb DEFAULT '{}',      -- extra data (agent info, etc.)
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_proposals_client ON subscription_proposals(client_address);
CREATE INDEX idx_proposals_agent ON subscription_proposals(agent_id);
CREATE INDEX idx_proposals_status ON subscription_proposals(status);

-- RLS
ALTER TABLE subscription_proposals ENABLE ROW LEVEL SECURITY;

-- Anyone can insert proposals (agents proposing)
CREATE POLICY "Anyone can create proposals" ON subscription_proposals
  FOR INSERT WITH CHECK (true);

-- Clients can view proposals addressed to them
CREATE POLICY "Clients can view their proposals" ON subscription_proposals
  FOR SELECT USING (client_address = auth.uid()::text);

-- Clients can update (approve/reject) their proposals
CREATE POLICY "Clients can update their proposals" ON subscription_proposals
  FOR UPDATE USING (client_address = auth.uid()::text);

-- Public read for agents to see their own proposals
CREATE POLICY "Agents can view own proposals" ON subscription_proposals
  FOR SELECT USING (agent_wallet = auth.uid()::text);
