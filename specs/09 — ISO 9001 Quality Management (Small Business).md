## 1. Core QMS Data Model

Focus on a single **Document** aggregate with typed content (policy, procedure, work instruction, record template) and separate **Records** for executed quality evidence.

## 1.1 Main entities

- Organization
  - id (UUID)
  - name
  - site_code
  - industry
- User
  - id (UUID)
  - org_id (FK Organization)
  - email
  - display_name
  - role (admin, quality_manager, staff, auditor, customer_rep)
  - is_active (bool)
- Document
  - id (UUID)
  - org_id (FK)
  - doc_number (string, unique per org, e.g. “QMS-PR-001”)
  - title (string)
  - type (enum: policy, procedure, work_instruction, form, record_template, external_ref)
  - process_area (enum: context, leadership, planning, support, operation, performance_eval, improvement)
  - iso_clause_refs (string[], e.g. ["7.5","9.2","9.3"])
  - owner_user_id (FK User)
  - status (enum: draft, in_review, approved, obsolete)
  - current_revision_id (FK DocumentRevision)
  - effective_date (date)
  - superseded_by_document_id (nullable FK Document)
  - is_controlled (bool)
- DocumentRevision
  - id (UUID)
  - document_id (FK Document)
  - revision_code (string, e.g. “A”, “B”, “C”)
  - change_summary (text)
  - change_reason (text)
  - author_user_id (FK User)
  - approver_user_id (FK User)
  - approval_date (datetime)
  - file_backend (enum: google_drive, sharepoint, internal_blob)
  - file_backend_id (string; Drive fileId / SharePoint itemId)
  - created_at (datetime)
  - is_effective (bool)
- DocumentLink
  - id (UUID)
  - from_document_id (FK Document)
  - to_document_id (FK Document)
  - relation_type (enum: references, derived_from, supersedes)

Distinguish **document** vs **record**: document templates define how work is done, records show work was done.

## 1.2 Quality record entities (examples)

- TrainingRecord
  - id, org_id
  - user_id (FK User)
  - training_type (string)
  - document_id (FK Document, procedure or WI trained to)
  - completion_date (date)
  - method (enum: on_the_job, classroom, online)
  - competency_verified_by_user_id
- InspectionRecord
  - id, org_id
  - work_order_id (nullable)
  - product_id (nullable)
  - inspector_user_id
  - document_id (FK WI / inspection plan)
  - sample_size (int)
  - qty_accepted (int)
  - qty_rejected (int)
  - characteristics (JSONB: list of {characteristic, spec_min, spec_max, measured, result})
  - nonconformance_capa_id (nullable)
- CalibrationRecord
  - id, org_id
  - equipment_id
  - calibration_date
  - due_date
  - result (enum: pass, fail)
  - certificate_file_id (Drive / SharePoint)
- AuditRecord (internal audits; see next section)
- ManagementReviewRecord (see §3)

You can extend this pattern for any clause-required record (competence, maintenance, design review etc.).

## 1.3 Example JSON schema – Document

```
json{
  "$id": "https://example.com/schemas/document.json",
  "type": "object",
  "required": ["id", "org_id", "doc_number", "title", "type", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "org_id": { "type": "string", "format": "uuid" },
    "doc_number": { "type": "string" },
    "title": { "type": "string" },
    "type": {
      "type": "string",
      "enum": ["policy", "procedure", "work_instruction", "form", "record_template", "external_ref"]
    },
    "process_area": {
      "type": "string",
      "enum": ["context", "leadership", "planning", "support", "operation", "performance_eval", "improvement"]
    },
    "iso_clause_refs": { "type": "array", "items": { "type": "string" } },
    "owner_user_id": { "type": "string", "format": "uuid" },
    "status": {
      "type": "string",
      "enum": ["draft", "in_review", "approved", "obsolete"]
    },
    "current_revision_id": { "type": "string", "format": "uuid" },
    "effective_date": { "type": "string", "format": "date" },
    "superseded_by_document_id": { "type": "string", "format": "uuid" },
    "is_controlled": { "type": "boolean" }
  }
}
```

------

## 2. Internal Review (Internal Audit) Scheduling & Checklists

ISO 9001 requires planned internal audits with defined criteria, scope, methods, and records of results.

## 2.1 Entities

