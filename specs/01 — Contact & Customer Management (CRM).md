## 1. Core domain model

At this scale, keep the domain small and explicit:

- Contact (person)
- Company (account)
- Lead (unqualified or lightly qualified)
- Opportunity (qualified deal / job)
- Interaction (activity history)
- User (your CRM user)
- Integration objects (Google, QuickBooks mappings)

## 1.1 Entity summary and relationships

- Company
  - 0..n Contacts, 0..n Leads, 0..n Opportunities.
  - 0..1 QuickBooksCustomer mapping.
- Contact
  - Belongs to 0..1 Company.
  - 0..n Leads (same person raising multiple jobs), 0..n Opportunities via company.
  - Has many Interactions.
- Lead
  - Belongs to 0..1 Contact, 0..1 Company.
  - 0..1 Opportunity (once qualified).
  - Has many Interactions.
- Opportunity
  - Belongs to 0..1 Contact, 0..1 Company.
  - 0..n Interactions.
  - 0..1 QuickBooksCustomer (for repeat work) or is mapped at Company.
- Interaction
  - Belongs to exactly one “parent”: Contact or Lead or Opportunity (plus optional cross-links).
  - Stores normalized reference to Gmail message, Calendar event, phone call, manual note.
- User
  - Owns Leads, Opportunities, Companies, Contacts, and Interactions.
  - Owns OAuth tokens / integration config for Google, QuickBooks.

------

## 2. Data structures and field definitions

Field types use a generic relational / document-DB vocabulary (string, text, integer, decimal, boolean, datetime, json, enum).

## 2.1 Company

Key goals: simple, QuickBooks‑friendly, service‑business–oriented.

**Main fields**

- id: string (UUID)
- created_at, updated_at: datetime
- name: string (required) – display name; should be kept aligned with QuickBooks Customer.DisplayName when synced.
- legal_name: string (optional)
- type: enum [business, individual, nonprofit, government, other]
- industry: string
- employee_count: integer (small range)
- website: string
- main_phone: string
- billing_address: object
  - line1, line2, city, state, postal_code, country: string
- shipping_address: object (same shape)
- primary_contact_id: string (FK Contact.id, nullable)
- status: enum [prospect, active_customer, inactive, archived]
- source: enum [manual, web_form, import_google_contacts, import_csv, api]
- tags: string[] (e.g., “plumbing”, “maintenance contract”)
- owner_user_id: string (FK User.id)
- quickbooks_customer_id: string (nullable) – QuickBooks Customer.Id.
- quickbooks_sync_status: enum [never, pending, synced, error]
- quickbooks_sync_error: text
- metadata: json – extensible custom data.

**JSON schema (abridged)**

```
json{
  "type": "object",
  "required": ["id", "name", "status", "owner_user_id"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "name": { "type": "string", "maxLength": 255 },
    "legal_name": { "type": "string" },
    "type": { "type": "string", "enum": ["business", "individual", "nonprofit", "government", "other"] },
    "industry": { "type": "string" },
    "employee_count": { "type": "integer", "minimum": 0 },
    "website": { "type": "string" },
    "main_phone": { "type": "string" },
    "billing_address": {
      "type": "object",
      "properties": {
        "line1": { "type": "string" },
        "line2": { "type": "string" },
        "city": { "type": "string" },
        "state": { "type": "string" },
        "postal_code": { "type": "string" },
        "country": { "type": "string" }
      }
    },
    "shipping_address": { "$ref": "#/properties/billing_address" },
    "primary_contact_id": { "type": "string" },
    "status": { "type": "string", "enum": ["prospect", "active_customer", "inactive", "archived"] },
    "source": {
      "type": "string",
      "enum": ["manual", "web_form", "import_google_contacts", "import_csv", "api"]
    },
    "tags": { "type": "array", "items": { "type": "string" } },
    "owner_user_id": { "type": "string" },
    "quickbooks_customer_id": { "type": "string" },
    "quickbooks_sync_status": {
      "type": "string",
      "enum": ["never", "pending", "synced", "error"]
    },
    "quickbooks_sync_error": { "type": "string" },
    "metadata": { "type": "object" }
  }
}
```

------

## 2.2 Contact

