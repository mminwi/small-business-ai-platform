Scope and architecture

This module exposes a customer-facing booking flow that writes to markdown-defined procedures and JSON data stores, then hands confirmed bookings to the internal scheduling module, which in turn syncs with QuickBooks for financials. The public surface is strictly read-only for availability/search and write-only for booking requests; all staff calendars, job details, and financial data remain internal.

Core data model

Key entities (JSON documents in Drive/SharePoint):

Business: id, name, locations, time zone, settings.

StaffMember: id, name, skills/services, working hours, capacity (1:1 vs classes), location.

BookingService: what can be booked (haircut, 60-min massage, dog walk, consultation).

BookingPolicy: booking window, buffers, cancellation/reschedule rules, deposits.

BookingSlot (virtual): computed, not stored permanently; read-only view of availability.

Customer: minimal CRM record, contact info, preferences.

CustomerBooking: customer request and state (pending, confirmed, declined, cancelled).

BookingPayment (optional): deposit, payment intent, refunds.

BookingNotification: events to send (email/SMS/push).

InternalAppointment / Job: internal scheduling entity that mirrors confirmed bookings.

Relationships:

Business has many StaffMember, BookingService, BookingPolicy.

StaffMember can perform many BookingService (skills matrix).

CustomerBooking references BookingService, optionally StaffMember, and maps 1:1 to an InternalAppointment when confirmed.

BookingConfirmation is a “view” over CustomerBooking including generated confirmation code, join links, and formatted messages; not necessarily a distinct stored entity.

Mapping to internal job/appointment:

CustomerBooking.id ↔ InternalAppointment.external_booking_id

CustomerBooking.service_id ↔ InternalAppointment.service_id

CustomerBooking.staff_id ↔ InternalAppointment.assigned_staff_id

CustomerBooking.start/end ↔ InternalAppointment.start/end

CustomerBooking.customer ↔ InternalAppointment.customer_id/contact

Status sync: confirmed → scheduled; cancelled → cancelled; rescheduled → updated appointment.
​

JSON schemas

Below are representative JSON Schemas (draft-07 style) you can store as .schema.json and validate with your AI/logic engine.

3.1 BookingService

json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "BookingService",
  "type": "object",
  "required": ["id", "business_id", "name", "duration_minutes", "base_price", "active"],
  "properties": {
    "id": { "type": "string" },
    "business_id": { "type": "string" },
    "name": { "type": "string" },
    "description_markdown": { "type": "string" },
    "category": { "type": "string" },
    "duration_minutes": { "type": "integer", "minimum": 5 },
    "base_price": { "type": "number", "minimum": 0 },
    "currency": { "type": "string", "minLength": 3, "maxLength": 3 },
    "allow_online_booking": { "type": "boolean", "default": true },
    "staff_ids": {
      "description": "Staff members who can perform this service; empty means any staff with matching skill.",
      "type": "array",
      "items": { "type": "string" }
    },
    "location_ids": {
      "type": "array",
      "items": { "type": "string" }
    },
    "max_per_slot": {
      "description": "For classes or group sessions.",
      "type": "integer",
      "minimum": 1,
      "default": 1
    },
    "requires_deposit": { "type": "boolean", "default": false },
    "deposit_amount": { "type": "number", "minimum": 0 },
    "deposit_type": {
      "type": "string",
      "enum": ["fixed", "percentage"],
      "default": "fixed"
    },
    "online_only": {
      "description": "If true, only bookable through the online module.",
      "type": "boolean",
      "default": false
    },
    "metadata": { "type": "object", "additionalProperties": true },
    "active": { "type": "boolean", "default": true }
  },
  "additionalProperties": false
}
3.2 BookingPolicy

