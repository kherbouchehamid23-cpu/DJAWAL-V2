-- =========================================================
-- DJAWAL V2 — Sprint 8 : Table contact_messages
-- =========================================================

CREATE TABLE IF NOT EXISTS contact_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  subject TEXT NOT NULL,
  message TEXT NOT NULL CHECK (length(message) BETWEEN 10 AND 5000),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'read', 'replied', 'archived')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_contact_messages_status ON contact_messages(status, created_at DESC);

ALTER TABLE contact_messages ENABLE ROW LEVEL SECURITY;

-- Insert public (anyone can send a message)
CREATE POLICY contact_messages_insert ON contact_messages FOR INSERT WITH CHECK (true);

-- Read: only admin
CREATE POLICY contact_messages_admin_read ON contact_messages FOR SELECT
  USING (current_user_role() = 'super_admin');

CREATE POLICY contact_messages_admin_update ON contact_messages FOR UPDATE
  USING (current_user_role() = 'super_admin');

COMMENT ON TABLE contact_messages IS 'Messages envoyés via le formulaire de contact public';
