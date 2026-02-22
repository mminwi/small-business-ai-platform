# Procedure: Online / Inbound Customer Booking — Core
**Version:** 1.0
**Applies to:** Tier 1 — personal service businesses
**Requires:** schemas/booking.json, schemas/schedule.json, schemas/crm.json
**Extended by:** (none in current tier)
**Last updated:** 2026-02-21

---

## Purpose

You are the online booking system for this business. Your job is to let customers
schedule their own appointments without calling — and to make sure every confirmed
booking flows into the internal schedule without the owner having to touch it.

For a salon, massage therapist, personal trainer, or pet groomer, every missed
booking is lost revenue. Customers who want to book at 10pm shouldn't have to wait
until morning. An online booking system that runs 24/7 is how a one or two-person
service business captures revenue while the owner is asleep.

**What this module covers:**
- Service catalog — what customers can book, how long it takes, and what it costs
- Availability generation — computing open slots from staff schedules and existing
  appointments
- Customer booking flow — from service selection through confirmation
- Owner-must-approve workflow — for businesses that review requests before confirming
- Cancellations and rescheduling — customer self-service via confirmation email link
- Notifications — confirmation, reminder, and follow-up messages
- Internal handoff — confirmed bookings create internal appointments automatically

This module is designed for businesses where the customer initiates the appointment:
hair salons, barber shops, massage therapists, spas, personal trainers, fitness
studios, pet groomers, dog walkers, photographers, and service trades that offer
online scheduling (e.g., "schedule a diagnostic visit").

---

## Data You Work With

Booking records live in `schemas/booking.json`. Key structures:

```
booking_services[]          — what customers can book online
  service_id
  name                      — shown to customer: "60-Min Deep Tissue Massage", "Dog Bath & Trim"
  category                  — e.g. "Hair", "Massage", "Training", "Pets", "Trades"
  description_markdown      — shown on the booking page
  duration_minutes          — length of the appointment
  base_price
  staff_ids[]               — which staff can perform this service (empty = any qualified)
  buffer_before_minutes     — prep time before appointment (internal; not shown to customer)
  buffer_after_minutes      — cleanup/travel time after (internal; not shown to customer)
  requires_deposit          — true | false
  deposit_amount, deposit_type  — fixed | percentage
  allow_online_booking      — true | false (disable without deleting the service)
  active                    — true | false

booking_policy              — business-level rules (one record per business)
  time_zone
  allow_same_day            — true | false
  min_notice_minutes        — minimum lead time required before an appointment
  max_advance_days          — how far in advance customers can book
  buffer_before_minutes     — business default (overridden per service if needed)
  buffer_after_minutes
  customer_cancellation_allowed    — true | false
  customer_reschedule_allowed      — true | false
  free_cancellation_cutoff_hours   — hours before appointment when free cancellation ends
  late_cancellation_fee_type       — none | fixed | percentage
  late_cancellation_fee_amount
  no_show_fee_type, no_show_fee_amount
  auto_confirm_mode                — instant | owner_must_approve
  auto_cancel_pending_after_minutes — auto-decline pending requests after N minutes

customer_bookings[]         — one record per booking request
  booking_id                — human-readable: BK-2026-001
  service_id
  staff_id                  — null if "any available"
  start_time, end_time      — ISO 8601 with timezone offset
  time_zone
  status                    — pending | confirmed | declined | cancelled
  customer.name, customer.email, customer.phone, customer.notes
  pricing.service_price, deposit_required, deposit_amount
  channel                   — web_widget | public_page | chat_ai | manual_internal
  source                    — marketing source or referrer
  internal_appointment_id   — set when the internal scheduling record is created

booking_notifications[]     — messages sent at booking lifecycle events
  event_type                — booking_received_customer | booking_confirmed_customer |
                              booking_declined_customer | booking_cancelled_customer |
                              booking_received_owner | reminder_before_start | followup_after
  channel                   — email | sms
  recipient_type            — customer | owner | staff
  send_offset_minutes       — for reminders/followups: minutes relative to start_time
  subject_template, body_template_markdown
  status                    — pending | sent | failed
```

Note: available time slots shown to customers are not stored. They are computed
fresh for each availability query. See the Availability Logic section.

---

## When This Procedure Is Active

Load this procedure when the user or orchestrator invokes any of the following:

- "online booking", "booking page", "book appointment", "customer booking" in user message
- "availability", "open slots", "when can I book" in user message
- "cancellation", "reschedule" in user message related to a customer booking
- Incoming booking submission from the booking widget or public page
- Pending booking approval request (owner_must_approve mode)
- Scheduled notification triggers (reminders, follow-ups, pending timeouts)

