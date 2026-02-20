Below is a compact but complete specification you can expand into a 15–25 page design document. You can treat each numbered section as 2–4 pages in your internal documentation.

------

## 1. Core Data Model Overview

Design for a multi‑tenant SaaS used by 1–20 employee firms. Key entities:

- Organization (tenant)
- User (with roles: Owner, PM, Contracts, Finance, Subcontract Manager)
- Opportunity
- Prime Contract
- Task Order / Delivery Order
- CLIN / SLIN
- Period of Performance (PoP)
- Funding / Obligation
- Deliverable (incl. CDRLs)
- Invoice (SF1034, WAWF)
- Subcontract and Subcontract Line Item
- Modification / Option
- Document (stored files, extracted fields, AI metadata)

All entities carry:

- `id` (UUID)
- `org_id`
- `created_at`, `updated_at`
- `created_by`, `updated_by`
- `status` enum as appropriate

------

## 2. JSON Schemas (Representative)

You can split these into separate files per microservice (contracts, billing, subs, AI).

## 2.1 Organization and User

```
json{
  "$id": "Organization",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "name": { "type": "string" },
    "duns": { "type": "string" },
    "cage_code": { "type": "string" },
    "sam_uei": { "type": "string" },
    "address": { "type": "string" },
    "time_zone": { "type": "string" },
    "wawf_vendor_num": { "type": "string" },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  },
  "required": ["id", "name"]
}
json{
  "$id": "User",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "org_id": { "type": "string", "format": "uuid" },
    "email": { "type": "string", "format": "email" },
    "name": { "type": "string" },
    "role": {
      "type": "string",
      "enum": ["OWNER", "PM", "CONTRACTS", "FINANCE", "SUBK_MANAGER"]
    },
    "active": { "type": "boolean" }
  },
  "required": ["id", "org_id", "email", "role"]
}
```

------

## 2.2 Opportunity

```
json{
  "$id": "Opportunity",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "org_id": { "type": "string", "format": "uuid" },
    "source_system": { "type": "string", "enum": ["SAM", "GSA_EBUY", "OTHER"] },
    "external_id": { "type": "string" },
    "title": { "type": "string" },
    "agency": { "type": "string" },
    "office": { "type": "string" },
    "solicitation_number": { "type": "string" },
    "naics": { "type": "string" },
    "set_aside": { "type": "string" },
    "vehicle_type": {
      "type": "string",
      "enum": ["IDIQ", "GWAC", "BPA", "FIRM_FIXED_PRICE", "T_AND_M", "COST_PLUS", "OTHER"]
    },
    "status": {
      "type": "string",
      "enum": ["IDENTIFIED", "QUALIFIED", "BID_DECISION_YES", "BID_DECISION_NO", "SUBMITTED", "LOST", "AWARDED"]
    },
    "capture_manager_id": { "type": "string", "format": "uuid" },
    "proposal_due_date": { "type": "string", "format": "date" },
    "anticipated_award_date": { "type": "string", "format": "date" },
    "probability_of_win": { "type": "number", "minimum": 0, "maximum": 1 },
    "estimated_value": { "type": "number" },
    "notes": { "type": "string" }
  },
  "required": ["id", "org_id", "title", "status"]
}
```

------

## 2.3 Prime Contract

```
json{
  "$id": "Contract",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "org_id": { "type": "string", "format": "uuid" },
    "opportunity_id": { "type": "string", "format": "uuid" },
    "role": { "type": "string", "enum": ["PRIME", "SUBCONTRACT"] },
    "prime_contract_number": { "type": "string" },
    "prime_award_id": { "type": "string" },
    "title": { "type": "string" },
    "agency": { "type": "string" },
    "contracting_office": { "type": "string" },
    "contract_type": {
      "type": "string",
      "enum": ["FFP", "T_AND_M", "COST_PLUS", "IDIQ", "BPA", "OTHER"]
    },
    "idiq_ceiling_value": { "type": "number" },
    "total_funded_value": { "type": "number" },
    "total_contract_value": { "type": "number" },
    "award_date": { "type": "string", "format": "date" },
    "base_pop_start": { "type": "string", "format": "date" },
    "base_pop_end": { "type": "string", "format": "date" },
    "number_of_options": { "type": "integer" },
    "current_status": {
      "type": "string",
      "enum": ["PRE_AWARD", "ACTIVE", "SUSPENDED", "EXPIRED", "CLOSED"]
    },
    "prime_poc_name": { "type": "string" },
    "prime_poc_email": { "type": "string", "format": "email" },
    "ko_name": { "type": "string" },
    "ko_email": { "type": "string", "format": "email" },
    "cor_name": { "type": "string" },
    "cor_email": { "type": "string", "format": "email" },
    "wawf_required": { "type": "boolean" },
    "wawf_instructions": { "type": "string" },
    "sf1034_required": { "type": "boolean" },
    "payment_terms_days": { "type": "integer" },
    "billing_frequency": {
      "type": "string",
      "enum": ["MONTHLY", "BIWEEKLY", "MILESTONE", "ON_DELIVERY"]
    }
  },
  "required": ["id", "org_id", "title", "current_status"]
}
```

