## 1. Google Workspace API and Auth Architecture

Google Workspace APIs are standard REST+JSON services protected by OAuth 2.0.

## 1.1 Core auth patterns

- **User delegated OAuth 2.0 (3‑legged)**
  - Used when users explicitly connect their Google account and you act only on their data.
  - Flow: Your app redirects to Google → user consents → Google redirects back with code → your backend exchanges code for access+refresh tokens.
  - Typical scopes:
    - Gmail: `https://www.googleapis.com/auth/gmail.modify` for read/send with label mutations.
    - Calendar: `https://www.googleapis.com/auth/calendar`.
    - Drive: `https://www.googleapis.com/auth/drive` or more narrow.
    - Sheets: `https://www.googleapis.com/auth/spreadsheets`.
    - Docs: `https://www.googleapis.com/auth/documents`.
    - Contacts: `https://www.googleapis.com/auth/contacts` for People API.
- **Service accounts**
  - Non-human principals with a key pair, used for backend-to-Google calls.
  - Without domain-wide delegation, they own their own Drive, can access shared documents, and can be used for “system” spreadsheets/docs.
- **Domain-wide delegation of authority (DWD)**
  - Workspace super admin authorizes a service account to impersonate any user for specified scopes; this allows central integration without each user doing OAuth.
  - Admin console: Security → Access and data control → API controls → Domain-wide delegation → add client ID and scopes, then your backend calls Google APIs with `sub=user@domain`.

## 1.2 Key APIs per product

- **Gmail API** (`gmail.googleapis.com`)
  - Read, search, send messages, manage labels, watch for changes (push notifications).
- **Calendar API** (`calendar.googleapis.com`)
  - Manage calendars and events (CRUD, attendees, reminders, watch for changes).
- **Drive API** (`drive.googleapis.com`)
  - CRUD on files/folders, permissions, search (query language), shared drives.
- **Sheets API** (`sheets.googleapis.com`)
  - Read/write ranges, append rows, format cells, manage sheets and spreadsheets.
- **Docs API** (`docs.googleapis.com`)
  - Create/modify Docs via a document model and batchUpdate.
- **People API (Contacts)** (`people.googleapis.com`)
  - Read and manage contacts, list connections, create/update/delete contacts.

------

## 2. Integration Architecture Overview

Your custom platform should have a **Workspace Integration Service** sitting behind your main backend.

## 2.1 Components

- **Auth and token service**
  - Stores per-user OAuth tokens and/or uses service account with DWD.
  - Normalizes tokens in a “WorkspaceAccount” table (user, domain, scopes, tokens, expiry).
- **Sync and orchestration workers**
  - Gmail sync worker, Calendar sync worker, Drive structuring worker, Contacts sync worker, Sheets/Docs reporting worker.
  - Event-driven (webhooks from Google + internal job queue).
- **Domain model in your platform**
  - Contacts/companies.
  - Activities (emails, meetings, calls).
  - Projects/deals with stages and milestones.
  - Documents (metadata pointing at Drive file IDs).
  - Metrics and reports (backed by Sheets).
- **AI agent layer**
  - Stateless or lightly stateful service that:
    - Reads context via your domain model.
    - Calls Workspace APIs through the integration service as tools.
    - Proposes or performs actions (draft emails, create meetings, generate docs).

## 2.2 Data isolation and tenancy

- For multi-tenant SaaS, map **Workspace domain → tenant**.
- Ensure all Workspace calls are scoped to the right tenant by:
  - Restricting which user accounts can connect.
  - Using service account DWD only for that tenant’s domain.

------

## 3. Gmail Integration for CRM Email Logging and AI Drafting

## 3.1 Use cases

- Auto-log email threads to CRM contacts/companies.
- Capture inbound and outbound messages with minimal latency.
- Allow AI to generate suggested replies and outbound outreach emails.

## 3.2 Email logging design

**Data model**

- `EmailMessage` (in your DB):
  - `id`
  - `gmail_message_id`
  - `gmail_thread_id`
  - `subject`
  - `from`, `to`, `cc`, `bcc`
  - `sent_at`, `received_at`
  - `direction` (inbound/outbound)
  - `snippet` or short body
  - `body_html` / `body_text` (if needed)
  - `contact_id` / `company_id` / `deal_id` foreign keys
  - `user_id` (owner)
  - `labels` (normalized label IDs)

**API call sequence: initial sync**

1. Obtain access token (user OAuth or service account+DWD).
2. List messages:
   - `GET https://gmail.googleapis.com/gmail/v1/users/me/messages?q=after:2025/01/01` or label filters.
3. For each message:
   - `GET .../users/me/messages/{id}?format=full`.
   - Parse headers, body parts, and labels.
   - Map participants to CRM contacts by email address and create/update contacts.
   - Insert `EmailMessage` linked to contacts/companies.

