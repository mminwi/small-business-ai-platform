10 — Document Control





## 1. Core concepts and scope

For this product, treat “controlled documents” as any document that directly or indirectly affects product or service quality: policies, procedures, work instructions, forms/templates, specifications, and externally sourced standards or customer documents.

Key responsibilities of the module for ISO 9001:

- Approve documents before issue.
- Review and update documents as needed, and re‑approve.
- Identify changes and current revision status.
- Ensure relevant versions are available at point of use.
- Ensure documents are legible, identifiable, and traceable.
- Control external documents and prevent unintended use of obsolete documents.

------

## 2. Data structures and JSON schemas

Design the data model so that the “file” lives in Google Drive or SharePoint, while your system is the **metadata** and workflow source of truth.

## 2.1 Entity list

- Document
- DocumentRevision
- DocumentDistribution (per‑role and per‑person distribution)
- DocumentReviewSchedule
- ChangeRequest (ECR)
- ChangeImpactAssessment
- ApprovalTask / WorkflowInstance
- ExternalDocument (customer specs, standards)

## 2.2 Document metadata JSON schema

This is the primary record for a controlled document; revisions are child records.

```
json{
  "$id": "https://example.com/schemas/document.json",
  "type": "object",
  "title": "Document",
  "required": [
    "id",
    "org_id",
    "doc_number",
    "title",
    "doc_type",
    "owner_user_id",
    "status",
    "current_revision_id",
    "created_at",
    "updated_at"
  ],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "org_id": { "type": "string", "format": "uuid" },
    "doc_number": { "type": "string" },
    "title": { "type": "string", "maxLength": 255 },
    "doc_type": {
      "type": "string",
      "enum": ["POLICY", "PROCEDURE", "WORK_INSTRUCTION", "FORM", "SPECIFICATION", "TEMPLATE", "RECORD_LAYOUT", "OTHER"]
    },
    "process_area": {
      "type": "string",
      "description": "Optional tag like 'Sales', 'Production', 'Calibration'."
    },
    "owner_user_id": { "type": "string", "format": "uuid" },
    "status": {
      "type": "string",
      "enum": ["DRAFT", "IN_REVIEW", "PENDING_APPROVAL", "ACTIVE", "OBSOLETE"]
    },
    "current_revision_id": { "type": "string", "format": "uuid" },
    "external": {
      "type": "boolean",
      "description": "True if externally originated (customer spec, standard)."
    },
    "external_source": {
      "type": "string",
      "description": "Customer name, standard body, URL, etc."
    },
    "tags": {
      "type": "array",
      "items": { "type": "string" }
    },
    "drive_file_id": {
      "type": "string",
      "description": "Google Drive file ID if using Drive."
    },
    "sharepoint_site_id": {
      "type": "string",
      "description": "SharePoint site identifier."
    },
    "sharepoint_drive_id": {
      "type": "string",
      "description": "SharePoint document library/drive ID."
    },
    "sharepoint_item_id": {
      "type": "string",
      "description": "SharePoint file item ID."
    },
    "distribution_mode": {
      "type": "string",
      "enum": ["ROLE_BASED", "USER_LIST", "PUBLIC"]
    },
    "effective_date": { "type": "string", "format": "date" },
    "superseded_by_document_id": { "type": "string", "format": "uuid" },
    "created_at": { "type": "string", "format": "date-time" },
    "created_by": { "type": "string", "format": "uuid" },
    "updated_at": { "type": "string", "format": "date-time" },
    "updated_by": { "type": "string", "format": "uuid" },
    "audit_trail_id": {
      "type": "string",
      "format": "uuid",
      "description": "Link to audit log stream if separated."
    }
  }
}
```

## 2.3 DocumentRevision JSON schema

Each revision is a distinct record, with linkage to the underlying file version (Drive / SharePoint).

