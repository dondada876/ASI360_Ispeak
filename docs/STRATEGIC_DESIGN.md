# Bilingual Vendor Communication System - Strategic Design Document

## Executive Summary

Building a **scalable, multi-vendor, multi-language communication hub** that serves as operational middleware between you (English) and vendors (any language). This is not just a translation tool—it's a **compliance engine, task tracker, and institutional memory system** that grows with your food hall.

---

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    COMMUNICATION ORCHESTRATOR                    │
│                     (Core MCP Server + N8N)                      │
└────────────┬────────────────────────────────────────────┬───────┘
             │                                              │
    ┌────────▼────────┐                          ┌─────────▼────────┐
    │  INPUT CHANNELS │                          │ OUTPUT CHANNELS  │
    │  - WhatsApp Bus │                          │  - Airtable      │
    │  - SMS          │                          │  - Supabase      │
    │  - Email        │                          │  - Google Drive  │
    │  - Voice/Audio  │                          │  - Dashboard     │
    └────────┬────────┘                          └─────────┬────────┘
             │                                              │
    ┌────────▼──────────────────────────────────────────────▼───────┐
    │              TRANSLATION & PROCESSING LAYER                    │
    │  - DeepL API (multi-language)                                 │
    │  - AssemblyAI (audio transcription + language detection)      │
    │  - Anthropic Claude (context understanding + task extraction) │
    └────────┬──────────────────────────────────────────────────────┘
             │
    ┌────────▼────────────────────────────────────────────────────┐
    │                    CORE DATABASE SCHEMA                      │
    │                      (Supabase PostgreSQL)                   │
    │  - vendor_profiles                                           │
    │  - conversations (all messages, all languages)               │
    │  - tasks (extracted action items)                            │
    │  - compliance_requirements                                   │
    │  - media_files (audio, images, documents)                    │
    └──────────────────────────────────────────────────────────────┘
```

---

## Core Design Principles

### 1. **Vendor-Agnostic Architecture**
- One system handles unlimited vendors
- Each vendor = profile with language preference
- No per-vendor customization needed
- Add new vendor in 30 seconds

### 2. **Channel-Based Communication** (NOT groups)
- Each vendor gets **dedicated phone number** (Twilio)
- All messages to that number → system intercepts → processes → logs
- You see unified dashboard, not 50 WhatsApp chats
- Vendors text "their number" (feels 1-on-1, actually centralized)

### 3. **Language as Metadata** (not hardcoded)
- System auto-detects language from first message
- Supports: Spanish, Portuguese, Mandarin, Vietnamese, Tagalog, etc.
- You always see English translation
- Vendor always sees their native language
- Switch languages mid-conversation (auto-detected)

### 4. **Compliance-First Design**
- Every message = potential legal evidence
- Immutable audit trail
- Automatic task extraction: "need insurance by Friday" → task created
- Deadline tracking with auto-escalation
- Read receipts + response time analytics

---

## Database Schema Design (Supabase PostgreSQL)

### Why Supabase over Airtable as primary DB?

**Supabase Advantages:**
- True relational database (foreign keys, joins, transactions)
- Real-time subscriptions (live dashboard updates)
- Row-level security (vendor can't see other vendors' data)
- Unlimited storage with Backblaze integration
- PostgREST API (instant REST endpoints)
- **Airtable becomes the "review interface"** (synced from Supabase)

**Airtable Role:**
- Visual dashboard for Don's review
- Quick edits and manual overrides
- Kanban views for task management
- Synced FROM Supabase (one-way or two-way depending on needs)

---

### Core Schema

```sql
-- =====================================================
-- VENDOR PROFILES
-- =====================================================
CREATE TABLE vendor_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  business_name TEXT NOT NULL,
  primary_contact_name TEXT NOT NULL,
  phone_number TEXT UNIQUE NOT NULL, -- Their dedicated line
  email TEXT,
  primary_language TEXT NOT NULL, -- ISO 639-1 code (es, pt, zh, vi)
  whatsapp_business_id TEXT, -- If using WhatsApp Business API
  status TEXT DEFAULT 'active', -- active, suspended, offboarded
  timezone TEXT DEFAULT 'America/Los_Angeles',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  metadata JSONB -- Flexible: cuisine_type, operating_hours, etc.
);

