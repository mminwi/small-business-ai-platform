Core data model

You’ll want a ServiceContract as the root object, with related line items, occurrences, renewals, and links into scheduling and invoicing. At a minimum:

ServiceContract

id (UUID)

customer_id (internal customer record, which itself maps to QuickBooks Customer.Id)

external_accounting_customer_ref (QuickBooks customer id)

contract_number (human-readable)

contract_type (HVAC, Pest Control, Lawn, Pool, Cleaning, Other)

status (draft, pending_activation, active, paused, expired, canceled, renewal_pending)

term_start_date, term_end_date

initial_term_months (e.g., 12, 24)

auto_renew (bool)

billing_pattern (flat_monthly, per_visit, prepaid_annual, hybrid)

billing_interval (monthly, quarterly, annually, per_visit)

default_service_location_id (for multi-property customers)

service_window_preferences (time-of-day, weekday preferences)

payment_method_token (for card/ACH in your payments provider; QuickBooks PaymentMethodRef id if applicable)

quickbooks_sync_status (pending, synced, error)

quickbooks_last_invoice_id (last created)

pricing_summary (expected_annual_revenue, expected_mrr, discount_percent)

metadata (free-form JSON for vertical-specific settings)

created_at, updated_at

ContractLineItem (child of ServiceContract)

id

contract_id

service_code (internal SKU or pricebook item; maps to QuickBooks ItemRef)

description

frequency (weekly, biweekly, monthly, quarterly, semiannual, annual, ad_hoc)

occurrences_per_term (e.g., 2 tune-ups per year)

unit_price

billing_mode (included_in_flat_fee, bill_per_visit, bill_parts_only)

estimated_duration_minutes

technician_role (e.g., “HVAC Level 2”, “Crew of 3”)

location_id_override (optional)

ContractOccurrence (each scheduled or to-be-scheduled visit)

id

contract_id

line_item_id

scheduled_date (target date)

scheduled_time_window (start/end)

status (planned, scheduled, completed, skipped, canceled, failed)

work_order_id (link to your WorkOrder entity)

technician_ids (one or many)

reason_code (for skipped/canceled, e.g., customer_vacation)

invoice_id (link to QBO invoice if per-visit billing)

notes

ContractRenewal

id

contract_id

prior_term_start, prior_term_end

new_term_start, new_term_end

renewal_type (auto, manual)

price_change_percent

proposal_id (link to a Proposal/Estimate entity if you have one)

status (pending, sent_to_customer, accepted, rejected, lapsed)

triggered_at, decided_at

Relationships into work orders, scheduling, invoicing

ServiceContract 1–N ContractLineItem

ServiceContract 1–N ContractOccurrence

ServiceContract 1–N ContractRenewal

ContractOccurrence 1–1 WorkOrder (or Job)

WorkOrder 1–N TimesheetEntries, MaterialsUsed, etc.

WorkOrder 1–N InvoiceLines (via QuickBooks Invoice Line items)

This mirrors how tools like ServiceTitan define memberships with recurring services that generate jobs and tie into billing and follow-ups.

JSON schemas

These are representative JSON Schemas (Draft 7–style) you can adapt.

ServiceContract

