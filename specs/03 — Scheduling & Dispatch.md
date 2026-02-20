## 1. Core Domain Concepts

This section defines the main entities and their relationships for scheduling and dispatch.

## 1.1 Entity Overview

- Customer: Person or business requesting service; owns one or more service locations.
- ServiceLocation: Physical address where work occurs, linked to a service territory and geocoded.
- Job: A unit of work requested by a customer (e.g., “Install water heater”), with required skills, estimated duration, and SLA.
- Appointment: A scheduled time window for a job, optionally split into multiple visits.
- Technician: Field resource with skills, certifications, home base, and availability calendar.
- TechnicianAvailability: Time-bounded segments indicating working hours, PTO, and breaks.
- ServiceTerritory: Geographical area with assignment rules and coverage hours.
- RouteStop / DailyRoute: Sequence of appointments assigned to a technician on a given day.
- Notification: Outbound customer or technician communication (SMS, email, push).
- CalendarSync: Integration record linking a technician/user to their Google Calendar.

------

## 2. JSON Schemas & Field Definitions

Schemas are illustrative; you can convert to OpenAPI, Protobuf, or DB DDL as needed.

## 2.1 Customer

```
json{
  "$id": "Customer",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "externalRef": { "type": ["string", "null"] },
    "name": { "type": "string" },
    "contactName": { "type": "string" },
    "phone": { "type": "string" },
    "email": { "type": ["string", "null"], "format": "email" },
    "preferredChannel": { "type": "string", "enum": ["sms", "email", "phone", "none"] },
    "billingAddress": {
      "type": "object",
      "properties": {
        "line1": { "type": "string" },
        "line2": { "type": ["string", "null"] },
        "city": { "type": "string" },
        "state": { "type": "string" },
        "postalCode": { "type": "string" },
        "country": { "type": "string", "default": "US" }
      },
      "required": ["line1", "city", "state", "postalCode"]
    },
    "createdAt": { "type": "string", "format": "date-time" },
    "updatedAt": { "type": "string", "format": "date-time" }
  },
  "required": ["id", "name", "phone", "createdAt"]
}
```

## 2.2 ServiceLocation

```
json{
  "$id": "ServiceLocation",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "customerId": { "type": "string", "format": "uuid" },
    "label": { "type": "string" },
    "address": {
      "type": "object",
      "properties": {
        "line1": { "type": "string" },
        "line2": { "type": ["string", "null"] },
        "city": { "type": "string" },
        "state": { "type": "string" },
        "postalCode": { "type": "string" },
        "country": { "type": "string", "default": "US" }
      },
      "required": ["line1", "city", "state", "postalCode"]
    },
    "geo": {
      "type": "object",
      "properties": {
        "lat": { "type": "number" },
        "lng": { "type": "number" },
        "geocodedAt": { "type": "string", "format": "date-time" }
      },
      "required": ["lat", "lng"]
    },
    "serviceTerritoryId": { "type": ["string", "null"], "format": "uuid" },
    "notes": { "type": ["string", "null"] },
    "accessInstructions": { "type": ["string", "null"] }
  },
  "required": ["id", "customerId", "label", "address"]
}
```

## 2.3 ServiceTerritory

Service territories group locations and technicians to minimize travel.

```
json{
  "$id": "ServiceTerritory",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "name": { "type": "string" },
    "description": { "type": ["string", "null"] },
    "polygon": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "lat": { "type": "number" },
          "lng": { "type": "number" }
        },
        "required": ["lat", "lng"]
      }
    },
    "timezone": { "type": "string" },
    "defaultBusinessHours": {
      "type": "object",
      "properties": {
        "mon": { "type": "array", "items": { "type": "string" } },
        "tue": { "type": "array", "items": { "type": "string" } },
        "wed": { "type": "array", "items": { "type": "string" } },
        "thu": { "type": "array", "items": { "type": "string" } },
        "fri": { "type": "array", "items": { "type": "string" } },
        "sat": { "type": "array", "items": { "type": "string" } },
        "sun": { "type": "array", "items": { "type": "string" } }
      }
    },
    "active": { "type": "boolean", "default": true }
  },
  "required": ["id", "name", "timezone"]
}
```