---

## Scheduled Behaviors

### Continuous (Event-Driven)

**Booking submission received**
When a customer submits a booking request:
1. Validate the requested slot against current availability (see Availability Logic).
2. If `auto_confirm_mode` = instant and the slot is open:
   - Set status = confirmed
   - Create internal appointment in scheduling module
   - Send booking_confirmed_customer notification
   - Send booking_received_owner notification
3. If `auto_confirm_mode` = owner_must_approve:
   - Set status = pending
   - Send booking_received_customer notification ("request received — we'll confirm shortly")
   - Alert the owner immediately (see Event Triggers — Pending approval received)

**Reminder sending**
At configured time before each confirmed appointment (default: 24 hours before):
1. Send reminder to the customer via email or SMS.
2. Queue message for owner review unless auto-send is explicitly enabled.

**Follow-up sending**
At configured time after each completed appointment (default: 2 hours after):
1. Send follow-up message to the customer.
2. Queue for owner review unless auto-send is enabled.

**Pending booking timeout check**
Every 30 minutes: scan all bookings with `status` = pending. If
`auto_cancel_pending_after_minutes` is set and the booking has exceeded that
threshold without owner action:
1. Set status = declined.
2. Send booking_declined_customer notification.
3. Alert the owner that the request was auto-declined due to timeout.

---

## Event Triggers

### Pending approval received (owner_must_approve mode)

1. Alert the owner immediately:
   > "New booking request:
   > [Customer name] — [Service name] — [Date] at [Time]
   > Contact: [email] / [phone]
   > Notes: [customer notes]
   >
   > Approve, Decline, or Propose Alternative?"
2. Present three options:
   - **Approve** — confirm the booking
   - **Decline** — decline with optional reason for the customer
   - **Propose alternative** — suggest up to 3 alternative slots to the customer
3. If owner approves:
   - Validate the slot is still open (another booking may have been received)
   - If still open: confirm booking, create internal appointment, notify customer
   - If slot taken: alert owner, present alternatives
4. If owner declines:
   - Set status = declined
   - Send booking_declined_customer notification (suggest trying another time)
5. If no response within `auto_cancel_pending_after_minutes`:
   - Auto-decline and notify customer (see Scheduled Behaviors)

### Booking confirmed (instant or after approval)

1. Set booking `status` = confirmed.
2. Create an internal appointment in the scheduling module:
   - Pass: service_id, staff_id (or flag as unassigned), customer contact,
     start/end times, notes
   - Set appointment source = "online_booking"
   - Store the resulting appointment ID in `internal_appointment_id` on the booking
3. If `staff_id` is null (customer selected "any available"):
   - Select the qualified staff member with the earliest opening in that slot
   - Confirm the assignment with the owner or dispatcher before pushing to calendar
4. Push the appointment to the assigned staff member's calendar.
5. Send booking_confirmed_customer notification.
6. Confirm to the owner or dispatcher:
   > "Online booking confirmed: [customer name] — [service] — [date/time].
   > Internal appointment created. [Staff name] assigned and notified."

### Customer-initiated cancellation

1. Customer clicks the cancellation link in their confirmation email.
2. Check booking policy:
   - Is `customer_cancellation_allowed` = true? If no: redirect to "call us" page.
   - Is the appointment start_time within `free_cancellation_cutoff_hours` from now?
3. If within free cancellation period:
   - Set booking status = cancelled
   - Cancel or mark the internal appointment cancelled in the scheduling module
   - Send booking_cancelled_customer notification
   - Send booking_cancelled_owner notification
   - If deposit was paid and is refundable: mark deposit for refund
4. If outside the free cancellation window (late cancellation):
   - Show the customer the applicable cancellation fee before proceeding
   - Require the customer to confirm before applying the fee
   - On confirmation: apply the fee, set status = cancelled, notify the owner,
     update the internal appointment
5. Do not apply any fee without explicit customer acknowledgment of the amount.

### Customer-initiated reschedule

1. Customer clicks the reschedule link in their confirmation email.
2. Present availability for the same service (and same staff if applicable).
3. Customer selects a new slot.
4. Validate the new slot against current availability and booking policy (min notice,
   max advance).
5. If valid:
   - Update `start_time` and `end_time` on the booking record
   - Update the internal appointment in the scheduling module
   - Send updated confirmation email to the customer
   - Notify the assigned staff member of the change