```
json{
  "$id": "https://example.com/schemas/document_revision.json",
  "type": "object",
  "title": "DocumentRevision",
  "required": [
    "id",
    "document_id",
    "revision_code",
    "status",
    "created_at",
    "created_by"
  ],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "document_id": { "type": "string", "format": "uuid" },
    "revision_code": {
      "type": "string",
      "description": "e.g. 'A', 'B', 'C' or '0', '1', '2'."
    },
    "revision_index": {
      "type": "integer",
      "description": "Monotonic increasing integer for sorting."
    },
    "status": {
      "type": "string",
      "enum": ["DRAFT", "IN_REVIEW", "PENDING_APPROVAL", "ACTIVE", "SUPERSEDED", "REJECTED"]
    },
    "change_summary": {
      "type": "string",
      "description": "Short description of changes for change log."
    },
    "change_reason": { "type": "string" },
    "effective_date": { "type": "string", "format": "date" },
    "supersedes_revision_id": { "type": "string", "format": "uuid" },
    "drive_file_version_id": {
      "type": "string",
      "description": "Optional mapping to Google Drive file version."
    },
    "sharepoint_version_label": {
      "type": "string",
      "description": "SharePoint version label (e.g. '3.0')."
    },
    "approver_ids": {
      "type": "array",
      "items": { "type": "string", "format": "uuid" }
    },
    "approved_at": { "type": "string", "format": "date-time" },
    "review_due_date": { "type": "string", "format": "date" },
    "attachments": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "label": { "type": "string" },
          "url": { "type": "string" }
        }
      }
    },
    "created_at": { "type": "string", "format": "date-time" },
    "created_by": { "type": "string", "format": "uuid" },
    "updated_at": { "type": "string", "format": "date-time" },
    "updated_by": { "type": "string", "format": "uuid" }
  }
}
```

## 2.4 Distribution and review schedule JSON schemas

These support ISO requirements to make relevant versions available and to review documents periodically.

```
json{
  "$id": "https://example.com/schemas/document_distribution.json",
  "type": "object",
  "title": "DocumentDistribution",
  "required": ["id", "document_id", "scope_type"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "document_id": { "type": "string", "format": "uuid" },
    "scope_type": {
      "type": "string",
      "enum": ["ROLE", "USER", "LOCATION", "GROUP"]
    },
    "scope_value": {
      "type": "string",
      "description": "Role name, user id, location id, or group id."
    },
    "mandatory_read": {
      "type": "boolean",
      "description": "If true, require read/acknowledgement."
    },
    "read_deadline": { "type": "string", "format": "date" },
    "created_at": { "type": "string", "format": "date-time" },
    "created_by": { "type": "string", "format": "uuid" }
  }
}
json{
  "$id": "https://example.com/schemas/document_review_schedule.json",
  "type": "object",
  "title": "DocumentReviewSchedule",
  "required": ["id", "document_id", "frequency_months", "next_review_date"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "document_id": { "type": "string", "format": "uuid" },
    "frequency_months": { "type": "integer", "minimum": 1 },
    "next_review_date": { "type": "string", "format": "date" },
    "last_completed_review_date": { "type": "string", "format": "date" },
    "responsible_user_id": { "type": "string", "format": "uuid" },
    "auto_create_change_request": {
      "type": "boolean",
      "description": "If true, open ChangeRequest at review date."
    }
  }
}
```

------

## 3. Workflow states and lifecycle

## 3.1 Document lifecycle stages

Align lifecycle with ISO control-of-documented-information expectations.

1. Draft
2. In Review
3. Pending Approval
4. Active (Released)
5. Obsolete

You can store workflow state on DocumentRevision.status and derive Document.status from the latest revision.

## Workflow state JSON schema

```
json{
  "$id": "https://example.com/schemas/document_workflow_state.json",
  "type": "object",
  "title": "DocumentWorkflowState",
  "required": ["state", "allowed_transitions"],
  "properties": {
    "state": {
      "type": "string",
      "enum": ["DRAFT", "IN_REVIEW", "PENDING_APPROVAL", "ACTIVE", "OBSOLETE"]
    },
    "allowed_transitions": {
      "type": "array",
      "items": { "type": "string" }
    },
    "requires_approval": { "type": "boolean" },
    "notifies_roles": {
      "type": "array",
      "items": { "type": "string" }
    }
  }
}
```

Example configuration (your seed data):

- DRAFT → IN_REVIEW, OBSOLETE
- IN_REVIEW → PENDING_APPROVAL, DRAFT
- PENDING_APPROVAL → ACTIVE, DRAFT, REJECTED (if you use that internal state)
- ACTIVE → OBSOLETE, DRAFT (for next revision)
- OBSOLETE → (no forward transitions)

## 3.2 Creation to approval flow

A typical lifecycle for a new document:

1. Creation
   - User creates Document (status DRAFT) and DocumentRevision DRAFT.
   - File created in Drive/SharePoint folder, with metadata tags mirroring doc_number, title, status.
2. Authoring
   - Edits happen directly in Drive/SharePoint.
   - System locks revision so only designated editors can modify.
3. Review
   - Author triggers “Send for review”.
   - System creates ApprovalTask(s) for reviewers, sets revision status IN_REVIEW.
4. Approval
   - Required approvers sign off (per routing rules).
   - On final approval:
     - Set revision status ACTIVE.
     - Document.current_revision_id updated.
     - Status ACTIVE, effective_date set.
     - Previous revision (if any) set to SUPERSEDED.
5. Distribution
   - Distribution rules applied.
   - Notifications to users/roles.
   - Optional read‑acknowledgement tracking.
6. Review and obsolescence
   - Scheduled reviews generate tasks/change requests.
   - When truly obsolete, status set to OBSOLETE, and Drive/SharePoint file is clearly tagged or moved to an “Obsolete” library, while preventing access at point of use.

------

## 4. Change control workflows

The change process should satisfy ISO requirements to identify changes, ensure re‑approval, and prevent unintended use of outdated versions.

## 4.1 ChangeRequest JSON schema

```
json{
  "$id": "https://example.com/schemas/change_request.json",
  "type": "object",
  "title": "ChangeRequest",
  "required": ["id", "org_id", "source_type", "status", "created_at", "created_by"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "org_id": { "type": "string", "format": "uuid" },
    "source_type": {
      "type": "string",
      "enum": ["DOCUMENT", "EXTERNAL_TRIGGER", "AUDIT", "CUSTOMER_COMPLAINT", "NONCONFORMITY"]
    },
    "document_id": { "type": "string", "format": "uuid" },
    "current_revision_id": { "type": "string", "format": "uuid" },
    "proposed_change_summary": { "type": "string" },
    "reason_for_change": { "type": "string" },
    "requested_by_user_id": { "type": "string", "format": "uuid" },
    "status": {
      "type": "string",
      "enum": ["OPEN", "UNDER_REVIEW", "APPROVED", "REJECTED", "IMPLEMENTED", "CLOSED"]
    },
    "impact_assessment_id": { "type": "string", "format": "uuid" },
    "target_completion_date": { "type": "string", "format": "date" },
    "linked_nonconformity_id": { "type": "string", "format": "uuid" },
    "linked_corrective_action_id": { "type": "string", "format": "uuid" },
    "created_at": { "type": "string", "format": "date-time" },
    "created_by": { "type": "string", "format": "uuid" }
  }
}
```

## 4.2 ChangeImpactAssessment JSON schema

```
json{
  "$id": "https://example.com/schemas/change_impact_assessment.json",
  "type": "object",
  "title": "ChangeImpactAssessment",
  "required": ["id", "change_request_id", "summary"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "change_request_id": { "type": "string", "format": "uuid" },
    "summary": { "type": "string" },
    "impacted_processes": {
      "type": "array",
      "items": { "type": "string" }
    },
    "impacted_documents": {
      "type": "array",
      "items": { "type": "string", "format": "uuid" }
    },
    "training_required": { "type": "boolean" },
    "training_plan": { "type": "string" },
    "risk_level": {
      "type": "string",
      "enum": ["LOW", "MEDIUM", "HIGH"]
    },
    "assessed_by_user_id": { "type": "string", "format": "uuid" },
    "assessed_at": { "type": "string", "format": "date-time" }
  }
}
```

## 4.3 ApprovalTask / routing schema

```
json{
  "$id": "https://example.com/schemas/approval_task.json",
  "type": "object",
  "title": "ApprovalTask",
  "required": ["id", "org_id", "target_type", "target_id", "status", "assignee_id"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "org_id": { "type": "string", "format": "uuid" },
    "target_type": {
      "type": "string",
      "enum": ["DOCUMENT_REVISION", "CHANGE_REQUEST"]
    },
    "target_id": { "type": "string", "format": "uuid" },
    "sequence_order": { "type": "integer" },
    "assignee_id": { "type": "string", "format": "uuid" },
    "role_required": {
      "type": "string",
      "description": "E.g. 'QUALITY_MANAGER', 'OPERATIONS_MANAGER'."
    },
    "status": {
      "type": "string",
      "enum": ["PENDING", "APPROVED", "REJECTED", "SKIPPED"]
    },
    "decision_at": { "type": "string", "format": "date-time" },
    "decision_comment": { "type": "string" },
    "created_at": { "type": "string", "format": "date-time" }
  }
}
```

