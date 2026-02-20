## 1. Core Concepts and Scope

For small service businesses and light manufacturers, a **work order** (WO) is the structured record of a job to be performed, including who does it, where, when, how long it takes, what materials are consumed, and what should be billed.

The module’s responsibilities:

- Capture all job details, status, and history.
- Track labor time against jobs and compute labor cost.
- Track material consumption from inventory and push inventory transactions.
- Feed invoicing/estimates with structured billable items.
- Support mobile entry for technicians/operators in the field or on the shop floor.
- Provide AI assist for creating work orders from plain language and generating post‑completion reports.

------

## 2. Data Model Overview

Key entities:

- WorkOrder
- WorkOrderTask (optional granular steps/checklists)
- WorkOrderAssignment (who is assigned)
- WorkOrderTimeEntry (labor/time tracking)
- WorkOrderMaterialUsage (material consumption)
- WorkOrderAttachment (photos/docs)
- WorkOrderNote (free‑form notes / internal vs external)
- WorkOrderStatusHistory
- WorkOrderInvoiceLink
- Integration references (to Customer, ServiceLocation, Project, Inventory items, Invoice)

This module relies on existing CRM (Customer, Contact), Scheduling (Appointment), Inventory (Part/SKU, InventoryTransaction), BOM (where jobs may be tied to assemblies), and Invoicing (Estimate/Invoice) modules.

------

## 3. JSON Schemas

Below are representative JSON schemas (OpenAPI‑style), which you can convert to DB DDL.

## 3.1 WorkOrder

```
json{
  "$id": "WorkOrder",
  "type": "object",
  "required": ["id", "organization_id", "status", "customer_id", "created_at"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "organization_id": { "type": "string", "format": "uuid" },

    "external_number": { "type": "string" }, 
    "human_readable_number": { "type": "string" }, 

    "title": { "type": "string", "maxLength": 200 },
    "description": { "type": "string" },

    "customer_id": { "type": "string", "format": "uuid" },
    "service_location_id": { "type": "string", "format": "uuid", "nullable": true },
    "project_id": { "type": "string", "format": "uuid", "nullable": true },
    "asset_id": { "type": "string", "format": "uuid", "nullable": true },

    "priority": {
      "type": "string",
      "enum": ["low", "normal", "high", "emergency"],
      "default": "normal"
    },

    "status": {
      "type": "string",
      "enum": [
        "draft",
        "scheduled",
        "dispatched",
        "in_progress",
        "on_hold",
        "completed",
        "ready_for_invoicing",
        "invoiced",
        "closed",
        "cancelled"
      ]
    },

    "requested_start_at": { "type": "string", "format": "date-time", "nullable": true },
    "requested_end_at": { "type": "string", "format": "date-time", "nullable": true },
    "scheduled_start_at": { "type": "string", "format": "date-time", "nullable": true },
    "scheduled_end_at": { "type": "string", "format": "date-time", "nullable": true },

    "estimated_labor_hours": { "type": "number", "minimum": 0 },
    "estimated_material_cost": { "type": "number", "minimum": 0 },
    "estimated_total_amount": { "type": "number", "minimum": 0 },

    "actual_labor_hours": { "type": "number", "minimum": 0 },
    "actual_material_cost": { "type": "number", "minimum": 0 },
    "actual_total_cost": { "type": "number", "minimum": 0 },

    "billable": { "type": "boolean", "default": true },
    "billing_type": {
      "type": "string",
      "enum": ["time_and_materials", "fixed_price", "no_charge"],
      "default": "time_and_materials"
    },

    "source_type": {
      "type": "string",
      "enum": ["manual", "recurring", "estimate", "project", "integration"],
      "default": "manual"
    },
    "source_reference_id": { "type": "string", "nullable": true },

    "tags": {
      "type": "array",
      "items": { "type": "string" }
    },

    "customer_visible_summary": { "type": "string" },
    "internal_notes": { "type": "string" },

    "completion_notes": { "type": "string" },
    "completed_at": { "type": "string", "format": "date-time", "nullable": true },
    "closed_at": { "type": "string", "format": "date-time", "nullable": true },

    "created_by_user_id": { "type": "string", "format": "uuid" },
    "updated_by_user_id": { "type": "string", "format": "uuid", "nullable": true },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time", "nullable": true }
  }
}
```

