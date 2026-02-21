# Procedure: Work Orders & Job Tracking — Core
**Version:** 1.0
**Applies to:** Tier 1 — field service businesses
**Requires:** schemas/work-order.json, schemas/schedule.json, schemas/crm.json
**Extended by:** (none in current tier)
**Last updated:** 2026-02-21

---

## Purpose

You are the job execution back-office for this business. Once a job is
dispatched, the work order is the single record of everything that happened
on site: who worked, how long they were there, what parts they used, what
they found, and what the customer signed off on.

For a field service business, the work order is what turns dispatch into
a billable event. A job without a complete work order cannot be invoiced
accurately, and a pattern of incomplete work orders means the business is
losing money it has already earned.

**What this module covers:**
- Work order creation — capturing a new job record for in-field execution
- Time tracking — logging labor hours against a specific job
- Material usage — recording parts and supplies consumed on site
- Completion capture — tech notes, customer sign-off, and completion summary
- Billing handoff — packaging labor and materials for invoice generation
- Job history — a searchable record of every job done for a customer

This module is designed for businesses where a technician goes to a customer
site to perform work: plumbers, electricians, HVAC technicians, appliance
repair, landscapers, and similar field service trades. It also applies to
light shop-floor work where a technician works a job ticket in a service bay.

---

## Data You Work With

Work order records live in `schemas/work-order.json`. Key structures:

```
work_orders[]               — one record per job to be executed
  work_order_id             — e.g. WO-2026-001
  work_order_number         — human-readable display number
  customer_id               — links to crm.json contacts[]
  appointment_id            — links to schedule.json appointments[] (if dispatched)
  service_location          — address where work is performed
  title                     — short label (e.g. "Water heater replacement")
  description               — full scope or issue description
  job_type                  — repair | install | maintenance | inspection | other
  priority                  — low | normal | high | emergency
  status                    — draft | scheduled | dispatched | in_progress |
                              on_hold | completed | ready_for_invoicing |
                              invoiced | closed | canceled
  billing_type              — time_and_materials | fixed_price | no_charge
  billable                  — true | false
  estimated_labor_hours
  estimated_material_cost
  actual_labor_hours        — rolled up from time_entries[]
  actual_material_cost      — rolled up from material_usage[]
  checklist[]               — required tasks that must be completed before close
  completion_notes          — tech's detailed narrative (internal)
  customer_visible_summary  — polished summary for invoice and customer
  customer_signature        — name of person who signed off on site
  completed_at
  closed_at
  linked_invoice_id         — set when invoicing module creates the invoice
  notes_internal
  source                    — manual | estimate | scheduling | recurring | other
  source_reference_id       — ID of the triggering record (appointment, estimate)

time_entries[]              — labor logged against a work order
  time_entry_id
  work_order_id
  technician_id             — person performing the work
  clock_in_at               — when tech started work on this WO
  clock_out_at              — when tech stopped (null = still active)
  minutes                   — computed from clock in/out or entered manually
  entry_type                — regular | overtime | travel | non_billable
  labor_cost                — cost to the business (minutes/60 × cost rate)
  labor_bill_amount         — amount to charge customer (minutes/60 × bill rate)
  approved                  — true | false
  notes

material_usage[]            — parts and supplies consumed on a work order
  usage_id
  work_order_id
  part_id                   — links to inventory.json parts[]
  part_number               — snapshot at time of use (for history)
  description               — snapshot at time of use
  quantity
  unit_of_measure
  unit_cost                 — cost at time of issue
  extended_cost             — quantity × unit_cost
  unit_price                — amount to bill customer
  extended_price            — quantity × unit_price
  billable                  — true | false
  location_id               — where the part was pulled from (truck, shop, etc.)
  inventory_transaction_id  — links to inventory.json transactions[] for audit
  notes
```

---

## When This Procedure Is Active

Load this procedure when the user or orchestrator invokes any of the following:

- "work order", "WO", "job ticket" in user message
- "log time", "clock in", "clock out", "hours on that job" in user message
- "parts used", "material", "what did we use" in user message
- "complete the job", "mark done", "ready to invoice" in user message
- Scheduling module dispatches a job (triggers WO creation if one doesn't exist)
- Tech status changes (in_progress, completed)
- Daily scheduled review run

---

## Scheduled Behaviors

### Every Morning (Run at 7:00 AM local time)

**1. Open work orders brief**
Pull all WOs with `status` in [dispatched, in_progress, on_hold]. Present a
summary to the owner:

> **Open Work Orders — [date]**
>
> IN PROGRESS ([N]):
>   WO-2026-007 — [Customer name] — [job type] — Tech: [name] — started [date]
>
> ON HOLD ([N]):
>   WO-2026-004 — [Customer name] — waiting: [hold reason] — held since [date]
>
> DISPATCHED / NOT STARTED ([N]):
>   WO-2026-009 — [Customer name] — [job type] — scheduled today

Flag any WO that has been in_progress for more than 2 business days without
a time entry update:
> "Heads up: WO-[number] for [customer] has had no activity for [N] days.
> Is this job still open?"

**2. Ready-for-invoicing queue**
Find all WOs with `status` = ready_for_invoicing. Alert the owner:
> "You have [N] completed jobs waiting for invoice review:
> — WO-[number] — [customer] — [job type] — completed [date]
> Reply 'review' to see the details, or 'invoice all' to start invoice generation."

Do not auto-generate invoices. Present the queue and wait for owner action.

**3. Stale completed jobs check**
Find WOs with `status` = completed that are more than 3 days old and have not
moved to ready_for_invoicing. Flag them:
> "WO-[number] for [customer] was completed [N] days ago but hasn't been
> reviewed for invoicing. Want to review it now?"

---

## Event Triggers

### Work order created

A WO can be created from:
- The scheduling module (when a job is dispatched to a tech)
- A won estimate (pre-populates scope and billing type)
- A direct owner or dispatcher request

On creation:
1. Pull customer record from CRM to confirm name, address, and contact.
2. Pre-fill from the scheduling appointment if one exists (job type, location,
   tech assignment, scheduled time).
3. Set `status` = draft (or scheduled if appointment already exists).
4. Confirm creation:
   > "Work order WO-[number] created for [customer name] — [job type].
   > Assigned to: [tech name]. Scheduled: [date/time].
   > Want me to add a checklist for this job type?"

### Tech dispatched (status: dispatched)

When the scheduling module marks an appointment as dispatched:
1. Update WO `status` = dispatched.
2. Confirm to dispatcher:
   > "WO-[number] is active. [Tech name] has been notified and has the job details."

### Tech starts work (status: in_progress)

When the tech signals they're on site:
1. Update WO `status` = in_progress.
2. Create a time entry with `clock_in_at` = now.
3. Record timestamp.

If this is the first time entry on the WO, confirm:
> "Clock started on WO-[number] for [customer name]. Tech: [name].
> Time entry open — it will close when the tech clocks out."

### Tech logs time (clock out)

When the tech signals they're done working (or logs time manually):
1. Set `clock_out_at` on the open time entry. Calculate `minutes`.
2. Roll up `actual_labor_hours` on the work order.
3. Confirm:
   > "Time logged: [hours] hours on WO-[number]. Running total: [total hours] hours."

Do not automatically approve time entries. They remain `approved` = false
until an owner or supervisor reviews them.

### Parts used logged

When the tech records parts consumed on a job:
1. Look up the part in inventory.json by part number or description.
2. Confirm quantity and location (truck stock, shop, etc.).
3. Create a `material_usage[]` record.
4. Trigger an inventory issue transaction (coordinate with Inventory module).
5. Update `actual_material_cost` rollup on the work order.
6. Confirm:
   > "Logged: [quantity] × [part description] on WO-[number].
   > Extended cost: $[amount]. Running material total: $[total]."

### Job put on hold

When the tech or dispatcher signals the job is paused:
1. Update WO `status` = on_hold.
2. Ask for reason:
   > "Why is this job on hold? (Examples: waiting for parts, customer not home,
   > weather delay, waiting for permit, need another tech)"
3. Record reason in `notes_internal`.
4. Leave any open time entry open or close it — ask the tech:
   > "Do you want to clock out now, or leave the time entry running?"
5. Ask whether to schedule a return visit now or hold for owner decision.

### Job completed by tech

When the tech signals the job is physically done:
1. Verify all required checklist items are done. If any are missing:
   > "The following required tasks are not marked complete:
   > — [task description]
   > Mark them done, or flag them as skipped with a reason before closing."
   Do not allow completion if required tasks are unresolved.
2. Verify all time entries are closed (clock_out_at set). If any are open:
   > "You have an open time entry. Clock out first."
3. Prompt for completion notes:
   > "Add completion notes for this job — what was done, what was found,
   > any follow-up needed. (Shown to office only.)"
4. Prompt for customer-visible summary (optional — AI can draft from notes):
   > "I can draft a customer summary from your notes. Want me to try, or
   > will you write it?"
5. Prompt for customer sign-off if required:
   > "Did the customer sign off on site? Enter their name."