json
{
  "$id": "https://example.com/schemas/ServiceContract.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ServiceContract",
  "type": "object",
  "required": [
    "id",
    "customer_id",
    "contract_number",
    "status",
    "term_start_date",
    "term_end_date",
    "billing_pattern"
  ],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "customer_id": { "type": "string" },
    "external_accounting_customer_ref": { "type": "string" },
    "contract_number": { "type": "string" },
    "contract_type": {
      "type": "string",
      "enum": ["HVAC", "PestControl", "LawnCare", "Pool", "Cleaning", "Other"]
    },
    "status": {
      "type": "string",
      "enum": [
        "draft",
        "pending_activation",
        "active",
        "paused",
        "expired",
        "canceled",
        "renewal_pending"
      ]
    },
    "term_start_date": { "type": "string", "format": "date" },
    "term_end_date": { "type": "string", "format": "date" },
    "initial_term_months": { "type": "integer", "minimum": 1 },
    "auto_renew": { "type": "boolean", "default": true },
    "billing_pattern": {
      "type": "string",
      "enum": ["flat_monthly", "per_visit", "prepaid_annual", "hybrid"]
    },
    "billing_interval": {
      "type": "string",
      "enum": ["per_visit", "monthly", "quarterly", "annually"]
    },
    "default_service_location_id": { "type": "string" },
    "service_window_preferences": {
      "type": "object",
      "properties": {
        "preferred_days_of_week": {
          "type": "array",
          "items": {
            "type": "string",
            "enum": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
          }
        },
        "time_window_start": { "type": "string" },
        "time_window_end": { "type": "string" }
      }
    },
    "payment_method_token": { "type": "string" },
    "quickbooks_sync_status": {
      "type": "string",
      "enum": ["never", "pending", "synced", "error"],
      "default": "never"
    },
    "quickbooks_last_invoice_id": { "type": "string" },
    "pricing_summary": {
      "type": "object",
      "properties": {
        "expected_annual_revenue": { "type": "number" },
        "expected_mrr": { "type": "number" },
        "discount_percent": { "type": "number" }
      }
    },
    "metadata": { "type": "object" },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
ContractLineItem

json
{
  "$id": "https://example.com/schemas/ContractLineItem.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ContractLineItem",
  "type": "object",
  "required": ["id", "contract_id", "service_code", "frequency"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "service_code": { "type": "string" },
    "description": { "type": "string" },
    "frequency": {
      "type": "string",
      "enum": [
        "weekly",
        "biweekly",
        "monthly",
        "quarterly",
        "semiannual",
        "annual",
        "ad_hoc"
      ]
    },
    "occurrences_per_term": { "type": "integer", "minimum": 1 },
    "unit_price": { "type": "number" },
    "billing_mode": {
      "type": "string",
      "enum": ["included_in_flat_fee", "bill_per_visit", "bill_parts_only"]
    },
    "estimated_duration_minutes": { "type": "integer" },
    "technician_role": { "type": "string" },
    "location_id_override": { "type": "string" },
    "metadata": { "type": "object" }
  }
}
ContractOccurrence

json
{
  "$id": "https://example.com/schemas/ContractOccurrence.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ContractOccurrence",
  "type": "object",
  "required": ["id", "contract_id", "line_item_id", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "line_item_id": { "type": "string", "format": "uuid" },
    "scheduled_date": { "type": "string", "format": "date" },
    "scheduled_time_window": {
      "type": "object",
      "properties": {
        "start": { "type": "string" },
        "end": { "type": "string" }
      }
    },
    "status": {
      "type": "string",
      "enum": [
        "planned",
        "scheduled",
        "completed",
        "skipped",
        "canceled",
        "failed"
      ]
    },
    "work_order_id": { "type": "string" },
    "technician_ids": {
      "type": "array",
      "items": { "type": "string" }
    },
    "reason_code": {
      "type": "string",
      "enum": [
        "none",
        "customer_vacation",
        "no_access",
        "weather",
        "equipment_failure",
        "other"
      ],
      "default": "none"
    },
    "invoice_id": { "type": "string" },
    "notes": { "type": "string" },
    "metadata": { "type": "object" }
  }
}
ContractRenewal

json
{
  "$id": "https://example.com/schemas/ContractRenewal.json",
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ContractRenewal",
  "type": "object",
  "required": ["id", "contract_id", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "prior_term_start": { "type": "string", "format": "date" },
    "prior_term_end": { "type": "string", "format": "date" },
    "new_term_start": { "type": "string", "format": "date" },
    "new_term_end": { "type": "string", "format": "date" },
    "renewal_type": {
      "type": "string",
      "enum": ["auto", "manual"]
    },
    "price_change_percent": { "type": "number" },
    "proposal_id": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["pending", "sent_to_customer", "accepted", "rejected", "lapsed"]
    },
    "triggered_at": { "type": "string", "format": "date-time" },
    "decided_at": { "type": "string", "format": "date-time" },
    "metadata": { "type": "object" }
  }
}
Contract lifecycle

