{\rtf1\ansi\ansicpg1252\cocoartf2761
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\margl1440\margr1440\vieww37900\viewh18180\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # Instructions for Claude Code\
\
## Context\
This repository contains specifications for ASI360 iSpeak - a bilingual vendor communication system for 500 Grand Live food hall.\
\
## Your Task\
Architect and implement the system based on specifications in:\
1. `ARCHITECTURE_SPEC.md` - Complete technical specifications\
2. `docs/` directory - All documentation\
3. `database/SCHEMA.md` - Database design\
4. `.env.example` - Required configuration\
\
## Implementation Order\
\
### Phase 1: Foundation (Start Here)\
1. Read `ARCHITECTURE_SPEC.md` completely\
2. Review database schema in `database/SCHEMA.md`\
3. Create Telegram bot (`telegram-bot/index.js`)\
4. Set up database connection (`src/database/client.js`)\
5. Implement core message routing (`src/core/router.js`)\
\
### Phase 2: Integrations\
1. Twilio WhatsApp integration (`src/integrations/twilio.js`)\
2. DeepL translation (`src/integrations/deepl.js`)\
3. AssemblyAI transcription (`src/integrations/assemblyai.js`)\
4. N8N workflows (JSON files in `n8n/workflows/`)\
\
### Phase 3: Automation\
1. Task management system (`src/tasks/manager.js`)\
2. Compliance monitoring (`src/compliance/monitor.js`)\
3. Reminder scheduler (`src/reminders/scheduler.js`)\
\
### Phase 4: Testing & Deployment\
1. Unit tests (`tests/unit/`)\
2. Integration tests (`tests/integration/`)\
3. Deployment scripts (`scripts/deploy.sh`)\
4. Health checks (`scripts/health_check.sh`)\
\
## Key Constraints\
- **Timeline:** 1 week for MVP\
- **Budget:** $42/month operational cost\
- **Users:** 2 admins, 2 vendors initially\
- **Languages:** English + Spanish (expand later)\
- **Platform:** DigitalOcean droplet + Supabase\
\
## Success Criteria\
- [ ] Telegram bot responds to admin commands\
- [ ] WhatsApp messages route correctly\
- [ ] Automatic translation works (EN \uc0\u8596  ES)\
- [ ] Tasks auto-create from conversations\
- [ ] Compliance reminders fire on schedule\
- [ ] Como En Casa can communicate successfully\
- [ ] Complete audit trail in database\
\
## Questions?\
Refer to comprehensive documentation in `docs/` directory or ask for clarification.\
\
---\
\
**Start by asking:** "I've read the ARCHITECTURE_SPEC.md. Should I begin implementing the Telegram bot or set up the database first?"}