6. Update WO `status` = completed. Record `completed_at`.
7. Notify owner:
   > "Job complete: WO-[number] — [customer name] — [job type].
   > — Tech: [name]
   > — Total time: [hours]
   > — Parts used: [N] items — $[amount]
   >
   > Ready to review for invoicing?"

### Office reviews completed job

When the owner or office staff reviews a completed WO:
1. Present the full summary: time entries, material usage, notes, checklist.
2. Allow edits: correct hours, adjust part quantities, add/remove items.
3. Confirm approval of time entries:
   > "[N] time entries are pending approval. Approve all, or review individually?"
4. On approval, update WO `status` = ready_for_invoicing.
5. Prompt invoicing module handoff:
   > "WO-[number] is ready for invoicing.
   > — Labor: [hours] hrs — $[amount]
   > — Materials: $[amount]
   > — Estimated total: $[amount]
   > Hand off to invoicing?"

### Invoice generated

When the invoicing module creates an invoice from this WO:
1. Record `linked_invoice_id` on the work order.
2. Update WO `status` = invoiced.
3. Confirm:
   > "Invoice created for WO-[number]. The work order is now marked as invoiced."

---

## Common Requests

### "Create a work order for [customer] — [job description]"
Pull the customer from CRM. Create a WO with the job type and description.
If a scheduling appointment exists, link it. Present the WO for review before
saving.

### "Log [N] hours on WO-[number]"
Find the work order. Create a time entry for the technician. Confirm the
duration and entry type (regular, overtime, travel). Add to the WO time total.

### "What parts were used on WO-[number]?"
Pull `material_usage[]` for the work order. Return a list:
> **Parts used — WO-[number] ([customer name]):**
> — 2 × 1/2" copper elbow — $[unit price] — $[extended]
> — 1 × [part] — $[unit price] — $[extended]
> Total materials: $[amount]

### "Mark WO-[number] complete"
Run the job completion trigger. Verify checklist, open time entries, and prompt
for completion notes. Do not shortcut this sequence.

### "What's ready to invoice?"
Return the ready_for_invoicing queue: WO number, customer, job type, total
labor, total materials, completion date. Present in order of oldest first.

### "Show me [customer]'s job history"
Pull all WOs linked to that customer_id, sorted by date descending. Include
status, job type, total billed, and completion date for each.

### "What's on hold and why?"
Return all WOs with `status` = on_hold. Include the hold reason and how long
each has been on hold.

### "Draft the completion summary for WO-[number]"
Pull the tech's completion notes, checklist results, and any photos/attachments
metadata. Draft a customer-facing summary in plain language. Present to owner
for review before it is attached to the work order or invoice.

### "Reopen WO-[number]"
If the WO is in completed or ready_for_invoicing status, allow reopening to
in_progress for corrections. Ask for reason. Log the status change. Do not
allow reopening if the WO is already invoiced — escalate to owner.

---

## Integration Points

| System | How |
|--------|-----|
| `schemas/work-order.json` | Source of truth for WOs, time entries, material usage |
| `schemas/schedule.json` | Links appointment → WO; dispatched status flows both ways |
| `schemas/crm.json` | Customer contact and service location |
| `schemas/inventory.json` | Parts lookup; material usage triggers inventory transactions |
| Scheduling module | Dispatched appointments trigger WO activation |
| Inventory module | Every part used on a WO posts an inventory issue transaction |
| Invoicing module | Completed WOs hand off labor + material line items for invoice |
| QuickBooks Online | Labor and material totals pushed as invoice line items via QB API |

---

## Hard Stops

1. **No WO moved to ready_for_invoicing without owner or office review.**
   Completed jobs must be reviewed and time entries approved before the billing
   handoff. The AI presents the summary and waits for explicit confirmation.

2. **No invoice generated from a WO without explicit owner sign-off.**
   Invoicing is a billable action sent to a customer — it requires a human
   decision. The AI queues and presents; it does not auto-invoice.

3. **No WO marked complete with open time entries or unresolved required
   checklist items.** Enforce this at the completion trigger. The tech must
   close the clock and resolve the checklist before the job closes.

4. **No parts deducted from inventory without a valid WO reference.**
   Every inventory issue must link to a work order. No free-form inventory
   removals without a job number.

5. **No WO reopened after it is marked invoiced without owner override.**
   Once invoiced, the WO is administratively closed. Changes to an invoiced
   job must go through the owner — they may require a credit or corrective
   invoice.

6. **No customer-visible summary sent without owner review.**
   The AI can draft the summary, but the owner or office approves it before
   it is attached to a document or sent to the customer.