- AuditProgram
  - id, org_id
  - period (enum: annual, semi_annual, quarterly)
  - year (int)
  - approved_by_user_id
  - approval_date
- AuditPlan
  - id, org_id
  - audit_program_id (FK)
  - name (e.g. “Q1 2026 Internal Audit”)
  - scope (text)
  - criteria (text; e.g. “ISO 9001:2015, customer X requirements”)
  - planned_start_date
  - planned_end_date
  - status (enum: planned, in_progress, completed, cancelled)
- AuditArea
  - id
  - audit_plan_id (FK)
  - process_name (string; e.g. “Purchasing”)
  - iso_clause_refs (string[])
  - responsible_owner_user_id
- AuditChecklistTemplate
  - id, org_id
  - name
  - iso_clause_refs (string[])
  - questions (JSONB: [{id, text, clause_ref, guidance}])
- AuditInstance
  - id
  - audit_plan_id (FK)
  - area_id (FK AuditArea)
  - auditor_user_id
  - auditee_user_id (nullable)
  - scheduled_date
  - actual_start
  - actual_end
  - status (enum: scheduled, in_progress, closed)
  - checklist_template_id (FK AuditChecklistTemplate)
- AuditChecklistItemResult
  - id
  - audit_instance_id (FK)
  - question_id (string from template)
  - response (enum: conforming, minor_nc, major_nc, observation, not_applicable)
  - notes (text)
  - evidence_links (string[] – links to records / documents)
  - capa_id (nullable FK CAPA module)

## 2.2 Workflow states

For **AuditPlan**:

- planned → in_progress
  - Trigger: first AuditInstance status moves to in_progress.
- in_progress → completed
  - All AuditInstances closed; management approves report.
- planned → cancelled

For **AuditInstance**:

- scheduled
  - Created with assigned auditor, date, and area; checklist attached.
- in_progress
  - Auditor begins; can log checklist results.
- closed
  - All checklist items answered; report summary and findings logged; linked CAPAs created as needed.

## 2.3 JSON schema – AuditChecklistTemplate

```
json{
  "$id": "https://example.com/schemas/audit_checklist_template.json",
  "type": "object",
  "required": ["id", "org_id", "name", "questions"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "org_id": { "type": "string", "format": "uuid" },
    "name": { "type": "string" },
    "iso_clause_refs": {
      "type": "array",
      "items": { "type": "string" }
    },
    "questions": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "text"],
        "properties": {
          "id": { "type": "string" },
          "text": { "type": "string" },
          "clause_ref": { "type": "string" },
          "guidance": { "type": "string" }
        }
      }
    }
  }
}
```

------

## 3. Management Review Documentation

Management review must consider defined inputs (audit results, customer feedback, process performance, etc.) and retain records of results and actions.

## 3.1 Entities

- ManagementReviewMeeting
  - id, org_id
  - meeting_number (string; “MR-2026-01”)
  - period_covered_start (date)
  - period_covered_end (date)
  - meeting_date
  - chair_user_id
  - attendees (JSONB: [{user_id, role_at_meeting}])
  - status (enum: draft, scheduled, held, minutes_approved)
  - agenda_doc_id (FK Document or file link)
- ManagementReviewInput
  - id
  - meeting_id (FK)
  - category (enum: audit_results, customer_feedback, process_performance, nonconformities_capa, supplier_performance, resources, risks_opportunities, previous_actions_status, external_issues)
  - source_reference (string; e.g. KPI dashboard, report id)
  - summary (text)
- ManagementReviewDecision
  - id
  - meeting_id (FK)
  - category (enum: opportunities_for_improvement, qms_changes, resource_needs, quality_objectives_changes, risk_treatment, supplier_actions)
  - description (text)
  - responsible_user_id
  - due_date
  - status (enum: open, in_progress, completed, cancelled)
  - linked_capa_id (nullable)
- ManagementReviewMinutes
  - id
  - meeting_id (FK)
  - document_revision_id (FK DocumentRevision if minutes are controlled doc)
  - notes (text) – or treat minutes as a controlled DocumentRevision only

## 3.2 Workflow

- draft
  - Meeting created with proposed date, agenda, and planned inputs.
- scheduled
  - Invitations sent; inputs linked.
- held
  - Meeting conducted; inputs reviewed; decisions recorded.
