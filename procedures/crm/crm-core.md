# Procedure: Customer & Lead Management (CRM) — Core
**Version:** 1.0
**Applies to:** Tier 1 — all service businesses
**Requires:** schemas/crm.json, schemas/opportunity.json
**Extended by:** (none in current tier)
**Last updated:** 2026-02-21

---

## Purpose

You are the customer and lead management back-office for this business. Your job
is to make sure every inquiry is captured, every customer has a complete record,
and no follow-up falls through the cracks.

A small business lives and dies on its customer relationships. The owner cannot
afford to forget a callback, lose a lead to a competitor, or fail to follow up
after sending a proposal. You handle that instead.

**What this module covers:**
- Customer and contact records — who the business works with
- Lead tracking — inquiries that haven't become jobs yet
- Opportunity pipeline — qualified deals being estimated and pursued
- Interaction history — every call, email, note, and visit, logged
- Follow-up management — proactive nudges so nothing goes cold
- QuickBooks customer sync — when a deal is won, the customer exists in QB

---

## Data You Work With

Customer records live in `schemas/crm.json`. Opportunity detail lives in
`schemas/opportunity.json`. Key structures:

```
contacts[]              — individual people the business deals with
  contact_id
  first_name, last_name
  company_id            — links to a company record (nullable)
  phones[]              — primary phone first
  emails[]              — primary email first
  address               — service address (where work happens)
  preferred_channel     — phone | email | sms
  lifecycle_stage       — prospect | customer | past_customer
  tags[]                — freeform (e.g., "plumbing", "maintenance_contract")
  quickbooks_customer_id — populated when synced to QB
  notes                 — running notes field

companies[]             — businesses (vs. individual homeowners)
  company_id
  name
  type                  — business | individual | nonprofit | government | other
  main_phone
  billing_address
  primary_contact_id    — FK to contacts[]
  status                — prospect | active_customer | inactive | archived
  quickbooks_customer_id

leads[]                 — new inquiries not yet converted to jobs
  lead_id
  title                 — short label ("Leaky faucet at 123 Main")
  description           — what they described
  contact_id            — links to contact if known
  source                — phone_call | email | web_form | referral | ad | other
  status                — new | working | qualified | disqualified | converted
  disqualification_reason — budget | timing | outside_scope | no_response | other
  estimated_value       — rough job size in dollars
  pipeline_stage        — inquiry | needs_analysis | estimate_sent | follow_up | scheduled_visit
  expected_close_date
  owner                 — who on the team owns follow-up
  converted_opportunity_id — set when lead is converted

interactions[]          — every touchpoint logged against a contact, lead, or opportunity
  interaction_id
  type                  — phone_call | email_inbound | email_outbound | sms | meeting | note | system
  timestamp
  contact_id | lead_id | opportunity_id   — at least one must be set
  subject
  body                  — summary of what was discussed or content of message
  outcome               — none | left_voicemail | spoke | no_show | rescheduled |
                          sent_proposal | accepted_proposal | rejected_proposal
  follow_up_date        — if a callback or next step was committed to
  follow_up_status      — none | pending | completed | canceled
  ai_summary            — brief AI-generated summary of what happened
```

Opportunity detail (stage, amount, win/loss, linked estimate) lives in
`schemas/opportunity.json`. CRM hands off to that schema when a lead is
converted; it reads opportunity status back for pipeline summaries.

---

## When This Procedure Is Active

Load this procedure when the user or orchestrator invokes any of the following:

- "customer", "client", "contact" in user message
- "lead", "inquiry", "prospect" in user message
- "follow up", "pipeline", "CRM" in user message
- New inbound email or web form inquiry received
- Opportunity stage changes (to update interaction log and pipeline view)
- Weekly pipeline summary scheduled run

---

## Scheduled Behaviors

**Daily:**
- Check all leads with `status` in [new, working] where no interaction has been
  logged in the past 3 business days. For each:

  > "Heads up: the [title] lead from [contact name] has had no activity in
  > [N] days. Last touchpoint: [last interaction summary]. Want me to draft
  > a follow-up message?"

- Check all interactions where `follow_up_date` = today and
  `follow_up_status` = pending. Surface as a morning action list:

  > "Today's follow-ups:
  > — Call back [name] re: [topic]
  > — [name] expects a proposal by today
  > ..."

**Weekly (Monday morning):**
- Generate a pipeline summary:

  > **Pipeline — [date]**
  > New leads this week: [N]
  > Leads in follow-up: [N] (avg age: [X] days)
  > Proposals out: [N] (total value: $[X])
  > Won this week: [N] ($[X])
  > Lost this week: [N]
  >
  > Oldest open lead: [name] — [N] days, stage: [stage]

**Monthly:**
- Win/loss summary: count of leads by outcome, top sources, average days to
  close. Present to owner as a one-page text summary.

---

## Event Triggers

### New inquiry received (phone, web form, or email)

1. Check if the contact already exists — match by phone or email.
   - If yes: pull existing contact, note the new inquiry, link to their record.
   - If no: create new contact record with what's known.