json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "BookingPolicy",
  "type": "object",
  "required": ["id", "business_id", "time_zone"],
  "properties": {
    "id": { "type": "string" },
    "business_id": { "type": "string" },
    "time_zone": { "type": "string" },
    "allow_same_day": { "type": "boolean", "default": true },
    "min_notice_minutes": {
      "description": "Minimum notice before start time to allow booking.",
      "type": "integer",
      "minimum": 0,
      "default": 0
    },
    "max_advance_days": {
      "description": "How far in advance customers can book.",
      "type": "integer",
      "minimum": 1,
      "default": 60
    },
    "buffer_before_minutes": {
      "description": "Default buffer before an appointment for this business.",
      "type": "integer",
      "minimum": 0,
      "default": 0
    },
    "buffer_after_minutes": {
      "description": "Default buffer after an appointment.",
      "type": "integer",
      "minimum": 0,
      "default": 0
    },
    "customer_cancellation_allowed": {
      "type": "boolean",
      "default": true
    },
    "customer_reschedule_allowed": {
      "type": "boolean",
      "default": true
    },
    "free_cancellation_cutoff_hours": {
      "description": "Hours before appointment when cancellation is free.",
      "type": "number",
      "minimum": 0,
      "default": 24
    },
    "late_cancellation_fee_type": {
      "type": "string",
      "enum": ["none", "fixed", "percentage"],
      "default": "none"
    },
    "late_cancellation_fee_amount": {
      "type": "number",
      "minimum": 0,
      "default": 0
    },
    "no_show_fee_type": {
      "type": "string",
      "enum": ["none", "fixed", "percentage"],
      "default": "none"
    },
    "no_show_fee_amount": {
      "type": "number",
      "minimum": 0,
      "default": 0
    },
    "auto_confirm_mode": {
      "description": "How online bookings are confirmed.",
      "type": "string",
      "enum": ["instant", "owner_must_approve"],
      "default": "instant"
    },
    "auto_cancel_pending_after_minutes": {
      "description": "If owner_must_approve and not actioned, auto-decline after this many minutes.",
      "type": "integer",
      "minimum": 0,
      "default": 1440
    },
    "deposit_required_for_services": {
      "description": "Optional overrides per service.",
      "type": "array",
      "items": {
        "type": "object",
        "required": ["service_id", "requires_deposit"],
        "properties": {
          "service_id": { "type": "string" },
          "requires_deposit": { "type": "boolean" },
          "deposit_amount": { "type": "number", "minimum": 0 },
          "deposit_type": {
            "type": "string",
            "enum": ["fixed", "percentage"]
          }
        },
        "additionalProperties": false
      }
    },
    "terms_markdown": { "type": "string" },
    "metadata": { "type": "object", "additionalProperties": true }
  },
  "additionalProperties": false
}
3.3 CustomerBooking (customer-submitted)

This is the payload the public UI posts; internal logic enriches it and persists a validated record.

json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "CustomerBooking",
  "type": "object",
  "required": [
    "id",
    "business_id",
    "service_id",
    "start_time",
    "time_zone",
    "customer",
    "source"
  ],
  "properties": {
    "id": {
      "description": "Public booking id (human readable or UUID).",
      "type": "string"
    },
    "business_id": { "type": "string" },
    "location_id": { "type": "string" },
    "service_id": { "type": "string" },
    "staff_id": {
      "description": "Optional preferred staff; null means 'any'.",
      "type": ["string", "null"]
    },
    "start_time": {
      "description": "Requested start time in ISO 8601 with offset.",
      "type": "string",
      "format": "date-time"
    },
    "end_time": {
      "description": "Computed on server using service duration and buffers.",
      "type": "string",
      "format": "date-time"
    },
    "time_zone": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["pending", "confirmed", "declined", "cancelled"],
      "default": "pending"
    },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "customer": {
      "type": "object",
      "required": ["name", "email"],
      "properties": {
        "id": { "type": "string" },
        "name": { "type": "string" },
        "phone": { "type": "string" },
        "email": { "type": "string", "format": "email" },
        "notes": { "type": "string" },
        "preferences": { "type": "object", "additionalProperties": true }
      },
      "additionalProperties": false
    },
    "pricing": {
      "type": "object",
      "properties": {
        "service_price": { "type": "number", "minimum": 0 },
        "currency": { "type": "string", "minLength": 3, "maxLength": 3 },
        "deposit_required": { "type": "boolean", "default": false },
        "deposit_amount": { "type": "number", "minimum": 0 },
        "tax_amount": { "type": "number", "minimum": 0 },
        "discount_amount": { "type": "number", "minimum": 0 },
        "total_due_now": { "type": "number", "minimum": 0 },
        "total_at_service": { "type": "number", "minimum": 0 }
      },
      "additionalProperties": false
    },
    "channel": {
      "description": "How the booking was created.",
      "type": "string",
      "enum": ["web_widget", "public_page", "chat_ai", "phone_agent", "manual_internal"],
      "default": "web_widget"
    },
    "source": {
      "description": "Marketing source or referrer.",
      "type": "string"
    },
    "notes": { "type": "string" },
    "metadata": { "type": "object", "additionalProperties": true }
  },
  "additionalProperties": false
}
3.4 BookingNotification

