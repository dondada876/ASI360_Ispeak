# N8N Workflows

This directory contains all N8N automation workflows for the ASI360 iSpeak system.

## Workflows

### 01 - Inbound Message Processing
**File:** `workflows/01_inbound_message.json`
**Trigger:** Webhook (Twilio)
**Purpose:** Process incoming messages from vendors

**Flow:**
1. Receive message from Twilio
2. Lookup vendor by phone number
3. Translate message to English (DeepL)
4. Analyze with Claude AI for action items
5. Store in database
6. Create tasks if needed
7. Notify admin if critical

### 02 - Outbound Message Sending
**File:** `workflows/02_outbound_message.json`
**Trigger:** Webhook (API call)
**Purpose:** Send messages to vendors

**Flow:**
1. Receive message request
2. Get vendor details
3. Translate to vendor's language
4. Send via WhatsApp or SMS
5. Store conversation
6. Log system event

### 03 - Compliance Deadline Monitor
**File:** `workflows/03_compliance_monitor.json`
**Trigger:** Schedule (every 6 hours)
**Purpose:** Automated deadline monitoring and reminders

**Flow:**
1. Query upcoming deadlines
2. Calculate reminder schedule
3. Send reminders at: 7d, 3d, 1d, 4h before
4. Mark overdue tasks
5. Update database

### 04 - Audio Transcription Pipeline
**File:** `workflows/04_audio_transcription.json`
**Trigger:** Schedule (every 5 minutes)
**Purpose:** Process audio messages

**Flow:**
1. Find pending audio files
2. Submit to AssemblyAI
3. Wait for transcription
4. Store result in database
5. Trigger message analysis

### 05 - Airtable Sync
**File:** `workflows/05_airtable_sync.json`
**Trigger:** Schedule (every 15 minutes)
**Purpose:** Sync data to Airtable dashboard

**Flow:**
1. Query recent vendor data
2. Sync to Airtable Vendors table
3. Query recent tasks
4. Sync to Airtable Tasks table

## Installation

### Automatic Import

```bash
./scripts/import_n8n_workflows.sh
```

### Manual Import

1. Access N8N dashboard: `https://your-domain.com:5678`
2. Go to Workflows
3. Click Import
4. Upload each JSON file from `workflows/` directory

## Configuration

### Required Credentials

Configure these credentials in N8N:

1. **Supabase** - PostgreSQL connection
2. **Twilio** - WhatsApp/SMS API
3. **DeepL** - Translation API
4. **AssemblyAI** - Audio transcription
5. **Anthropic** - Claude AI API
6. **Airtable** - Dashboard sync

### Environment Variables

All workflows use these environment variables:
- `SUPABASE_URL`
- `TWILIO_ACCOUNT_SID`
- `DEEPL_API_KEY`
- `ANTHROPIC_API_KEY`
- etc.

## Webhook URLs

After deployment, configure these webhooks:

- **Twilio Inbound:** `https://your-domain.com/webhook/twilio/inbound`
- **Send Message:** `https://your-domain.com/webhook/send-message`

## Monitoring

View execution logs in N8N dashboard:
1. Go to Executions
2. Filter by workflow
3. View detailed logs for each run

## Troubleshooting

### Workflow not triggering
- Check webhook URL in Twilio
- Verify N8N is running: `docker ps | grep n8n`
- Check N8N logs: `docker logs asi360-n8n`

### Workflow failing
- Check execution logs in N8N dashboard
- Verify all credentials are configured
- Ensure environment variables are set