------

## 2.4 Task Orders / Delivery Orders

```
json{
  "$id": "TaskOrder",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "order_number": { "type": "string" },
    "title": { "type": "string" },
    "award_date": { "type": "string", "format": "date" },
    "pop_start": { "type": "string", "format": "date" },
    "pop_end": { "type": "string", "format": "date" },
    "ceiling_value": { "type": "number" },
    "funded_value": { "type": "number" },
    "status": {
      "type": "string",
      "enum": ["PLANNED", "ACTIVE", "EXPIRED", "CLOSED"]
    }
  },
  "required": ["id", "contract_id", "order_number", "status"]
}
```

------

## 2.5 CLINs and SLINs

CLINs are the core structure tying deliverables, funding, and billing; each CLIN identifies a deliverable or service and negotiated price.

```
json{
  "$id": "Clin",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "task_order_id": { "type": ["string", "null"], "format": "uuid" },
    "clin_number": { "type": "string" },
    "parent_clin_id": { "type": ["string", "null"], "format": "uuid" },
    "description": { "type": "string" },
    "clin_type": {
      "type": "string",
      "enum": ["PRODUCT", "SERVICE", "TRAVEL", "DATA", "OTHER"]
    },
    "pricing_type": {
      "type": "string",
      "enum": ["FFP", "T_AND_M", "CPFF", "CPIF", "LABOR_HOUR", "OTHER"]
    },
    "unit": { "type": "string" },
    "unit_price": { "type": "number" },
    "quantity": { "type": "number" },
    "ceiling_amount": { "type": "number" },
    "funded_amount": { "type": "number" },
    "pop_start": { "type": "string", "format": "date" },
    "pop_end": { "type": "string", "format": "date" },
    "is_option": { "type": "boolean" },
    "status": {
      "type": "string",
      "enum": ["PLANNED", "ACTIVE", "EXERCISED", "EXPIRED", "CLOSED"]
    }
  },
  "required": ["id", "contract_id", "clin_number", "pricing_type"]
}
```

------

## 2.6 Periods of Performance

```
json{
  "$id": "PeriodOfPerformance",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "related_clin_id": { "type": ["string", "null"], "format": "uuid" },
    "related_task_order_id": { "type": ["string", "null"], "format": "uuid" },
    "label": { "type": "string" },
    "type": {
      "type": "string",
      "enum": ["BASE", "OPTION", "STOP_WORK", "MODIFIED"]
    },
    "start_date": { "type": "string", "format": "date" },
    "end_date": { "type": "string", "format": "date" },
    "status": {
      "type": "string",
      "enum": ["PLANNED", "ACTIVE", "EXPIRED"]
    },
    "modification_id": { "type": ["string", "null"], "format": "uuid" }
  },
  "required": ["id", "contract_id", "label", "start_date", "end_date"]
}
```

------

## 2.7 Funding / Obligations

```
json{
  "$id": "Funding",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "task_order_id": { "type": ["string", "null"], "format": "uuid" },
    "clin_id": { "type": ["string", "null"], "format": "uuid" },
    "funding_document_number": { "type": "string" },
    "appropriation": { "type": "string" },
    "fiscal_year": { "type": "string" },
    "obligated_amount": { "type": "number" },
    "deobligated_amount": { "type": "number" },
    "obligation_date": { "type": "string", "format": "date" },
    "modification_id": { "type": ["string", "null"], "format": "uuid" }
  },
  "required": ["id", "contract_id", "obligated_amount", "obligation_date"]
}
```