json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "BookingNotification",
  "type": "object",
  "required": ["id", "business_id", "event_type", "channel", "recipient_type"],
  "properties": {
    "id": { "type": "string" },
    "business_id": { "type": "string" },
    "booking_id": { "type": "string" },
    "event_type": {
      "description": "Trigger in the booking lifecycle.",
      "type": "string",
      "enum": [
        "booking_created_customer",
        "booking_created_owner",
        "booking_confirmed_customer",
        "booking_confirmed_owner",
        "booking_declined_customer",
        "booking_cancelled_customer",
        "booking_cancelled_owner",
        "reminder_before_start",
        "followup_after"
      ]
    },
    "channel": {
      "type": "string",
      "enum": ["email", "sms", "push", "webhook"]
    },
    "recipient_type": {
      "type": "string",
      "enum": ["customer", "owner", "staff"]
    },
    "send_offset_minutes": {
      "description": "For reminders/followups; minutes relative to start_time.",
      "type": "integer"
    },
    "to": {
      "description": "Resolved address/phone; can be derived at send time.",
      "type": "string"
    },
    "subject_template": { "type": "string" },
    "body_template_markdown": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["pending", "sent", "failed"],
      "default": "pending"
    },
    "error": { "type": "string" },
    "created_at": { "type": "string", "format": "date-time" },
    "sent_at": { "type": "string", "format": "date-time" },
    "metadata": { "type": "object", "additionalProperties": true }
  },
  "additionalProperties": false
}
Availability logic and BookingSlot

4.1 Concept of BookingSlot

BookingSlot is not a primary stored entity. Instead, your backend computes an array of candidate start times given:

Staff working hours and breaks.

Staff/service skills and service duration.

Existing internal appointments and online bookings.

Buffers (before/after) per policy or service.

Business constraints (booking window, min notice).

You expose BookingSlot via a dedicated read-only endpoint or file, e.g. GET /public/availability?business_id=&service_id=&date=&staff_id= which returns an array of slots (start, end, staff_id, capacity remaining) without leaking anything about other appointments.

4.2 Data shape for BookingSlot (response, not persisted)

json
{
  "business_id": "biz_123",
  "service_id": "svc_haircut_30",
  "staff_id": "staff_alex",
  "date": "2026-02-25",
  "time_zone": "America/Chicago",
  "slots": [
    {
      "start_time": "2026-02-25T09:00:00-06:00",
      "end_time": "2026-02-25T09:30:00-06:00",
      "capacity_total": 1,
      "capacity_available": 1
    },
    {
      "start_time": "2026-02-25T09:45:00-06:00",
      "end_time": "2026-02-25T10:15:00-06:00",
      "capacity_total": 1,
      "capacity_available": 0
    }
  ]
}
4.3 Generation algorithm (high-level)

For each staff/service/location/day:

Get staff working intervals (e.g., 9–5 with breaks).

Expand into candidate start times at a configurable granularity (e.g., 15-minute grid).

For each candidate:

Compute service end time = start + service_duration.

Add buffer_before and buffer_after (service-level override or policy default).

Check:

Within booking window: now + min_notice ≤ start ≤ now + max_advance_days.