## 3.2 WorkOrderTask

```
json{
  "$id": "WorkOrderTask",
  "type": "object",
  "required": ["id", "work_order_id", "title", "sort_index"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "work_order_id": { "type": "string", "format": "uuid" },
    "title": { "type": "string", "maxLength": 200 },
    "description": { "type": "string" },
    "sort_index": { "type": "integer", "minimum": 0 },

    "required": { "type": "boolean", "default": false },
    "status": {
      "type": "string",
      "enum": ["not_started", "in_progress", "blocked", "done"],
      "default": "not_started"
    },

    "estimated_minutes": { "type": "integer", "minimum": 0 },
    "actual_minutes": { "type": "integer", "minimum": 0 },

    "completed_by_user_id": { "type": "string", "format": "uuid", "nullable": true },
    "completed_at": { "type": "string", "format": "date-time", "nullable": true }
  }
}
```

## 3.3 WorkOrderAssignment

```
json{
  "$id": "WorkOrderAssignment",
  "type": "object",
  "required": ["id", "work_order_id", "user_id"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "work_order_id": { "type": "string", "format": "uuid" },
    "user_id": { "type": "string", "format": "uuid" },

    "role": {
      "type": "string",
      "enum": ["technician", "helper", "supervisor", "operator"],
      "default": "technician"
    },

    "planned_start_at": { "type": "string", "format": "date-time", "nullable": true },
    "planned_end_at": { "type": "string", "format": "date-time", "nullable": true },

    "actual_start_at": { "type": "string", "format": "date-time", "nullable": true },
    "actual_end_at": { "type": "string", "format": "date-time", "nullable": true },

    "hourly_cost_rate": { "type": "number", "minimum": 0 },
    "hourly_bill_rate": { "type": "number", "minimum": 0 }
  }
}
```

## 3.4 WorkOrderTimeEntry

```
json{
  "$id": "WorkOrderTimeEntry",
  "type": "object",
  "required": [
    "id",
    "work_order_id",
    "user_id",
    "clock_in_at",
    "minutes",
    "labor_cost"
  ],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "work_order_id": { "type": "string", "format": "uuid" },
    "work_order_task_id": { "type": "string", "format": "uuid", "nullable": true },
    "user_id": { "type": "string", "format": "uuid" },

    "clock_in_at": { "type": "string", "format": "date-time" },
    "clock_out_at": { "type": "string", "format": "date-time", "nullable": true },
    "minutes": { "type": "integer", "minimum": 0 },

    "time_entry_type": {
      "type": "string",
      "enum": ["regular", "overtime", "travel", "non_billable"],
      "default": "regular"
    },

    "labor_cost": { "type": "number", "minimum": 0 },
    "labor_bill_amount": { "type": "number", "minimum": 0 },

    "approved": { "type": "boolean", "default": false },
    "approved_by_user_id": { "type": "string", "format": "uuid", "nullable": true },
    "approved_at": { "type": "string", "format": "date-time", "nullable": true }
  }
}
```

## 3.5 WorkOrderMaterialUsage

```
json{
  "$id": "WorkOrderMaterialUsage",
  "type": "object",
  "required": [
    "id",
    "work_order_id",
    "inventory_item_id",
    "quantity",
    "unit_cost"
  ],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "work_order_id": { "type": "string", "format": "uuid" },
    "work_order_task_id": { "type": "string", "format": "uuid", "nullable": true },

    "inventory_item_id": { "type": "string", "format": "uuid" },
    "location_id": { "type": "string", "format": "uuid", "nullable": true },

    "quantity": { "type": "number" },
    "unit_of_measure": { "type": "string" },

    "unit_cost": { "type": "number", "minimum": 0 },
    "extended_cost": { "type": "number", "minimum": 0 },
    "unit_price": { "type": "number", "minimum": 0 },
    "extended_price": { "type": "number", "minimum": 0 },

    "inventory_transaction_id": { "type": "string", "format": "uuid", "nullable": true },

    "billable": { "type": "boolean", "default": true },
    "notes": { "type": "string" }
  }
}
```

