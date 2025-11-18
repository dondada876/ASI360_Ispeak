# ASI360_Is# ASI360 iSpeak - Multilingual Vendor Communication Platform

**Bilingual vendor communication system with automated translation, compliance tracking, and task management for 500 Grand Live food hall operations.**

![System Status](https://img.shields.io/badge/status-active-success)
![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-proprietary-red)

---

## 🎯 **Overview**

ASI360 iSpeak is a comprehensive communication platform designed for managing multilingual vendor relationships in food hall operations. The system handles:

- 📱 **WhatsApp & SMS messaging** with automatic translation
- 🎤 **Audio transcription** for voice messages
- ✅ **Compliance tracking** with automated deadline monitoring
- 📊 **Task management** with vendor-specific workflows
- 🔔 **Automated reminders** and escalation protocols
- 📈 **Analytics dashboard** for operational insights

---

## 🏗️ **Architecture**
```
┌─────────────────────────────────────────────────────────────┐
│                  ASI360 iSpeak Communication Hub             │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   Twilio     │─────▶│     N8N      │─────▶│   Supabase   │
│  WhatsApp    │      │  Automation  │      │  PostgreSQL  │
│   + SMS      │      │   Engine     │      │   Database   │
└──────────────┘      └──────────────┘      └──────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
            ┌──────────────┐    ┌──────────────┐
            │    DeepL     │    │  AssemblyAI  │
            │ Translation  │    │Transcription │
            └──────────────┘    └──────────────┘
                    │
                    ▼
            ┌──────────────┐
            │   Airtable   │
            │  Dashboard   │
            └──────────────┘
```

---

## ⚡ **Quick Start**

### **Prerequisites**
- DigitalOcean account
- Supabase account
- Twilio account with WhatsApp enabled
- DeepL API key
- AssemblyAI API key
- Domain name (optional but recommended)

### **Installation**
```bash
# 1. Clone the repository
git clone https://github.com/500grand/asi360_ispeak.git
cd asi360_ispeak

# 2. Copy environment template
cp .env.example .env

# 3. Edit .env with your credentials
nano .env

# 4. Run automated setup
chmod +x scripts/*.sh
./scripts/deploy.sh

# 5. Verify installation
./scripts/health_check.sh
```

**⏱️ Setup time: ~10 minutes**

---

## 📁 **Repository Structure**
```
asi360_ispeak/
├── README.md                          # This file
├── .env.example                       # Environment variables template
├── .gitignore                         # Git ignore rules
├── LICENSE.md                         # License information
│
├── docker-compose.yml                 # N8N + supporting services
├── docker-compose.supabase.yml        # Self-hosted Supabase (optional)
│
├── database/
│   ├── README.md                      # Database documentation
│   ├── schema.sql                     # Complete database schema
│   ├── migrations/                    # Database migrations
│   └── seed/                          # Seed data
│
├── n8n/
│   ├── README.md                      # N8N workflow documentation
│   ├── workflows/                     # N8N workflow JSON files
│   ├── credentials/                   # Credential templates
│   └── settings/                      # N8N configuration
│
├── scripts/
│   ├── README.md                      # Scripts documentation
│   ├── deploy.sh                      # Main deployment script
│   ├── setup_droplet.sh               # DigitalOcean setup
│   ├── setup_supabase.sh              # Supabase configuration
│   ├── import_n8n_workflows.sh        # Import workflows
│   ├── backup.sh                      # Backup automation
│   └── health_check.sh                # Health monitoring
│
├── nginx/
│   ├── README.md                      # Nginx configuration docs
│   └── nginx.conf                     # Reverse proxy config
│
├── docs/
│   ├── DEPLOYMENT.md                  # Detailed deployment guide
│   ├── API.md                         # API documentation
│   ├── TROUBLESHOOTING.md             # Common issues & solutions
│   ├── MAINTENANCE.md                 # Maintenance procedures
│   ├── ARCHITECTURE.md                # System architecture details
│   └── WORKFLOWS.md                   # N8N workflow explanations
│
└── tests/
    ├── README.md                      # Testing documentation
    ├── test_translation.sh            # Translation tests
    ├── test_webhooks.sh               # Webhook tests
    └── test_database.sh               # Database tests
```

---

## 🚀 **Features**

### **Core Communication**
- ✅ Bidirectional WhatsApp messaging
- ✅ SMS fallback for critical messages
- ✅ Automatic language detection
- ✅ Real-time translation (English ↔ Spanish/Portuguese/Vietnamese/Mandarin)
- ✅ Audio message transcription
- ✅ Media file storage (images, documents, audio)

### **Compliance Management**
- ✅ Automated deadline tracking
- ✅ Multi-tier reminder system (7 days, 3 days, 1 day, 4 hours)
- ✅ Automatic vendor suspension on non-compliance
- ✅ Insurance certificate tracking
- ✅ Health permit monitoring
- ✅ Business license verification

### **Task Management**
- ✅ Automatic task extraction from conversations
- ✅ Priority-based task queues
- ✅ Vendor-specific task workflows
- ✅ Integration with Airtable dashboard
- ✅ Email/SMS notifications for task updates

### **Analytics & Reporting**
- ✅ Response time tracking
- ✅ Vendor engagement scoring
- ✅ Compliance forecasting
- ✅ Message volume analytics
- ✅ Custom report generation

---

## 💰 **Cost Breakdown**

### **Infrastructure (Monthly)**
| Service | Tier | Cost |
|---------|------|------|
| DigitalOcean Droplet | 2 vCPU, 4GB RAM | $24 |
| Supabase Pro | Managed PostgreSQL | $25 |
| Twilio | SMS + WhatsApp | ~$30 |
| DeepL API | Professional | ~$15 |
| AssemblyAI | Transcription | ~$25 |
| **Total** | | **$119/month** |

### **Optimization Options**
- Start with Supabase free tier: Save $25/month
- Use smaller droplet ($12/mo): Save $12/month
- Google Translate instead of DeepL: Save $10/month

**Minimum viable cost: ~$52/month**

---

## 📖 **Documentation**

Detailed documentation available in `/docs`:

- **[Deployment Guide](docs/DEPLOYMENT.md)** - Step-by-step setup instructions
- **[API Documentation](docs/API.md)** - API endpoints and usage
- **[Architecture](docs/ARCHITECTURE.md)** - System design and data flows
- **[Workflows](docs/WORKFLOWS.md)** - N8N workflow explanations
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Maintenance](docs/MAINTENANCE.md)** - Ongoing maintenance procedures