------

## 2.8 Deliverables and Reporting Requirements

Contracts often define data deliverables via a Contract Data Requirements List, with associated CLINs and due dates.

```
json{
  "$id": "Deliverable",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "task_order_id": { "type": ["string", "null"], "format": "uuid" },
    "clin_id": { "type": ["string", "null"], "format": "uuid" },
    "cdrl_number": { "type": "string" },
    "title": { "type": "string" },
    "description": { "type": "string" },
    "type": {
      "type": "string",
      "enum": ["REPORT", "DATA", "HARDWARE", "SOFTWARE", "OTHER"]
    },
    "recurrence": {
      "type": "string",
      "enum": ["ONE_TIME", "WEEKLY", "MONTHLY", "QUARTERLY", "ANNUAL", "EVENT_DRIVEN"]
    },
    "first_due_date": { "type": "string", "format": "date" },
    "lead_time_days": { "type": "integer" },
    "submission_method": {
      "type": "string",
      "enum": ["EMAIL", "PORTAL", "WAWF", "OTHER"]
    },
    "required_reviewer": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["PLANNED", "IN_PROGRESS", "SUBMITTED", "ACCEPTED", "REJECTED", "WAIVED"]
    },
    "last_submission_id": { "type": ["string", "null"], "format": "uuid" }
  },
  "required": ["id", "contract_id", "title", "recurrence"]
}
```

Concrete instances in a calendar are separate:

```
json{
  "$id": "DeliverableInstance",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "deliverable_id": { "type": "string", "format": "uuid" },
    "due_date": { "type": "string", "format": "date" },
    "status": {
      "type": "string",
      "enum": ["PLANNED", "IN_PROGRESS", "SUBMITTED", "ACCEPTED", "REJECTED", "LATE", "WAIVED"]
    },
    "submitted_date": { "type": ["string", "null"], "format": "date-time" },
    "submission_link": { "type": ["string", "null"] },
    "internal_owner_id": { "type": "string", "format": "uuid" }
  },
  "required": ["id", "deliverable_id", "due_date", "status"]
}
```

------

## 2.9 Invoicing (SF1034 / WAWF)

SF1034 is the standard public voucher used to request payment for purchases and services other than personal, capturing department, contract number, payee, and cost breakdown.
WAWF (now part of DoD’s E-Business Suite) is a secure web system to submit invoices and receiving reports electronically and is mandatory for most DoD contracts.

```
json{
  "$id": "Invoice",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "task_order_id": { "type": ["string", "null"], "format": "uuid" },
    "invoice_number": { "type": "string" },
    "invoice_date": { "type": "string", "format": "date" },
    "billing_period_start": { "type": "string", "format": "date" },
    "billing_period_end": { "type": "string", "format": "date" },
    "invoice_type": {
      "type": "string",
      "enum": ["SF1034", "WAWF_COMBO", "WAWF_2IN1", "WAWF_COST_VOUCHER", "WAWF_PROGRESS", "OTHER"]
    },
    "total_amount": { "type": "number" },
    "status": {
      "type": "string",
      "enum": ["DRAFT", "READY_FOR_REVIEW", "SUBMITTED", "ACCEPTED", "REJECTED", "PAID", "VOID"]
    },
    "external_reference": { "type": "string" },
    "sf1034_fields": {
      "type": "object",
      "properties": {
        "department": { "type": "string" },
        "bureau": { "type": "string" },
        "voucher_number": { "type": "string" },
        "schedule_number": { "type": "string" },
        "contract_number": { "type": "string" },
        "payee_name": { "type": "string" },
        "payee_address": { "type": "string" },
        "discount_terms": { "type": "string" }
      }
    },
    "wawf_document_type": { "type": "string" },
    "wawf_routing_info": {
      "type": "object",
      "properties": {
        "cage_code": { "type": "string" },
        "pay_office_do_daac": { "type": "string" },
        "acceptor_do_daac": { "type": "string" },
        "issue_by_do_daac": { "type": "string" }
      }
    }
  },
  "required": ["id", "contract_id", "invoice_number", "invoice_type", "status"]
}
```

Line items:

```
json{
  "$id": "InvoiceLine",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "invoice_id": { "type": "string", "format": "uuid" },
    "clin_id": { "type": "string", "format": "uuid" },
    "description": { "type": "string" },
    "quantity": { "type": "number" },
    "unit": { "type": "string" },
    "unit_price": { "type": "number" },
    "amount": { "type": "number" }
  },
  "required": ["id", "invoice_id", "clin_id", "amount"]
}
```

------

## 2.10 Subcontract Management

```
json{
  "$id": "Subcontract",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "prime_contract_id": { "type": "string", "format": "uuid" },
    "subcontract_number": { "type": "string" },
    "subcontractor_name": { "type": "string" },
    "sub_duns": { "type": "string" },
    "sub_cage_code": { "type": "string" },
    "effective_date": { "type": "string", "format": "date" },
    "pop_start": { "type": "string", "format": "date" },
    "pop_end": { "type": "string", "format": "date" },
    "ceiling_value": { "type": "number" },
    "funded_value": { "type": "number" },
    "flowdowns": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["PLANNED", "ACTIVE", "SUSPENDED", "CLOSED"]
    }
  },
  "required": ["id", "prime_contract_id", "subcontract_number", "status"]
}
json{
  "$id": "SubcontractLineItem",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "subcontract_id": { "type": "string", "format": "uuid" },
    "prime_clin_id": { "type": ["string", "null"], "format": "uuid" },
    "line_number": { "type": "string" },
    "description": { "type": "string" },
    "unit": { "type": "string" },
    "unit_price": { "type": "number" },
    "quantity": { "type": "number" },
    "ceiling_amount": { "type": "number" },
    "funded_amount": { "type": "number" }
  },
  "required": ["id", "subcontract_id", "line_number"]
}
```

------

## 2.11 Modifications and Options

```
json{
  "$id": "Modification",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "mod_number": { "type": "string" },
    "mod_type": {
      "type": "string",
      "enum": ["ADMIN", "FUNDING", "SCOPE", "POPSHIFT", "OPTION_EXERCISE", "TERMINATION", "OTHER"]
    },
    "effective_date": { "type": "string", "format": "date" },
    "signed_date": { "type": "string", "format": "date" },
    "summary": { "type": "string" },
    "value_change": { "type": "number" },
    "funding_change": { "type": "number" },
    "pop_start_change": { "type": "string", "format": "date" },
    "pop_end_change": { "type": "string", "format": "date" }
  },
  "required": ["id", "contract_id", "mod_number", "mod_type"]
}
```

Options are represented either as CLINs with `is_option = true` or a dedicated table:

```
json{
  "$id": "OptionPeriod",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "label": { "type": "string" },
    "pop_start": { "type": "string", "format": "date" },
    "pop_end": { "type": "string", "format": "date" },
    "value": { "type": "number" },
    "status": {
      "type": "string",
      "enum": ["PLANNED", "EXERCISABLE", "EXERCISED", "EXPIRED"]
    },
    "exercise_deadline": { "type": "string", "format": "date" },
    "exercise_mod_id": { "type": ["string", "null"], "format": "uuid" }
  },
  "required": ["id", "contract_id", "label", "status"]
}
```

------

## 2.12 Document and AI Extraction

```
json{
  "$id": "ContractDocument",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "modification_id": { "type": ["string", "null"], "format": "uuid" },
    "file_name": { "type": "string" },
    "file_type": { "type": "string" },
    "storage_url": { "type": "string" },
    "source": {
      "type": "string",
      "enum": ["AWARD", "MOD", "RFP", "SOW", "ATTACHMENT", "OTHER"]
    },
    "ai_extraction_status": {
      "type": "string",
      "enum": ["NOT_STARTED", "IN_PROGRESS", "COMPLETED", "FAILED"]
    }
  },
  "required": ["id", "contract_id", "file_name", "storage_url"]
}
json{
  "$id": "AIExtractionResult",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "document_id": { "type": "string", "format": "uuid" },
    "model_version": { "type": "string" },
    "extracted_fields": { "type": "object" },
    "confidence_scores": { "type": "object" },
    "review_status": {
      "type": "string",
      "enum": ["PENDING_REVIEW", "APPROVED", "REJECTED"]
    },
    "reviewed_by": { "type": ["string", "null"], "format": "uuid" }
  },
  "required": ["id", "document_id", "model_version", "extracted_fields"]
}
```