## 2.4 Technician

```
json{
  "$id": "Technician",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "userId": { "type": "string", "format": "uuid" },
    "name": { "type": "string" },
    "phone": { "type": "string" },
    "email": { "type": ["string", "null"], "format": "email" },
    "homeBase": {
      "type": "object",
      "properties": {
        "lat": { "type": "number" },
        "lng": { "type": "number" }
      },
      "required": ["lat", "lng"]
    },
    "primaryTerritoryId": { "type": ["string", "null"], "format": "uuid" },
    "territoryIds": {
      "type": "array",
      "items": { "type": "string", "format": "uuid" }
    },
    "skills": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "code": { "type": "string" },
          "level": { "type": "integer", "minimum": 1, "maximum": 5 }
        },
        "required": ["code", "level"]
      }
    },
    "maxDailyHours": { "type": "number", "default": 8 },
    "active": { "type": "boolean", "default": true }
  },
  "required": ["id", "name", "phone", "homeBase"]
}
```

## 2.5 TechnicianAvailability

Availability captures working shifts, time off, and exceptions.

```
json{
  "$id": "TechnicianAvailability",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "technicianId": { "type": "string", "format": "uuid" },
    "type": { "type": "string", "enum": ["work", "pto", "break", "blocked"] },
    "start": { "type": "string", "format": "date-time" },
    "end": { "type": "string", "format": "date-time" },
    "recurrenceRule": { "type": ["string", "null"] },
    "reason": { "type": ["string", "null"] }
  },
  "required": ["id", "technicianId", "type", "start", "end"]
}
```

## 2.6 Job

```
json{
  "$id": "Job",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "jobNumber": { "type": "string" },
    "customerId": { "type": "string", "format": "uuid" },
    "serviceLocationId": { "type": "string", "format": "uuid" },
    "problemDescription": { "type": "string" },
    "jobType": { "type": "string", "enum": ["repair", "install", "maintenance", "inspection", "other"] },
    "requiredSkills": {
      "type": "array",
      "items": { "type": "string" }
    },
    "estimatedDurationMinutes": { "type": "integer" },
    "priority": { "type": "string", "enum": ["low", "normal", "high", "emergency"], "default": "normal" },
    "slaDueAt": { "type": ["string", "null"], "format": "date-time" },
    "status": {
      "type": "string",
      "enum": ["new", "scheduled", "in_progress", "on_hold", "completed", "canceled"]
    },
    "source": {
      "type": "string",
      "enum": ["phone", "web_form", "email", "repeat", "other"],
      "default": "phone"
    },
    "createdAt": { "type": "string", "format": "date-time" },
    "updatedAt": { "type": "string", "format": "date-time" },
    "notesInternal": { "type": ["string", "null"] },
    "notesCustomerVisible": { "type": ["string", "null"] }
  },
  "required": ["id", "jobNumber", "customerId", "serviceLocationId", "problemDescription", "jobType", "estimatedDurationMinutes", "status", "createdAt"]
}
```

## 2.7 Appointment

An appointment is the scheduled execution of a job (or subset of work) with optional technician assignment.

