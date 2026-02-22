# Perplexity Research Prompts — Gap Specs

These three prompts cover modules identified as gaps in the existing spec set.
Run each prompt in Perplexity (Pro, with Deep Research enabled). Paste results
into the `/specs/` folder as new spec files.

**Target audience for all three:** Non-technical small business owners with 1–10
employees. Field service trades (plumbers, HVAC, electricians, auto mechanics,
lawn care, pest control, pool service, cleaning services) and personal service
businesses (salons, massage therapists, personal trainers, pet groomers).

---

## Prompt 21 — Recurring Service Contracts & Maintenance Agreements

**Run this in Perplexity with Deep Research enabled.**

```
I am building an open-source AI-powered back-office platform for small service
businesses (1–10 employees). The platform uses Claude (Anthropic API) as the AI
engine. All business logic lives in markdown procedure files. Data lives in JSON
files stored in Google Drive or SharePoint. QuickBooks Online is the accounting
system and we integrate with it via API — we never rebuild what QB already does.

I need a comprehensive technical spec for a Recurring Service Contracts /
Maintenance Agreements module. This is for businesses that sell ongoing service
agreements — for example: an HVAC company that sells annual tune-up contracts
($200/year for 2 visits), a pest control company with monthly service agreements,
a lawn care company with weekly mowing agreements, a pool service company with
monthly maintenance agreements, and a house cleaning company with biweekly
service agreements.

Please cover:

1. Core data model — what entities are needed? A contract record, recurring
   schedule, linked customers, services covered, pricing, term dates. What are
   the key fields? What relationships connect contracts to work orders,
   scheduling, and invoicing?

2. JSON schemas — provide representative JSON schemas for: ServiceContract,
   ContractLineItem (what services are included), ContractOccurrence (each
   scheduled visit generated from the contract), and ContractRenewal (tracking
   renewals and lapses).

3. Contract lifecycle — what are the states? (draft, active, paused, expired,
   canceled, renewed). What triggers each transition? What automation should
   exist — auto-generating work orders on schedule, sending renewal reminders,
   auto-invoicing per visit or monthly flat?

4. Scheduling integration — how does a recurring contract auto-generate
   appointments or work orders on a defined schedule (weekly, biweekly, monthly,
   quarterly, annual)? How does it handle skipped visits (customer on vacation),
   date adjustments, and multi-technician assignments?

5. Billing patterns — flat monthly fee regardless of visits, per-visit billing,
   prepaid annual (customer pays upfront for the year), and hybrid (monthly fee
   + parts billed separately). How do these map to QuickBooks recurring
   invoices? What does the QB API integration look like for recurring billing?

6. Renewal workflow — when should renewal reminders trigger (30/60/90 days out)?
   What should an AI-drafted renewal offer look like? How do you handle price
   increases at renewal? What happens when a contract expires without renewal —
   do open work orders continue?

7. Reporting — what does the owner need to see? Active contracts by type, MRR
   (monthly recurring revenue), contracts expiring in the next 90 days, visit
   completion rate per contract, contracts overdue for a visit.

8. AI assistance opportunities — where can AI specifically help? Drafting
   contract proposals, flagging contracts where visits are behind schedule,
   identifying customers who might want to upgrade, suggesting pricing based on
   service history.

9. Edge cases — partial year contracts (customer signs mid-year), contracts
   that include emergency calls, contracts that cover multiple locations for the
   same customer, contracts inherited when a customer changes ownership
   (property management scenario).

10. Comparison to how other small business software handles this — what do
    ServiceTitan, Jobber, Housecall Pro, or similar field service platforms do
    for maintenance agreements? What do they do well? What do they miss for very
    small businesses?

Format your response with numbered sections matching the above. Include JSON
schema examples in code blocks. Be specific and practical — this is for
implementation, not a marketing overview.
```

---

## Prompt 22 — Asset & Equipment Tracking (Customer Equipment)

**Run this in Perplexity with Deep Research enabled.**

