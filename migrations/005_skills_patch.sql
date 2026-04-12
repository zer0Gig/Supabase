-- ══════════════════════════════════════════════════════════════════════════════
-- Skills Table Patch — Add is_verified column + Seed Data
-- ══════════════════════════════════════════════════════════════════════════════
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ─────────────────────────────────────────────────────────────────────────────

-- Step 1: Add is_verified column (if not exists)
ALTER TABLE skills ADD COLUMN IF NOT EXISTS is_verified boolean NOT NULL DEFAULT false;

-- Step 2: Upsert verified skills (backend handler is implemented)
-- This uses ON CONFLICT to safely update existing rows
INSERT INTO skills (id, name, description, category, icon, tool_name, is_active, is_verified, config_schema) VALUES
  ('web_search',      'Web Search',      'Search the web for real-time information using Serper.dev API',                     'data',          '🔍', 'builtin', true, true,  '{"properties": {"apiKey": {"type": "string", "title": "Serper.dev API Key", "description": "Get a free key at serper.dev"}, "maxResults": {"type": "number", "title": "Max Results", "default": 5}}}'),
  ('http_fetch',      'HTTP Fetch',      'Call any public or private API endpoint from agent workflow',                       'data',          '🌐', 'builtin', true, true,  '{"properties": {"url": {"type": "string", "title": "Base URL"}, "method": {"type": "string", "title": "Method"}}}'),
  ('github_reader',   'GitHub Reader',   'Read files, repos, and issues from GitHub',                                       'code',          '🐙', 'builtin', true, true,  '{"properties": {"token": {"type": "string", "title": "GitHub Token (optional)"}, "repo": {"type": "string", "title": "Default Repo (optional)"}}}'),
  ('code_exec',       'Code Executor',   'Run real Python/JS/Go/Rust — the agent thinks AND executes code. Powered by Piston API.', 'code', '💻', 'builtin', true, true, '{"properties": {"language": {"type": "string", "title": "Language", "description": "python, javascript, typescript, ruby, go, rust, java, cpp, c, php, swift, kotlin"}, "code": {"type": "string", "title": "Default Script (optional)"}}}'),
  ('telegram_notify', 'Telegram Notify', 'Agent sends milestone cards and approve buttons to your Telegram',                   'communication', '✈️', 'builtin', true, true,  '{"properties": {"chatId": {"type": "string", "title": "Telegram Chat ID", "description": "Connect your Telegram to auto-fill"}}}')
ON CONFLICT (id) DO UPDATE SET
  description   = EXCLUDED.description,
  is_verified   = EXCLUDED.is_verified,
  tool_name     = EXCLUDED.tool_name,
  config_schema = EXCLUDED.config_schema,
  is_active     = EXCLUDED.is_active;

-- Step 3: Mark planned-but-not-implemented skills as NOT verified
INSERT INTO skills (id, name, description, category, icon, tool_name, is_active, is_verified, config_schema) VALUES
  ('csv_analyst',     'CSV Analyst',     'Upload or link a CSV — agent analyzes and visualizes it',                          'data',          '📊', 'http', false, false, '{}'),
  ('pdf_reader',      'PDF Reader',      'Extract and summarize text from PDF documents',                                  'media',         '📄', 'http', false, false, '{}'),
  ('image_gen',       'Image Generation', 'Generate images from text prompts via AI',                                        'media',         '🎨', 'http', false, false, '{"properties": {"apiKey": {"type": "string", "title": "Image Gen API Key"}}}'),
  ('sql_query',       'SQL Query',       'Run read-only SQL queries against a connected DB',                               'storage',       '🗄️', 'http', false, false, '{"properties": {"connectionUrl": {"type": "string", "title": "Database Connection URL"}}}'),
  ('whatsapp_notify', 'WhatsApp Notify', 'Send milestone updates via WhatsApp (Meta Cloud API)',                           'communication', '💬', 'http', false, false, '{"properties": {"accessToken": {"type": "string", "title": "Meta Access Token"}, "phoneNumberId": {"type": "string", "title": "Phone Number ID"}}}')
ON CONFLICT (id) DO UPDATE SET
  is_verified = EXCLUDED.is_verified,
  is_active   = EXCLUDED.is_active;

-- Verify
SELECT id, name, is_verified, is_active, tool_name FROM skills ORDER BY is_verified DESC, name;