No overlap with existing internal appointments plus their buffers.

No overlap with other bookings for same staff and location.

Staff capacity not exceeded for group events.

Return only those candidates that pass.

Buffer handling:

Store buffer defaults in BookingPolicy; allow per-service overrides.

When checking overlaps, consider appointment interval as [start - buffer_before, end + buffer_after].

For back-to-back same-service bookings, buffers still apply, preventing unrealistic stacking.

Security:

The customer-facing API never returns raw appointment titles, notes, or customer names; only free/blocked times.
​

You can pre-compute and cache slot JSON per day/service/staff into Drive/SharePoint to reduce computation for low-resourced businesses.

Service configuration (owner/admin)

Admin-configurable fields, stored in JSON (or markdown + JSON):

Business profile: name, logo, address, time zone, default location.

Services:

Name, description, category.

Duration, price, tax treatment.

Which staff can perform (list or inferred by skill tags).

Location(s) and whether virtual.

Max capacity (1 for 1:1, >1 for classes).

Online booking enabled/disabled per service.

Buffer overrides before/after.

Deposit requirement and amount (or “use policy default”).

Booking window:

Allow same-day or not.

Minimum notice (minutes/hours).

Maximum days in advance.

Cancellation and reschedule:

Allowed or not.

Free cancellation cutoff.

Late cancellation/no-show fee rules and whether auto-charge is enabled via payment processor (Square/Stripe/etc.).
​

Deposits:

Global default for online bookings.

Service-specific overrides.

Whether deposit is refundable or applied to final bill.

Confirmation behavior:

Instant confirm (slot reserved on submission).

Owner-must-approve (booking goes to pending; owner approves/declines).

Optional auto-expire for pending.

Notifications:

Which emails/SMS to send (booking created, confirmed, reminders).

Reminder timing (e.g., 24h and 2h before).

AI/chat options:

Allow AI chat to book on behalf of customers.

Allowed services and times for AI.

Tone/persona (less critical, but fits your markdown procedures design).

All of this can be managed in a simple JSON editor UI or even YAML/markdown that is parsed into JSON for the AI engine.

Customer experience flow

Typical UX for a hair salon, massage therapist, trainer, etc.:

Entry

Customer clicks “Book Now” from website, social profile, or Google Business Profile link.

Landing page shows business name, logo, basic instructions, and service list.

Service selection

List of categories (Hair, Massage, Training, Pets, Photography).

For each service: name, duration, price, short description.

Optional add-ons (e.g., beard trim added to haircut) using a simple nested service or modifiers model.

Staff selection (optional)

If owner enables staff choice:

“Any available” or a list of staff with avatars.

Some verticals (wedding photographer, personal trainer) may always expose staff.

Otherwise, staff assignment is automatic based on availability and skill.

Date/time selection

Calendar view for date; shows which days have open slots.

Time grid for the selected date, grouped by staff if staff is visible.

Customer chooses a slot; UI indicates time zone and buffer (implicit, not shown as “buffer” but by not offering too-tight times).

If AI/chat: conversation collects service and preferred times, then surfaces the same slots in conversational form.

Customer details

Fields:

Name (required).

Email (required for confirmation).

Phone (recommended, for SMS reminders).

Optional notes (e.g., “I have long hair”, “my dog is anxious”).

Acknowledgment checkbox for policy/terms, with link to cancellation and deposit policy.

For services requiring deposit: show amount due now and payment UI.

Review & confirmation

Summary screen:

Service, staff, location, date/time, price, deposit, policies.

Customer confirms; system creates CustomerBooking with status:

confirmed for instant confirm.

pending for owner-must-approve.

Confirmation page:

Confirmation number.

Instructions (e.g., arrive 5 min early).

“Add to calendar” links (Google, Apple, Outlook).

Link to reschedule/cancel (with policy notes).

Communications

Immediate:

Customer email: booking received/confirmed with summary and links.

Owner/staff email/SMS: new booking notification.

Reminders:

Typical pattern: 24h before and 2h before via email/SMS, configurable.

Follow-up:

Optional “How was your visit?” and “Ready to book your next session?” for retention.

Embedding and delivery

Technical delivery options for very small businesses:

Embeddable widget:

A JS snippet that injects an iframe or web component into any site (Squarespace, Wix, WordPress, custom HTML).

e.g., <script src=".../booking-widget.js" data-business-id="biz_123"></script>.

Widget communicates with your backend via public JSON APIs.

Standalone booking page:

Hosted by your platform, with a unique URL per business: https://book.example.com/{business_slug}.

Owner can link this from Instagram, Facebook, email signatures, etc.

Link in email or SMS:

Simple deep links including service and staff preselected via query params: ...?service=massage60&staff=alex.

Google Business Profile integration:

Initially, simplest is to configure “Book” button to the standalone booking page.

Later, you could integrate with Reserve with Google (but that’s more complex and not necessary for MVP).
​

No-developer setup:

Admin UI that generates:

Copy-paste HTML snippet for websites.

Shareable booking link.

QR code image pointing to booking page (for printing on cards/signs).

Owner-must-approve workflow

When policy is owner_must_approve:

Customer flow is the same, but final screen says “Request sent” instead of “Confirmed”.

CustomerBooking stored with status pending.

Notifications:

Owner/staff receive email/SMS: “New booking request from [Name] for [Service] at [Time]” with Approve/Decline buttons or links.

Optionally, a simple internal dashboard view lists pending requests.

Approval actions:

Owner clicks Approve link → internal API validates that the slot is still free.

If free:

Set booking status = confirmed.

Create InternalAppointment.

Send confirmation email/SMS to customer.

If not free (e.g., filled by someone else, staff changed):

Prompt owner for alternative slot suggestions (or let AI propose options).

If owner picks alternative, send proposal to customer.

Decline:

Set status declined.

Optionally capture reason.

Notify customer with suggestion to try other times.

Timeouts:

If auto_cancel_pending_after_minutes > 0, a scheduled task checks pending bookings and:

Auto-declines those exceeding the timeframe.

Notifies customer: “We weren’t able to confirm this time, please choose another slot.”

Owner can override manually in internal scheduling UI at any time.

Cancellations and rescheduling

9.1 Customer-initiated cancellation

Confirmation email includes a secure “Manage booking” link with booking id and token.

Manage page offers:

Cancel appointment (if allowed by policy).

Reschedule to a new time (subject to availability).
​

Cancellation policy enforcement:

On cancel request:

Check time until start vs free_cancellation_cutoff_hours.

If before cutoff:

Mark booking cancelled.

For deposit:

If refundable: mark deposit for refund or create refund transaction.

If non-refundable: keep and mark as cancellation fee.

If after cutoff and late_cancellation_fee_type != none:

Calculate fee (fixed or percentage).

If card-on-file or deposit available, create charge or deduct from deposit.
​

Always push cancellation update to InternalAppointment (set to cancelled and trigger any downstream processes).

9.2 Rescheduling flow

Manage page:

“Reschedule” button opens availability UI scoped to same service (and optionally same staff).

Customer chooses new slot; system:

Validates against policies (min notice, max advance).

Updates booking start/end time.

Updates InternalAppointment accordingly.

Recalculates deposit/cancellation rules if policing by date, if needed.

Policy examples:

Allow reschedule up to X hours before start.

Consider late reschedule as cancellation + new booking, potentially with fee.

All actions write audit notes into the booking JSON or a separate history log.

Integration with internal scheduling module

10.1 Mapping on confirmation

When a booking becomes confirmed (instant or after approval):

Create InternalAppointment record with:

external_booking_id = CustomerBooking.id

business_id, location_id

service_id

assigned_staff_id (or null if auto-assign later)

customer_id (link to Customer, create if new)

start_time, end_time, time_zone

status = scheduled

source = "online_booking"

notes (customer notes and internal notes)

price, tax, deposit, outstanding_balance

Any tags (e.g., “new_customer”, “rebooking”).

Additionally, create:

Work order/job record if your scheduling module differentiates jobs from appointments (especially for field trades).

