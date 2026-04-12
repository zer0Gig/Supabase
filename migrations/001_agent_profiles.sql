-- Migration: 001_agent_profiles.sql
-- Description: Creates the agent_profiles table for storing agent metadata and profile information
-- Created: 2026-04-11

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: agent_profiles
-- Stores profile information for agents including display name, avatar, bio, and metadata
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE agent_profiles (
  id          bigserial PRIMARY KEY,
  agent_id    bigint NOT NULL REFERENCES public.agents(id) ON DELETE CASCADE,
  owner_address text NOT NULL,
  display_name text,
  avatar_url  text,
  bio         text,
  metadata    jsonb NOT NULL DEFAULT '{}',
  tags        text[],
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Index for fast lookups by agent_id
CREATE INDEX idx_agent_profiles_agent_id ON agent_profiles (agent_id);

-- Index for owner-based queries
CREATE INDEX idx_agent_profiles_owner_address ON agent_profiles (owner_address);

-- ─────────────────────────────────────────────────────────────────────────────
-- Row Level Security (RLS)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE agent_profiles ENABLE ROW LEVEL SECURITY;

-- Policy: Owners can view their own agent profiles
CREATE POLICY ""agent_profiles_select_policy""
  ON agent_profiles FOR SELECT
  USING (
    auth.uid()::text = owner_address
    OR EXISTS (
      SELECT 1 FROM public.agents WHERE id = agent_profiles.agent_id AND owner = auth.uid()::text
    )
  );

-- Policy: Owners can insert their own agent profiles
CREATE POLICY ""agent_profiles_insert_policy""
  ON agent_profiles FOR INSERT
  WITH CHECK (auth.uid()::text = owner_address);

-- Policy: Owners can update their own agent profiles
CREATE POLICY ""agent_profiles_update_policy""
  ON agent_profiles FOR UPDATE
  USING (auth.uid()::text = owner_address)
  WITH CHECK (auth.uid()::text = owner_address);

-- Policy: Owners can delete their own agent profiles
CREATE POLICY ""agent_profiles_delete_policy""
  ON agent_profiles FOR DELETE
  USING (auth.uid()::text = owner_address);

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper Function: is_owner_or_agent
-- Returns true if the current user is the owner of the agent or the agent itself
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.is_owner_or_agent(profile_agent_id bigint)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS 
  SELECT EXISTS (
    SELECT 1 FROM public.agents
    WHERE id = profile_agent_id
    AND (owner = auth.uid()::text OR id = profile_agent_id)
  )
  OR auth.uid()::text = (
    SELECT owner_address FROM agent_profiles WHERE agent_id = profile_agent_id LIMIT 1
  )
;

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper Function: owner_exists
-- Returns true if the owner field contains a valid user reference
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.owner_exists()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS 
  SELECT EXISTS (
    SELECT 1 FROM agent_profiles WHERE owner_address = auth.uid()::text
  )
;

COMMENT ON TABLE agent_profiles IS 'Stores agent profile information including display name, avatar, bio, and custom metadata';