Optimized for people; ties into Google People API shapes.

**Main fields**

- id: string (UUID)
- created_at, updated_at: datetime
- first_name, last_name: string
- full_name: string (denormalized)
- company_id: string (nullable, FK Company.id)
- job_title: string
- emails: array of objects
  - email: string
  - type: enum [work, home, other]
  - primary: boolean
- phones: array of objects
  - number: string
  - type: enum [mobile, work, home, other]
  - primary: boolean
- addresses: array (same shape as Company.billing_address + type enum)
- preferred_channel: enum [phone, email, sms, other]
- lifecycle_stage: enum [prospect, customer, past_customer]
- source: enum [manual, web_form, import_google_contacts, import_csv, api]
- tags: string[]
- owner_user_id: string
- google_resource_name: string (nullable) – People API resourceName, e.g. “people/xxxx”.
- google_etag: string (for optimistic concurrency).
- quickbooks_customer_id: string (if you sync individuals as customers)
- metadata: json

**JSON schema (abridged)**

```
json{
  "type": "object",
  "required": ["id", "full_name", "owner_user_id"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "first_name": { "type": "string" },
    "last_name": { "type": "string" },
    "full_name": { "type": "string" },
    "company_id": { "type": "string" },
    "job_title": { "type": "string" },
    "emails": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["email"],
        "properties": {
          "email": { "type": "string", "format": "email" },
          "type": {
            "type": "string",
            "enum": ["work", "home", "other"]
          },
          "primary": { "type": "boolean" }
        }
      }
    },
    "phones": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "number": { "type": "string" },
          "type": {
            "type": "string",
            "enum": ["mobile", "work", "home", "other"]
          },
          "primary": { "type": "boolean" }
        }
      }
    },
    "addresses": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "line1": { "type": "string" },
          "line2": { "type": "string" },
          "city": { "type": "string" },
          "state": { "type": "string" },
          "postal_code": { "type": "string" },
          "country": { "type": "string" },
          "type": {
            "type": "string",
            "enum": ["home", "work", "billing", "shipping", "other"]
          }
        }
      }
    },
    "preferred_channel": {
      "type": "string",
      "enum": ["phone", "email", "sms", "other"]
    },
    "lifecycle_stage": {
      "type": "string",
      "enum": ["prospect", "customer", "past_customer"]
    },
    "source": {
      "type": "string",
      "enum": ["manual", "web_form", "import_google_contacts", "import_csv", "api"]
    },
    "tags": { "type": "array", "items": { "type": "string" } },
    "owner_user_id": { "type": "string" },
    "google_resource_name": { "type": "string" },
    "google_etag": { "type": "string" },
    "quickbooks_customer_id": { "type": "string" },
    "metadata": { "type": "object" }
  }
}
```

------

## 2.3 Lead

Lead is the “top of funnel” record; for your audience, leads are “inquiries about jobs”.

**Main fields**

- id: string
- created_at, updated_at: datetime
- title: string – short label (“Kitchen sink leak”, “Wedding catering 120 ppl”)
- description: text – freeform description.
- contact_id: string (nullable)
- company_id: string (nullable)
- email, phone: string (for pre-contact captured via web form or call)
- source: enum [phone_call, email, web_form, referral, ad, other]
- status: enum [new, working, qualified, disqualified, converted]
- disqualification_reason: enum [budget, timing, outside_scope, competitor, no_response, other]
- estimated_value: decimal (e.g., job size)
- probability: integer 0–100
- owner_user_id: string
- pipeline_stage: enum [inquiry, needs_analysis, estimate_sent, follow_up, scheduled_visit]
- expected_close_date: date
- converted_opportunity_id: string (nullable)
- tags: string[]
- metadata: json

**JSON schema (abridged)**