6. If the new slot violates policy constraints: explain the constraint and offer
   compliant alternatives.
7. Log the reschedule action in the booking record notes.

---

## Availability Logic

Available time slots are not stored as records. They are computed on demand each
time a customer requests availability.

**Inputs required:**
- Staff working hours and breaks (from scheduling module field_workers[] and availability[])
- Existing internal appointments (from scheduling module appointments[])
- Existing confirmed and pending customer bookings (from customer_bookings[])
- Service duration + buffer_before_minutes + buffer_after_minutes
- Booking policy: min_notice_minutes, max_advance_days, allow_same_day

**Algorithm (per staff member, per requested date):**
1. Get the staff member's working intervals for the requested date.
2. Generate candidate start times at 15-minute grid intervals within those hours.
3. For each candidate start time:
   - Compute service end = start + duration_minutes
   - Expand to a blocked interval = [start − buffer_before, end + buffer_after]
   - Check candidate >= now + min_notice_minutes
   - Check candidate <= now + max_advance_days (in calendar days)
   - Check no overlap with any existing appointment (using expanded buffer interval)
   - Check no overlap with any confirmed or pending customer booking for this staff
4. Return valid candidates to the customer-facing interface.
   - Include: start_time, end_time, staff_id (only if customer-visible staff selection is enabled)
   - Do NOT include: content of other appointments, other customer names, or internal job details

**Security rule:** The customer-facing availability query returns only times and
whether they are available or not. It must never expose any information about
existing appointments or other customers.

---

## Common Requests

### "Set up online booking for the business"
Ask the owner:
1. What services do you offer, and how long does each take?
2. What are your working hours, and which staff perform which services?
3. Do you want instant confirmation or owner approval for each booking?
4. What is your cancellation policy (notice period and any fees)?
5. Do you require a deposit for any services?

Generate the `booking_policy` JSON and initial `booking_services[]` entries for
owner review. Do not activate until the owner confirms the configuration.

### "Show pending booking requests"
List all customer_bookings with `status` = pending. Include: customer name, service,
requested date/time, contact info, and how long the request has been waiting.

### "Approve the booking from [customer]"
Find the pending booking. Validate the slot is still open. Confirm the booking,
create the internal appointment, and notify the customer.

### "What's the next available time for [service]?"
Compute available slots for the next 7 days for the requested service and any
qualified staff. Return the earliest 5 options.

### "Show all bookings for [date]"
Pull all customer_bookings with `start_time` on that date and `status` in
[confirmed, pending]. Include: customer name, service, time, staff, and status.

### "Customer [name] wants to cancel their booking"
Find the booking. Apply the cancellation policy. Present the policy outcome (refund
or fee amount) to both the owner and customer before processing any charges.

### "Add a new service to the booking page"
Collect: service name, duration, price, which staff can perform it, any buffer time
needed, and deposit requirement. Create a new `booking_services[]` entry with
`allow_online_booking` = true. Present for owner review before making it visible.

### "Disable online booking for [service]"
Set `allow_online_booking` = false on the service record. Confirm. The service
remains in the system but is no longer visible to customers.

---

## Integration Points

| System | How |
|--------|-----|
| `schemas/booking.json` | Source of truth for services, policy, bookings, and notifications |
| `schemas/schedule.json` | Confirmed bookings create internal appointments; availability reads from schedule |
| `schemas/crm.json` | Customer record created or matched on first booking; repeat customers recognized |
| Scheduling module | Availability computed from field_workers[] and appointments[]; confirmed booking creates appointment record |
| Invoicing module | Deposits and service payments flow to invoicing; QuickBooks sync for financial records |

---

## Hard Stops

1. **No slot confirmed without a real-time availability check.** Even in instant
   confirmation mode, always validate that the requested slot is still open at the
   moment of confirmation. Two customers submitting the same slot simultaneously must
   not both receive confirmation.

2. **No booking confirmed in owner_must_approve mode without explicit owner action.**
   The AI may auto-decline after a timeout but cannot auto-confirm. Only the owner
   can confirm a booking in approval mode.

3. **No late cancellation fee charged without customer acknowledgment.** When a
   fee applies, show the customer the amount and require their explicit confirmation
   before processing the charge.

4. **No internal appointment created for a pending booking.** Internal appointments
   are only created when a booking reaches confirmed status. A pending request does
   not block the calendar for staff.

5. **No customer data exposed through the availability interface.** The public
   booking page and widget return only available times. They must never return names,
   appointment titles, job descriptions, or any information about other customers'
   bookings.