- minutes_approved
  - Chair approves minutes; decisions/action items tracked to closure.

JSON example for **ManagementReviewMeeting**:

```
json{
  "id": "uuid",
  "org_id": "uuid",
  "meeting_number": "MR-2026-01",
  "period_covered_start": "2025-01-01",
  "period_covered_end": "2025-12-31",
  "meeting_date": "2026-02-15",
  "chair_user_id": "uuid",
  "attendees": [
    { "user_id": "uuid1", "role_at_meeting": "CEO" },
    { "user_id": "uuid2", "role_at_meeting": "Quality Manager" }
  ],
  "status": "minutes_approved"
}
```

------

## 4. Customer Satisfaction Tracking

ISO 9001 expects monitoring of customer perceptions (complaints, surveys, on-time delivery, returns, etc.).

## 4.1 Entities

- Customer
  - id, org_id
  - name
  - erp_reference (string)
  - criticality (enum: high, medium, low)
- CustomerFeedbackChannel
  - id
  - org_id
  - name (e.g. complaint, NPS_survey, informal_feedback, customer_scorecard)
- CustomerSatisfactionRecord
  - id, org_id
  - customer_id (FK)
  - date_received
  - channel_id (FK CustomerFeedbackChannel)
  - source_reference (string; e.g. ticket id, email id)
  - type (enum: complaint, compliment, suggestion, survey_response, scorecard)
  - rating_value (number, nullable; e.g. 1–5 or NPS)
  - rating_scale (string; e.g. “1-5”, “-100–100”)
  - text_feedback (text)
  - product_id (nullable)
  - order_reference (nullable)
  - severity (enum: low, medium, high, critical) – for complaints
  - linked_capa_id (nullable)
  - status (enum: open, in_review, closed)
- CustomerScorecardMetric
  - id
  - satisfaction_record_id (FK, type=scorecard)
  - metric_name (string; e.g. “On-Time Delivery”)
  - metric_value (number)
  - metric_unit (string; “percent”, “ppm”, etc.)

JSON schema snippet:

```
json{
  "$id": "https://example.com/schemas/customer_satisfaction_record.json",
  "type": "object",
  "required": ["id", "org_id", "customer_id", "date_received", "type"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "org_id": { "type": "string", "format": "uuid" },
    "customer_id": { "type": "string", "format": "uuid" },
    "date_received": { "type": "string", "format": "date" },
    "channel_id": { "type": "string", "format": "uuid" },
    "type": {
      "type": "string",
      "enum": ["complaint", "compliment", "suggestion", "survey_response", "scorecard"]
    },
    "rating_value": { "type": "number" },
    "rating_scale": { "type": "string" },
    "text_feedback": { "type": "string" },
    "severity": {
      "type": "string",
      "enum": ["low", "medium", "high", "critical"]
    },
    "linked_capa_id": { "type": "string", "format": "uuid" },
    "status": {
      "type": "string",
      "enum": ["open", "in_review", "closed"]
    }
  }
}
```

------

## 5. Supplier Evaluation & Approved Vendor List (AVL)

Supplier control is under ISO 9001 clause 8.4.

## 5.1 Entities

- Supplier
  - id, org_id
  - name
  - erp_reference
  - category (enum: raw_material, machining, finishing, services, calibration, logistics, other)
  - criticality (enum: high, medium, low)
  - status (enum: proposed, approved, conditional, disapproved)
  - approval_date
  - approved_by_user_id
  - notes (text)
- SupplierEvaluationCriteria
  - id, org_id
  - name (e.g. “Quality”, “On-Time Delivery”, “Responsiveness”)
  - description
  - weight (number; 0–1)
- SupplierEvaluation
  - id
  - org_id
  - supplier_id (FK)
  - period_start (date)
  - period_end (date)
  - evaluator_user_id
  - total_score (number)
  - result (enum: approved, probation, disapproved)
  - comments (text)
- SupplierEvaluationScore
  - id
  - evaluation_id (FK)
  - criteria_id (FK SupplierEvaluationCriteria)
  - score_value (number; standardized to e.g. 0–100)
- SupplierPerformanceMetric
  - id
  - supplier_id (FK)
  - metric_name (string; e.g. “otd_percent”, “ppm_defects”)
  - period_start, period_end
  - value (number)
  - unit (string)