-- =====================================================
-- CONVERSATIONS (All Messages)
-- =====================================================
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendor_profiles(id),
  direction TEXT NOT NULL, -- 'inbound' or 'outbound'
  channel TEXT NOT NULL, -- 'whatsapp', 'sms', 'email', 'voice'
  
  -- Original Message
  original_text TEXT,
  original_language TEXT, -- Auto-detected
  
  -- Translated Message
  translated_text TEXT,
  translated_language TEXT DEFAULT 'en',
  
  -- Media Handling
  media_type TEXT, -- 'audio', 'image', 'document', null
  media_url TEXT, -- Cloud storage URL
  media_transcription TEXT, -- For audio files
  
  -- Metadata
  sent_at TIMESTAMPTZ DEFAULT NOW(),
  delivered_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  
  -- Context & Classification
  message_type TEXT, -- 'inquiry', 'compliance', 'operational', 'payment'
  urgency_level TEXT DEFAULT 'normal', -- 'low', 'normal', 'high', 'critical'
  
  -- Task Extraction (AI-powered)
  contains_action_item BOOLEAN DEFAULT FALSE,
  extracted_tasks JSONB, -- Array of task objects
  
  -- Full audit trail
  raw_webhook_data JSONB, -- Complete payload from Twilio/WhatsApp
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast lookups
CREATE INDEX idx_conversations_vendor ON conversations(vendor_id, sent_at DESC);
CREATE INDEX idx_conversations_unread ON conversations(vendor_id, read_at) WHERE read_at IS NULL;

-- =====================================================
-- TASKS (Extracted Action Items)
-- =====================================================
CREATE TABLE tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendor_profiles(id),
  conversation_id UUID REFERENCES conversations(id), -- Source message
  
  -- Task Details
  title TEXT NOT NULL, -- "Submit insurance certificate"
  description TEXT,
  task_type TEXT NOT NULL, -- 'insurance', 'payment', 'menu', 'permit', 'maintenance'
  
  -- Status & Tracking
  status TEXT DEFAULT 'pending', -- 'pending', 'in_progress', 'completed', 'overdue', 'cancelled'
  priority TEXT DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'
  
  -- Deadlines
  due_date TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  
  -- Assignment
  assigned_to TEXT, -- 'vendor', 'nathan', 'don', 'system'
  
  -- Automation
  auto_reminder_enabled BOOLEAN DEFAULT TRUE,
  reminder_schedule JSONB, -- Array: ['24h_before', '4h_before', 'at_deadline']
  last_reminder_sent_at TIMESTAMPTZ,
  
  -- Compliance Tracking
  is_compliance_requirement BOOLEAN DEFAULT FALSE,
  compliance_consequence TEXT, -- "Operations suspended until resolved"
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tasks_vendor_status ON tasks(vendor_id, status, due_date);
CREATE INDEX idx_tasks_overdue ON tasks(due_date) WHERE status != 'completed' AND due_date < NOW();

-- =====================================================
-- COMPLIANCE REQUIREMENTS (Templates)
-- =====================================================
CREATE TABLE compliance_requirements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  requirement_type TEXT UNIQUE NOT NULL, -- 'insurance', 'health_permit', 'business_license', 'menu_submission'
  display_name TEXT NOT NULL,
  description TEXT,
  
  -- Frequency
  frequency TEXT, -- 'one_time', 'annual', 'quarterly', 'monthly'
  advance_notice_days INTEGER DEFAULT 30, -- Remind X days before expiration
  
  -- Escalation
  escalation_schedule JSONB, -- When to escalate: ['7_days', '3_days', '1_day', 'deadline']
  
  -- Templates
  template_message_en TEXT, -- English template
  template_message_es TEXT, -- Spanish template
  template_message_pt TEXT, -- Portuguese template
  -- (Add more languages as needed)
  
  -- Consequence
  non_compliance_action TEXT DEFAULT 'suspend_operations',
  
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed Data Example
INSERT INTO compliance_requirements (requirement_type, display_name, frequency, advance_notice_days) VALUES
('insurance_certificate', 'Insurance Certificate of Liability', 'annual', 30),
('health_permit', 'Health Department Permit', 'annual', 45),
('business_license', 'City Business License', 'annual', 30),
('menu_submission', 'Menu Items & Pricing', 'one_time', 0);

-- =====================================================
-- VENDOR COMPLIANCE STATUS (Join Table)
-- =====================================================
CREATE TABLE vendor_compliance (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendor_profiles(id),
  requirement_id UUID REFERENCES compliance_requirements(id),
  
  -- Status
  status TEXT DEFAULT 'not_submitted', -- 'not_submitted', 'pending_review', 'approved', 'expired', 'rejected'
  
  -- Submission
  submitted_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  
  -- Document Storage
  document_url TEXT, -- Link to Google Drive / Backblaze
  document_metadata JSONB,
  
  -- Notes
  admin_notes TEXT,
  rejection_reason TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(vendor_id, requirement_id)
);

-- =====================================================
-- MEDIA FILES (Audio, Images, Documents)
-- =====================================================
CREATE TABLE media_files (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES conversations(id),
  vendor_id UUID REFERENCES vendor_profiles(id),
  
  -- File Details
  file_type TEXT NOT NULL, -- 'audio', 'image', 'pdf', 'document'
  mime_type TEXT,
  file_size_bytes BIGINT,
  
  -- Storage
  storage_provider TEXT DEFAULT 'backblaze', -- 'backblaze', 'google_drive', 'supabase'
  storage_url TEXT NOT NULL, -- Public or signed URL
  storage_path TEXT, -- Internal path for organization
  
  -- Processing Status (for audio)
  transcription_status TEXT DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
  transcription_text TEXT,
  transcription_language TEXT,
  
  -- Metadata
  original_filename TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW(),
  processed_at TIMESTAMPTZ,
  
  metadata JSONB -- Duration (audio), dimensions (image), etc.
);