```
json{
  "type": "object",
  "required": ["id", "status", "owner_user_id"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "title": { "type": "string" },
    "description": { "type": "string" },
    "contact_id": { "type": "string" },
    "company_id": { "type": "string" },
    "email": { "type": "string", "format": "email" },
    "phone": { "type": "string" },
    "source": {
      "type": "string",
      "enum": ["phone_call", "email", "web_form", "referral", "ad", "other"]
    },
    "status": {
      "type": "string",
      "enum": ["new", "working", "qualified", "disqualified", "converted"]
    },
    "disqualification_reason": {
      "type": "string",
      "enum": ["budget", "timing", "outside_scope", "competitor", "no_response", "other", "none"]
    },
    "estimated_value": { "type": "number" },
    "probability": { "type": "integer", "minimum": 0, "maximum": 100 },
    "owner_user_id": { "type": "string" },
    "pipeline_stage": {
      "type": "string",
      "enum": ["inquiry", "needs_analysis", "estimate_sent", "follow_up", "scheduled_visit"]
    },
    "expected_close_date": { "type": "string", "format": "date" },
    "converted_opportunity_id": { "type": "string" },
    "tags": { "type": "array", "items": { "type": "string" } },
    "metadata": { "type": "object" }
  }
}
```

------

## 2.4 Opportunity

Opportunity is the “job” that may be repeated (service contracts, recurring maintenance).

**Main fields**

- id: string
- created_at, updated_at: datetime
- name: string (“Replace water heater at 123 Main”)
- description: text
- contact_id, company_id: string
- lead_id: string (nullable, original lead)
- stage: enum [qualification, estimating, proposal_sent, negotiating, scheduled, won, lost, canceled] (clearly defined entry/exit criteria).
- reason_lost: enum [price, competition, timing, no_decision, scope, other]
- amount: decimal – expected revenue.
- probability: integer 0–100
- close_date: date (expected or actual)
- owner_user_id: string
- source: enum [lead_conversion, repeat_customer, upsell, referral, other]
- job_location: object (address)
- service_type: string (free text, or reference to a “service catalog” in a later iteration)
- tags: string[]
- quickbooks_customer_id: string (nullable)
- quickbooks_last_invoice_id: string (nullable)
- metadata: json

**JSON schema (abridged)**

```
json{
  "type": "object",
  "required": ["id", "name", "stage", "owner_user_id"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "name": { "type": "string" },
    "description": { "type": "string" },
    "contact_id": { "type": "string" },
    "company_id": { "type": "string" },
    "lead_id": { "type": "string" },
    "stage": {
      "type": "string",
      "enum": [
        "qualification",
        "estimating",
        "proposal_sent",
        "negotiating",
        "scheduled",
        "won",
        "lost",
        "canceled"
      ]
    },
    "reason_lost": {
      "type": "string",
      "enum": ["price", "competition", "timing", "no_decision", "scope", "other", "none"]
    },
    "amount": { "type": "number" },
    "probability": { "type": "integer", "minimum": 0, "maximum": 100 },
    "close_date": { "type": "string", "format": "date" },
    "owner_user_id": { "type": "string" },
    "source": {
      "type": "string",
      "enum": ["lead_conversion", "repeat_customer", "upsell", "referral", "other"]
    },
    "job_location": {
      "type": "object",
      "properties": {
        "line1": { "type": "string" },
        "line2": { "type": "string" },
        "city": { "type": "string" },
        "state": { "type": "string" },
        "postal_code": { "type": "string" },
        "country": { "type": "string" }
      }
    },
    "service_type": { "type": "string" },
    "tags": { "type": "array", "items": { "type": "string" } },
    "quickbooks_customer_id": { "type": "string" },
    "quickbooks_last_invoice_id": { "type": "string" },
    "metadata": { "type": "object" }
  }
}
```

------

## 2.5 Interaction (activity history)

Interaction captures mails, calls, appointments, and notes so AI can reason about the relationship.

**Main fields**

- id: string
- created_at, updated_at: datetime
- type: enum [email_inbound, email_outbound, phone_call, sms, meeting, note, system]
- direction: enum [inbound, outbound, internal] (for calls/emails)
- timestamp: datetime
- actor_user_id: string (nullable; internal user)
- contact_id, lead_id, opportunity_id: string (nullable; at least one must be non-null)
- subject: string
- body: text – canonicalized plain text (for emails, AI summary; full raw stored elsewhere if needed).
- channel_metadata: json
  - For email: message_id, thread_id, gmail_label_ids, from, to, cc, bcc.
  - For calendar: event_id, calendar_id.
  - For phone: duration, recording_url.