- ApprovedVendorListSnapshot
  - id
  - org_id
  - effective_date
  - data (JSONB; cached view of all approved suppliers and their details at that date)

JSON example:

```
json{
  "id": "uuid",
  "org_id": "uuid",
  "supplier_id": "uuid",
  "period_start": "2025-01-01",
  "period_end": "2025-12-31",
  "evaluator_user_id": "uuid",
  "total_score": 87.5,
  "result": "approved",
  "comments": "Strong OTD and low defect rate."
}
```

------

## 6. QMS Structure in Google Drive / SharePoint

ISO 9001 requires identification, access, and control of documented information (current versions at point of use, protection, retention).

## 6.1 Folder hierarchy

At the root (e.g. “Company QMS”):

- 00 – Context & Scope
- 01 – Policies & Manual
- 02 – Procedures
- 03 – Work Instructions
- 04 – Forms & Templates
- 05 – Records
  - 05.01 – Training
  - 05.02 – Calibration
  - 05.03 – Production & Inspection
  - 05.04 – Customer Feedback & Complaints
  - 05.05 – Internal Audits
  - 05.06 – Management Review
  - 05.07 – Supplier Evaluation
- 06 – External Documents (customer specs, standards)
- 99 – Obsolete

Your application stores:

- folder_backend_id per logical area (Drive folderId / SharePoint folder URL)
- mapping Document → current file id; Records → folder + file id.

## 6.2 Naming conventions

For controlled documents (Drive file name / SharePoint name):

- Policies: `QMS-PL-001 Quality Policy revA`
- Procedures: `QMS-PR-003 Purchasing Procedure revC`
- Work instructions: `QMS-WI-015 CNC Setup – Haas VF2 revB`
- Forms/templates: `QMS-FM-010 Nonconformance Report Form revA`
- Records: `QMS-RC-010 NCR 2026-00023` (no rev; records are immutable)

Recommended pattern:

`{doc_number} {short_title} rev{revision_code}` for documents.
Records use `{record_type_code} {YYYY}-{sequence}` and no revision (superseded by correction entries or CAPA references).

The system should enforce uniqueness of doc_number and manage revisions so only one active revision exists per document.

## 6.3 Revision tracking

Use your DB as master for metadata and Drive/SharePoint as file store.

- For each new revision:
  - Create new file (copy of previous), update title with new rev.
  - Update DocumentRevision with backend id.
  - Optionally move superseded file to “99 – Obsolete” or set restricted permissions.
- For SharePoint:
  - Either map each revision to a separate file or use SharePoint version history, but still store DocumentRevision rows with version numbers.

Key fields:

- backend (google_drive / sharepoint)
- backend_id (file id)
- backend_version (for SharePoint, major version number)
- is_effective (bool)

------

## 7. KPIs and Metrics

ISO 9001 clause 9.1 expects monitoring, measurement, analysis, and evaluation of QMS performance.

## 7.1 KPI entity

- KpiDefinition
  - id, org_id
  - name (e.g. “On-Time Delivery %”)
  - code (string; “OTD_PERCENT”)
  - description
  - formula (text; human-readable)
  - target_value (number)
  - unit (string; “percent”, “ppm”, “days”)
  - frequency (enum: monthly, quarterly, annually)
  - owner_user_id
- KpiMeasurement
  - id
  - org_id
  - kpi_id (FK)
  - period_start
  - period_end
  - value (number)
  - status (enum: below_target, meets_target, exceeds_target)
  - notes (text)
  - source_reference (string; e.g. report id)

## 7.2 Typical metrics for 1–20 person manufacturers

- On‑time delivery % (per month, per key customer)
- Customer complaint rate (per 100 orders)
- Internal defect rate (scrap %, rework hours)
- Supplier on‑time delivery and defect rate (PPM)
- Training completion vs plan
- Audit findings count (by severity)
- CAPA closure time (average days)

Use your KpiDefinition/KpiMeasurement tables to attach these to management reviews and dashboards.

Markdown table for common KPIs:

| KPI name                | Definition (example)                                  | Source entities                         |
| :---------------------- | :---------------------------------------------------- | :-------------------------------------- |
| On-time delivery %      | Shipments on/before promised date ÷ total shipments   | Shipments, CustomerOrders               |
| Customer complaint rate | Complaints in period ÷ orders in period               | CustomerSatisfactionRecord, Orders      |
| Internal defect rate    | Defective units ÷ units produced                      | InspectionRecord, ProductionRecord      |
| Supplier OTD %          | On-time supplier receipts ÷ total receipts            | SupplierPerformanceMetric, Receipts     |
| Supplier defect PPM     | Defective incoming units × 1e6 ÷ total incoming units | IncomingInspection, SupplierPerformance |
| Training completion %   | Completed trainings ÷ planned trainings               | TrainingRecord, TrainingPlan            |
| CAPA avg closure time   | Mean days from CAPA open to closed                    | CAPA module                             |



------

## 8. AI Assistance for QMS Documentation

AI can help small shops keep documentation lean while aligning with ISO 9001 requirements for processes, procedures, and records.

## 8.1 Drafting and templating

Data inputs:

- Org profile (size, industry, special processes).
- Required clauses / customer-specific requirements.
- Existing documents and records.

AI services:

- Generate initial **policy**, **procedure**, and **work instruction** drafts given:
  - Process name, owner, inputs/outputs, basic steps.
- Suggest **document structures** (sections, headings) aligned with ISO concepts of processes, procedures, and work instructions.
- Create **forms/templates** for records that match required retained information (e.g. internal audit record, management review minutes, supplier evaluation form).

Represent AI prompts as a separate table:

- AiPromptTemplate
  - id, org_id
  - use_case (enum: draft_procedure, revise_document, gap_analysis, summarize_records)
  - prompt_text (text with placeholders)
- AiSession
  - id, org_id
  - use_case
  - input_context (JSONB; document ids, clauses, free text)
  - output_text (text)
  - created_by_user_id
  - created_at

## 8.2 Maintenance and change impact

AI can:

- Compare a new revision draft to previous revision; summarize changes and potential impacts on training, risk, and other documents.
- Suggest which **work instructions** or **forms** may need updates when a higher-level procedure changes (using DocumentLink graph).
- Propose updated **training plans** based on changed documents (e.g., employees who need retraining because a WI they use changed).

## 8.3 Gap analysis vs ISO / customer requirements

Input:

- List of required documents/records for a given standard or customer (modelled as ISORequirement rows).
  - ISORequirement
    - id
    - standard (e.g. “ISO 9001:2015”)
    - clause (string)
    - requirement_text (text)
    - type (enum: required_document, required_record, process_requirement)
- Map of existing Document.iso_clause_refs and QualityRecord types.

AI tasks:

- Generate a **gap report**:
  - For each requirement, identify matching documents/records based on clause_ref, type, and text similarity.
  - Flag missing or weak coverage.
- Provide remediation suggestions:
  - “Create procedure for internal audit (clause 9.2)” if no documents with those references exist.
  - “Add customer satisfaction monitoring method for clause 9.1.2.”

Persist:

- GapAnalysisRun
  - id, org_id
  - standard
  - run_date
  - scope (text)
  - summary (text)
- GapAnalysisFinding
  - id
  - run_id (FK)
  - requirement_id (FK ISORequirement)
  - coverage_level (enum: covered, partial, missing)
  - suggested_actions (text)
  - linked_document_ids (string[])

## 8.4 Guardrails

- AI outputs treated as **drafts**, not authoritative.
- Approval via standard DocumentRevision workflow (owner + approver required).
- AI access restricted to org’s data; no cross-tenant leakage.
- Logs of all AI suggestions kept (AiSession) for auditability.

------

## 9. High-level ER relationships

Conceptual relationships you can turn into an ERD:

- Organization 1—N Users, Documents, Records, Suppliers, Customers.
- Document 1—N DocumentRevision.
- Document N—M Document (via DocumentLink).
- AuditProgram 1—N AuditPlan 1—N AuditArea 1—N AuditInstance 1—N AuditChecklistItemResult.
- ManagementReviewMeeting 1—N ManagementReviewInput, 1—N ManagementReviewDecision.
- Supplier 1—N SupplierEvaluation, 1—N SupplierPerformanceMetric.
- Customer 1—N CustomerSatisfactionRecord.
- KpiDefinition 1—N KpiMeasurement.
- ISORequirement 1—N GapAnalysisFinding.

All IDs can be UUID; use soft deletes (is_deleted) where appropriate.