CREATE INDEX idx_media_vendor ON media_files(vendor_id, uploaded_at DESC);

-- =====================================================
-- COMMUNICATION TEMPLATES
-- =====================================================
CREATE TABLE message_templates (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  template_name TEXT UNIQUE NOT NULL,
  category TEXT NOT NULL, -- 'compliance', 'payment', 'operational', 'marketing'
  
  -- Multilingual Templates
  templates JSONB NOT NULL, -- { "en": "...", "es": "...", "pt": "..." }
  
  -- Variables (for personalization)
  variables JSONB, -- ["vendor_name", "due_date", "amount"]
  
  -- Usage
  usage_count INTEGER DEFAULT 0,
  last_used_at TIMESTAMPTZ,
  
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Example Template
INSERT INTO message_templates (template_name, category, templates, variables) VALUES (
  'insurance_final_notice',
  'compliance',
  '{
    "en": "URGENT - Insurance Compliance Required\n\n{{vendor_name}},\n\nYour insurance certificate does not include required additional insureds:\n- 500 Grand Ave LLC\n- 500 Grand Live LLC\n- People Park X\n\nREQUIRED BY: {{due_date}}\n\nWithout proper insurance by deadline, operations must cease per Section 7.2 of vendor agreement.",
    "es": "URGENTE - Seguro Requerido\n\n{{vendor_name}},\n\nSu certificado de seguro no incluye los asegurados adicionales requeridos:\n- 500 Grand Ave LLC\n- 500 Grand Live LLC\n- People Park X\n\nREQUERIDO ANTES DE: {{due_date}}\n\nSin el seguro correcto antes del plazo, las operaciones deben cesar según Sección 7.2 del acuerdo de vendedor."
  }',
  '["vendor_name", "due_date"]'
);

-- =====================================================
-- SYSTEM EVENTS LOG (Audit Trail)
-- =====================================================
CREATE TABLE system_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_type TEXT NOT NULL, -- 'message_sent', 'task_created', 'deadline_missed', 'vendor_suspended'
  vendor_id UUID REFERENCES vendor_profiles(id),
  related_id UUID, -- conversation_id, task_id, etc.
  
  -- Event Details
  description TEXT NOT NULL,
  severity TEXT DEFAULT 'info', -- 'info', 'warning', 'error', 'critical'
  
  -- Actor
  triggered_by TEXT DEFAULT 'system', -- 'system', 'user:don', 'user:nathan', 'automation'
  
  -- Metadata
  event_data JSONB,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_events_vendor ON system_events(vendor_id, created_at DESC);
CREATE INDEX idx_events_critical ON system_events(severity, created_at DESC) WHERE severity IN ('error', 'critical');
```

---

## Media Storage Strategy

### Decision Matrix: Where to Store Audio Files

| Storage Option | Cost | Pros | Cons | Recommendation |
|---------------|------|------|------|----------------|
| **WhatsApp (Keep)** | Free | Simple, already there | 30-day expiration, no control | ❌ No - Legal risk |
| **Supabase Storage** | $0.021/GB | Integrated with DB, CDN | Costs scale with usage | ✅ Good for <10GB/month |
| **Backblaze B2** | $0.005/GB | Cheapest, unlimited | Requires separate integration | ✅ **Best for scale** |
| **Google Drive** | $1.99/100GB | Easy sharing with Don | Manual organization, slow API | ⚠️ Backup only |

### **RECOMMENDATION: Hybrid Approach**

```
┌─────────────────────────────────────────────────────┐
│                  MEDIA FLOW                         │
└─────────────────────────────────────────────────────┘

1. Audio received via WhatsApp
   ↓
2. Immediately download to N8N temp storage (30 sec retention)
   ↓
3. Upload to BACKBLAZE B2 (primary storage)
   - Path: /vendor-media/{vendor_id}/{YYYY}/{MM}/{filename}
   - Retention: Permanent (legal compliance)
   - Cost: ~$0.50/month for 100 audio files
   ↓
4. Store URL in Supabase `media_files` table
   ↓
5. Send to AssemblyAI for transcription
   ↓
6. Transcription saved in Supabase `media_files.transcription_text`
   ↓
7. OPTIONAL: Weekly sync to Google Drive for Don's review
   - Path: "500 Grand Vendor Communications/Audio Archive/"
   - Organized by vendor + date
```

### Backblaze B2 Setup

**Bucket Structure:**
```
500grand-vendor-media/
├── audio/
│   ├── como-en-casa-colombia/
│   │   ├── 2025/
│   │   │   ├── 11/
│   │   │   │   ├── 20251117_143022_olga_insurance.m4a
│   │   │   │   └── 20251117_143022_transcription.txt
├── images/
│   ├── como-en-casa-colombia/
│   │   └── menu-items/
│   │       ├── bandeja-paisa.jpg
│   │       └── empanadas.jpg
├── documents/
    ├── como-en-casa-colombia/
        └── insurance-certificates/
            └── 20251119_certificate.pdf
