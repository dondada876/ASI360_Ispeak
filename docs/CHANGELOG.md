# Changelog

All notable changes to ASI360 iSpeak will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned
- Multi-language support (Portuguese, Mandarin, Vietnamese)
- Mobile app for vendors
- POS system integration
- AI-powered response suggestions
- Voice call support
- Video message support

---

## [1.0.0] - 2025-11-17

### Added
- Initial release of ASI360 iSpeak
- Telegram bot for admin interface
- WhatsApp integration via Twilio
- Automatic translation (English ↔ Spanish)
- Audio message transcription
- Task management system
- Compliance tracking
- Automated deadline reminders
- Document upload/storage
- Vendor onboarding workflow
- Admin dashboard commands
- Message history and audit trail
- Supabase database backend
- N8N automation workflows
- DeepL translation integration

### Security
- Row-level security policies in Supabase
- Environment variable configuration
- Webhook signature verification
- Rate limiting on API endpoints

### Documentation
- Complete deployment guide
- API documentation
- Architecture overview
- Troubleshooting guide
- Maintenance procedures
- Contributing guidelines

---

## [0.9.0] - 2025-11-10 (Beta)

### Added
- Beta testing with Como En Casa Colombia Food
- Basic Telegram bot functionality
- WhatsApp messaging via Twilio
- Manual translation workflow
- Simple task tracking

### Fixed
- Message delivery reliability
- Translation accuracy improvements
- Timezone handling

### Known Issues
- Audio transcription pending
- Limited to English/Spanish only
- Manual reminder system

---

## [0.5.0] - 2025-11-03 (Alpha)

### Added
- Proof of concept with Telegram bot
- Database schema design
- N8N workflow prototypes
- Basic vendor registration

### Changed
- Migrated from manual WhatsApp to automated system
- Switched from Google Translate to DeepL

---

## Version History Summary

| Version | Date | Milestone |
|---------|------|-----------|
| 1.0.0 | 2025-11-17 | Production release |
| 0.9.0 | 2025-11-10 | Beta testing |
| 0.5.0 | 2025-11-03 | Alpha/POC |

---

## Upgrade Guide

### From 0.9.0 to 1.0.0

**Database Changes:**
```sql
-- Add new columns
ALTER TABLE vendors ADD COLUMN telegram_chat_id BIGINT UNIQUE;
ALTER TABLE messages ADD COLUMN translated_text TEXT;

-- Run migration
psql $DATABASE_URL -f database/migrations/001_v1_upgrade.sql
```

**Configuration Changes:**
- Add `ASSEMBLYAI_API_KEY` to `.env`
- Update `N8N_WEBHOOK_URL` format
- Configure new Telegram bot token

**Breaking Changes:**
- None - fully backwards compatible

---

## Support

For questions about changes or upgrade assistance:
- Email: dev@500grandparking.com
- GitHub Issues: https://github.com/500grand/asi360_ispeak/issues

---

[Unreleased]: https://github.com/500grand/asi360_ispeak/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/500grand/asi360_ispeak/releases/tag/v1.0.0
[0.9.0]: https://github.com/500grand/asi360_ispeak/releases/tag/v0.9.0
[0.5.0]: https://github.com/500grand/asi360_ispeak/releases/tag/v0.5.0