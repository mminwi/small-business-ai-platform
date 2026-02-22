# Schema Index

This folder contains all JSON data schemas for the Small Business AI Platform.
Each schema is a template — fill in values for a specific business deployment.

---

## Canonical Terminology Rules

These rules exist to prevent AI agents from creating duplicate or conflicting records.

| Concept | Canonical term | Wrong words (do not use) |
|---|---|---|
| A business the company sells to | `company` | customer, client, account |
| An individual person | `contact` | customer, user, person |
| A sales package (estimate + proposal) | `opportunity` | estimate, quote, proposal, bid |
| A dispatched work event | `job` (schedule.json) | project, ticket, order |
| An execution record | `work_order` (work-order.json) | job, ticket, task |
| A set of billing rates | `rateset` | rate card, price list |

---

## ID Format Reference

| Prefix | Record type | Schema |
|---|---|---|
| `OPP-YYYY-NNN` | Opportunity / proposal package | opportunity.json |
| `INV-YYYY-NNN` | Invoice | invoice.json |
| `CO-NNN` | Company (B2B customer) | crm.json companies[] |
| `CON-NNN` | Contact (individual person) | crm.json contacts[] |
| `LEAD-NNN` | Inbound lead | crm.json leads[] |
| `INT-NNN` | CRM interaction log entry | crm.json interactions[] |
| `JOB-YYYY-NNN` | Scheduled job | schedule.json jobs[] |
| `APT-NNN` | Appointment (visit) | schedule.json appointments[] |
| `FW-NNN` | Field worker / technician | schedule.json field_workers[] |
| `WO-YYYY-NNN` | Work order | work-order.json work_orders[] |
| `TE-NNN` | Time entry | work-order.json time_entries[] |
| `MAT-NNN` | Material usage line | work-order.json material_usage[] |
| `SC-YYYY-NNN` | Service contract | service-contract.json service_contracts[] |
| `OCC-NNN` | Contract occurrence (scheduled visit) | service-contract.json contract_occurrences[] |
| `YYYY-STD` / `YYYY-GOV` | Rate set | ratesets.json ratesets[] |
| `PART-NNNN` | Inventory part | inventory.json parts[] |
| `LOC-NNN` | Storage location | inventory.json locations[] |
| `PO-YYYY-NNN` | Purchase order | inventory.json purchase_orders[] |
| `SUP-NNN` | Inventory supplier | inventory.json suppliers[] |
| `TXN-NNN` | Inventory transaction | inventory.json transactions[] |
| `ASSET-NNN` | Customer-owned equipment | asset.json assets[] |
| `ASH-NNN` | Asset service history entry | asset.json asset_service_history[] |
| `BK-YYYY-NNN` | Customer booking | booking.json customer_bookings[] |
| `SVC-NNN` | Bookable service offering | booking.json booking_services[] |
| `QM/QP/WI/QF-NNN` | Quality document | quality-record.json documents[] |
| `NCR-YYYY-NNN` | Nonconformance report | quality-record.json ncrs[] |
| `SPC-NNN` | Quality-approved supplier | quality-record.json suppliers[] |
| `PP-NNN` | Past performance entry | bd-content.json past_performance[] |
| `CONT-NNN` | BD content library item | bd-content.json content_library[] |

---

## Schema Purposes

| File | What it stores |
|---|---|
| **crm.json** | All people and companies the business deals with. Source of truth for contact data. Every other schema pulls names, phones, and addresses from here — never duplicates them. |
| **opportunity.json** | Full proposal package: scope, WBS, hour estimates, compliance flags, risks, and approval status. One record per pursuit. |
| **ratesets.json** | Billing rates by role and year. Referenced by opportunity.json and invoice.json. Never hardcode rates anywhere else. |
| **invoice.json** | One record per invoice generated. QuickBooks is the accounting source of truth; this record is for AI operational tracking. |
| **schedule.json** | Jobs, appointments, field workers, and availability. Drives dispatch and calendar sync. |
| **work-order.json** | What actually happened on a job: labor time entries and materials used. Feeds invoice generation. |
| **service-contract.json** | Recurring maintenance agreements. Manages visit schedules, renewals, and recurring billing. |
| **inventory.json** | Parts catalog, stock levels by location, transaction log, and purchase orders. |
| **asset.json** | Customer-owned equipment with full service history and condition tracking. |
| **booking.json** | Online / inbound customer booking: services offered, booking policy, and booking records. |
| **quality-record.json** | Document register, training records, NCRs/CAPAs, supplier qualification, and management reviews. |
| **bd-content.json** | BD content library, past performance, agency contacts, and content calendar. |