## 3.6 WorkOrderStatusHistory

```
json{
  "$id": "WorkOrderStatusHistory",
  "type": "object",
  "required": ["id", "work_order_id", "from_status", "to_status", "changed_at"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "work_order_id": { "type": "string", "format": "uuid" },

    "from_status": { "type": "string" },
    "to_status": { "type": "string" },

    "reason": { "type": "string" },
    "changed_by_user_id": { "type": "string", "format": "uuid" },
    "changed_at": { "type": "string", "format": "date-time" }
  }
}
```

## 3.7 WorkOrderInvoiceLink

```
json{
  "$id": "WorkOrderInvoiceLink",
  "type": "object",
  "required": ["id", "work_order_id", "invoice_id"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "work_order_id": { "type": "string", "format": "uuid" },
    "invoice_id": { "type": "string", "format": "uuid" },
    "integration_system": {
      "type": "string",
      "enum": ["internal", "quickbooks_online", "xero", "other"]
    },
    "integration_external_id": { "type": "string", "nullable": true }
  }
}
```

Attachments and notes can be shared patterns with other modules (simple blob references with metadata).

------

## 4. Work Order Lifecycle and State Machine

## 4.1 High‑Level Lifecycle

Typical lifecycle (adapted to small shop realities):

1. Created (often from estimate, recurring plan, or manual customer request).
2. Scheduled (linked to one or more appointments/assignments).
3. Dispatched (tech notified, accepted).
4. In Progress (tech on site / machine running).
5. On Hold (waiting on parts, customer, or another job).
6. Completed (work physically done, data captured).
7. Ready for Invoicing (office review, corrections).
8. Invoiced (invoice generated/synced).
9. Closed (no further edits; for reporting only).
10. Cancelled (never executed).

## 4.2 State Machine Definition

Allowed transitions (subset; you can encode as a table):

| From                | To                                | Notes                                   |
| :------------------ | :-------------------------------- | :-------------------------------------- |
| draft               | scheduled, cancelled              | Created but not yet planned.            |
| scheduled           | dispatched, cancelled             | Usually when assignment exists.         |
| dispatched          | in_progress, on_hold, cancelled   | Tech accepts, declines, or job delayed. |
| in_progress         | on_hold, completed, cancelled     | Time entries active.                    |
| on_hold             | scheduled, in_progress, cancelled | E.g., waiting on parts.                 |
| completed           | ready_for_invoicing, in_progress  | Allow reopen to fix data.               |
| ready_for_invoicing | invoiced, completed               | Review stage.                           |
| invoiced            | closed                            | Generally immutable operationally.      |
| cancelled           | closed                            | Optional.                               |

Validation rules:

- Cannot move to `invoiced` without at least one billable item (labor or material) unless `billing_type = "no_charge"`.
- Cannot move to `completed` unless all `required` WorkOrderTasks are `done` or overridden by supervisor.
- Time entries must be closed (clock_out_at set) before `completed` or `ready_for_invoicing`.

Implementation: store a finite state machine definition in code or configuration so you can reuse patterns across modules.

------

## 5. Time Tracking and Labor Cost Capture

## 5.1 Approaches to Time Capture

Support three patterns (configuration per org):

- Clock in/out per **day** and allocate to WOs via splits (good for small teams with paper‑like habits).
- Clock in/out per **work order** from mobile.
- Manual entry of duration (start/end or hours) per work order/time entry.

Fields already in `WorkOrderTimeEntry` support:

- Minutes and type (regular, overtime, travel).
- Cost and bill amounts (pre‑calculated at entry or by nightly job using current rates).
- Optional link to project cost codes or GL codes for integration with accounting/payroll.

## 5.2 Cost Calculation

Per time entry:

- `labor_cost = minutes / 60 * hourly_cost_rate`
- `labor_bill_amount = minutes / 60 * hourly_bill_rate` (if billable)

