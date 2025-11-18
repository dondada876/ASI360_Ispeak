-- =====================================================
-- ASI360 iSpeak - Complete Database Schema
-- Version: 1.0.0
-- Platform: Supabase (PostgreSQL 15+)
-- =====================================================
-- This schema implements a complete vendor communication
-- system with multilingual support, compliance tracking,
-- task management, and audit trails.
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For fuzzy text search

-- =====================================================
-- VENDOR PROFILES
-- =====================================================
CREATE TABLE vendor_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_name TEXT NOT NULL,
  primary_contact_name TEXT NOT NULL,

  -- Contact Information
  phone_number TEXT UNIQUE, -- For WhatsApp/SMS
  telegram_chat_id BIGINT UNIQUE, -- For Telegram users
  email TEXT,

  -- Communication Preferences
  preferred_channel TEXT DEFAULT 'whatsapp' CHECK (preferred_channel IN ('whatsapp', 'sms', 'telegram', 'email')),
  primary_language TEXT NOT NULL DEFAULT 'es', -- ISO 639-1 code (en, es, pt, zh, vi)

  -- Business Details
  cuisine_type TEXT,
  business_license_number TEXT,
  tax_id TEXT,

  -- Status Management
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'suspended', 'pending', 'offboarded')),
  suspension_reason TEXT,
  suspended_at TIMESTAMPTZ,

  -- Location & Timezone
  timezone TEXT DEFAULT 'America/Los_Angeles',
  location_identifier TEXT, -- e.g., "Stall A-12"

  -- WhatsApp Business API (if using direct API)
  whatsapp_business_id TEXT,
  whatsapp_phone_number_id TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  last_contact_at TIMESTAMPTZ,
  onboarded_at TIMESTAMPTZ,

  -- Flexible metadata for future expansion
  metadata JSONB DEFAULT '{}',

  -- Constraints
  CONSTRAINT vendor_contact_required CHECK (
    phone_number IS NOT NULL OR
    telegram_chat_id IS NOT NULL OR
    email IS NOT NULL
  )
);

-- Indexes for vendor_profiles
CREATE INDEX idx_vendor_phone ON vendor_profiles(phone_number) WHERE phone_number IS NOT NULL;
CREATE INDEX idx_vendor_telegram ON vendor_profiles(telegram_chat_id) WHERE telegram_chat_id IS NOT NULL;
CREATE INDEX idx_vendor_status ON vendor_profiles(status);
CREATE INDEX idx_vendor_language ON vendor_profiles(primary_language);
CREATE INDEX idx_vendor_business_name ON vendor_profiles USING gin(business_name gin_trgm_ops);

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_vendor_profiles_updated_at BEFORE UPDATE ON vendor_profiles
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- CONVERSATIONS (All Messages)
-- =====================================================
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,

  -- Message Direction & Channel
  direction TEXT NOT NULL CHECK (direction IN ('inbound', 'outbound')),
  channel TEXT NOT NULL CHECK (channel IN ('whatsapp', 'sms', 'telegram', 'email', 'voice')),

  -- Original Message
  original_text TEXT,
  original_language TEXT, -- Auto-detected or specified

  -- Translated Message
  translated_text TEXT,
  translated_language TEXT DEFAULT 'en',
  translation_confidence NUMERIC(3,2), -- 0.00 to 1.00

  -- Media Handling
  media_type TEXT CHECK (media_type IN ('audio', 'image', 'video', 'document', 'location')),
  media_url TEXT,
  media_transcription TEXT, -- For audio/video files
  media_file_id UUID, -- Reference to media_files table

  -- Message Metadata
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  failure_reason TEXT,

  -- External Message IDs (for tracking with providers)
  twilio_message_sid TEXT,
  telegram_message_id BIGINT,
  whatsapp_message_id TEXT,

  -- Context & Classification
  message_type TEXT CHECK (message_type IN ('inquiry', 'compliance', 'operational', 'payment', 'menu', 'emergency', 'general')),
  urgency_level TEXT DEFAULT 'normal' CHECK (urgency_level IN ('low', 'normal', 'high', 'critical')),
  sentiment TEXT CHECK (sentiment IN ('positive', 'neutral', 'negative', 'urgent')),

  -- Task Extraction (AI-powered)
  contains_action_item BOOLEAN DEFAULT FALSE,
  extracted_tasks JSONB DEFAULT '[]', -- Array of task objects
  ai_summary TEXT, -- Claude-generated summary
  ai_confidence NUMERIC(3,2),

  -- Threading (for conversation grouping)
  thread_id UUID, -- Group related messages
  reply_to_message_id UUID REFERENCES conversations(id),

  -- Audit Trail
  raw_webhook_data JSONB, -- Complete payload from provider
  processed_by TEXT DEFAULT 'system', -- 'system', 'user:name', 'ai'

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ
);