```
json{
  "$id": "Appointment",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "jobId": { "type": "string", "format": "uuid" },
    "serviceLocationId": { "type": "string", "format": "uuid" },
    "technicianId": { "type": ["string", "null"], "format": "uuid" },
    "scheduledStart": { "type": "string", "format": "date-time" },
    "scheduledEnd": { "type": "string", "format": "date-time" },
    "timeWindowStart": { "type": "string", "format": "date-time" },
    "timeWindowEnd": { "type": "string", "format": "date-time" },
    "status": {
      "type": "string",
      "enum": ["unassigned", "assigned", "en_route", "on_site", "paused", "completed", "canceled"]
    },
    "sequenceInRoute": { "type": ["integer", "null"] },
    "visitNumber": { "type": "integer", "default": 1 },
    "notesDispatcher": { "type": ["string", "null"] },
    "googleCalendarEventId": { "type": ["string", "null"] },
    "notificationState": {
      "type": "object",
      "properties": {
        "bookingConfirmedAt": { "type": ["string", "null"], "format": "date-time" },
        "reminderSentAt": { "type": ["string", "null"], "format": "date-time" },
        "techOnTheWaySentAt": { "type": ["string", "null"], "format": "date-time" }
      }
    }
  },
  "required": ["id", "jobId", "serviceLocationId", "scheduledStart", "scheduledEnd", "timeWindowStart", "timeWindowEnd", "status"]
}
```

## 2.8 Route & RouteStop

```
json{
  "$id": "DailyRoute",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "technicianId": { "type": "string", "format": "uuid" },
    "date": { "type": "string", "format": "date" },
    "stops": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "appointmentId": { "type": "string", "format": "uuid" },
          "sequence": { "type": "integer" },
          "plannedArrival": { "type": "string", "format": "date-time" },
          "plannedDeparture": { "type": "string", "format": "date-time" },
          "travelMinutesFromPrevious": { "type": "integer" }
        },
        "required": ["appointmentId", "sequence"]
      }
    },
    "totalTravelMinutes": { "type": "integer", "default": 0 },
    "totalJobMinutes": { "type": "integer", "default": 0 }
  },
  "required": ["id", "technicianId", "date"]
}
```

## 2.9 Notification

```
json{
  "$id": "Notification",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "type": { "type": "string", "enum": ["booking_confirmation", "reminder", "on_the_way", "completion_summary"] },
    "channel": { "type": "string", "enum": ["sms", "email", "push"] },
    "recipient": { "type": "string" },
    "payload": { "type": "object" },
    "status": { "type": "string", "enum": ["queued", "sent", "failed"] },
    "errorMessage": { "type": ["string", "null"] },
    "relatedAppointmentId": { "type": ["string", "null"], "format": "uuid" },
    "relatedJobId": { "type": ["string", "null"], "format": "uuid" },
    "createdAt": { "type": "string", "format": "date-time" },
    "sentAt": { "type": ["string", "null"], "format": "date-time" }
  },
  "required": ["id", "type", "channel", "recipient", "status", "createdAt"]
}
```

## 2.10 CalendarSync (Google)

```
json{
  "$id": "CalendarSync",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "technicianId": { "type": "string", "format": "uuid" },
    "provider": { "type": "string", "enum": ["google"] },
    "calendarId": { "type": "string" },
    "googleAccountEmail": { "type": "string", "format": "email" },
    "accessToken": { "type": "string" },
    "refreshToken": { "type": "string" },
    "tokenExpiry": { "type": "string", "format": "date-time" },
    "syncDirection": { "type": "string", "enum": ["one_way_to_google", "one_way_from_google", "two_way"], "default": "one_way_to_google" },
    "lastSyncAt": { "type": ["string", "null"], "format": "date-time" }
  },
  "required": ["id", "technicianId", "provider", "calendarId", "accessToken", "refreshToken", "tokenExpiry", "syncDirection"]
}
```

------

## 3. Workflow States

## 3.1 Job Lifecycle States

- new: Job captured, not yet scheduled.
- scheduled: At least one appointment exists and is in assigned/unassigned status.
- in_progress: Technician has arrived on site for at least one appointment.
- on_hold: Work paused (e.g., waiting for parts, customer not home).
- completed: All required work done, paperwork finished, and job closed.
- canceled: Job canceled by customer or business.

State transitions:

- new → scheduled (appointment created).
- scheduled → in_progress (tech sets appointment to on_site).
- in_progress → completed (tech marks work complete).
- in_progress → on_hold (flag set; can return to in_progress).
- any non-final → canceled (with reason).