Deliverable scheduling assistant:

```
json{
  "$id": "AIScheduleSuggestion",
  "type": "object",
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "contract_id": { "type": "string", "format": "uuid" },
    "deliverable_id": { "type": ["string", "null"], "format": "uuid" },
    "suggested_instances": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "due_date": { "type": "string", "format": "date" },
          "reason": { "type": "string" },
          "source_clause_ref": { "type": "string" }
        },
        "required": ["due_date"]
      }
    }
  },
  "required": ["id", "contract_id"]
}
```

------

## 3. Contract Lifecycle Workflows

## 3.1 Opportunity → Proposal

1. Capture:
   - Create `Opportunity`; populate solicitation, NAICS, set‑aside, estimated value.
2. Qualification:
   - Update `status` from `IDENTIFIED` → `QUALIFIED` → bid decision.
3. Proposal management:
   - Attach RFP docs as `ContractDocument` (source=RFP).
   - Track internal tasks (separate “ProposalTask” table if needed).
4. Submission:
   - Update `status` = `SUBMITTED`.
   - Store submission date, amount.

------

## 3.2 Proposal → Award → Contract Setup

1. Award recognition:
   - Convert Opportunity with `status = AWARDED` into `Contract`.
2. AI‑assisted setup:
   - Upload award document as `ContractDocument` (source=AWARD).
   - Run AI extraction to populate:
     - Contract number, title, agency, type, POP, CLIN list, options, WAWF/SF1034 instructions, CDRLs.
3. Human review:
   - Contracts user validates `AIExtractionResult`, approves, and system writes to `Contract`, `Clin`, `OptionPeriod`, `Deliverable`.
4. Financial baseline:
   - Enter initial `Funding` at contract/CLIN level.
   - Set `total_contract_value`, `total_funded_value`.

------

## 3.3 Execution Phase

Core workflows:

- Performance tracking: link internal timekeeping/expense to `Clin` and/or `TaskOrder`.
- Deliverable scheduling:
  - Generate `DeliverableInstance` records from recurrence and POP.
  - Dashboard for upcoming and overdue instances.
- Invoicing:
  - For each billing cycle, system suggests `Invoice` lines based on:
    - Labor hours, materials, milestones, and CLIN structure.
  - For DoD via WAWF:
    - Use contract’s `wawf_instructions` to select document type (Combo, 2‑in‑1, Cost Voucher, etc.).
  - For civilian using SF1034:
    - Pre‑fill SF1034 header fields and line items.

------

## 3.4 Modifications, Options, and Closeout

- Modification ingestion:
  - Upload mod, run AI extraction to propose `Modification` and updated POP, funding, CLIN changes.
  - Contracts user approves changes.
- Option monitoring:
  - Track `exercise_deadline` for each `OptionPeriod`.
  - Alerts at configurable days before deadline.
- Closeout:
  - Preconditions:
    - All deliverables accepted or waived.
    - No open invoices; all funding reconciled.
  - Set `current_status = CLOSED`, log closeout checklist outcome.

------

## 4. Deliverable and Reporting Management

## 4.1 Data Structures

- `Deliverable` defines type, recurrence, linked CLIN/CDRL, submission method.
- `DeliverableInstance` drives reminders and performance tracking.
- Key fields:
  - `lead_time_days` for internal “start work” alerts.
  - `internal_owner_id` for accountability.

## 4.2 Workflow

1. Creation:
   - AI suggests deliverables from SOW/CDRL language; contracts team confirms.
2. Scheduling:
   - System generates instances across relevant POP; adjusts when POP/option dates shift.
3. Execution:
   - PM updates status (`IN_PROGRESS`, `SUBMITTED`, etc.), attaches artifacts.
4. Government feedback:
   - Record acceptance/rejection and reasons, linking to `DeliverableInstance`.

------

## 5. Government Billing Integration

## 5.1 SF1034 Support

- Present SF1034 view for applicable contracts:
  - Map invoice header fields:
    - Department, bureau, contract number, payee name/address, schedule number.
  - Group `InvoiceLine` by CLIN for clarity.

Export options:

- PDF rendition formatted like SF1034.
- Data export (JSON/CSV) for internal accounting.

## 5.2 WAWF Support