-- Indexes for conversations
CREATE INDEX idx_conversations_vendor ON conversations(vendor_id, sent_at DESC);
CREATE INDEX idx_conversations_unread ON conversations(vendor_id, read_at) WHERE read_at IS NULL;
CREATE INDEX idx_conversations_direction ON conversations(direction, sent_at DESC);
CREATE INDEX idx_conversations_channel ON conversations(channel);
CREATE INDEX idx_conversations_urgency ON conversations(urgency_level) WHERE urgency_level IN ('high', 'critical');
CREATE INDEX idx_conversations_action_items ON conversations(contains_action_item) WHERE contains_action_item = TRUE;
CREATE INDEX idx_conversations_thread ON conversations(thread_id) WHERE thread_id IS NOT NULL;
CREATE INDEX idx_conversations_text_search ON conversations USING gin(to_tsvector('english', translated_text));

-- =====================================================
-- TASKS (Extracted Action Items)
-- =====================================================
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL, -- Source message

  -- Task Details
  title TEXT NOT NULL,
  description TEXT,
  task_type TEXT NOT NULL CHECK (task_type IN (
    'insurance', 'payment', 'menu', 'permit', 'maintenance',
    'health_inspection', 'license', 'tax', 'training', 'other'
  )),

  -- Status & Tracking
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'overdue', 'cancelled', 'blocked')),
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'critical')),

  -- Deadlines & Completion
  due_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  estimated_hours NUMERIC(5,2),

  -- Assignment
  assigned_to TEXT, -- 'vendor', 'admin:nathan', 'admin:don', 'system'
  assigned_by TEXT DEFAULT 'system',
  assigned_at TIMESTAMPTZ,

  -- Automation
  auto_reminder_enabled BOOLEAN DEFAULT TRUE,
  reminder_schedule JSONB DEFAULT '["7d", "3d", "1d", "4h"]', -- Array: time before due_date
  last_reminder_sent_at TIMESTAMPTZ,
  next_reminder_at TIMESTAMPTZ,
  reminder_count INTEGER DEFAULT 0,

  -- Compliance Tracking
  is_compliance_requirement BOOLEAN DEFAULT FALSE,
  compliance_requirement_id UUID, -- Reference to compliance_requirements
  compliance_consequence TEXT, -- "Operations suspended until resolved"

  -- Blocking & Dependencies
  blocked_by TEXT, -- Reason task is blocked
  depends_on_task_id UUID REFERENCES tasks(id), -- Task dependency

  -- Attachments & Evidence
  attachment_urls JSONB DEFAULT '[]', -- Array of URLs
  completion_evidence_url TEXT,
  completion_notes TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Metadata
  metadata JSONB DEFAULT '{}'
);

-- Indexes for tasks
CREATE INDEX idx_tasks_vendor_status ON tasks(vendor_id, status, due_date);
CREATE INDEX idx_tasks_overdue ON tasks(due_date, status) WHERE status != 'completed' AND due_date < NOW();
CREATE INDEX idx_tasks_pending ON tasks(status) WHERE status IN ('pending', 'in_progress');
CREATE INDEX idx_tasks_compliance ON tasks(is_compliance_requirement) WHERE is_compliance_requirement = TRUE;
CREATE INDEX idx_tasks_assigned ON tasks(assigned_to);
CREATE INDEX idx_tasks_next_reminder ON tasks(next_reminder_at) WHERE auto_reminder_enabled = TRUE AND status != 'completed';