## 3.2 Appointment Lifecycle States

- unassigned: Time window chosen but no technician assigned.
- assigned: Technician and scheduled time set.
- en_route: Technician marked traveling to site.
- on_site: Technician checked in at location.
- paused: Work temporarily stopped during visit.
- completed: Visit finished.
- canceled: Appointment canceled (may or may not cancel the job).

Example transitions:

- unassigned → assigned (dispatch).
- assigned → en_route (tech tap in app).
- en_route → on_site (geofence or tech action).
- on_site → completed | paused.
- paused → on_site | completed.
- any → canceled (with reason).

------

## 4. Scheduling Logic

Scheduling logic must respect availability, skills, territories, travel time, and job priorities.

## 4.1 Constraints

Hard constraints:

- TechnicianAvailability type=work must cover scheduledStart–scheduledEnd.
- No overlapping appointments for a technician.
- RequiredSkills ⊆ technician.skills (respecting minimum level).
- ServiceLocation within technician’s territoryIds or temporary override.
- MaxDailyHours not exceeded.

Soft constraints:

- Minimize travel time between consecutive appointments.
- Respect customer time window preferences.
- Respect technician preferences (home base proximity, start/end near home).
- Balance workload across technicians.

## 4.2 Conflict Detection

When placing or updating an appointment for technician T:

1. Fetch all existing appointments for T on the appointment date.
2. Check overlapping intervals: if [start,end][*s**t**a**r**t*,*e**n**d*] intersects any existing scheduledStart–scheduledEnd, flag conflict.
3. Verify that appointment window lies inside a work availability segment and not inside pto/blocked segments.
4. Validate requiredSkills vs technician.skills.
5. Ensure travel buffer: previousStop.plannedDeparture + travelMinutes ≤ newAppointment.scheduledStart.

Conflict resolution strategies:

- Suggest nearest free slot in same day.
- Suggest different technician in same territory with skills.
- Shorten appointment if estimatedDurationMinutes > scheduled slot (ask dispatcher to confirm).

## 4.3 Priority Queueing

Maintain a scheduling queue for unscheduled or rescheduling-required jobs.

Job priority score (higher = more urgent):

- Base on job.priority enum (emergency > high > normal > low).
- Increase score as slaDueAt approaches or is breached.
- Optionally add customer tier or revenue weight.

Implementation sketch:

- Store queued jobs in a table or in-memory queue with computed score and insertion time.
- Periodically (or on demand) run an assignment algorithm over top N jobs.
- For each job, evaluate candidate technicians and timeslots, rank by score (see 6.3), and assign the best feasible slot.

------

## 5. Dispatch Workflow

This covers the flow from inbound customer request through job completion.

## 5.1 From Call to Job Creation

1. Dispatcher answers phone or receives online request.
2. Search existing Customer by phone/email, or create new Customer.
3. Confirm ServiceLocation or create new; geocode and assign territory.
4. Capture problemDescription, jobType, estimatedDurationMinutes, and priority.
5. Create Job with status=new and associate customer/location.

## 5.2 Appointment Booking Flow

For a small team UI, provide:

- “Quick schedule”: dispatcher selects a date, time window, and optionally a specific technician.
- “Smart schedule”: system suggests best slot based on constraints (section 6).

Process:

1. Dispatcher chooses desired day and time window.
2. System filters technicians by territory, skills, and base availability.
3. System calculates travel time impact if inserted into existing routes.
4. UI shows a ranked list of technicians and slots; dispatcher selects one.
5. Appointment is created (status=assigned or unassigned), Job moves to scheduled, notifications queued.

## 5.3 Day-of-Dispatch

- Dispatcher dashboard: list of today’s appointments grouped by technician and status.
- Ability to drag/drop appointments between technicians and timeslots with real-time conflict checks.
- Emergency job handling:
  - Insert into nearest feasible gap for technician in same territory.
  - Or re-optimize affected technician’s remaining route.