- outcome: enum [none, left_voicemail, spoke, no_show, rescheduled, sent_proposal, accepted_proposal, rejected_proposal]
- follow_up_date: datetime (nullable)
- follow_up_status: enum [none, pending, completed, canceled]
- ai_summary: text – short summary.
- ai_suggested_next_actions: json (optional)
- is_auto_generated: boolean
- metadata: json

**JSON schema (abridged)**

```
json{
  "type": "object",
  "required": ["id", "type", "timestamp"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "type": {
      "type": "string",
      "enum": [
        "email_inbound",
        "email_outbound",
        "phone_call",
        "sms",
        "meeting",
        "note",
        "system"
      ]
    },
    "direction": {
      "type": "string",
      "enum": ["inbound", "outbound", "internal", "none"]
    },
    "timestamp": { "type": "string", "format": "date-time" },
    "actor_user_id": { "type": "string" },
    "contact_id": { "type": "string" },
    "lead_id": { "type": "string" },
    "opportunity_id": { "type": "string" },
    "subject": { "type": "string" },
    "body": { "type": "string" },
    "channel_metadata": { "type": "object" },
    "outcome": {
      "type": "string",
      "enum": [
        "none",
        "left_voicemail",
        "spoke",
        "no_show",
        "rescheduled",
        "sent_proposal",
        "accepted_proposal",
        "rejected_proposal"
      ]
    },
    "follow_up_date": { "type": "string", "format": "date-time" },
    "follow_up_status": {
      "type": "string",
      "enum": ["none", "pending", "completed", "canceled"]
    },
    "ai_summary": { "type": "string" },
    "ai_suggested_next_actions": { "type": "object" },
    "is_auto_generated": { "type": "boolean" },
    "metadata": { "type": "object" }
  }
}
```

------

## 2.6 User and integration tokens

**User**

- id, created_at, updated_at
- email, name
- role: enum [owner, admin, user]
- timezone, locale
- google_oauth_connected: boolean
- quickbooks_oauth_connected: boolean

**IntegrationToken**

- id
- user_id
- provider: enum [google, quickbooks]
- access_token, refresh_token, expires_at
- scopes: string[]
- metadata: json (e.g., Google account email, QuickBooks realmId).

------

## 2.7 Quick comparison table

| Entity      | Primary purpose     | Key external mappings                            |
| :---------- | :------------------ | :----------------------------------------------- |
| Company     | Account/customer    | QuickBooks Customer, possibly Google domain name |
| Contact     | Person              | Google People contact, optional QuickBooks cust. |
| Lead        | Unqualified inquiry | Web form/email source only                       |
| Opportunity | Qualified job/deal  | QuickBooks Customer + Invoice references         |
| Interaction | Comms + history     | Gmail message, Calendar event, call record       |

------

## 3. Core workflows

## 3.1 Lead capture workflow

## Sources

- Web form (e.g., job request on website).
- Inbound phone calls (CSR keying in details).
- Inbound emails (Gmail integration).

## Web form → Lead

1. Web form posts to `/public/leads` with fields: name, email, phone, description, service_type, preferred_time.
2. Backend:
   - Normalize contact (trim, lower-case email).
   - Match existing Contact by email or phone; if found, set contact_id and company_id.
   - Create Lead with status=new, stage=inquiry, source=web_form.
   - Create Interaction of type=email_inbound or note with body=web form contents.
   - Optionally create a task/follow-up Interaction with follow_up_date = now + 1 business hour.

## Phone call → Lead

1. CSR opens “New Inquiry” screen, enters caller info.
2. System attempts fuzzy match on phone number and name to existing Contact/Company.
3. Same logic as web form to create Lead + Interaction of type=phone_call.

## Gmail inbound email → Lead / Interaction

1. For each user with Google connected, run periodic sync or webhook via Gmail API (via Pub/Sub) capturing new messages in specified labels (e.g., “Leads”, “Support”).
2. For a new email:
   - Determine if matches existing Contact email; if yes, create Interaction tied to Contact (and to open Lead/Opportunity if last activity < N days).
   - If no match, create new Lead with email, subject as title, body snippet as description, source=email.
   - Create Interaction with channel_metadata.message_id, thread_id.