-- Trigger for tasks
CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- COMPLIANCE REQUIREMENTS (Templates)
-- =====================================================
CREATE TABLE compliance_requirements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requirement_type TEXT UNIQUE NOT NULL, -- 'insurance', 'health_permit', etc.
  display_name TEXT NOT NULL,
  description TEXT,

  -- Frequency & Timing
  frequency TEXT CHECK (frequency IN ('one_time', 'annual', 'semi_annual', 'quarterly', 'monthly', 'weekly')),
  advance_notice_days INTEGER DEFAULT 30, -- Remind X days before expiration
  grace_period_days INTEGER DEFAULT 0, -- Days after deadline before enforcement

  -- Escalation Schedule
  escalation_schedule JSONB DEFAULT '["30d", "14d", "7d", "3d", "1d", "4h", "0h"]',

  -- Multilingual Templates
  template_message_en TEXT,
  template_message_es TEXT,
  template_message_pt TEXT,
  template_message_zh TEXT,
  template_message_vi TEXT,

  -- Required Documents
  required_documents JSONB DEFAULT '[]', -- Array of document types
  document_validation_rules JSONB DEFAULT '{}', -- JSON schema for validation

  -- Consequence of Non-Compliance
  non_compliance_action TEXT DEFAULT 'suspend_operations' CHECK (non_compliance_action IN (
    'warning', 'suspend_operations', 'terminate_contract', 'fine', 'escalate_to_legal'
  )),
  fine_amount NUMERIC(10,2),

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  is_mandatory BOOLEAN DEFAULT TRUE,
  applies_to_all_vendors BOOLEAN DEFAULT TRUE,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Metadata
  metadata JSONB DEFAULT '{}'
);

-- Indexes for compliance_requirements
CREATE INDEX idx_compliance_req_active ON compliance_requirements(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_compliance_req_type ON compliance_requirements(requirement_type);

CREATE TRIGGER update_compliance_requirements_updated_at BEFORE UPDATE ON compliance_requirements
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VENDOR COMPLIANCE STATUS (Join Table)
-- =====================================================
CREATE TABLE vendor_compliance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  requirement_id UUID REFERENCES compliance_requirements(id) ON DELETE CASCADE,

  -- Status
  status TEXT DEFAULT 'not_submitted' CHECK (status IN (
    'not_submitted', 'pending_review', 'approved', 'expired', 'rejected', 'waived'
  )),

  -- Submission Details
  submitted_at TIMESTAMPTZ,
  submitted_by TEXT, -- Who submitted (vendor or admin)
  approved_at TIMESTAMPTZ,
  approved_by TEXT,
  rejected_at TIMESTAMPTZ,
  rejected_by TEXT,
  expires_at TIMESTAMPTZ,

  -- Document Storage
  document_url TEXT,
  document_urls JSONB DEFAULT '[]', -- Multiple documents
  document_metadata JSONB DEFAULT '{}',

  -- Review Notes
  admin_notes TEXT,
  rejection_reason TEXT,
  reviewer_checklist JSONB DEFAULT '{}',

  -- Automatic Reminders
  last_reminder_sent_at TIMESTAMPTZ,
  reminder_count INTEGER DEFAULT 0,

  -- Waiver (if applicable)
  waived_until TIMESTAMPTZ,
  waiver_reason TEXT,
  waiver_approved_by TEXT,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(vendor_id, requirement_id)
);