```

**Cost Example:**
- 500 audio files/month @ 2MB each = 1GB
- 200 images @ 5MB each = 1GB
- 50 PDFs @ 1MB each = 50MB
- **Total: 2.05GB/month = $0.10/month storage + $0.01 download = $0.11/month**

---

## Communication Channel Architecture

### Why Dedicated Phone Numbers (NOT WhatsApp Groups)

**Proposed Structure:**

```
500 Grand Parking Main: (510) 288-8654
  ↓
Vendor-Specific Numbers (Twilio):
├── Como En Casa Colombia: (510) 555-0101 → Olga texts this
├── Future Vendor 2: (510) 555-0102
├── Future Vendor 3: (510) 555-0103
└── ... (add unlimited vendors)

Each number → WhatsApp Business API → N8N Webhook → System Processing
```

**Why This Works:**

1. **Vendor Experience:**
   - Olga saves "(510) 555-0101" as "500 Grand Parking"
   - Texts like normal 1-on-1 conversation
   - No app downloads, no group confusion
   - Feels personal, actually centralized

2. **Your Experience:**
   - Single dashboard shows all vendor conversations
   - Click "Como En Casa" → see full history
   - Reply from dashboard → auto-translated → sent to vendor
   - No context switching between 50 WhatsApp chats

3. **Scalability:**
   - Add vendor = provision new Twilio number (60 seconds)
   - No per-vendor code changes
   - System handles routing automatically

4. **Compliance:**
   - Each number = separate audit trail
   - Legal discovery: "Show all communications with Vendor X"
   - Easy to suspend/archive vendor communication

### Twilio vs WhatsApp Business API

| Feature | Twilio (SMS + WhatsApp) | WhatsApp Business API (Direct) |
|---------|-------------------------|-------------------------------|
| **Setup Complexity** | Easy (24 hours) | Complex (2-4 weeks approval) |
| **Cost per Message** | $0.0079 SMS + $0.005 WhatsApp | $0.005-0.01 WhatsApp only |
| **Phone Numbers** | Easy to provision | Requires Facebook verification |
| **SMS Fallback** | Yes (critical) | No |
| **Rich Media** | Yes | Yes |
| **Two-way Messaging** | Yes | Yes |

**RECOMMENDATION: Start with Twilio → Migrate to WhatsApp Business API later**

**Reasoning:**
- Twilio gets you operational in 1-2 days
- WhatsApp Business API requires Facebook Business verification (2-4 weeks)
- SMS fallback critical for vendors without smartphones/data
- Can migrate later without changing vendor-facing numbers (Twilio supports both)

---

## N8N Workflow Architecture

### Core Workflows

#### **Workflow 1: Inbound Message Processing**

```
WEBHOOK: Twilio Receives Message
  ↓
IF: Contains Media (audio/image)?
  YES →
    ├─ Download media file
    ├─ Upload to Backblaze B2
    ├─ IF audio: Send to AssemblyAI for transcription
    ├─ Store media record in Supabase
    └─ Extract media URL for later use
  NO → Continue
  ↓
LOOKUP: Vendor profile by phone number
  ↓
DETECT: Language of message (DeepL or AssemblyAI)
  ↓
TRANSLATE: To English (if not already)
  ↓
ANTHROPIC CLAUDE: Analyze message
  - Extract intent (compliance, payment, operational question)
  - Identify urgency level
  - Extract action items → create tasks
  - Detect if deadline mentioned
  - Classify message type
  ↓
STORE: In Supabase `conversations` table
  - original_text + original_language
  - translated_text (EN)
  - extracted_tasks (JSON)
  - urgency_level
  - AI-generated summary
  ↓
IF: Contains action item?
  YES →
    CREATE: Task in `tasks` table
    ├─ Extract due date (or set based on urgency)
    ├─ Assign priority
    ├─ Set auto-reminder schedule
    └─ Link to conversation_id
  ↓
IF: Compliance-related?
  YES →
    UPDATE: `vendor_compliance` status
    LOG: System event
  ↓
NOTIFY: Dashboard (real-time via Supabase subscriptions)
  ↓
IF: Urgency = 'critical'?
  YES →
    SEND: SMS to Don/Nathan
    CREATE: High-priority notification
```

#### **Workflow 2: Outbound Message Sending**

```
TRIGGER: User sends message via dashboard OR template selected
  ↓
LOOKUP: Vendor profile (get language preference)
  ↓
IF: Message in English (always assume yes for outbound)
  ↓
TRANSLATE: To vendor's language (DeepL API)
  ↓
FORMAT: Bilingual message:
    🇺🇸 ENGLISH:
    {original}
    
    🇨🇴 ESPAÑOL:
    {translation}
  ↓