Per work order (rollup):

- Sum all approved time entries to compute `actual_labor_hours`, `actual_total_cost`, and billable total.

You can compute labor cost in your own system and optionally send summary totals to QBO as line items (e.g., “Labor – Technician A – 3.5 hours”), reusing item mappings from your invoicing module.

## 5.3 Approval Workflow

- Status per time entry: pending → approved → locked.
- Supervisors approve entries per work order or per technician/day.
- Once invoiced, time entries are locked or require supervisor override.

------

## 6. Inventory and Material Consumption Integration

## 6.1 Integration Points

Each `WorkOrderMaterialUsage` should map to:

- Inventory item (part/SKU) in your Inventory module.
- Optional location (warehouse, truck, technician van).
- Inventory transaction (issue) representing reduction in on‑hand quantity.

Pattern:

1. Technician selects items from a job‑specific pick list (from BOM, templated kit, or ad‑hoc search).
2. On save, create `WorkOrderMaterialUsage` rows and **post inventory transactions** of type `issue` from the selected location.
3. Update Inventory balances and trigger re‑order logic if needed.

## 6.2 Inventory Transaction Characteristics

InventoryTransaction fields (from your inventory module):

- transaction_type: `issue_to_work_order`
- work_order_id
- inventory_item_id
- location_id
- quantity
- unit_cost
- extended_cost
- reference (e.g., technician id, note)

Costing: rely on inventory module’s costing (average, FIFO) to determine unit_cost. Work order simply stores unit_cost at issue time for historical accuracy.

## 6.3 Handling Returns and Adjustments

- Returns: negative `WorkOrderMaterialUsage` and matching `inventory_transaction` of type `return_from_work_order`.
- Lost/damaged: type `adjustment_shrinkage` with work_order_id for traceability.

------

## 7. Invoicing and Billing Integration

## 7.1 Invoice Generation Workflow

Tie into your existing invoicing and QBO integration patterns.

1. Work order moves to `ready_for_invoicing` once:
   - Time entries approved.
   - Material usage reviewed.
   - Completion notes captured.
2. Office user creates invoice:
   - Create internal `Invoice` entity.
   - Map to QBO `Invoice` via existing integration.
3. Line item mapping:
   - Labor: roll up per technician or per labor type (e.g., “Labor – HVAC Tech – 3.5 hours”).
   - Materials: each `WorkOrderMaterialUsage` becomes a line item referencing inventory SKU or service item in QBO.
   - Fixed price: if `billing_type = "fixed_price"`, create single service line; optionally still track internal cost from time/material for margin analysis.
4. Link invoice and work order with `WorkOrderInvoiceLink` and mark WO as `invoiced`.

## 7.2 Data Mapping Considerations

- Customer: WorkOrder.customer_id ↔ QBO Customer Id; reused from CRM/QBO mapping.
- Tax: Use invoice module’s tax logic; WO holds no tax calculations.
- Partial invoicing:
  - Flag on WO: `allow_partial_invoicing`.
  - Each invoice link can store percentage of WO billed or specific line references.

------

## 8. Mobile Data Entry (Field/Shop Floor)

## 8.1 Core Mobile Scenarios

From mobile (iOS/Android or PWA), technicians/operators should:

- View today’s assigned work orders (list with status, time window).
- See full job details (customer/location, contact info, notes, tasks, checklists).
- Start/stop time tracking for a work order.
- Add/edit materials used:
  - Select from templates/BOM, scan barcode/QR, or search inventory.
- Capture photos and files (before/after, serial numbers, signatures).
- Update tasks/checklists, mark required tasks complete.
- Enter completion notes (internal and customer‑visible).
- Collect customer sign‑off (signature, name, optional rating).

## 8.2 Offline‑First Patterns

For small shops in the field:

- Cache assigned WOs for next 1–3 days with details.
- Queue time entries, material usage, and notes offline; sync when online.
- Use conflict resolution that prefers server version for status but merges additive data like notes and attachments.

## 8.3 UX Constraints

