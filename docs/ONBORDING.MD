# Vendor Onboarding Guide

Complete guide for onboarding new food vendors to the ASI360 iSpeak communication system.

---

## Table of Contents

- [Overview](#overview)
- [Pre-Onboarding Checklist](#pre-onboarding-checklist)
- [Onboarding Steps](#onboarding-steps)
- [Vendor Communication Templates](#vendor-communication-templates)
- [Compliance Requirements](#compliance-requirements)
- [Timeline](#timeline)
- [Troubleshooting](#troubleshooting)

---

## Overview

### Onboarding Goals

1. **Register vendor** in system
2. **Establish communication** channel (WhatsApp or Telegram)
3. **Collect compliance documents** (insurance, permits, licenses)
4. **Submit menu** items and pricing
5. **Configure operations** schedule
6. **Complete orientation** and training

### Expected Timeline

- **Day 1-3:** Initial contact and registration
- **Day 4-7:** Document collection
- **Day 8-10:** Menu submission and review
- **Day 11-14:** Final approvals and go-live

**Total: 2 weeks from first contact to operations**

---

## Pre-Onboarding Checklist

### Before First Contact

- [ ] Parking stall assignment determined
- [ ] Rental rate agreed upon
- [ ] Lease term established
- [ ] Deposit amount confirmed
- [ ] Insurance requirements documented
- [ ] Health department requirements verified

### Information to Collect

- [ ] Business legal name
- [ ] Primary contact person
- [ ] Phone number (for WhatsApp)
- [ ] Email address
- [ ] Preferred language
- [ ] Business license number
- [ ] EIN/Tax ID
- [ ] Cuisine type
- [ ] Operating hours desired

---

## Onboarding Steps

### Step 1: Initial Contact & Registration

**Admin Action (via Telegram):**
```
/onboard [Business Name]
```

**System Response:**
- Creates vendor profile in database
- Generates unique vendor ID
- Sends welcome message to vendor
- Creates onboarding checklist
- Assigns tasks with deadlines

**Vendor Receives (WhatsApp or Telegram):**
```
🎉 Welcome to 500 Grand Live!

We're excited to have [Business Name] join our food hall.

📋 Next Steps:
1. Submit insurance certificate (Due: 7 days)
2. Upload business license (Due: 7 days)
3. Provide health permit (Due: 7 days)
4. Submit menu with pricing (Due: 10 days)

Reply with questions anytime!

---

🇪🇸 Versión en Español:

¡Bienvenido a 500 Grand Live!

Estamos emocionados de tener a [Business Name] en nuestro mercado de comida.

📋 Próximos Pasos:
1. Enviar certificado de seguro (Plazo: 7 días)
2. Subir licencia comercial (Plazo: 7 días)
3. Proporcionar permiso de salud (Plazo: 7 días)
4. Enviar menú con precios (Plazo: 10 días)

¡Responde con preguntas en cualquier momento!
```

---

### Step 2: Compliance Document Collection

**Required Documents:**

#### A. Insurance Certificate

**Requirements:**
- General Liability: $2,000,000 minimum
- Workers Compensation (if applicable)
- Additional Insureds:
  - 500 Grand Ave LLC
  - 500 Grand Live LLC
  - People Park X

**Vendor Instructions:**
```
📄 Insurance Certificate Required

Please upload certificate that includes:
✅ $2M general liability coverage
✅ Additional insureds:
   • 500 Grand Ave LLC
   • 500 Grand Live LLC
   • People Park X

📎 Send photo or PDF of certificate

---

🇪🇸 Certificado de Seguro Requerido

Por favor suba el certificado que incluya:
✅ Cobertura de $2M de responsabilidad general
✅ Asegurados adicionales:
   • 500 Grand Ave LLC
   • 500 Grand Live LLC
   • People Park X

📎 Envíe foto o PDF del certificado
```

**Admin Review Process:**

1. Vendor uploads document via WhatsApp/Telegram
2. System stores in Supabase Storage
3. Admin receives notification in Telegram
4. Admin reviews document
5. Admin approves or requests corrections

**Telegram Commands:**
```
/review_insurance [vendor_id]
/approve_insurance [vendor_id]
/reject_insurance [vendor_id] [reason]
```

#### B. Business License

**Requirements:**
- Valid Oakland business license
- Current year
- Matches business legal name

**Vendor Instructions:**
```
🏢 Business License Required

Upload current Oakland business license

Requirements:
✅ Current year (2025)
✅ Matches your legal business name
✅ Valid for food service

📎 Send photo or PDF

---

🇪🇸 Licencia Comercial Requerida

Suba la licencia comercial actual de Oakland

Requisitos:
✅ Año actual (2025)
✅ Coincide con su nombre legal de negocio
✅ Válida para servicio de alimentos

📎 Envíe foto o PDF
```

#### C. Health Department Permit

**Requirements:**
- Alameda County Health Permit
- Current inspection passed
- Covers mobile food operations

**Vendor Instructions:**
```
🏥 Health Permit Required

Upload current health department permit

Requirements:
✅ Alameda County Health Department
✅ Current inspection passed
✅ Covers mobile food operations

📎 Send photo or PDF

---

🇪🇸 Permiso de Salud Requerido

Suba el permiso actual del departamento de salud

Requisitos:
✅ Departamento de Salud del Condado de Alameda
✅ Inspección actual aprobada
✅ Cubre operaciones de comida móvil

📎 Envíe foto o PDF
```

---

### Step 3: Menu Submission

**Format Requirements:**
- Item name (English + native language if applicable)
- Description (2-3 sentences)
- Price
- Dietary tags (vegetarian, vegan, gluten-free, etc.)
- Photo of each item (high quality)

**Vendor Instructions:**
```
📋 Menu Submission

For each menu item, send:

1️⃣ Name (English + Spanish if applicable)
2️⃣ Description
3️⃣ Price
4️⃣ Photo
5️⃣ Dietary info (vegetarian, vegan, etc.)

Example:
📸 [Photo of dish]
🍽️ Bandeja Paisa
💵 $22.00
📝 Traditional Colombian platter with rice, beans, pork, beef, egg, plantain, arepa
🥗 Contains: meat, dairy, gluten

Send items one at a time, or as a list

---

🇪🇸 Envío de Menú

Para cada artículo del menú, envíe:

1️⃣ Nombre
2️⃣ Descripción
3️⃣ Precio
4️⃣ Foto
5️⃣ Info dietética (vegetariano, vegano, etc.)

Ejemplo:
📸 [Foto del plato]
🍽️ Bandeja Paisa
💵 $22.00
📝 Plato tradicional colombiano con arroz, frijoles, cerdo, res, huevo, plátano, arepa
🥗 Contiene: carne, lácteos, gluten

Envíe artículos uno a la vez, o como lista
```

**Admin Review:**
```
/review_menu [vendor_id]
/approve_item [item_id]
/request_changes [item_id] [reason]
/approve_menu [vendor_id]
```

---

### Step 4: Operating Schedule

**Required Information:**
- Days of operation
- Operating hours
- Setup time needed
- Breakdown time needed
- Special closures

**Vendor Instructions:**
```
📅 Operating Schedule

Please provide:

1. Days you'll operate (Mon-Sun)
2. Operating hours (when serving customers)
3. Setup time needed (before opening)
4. Breakdown time (after closing)

Example:
📅 Days: Friday, Saturday, Sunday
⏰ Hours: 11:00 AM - 8:00 PM
🔧 Setup: 30 minutes before
📦 Breakdown: 30 minutes after

---

🇪🇸 Horario de Operación

Por favor proporcione:

1. Días de operación (Lun-Dom)
2. Horas de operación (cuando sirve clientes)
3. Tiempo de preparación necesario
4. Tiempo de desmontaje

Ejemplo:
📅 Días: Viernes, Sábado, Domingo
⏰ Horas: 11:00 AM - 8:00 PM
🔧 Preparación: 30 minutos antes
📦 Desmontaje: 30 minutos después
```

---

### Step 5: Payment & Contract

**Payment Structure:**

**Deposit:**
- Required before operations begin
- Amount: [As per lease agreement]
- Accepted methods:
  - Zelle
  - Wire transfer
  - Cashier's check

**Monthly Rent:**
- Due: 1st of each month
- Grace period: 5 days
- Late fee: $50 after grace period

**Contract Signature:**

System sends BoldSign electronic signature request:
```
📝 Vendor Agreement Ready

Your vendor agreement is ready for signature.

You'll receive an email from BoldSign with:
✅ Lease terms
✅ Operating guidelines
✅ Payment schedule
✅ Compliance requirements

Please review and sign within 48 hours.

Questions? Reply here anytime.

---

🇪🇸 Acuerdo de Vendedor Listo

Su acuerdo de vendedor está listo para firmar.

Recibirá un correo de BoldSign con:
✅ Términos del arrendamiento
✅ Directrices de operación
✅ Calendario de pagos
✅ Requisitos de cumplimiento

Por favor revise y firme dentro de 48 horas.

¿Preguntas? Responda aquí en cualquier momento.
```

---

### Step 6: Orientation & Training

**Topics Covered:**

1. **Facility Rules**
   - Parking lot access
   - Setup locations
   - Trash/waste disposal
   - Water/power access

2. **Safety Requirements**
   - Fire extinguisher location
   - Emergency procedures
   - Security contact info
   - Closing procedures

3. **Communication Protocol**
   - How to reach management
   - Emergency contact numbers
   - Daily check-in process
   - Incident reporting

4. **Customer Service Standards**
   - Service expectations
   - Complaint handling
   - Quality standards
   - Pricing display requirements

**Delivery Method:**
- In-person walkthrough (preferred)
- Video call (if needed)
- Recorded video + Q&A

---

## Vendor Communication Templates

### Welcome Message
```
🎉 Welcome to 500 Grand Live Family!

Hi [Vendor Name]!

We're thrilled to have you join our food hall community. Here's what happens next:

📋 NEXT STEPS (Complete in 7 days):
1. Insurance certificate → Upload via this chat
2. Business license → Upload via this chat
3. Health permit → Upload via this chat
4. Menu submission → Send items via this chat

💬 COMMUNICATION:
- Ask questions anytime in this chat
- Get reminders for important deadlines
- Upload documents directly here
- Receive approvals and updates

⏰ TIMELINE:
Week 1: Document collection
Week 2: Menu review and approval
Week 3: Contract signature and payment
Week 4: GO LIVE! 🚀

Let's get started! Please send your insurance certificate first.

Questions? Just reply to this message.

---

🇪🇸 [Spanish version]
```

### Document Reminder (7 days before deadline)
```
📌 Friendly Reminder

Hi [Vendor Name],

Your [document type] is due in 7 days.

Due date: [Date]

Please upload:
📎 [Document details]

Need help? Just ask!

---

🇪🇸 [Spanish version]
```

### Document Reminder (24 hours before deadline)
```
⚠️ URGENT: Document Due Tomorrow

Hi [Vendor Name],

Your [document type] is due tomorrow at 5:00 PM.

To avoid delays in your onboarding, please upload today.

Need assistance? Call/text: (510) 288-8654

---

🇪🇸 [Spanish version]
```

### Document Approved
```
✅ Document Approved!

Great news [Vendor Name]!

Your [document type] has been approved.

✅ Completed: [Document name]

Next step: [Next requirement]
Due: [Date]

You're making great progress! 🎉

---

🇪🇸 [Spanish version]
```

### Document Needs Revision
```
📄 Document Needs Update

Hi [Vendor Name],

We reviewed your [document type] and need a small correction:

❌ Issue: [Specific problem]

✅ Solution: [What to fix]

Please re-upload corrected document within 48 hours.

Questions? Reply here!

---

🇪🇸 [Spanish version]
```

### Onboarding Complete
```
🎊 Congratulations! Onboarding Complete!

Hi [Vendor Name],

You've completed all onboarding requirements!

✅ Insurance: Approved
✅ Business license: Approved
✅ Health permit: Approved
✅ Menu: Approved
✅ Contract: Signed
✅ Payment: Received

🚀 START DATE: [Date]

Your assigned location: Stall #[Number]

Setup time: [Time]

Welcome to the 500 Grand Live family! We're excited to have you.

See you soon! 🎉

---

🇪🇸 [Spanish version]
```

---

## Compliance Requirements

### Insurance

**Minimum Coverage:**
- General Liability: $2,000,000
- Workers Compensation: As required by law
- Auto (if using vehicle for business)

**Additional Insureds:**
- 500 Grand Ave LLC
- 500 Grand Live LLC
- People Park X

**Renewal:**
- Track expiration dates
- Remind vendor 30 days before expiration
- Require renewal certificate

### Licenses & Permits

**City of Oakland:**
- Business license (annual)
- Mobile food facility permit

**Alameda County:**
- Health permit
- Passed inspection within 6 months

**State of California:**
- Seller's permit (sales tax)
- Food handler certifications for staff

---

## Timeline

### Standard 2-Week Onboarding
```
Week 1:
├─ Day 1: Initial contact, send welcome message
├─ Day 2-3: Vendor submits insurance, license, permit
├─ Day 4-5: Admin reviews documents
└─ Day 6-7: Vendor corrects any issues

Week 2:
├─ Day 8-9: Vendor submits menu
├─ Day 10-11: Menu review and approval
├─ Day 12-13: Contract signature, payment processing
└─ Day 14: Go-live preparation

Week 3:
└─ Day 15: OPERATIONS BEGIN! 🎉
```

### Expedited 1-Week Onboarding

For vendors with all documents ready:
```
Day 1: Welcome + document upload
Day 2: Document review + approval
Day 3: Menu submission
Day 4: Menu approval + contract
Day 5: Payment + orientation
Day 6-7: Setup and go-live
```

---

## Troubleshooting

### Vendor Not Responding

**After 24 hours:**
```
/remind [vendor_id]
```

**After 48 hours:**
- Call vendor directly
- Send SMS in addition to app message

**After 72 hours:**
```
/escalate [vendor_id]
```

### Document Quality Issues

**Photo unclear:**
```
Hi [Vendor Name],

The photo of your [document] is a bit unclear.

Could you please:
1. Take photo in good lighting
2. Make sure all text is readable
3. Include full document (all pages)

Thanks!
```

**Wrong document:**
```
Hi [Vendor Name],

Thanks for uploading! However, we need [correct document] instead.

The document you sent is [what they sent].

Please send [what you actually need] instead.

Need help finding it? Let me know!
```

### Language Barrier

**If automated translation unclear:**
- Schedule video call with interpreter
- Use Google Translate in real-time
- Provide documents in vendor's native language
- Connect with bilingual staff member

### Payment Issues

**Deposit not received:**
```
/payment_reminder [vendor_id]
```

**Payment method issues:**
- Offer alternative methods (Zelle, wire, check)
- Provide detailed wire instructions
- Accept partial payment with plan for remainder

---

## Best Practices

### Communication

1. **Respond within 4 hours** during business hours
2. **Always send bilingual** if vendor preference is non-English
3. **Use simple language** (avoid jargon)
4. **Include action items** clearly
5. **Set expectations** for response times

### Document Management

1. **Label all documents** clearly in storage
2. **Track expiration dates** in system
3. **Set renewal reminders** 30 days in advance
4. **Keep digital backups** of everything
5. **Verify authenticity** of documents

### Timeline Management

1. **Set realistic deadlines** (7-14 days for documents)
2. **Send reminders** at 7 days, 3 days, 1 day before
3. **Be flexible** for legitimate delays
4. **Escalate early** if vendor unresponsive
5. **Celebrate milestones** when completed

---

## Related Documentation

- [Compliance Tracking](./COMPLIANCE.md)
- [Communication Templates](./TEMPLATES.md)
- [Admin Commands](../telegram-bot/COMMANDS.md)
- [Troubleshooting Guide](./TROUBLESHOOTING.md)

---

**Questions?** Contact: don@500grandparking.com