SEND: Via Twilio WhatsApp to vendor's number
  ↓
STORE: In Supabase `conversations` table
  - direction = 'outbound'
  - both language versions
  ↓
IF: Message type = 'compliance' OR urgency = 'high'
  ALSO SEND: SMS backup
  ↓
TRACK: Delivery status (webhook from Twilio)
  - delivered_at
  - read_at (if WhatsApp)
  ↓
IF: No response in X hours (based on urgency)
  TRIGGER: Auto-escalation workflow
```

#### **Workflow 3: Compliance Deadline Monitor** (Runs every hour)

```
CRON: Every hour
  ↓
QUERY: Supabase for tasks WHERE:
  - status != 'completed'
  - due_date IS NOT NULL
  - Calculate time until deadline
  ↓
FOR EACH: Task approaching deadline
  ↓
  CHECK: Reminder schedule
    - 7 days before?
    - 3 days before?
    - 24 hours before?
    - 4 hours before?
    - AT deadline?
  ↓
  IF: Reminder due NOW
    ↓
    GET: Appropriate template from `message_templates`
    ↓
    PERSONALIZE: Replace variables (vendor name, deadline, etc.)
    ↓
    SEND: Translated reminder via Workflow 2
    ↓
    UPDATE: task.last_reminder_sent_at
    ↓
    LOG: System event "reminder_sent"
  ↓
  IF: PAST deadline AND status != 'completed'
    ↓
    UPDATE: task.status = 'overdue'
    ↓
    CREATE: Critical system event
    ↓
    NOTIFY: Don/Nathan (SMS + Dashboard alert)
    ↓
    IF: is_compliance_requirement = true
      ↓
      CHECK: `compliance_requirements.non_compliance_action`
      ↓
      IF: Action = 'suspend_operations'
        ↓
        UPDATE: vendor_profiles.status = 'suspended'
        ↓
        SEND: Suspension notice to vendor (bilingual)
        ↓
        LOG: "vendor_suspended_for_non_compliance"
```

#### **Workflow 4: Audio Transcription Pipeline**

```
TRIGGER: New media_file with file_type = 'audio' AND transcription_status = 'pending'
  ↓
UPDATE: transcription_status = 'processing'
  ↓
SEND: Audio URL to AssemblyAI
  - Enable: Language detection
  - Enable: Speaker diarization (if multiple speakers)
  - Enable: Punctuation/formatting
  ↓
WAIT: For AssemblyAI webhook (transcription complete)
  ↓
RECEIVE: Transcription result
  - Full text
  - Detected language
  - Confidence score
  - Speaker labels (if multiple)
  ↓
UPDATE: media_files table
  - transcription_text
  - transcription_language
  - transcription_status = 'completed'
  - processed_at = NOW()
  ↓
TRANSLATE: Transcription to English (if not already)
  ↓
UPDATE: Linked conversation with transcription
  ↓
ANTHROPIC CLAUDE: Analyze transcription
  - Extract action items
  - Detect urgency/emotion
  - Summarize key points
  ↓
IF: Contains action items
  → TRIGGER: Task creation workflow
  ↓
NOTIFY: Dashboard with transcription + translation
```

---

## Dashboard Interface (Airtable Sync)

### Supabase → Airtable Sync Strategy

**Why Sync (Instead of Airtable as Primary)?**
- Supabase = source of truth (reliable, scalable, fast queries)
- Airtable = visual interface for Don/Nathan (easy filtering, kanban, calendar views)

**Sync Approach: Real-time via N8N**

```
SUPABASE TRIGGER: Row inserted/updated in key tables
  ↓
N8N WEBHOOK: Receives change notification
  ↓
TRANSFORM: Data to Airtable format
  ↓
AIRTABLE API: Create/update record
  ↓
HANDLE: Field mapping (UUID → Airtable Record ID)
```

### Airtable Base Structure

**Table 1: Vendors**
- Name (linked to other tables)
- Primary Contact
- Phone Number
- Language
- Status (Active/Suspended/Offboarded)
- Total Tasks (rollup)
- Overdue Tasks (rollup)
- Last Contact Date
- Compliance Score (formula)

**Table 2: Conversations** (Read-only sync)
- Vendor (link)
- Direction (Inbound/Outbound)
- Original Message
- Translated Message
- Urgency Level
- Contains Action Item? (checkbox)
- Sent Date
- Read Date
- Audio Transcription (long text)

**Table 3: Tasks** (Two-way sync)
- Vendor (link)
- Task Title
- Task Type (dropdown)
- Status (dropdown: Pending, In Progress, Completed, Overdue)
- Priority
- Due Date
- Assigned To
- Source Message (link to Conversations)
- Completion Date

**Views:**
- "🔥 Overdue by Vendor" (Kanban by status)
- "📅 This Week's Deadlines" (Calendar view)
- "⚠️ Compliance Issues" (Filter: is_compliance_requirement = true)
- "💬 Recent Messages" (Gallery view with transcriptions)

**Table 4: Compliance Tracker**
- Vendor (link)
- Requirement Type
- Status (Not Submitted, Pending, Approved, Expired)
- Submitted Date
- Expiration Date
- Document Link (Google Drive)
- Days Until Expiration (formula)
- Auto-color: Red (<7 days), Yellow (<30 days), Green (>30 days)

---

## MCP Server Specification

### Custom MCP Server: `vendor-communication-hub`

**Purpose:** Give Claude Code direct access to vendor communication system for:
- Sending messages
- Checking compliance status
- Creating tasks
- Reviewing conversation history

**Capabilities:**

```typescript
// MCP Server: vendor-communication-hub

