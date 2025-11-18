# Telegram Bot (Optional)

Optional Telegram bot implementation for admin interface.

## Status

⚠️ **Not yet implemented**

This is a placeholder for future Telegram bot integration.

## Planned Features

- Admin command interface
- Send messages to vendors
- View vendor status
- Task management
- Compliance alerts

## Architecture

The MVP spec (docs/MVP_SPEC.md) describes a Telegram + WhatsApp hybrid approach.

If implementing:

1. Create bot with @BotFather
2. Get bot token
3. Add to .env: `TELEGRAM_BOT_TOKEN`
4. Implement bot handlers in this directory

## Alternative

Currently, all admin operations can be done through:
- N8N Dashboard
- Airtable Interface
- Direct API calls