3. Update lead status from new → working and set owner to user if assigned.

------

## 3.2 Contact lifecycle

## Creation and enrichment

- Created implicitly from Leads or explicitly by user.
- AI agent can parse freeform description into structured fields (service_type, budget, location).
- If Google Contacts integration enabled, you can optionally push new Contacts into Google People with minimal fields.

## Stages

- prospect: only inquiries, no closed jobs.
- customer: at least one Opportunity stage=won.
- past_customer: no jobs in last N months; set via nightly job.

## Merge / dedupe

Design an idempotent merge operation:

- Merge candidate contacts by identical email/phone.
- Winner Contact retains id; losing Contact ids are referenced in a ContactMerge table for audit.
- Merge arrays (emails, phones, tags) with uniqueness on value.

------

## 3.3 Lead → Opportunity conversion

From a “qualified” Lead:

1. User clicks “Convert lead”.
2. System:
   - Ensure Contact exists (create if needed based on Lead.email/phone).
   - Ensure Company exists (if company name captured).
   - Create Opportunity with:
     - name derived from Lead.title + company name.
     - amount = estimated_value.
     - stage = estimating or proposal_sent, depending on workflow.
     - link to lead_id.
   - Set Lead.status=converted and converted_opportunity_id.
3. Link all future Interactions (e.g., estimate email, site visit) primarily to Opportunity.

------

## 3.4 Interaction and follow-up workflow

Design around simple rules the small business can understand:

- Every new Interaction may generate a follow-up action.
- Follow-up is modeled via follow_up_date and follow_up_status on Interaction.
- Example rule set:
  - When stage moves to proposal_sent → create Interaction (system) with follow_up_date = T+3 days; ai_suggested_next_actions contains email draft.
  - When a meeting is created in Calendar for job estimate → Interaction type=meeting with follow_up_date = same-day evening for internal notes.

------

## 4. Google Workspace integration

You mainly need Gmail, Calendar, and People API.

## 4.1 Authentication and scopes

Per-user OAuth 2.0 with offline access; store tokens in IntegrationToken.

- Gmail: scopes like `https://www.googleapis.com/auth/gmail.readonly` and `gmail.modify` if you want to apply labels.
- Calendar: `https://www.googleapis.com/auth/calendar.events`.
- People API: `https://www.googleapis.com/auth/contacts` and/or `contacts.readonly` depending on whether you write back.

------

## 4.2 Gmail: email → Interaction

Design a stateless sync worker per user:

1. Maintain a “last historyId” cursor per user.
2. Use Gmail history or Pub/Sub to fetch new messages in relevant labels.
3. For each message:
   - Normalize “from” and “to” addresses.
   - Attempt to match to Contact by email.
   - Build Interaction with:
     - type email_inbound/outbound, direction inbound/outbound;
     - subject from message;
     - body from text/plain or HTML-to-text;
     - channel_metadata: Gmail message_id, thread_id, label_ids.
   - Call AI summarizer to produce ai_summary and suggestions.
4. De‑duplicate by storing gmail_message_id on Interaction.

Optional: show Gmail thread context in the UI by linking back to `https://mail.google.com/mail/u/0/#inbox/<threadid>`.

------

## 4.3 Calendar: events → meetings

Use Calendar API to sync events tagged as “job visits” or “estimates”.

1. User connects Google and chooses which calendars to sync.
2. For each selected calendar, store calendar_id and sync token.
3. Use `events.list` with `syncToken` to incrementally load new/updated events.
4. For each event:
   - If event has attendees containing a contact email or has a location matching job address, tie to Opportunity/Contact.
   - Create or update Interaction type=meeting:
     - timestamp = start.dateTime;
     - subject = summary;
     - body = description;
     - channel_metadata.event_id, calendar_id, start, end, hangoutLink.
   - If event is canceled, mark Interaction as canceled.
5. Optionally, when a user schedules an estimate from the CRM, create the event via `events.insert` and add context into description.

------

## 4.4 People API: contacts sync

Keep this lightweight to avoid spamming users’ address books.

Patterns:

- One‑way read:
  - On initial connection, pull People connections via `people.connections.list` with `personFields=names,emailAddresses,phoneNumbers`.
  - For each Person, create or match a CRM Contact; store google_resource_name and etag.
  - Use this to enrich missing phone/email fields.
- Optional write‑back:
  - When CRM Contact is marked `sync_to_google=true`, call `people.createContact` or `people.updateContact` to push names, email, phone.
  - Use etag for concurrency; store the returned google_resource_name.

Avoid full two-way sync initially; prefer CRM-as-source-of-truth with one‑way enrichment from Google.

------

## 5. QuickBooks Online sync patterns

Your primary integration need is syncing customers (Company/Contact) and possibly linking Opportunities to invoices.

## 5.1 Authentication and setup

- OAuth 2.0 with scopes including `com.intuit.quickbooks.accounting`.
- Store realmId (company id) alongside tokens.
- QuickBooks API minorVersion ≥ 75 to be future‑proof, as older versions are being discontinued.

## 5.2 Data model alignment

QuickBooks Customer entity has fields like DisplayName, GivenName, FamilyName, PrimaryEmailAddr, PrimaryPhone, BillAddr, ShipAddr, and supports CustomField arrays in newer premium APIs.

For a service-business CRM:

- Map Company to QuickBooks Customer when the customer is an organization.
- Map individual Contact (no company) to QuickBooks Customer when working with homeowners.
- Optionally use Custom Fields API to store CRM ids (e.g., company.id or contact.id) on the QuickBooks Customer as metadata.

## 5.3 Sync strategies

Use a “write-once-on-demand, update opt-in” model:

- Direction: CRM → QuickBooks for customer creation; QuickBooks → CRM for balance/summary only.
- Trigger:
  - When an Opportunity becomes stage=won, present “Create customer in QuickBooks” if not already mapped.
  - Or, nightly job to ensure all active customers exist in QuickBooks.

**Customer create request (conceptual)**

```
json{
  "DisplayName": "Acme Plumbing, LLC",
  "PrimaryEmailAddr": { "Address": "billing@acmeplumbing.com" },
  "PrimaryPhone": { "FreeFormNumber": "+1-555-123-4567" },
  "BillAddr": {
    "Line1": "123 Main St",
    "City": "Madison",
    "CountrySubDivisionCode": "WI",
    "PostalCode": "53703"
  },
  "ShipAddr": {
    "Line1": "123 Main St",
    "City": "Madison",
    "CountrySubDivisionCode": "WI",
    "PostalCode": "53703"
  },
  "CustomField": [
    {
      "DefinitionId": "540344",
      "Name": "crm_company_id",
      "Type": "StringType",
      "StringValue": "a032d6b2-..."
    }
  ]
}
```

CustomField usage follows the pattern introduced in the Custom Fields API: define custom fields via GraphQL, apply via REST with `include=enhancedAllCustomFields` and minorversion=75.

## 5.4 One-time import of customers

For onboarding:

1. Fetch all active Customers from QuickBooks via `/v3/company/{realmId}/query` (paged).
2. For each Customer:
   - Attempt to match CRM Company/Contact by DisplayName + email/phone.
   - If no match, create Company or Contact with quickbooks_customer_id populated.
3. Maintain a mapping table to help dedupe and track import.

## 5.5 Data consistency and throttling

- Implement backoff and respect QBO limits; post‑2025 Batch endpoints are throttled and older minor versions are deprecated, so centralize rate limit handling.
- Store last_sync_at, last_sync_status per mapped Company/Contact.

------

## 6. AI agents for automation

You have a natural fit for AI in three areas:

1. Parsing and normalizing inbound unstructured data.
2. Suggesting and/or sending follow-ups.
3. Keeping data “clean” (dedupe, field completion, notes summarization).

## 6.1 AI architecture components

- AI Orchestrator service
  - Exposes APIs like `/ai/parse-lead`, `/ai/summarize-interaction`, `/ai/suggest-followup`.
  - Handles prompt templates, model selection, and safety.
- Embeddings / vector index (optional in v1) for semantic search across Interactions.
- Background job workers to apply AI as events arrive.

## 6.2 AI-assisted data entry

**Use cases**