interface VendorCommunicationHub {
  
  // ============ MESSAGING ============
  
  send_message(params: {
    vendor_id: string,
    message: string, // Always in English
    urgency: 'low' | 'normal' | 'high' | 'critical',
    message_type?: 'compliance' | 'payment' | 'operational',
    template_id?: string, // Optional: use pre-built template
    variables?: Record<string, string>, // For template personalization
    send_sms_backup?: boolean // Force SMS in addition to WhatsApp
  }): {
    conversation_id: string,
    sent_at: string,
    translated_to: string, // Language code
    delivery_status: 'sent' | 'delivered' | 'read'
  }
  
  // ============ TASKS ============
  
  create_task(params: {
    vendor_id: string,
    title: string,
    task_type: 'insurance' | 'payment' | 'menu' | 'permit' | 'maintenance' | 'other',
    due_date?: string, // ISO 8601
    priority?: 'low' | 'medium' | 'high' | 'critical',
    description?: string,
    is_compliance_requirement?: boolean
  }): {
    task_id: string,
    auto_reminders_scheduled: string[] // Timestamps
  }
  
  update_task_status(params: {
    task_id: string,
    status: 'pending' | 'in_progress' | 'completed' | 'cancelled',
    completion_note?: string
  }): {
    updated_at: string,
    notifications_sent: string[] // Who was notified
  }
  
  // ============ COMPLIANCE ============
  
  check_vendor_compliance(params: {
    vendor_id: string
  }): {
    vendor_name: string,
    overall_status: 'compliant' | 'minor_issues' | 'major_issues' | 'suspended',
    requirements: Array<{
      type: string,
      status: string,
      expires_at?: string,
      days_until_expiration?: number,
      document_url?: string
    }>,
    open_tasks: Array<{
      title: string,
      due_date: string,
      is_overdue: boolean
    }>
  }
  
  get_all_vendors_compliance_summary(): {
    total_vendors: number,
    compliant: number,
    minor_issues: number,
    major_issues: number,
    suspended: number,
    vendors: Array<{
      vendor_id: string,
      name: string,
      status: string,
      overdue_task_count: number
    }>
  }
  
  // ============ CONVERSATION HISTORY ============
  
  get_conversation_history(params: {
    vendor_id: string,
    limit?: number, // Default 50
    include_translations?: boolean, // Default true
    message_type_filter?: string,
    date_from?: string,
    date_to?: string
  }): {
    vendor_name: string,
    total_messages: number,
    conversations: Array<{
      conversation_id: string,
      direction: 'inbound' | 'outbound',
      original_text: string,
      translated_text: string,
      sent_at: string,
      urgency_level: string,
      contains_action_item: boolean,
      media_url?: string,
      audio_transcription?: string
    }>
  }
  
  // ============ ANALYTICS ============
  
  get_vendor_analytics(params: {
    vendor_id: string
  }): {
    total_messages_sent: number,
    total_messages_received: number,
    average_response_time_hours: number,
    compliance_score: number, // 0-100
    task_completion_rate: number, // Percentage
    overdue_tasks: number,
    last_contact_date: string
  }
  
  // ============ BULK OPERATIONS ============
  
  send_bulk_message(params: {
    vendor_ids: string[], // Multiple vendors
    message: string,
    urgency: string,
    template_id?: string
  }): {
    sent_count: number,
    failed_count: number,
    conversation_ids: string[]
  }
  
  // ============ TEMPLATES ============
  
  list_templates(params: {
    category?: string
  }): {
    templates: Array<{
      template_id: string,
      name: string,
      category: string,
      supported_languages: string[],
      required_variables: string[]
    }>
  }
  
  render_template(params: {
    template_id: string,
    language: string,
    variables: Record<string, string>
  }): {
    rendered_message: string
  }
}
```

### Example Usage in Claude Code

```typescript
// User: "Send insurance reminder to Como En Casa Colombia"

const hub = new VendorCommunicationHub();

// Step 1: Check current compliance status
const compliance = await hub.check_vendor_compliance({
  vendor_id: "como-en-casa-uuid"
});

console.log(`Current Status: ${compliance.overall_status}`);
console.log(`Open Insurance Requirement: ${compliance.requirements.find(r => r.type === 'insurance').status}`);