## 5.4 Technician Mobile Workflow

On technician app (iOS/Android/Web):

- View today’s route with ordered stops, map view.
- For each appointment:
  - Status transitions: assigned → en_route → on_site → completed.
  - Capture photos, notes, used parts, customer signature.
- Offline-first: cache today’s jobs, queue updates and sync when online.

Completion:

- When appointment set to completed, update Job status; if multi-visit, complete job when last appointment done.

------

## 6. AI-Based Schedule Optimization

AI features should be additive to a deterministic rules engine and focused on skills and location.

## 6.1 Optimization Objectives

- Minimize total technician travel time.
- Maximize on-time arrival within customer windows and SLAs.
- Maximize skill–job fit and first-time fix probability.
- Balance workload among technicians to avoid burnout.

## 6.2 Inputs

For a planning horizon (e.g., 1 day):

- Jobs: locations (lat/lng), requiredSkills, estimatedDurationMinutes, time windows, priority.
- Technicians: homeBase, skills, availability, maxDailyHours.
- ServiceTerritories: constraints for which techs cover which areas.
- Travel matrix: estimated travel times between locations via mapping API.

## 6.3 Scoring Function

For assigning job J to technician T at position k in route:

- Score = w1 * skill_fit + w2 * travel_delta + w3 * priority_factor + w4 * sla_factor + w5 * workload_balance.
- skill_fit: 1.0 if all requiredSkills met with level ≥ threshold, else penalty.
- travel_delta: negative of additional travel minutes if inserted.
- priority_factor: higher for emergency and near-SLA jobs.
- sla_factor: penalty if arrival time would break time window or SLA.
- workload_balance: penalty if T’s load significantly above team average.

Heuristic algorithm (good for 1–10 techs):

- Greedy insertion:
  - Sort jobs by priority score.
  - For each job, enumerate technicians and possible insertion positions, compute score, choose best feasible.
- Optional local search:
  - Apply 2-opt or swap operations between routes to further reduce travel.

## 6.4 AI Enhancements

- Predict job duration using past jobs of same type and technician.
- Suggest best technician based on historical first-time fix rate for similar jobs.
- Real-time re-optimization when:
  - Job canceled, a tech calls in sick, or a job overruns.
- Explainability: show dispatcher “why” a suggestion was made (shorter drive, better skill fit, earlier SLA).

------

## 7. Google Calendar API Integration

Integration lets small teams see their work in Google Calendar and optionally block off personal events.

## 7.1 Authentication & Setup

- Use OAuth 2.0 with offline access to obtain accessToken and refreshToken.
- Store tokens in CalendarSync records, encrypted at rest.
- Let technicians choose a target calendar (primary or a dedicated “Field Jobs” calendar).

## 7.2 Core Operations

For syncDirection=one_way_to_google:

- On appointment create/update/delete:
  - Create/update/delete a Google Calendar event.
- Event mapping:
  - summary: “Job #1234 – Water heater repair”.
  - description: customer name, address, contact, problemDescription.
  - start/end: scheduledStart/End with correct timezone.
  - location: service address string.
  - attendees: optional technician email, customer email.
- Persist googleCalendarEventId on Appointment.

For reading technician busy slots (optional):

- Use freeBusy endpoint to fetch busy ranges within planning horizon.
- Convert busy ranges to TechnicianAvailability type=blocked (not persisted or stored as external-sourced blocks).

## 7.3 Webhooks & Sync

- Use Google Calendar push notifications (webhooks) to detect external changes.
- When an event with matching googleCalendarEventId is moved or canceled:
  - Update local Appointment or mark as “externally_modified” requiring dispatcher review.
- Rate limits:
  - Batch event operations when mass-rescheduling.

Security and permissions:

- Separate OAuth consent per-user; no cross-account access.
- Allow disconnecting sync and revoking tokens.

------

## 8. Customer Notification Workflows