-- Indexes for vendor_compliance
CREATE INDEX idx_vendor_compliance_vendor ON vendor_compliance(vendor_id);
CREATE INDEX idx_vendor_compliance_status ON vendor_compliance(status);
CREATE INDEX idx_vendor_compliance_expires ON vendor_compliance(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_vendor_compliance_pending ON vendor_compliance(status, submitted_at) WHERE status = 'pending_review';
CREATE INDEX idx_vendor_compliance_expiring ON vendor_compliance(expires_at) WHERE status = 'approved' AND expires_at < NOW() + INTERVAL '30 days';

CREATE TRIGGER update_vendor_compliance_updated_at BEFORE UPDATE ON vendor_compliance
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- MEDIA FILES (Audio, Images, Documents)
-- =====================================================
CREATE TABLE media_files (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,

  -- File Details
  file_type TEXT NOT NULL CHECK (file_type IN ('audio', 'image', 'video', 'pdf', 'document', 'spreadsheet')),
  mime_type TEXT,
  file_size_bytes BIGINT,
  file_name TEXT,
  original_filename TEXT,

  -- Storage
  storage_provider TEXT DEFAULT 'backblaze' CHECK (storage_provider IN ('backblaze', 'google_drive', 'supabase', 'digitalocean_spaces')),
  storage_url TEXT NOT NULL, -- Public or signed URL
  storage_path TEXT, -- Internal path: /vendor-id/yyyy/mm/filename
  storage_bucket TEXT DEFAULT 'asi360-ispeak-media',

  -- Processing Status (for audio/video)
  transcription_status TEXT DEFAULT 'pending' CHECK (transcription_status IN ('pending', 'processing', 'completed', 'failed', 'skipped')),
  transcription_text TEXT,
  transcription_language TEXT,
  transcription_confidence NUMERIC(3,2),
  transcription_duration_seconds INTEGER,

  -- OCR Status (for images/PDFs)
  ocr_status TEXT DEFAULT 'pending' CHECK (ocr_status IN ('pending', 'processing', 'completed', 'failed', 'skipped')),
  ocr_text TEXT,
  ocr_confidence NUMERIC(3,2),

  -- Media Analysis (AI-powered)
  ai_analysis JSONB DEFAULT '{}', -- Object detection, content moderation, etc.
  contains_sensitive_info BOOLEAN DEFAULT FALSE,

  -- Timestamps
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  last_accessed_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ, -- For temporary signed URLs

  -- Access Control
  is_public BOOLEAN DEFAULT FALSE,
  access_granted_to JSONB DEFAULT '[]', -- Array of user IDs or roles

  -- Metadata
  metadata JSONB DEFAULT '{}' -- Duration, dimensions, codec, etc.
);

-- Indexes for media_files
CREATE INDEX idx_media_vendor ON media_files(vendor_id, uploaded_at DESC);
CREATE INDEX idx_media_conversation ON media_files(conversation_id);
CREATE INDEX idx_media_transcription_status ON media_files(transcription_status) WHERE transcription_status IN ('pending', 'processing');
CREATE INDEX idx_media_ocr_status ON media_files(ocr_status) WHERE ocr_status IN ('pending', 'processing');
CREATE INDEX idx_media_file_type ON media_files(file_type);

-- =====================================================
-- MESSAGE TEMPLATES
-- =====================================================
CREATE TABLE message_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_name TEXT UNIQUE NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('compliance', 'payment', 'operational', 'marketing', 'emergency', 'onboarding')),

  -- Multilingual Templates
  templates JSONB NOT NULL, -- { "en": "...", "es": "...", "pt": "...", "zh": "...", "vi": "..." }

  -- Variables (for personalization)
  variables JSONB DEFAULT '[]', -- ["vendor_name", "due_date", "amount"]

  -- Template Metadata
  description TEXT,
  usage_instructions TEXT,

  -- Usage Tracking
  usage_count INTEGER DEFAULT 0,
  last_used_at TIMESTAMPTZ,

  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  requires_approval BOOLEAN DEFAULT FALSE, -- Some templates need admin approval

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  created_by TEXT,

  -- Metadata
  metadata JSONB DEFAULT '{}'
);

