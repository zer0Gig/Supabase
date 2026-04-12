-- Migration: 005_skills.sql
-- Description: Creates the skills catalog table for storing available agent skills
-- Created: 2026-04-11

-- ─────────────────────────────────────────────────────────────────────────────
-- Table: skills
-- Catalog of available skills that agents can possess.
-- Each skill has an ID, name, description, category, and optional tool configuration.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE skills (
  id            text PRIMARY KEY,
  name          text NOT NULL,
  description   text,
  category      text,
  icon          text,
  tool_name     text,
  config_schema jsonb NOT NULL DEFAULT '{}',
  is_active     boolean NOT NULL DEFAULT true,
  is_verified   boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now()
);

-- Index for fast lookups by category
CREATE INDEX idx_skills_category ON skills (category);

-- Index for active skills filtering
CREATE INDEX idx_skills_is_active ON skills (is_active) WHERE is_active = true;

-- ─────────────────────────────────────────────────────────────────────────────
-- Row Level Security (RLS)
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE skills ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view active skills (public read access)
CREATE POLICY "skills_select_policy"
  ON skills FOR SELECT
  USING (is_active = true);

-- Policy: Only authenticated users can manage skills (admin function)
CREATE POLICY "skills_insert_policy"
  ON skills FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);

-- Policy: Only authenticated users can update skills
CREATE POLICY "skills_update_policy"
  ON skills FOR UPDATE
  USING (auth.uid() IS NOT NULL);

-- Policy: Only authenticated users can delete skills
CREATE POLICY "skills_delete_policy"
  ON skills FOR DELETE
  USING (auth.uid() IS NOT NULL);

COMMENT ON TABLE skills IS 'Catalog of available skills that agents can possess. Skills have an ID, name, description, category, icon, and optional tool configuration.';

-- ─────────────────────────────────────────────────────────────────────────────
-- Seed Data: Pre-built skills available to all agents
-- ─────────────────────────────────────────────────────────────────────────────

-- IMPORTANT: is_verified = true means the backend handler is implemented.
-- Skills with is_verified = false are planned but not yet implemented.

INSERT INTO skills (id, name, description, category, icon, tool_name, is_verified, config_schema) VALUES
  -- === VERIFIED: Backend handler implemented ===
  ('web_search',      'Web Search',      'Search the web for real-time information using Serper.dev API',                    'data',          '🔍', 'builtin', true,  '{"properties": {"apiKey": {"type": "string", "title": "Serper.dev API Key", "description": "Get a free key at serper.dev"}, "maxResults": {"type": "number", "title": "Max Results", "default": 5}}}'),
  ('http_fetch',      'HTTP Fetch',      'Call any public or private API endpoint from agent workflow',                      'data',          '🌐', 'builtin', true,  '{"properties": {"url": {"type": "string", "title": "Base URL", "description": "e.g. https://api.example.com/endpoint"}, "method": {"type": "string", "title": "Method"}}}'),
  ('github_reader',   'GitHub Reader',   'Read files, repos, and issues from GitHub',                                          'code',          '🐙', 'builtin', true,  '{"properties": {"token": {"type": "string", "title": "GitHub Token (optional)", "description": "Increases API rate limit from 60 to 5000 req/hr"}, "repo": {"type": "string", "title": "Default Repo (optional)"}}}'),
  ('code_exec',       'Code Executor',   'Run real Python/JS/Go/Rust — the agent thinks AND executes code. Powered by Piston API.', 'code', '💻', 'builtin', true, '{"properties": {"language": {"type": "string", "title": "Language", "description": "python, javascript, typescript, ruby, go, rust, java, cpp, c, php, swift, kotlin"}, "code": {"type": "string", "title": "Default Script (optional)"}}}'),
  ('telegram_notify', 'Telegram Notify', 'Agent sends milestone cards and approve buttons to your Telegram',                  'communication', '✈️', 'builtin', true,  '{"properties": {"chatId": {"type": "string", "title": "Telegram Chat ID", "description": "Connect your Telegram to auto-fill"}}}'),

  -- === NOT VERIFIED: Planned but backend handler not yet implemented ===
  ('csv_analyst',     'CSV Analyst',      'Upload or link a CSV — agent analyzes and visualizes it',                           'data',          '📊', 'http',    false, '{}'),
  ('pdf_reader',      'PDF Reader',       'Extract and summarize text from PDF documents',                                    'media',         '📄', 'http',    false, '{}'),
  ('image_gen',       'Image Generation', 'Generate images from text prompts via AI',                                         'media',         '🎨', 'http',    false, '{"properties": {"apiKey": {"type": "string", "title": "Image Gen API Key"}}}'),
  ('sql_query',       'SQL Query',        'Run read-only SQL queries against a connected DB',                                 'storage',       '🗄️', 'http',    false, '{"properties": {"connectionUrl": {"type": "string", "title": "Database Connection URL"}}}'),
  ('whatsapp_notify', 'WhatsApp Notify', 'Send milestone updates via WhatsApp (Meta Cloud API)',                              'communication', '💬', 'http',    false, '{"properties": {"accessToken": {"type": "string", "title": "Meta Access Token"}, "phoneNumberId": {"type": "string", "title": "Phone Number ID"}}}')
ON CONFLICT (id) DO UPDATE SET
  description = EXCLUDED.description,
  config_schema = EXCLUDED.config_schema,
  is_verified = EXCLUDED.is_verified,
  tool_name = EXCLUDED.tool_name;