Timely notifications improve show rates and satisfaction.

## 8.1 Triggers

Notifications are driven by appointment status and timing:

- Booking confirmation:
  - Trigger: appointment created with status=assigned.
- Reminder:
  - Trigger: scheduledStart - reminderLeadTime (e.g., 24 hours) via background job.
- On-the-way:
  - Trigger: tech sets status=en_route or enters geo-fence radius.
- Completion summary:
  - Trigger: appointment status → completed.

## 8.2 Channels & Templates

- SMS: primary for quick updates.
- Email: detailed confirmations and summaries.
- Push: optional for customers using your portal/app.

Template fields:

- Customer name, Company name.
- Job number, date, time window.
- Technician name and photo (if available).
- Links to tracking page (for on-the-way) and feedback form.

Example payload structure:

```
json{
  "type": "booking_confirmation",
  "channel": "sms",
  "recipient": "+16085551234",
  "payload": {
    "customerName": "John",
    "jobNumber": "1234",
    "date": "2026-02-18",
    "timeWindow": "9–11am",
    "technicianName": "Alex"
  }
}
```

Retry and failure handling:

- Exponential backoff for transient errors, cap at N attempts.
- Mark Notification.status=failed with errorMessage for operator visibility.

------

## 9. Mobile Data Access Patterns for Field Techs

Field techs need fast, offline-capable access to schedule and job data.

## 9.1 Data Model for Mobile Sync

Per technician, per day:

- Today’s route (DailyRoute + stops).
- All referenced Appointments, Jobs, Customers, ServiceLocations.
- Necessary configuration (territories, skills, status enums).

Recommended payload:

```
json{
  "route": { /* DailyRoute */ },
  "appointments": [ /* Appointment[] */ ],
  "jobs": [ /* Job[] */ ],
  "customers": [ /* Customer[] */ ],
  "locations": [ /* ServiceLocation[] */ ],
  "serverTime": "2026-02-18T09:00:00Z"
}
```

## 9.2 Sync Strategy

- Initial sync:
  - On login or at start-of-day, download route and jobs for today (+1 day).
- Incremental sync:
  - Poll every N minutes or use push to deliver changes (new jobs, schedule changes).
- Offline handling:
  - Store data in local DB (SQLite/Room/CoreData).
  - Queue actions (status changes, notes, photos) with timestamps and resolve conflicts on server side (server wins for schedule, client wins for visit artifacts).

## 9.3 Mobile Permissions & Visibility

- A tech sees only:
  - Their assigned Appointments and related Jobs.
  - Unassigned jobs only if that’s a business rule (e.g., self-claim).
- Dispatcher can force refresh of a tech’s schedule when doing late changes.

------

## 10. API Surface (High-Level)

This section sketches core APIs; you can formalize as REST/GraphQL.

## 10.1 Dispatcher-Facing

- POST /jobs
- POST /jobs/{id}/appointments
- POST /appointments/{id}/assign
- POST /appointments/{id}/reschedule
- GET /schedule?date=YYYY-MM-DD
- POST /schedule/optimize (trigger AI run for given day or date range)

## 10.2 Technician-Facing

- GET /me/route?date=YYYY-MM-DD
- POST /appointments/{id}/status (en_route, on_site, completed)
- POST /appointments/{id}/notes
- POST /appointments/{id}/artifacts (photos, signatures)

## 10.3 Integration & Notifications

- POST /webhooks/google-calendar
- POST /notifications/test
- Webhook endpoints for SMS and email providers (delivery receipts).

------

## 11. Non-Functional Requirements (Brief)

- Performance:
  - Optimizer should handle up to 10 technicians and 100 jobs/day within a few seconds.
- Reliability:
  - Idempotent scheduling APIs to avoid duplicates during retries.
- Security:
  - RBAC: dispatcher, technician, admin roles.
  - Encrypt OAuth tokens and PII at rest.
- Auditability:
  - Track who scheduled or changed each appointment and when.