WAWF supports electronic submission of invoices and receiving reports and is mandated under DFARS 252.232‑7003 and 252.232‑7006 for DoD contracts.

System support:

- Store WAWF routing codes (CAGE, DoDAACs) on `Contract`.
- For each invoice:
  - Validate document type matches WAWF instructions (Combo vs 2‑in‑1, etc.).
  - Validate CLIN coverage and amounts.
- Integration patterns (choose based on scope):
  - Phase 1: User‑driven – generate a “WAWF data sheet” the user keys into WAWF.
  - Phase 2: API automation (if you integrate with PIEE/WAWF web services) – system submits invoice payload and stores WAWF reference ID.

------

## 6. Subcontractor Management (Prime/Sub)

## 6.1 Prime Perspective

- Maintain `Subcontract` records linked to `prime_contract_id`.
- Map each `SubcontractLineItem` to a prime `Clin` where possible.
- Track:
  - SubK POP, ceiling, funded value, flow‑down clauses.
  - SubK invoices (mirror of `Invoice` but categorized as payable).

## 6.2 Workflow

1. Award:
   - Create subcontracts aligned with prime CLINs.
2. Flow‑down:
   - Flag mandatory flow‑down clauses and require acknowledgment.
3. Performance:
   - Associate sub labor and deliverables with sub line items.
4. Payment:
   - When prime invoice is accepted/paid, show recommended sub payments based on SubK payment terms.

------

## 7. Contract Modification and Option Tracking

## 7.1 Mod Processing

1. Intake:
   - Upload mod PDF; create `ContractDocument` and run AI extraction.
2. Parsing:
   - Extract:
     - Mod number and type.
     - Changes to POP, value, funding, and CLIN structure.
3. Review:
   - Show “before vs after” view of:
     - POP, CLIN ceilings, funded amounts, options.
4. Apply:
   - On approval, update:
     - `Contract`, `Clin`, `Funding`, `PeriodOfPerformance`, `OptionPeriod`.

## 7.2 Option Lifecycle

- Status transitions:
  - `PLANNED` → `EXERCISABLE` → `EXERCISED` → `EXPIRED`.
- Automatic effects:
  - When exercised:
    - Create `Modification` of type `OPTION_EXERCISE`.
    - Activate associated `PeriodOfPerformance` and CLINs; generate new deliverable instances.

------

## 8. AI Assistance Design

## 8.1 Award Document Extraction

Target outputs from PDFs/DOCs:

- Contract metadata: number, title, agency, contract type, POP.
- CLIN table:
  - CLIN number, description, CLIN type, pricing type, unit, unit price, quantity, total.
- Options:
  - Option year labels, POP, value, exercise windows.
- Funding:
  - Initial obligations and multi‑year funding references.
- Billing instructions:
  - WAWF document type, routing info, SF1034 requirement.
- CDRLs and deliverables.

Pipeline:

1. Ingestion:
   - OCR if necessary; text segmentation.
2. Layout and table detection:
   - Detect CLIN and CDRL tables.
3. NER + schema mapping:
   - Map extracted data to `AIExtractionResult.extracted_fields`.
4. Human‑in‑the‑loop:
   - Side‑by‑side document and extracted values; user approves or edits.

## 8.2 Deliverable Scheduling Assistant

Use extracted clauses like “The Contractor shall submit monthly status reports within 10 days after the end of each month.” to:

- Identify recurrence (monthly) and lead time (e.g., 10 days).
- Propose `Deliverable` and `DeliverableInstance` records.
- Show reasoning (source clause text and reference) for user trust.

------

## 9. Lifecycle Summary Table

| Concept             | Key Entities                            | Primary Workflows                         |
| :------------------ | :-------------------------------------- | :---------------------------------------- |
| Opportunity         | Opportunity                             | Capture, qualification, proposal tracking |
| Award & Setup       | Contract, Clin, OptionPeriod            | AI extraction, financial baseline         |
| Execution           | TaskOrder, DeliverableInstance, Invoice | Performance, deliverables, invoicing      |
| Mods & Options      | Modification, PeriodOfPerformance       | POP/value changes, option exercise        |
| Subs                | Subcontract, SubcontractLineItem        | Flowdown, sub performance & payment       |
| Billing Integration | Invoice, SF1034, WAWF routing fields    | SF1034 generation, WAWF prep/automation   |