- Minimal typing: use pick lists, checkboxes, templates.
- Short forms: e.g., adding material is typically item + qty + location; advanced fields hidden by default.
- One‑tap status transitions: e.g., “Start Job” → sets `dispatched` → `in_progress` with time entry start.

------

## 9. AI Assistance

## 9.1 AI‑Assisted Work Order Creation

Use an AI service to parse plain‑language job descriptions into structured WOs.

Inputs:

- Free text from dispatcher or technician (email, phone summary, customer portal request).
- Optional historical data (customer’s last jobs, assets, typical services).

Outputs:

- Suggested `title`, `description`, `priority`, `billing_type`.
- Suggested `tasks` checklist (3–10 items).
- Suggested `estimated_labor_hours` and `materials` (from BOM templates and inventory catalog).

Workflow:

1. User pastes or types description (e.g., “Customer reports no cooling on 3rd floor unit, last serviced 2 years ago. Likely low refrigerant, filter dirty.”).
2. AI endpoint `/ai/workorders/suggest` returns draft WO + tasks + materials.
3. User reviews/edits; system saves as `draft` WO.

## 9.2 AI‑Generated Post‑Completion Reports

After WO is `completed` and time/material data is available, AI can generate:

- Internal summary: causes, actions, recommendations.
- Customer‑visible report: human‑readable explanation and work summary.

Inputs:

- WorkOrder, tasks, time entries, material usage, notes, attachments metadata.

Outputs:

- `customer_visible_summary` suitable for invoices.
- Internal `completion_notes` focused on future technicians.

Endpoint: `/ai/workorders/{id}/summarize`.

## 9.3 Guardrails and Data Scope

- Constrain AI context to a single organization’s data; no cross‑tenant leakage.
- Use templates/prompts aligned with your vertical (HVAC, fabrication, etc.).
- Allow user to regenerate summaries; store final text in standard fields.

------

## 10. Field and Attribute Definitions (Selected)

Below is a concise table for key WorkOrder fields.

| Field                    | Type     | Description                                   |
| :----------------------- | :------- | :-------------------------------------------- |
| id                       | UUID     | Primary key.                                  |
| organization_id          | UUID     | Tenant.                                       |
| human_readable_number    | String   | Short code like “WO‑1023”.                    |
| title                    | String   | Short job label.                              |
| description              | Text     | Detailed scope or issue description.          |
| customer_id              | UUID     | Links to CRM Customer.                        |
| service_location_id      | UUID     | Where work occurs.                            |
| asset_id                 | UUID     | Equipment/asset if applicable.                |
| priority                 | Enum     | low/normal/high/emergency; drives scheduling. |
| status                   | Enum     | Lifecycle state (see above).                  |
| requested_start_at       | DateTime | Customer preferred window.                    |
| scheduled_start_at       | DateTime | Dispatcher‑chosen start.                      |
| estimated_labor_hours    | Number   | For planning and quotes.                      |
| estimated_material_cost  | Number   | From template/BOM.                            |
| billable                 | Boolean  | Whether to bill external customer.            |
| billing_type             | Enum     | T&M, fixed price, no charge.                  |
| completion_notes         | Text     | Tech’s detailed completion narrative.         |
| customer_visible_summary | Text     | Polished summary for invoice.                 |
| completed_at             | DateTime | When work physically completed.               |
| closed_at                | DateTime | When WO administratively closed.              |

Extend similar tables for TimeEntry and MaterialUsage in your full spec.

------

## 11. Comparison Table: Work Orders vs Related Objects

To help you position this module in your suite:

| Concept              | Primary Purpose                          | Owned By Module        |
| :------------------- | :--------------------------------------- | :--------------------- |
| WorkOrder            | Operational execution record of a job.   | Work Orders module     |
| Project              | Multi‑job initiative with milestones.    | Project Management     |
| Appointment          | Time slot on calendar, may reference WO. | Scheduling & Dispatch  |
| Estimate             | Proposed scope/pricing before approval.  | Invoicing & Estimates  |
| Invoice              | Accounting document for billing.         | Invoicing (QBO‑synced) |
| InventoryTransaction | Changes in on‑hand stock.                | Inventory & Parts      |