// Step 2: Send reminder using template
const result = await hub.send_message({
  vendor_id: "como-en-casa-uuid",
  template_id: "insurance_final_notice",
  urgency: "critical",
  variables: {
    vendor_name: "Olga",
    due_date: "Tuesday, November 19, 2025 @ 5:00 PM PST"
  },
  send_sms_backup: true // Also send SMS since critical
});

console.log(`✓ Message sent and translated to Spanish`);
console.log(`✓ Conversation ID: ${result.conversation_id}`);
console.log(`✓ SMS backup sent`);

// Step 3: Create task with deadline
await hub.create_task({
  vendor_id: "como-en-casa-uuid",
  title: "Submit updated insurance certificate with additional insureds",
  task_type: "insurance",
  due_date: "2025-11-19T17:00:00-08:00",
  priority: "critical",
  is_compliance_requirement: true
});

console.log(`✓ Task created with auto-reminders at 24h, 4h, and deadline`);
```

---

## Implementation Roadmap

### Phase 1: Foundation (Week 1-2) - **PRIORITY FOR OLGA CRISIS**

**Goals:**
- Operational system for current vendor (Como En Casa)
- Manual but structured process
- Compliance tracking functional

**Tasks:**
1. **Supabase Setup** (Day 1)
   - Create project
   - Deploy schema (provided above)
   - Seed compliance requirements
   - Add Como En Casa vendor profile

2. **Twilio Setup** (Day 1-2)
   - Purchase phone number for Como En Casa
   - Configure webhook to N8N
   - Test SMS + WhatsApp delivery

3. **N8N Workflows** (Day 2-4)
   - Workflow 1: Inbound message processing (basic version)
   - Workflow 2: Outbound message sending
   - DeepL API integration
   - Basic logging to Supabase

4. **Airtable Dashboard** (Day 3-5)
   - Create base with 4 core tables
   - Manual initial sync from Supabase
   - Set up views for Don/Nathan
   - Add Como En Casa data

5. **Backblaze B2** (Day 4)
   - Create bucket
   - Configure N8N upload workflow
   - Test audio file storage

6. **Testing & Olga Communication** (Day 5-7)
   - Send test messages (bilingual)
   - Verify translation quality
   - Create 5 critical templates (insurance, payment, menu, security, general)
   - **Send insurance compliance message to Olga**

**Deliverables:**
- ✅ Olga can receive bilingual messages
- ✅ Audio messages transcribed and stored
- ✅ Compliance tasks tracked in Airtable
- ✅ Dashboard shows all communications

---

### Phase 2: Automation (Week 3-4)

**Goals:**
- Reduce manual intervention
- Automated deadline monitoring
- Real-time notifications

**Tasks:**
1. **AssemblyAI Integration**
   - Audio transcription pipeline (Workflow 4)
   - Language detection
   - Automatic task extraction from audio

2. **Anthropic Claude Integration**
   - Message intent analysis
   - Action item extraction
   - Urgency classification
   - Summary generation

3. **Compliance Deadline Monitor** (Workflow 3)
   - Hourly cron job
   - Auto-reminder system
   - Escalation logic
   - Vendor suspension automation

4. **Supabase → Airtable Real-time Sync**
   - N8N workflow for automatic sync
   - Handle updates in both directions
   - Conflict resolution logic

5. **Dashboard Enhancements**
   - Real-time updates (Supabase subscriptions)
   - Vendor analytics views
   - Compliance score calculations

**Deliverables:**
- ✅ Zero manual reminders needed
- ✅ Automatic task creation from conversations
- ✅ Real-time dashboard updates
- ✅ Audio transcriptions automatic

---

### Phase 3: Scale & Intelligence (Week 5-6)

**Goals:**
- Multi-vendor ready
- MCP server operational
- Advanced analytics

**Tasks:**
1. **MCP Server Development**
   - Build `vendor-communication-hub` server
   - Implement all capabilities (listed above)
   - Test with Claude Code
   - Deploy to production

2. **Multi-vendor Onboarding Flow**
   - Automated vendor profile creation
   - Twilio number provisioning API
   - Welcome message automation
   - Compliance checklist generation

3. **Advanced Analytics**
   - Response time tracking
   - Vendor engagement scoring
   - Compliance forecasting (predict overdue)
   - Revenue impact correlation

4. **WhatsApp Business API Migration** (optional, can defer)
   - Apply for Facebook Business verification
   - Migrate from Twilio WhatsApp to direct API
   - Keep Twilio SMS as fallback

**Deliverables:**
- ✅ Add new vendor in <5 minutes
- ✅ Claude Code can manage vendors autonomously
- ✅ Predictive compliance alerts
- ✅ System handles 10+ vendors effortlessly

---

### Phase 4: Food Court Launch Ready (Week 7-8)

**Goals:**
- 20-30 vendor capacity
- Multi-language support (beyond Spanish)
- Integration with POS/ordering systems

**Tasks:**
1. **Language Expansion**
   - Add Portuguese templates
   - Add Mandarin templates
   - Add Vietnamese templates
   - Test with native speakers

2. **POS Integration**
   - Link vendor tasks to menu updates
   - Sync compliance status → disable vendor in ordering app
   - Automated "vendor offline" notifications

3. **Reporting & Invoicing**
   - Monthly vendor communication reports
   - Compliance audit exports
   - Response time SLA tracking

4. **Mobile Dashboard** (optional)
   - Airtable mobile app configuration
   - Push notifications for critical items
   - Quick-reply templates

**Deliverables:**
- ✅ System supports 6+ languages
- ✅ Vendor compliance auto-enforced in POS
- ✅ Monthly reports automated
- ✅ Don/Nathan can manage from phone

---

## Cost Breakdown (Monthly Recurring)

### Phase 1 (Foundation) Costs
| Service | Monthly Cost |
|---------|-------------|
| Supabase Pro | $25 |
| N8N Cloud (Starter) | $20 |
| DeepL API Pro | $6 + $5/250k chars (~$15 total) |
| Twilio (1 number + SMS/WhatsApp) | $1 + $30 usage = $31 |
| Backblaze B2 (5GB) | $0.03 |
| AssemblyAI (100 hours audio) | $25 |
| **TOTAL** | **~$116/month** |

### Phase 3 (Full Scale - 10 Vendors) Costs
| Service | Monthly Cost |
|---------|-------------|
| Supabase Pro | $25 |
| N8N Cloud (Pro) | $50 (for higher execution volume) |
| DeepL API Pro | $30 (more translations) |
| Twilio (10 numbers + usage) | $10 + $150 usage = $160 |
| Backblaze B2 (50GB) | $0.25 |
| AssemblyAI (500 hours) | $125 |
| Anthropic API (Claude for analysis) | $50 |
| **TOTAL** | **~$440/month** |

**ROI at 10 Vendors:**
- Current manual vendor management: 15 hours/week × $100/hour = $6,000/month
- System cost: $440/month
- **Net savings: $5,560/month**
- **Time savings: 90%**

---

## Immediate Next Steps (This Week)

### Day 1 (Today): Database & Core Infrastructure
```bash
# 1. Create Supabase project
# 2. Run SQL schema (provided above)
# 3. Add Como En Casa vendor profile
# 4. Seed compliance requirements
```

### Day 2: Communication Channels
```bash
# 1. Purchase Twilio phone number
# 2. Configure WhatsApp sender
# 3. Set up webhook endpoint (N8N)
# 4. Test bidirectional messaging
```

### Day 3: Translation & Storage
```bash
# 1. DeepL API key
# 2. Backblaze B2 bucket creation
# 3. N8N workflows: inbound/outbound
# 4. Test bilingual message flow
```

### Day 4: Airtable Dashboard
```bash
# 1. Create base with schema
# 2. Manual data import from Supabase
# 3. Build views for Don/Nathan
# 4. Test task management
```

### Day 5: Olga Crisis Resolution
```bash
# 1. Send insurance compliance message (bilingual)
# 2. Create task with deadline (Nov 19, 5 PM)
# 3. Set up auto-reminders
# 4. Document in system
```

---

## Questions for You to Decide

1. **Twilio vs WhatsApp Business API for Phase 1?**
   - My rec: Twilio (faster setup, SMS fallback)
   - Can migrate to WhatsApp Business API in Phase 3

2. **MCP Server Priority?**
   - Phase 1: Not needed (manual dashboard use)
   - Phase 3: High value (Claude Code automation)
   - Your call: Do you want to use Claude Code for vendor mgmt immediately?

3. **Airtable Two-way Sync?**
   - One-way (Supabase → Airtable): Safer, simpler
   - Two-way: Allows Don to edit tasks in Airtable → syncs back
   - My rec: Start one-way, add two-way in Phase 2

4. **Google Drive Integration?**
   - Just for Don's review backups?
   - Or also for vendor document uploads?
   - My rec: Backblaze primary, Google Drive weekly backup

5. **Who manages the system day-to-day?**
   - Nathan monitors dashboard?
   - Don reviews analytics weekly?
   - System auto-escalates critical items to Don?

---

## Ready to Build?

I can start immediately on:

**Option A: Complete Phase 1 Implementation**
- Supabase schema deployment
- N8N workflow creation (with JSON exports you can import)
- Airtable base setup (with copy-paste schema)
- Bilingual templates for Olga situation
- **ETA: 3-4 days for working system**

**Option B: MCP Server First** (if Claude Code integration is priority)
- Build `vendor-communication-hub` MCP server
- Deploy locally for testing
- Create example commands
- **ETA: 2 days for functional MCP server**

**Option C: Immediate Crisis Mode** (just solve Olga today)
- Bilingual insurance message (ready to send)
- Manual Airtable task tracker
- Simple N8N workflow for future messages
- **ETA: 2 hours for operational capability**

**Which approach do you want to pursue?**