## 4.4 Change control workflow summary

- Request: User raises ChangeRequest, linking the current DocumentRevision and reason.
- Impact assessment: Assigned user or AI assistant drafts impact summary, routes for review.
- Approval: ApprovalTasks created; on all APPROVED, system allows creation of new DocumentRevision.
- Implementation: New revision authored, approved, and released; training tasks generated if required; ChangeRequest set to IMPLEMENTED/CLOSED.

------

## 5. Google Drive and SharePoint integration

ISO 9001 does not require a specific tool, but modern implementations typically use DMS platforms like SharePoint or Drive to ensure access control, versioning, and auditability.

## 5.1 Repository strategy

- Google Drive:
  - One top‑level folder per organization: `/QMS Documents`.
  - Subfolders by process or document type: `/Procedures`, `/Work Instructions`, `/Forms`, `/Obsolete`.
  - Use Drive file IDs in Document.drive_file_id.
  - Use Drive API to: create files, set permissions, read version history, move obsolete versions.
- SharePoint:
  - One dedicated site for QMS (e.g., `qms.yourcompany.com/sites/QMS`).
  - Use one or more document libraries: `Controlled Documents`, `Records`, `Obsolete Documents`.
  - Mirror key metadata (doc number, title, status, revision) into SharePoint columns as needed.
  - Enable versioning (major/minor versions) and content approval on the library so that editors see drafts and end users see only approved versions.

## 5.2 Integration patterns

- Store only IDs in your DB; do not duplicate files unless you need backups.
- Use OAuth for per‑user access; service account for system operations (e.g., auto moving obsolete docs).
- Read‑only users in your app correspond to limited permissions in Drive/SharePoint to prevent unauthorized edits.

------

## 6. Document numbering and revision control

## 6.1 Document numbering scheme

For small businesses, keep the scheme simple and human‑friendly. A common pattern:

```
[Category]-[ProcessCode]-[Sequence]-[OptionalSuffix]
```

Examples:

- `POL-QUA-001` – Quality Policy
- `PRO-PROD-004` – Production Procedure 004
- `WI-PROD-004-01` – Work Instruction 01 under that procedure

Fields to support:

- category: POL, PRO, WI, FRM, SPEC
- process_code: short alpha code maintained in a lookup table
- sequence: zero‑padded integer (001–999)
- suffix: optional version of sub‑document

Document.doc_number holds the final composite string.

## 6.2 Revision control implementation

- Use a sequential revision_index integer plus display revision_code.
- For documents, use alphabetic codes for controlled revisions: A, B, C…; minor drafts can use numeric suffix or track only in Drive/SharePoint (e.g., 0.1, 0.2).
- When a revision is approved:
  - Freeze revision record (immutable except for status fields).
  - Tag the Drive/SharePoint version with the revision code (e.g., label “Rev B”).
  - Automatically update change log and distribution.

------

## 7. AI assistance features

ISO 9001 does not require AI, but you can leverage it to reduce overhead of drafting and maintaining documents, while still preserving human approval.

## 7.1 Drafting assistance

Use AI for:

- Drafting new procedures from plain‑language prompts (“Create a calibration procedure for handheld multimeters”).
- Generating work instructions from process descriptions and photos.
- Suggesting structure based on ISO 9001 guidance on documented information.

Minimal fields for AI draft request:

```
json{
  "organization_profile": "Small contract manufacturer, 10 employees, machining and assembly.",
  "document_type": "PROCEDURE",
  "process_description": "How we receive, inspect, and store incoming raw materials.",
  "constraints": [
    "ISO 9001:2015 compliant",
    "Keep under 3 pages",
    "Use clear step-wise instructions"
  ],
  "reference_documents": [
    { "doc_id": "uuid-of-related-proc" }
  ]
}
```

The output should be plain text or structured sections, inserted into a Drive/SharePoint document as a DRAFT revision for human editing.

## 7.2 Gap analysis

AI can analyze:

- Alignment of an existing procedure against ISO 9001 clauses (e.g., 7.5 for documented information, 8.5 for production).
- Coverage of mandatory documented information list for ISO 9001 (quality policy, objectives, procedures, records).

Minimal gap analysis payload:

```
json{
  "document_text": "Full text or excerpt of the procedure...",
  "target_requirements": [
    "ISO 9001:2015 clause 7.5.3 control of documented information",
    "Internal QMS procedure DOC-STD-001"
  ],
  "expected_outputs": [
    "List of met requirements",
    "List of gaps with clause references",
    "Suggested wording changes"
  ]
}
```

## 7.3 Change impact assessment

AI can help draft the ChangeImpactAssessment.summary and impacted_documents fields by:

- Looking up other documents referencing the same process or terms.
- Suggesting related documents (forms, work instructions) that likely need revision when a high‑level procedure changes.

You still keep the **final** impact assessment as a user‑editable field that AI merely seeds.

------

## 8. Minimum viable document control for ISO audit readiness

For a 1–20‑person company, you need a small, explicit set of features to be “audit‑ready” for document control.

## 8.1 Mandatory capabilities

- Unique document identification (doc number, title, version).
- Single source of truth for approved versions; only the current revision is available to users at point of use.
- Formal approval before release, with evidence of who approved and when.
- Change history and revision log: what changed and why.
- Periodic review mechanism with reminders and records.
- Obsolete document control (clearly marked, moved, or access‑restricted).
- Control of external documents: register of key customer and standard documents with version tracking.

## 8.2 “Nice to have but optional” for first audit

- Read‑acknowledgement tracking for critical documents.
- Automated linkage to nonconformities and corrective actions.
- AI gap analysis and drafting (can be positioned as productivity, not compliance).

------

## 9. Example field definitions (abbreviated)

## 9.1 Document fields

| Field                     | Type    | Description                                           |
| :------------------------ | :------ | :---------------------------------------------------- |
| id                        | UUID    | Primary key.                                          |
| org_id                    | UUID    | Tenant organization.                                  |
| doc_number                | String  | Human document number, unique per org.                |
| title                     | String  | Human‑readable title.                                 |
| doc_type                  | Enum    | POLICY, PROCEDURE, WI, FORM, SPEC, TEMPLATE, OTHER.   |
| owner_user_id             | UUID    | Person responsible for content.                       |
| status                    | Enum    | DRAFT, IN_REVIEW, PENDING_APPROVAL, ACTIVE, OBSOLETE. |
| current_revision_id       | UUID    | Latest ACTIVE revision.                               |
| external                  | Boolean | True if external origin (customer or standard).       |
| effective_date            | Date    | Date current revision became effective.               |
| superseded_by_document_id | UUID    | If replaced by another document.                      |

## 9.2 DocumentRevision fields

| Field          | Type     | Description                                             |
| :------------- | :------- | :------------------------------------------------------ |
| id             | UUID     | Primary key.                                            |
| document_id    | UUID     | Parent document.                                        |
| revision_code  | String   | Display code (A, B, C…).                                |
| revision_index | Int      | Monotonic integer.                                      |
| status         | Enum     | DRAFT, IN_REVIEW, PENDING_APPROVAL, ACTIVE, SUPERSEDED. |
| change_summary | String   | One‑line description of changes.                        |
| change_reason  | String   | Why change was made.                                    |
| effective_date | Date     | Effective if ACTIVE.                                    |
| approver_ids   | Array    | User IDs of approvers.                                  |
| approved_at    | Datetime | Final approval timestamp.                               |

------

## 10. Putting it together

A typical small‑business deployment for ISO 9001:

- Uses SharePoint or Google Drive as the file store with versioning turned on and a dedicated “Controlled Documents” library/folder.
- Uses your application as the authoritative metadata/workflow layer with schemas above.
- Implements a slim, opinionated UX:
  - “New document” wizard → AI draft (optional) → human edit → send for review → approve → distribute.
  - “Change request” wizard for any modification, feeding impact assessment and new revision flow.
- Provides audit‑friendly reports: document list with status and revision, change log, review schedule compliance, and sample trails of approvals for a few documents, covering the ISO 9001 clause 7.5 expectations without overwhelming a 5‑person shop.

You can expand each section above into ~1–2 pages of implementation notes, UI sketches, and API/DB specifics to reach your 15–25 page internal spec.