Payment entries or QuickBooks sales receipt/invoice when appropriate (depending on your finance integration design).

10.2 Staff notification

On appointment creation or update:

Notify assigned staff by:

Email with appointment details.

Optional SMS push (e.g., via Twilio or similar).

Update of their internal schedule view.

For mobile field workers (dog walkers, plumbers), you can write the job into a JSON file consumed by a mobile app or web app; notifications can include deep links into that.

Bidirectional behavior:

If owner edits time/staff from internal scheduling UI, you can optionally:

Update the linked CustomerBooking record.

Send updated confirmation to customer.

AI assistance opportunities

With Claude as your engine, you can embed AI deeply into the booking flow:

Chat/text booking agent:

Channel: web chat widget, SMS, WhatsApp, or social DMs.

AI interprets user intent: “Need a haircut Saturday after 2pm” → maps to service, preferred window, location.

AI queries availability endpoint to fetch free slots and proposes top 3 options.

After user confirms, AI constructs a CustomerBooking JSON and posts it to your booking API.

Smart slot suggestions:

AI looks at:

Customer history: preferred staff, usual days/times, frequency.

Business goals: fill gaps, reduce idle time, steer to off-peak discounts.

Suggest: “You usually see Alex on Thursday evenings. The next available is Thu 6:30pm — book it?”

Rebooking reminders:

Periodic job uses history to detect patterns (e.g., massages every 4 weeks, haircuts every 6 weeks) and prompts via email/SMS:

“It’s been 6 weeks since your last appointment, want to rebook?” with direct link to AI chat or prefilled booking page.

Policy explanations and triage:

AI explains cancellation/reschedule policies in natural language.

For edge cases (“I’m sick last minute”), AI can:

Classify as exception candidate.

Draft suggested response for owner.

Create internal note if a manual override is requested.

Owner assistance:

AI can help set up services and policies by asking guided questions, then generating the BookingService and BookingPolicy JSON.

AI can propose a minimal booking flow configuration based on industry type (salon, massage, trainer, pet, trades).

Your markdown procedures can define prompts and guardrails so AI reads/writes only allowed JSON structures and respects policy files.

Comparison and MVP definition

Feature comparison snapshot
Product	Self-service booking	Staff selection	Policies & deposits	Integrations focus
Calendly	Yes, primarily meetings
Limited	Basic buffers, limited deposits
Calendars, video conferencing, simple payments
Acuity Scheduling	Yes, customizable services
Yes	Strong packages, payments, forms
Websites, payments, CRM, marketing tools
Square Appointments	Yes, tightly tied to POS
Yes	Strong cancellation/no-show fees
​	Payments, POS, retail, inventory
​
Vagaro	Yes, rich for beauty/fitness
​	Yes	Memberships, packages, fees
​	POS, marketing, multi-location
​
Booksy	Yes, mobile-first salon/barber
​	Yes	No-show protection, prepayments
​	Marketplace, payments, marketing
​
ServiceTitan OB	Yes for trades (jobs)
Typically auto	Job-focused, narrower consumer UX
Deep field ops, dispatch, estimates, invoices
MVP for a 2-person salon or solo massage therapist:

Owner configuration:

Create 3–10 services with duration and price.

Set working hours and simple buffer (e.g., 10 minutes).

Enable instant confirmation.

Set a basic cancellation policy (24h, no fee) and optional deposit.

Customer-facing:

Simple 3–4 step flow: service → date/time → details → confirm.

Staff selection optional; for solo operators, skip staff entirely.

Email confirmation and one reminder (24h before).

Backend:

Availability generation per service/staff/day.

Creation of CustomerBooking JSON and InternalAppointment.

Simple cancellations/reschedules via link.

Owner email notifications; staff optionally.

Integrations:

Standalone booking page + embeddable widget.

Optional QuickBooks sync of deposits/receipts later; can be deferred beyond MVP, as many micro-operators can manually reconcile.

You can then layer on more complex workflows (group classes, owner approval, payment automation, AI chat booking) without complicating the base flow for very small service businesses.