**Incremental sync**

- Use `history.list` with the last historyId to get new/changed messages, or use `watch`:
  - Setup `watch`:
    - `POST .../users/me/watch` with pub/sub topic and label filters.
  - When notification arrives:
    - Call `history.list` to see which messages changed.
    - Fetch and persist.

**Logging outbound emails sent from your app**

1. User composes in your UI.
2. Backend calls `users.messages.send` with MIME message:
   - `POST .../users/me/messages/send`.
3. Gmail assigns message/thread IDs; you upsert them into `EmailMessage`.
4. Optionally apply a CRM label via `users.messages.modify`.

## 3.3 AI-assisted drafting

**Context gathering**

- For a “draft reply”:
  - Fetch recent messages in the thread: `users.messages.get` × N.
  - Pull CRM context (contact details, deal stage, last activities).
- Pass to your LLM with instructions: “Draft a concise reply, in the user’s tone X, keep under 200 words.”

**Actions**

- Generated draft is stored as:
  - a Gmail draft via `users.drafts.create`, or
  - directly as `users.messages.send` if auto-send is allowed.
- Provide a UI for the human to:
  - Accept/send.
  - Edit.
  - Decline.

**AI logging sequence**

1. User selects “AI reply”.
2. Backend calls Gmail to fetch thread context.
3. Backend calls AI (your engine) with context.
4. AI returns draft text.
5. Backend creates Gmail draft and an `EmailMessage` in “draft” status.
6. On user send, mark as “sent” after Gmail confirms.

------

## 4. Google Calendar Integration for Scheduling and Milestones

## 4.1 Use cases

- Show project calendars, personal calendars, and availability.
- Create events for customer meetings tied to CRM records.
- Map project milestones to calendar events.

## 4.2 Calendar and event model

- Use `Calendar` and `Event` resources.
- Store:
  - `calendar_id` (e.g., `primary` or project-specific).
  - `event_id`.
  - `project_id`, `contact_id`, `deal_id`.
  - `start`, `end`, `attendees`, `location`, `hangoutLink`/conference data.

## 4.3 API call sequences

**List calendars and events**

1. `GET /calendar/v3/users/me/calendarList` to show user calendars.
2. For a chosen calendar, list events:
   - `GET /calendar/v3/calendars/{calendarId}/events?timeMin=...&timeMax=...`.

**Create meeting for a contact**

1. User picks contact and time.
2. Backend builds `Event`:
   - `summary`, `description` (include CRM link), `start`, `end`, `attendees`, `reminders`.
3. Call:
   - `POST /calendar/v3/calendars/primary/events?sendUpdates=all`.
4. Store `event_id` and link to contact/company/project.

**Project milestones as events**

- When a project stage is scheduled:
  - Create or update a dedicated “Project: X” calendar.
    - `POST /calendar/v3/calendars` (only once per project if using separate calendars).
  - Map milestones to events:
    - `Event.summary = "Milestone: Design Complete"`.
    - Description includes project metadata.
    - `POST .../events`.

**Change tracking**

- Use `events.watch` with push notifications for updates, or poll with `syncToken` returned by `events.list`.
- On event changes:
  - Update your DB.
  - Recompute derived project timelines if needed.

------

## 5. Google Drive Integration and DMS Structure

## 5.1 Drive DMS principles

Drive provides user “My Drive” and shared drives, with file and folder metadata and fine-grained permissions.

Recommended pattern:

- Maintain one **shared drive per tenant** (or per business unit) as the “System Drive”.
- Within that, enforce a deterministic folder hierarchy for your platform.

## 5.2 Folder structure design

Example for a CRM/project system:

- `/CRM`
  - `/Contacts/{ContactName} – {ContactId}`
  - `/Companies/{CompanyName} – {CompanyId}`
- `/Projects`
  - `/Projects/{ProjectCode} – {ProjectName}/`
    - `/01 – Contracts`
    - `/02 – Design`
    - `/03 – Deliverables`
- `/Reports`
  - `/Dashboards`
  - `/Exports`

Store the **Drive folder ID** on your entities:

- `contact.drive_folder_id`
- `company.drive_folder_id`
- `project.drive_folder_id`

## 5.3 Drive API sequences

**Create base shared drive (one-time per tenant)**

- `POST https://www.googleapis.com/drive/v3/drives` with `name`.

**Create structured folders**

- `POST /drive/v3/files`
  - body: `{ name, mimeType: "application/vnd.google-apps.folder", parents: [parentId], driveId, supportsAllDrives: true }`.

**Linking documents**

