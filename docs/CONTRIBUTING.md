# Contributing to ASI360 iSpeak

## Project Overview

ASI360 iSpeak is a proprietary vendor communication system for 500 Grand Parking Inc. This document outlines development standards and contribution guidelines.

---

## Development Workflow

### 1. Branch Strategy
```
main (production)
  ↓
develop (staging)
  ↓
feature/[feature-name] (development)
```

**Branch Naming:**
- `feature/telegram-bot-commands` - New features
- `fix/translation-error` - Bug fixes
- `docs/api-documentation` - Documentation
- `refactor/database-schema` - Code improvements

### 2. Commit Messages

Follow conventional commits:
```
feat: add vendor onboarding workflow
fix: resolve WhatsApp message delivery issue
docs: update deployment guide
refactor: optimize database queries
test: add translation accuracy tests
chore: update dependencies
```

### 3. Pull Request Process

1. Create feature branch from `develop`
2. Implement changes with tests
3. Update documentation
4. Submit PR with description
5. Request review from team lead
6. Address feedback
7. Merge after approval

---

## Code Standards

### Node.js / JavaScript

**Style Guide:**
- Use ES6+ features
- Async/await over callbacks
- Destructuring where appropriate
- Meaningful variable names

**Example:**
```javascript
// Good
const { vendorId, message } = req.body;
const translatedText = await translateMessage(message, 'es');

// Avoid
var x = req.body.vendorId;
translateMessage(message, 'es', function(err, result) { ... });
```

### Database

**SQL Standards:**
- Use lowercase with underscores for table/column names
- Always include timestamps (`created_at`, `updated_at`)
- Use UUIDs for primary keys
- Add indexes for foreign keys

**Example:**
```sql
CREATE TABLE vendor_tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendors(id),
  task_title TEXT NOT NULL,
  due_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_vendor_tasks_vendor_id ON vendor_tasks(vendor_id);
```

### N8N Workflows

**Best Practices:**
- Use descriptive node names
- Add notes explaining complex logic
- Handle errors gracefully
- Test with sample data
- Version control workflow JSON files

---

## Testing Requirements

### Unit Tests

All new features must include unit tests:
```javascript
describe('Translation Service', () => {
  it('should translate English to Spanish', async () => {
    const result = await translate('Hello', 'en', 'es');
    expect(result.text).toBe('Hola');
  });
  
  it('should handle translation errors', async () => {
    await expect(translate('', 'en', 'es')).rejects.toThrow();
  });
});
```

### Integration Tests

Test complete workflows:
```javascript
describe('Vendor Onboarding', () => {
  it('should create vendor and send welcome message', async () => {
    const vendor = await createVendor(vendorData);
    expect(vendor.id).toBeDefined();
    
    const message = await getLastMessage(vendor.id);
    expect(message.text).toContain('Welcome');
  });
});
```

### Manual Testing Checklist

Before submitting PR:
- [ ] Telegram bot responds to all commands
- [ ] WhatsApp messages are translated correctly
- [ ] Tasks are created and reminders sent
- [ ] Files upload successfully
- [ ] Compliance tracking works
- [ ] Admin notifications fire correctly

---

## Documentation Standards

### Code Comments

**When to comment:**
- Complex algorithms
- Business logic
- Workarounds
- External API integrations

**Example:**
```javascript
// Calculate reminder schedule based on urgency
// Critical: 4h, 1h before deadline
// High: 24h, 4h before
// Normal: 7 days, 24h before
const reminderSchedule = calculateReminders(task.urgency, task.due_date);
```

### API Documentation

Use JSDoc for functions:
```javascript
/**
 * Sends a message to a vendor via their preferred channel
 * @param {string} vendorId - UUID of the vendor
 * @param {string} message - Message text in English
 * @param {string} urgency - 'low', 'normal', 'high', 'critical'
 * @returns {Promise<Object>} Message delivery status
 * @throws {Error} If vendor not found or delivery fails
 */
async function sendToVendor(vendorId, message, urgency) {
  // Implementation
}
```

### Markdown Documentation

Follow this structure for documentation files:
```markdown
# Title

Brief description (1-2 sentences)

## Table of Contents
- [Section 1](#section-1)
- [Section 2](#section-2)

## Section 1

Content with examples

## Section 2

More content

## Related Documentation
- [Link to related doc](./related.md)
```

---

## Environment Setup

### Local Development

1. **Clone Repository**
```bash
git clone https://github.com/500grand/asi360_ispeak.git
cd asi360_ispeak
```

2. **Install Dependencies**
```bash
npm install
```

3. **Setup Environment**
```bash
cp .env.example .env
# Edit .env with your development credentials
```

4. **Start Development Server**
```bash
npm run dev
```

5. **Run Tests**
```bash
npm test
npm run test:watch
```

### Development Database

Use Supabase local development:
```bash
npx supabase start
npx supabase db reset
```

---

## Security Guidelines

### Secrets Management

**Never commit:**
- API keys
- Passwords
- Private keys
- Tokens
- `.env` files

**Always:**
- Use environment variables
- Store secrets in password manager
- Rotate keys every 90 days
- Use least-privilege access

### Code Review Checklist

- [ ] No hardcoded credentials
- [ ] Input validation present
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] Rate limiting on endpoints
- [ ] Authentication required
- [ ] Error messages don't leak data

---

## Release Process

### Versioning

We use Semantic Versioning (semver):

- `MAJOR.MINOR.PATCH`
- `1.0.0` - Initial release
- `1.1.0` - New features (backwards compatible)
- `1.0.1` - Bug fixes
- `2.0.0` - Breaking changes

### Release Checklist

- [ ] All tests passing
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] Version bumped in package.json
- [ ] Tagged in git
- [ ] Deployed to staging
- [ ] Smoke tests passed
- [ ] Deployed to production
- [ ] Monitoring alerts configured

---

## Getting Help

**Questions?**
- Check documentation in `/docs`
- Search existing GitHub issues
- Ask in team Slack channel

**Found a bug?**
- Check if already reported
- Create GitHub issue with:
  - Steps to reproduce
  - Expected behavior
  - Actual behavior
  - Screenshots if applicable
  - Environment details

**Feature requests?**
- Open GitHub issue with `enhancement` label
- Describe use case
- Propose solution (optional)
- Wait for team discussion

---

## Contact

**Technical Lead:** don@500grandparking.com  
**DevOps:** nathan@500grandparking.com  
**Repository:** https://github.com/500grand/asi360_ispeak

---

Thank you for contributing to ASI360 iSpeak!