```
I am building an open-source AI-powered back-office platform for small service
businesses (1–10 employees). The platform uses Claude (Anthropic API) as the AI
engine. All business logic lives in markdown procedure files. Data lives in JSON
files stored in Google Drive or SharePoint. QuickBooks Online is the accounting
system.

I need a comprehensive technical spec for an Asset & Equipment Tracking module.
This tracks the customer's physical equipment that the company services — not the
company's own parts inventory (that's a separate module). Examples:

- HVAC company tracks each customer's furnace, AC unit, heat pump, and air handler:
  brand, model, serial number, install date, warranty expiration, refrigerant type,
  filter size, service history.
- Auto mechanic tracks each customer's vehicles: year/make/model, VIN, license
  plate, mileage at each visit, current mileage, service history, known issues.
- Pool service company tracks each customer's pump, filter, heater, and controller:
  brand, model, chemical history, equipment age.
- Appliance repair company tracks customer appliances: brand, model, serial number,
  purchase date, warranty, parts previously installed.
- Elevator maintenance company tracks each elevator at each building.

Please cover:

1. Core data model — what entities are needed? Asset record, linked to customer
   and service location. What are the key fields that apply across all industries
   (and which are industry-specific)? How do assets relate to work orders (service
   history), parts/inventory (what parts have been installed), and contracts
   (which maintenance agreement covers this asset)?

2. JSON schemas — provide representative JSON schemas for: Asset (the equipment
   record), AssetAttribute (flexible key-value pairs for industry-specific fields
   like VIN, refrigerant type, filter size), AssetServiceHistory (summary view
   linking to work orders), and AssetDocument (manuals, warranty docs, photos).

3. Asset identification — barcode/QR code tagging for field identification (the
   tech scans the unit to pull it up). Serial number lookup. How should the AI
   handle "I can't find this unit in the system" — create a new asset record on
   the spot?

4. Service history — when a work order is completed against an asset, what
   information should be captured on the asset record? Mileage (for vehicles),
   readings/measurements (refrigerant charge, pressure readings), parts installed
   (with serial numbers for warranty tracking), condition rating.

5. Warranty tracking — how to track both manufacturer warranty (expires by date
   or by usage/mileage) and extended warranties or service warranties the company
   itself provides. Alert triggers when warranty is about to expire — useful for
   "your warranty expires in 30 days, would you like to purchase an extended
   plan?"

6. Integration with work orders — when a technician opens a work order, how
   does the asset record surface? What prior history should the AI proactively
   show? "Last time we serviced this unit (6 months ago), the tech noted the
   heat exchanger was cracked — is it repaired?"

7. Integration with recurring contracts — how do assets connect to maintenance
   agreements? A contract might cover "all HVAC equipment at this address" or
   a specific unit by serial number.

8. Multi-location and multi-asset customers — a property management company has
   100 units, each with HVAC equipment. A fleet customer has 20 vehicles. What
   does the data model look like for bulk asset management without becoming an
   enterprise ERP?

9. AI assistance opportunities — where can AI specifically help? Recommending
   service based on asset age and history, flagging assets that are overdue for
   service, drafting "your system is aging — here's a replacement quote,"
   identifying patterns (brand X always fails at 8 years).

10. Comparison — how do ServiceTitan, Jobber, RepairShopr, Shop-Ware (auto),
    and similar platforms handle equipment tracking? What is the minimum viable
    implementation for a 3-person HVAC shop vs. a 10-person auto repair shop?

Format your response with numbered sections. Include JSON schema examples in
code blocks. Be specific and practical — this is for implementation, not a
marketing overview.
```

---

## Prompt 23 — Online / Inbound Customer Booking

**Run this in Perplexity with Deep Research enabled.**