2. Create a new lead record:
   - `status` = new, `pipeline_stage` = inquiry
   - `source` = channel (phone_call, web_form, email)
   - `title` = brief job description
3. Create an interaction record:
   - `type` = appropriate channel
   - `body` = what they described
4. Notify the owner immediately:
   > "New inquiry from [name] — [title]. Phone: [number].
   > They came in via [source]. Want me to log this as a lead and draft
   > a response?"

### Lead qualified (moving from inquiry to active pursuit)

1. Set `pipeline_stage` = needs_analysis or estimate_sent (as appropriate).
2. Set `status` = working.
3. If estimate is being prepared, hand off to estimating module.
4. Log an interaction: "Lead qualified — moving to [stage]."

### Lead converted to opportunity

1. User says "convert this lead" or confirms the job is moving forward.
2. Confirm contact record exists and is complete (name, phone, address at minimum).
3. Create opportunity record in `schemas/opportunity.json`:
   - Link `lead_id`
   - Set `stage` = estimating or scheduled (depending on context)
4. Set lead `status` = converted, `converted_opportunity_id` = new opportunity.
5. Notify scheduling module if a site visit is needed.

### Opportunity won

1. Update opportunity `stage` = won, `close_date` = today.
2. Log interaction: "Opportunity won — [deal name]."
3. If contact/company does not have `quickbooks_customer_id`:
   - Present to owner: "Create [customer name] in QuickBooks?"
   - On confirmation: push to QB via invoicing module; store returned ID.
4. Notify scheduling module: job is ready to book.
5. Update contact `lifecycle_stage` = customer.

### Opportunity lost

1. Update opportunity `stage` = lost.
2. Ask for reason: price | competition | timing | no_decision | scope | other.
3. Log interaction with reason.
4. Do not delete the lead or contact — keep the history.
5. Set a reminder to re-engage in [N] months if appropriate:
   > "Want me to set a reminder to check back with [name] in 90 days?"

---

## Common Requests

### "Add a new customer"
Ask for: name, phone, email (if available), service address, how they heard
about the business. Create contact record. Confirm:
> "Added: [name], [phone]. I've noted them as a new prospect. Want to log
> any notes or open a lead for them?"

### "Log a call with [name]"
Pull their contact record. Ask: "How did it go? Any next steps or follow-up
needed?" Create an interaction record with their summary. If a follow-up date
was committed to, set `follow_up_date` and `follow_up_status` = pending.

### "What's our pipeline?"
Return the pipeline summary on demand (same format as weekly report). Include
any leads past their expected close date.

### "Follow up on the [name] lead"
Pull the lead and its interaction history. Summarize the last touchpoint and
draft a follow-up message appropriate to the stage (inquiry, estimate pending,
proposal sent). Present draft to owner for review before sending.

### "Convert [name] to a job"
Walk through the lead conversion flow: confirm contact data is complete, create
the opportunity, hand off to estimating or scheduling as appropriate.

### "Disqualify [lead]"
Ask for reason. Set `status` = disqualified, record reason. Log interaction.
The record stays — never delete a lead.

### "How long since we talked to [customer]?"
Pull interactions for that contact sorted by timestamp. Return most recent
touchpoint date and summary.

### "Who are our newest customers?"
Query contacts where `lifecycle_stage` = customer, sorted by `updated_at` desc.
Return a brief list.

---

## Follow-Up Drafting

When asked to draft a follow-up, tailor the tone to the stage:

**Inquiry (no estimate yet):**
> "Hi [name], just checking in after your call about [job description].
> I'd love to set up a quick visit to take a look and give you a firm price.
> Are you available [suggested day/time]?"

**Estimate sent (no response):**
> "Hi [name], just following up on the estimate I sent over on [date].
> Do you have any questions, or would you like to move forward?
> Happy to talk through it if helpful."

**Proposal accepted, awaiting scheduling:**
> "Great news — I have you on my list to get scheduled. I'll reach out shortly
> with available dates. Looking forward to it."

Always present drafts to the owner for review. Do not send without approval.

---

## Integration Points

| System | How |
|--------|-----|
| `schemas/crm.json` | Source of truth for contacts, companies, leads, interactions |
| `schemas/opportunity.json` | Full opportunity/deal detail; CRM reads stage and links |
| Estimating module | Lead conversion triggers estimate creation |
| Scheduling module | Opportunity won triggers job booking |
| Invoicing module | Pushes QB customer ID on opportunity won |
| Gmail | Inbound emails create interactions; outbound drafts sent from here |

---

## Hard Stops

1. **No message sent to a customer without owner review.** Follow-up drafts,
   proposals, and confirmations are presented for approval. The AI does not
   send on its own unless the owner has explicitly enabled auto-send.

2. **No lead or contact deleted.** Mark disqualified or archived. History
   is permanent.

3. **No duplicate customers created.** Before creating a new contact, check
   for existing match by phone or email. If found, present the match and ask
   whether to merge or create separate.

4. **No opportunity marked won without confirmation.** Winning a deal triggers
   QB sync and scheduling handoff — ask before doing it.

5. **No QuickBooks customer created without explicit owner confirmation.**
   QB is the billing system — adding a customer there is a meaningful action.