States:

draft – created, not yet active.

pending_activation – signed but term_start_date in the future.

active – term_start_date reached, not paused/canceled/expired.

paused – temporarily on hold (billing and occurrences either halted or marked as paused).

renewal_pending – near end-of-term; renewal offer sent; still active until term_end.

expired – term_end passed, and no renewal accepted.

canceled – early termination.

Transitions and triggers:

draft → pending_activation

Trigger: contract approved (e-sign or internal), term_start_date in future.

Automation: generate initial set of ContractOccurrences for full term.

draft → active

Trigger: term_start_date is today or earlier and signed.

pending_activation → active

Trigger: cron/worker checks daily; when current_date ≥ term_start_date.

Automation: confirm occurrences are generated; first billing event if prepaid or flat.

active → paused

Trigger: user pause (customer request, delinquent payment).

Automation:

Option A: mark upcoming occurrences as paused, do not generate new ones.

Option B: keep schedule but mark occurrences as skipped with reason_code.

active → canceled

Trigger: explicit cancel; may include effective date.

Automation:

Cancel/skip future occurrences.

Stop future invoice generation.

Optionally create a final invoice (cancellation fee).

active → renewal_pending

Trigger: renewal workflow starting X days before term_end.

renewal_pending → active (new term)

Trigger: renewal accepted or auto-renewal executed.

Automation:

Create ContractRenewal record.

Update term_start_date/term_end_date (or create a new ServiceContract cloned from old).

Regenerate occurrences for the new term.

Adjust pricing_summary.

active/renewal_pending → expired

Trigger: current_date > term_end_date and no renewal accepted, or explicit non-renewal.

Automation: close out open occurrences (cancel remaining) and stop billing.

Automation hooks:

Work order generation

Nightly job (or ahead-of-time batch) scans active contracts, finds occurrences with status=planned in next N days, creates WorkOrders, assigns technicians by rules, and sets status=scheduled.

Similar to ServiceTitan’s recurring service events that populate a follow-up screen and get booked into jobs.

Renewal reminders

Scheduled tasks at T–90, T–60, T–30 days relative to term_end_date.

Generate an AI-drafted email + proposal; allow human review then send.

Auto-invoicing

On a schedule (daily):

Flat_monthly: create QuickBooks invoices each month.

Per_visit: create invoice upon WorkOrder completion.

Prepaid_annual: create 1 invoice at activation.

Hybrid: recurring fee invoices + ad-hoc parts invoices attached to jobs.

Scheduling integration

Recurring contracts drive your scheduling layer via ContractOccurrence.

Generating occurrences

On contract activation (or when line items are added), generate ContractOccurrences for the entire term based on frequency and occurrences_per_term.

For weekly/biweekly: use base weekday + interval offset from term_start_date.

For monthly/quarterly: use anchor day-of-month or rules like “first Monday.”

Keep occurrences as status=planned until inside a scheduling window (e.g., 30 days out).

Creating appointments/work orders

A scheduling worker looks at planned occurrences within the window and:

Creates a WorkOrder entity with references to contract_id and occurrence_id.

Applies default_service_location_id or line-item overrides.

Applies technician assignment rules (territory, skill, load balancing).

This matches how ServiceTitan uses recurring service events that are booked into jobs.
​

Skipped visits (customer vacation, etc.)

When a visit is skipped, set occurrence.status=skipped and reason_code=customer_vacation.

Business rule knob:

Option 1 (no make-up): do nothing; contract just has fewer visits that term.

Option 2 (make-up): generate a replacement occurrence with a new scheduled_date.

Date adjustments

Allow drag-and-drop reschedule in calendar UI; update occurrence.scheduled_date/time_window and associated WorkOrder date.

Preserve original planned date in metadata for reporting on adherence.