```
I am building an open-source AI-powered back-office platform for small service
businesses (1–10 employees). The platform uses Claude (Anthropic API) as the AI
engine. All business logic lives in markdown procedure files. Data lives in JSON
files stored in Google Drive or SharePoint. QuickBooks Online is the accounting
system.

I need a comprehensive technical spec for an Online / Inbound Customer Booking
module — a customer-facing booking interface where customers can schedule their
own appointments without calling the business. This is important for:

- Hair salons and barber shops (customers book specific stylists and services)
- Massage therapists and spas (customers book specific service lengths and types)
- Personal trainers and fitness studios (customers book sessions or classes)
- Pet groomers and dog walkers (customers book grooming appointments or walks)
- Photographers (customers book sessions with optional package selection)
- Wedding planners (clients book consultations)
- Service trades where the business wants to offer online booking as an option
  (a plumber who accepts "schedule a diagnostic" requests online)

This module is the inbound customer channel. Once a booking is made, it flows
into the internal scheduling module (which handles dispatch, work orders, etc.).

Please cover:

1. Core data model — what entities are needed? BookingService (what can be
   booked: name, duration, price, which staff can perform it), BookingSlot
   (available time offered to customers), CustomerBooking (the customer's
   reservation), BookingConfirmation. How do these map to the internal
   appointment/job records?

2. JSON schemas — provide representative JSON schemas for: BookingService,
   BookingPolicy (cancellation rules, advance booking window, buffer time
   between appointments), CustomerBooking (customer-submitted), and
   BookingNotification (what gets sent when).

3. Availability logic — how does the system generate available slots for
   customers to choose from? The source of truth is the internal scheduling
   module's field worker availability and existing appointments. What is the
   correct way to expose a read-only "available times" view to the public
   without exposing internal business data? How is buffer time handled between
   appointments?

4. Service configuration — what does the owner need to configure? Services
   offered (name, duration, price, which staff), booking window (can customers
   book same-day? how far in advance?), cancellation policy (24-hour notice,
   no refunds, etc.), deposit requirements, confirmation behavior (instant
   confirm vs. owner-must-approve).

5. Customer experience flow — step by step, what does the customer see?
   Service selection → staff selection (optional) → date/time selection →
   contact info → confirmation. What confirmation communications are sent?
   What reminders?

6. Embedding and delivery — how is this delivered to the customer? An
   embeddable widget for the company's existing website, a standalone booking
   page URL, a link in email or text, a Google Business Profile integration.
   What are the technical options for a very small business that may not have
   a developer?

7. Owner-must-approve workflow — for businesses that don't want fully automatic
   booking (a contractor who wants to review before confirming). What does the
   approval workflow look like? What notification does the owner receive? What
   happens if they don't respond in time?

8. Cancellations and rescheduling — customer-initiated cancellation (web link
   in confirmation email). Rescheduling flow. Cancellation policy enforcement.
   How does a canceled online booking flow back into the internal scheduling
   system?

9. Integration with internal scheduling module — when a customer booking is
   confirmed, it should automatically create a job record and appointment in
   the internal scheduling module. What data maps over? How is the field worker
   notified?

10. AI assistance opportunities — where can AI specifically help in a booking
    flow? Handling inbound booking requests via chat or text (customer texts
    "I need a haircut Saturday" and AI books it). Smart slot suggestions based
    on customer preference history. Rebooking reminders ("You usually come in
    every 6 weeks — ready to book?").

11. Comparison — how do Calendly, Acuity Scheduling, Square Appointments,
    Vagaro, Booksy, and ServiceTitan's online booking handle this? What is the
    minimum viable implementation that gives a 2-person salon or a solo massage
    therapist what they need, without over-engineering?

Format your response with numbered sections. Include JSON schema examples in
code blocks. Be specific and practical — this is for implementation.
```

---

## After Running These Prompts

1. Paste each result into `/specs/` as:
   - `21 — Recurring Service Contracts.md`
   - `22 — Asset & Equipment Tracking.md`
   - `23 — Online Inbound Booking.md`

2. Next session: write procedure files and schemas for each, following the
   same pattern as Chunks 1–3.