- New Lead from web form/email: structure free text description into fields (service_type, urgency, budget_range, location).
- New Contact: infer job_title, company from email signature.
- Interaction: summarize long email thread, extract commitments, and update Opportunities.

**Example: `/ai/parse-lead` input/output**

Input:

```
json{
  "free_text": "Hi, our restaurant needs catering for 80 guests on March 14, dinner buffet. Budget around $4k. We need vegetarian options.",
  "channel": "web_form"
}
```

Output (model-completed):

```
json{
  "service_type": "event catering",
  "industry": "restaurant",
  "party_size": 80,
  "event_date": "2026-03-14",
  "budget_min": 3500,
  "budget_max": 4500,
  "special_requirements": ["vegetarian options"],
  "urgency": "medium"
}
```

You then map these into Lead.metadata and Opportunity fields.

## 6.3 AI follow-up agent

Follow-up automation is where AI agents shine for small teams.

**Core loop**

1. Nightly job finds “attention needed” records:
   - Leads where status in [new, working] and no Interaction in last N days.
   - Opportunities in proposal_sent stage without follow-up in 3–5 days.
2. For each, gather context:
   - Contact name, last Interactions (latest 3).
   - Stage, amount, expected_close_date.
3. Call `/ai/suggest-followup` which returns:
   - recommended_channel, recommended_time_offset, email_draft, sms_draft, call_script.
4. Either:
   - create Interaction with follow_up_date and ai_suggested_next_actions, and show to user for approval; or
   - if user opted-in, auto-send email using Gmail API (from their account).

**Example follow-up payload**

```
json{
  "contact": {
    "name": "Jane Doe",
    "preferred_channel": "email"
  },
  "opportunity": {
    "name": "Kitchen remodel plumbing",
    "stage": "proposal_sent",
    "amount": 8200
  },
  "last_interactions": [
    {
      "timestamp": "2026-02-10T15:00:00Z",
      "type": "email_outbound",
      "body": "Sent proposal and itemized quote..."
    }
  ],
  "ai_recommendation": {
    "recommended_channel": "email",
    "recommended_time_offset_hours": 72,
    "email_subject": "Quick check-in on your plumbing proposal",
    "email_body": "Hi Jane,\n\nJust checking in to see if you had any questions about..."
  }
}
```

When sending via Gmail, you create an outbound Interaction with is_auto_generated=true and store Gmail message_id.

------

## 6.4 AI-powered hygiene: dedupe, enrichment, risk

- Dedupe agent: periodically scans new Contacts/Companies, computes similarity on names/emails/phones, and proposes merges.
- Enrichment agent: uses patterns from prior jobs to suggest missing fields (e.g., service_type, typical amount range).
- Risk agent: analyzes Interactions to flag “at risk” Opportunities (negative sentiment, stalled communication).

------

## 7. Implementation notes (at architect level)

## 7.1 Storage and indexing

- Use a normalized relational schema (PostgreSQL/MySQL) with JSONB for metadata.
- Key indexes:
  - Contact.email, Contact.phones.number (GIN for arrays).
  - Interaction.contact_id/lead_id/opportunity_id + timestamp desc.
  - Lead.status, Lead.owner_user_id.
  - Opportunity.stage, Opportunity.owner_user_id.

Soft-delete with `deleted_at` fields for all entities; hide by default queries.

## 7.2 Event model

Define internal domain events:

- `lead.created`, `lead.converted`, `opportunity.stage_changed`, `interaction.created`, `user.connected_google`, `user.connected_quickbooks`.

Use them to:

- Trigger AI jobs.
- Trigger Google/QuickBooks calls.
- Drive a simple “automation rules” engine later (if stage = proposal_sent then create follow-up).

------

## 7.3 Minimal REST API surface (example)

- `/contacts` CRUD
- `/companies` CRUD
- `/leads` CRUD + `/leads/{id}/convert`
- `/opportunities` CRUD + `/opportunities/{id}/stage`
- `/interactions` CRUD
- `/integrations/google/connect`, `/integrations/google/webhook`
- `/integrations/quickbooks/connect`, `/integrations/quickbooks/customers/sync`
- `/ai/parse-lead`, `/ai/summarize-interaction`, `/ai/suggest-followup`