Multi-technician or crew assignments

ContractOccurrence.technician_ids is an array.

WorkOrder can carry crew_size or primary_tech + helpers.

Scheduling engine ensures capacity (e.g., total allocated minutes per technician per day).

Billing patterns and QuickBooks mapping

Patterns:

Flat monthly fee

Contract.billing_pattern = flat_monthly, billing_interval=monthly.

Expected behavior: same amount each month regardless of visits (like a membership).

QuickBooks:

The QBO API does not support creating recurring templates directly, so you schedule invoice creation in your platform and call the Invoice create endpoint per cycle.

Invoice lines: one line referencing a “Maintenance Plan” ItemRef with the monthly price.

Per-visit billing

billing_pattern = per_visit, billing_interval=per_visit.

On WorkOrder completion, create an invoice in QBO for that visit.

Line items may mirror ContractLineItems or actual materials used.

Prepaid annual

billing_pattern = prepaid_annual, billing_interval=annually.

At activation: create one invoice for the full annual amount.

Visits do not produce new invoices unless additional parts are billed.

Hybrid (monthly fee + parts)

billing_pattern = hybrid.

Monthly: a flat membership fee invoice.

Per job: an invoice or additional lines for parts/materials not included in contract.

QuickBooks API integration (core approach):

Since RecurringTransaction templates are managed inside QBO and not exposed to the Accounting API, you implement your own recurring schedule and call the Invoice endpoint yourself.

Mapping fields:

ServiceContract.external_accounting_customer_ref → Invoice.CustomerRef.value

ContractLineItem.service_code → Invoice.Line[].SalesItemLineDetail.ItemRef.value

Price fields → Invoice.Line[].Amount and UnitPrice.

For automatic email sending, set appropriate EmailStatus and SendLater flags or rely on QBO settings.

Idempotency: store quickbooks_last_invoice_id and a billing_period_key per invoice to avoid duplicates when retrying API calls.
​

Renewal workflow

Timing and reminders:

Recommended triggers:

90 days before term_end_date – internal alert + draft renewal proposal.

60 days – send first outbound renewal communication (email/SMS with link).

30 days – final reminder with clear call to action.

AI-drafted renewal offers (using Claude):

Inputs: customer usage (how many visits completed vs planned), upsell options, upcoming price adjustments, historical issues.

Content pattern:

Subject: “Your [Service] Maintenance Plan Renewal”

Body includes:

Summary of past year’s service (“Completed 2 tune-ups, responded to 1 emergency call”).

Value bullet points (energy savings, fewer breakdowns, pest-free, etc.).

Renewal terms (new term dates, visit count, price).

Explicit note for price increase with justification (labor/material costs, inflation).

Store generated text in a RenewalCommunication entity so staff can edit.

Price increases at renewal:

ContractRenewal.price_change_percent holds the adjustment.

When renewal accepted:

Update ServiceContract.pricing_summary and relevant ContractLineItem.unit_price fields.

Optionally keep price history in metadata or a separate PriceHistory object.

When a contract expires without renewal:

On transition to expired:

Cancel remaining planned occurrences and related unscheduled work orders.

Decide whether to keep completed work orders billable at non-contract rates.

If there are scheduled jobs after term_end_date, either:

Auto-cancel (with customer notification), or

Convert into one-off jobs not linked to a contract (and bill at standard pricing).

Reporting

Owner-level dashboards should include:

Active contracts by type

Group ServiceContract where status=active by contract_type and count.

Show total expected_annual_revenue and expected_mrr per type.

MRR (Monthly Recurring Revenue)

Derived from active contracts:

flat_monthly: sum monthly price.

prepaid_annual: annual price / 12.

hybrid: base monthly fee + average add-ons (optional).

Present as a time series and as a current month snapshot, similar to “membership revenue” reporting in service platforms.

Contracts expiring in next 90 days

Query contracts where term_end_date between today and today+90 and status in (active, renewal_pending).

Count by month bucket and type.

Visit completion rate per contract

For each contract:

planned_visits = count(ContractOccurrence where status in planned/scheduled/completed/skipped/canceled within term).

completed_visits = count where status=completed.

completion_rate = completed / planned.

Highlight contracts below threshold (e.g., <80%).

Contracts overdue for a visit

For each occurrence with status in (planned, scheduled) and scheduled_date < today – grace_days, mark as overdue.

Roll up counts per contract and flag those with any overdue occurrences.

AI assistance opportunities

Places Claude can add real value:

Drafting contract proposals

From a basic configuration template (service type, frequency, pricing, inclusions/exclusions), generate customer-facing proposal text for email, PDF, or e-sign.

Contract health monitoring

Daily job analyzes ContractOccurrence vs term timeline to flag:

Contracts behind schedule on visits.

High number of skipped visits.

Upsell and upgrade suggestions

Using service history (emergency calls, extra work, high spend customers), identify candidates for higher tiers (e.g., more frequent visits, extended warranties).

Suggest campaigns or individualized offers.

Pricing assistance

Given region, historical job duration, materials cost, and competitor benchmarks (if you feed them in), propose target pricing and contract structure.

Renewal messaging

Auto-generate 30/60/90-day reminders and varied scripts (email, SMS, call script) tailored to customer history and personality tags.

Natural language interface

Owner can ask: “Which pest control contracts are behind on visits this month?” and AI translates to queries over your JSON data.

Edge cases

You should handle several non-standard scenarios at the data and rules level.

Partial year contracts (start mid-year)

Term_start_date is whenever the customer signs; generate occurrences from that date.

For seasonal services (lawn, pool), your occurrence generator should be season-aware (e.g., only generate visits during April–October).

Billing: you can pro-rate flat_monthly or create a shorter initial_term_months.

Contracts including emergency calls

Model emergency entitlements on the contract:

included_emergency_visits_per_term, emergency_visit_discount_percent.

When a job is marked emergency, apply contract rules to invoice line pricing.

Multiple locations for same customer

Either:

One ServiceContract with multiple ContractLineItems, each with location_id_override, or

Separate contracts per location, linked by a customer_group_id.

Reporting should aggregate by customer as well as by location.

Contracts inherited when customer changes ownership

Add fields: property_id, current_owner_customer_id, previous_owner_customer_id.

Ownership change flow:

New owner is created as a Customer.

ServiceContract.customer_id updated to new owner, previous_owner_customer_id populated.

Optionally trigger a renegotiation or renewal flow; you may want to keep pricing but reset payment_method_token.

Comparison to existing platforms

These platforms can guide feature expectations and highlight gaps for very small businesses.

Platform	How they handle agreements	Strengths	Gaps for very small businesses
ServiceTitan	Membership/maintenance agreements with recurring service events that auto-generate jobs, tied to billing rules and follow-ups.
Deep integration of agreements, scheduling, and billing; strong reporting on profitability and renewals.
Heavy, complex, and expensive; more than a 1–5 tech shop usually needs.
Jobber	Recurring jobs and subscription-like billing; fixed or variable recurring payments and flexible scheduling.
​	Simple recurring job setup; good for standard home services; easy automated invoicing.
Less explicit “contract” object; maintenance plans are jobs + billing patterns, which can make renewals and contract analytics less structured.
Housecall Pro	Similar concept with recurring service plans and membership programs (jobs, discounts, auto-billing).	Easy UX for owner-operators; good mobile apps and automated reminders.	Limited deeper contract lifecycle tracking (price history, complex multi-location contracts) out of the box.
QuickBooks Online alone	Recurring transactions (invoices) configured in the UI, not via API.
Great for pure billing automation.	No concept of visits, maintenance occurrences, or contract health; you must build scheduling and contract logic externally.
Your architecture—contracts as JSON in Drive/SharePoint with explicit occurrences and renewals, plus QuickBooks used only for accounting—lets you keep the business logic and AI workflows in markdown/Claude while still mirroring the proven patterns from tools like ServiceTitan and Jobber.