---

## Cross-Reference Map

Who links to whom. Follow these foreign keys to pull related data.

```
crm.json
  companies[CO-]  ←── opportunity.json (company_id)
                  ←── invoice.json (company_id)
                  ←── schedule.json jobs (customer_id → B2B)
                  ←── work-order.json (customer_id → B2B)
                  ←── service-contract.json (customer_id → B2B)
                  ←── asset.json (customer_id → B2B)
  contacts[CON-]  ←── opportunity.json (primary_contact_id)
                  ←── booking.json customer_bookings (customer.id)
                  ←── crm.json companies (primary_contact_id)
  leads[LEAD-]    ──→ opportunity.json (converted_opportunity_id)

opportunity.json [OPP-]
  ←── invoice.json (linked_estimate_id)
  ←── schedule.json jobs (crm_opportunity_id)
  ──→ ratesets.json (rateset_id)
  ──→ crm.json companies (company_id)
  ──→ crm.json contacts (primary_contact_id)

schedule.json
  jobs[JOB-]      ←── work-order.json (appointment_id → APT- → JOB-)
                  ←── service-contract.json occurrences (work_order_id → WO-, not JOB-)
                  ──→ invoice.json (linked_invoice_id)
  appointments[APT-] ──→ schedule.json jobs (job_id)
  field_workers[FW-] ←── booking.json (staff_id)
                       ←── service-contract.json occurrences (technician_ids)

work-order.json [WO-]
  ──→ schedule.json appointments (appointment_id)
  ──→ inventory.json parts (part_id, via material_usage)
  ──→ inventory.json transactions (inventory_transaction_id)
  ──→ invoice.json (linked_invoice_id)
  ←── asset.json service_history (work_order_id)
  ←── service-contract.json occurrences (work_order_id)

inventory.json
  suppliers[SUP-] ←── purchase_orders (supplier_id)
  parts[PART-]    ←── work-order.json material_usage (part_id)
                  ←── asset.json service_history parts_installed (part_id)
  locations[LOC-] ←── work-order.json material_usage (location_id)
                  ←── purchase_orders (ship_to_location_id)

service-contract.json [SC-]
  ──→ crm.json (customer_id)
  ──→ work-order.json (work_order_id, via occurrences)
  ←── asset.json (contract_ids)

booking.json [BK-]
  ──→ crm.json contacts (customer.id)
  ──→ schedule.json appointments (internal_appointment_id)
  ──→ schedule.json field_workers (staff_id)
  ──→ booking_services (service_id)

quality-record.json
  ncrs ──→ quality-record.json suppliers (linked_supplier_id)

bd-content.json
  past_performance ──→ opportunity.json (used_in: [OPP-...])
  content_library  ←── content_calendar (content_id)
```

---

## Key Rules for AI Agents

1. **Never duplicate contact data.** Names, phones, and addresses live in crm.json. All other schemas carry only the ID and pull the rest at runtime.

2. **Never hardcode rates.** Rates live in ratesets.json. Opportunity and invoice records carry a `rateset_id` reference only.

3. **QuickBooks is the accounting authority.** These schemas are the operational layer. QB sync fields (`qb_invoice_id`, `quickbooks_customer_id`, etc.) are populated by the invoicing module — never set manually.

4. **No client-facing action without human approval.** Invoice status must be `approved` before sending. Opportunity `qc_passed` must be `true` before proposal export.

5. **Never guess hours.** Opportunity estimates must reference a workflow template from `procedures/estimating/workflow-library.md`.

6. **`customer_id` resolution rule.** For business clients: `customer_id` links to crm.json `companies[CO-]`. For individual consumers with no company: links to `contacts[CON-]`.