-- Indexes for message_templates
CREATE INDEX idx_templates_category ON message_templates(category);
CREATE INDEX idx_templates_active ON message_templates(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_templates_name ON message_templates USING gin(template_name gin_trgm_ops);

CREATE TRIGGER update_message_templates_updated_at BEFORE UPDATE ON message_templates
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- SYSTEM EVENTS LOG (Audit Trail)
-- =====================================================
CREATE TABLE system_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type TEXT NOT NULL, -- 'message_sent', 'task_created', 'deadline_missed', 'vendor_suspended', etc.
  vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE SET NULL,
  related_id UUID, -- conversation_id, task_id, etc.
  related_table TEXT, -- 'conversations', 'tasks', etc.

  -- Event Details
  description TEXT NOT NULL,
  severity TEXT DEFAULT 'info' CHECK (severity IN ('debug', 'info', 'warning', 'error', 'critical')),

  -- Actor/Trigger
  triggered_by TEXT DEFAULT 'system', -- 'system', 'user:don', 'user:nathan', 'automation:n8n', 'ai:claude'
  user_agent TEXT,
  ip_address INET,

  -- Event Data
  event_data JSONB DEFAULT '{}', -- Full event payload
  previous_state JSONB, -- Before state (for updates)
  new_state JSONB, -- After state (for updates)

  -- Performance Tracking
  duration_ms INTEGER, -- How long the operation took

  -- Timestamp
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for system_events
CREATE INDEX idx_events_vendor ON system_events(vendor_id, created_at DESC);
CREATE INDEX idx_events_type ON system_events(event_type, created_at DESC);
CREATE INDEX idx_events_severity ON system_events(severity, created_at DESC) WHERE severity IN ('error', 'critical');
CREATE INDEX idx_events_triggered_by ON system_events(triggered_by);
CREATE INDEX idx_events_created ON system_events(created_at DESC);

-- Partitioning for system_events (optional, for high-volume environments)
-- CREATE TABLE system_events_2025_11 PARTITION OF system_events FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

-- =====================================================
-- ANALYTICS & REPORTING VIEWS
-- =====================================================

-- View: Vendor Response Time Analytics
CREATE OR REPLACE VIEW vendor_response_times AS
SELECT
  v.id AS vendor_id,
  v.business_name,
  COUNT(CASE WHEN c.direction = 'inbound' THEN 1 END) AS messages_received,
  COUNT(CASE WHEN c.direction = 'outbound' THEN 1 END) AS messages_sent,
  AVG(EXTRACT(EPOCH FROM (c.read_at - c.sent_at))) / 60 AS avg_response_time_minutes,
  MAX(c.sent_at) AS last_contact
FROM vendor_profiles v
LEFT JOIN conversations c ON c.vendor_id = v.id
WHERE c.sent_at > NOW() - INTERVAL '30 days'
GROUP BY v.id, v.business_name;

-- View: Compliance Dashboard
CREATE OR REPLACE VIEW compliance_dashboard AS
SELECT
  v.id AS vendor_id,
  v.business_name,
  v.status AS vendor_status,
  cr.requirement_type,
  cr.display_name AS requirement_name,
  vc.status AS compliance_status,
  vc.expires_at,
  CASE
    WHEN vc.expires_at IS NULL THEN NULL
    WHEN vc.expires_at < NOW() THEN 0
    ELSE EXTRACT(DAY FROM (vc.expires_at - NOW()))
  END AS days_until_expiration,
  vc.submitted_at,
  vc.approved_at
FROM vendor_profiles v
CROSS JOIN compliance_requirements cr
LEFT JOIN vendor_compliance vc ON vc.vendor_id = v.id AND vc.requirement_id = cr.id
WHERE cr.is_active = TRUE AND v.status = 'active'
ORDER BY v.business_name, cr.requirement_type;

-- View: Task Overview
CREATE OR REPLACE VIEW task_overview AS
SELECT
  v.id AS vendor_id,
  v.business_name,
  COUNT(*) FILTER (WHERE t.status = 'pending') AS pending_tasks,
  COUNT(*) FILTER (WHERE t.status = 'in_progress') AS in_progress_tasks,
  COUNT(*) FILTER (WHERE t.status = 'completed') AS completed_tasks,
  COUNT(*) FILTER (WHERE t.status = 'overdue') AS overdue_tasks,
  COUNT(*) FILTER (WHERE t.is_compliance_requirement = TRUE AND t.status != 'completed') AS compliance_tasks,
  MIN(t.due_date) FILTER (WHERE t.status NOT IN ('completed', 'cancelled')) AS next_deadline
FROM vendor_profiles v
LEFT JOIN tasks t ON t.vendor_id = v.id
WHERE v.status = 'active'
GROUP BY v.id, v.business_name;

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE vendor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE compliance_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_compliance ENABLE ROW LEVEL SECURITY;
ALTER TABLE media_files ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_events ENABLE ROW LEVEL SECURITY;

-- Admin full access policy (for service role)
CREATE POLICY "Admin full access" ON vendor_profiles FOR ALL USING (true);
CREATE POLICY "Admin full access" ON conversations FOR ALL USING (true);
CREATE POLICY "Admin full access" ON tasks FOR ALL USING (true);
CREATE POLICY "Admin full access" ON compliance_requirements FOR ALL USING (true);
CREATE POLICY "Admin full access" ON vendor_compliance FOR ALL USING (true);
CREATE POLICY "Admin full access" ON media_files FOR ALL USING (true);
CREATE POLICY "Admin full access" ON message_templates FOR ALL USING (true);
CREATE POLICY "Admin full access" ON system_events FOR ALL USING (true);

-- Vendor read-only access to their own data (if implementing vendor portal)
-- CREATE POLICY "Vendors see own data" ON vendor_profiles FOR SELECT USING (auth.uid()::text = id::text);
-- CREATE POLICY "Vendors see own messages" ON conversations FOR SELECT USING (auth.uid()::text = vendor_id::text);
-- ... (add similar policies for other tables if needed)

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================

-- Function: Calculate vendor compliance score (0-100)
CREATE OR REPLACE FUNCTION calculate_compliance_score(p_vendor_id UUID)
RETURNS INTEGER AS $$
DECLARE
  total_requirements INTEGER;
  approved_requirements INTEGER;
  score INTEGER;
BEGIN
  -- Count total active compliance requirements
  SELECT COUNT(*) INTO total_requirements
  FROM compliance_requirements
  WHERE is_active = TRUE AND is_mandatory = TRUE;

  -- Count approved compliance items for vendor
  SELECT COUNT(*) INTO approved_requirements
  FROM vendor_compliance vc
  JOIN compliance_requirements cr ON vc.requirement_id = cr.id
  WHERE vc.vendor_id = p_vendor_id
    AND vc.status = 'approved'
    AND cr.is_active = TRUE
    AND cr.is_mandatory = TRUE
    AND (vc.expires_at IS NULL OR vc.expires_at > NOW());

  -- Calculate score
  IF total_requirements = 0 THEN
    RETURN 100;
  ELSE
    score := (approved_requirements * 100) / total_requirements;
    RETURN score;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Update task status to overdue
CREATE OR REPLACE FUNCTION update_overdue_tasks()
RETURNS INTEGER AS $$
DECLARE
  updated_count INTEGER;
BEGIN
  UPDATE tasks
  SET status = 'overdue',
      updated_at = NOW()
  WHERE status IN ('pending', 'in_progress')
    AND due_date < NOW()
    AND due_date IS NOT NULL;

  GET DIAGNOSTICS updated_count = ROW_COUNT;
  RETURN updated_count;
END;
$$ LANGUAGE plpgsql;

-- Function: Get vendor statistics
CREATE OR REPLACE FUNCTION get_vendor_stats(p_vendor_id UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'vendor_id', p_vendor_id,
    'total_messages', (SELECT COUNT(*) FROM conversations WHERE vendor_id = p_vendor_id),
    'messages_last_30_days', (SELECT COUNT(*) FROM conversations WHERE vendor_id = p_vendor_id AND sent_at > NOW() - INTERVAL '30 days'),
    'open_tasks', (SELECT COUNT(*) FROM tasks WHERE vendor_id = p_vendor_id AND status NOT IN ('completed', 'cancelled')),
    'overdue_tasks', (SELECT COUNT(*) FROM tasks WHERE vendor_id = p_vendor_id AND status = 'overdue'),
    'compliance_score', calculate_compliance_score(p_vendor_id),
    'last_contact', (SELECT MAX(sent_at) FROM conversations WHERE vendor_id = p_vendor_id)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS FOR AUTOMATION
-- =====================================================

-- Trigger: Update vendor last_contact_at when message received
CREATE OR REPLACE FUNCTION update_vendor_last_contact()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE vendor_profiles
  SET last_contact_at = NEW.sent_at
  WHERE id = NEW.vendor_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_vendor_last_contact
AFTER INSERT ON conversations
FOR EACH ROW
EXECUTE FUNCTION update_vendor_last_contact();

-- Trigger: Log system event when vendor is suspended
CREATE OR REPLACE FUNCTION log_vendor_suspension()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'suspended' AND OLD.status != 'suspended' THEN
    INSERT INTO system_events (
      event_type, vendor_id, description, severity, triggered_by, event_data
    ) VALUES (
      'vendor_suspended',
      NEW.id,
      format('Vendor %s suspended. Reason: %s', NEW.business_name, NEW.suspension_reason),
      'warning',
      COALESCE(current_setting('app.current_user', true), 'system'),
      json_build_object('previous_status', OLD.status, 'new_status', NEW.status, 'reason', NEW.suspension_reason)
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_vendor_suspension
AFTER UPDATE ON vendor_profiles
FOR EACH ROW
EXECUTE FUNCTION log_vendor_suspension();

-- Trigger: Auto-create task from conversation if action item detected
CREATE OR REPLACE FUNCTION auto_create_task_from_conversation()
RETURNS TRIGGER AS $$
DECLARE
  task_data JSONB;
BEGIN
  IF NEW.contains_action_item = TRUE AND NEW.extracted_tasks IS NOT NULL THEN
    -- Loop through extracted tasks and create task records
    FOR task_data IN SELECT * FROM jsonb_array_elements(NEW.extracted_tasks)
    LOOP
      INSERT INTO tasks (
        vendor_id, conversation_id, title, description, task_type, priority, due_date, assigned_to
      ) VALUES (
        NEW.vendor_id,
        NEW.id,
        task_data->>'title',
        task_data->>'description',
        COALESCE(task_data->>'task_type', 'other'),
        COALESCE(task_data->>'priority', 'medium'),
        (task_data->>'due_date')::TIMESTAMPTZ,
        'vendor'
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_create_task
AFTER INSERT OR UPDATE ON conversations
FOR EACH ROW
EXECUTE FUNCTION auto_create_task_from_conversation();

-- =====================================================
-- SEED DATA: Compliance Requirements
-- =====================================================

INSERT INTO compliance_requirements (requirement_type, display_name, frequency, advance_notice_days, template_message_en, template_message_es) VALUES
('insurance_certificate', 'Insurance Certificate of Liability', 'annual', 30,
  'URGENT - Insurance Compliance Required\n\n{{vendor_name}},\n\nYour insurance certificate must include:\n- 500 Grand Ave LLC\n- 500 Grand Live LLC\n- People Park X\n\nREQUIRED BY: {{due_date}}\n\nWithout proper insurance, operations must cease per vendor agreement Section 7.2.',
  'URGENTE - Seguro Requerido\n\n{{vendor_name}},\n\nSu certificado de seguro debe incluir:\n- 500 Grand Ave LLC\n- 500 Grand Live LLC\n- People Park X\n\nREQUERIDO ANTES DE: {{due_date}}\n\nSin el seguro correcto, las operaciones deben cesar según acuerdo de vendedor Sección 7.2.'),

('health_permit', 'Health Department Permit', 'annual', 45,
  'Health Permit Renewal Required\n\n{{vendor_name}},\n\nYour health permit expires on {{expiration_date}}.\n\nPlease schedule inspection and submit renewed permit by {{due_date}}.',
  'Renovación de Permiso de Salud Requerida\n\n{{vendor_name}},\n\nSu permiso de salud vence el {{expiration_date}}.\n\nPor favor programe inspección y presente el permiso renovado antes de {{due_date}}.'),

('business_license', 'City Business License', 'annual', 30,
  'Business License Renewal\n\n{{vendor_name}},\n\nYour city business license needs renewal.\n\nDeadline: {{due_date}}',
  'Renovación de Licencia de Negocio\n\n{{vendor_name}},\n\nSu licencia de negocio de la ciudad necesita renovación.\n\nFecha límite: {{due_date}}'),

('menu_submission', 'Menu Items & Pricing', 'one_time', 0,
  'Menu Submission Required\n\n{{vendor_name}},\n\nPlease submit your complete menu with pricing.\n\nThis is required before operations can begin.',
  'Presentación de Menú Requerida\n\n{{vendor_name}},\n\nPor favor presente su menú completo con precios.\n\nEsto es requerido antes de que las operaciones puedan comenzar.');

-- =====================================================
-- SEED DATA: Message Templates
-- =====================================================

INSERT INTO message_templates (template_name, category, templates, variables) VALUES
('welcome_onboarding', 'onboarding',
  '{"en": "Welcome to 500 Grand Live!\n\nHi {{vendor_name}},\n\nWe''re excited to have you join us! This is your direct communication line with our operations team.\n\nYou can:\n- Send us messages in your preferred language\n- Upload documents (photos, PDFs)\n- Receive important updates\n\nReply to this message anytime. We''re here to help!\n\n- Don & Nathan", "es": "¡Bienvenido a 500 Grand Live!\n\nHola {{vendor_name}},\n\n¡Estamos emocionados de tenerte con nosotros! Esta es tu línea directa de comunicación con nuestro equipo de operaciones.\n\nPuedes:\n- Enviarnos mensajes en tu idioma preferido\n- Subir documentos (fotos, PDFs)\n- Recibir actualizaciones importantes\n\nResponde a este mensaje en cualquier momento. ¡Estamos aquí para ayudar!\n\n- Don & Nathan"}',
  '["vendor_name"]'),

('payment_reminder', 'payment',
  '{"en": "Payment Reminder\n\n{{vendor_name}},\n\nYour payment of ${{amount}} is due on {{due_date}}.\n\nPlease submit payment to avoid late fees.\n\nQuestions? Reply to this message.", "es": "Recordatorio de Pago\n\n{{vendor_name}},\n\nSu pago de ${{amount}} vence el {{due_date}}.\n\nPor favor envíe el pago para evitar cargos por demora.\n\n¿Preguntas? Responda a este mensaje."}',
  '["vendor_name", "amount", "due_date"]'),

('compliance_final_warning', 'compliance',
  '{"en": "FINAL NOTICE - Compliance Required\n\n{{vendor_name}},\n\nThis is your final notice for:\n{{requirement_name}}\n\nDeadline: {{due_date}}\n\nFailure to comply will result in suspension of operations per your vendor agreement.\n\nPlease contact us immediately.", "es": "AVISO FINAL - Cumplimiento Requerido\n\n{{vendor_name}},\n\nEste es su aviso final para:\n{{requirement_name}}\n\nFecha límite: {{due_date}}\n\nEl incumplimiento resultará en suspensión de operaciones según su acuerdo de vendedor.\n\nPor favor contáctenos inmediatamente."}',
  '["vendor_name", "requirement_name", "due_date"]');

-- =====================================================
-- DATABASE INITIALIZATION COMPLETE
-- =====================================================

-- Grant necessary permissions (adjust as needed)
-- GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
-- GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO authenticated;

-- Create a function to get database statistics
CREATE OR REPLACE FUNCTION get_database_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'vendors', (SELECT COUNT(*) FROM vendor_profiles),
    'active_vendors', (SELECT COUNT(*) FROM vendor_profiles WHERE status = 'active'),
    'total_messages', (SELECT COUNT(*) FROM conversations),
    'tasks', (SELECT COUNT(*) FROM tasks),
    'open_tasks', (SELECT COUNT(*) FROM tasks WHERE status NOT IN ('completed', 'cancelled')),
    'overdue_tasks', (SELECT COUNT(*) FROM tasks WHERE status = 'overdue'),
    'compliance_requirements', (SELECT COUNT(*) FROM compliance_requirements WHERE is_active = TRUE),
    'media_files', (SELECT COUNT(*) FROM media_files),
    'database_size', pg_size_pretty(pg_database_size(current_database()))
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- END OF SCHEMA
-- =====================================================
-- To verify installation, run: SELECT get_database_stats();