- For a “New project contract” action:
  1. Look up `project.drive_folder_id` and `contracts` subfolder.
  2. Create a Google Doc:
     - `POST /drive/v3/files` with `mimeType: "application/vnd.google-apps.document"`, parent = contracts folder.
  3. Optionally, call Docs API to insert a template body (see section 6).

**Permissions**

- Use `permissions.create` to:
  - Add project team as editors.
  - Add client contact’s Google account as viewer/commenter if allowed.

**Search and discovery**

- Use Drive query syntax, e.g.:
  - `name contains '{ProjectCode}' and mimeType='application/vnd.google-apps.folder' and 'driveId' in parents`.
- Store results in your metadata to avoid repeated queries.

------

## 6. Google Sheets for Reporting and Dashboards

## 6.1 Use cases

- Expose analytics and tabular reports in Sheets.
- Let users build their own charts/queries on top of synced data.

Sheets is a REST interface for spreadsheet data, enabling create/read/write/format operations.

## 6.2 Data mapping

Typical patterns:

- One spreadsheet per tenant; sheets for:
  - `Deals`, `Projects`, `Activities`, `Invoices`.
- Columns are normalized fields from your DB.

Example mapping for a `Deals` sheet:

| Column | CRM field  |
| :----- | :--------- |
| A      | deal_id    |
| B      | name       |
| C      | stage      |
| D      | amount     |
| E      | owner      |
| F      | created_at |
| G      | close_date |

## 6.3 API sequences

**Create reporting spreadsheet**

1. `POST https://sheets.googleapis.com/v4/spreadsheets` with `properties.title`.
2. Store `spreadsheetId` as tenant’s report object.

**Initial data load**

- Use `spreadsheets.values.batchUpdate` with multiple ranges:
  - Each range for a table (e.g. `Deals!A1:G1000`).

**Incremental updates**

- For daily sync:
  - Rebuild the relevant sheet with truncate+rewrite, or:
    - Use `values.update` for row-level updates using `deal_id` as key.
- For near-real-time:
  - Use an internal change log and a worker that:
    - Resolves row number by ID (maintain an index sheet mapping IDs to row numbers).
    - Updates only changed rows.

**Formatting and charts**

- Use `spreadsheets.batchUpdate` with `UpdateCellsRequest`, `RepeatCellRequest`, and `AddChartRequest` for visual dashboards.

------

## 7. Google Docs for Document Templates

Docs API allows you to create and modify Docs documents programmatically.

## 7.1 Use cases

- Contract generation from CRM data.
- Proposals, SOWs, project briefs.

## 7.2 Template pattern

- Create a “master template” Doc per type (e.g., Contract Template).
- Insert placeholder tokens like `{{ClientName}}`, `{{ProjectName}}`, `{{StartDate}}`.

**API sequence: generate contract**

1. Duplicate template via Drive:
   - `POST /drive/v3/files/{templateId}/copy` with new name and parent folder.
2. Call Docs API `documents.batchUpdate` with `ReplaceAllTextRequest` for each placeholder:
   - e.g. replace `{{ClientName}}` with actual name.
3. Store resulting `documentId` and link it to project.

------

## 8. Google Contacts / People API CRM Sync

## 8.1 Data model and direction

People API exposes contacts, “Other contacts”, and profile data.

Decide:

- Authoritative source: your CRM or Google Contacts.
- Recommended: your CRM is primary; Google Contacts is a convenience sync for end users.

**Field mapping example**

- Your `Contact` ↔ People `person`:
  - `contact.id` ↔ stored in `person.userDefined` metadata or in your DB mapped by `resourceName`.
  - `given_name`, `family_name` ↔ `names.givenName`, `names.familyName`.
  - `email` ↔ `emailAddresses.value`.
  - `phone` ↔ `phoneNumbers.value`.
  - `company` ↔ `organizations.name`.
  - tags/segments ↔ `userDefined` fields.

## 8.2 API sequences

**List user contacts**

- `GET /v1/people/me/connections?personFields=names,emailAddresses,phoneNumbers,organizations,userDefined`.

**Create/update contacts from CRM**

1. When CRM contact is created and user chooses “sync to Google”:
   - `POST /v1/people:createContact` with person object.
2. Store `resourceName` returned (e.g. `people/c123`).
3. On later changes:
   - `PATCH /v1/{resourceName}:updateContact?updatePersonFields=...` with new values.

**Import contacts from Google**

1. List connections.
2. For each, pick a primary email.
3. If email not in CRM, create contact; store `resourceName`.
4. If email exists, map as a linked external ID and possibly update fields based on conflict strategy.

------

## 9. Integration Architecture for Drive as a DMS

## 9.1 DMS capabilities

Drive’s metadata and permissions make it a capable document management system when combined with your platform’s structure.

Key features to implement:

- **Canonical mapping**: Every core entity has:
  - `drive_folder_id`
  - Optionally `primary_doc_id` (latest contract, SOW, etc.).
- **Lifecycle hooks**:
  - On entity creation: ensure folder exists.
  - On stage changes: add subfolders or docs.
  - On delete/archival: move folder to an `/Archive` hierarchy; avoid deleting by default.

## 9.2 Governance and naming

- Enforce naming patterns in code, not manually.
- Use IDs in folder/file names to avoid collisions, e.g. `ACME Corp – C1234`.
- Maintain a `DriveIndex` table to quickly resolve entity IDs -> Drive IDs without querying every time.

## 9.3 Permissions pattern

- For internal users: rely on shared drive membership and subfolder access control.
- For external users: per-file `permissions.create` with role viewer/commenter, optionally with expiration.
- Optionally log permission changes in your audit log.

------

## 10. AI Agents Interacting with Google Workspace

## 10.1 Patterns for AI agents

Google’s own Workspace agent platform (Workspace Studio, Gemini) demonstrates an “agentic” model where agents read context from Gmail, Drive, and Sheets and perform actions.

You can mirror this pattern:

- Treat each API operation as a **tool** available to your AI agent.
- The agent never sees tokens; your orchestration layer enforces auth and policies.
- The agent reasons: “To schedule a meeting, I need to call Calendar to find availability, then create an event.”

## 10.2 Tooling interface (examples)

Define internal tools like:

- `get_email_thread(thread_id)`
- `send_email(to, subject, body, thread_id?)`
- `list_calendar_events(time_range, attendees)`
- `create_meeting(contact_id, time_range, duration)`
- `search_drive(query, entity_context)`
- `generate_contract(project_id)`
- `update_sheet_report(report_id, metric_name, value)`

Each tool maps to one or more Google API calls plus your domain logic (e.g., associating events and documents with CRM records).

## 10.3 Policy and guardrails

- Restrict risky scopes:
  - E.g., read-only for some operations, separate service account for reporting-only.
- Implement **approval workflows**:
  - AI proposes changes, human approves (e.g., contract draft creation, emails to external recipients).
- Log all AI-initiated actions in an audit log:
  - Who (user on whose behalf), what, when, Workspace objects affected.

## 10.4 Example: AI meeting scheduler

**Goal:** “Schedule a 30-minute call with Alice next week.”

Sequence:

1. Agent uses CRM to resolve “Alice” → contact email.
2. Tool: `list_calendar_events` for the owner and Alice’s free/busy (if same domain).
   - Calls Calendar API freeBusy query (if you choose to use it) or just owner’s events.
3. Agent picks candidate slots.
4. Agent drafts an email with 2–3 proposed times via Gmail draft tool.
5. Once Alice confirms, agent:
   - Calls Calendar `events.insert` with final time, invites Alice, links event to CRM.

------

## 11. End-to-End Example Architectures

## 11.1 High-level component diagram

(Described textually.)

- **Frontend** (web/app):
  - CRM UI, project dashboard, document browser.
- **Backend (Core)**:
  - Business logic, data model, workflows.
- **Workspace Integration Service**:
  - Handles all Google API calls, token storage, sync workers, DMS rules.
- **AI Orchestration Layer**:
  - LLM, tools (Workspace+CRM), guardrails, observability.
- **Google Workspace**:
  - Gmail, Calendar, Drive, Sheets, Docs, People.

Data flows:

- UI actions → Core backend → Integration Service → Google APIs.
- Google webhooks (Gmail watch, Calendar events.watch, Drive changes) → Integration Service → Core backend updates → UI.
- AI tasks: Core backend → AI layer → Integration tools ↔ Workspace.

## 11.2 Example API call sequences summary

| Use case               | Sequence (simplified)                                        |
| :--------------------- | :----------------------------------------------------------- |
| Log emails             | `messages.list` → `messages.get` → map to contacts → store.  |
| AI draft reply         | `messages.get` (thread) → LLM draft → `drafts.create` or `messages.send`. |
| Create project meeting | `events.insert` on project/primary calendar → store event link. |
| Generate contract      | Drive `files.copy` template → Docs `documents.batchUpdate` → store Doc ID. |
| Sync contacts          | People `connections.list` ↔ `createContact`/`updateContact`. |
| Build reports          | Sheets `spreadsheets.create` → `values.batchUpdate` → optional formatting. |

------

## 12. Practical Implementation Notes

- Start with **user-delegated OAuth** for least friction; introduce service account+DWD later for admin-managed domains.
- Use client libraries for your language where possible:
  - They manage auth, pagination, and discovery documents.
- Apply backoff and retry for 429/5xx responses and enforce your own rate limiting.
- Plan a cleanup story for revocation:
  - Detect revoked access tokens and handle gracefully in your sync loops.