---

## 🔐 **Security**

- All communications encrypted in transit (TLS 1.3)
- Database credentials stored in environment variables
- Row-level security policies in Supabase
- Webhook signature verification
- Rate limiting on all endpoints
- Automated backup system
- GDPR-compliant data handling

---

## 🧪 **Testing**
```bash
# Run all tests
./tests/run_all_tests.sh

# Individual test suites
./tests/test_translation.sh      # Translation accuracy
./tests/test_webhooks.sh         # Webhook functionality
./tests/test_database.sh         # Database operations
```

---

## 📊 **Monitoring**

Access system dashboards:

- **N8N Workflows**: `https://n8n.yourdomain.com`
- **Supabase Dashboard**: `https://supabase.com/dashboard`
- **Airtable Interface**: `https://airtable.com/[your-base]`
- **System Health**: `https://yourdomain.com/health`

---

## 🔄 **Version History**

### **v1.0.0** (2025-11-17)
- ✅ Initial release
- ✅ WhatsApp/SMS integration
- ✅ Spanish translation support
- ✅ Audio transcription
- ✅ Compliance tracking
- ✅ Airtable dashboard sync

### **Roadmap**
- [ ] v1.1.0 - Multi-language expansion (Portuguese, Mandarin, Vietnamese)
- [ ] v1.2.0 - Mobile app for vendors
- [ ] v1.3.0 - POS system integration
- [ ] v2.0.0 - AI-powered response suggestions

---

## 🤝 **Contributing**

This is a proprietary system for 500 Grand Parking Inc. Internal contributions welcome.

For feature requests or bug reports:
1. Open an issue in GitHub
2. Email: dev@500grandparking.com

---

## 📞 **Support**

**Technical Issues**: dev@500grandparking.com  
**Business Questions**: don@500grandparking.com  
**Emergency**: (510) 288-8654

---

## 📄 **License**

Proprietary - 500 Grand Parking Inc. All rights reserved.

See [LICENSE.md](LICENSE.md) for details.

---

## 🙏 **Acknowledgments**

Built with:
- [N8N](https://n8n.io) - Workflow automation
- [Supabase](https://supabase.com) - Backend infrastructure
- [DeepL](https://deepl.com) - Translation services
- [AssemblyAI](https://assemblyai.com) - Audio transcription
- [Twilio](https://twilio.com) - Messaging platform
- [Airtable](https://airtable.com) - Dashboard interface

---

**System Status**: 🟢 Operational  
**Last Updated**: 2025-11-17  
**Maintained by**: 500 Grand Parking Inc.

---

For questions or support, contact: **don@500grandparking.com**