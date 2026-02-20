A minimal, audit-ready CAPA module for 1–20‑person companies should center on a single “CAPA record” that ties together the nonconformance, root cause analysis, corrective actions, and effectiveness verification in a closed-loop workflow that follows ISO 9001:2015 clause 10.2 expectations.

------

## 1. Core Entities and Data Structures

## 1.1 Nonconformance / CAPA Header

Treat “Nonconformance Report (NCR)” and “CAPA” as one record with flags that allow you to support simple correction-only NCRs vs full CAPAs. ISO 9001 expects you to record the nature of nonconformities and subsequent actions at minimum.

**Entity: CapaRecord**

```
json{
  "$id": "CapaRecord",
  "type": "object",
  "required": [
    "id",
    "number",
    "title",
    "reported_date",
    "reported_by_id",
    "source_type",
    "status",
    "containment_required"
  ],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "number": { "type": "string", "description": "Human readable e.g. CAPA-2026-001" },
    "title": { "type": "string", "maxLength": 200 },
    "description": { "type": "string" },
    "reported_date": { "type": "string", "format": "date-time" },
    "reported_by_id": { "type": "string", "format": "uuid" },
    "department": { "type": "string" },
    "source_type": {
      "type": "string",
      "enum": [
        "customer_complaint",
        "internal_audit",
        "external_audit",
        "production_nonconformance",
        "supplier_nonconformance",
        "service_failure",
        "near_miss",
        "risk_identification",
        "management_review",
        "other"
      ]
    },
    "source_reference": {
      "type": "string",
      "description": "Link to complaint, audit, WO, job, etc."
    },
    "product_or_service": { "type": "string" },
    "serial_or_lot": { "type": "string" },
    "customer_id": { "type": "string", "format": "uuid" },
    "severity": {
      "type": "string",
      "enum": ["low", "medium", "high", "critical"]
    },
    "occurrence_frequency": {
      "type": "string",
      "enum": ["rare", "occasional", "frequent"],
      "description": "For risk-based thinking"
    },
    "risk_rating": {
      "type": "integer",
      "minimum": 1,
      "maximum": 9,
      "description": "Simple severity x occurrence matrix"
    },
    "status": {
      "type": "string",
      "enum": [
        "draft",
        "open",
        "under_investigation",
        "actions_planned",
        "actions_implemented",
        "pending_effectiveness_review",
        "closed_effective",
        "closed_ineffective",
        "cancelled"
      ]
    },
    "priority": {
      "type": "string",
      "enum": ["p1", "p2", "p3"]
    },
    "capa_required": {
      "type": "boolean",
      "description": "True if full corrective action is required vs simple correction"
    },
    "preventive_action_flag": {
      "type": "boolean",
      "description": "True if this is mainly preventive (potential nonconformity)"
    },
    "containment_required": { "type": "boolean" },
    "containment_summary": { "type": "string" },
    "containment_completed_at": { "type": "string", "format": "date-time" },
    "containment_responsible_id": { "type": "string", "format": "uuid" },
    "due_date": { "type": "string", "format": "date-time" },
    "owner_id": { "type": "string", "format": "uuid" },
    "approver_id": { "type": "string", "format": "uuid" },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" },
    "closed_at": { "type": "string", "format": "date-time" },
    "closure_comment": { "type": "string" },
    "qms_impact": {
      "type": "object",
      "properties": {
        "procedure_change_required": { "type": "boolean" },
        "training_required": { "type": "boolean" },
        "risk_register_update_required": { "type": "boolean" }
      }
    },
    "tags": {
      "type": "array",
      "items": { "type": "string" }
    },
    "audit_trail": {
      "type": "array",
      "items": { "$ref": "AuditEntry" }
    }
  }
}
```

**Entity: AuditEntry** (generic, reused with other modules)

```
json{
  "$id": "AuditEntry",
  "type": "object",
  "required": ["timestamp", "user_id", "action", "field_changes"],
  "properties": {
    "timestamp": { "type": "string", "format": "date-time" },
    "user_id": { "type": "string", "format": "uuid" },
    "action": {
      "type": "string",
      "description": "e.g., status_change, field_update, comment_added"
    },
    "field_changes": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["field", "old_value", "new_value"],
        "properties": {
          "field": { "type": "string" },
          "old_value": {},
          "new_value": {}
        }
      }
    },
    "comment": { "type": "string" }
  }
}
```

This satisfies the requirement to retain documented information on the nature of nonconformities and results of corrective actions.

------

## 2. Root Cause Analysis Structures

ISO 9001 expects evaluation of causes, including whether similar nonconformities exist or could potentially occur. Your module can support flexible methods but persist them in simple schemas.

## 2.1 RootCauseAnalysis (summary)

```
json{
  "$id": "RootCauseAnalysis",
  "type": "object",
  "required": ["id", "capa_id", "method", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "capa_id": { "type": "string", "format": "uuid" },
    "method": {
      "type": "string",
      "enum": ["five_why", "fishbone", "custom"]
    },
    "problem_statement": { "type": "string" },
    "primary_root_cause": { "type": "string" },
    "contributing_factors": {
      "type": "array",
      "items": { "type": "string" }
    },
    "similar_issues_review": {
      "type": "string",
      "description": "Notes on whether similar nonconformities exist or could occur"
    },
    "completed_by_id": { "type": "string", "format": "uuid" },
    "completed_at": { "type": "string", "format": "date-time" },
    "status": {
      "type": "string",
      "enum": ["not_started", "in_progress", "completed", "approved"]
    },
    "attachments": {
      "type": "array",
      "items": { "$ref": "Attachment" }
    },
    "ai_assist_metadata": {
      "type": "object",
      "properties": {
        "root_cause_suggestions": {
          "type": "array",
          "items": { "type": "string" }
        },
        "accepted_suggestion_index": { "type": "integer" }
      }
    }
  }
}
```

**Attachment** can be reused from your document control or ticketing modules (file id, filename, mime type, source).

## 2.2 5‑Why Data Structure

```
json{
  "$id": "FiveWhyAnalysis",
  "type": "object",
  "required": ["id", "root_cause_analysis_id"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "root_cause_analysis_id": {
      "type": "string",
      "format": "uuid"
    },
    "chain": {
      "type": "array",
      "description": "Ordered WHY chain",
      "items": {
        "type": "object",
        "required": ["order", "why", "answer"],
        "properties": {
          "order": { "type": "integer", "minimum": 1 },
          "why": { "type": "string" },
          "answer": { "type": "string" },
          "evidence": { "type": "string" },
          "created_by_id": { "type": "string", "format": "uuid" },
          "created_at": { "type": "string", "format": "date-time" }
        }
      }
    },
    "final_root_cause": { "type": "string" }
  }
}
```

This supports a minimal but structured 5‑Why chain that an auditor can follow from problem to root cause.

## 2.3 Fishbone (Ishikawa) Data Structure

Use fixed or configurable categories (e.g., Methods, Machines, Materials, Manpower, Measurement, Environment) but keep the persistence generic.

```
json{
  "$id": "FishboneAnalysis",
  "type": "object",
  "required": ["id", "root_cause_analysis_id"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "root_cause_analysis_id": {
      "type": "string",
      "format": "uuid"
    },
    "categories": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["name"],
        "properties": {
          "name": {
            "type": "string",
            "description": "e.g., Methods, Machines, People"
          },
          "factors": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["description"],
              "properties": {
                "description": { "type": "string" },
                "evidence": { "type": "string" },
                "is_primary_cause": { "type": "boolean" }
              }
            }
          }
        }
      }
    },
    "primary_cause_category": { "type": "string" },
    "primary_cause_factor": { "type": "string" }
  }
}
```

You can link both 5‑Why and Fishbone to the same RootCauseAnalysis record, allowing teams to use either or both methods depending on complexity.

------

## 3. Corrective and Preventive Actions

ISO 9001 requires implementing actions needed, reviewing effectiveness, and updating risks/opportunities and the QMS as necessary.

## 3.1 CorrectiveActionItem

```
json{
  "$id": "CorrectiveActionItem",
  "type": "object",
  "required": ["id", "capa_id", "type", "description", "status"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "capa_id": { "type": "string", "format": "uuid" },
    "type": {
      "type": "string",
      "enum": [
        "correction",
        "corrective_action",
        "preventive_action",
        "containment"
      ]
    },
    "description": { "type": "string" },
    "linked_root_cause": { "type": "string" },
    "responsible_id": { "type": "string", "format": "uuid" },
    "due_date": { "type": "string", "format": "date-time" },
    "completed_at": { "type": "string", "format": "date-time" },
    "status": {
      "type": "string",
      "enum": ["not_started", "in_progress", "completed", "cancelled"]
    },
    "effect_on_product": {
      "type": "string",
      "description": "Note on possible adverse effects"
    },
    "requires_validation": { "type": "boolean" },
    "validation_summary": { "type": "string" },
    "cost_estimate": { "type": "number" },
    "attachments": {
      "type": "array",
      "items": { "$ref": "Attachment" }
    },
    "document_changes": {
      "type": "array",
      "description": "Links to document change requests",
      "items": { "$ref": "DocumentChangeLink" }
    },
    "training_actions": {
      "type": "array",
      "items": { "$ref": "TrainingActionLink" }
    }
  }
}
```

**DocumentChangeLink** and **TrainingActionLink** are small linking structures that tie into your document control and training modules.

```
json{
  "$id": "DocumentChangeLink",
  "type": "object",
  "required": ["document_id"],
  "properties": {
    "document_id": { "type": "string", "format": "uuid" },
    "change_request_id": { "type": "string", "format": "uuid" },
    "note": { "type": "string" }
  }
}
json{
  "$id": "TrainingActionLink",
  "type": "object",
  "required": ["training_item_id"],
  "properties": {
    "training_item_id": { "type": "string", "format": "uuid" },
    "note": { "type": "string" },
    "completed_at": { "type": "string", "format": "date-time" }
  }
}
```

This allows auditable linkage between CAPA, procedure changes, and training, supporting the requirement to update the management system and ensure staff are aware of changes.

------

## 4. Effectiveness Verification

ISO 9001 clause 10.2 requires reviewing the effectiveness of any corrective action taken. Keep this explicit instead of burying it in free-text closures.

## 4.1 EffectivenessReview

```
json{
  "$id": "EffectivenessReview",
  "type": "object",
  "required": [
    "id",
    "capa_id",
    "planned_review_date",
    "status",
    "review_type"
  ],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "capa_id": { "type": "string", "format": "uuid" },
    "review_type": {
      "type": "string",
      "enum": [
        "data_trend_review",
        "sample_check",
        "audit_check",
        "customer_feedback",
        "other"
      ]
    },
    "planned_review_date": { "type": "string", "format": "date-time" },
    "actual_review_date": { "type": "string", "format": "date-time" },
    "reviewer_id": { "type": "string", "format": "uuid" },
    "criteria": {
      "type": "string",
      "description": "How will we judge effectiveness?"
    },
    "metrics_snapshot": {
      "type": "object",
      "description": "Optional JSON of before/after metrics"
    },
    "result": {
      "type": "string",
      "enum": ["effective", "ineffective", "partially_effective"]
    },
    "evidence": { "type": "string" },
    "follow_up_required": { "type": "boolean" },
    "follow_up_capa_id": {
      "type": "string",
      "format": "uuid",
      "description": "Link to new CAPA when actions are ineffective"
    },
    "ai_effectiveness_score": {
      "type": "number",
      "minimum": 0,
      "maximum": 1
    },
    "ai_explanation": { "type": "string" }
  }
}
```

This enables a closed-loop CAPA where ineffective actions can spawn new CAPAs or adjustments.

------

## 5. Workflow and State Machines

## 5.1 High-Level CAPA Workflow

The workflow should map tightly to ISO 9001 clause 10.2 steps: react to nonconformity, evaluate causes, implement actions, review effectiveness, and update QMS as needed.

**Workflow states (CapaRecord.status):**

1. draft
2. open
3. under_investigation
4. actions_planned
5. actions_implemented
6. pending_effectiveness_review
7. closed_effective
8. closed_ineffective
9. cancelled

**State machine (simplified):**

| From                           | Event / Guard                                      | To                                                 |
| :----------------------------- | :------------------------------------------------- | :------------------------------------------------- |
| draft                          | submit (owner set, containment_required evaluated) | open                                               |
| open                           | containment completed                              | under_investigation                                |
| open                           | mark no CAPA needed (e.g., trivial)                | closed_effective                                   |
| under_investigation            | root cause analysis completed & approved           | actions_planned                                    |
| actions_planned                | all actions assigned & due dates set               | actions_implemented (when all marked completed)    |
| actions_implemented            | schedule effectiveness review                      | pending_effectiveness_review                       |
| pending_effectiveness_review   | reviewer marks effective                           | closed_effective                                   |
| pending_effectiveness_review   | reviewer marks ineffective                         | closed_ineffective (and optionally spawn new CAPA) |
| any (except closed, cancelled) | cancel (with reason)                               | cancelled                                          |

**Minimal validation rules:**

- Cannot move to actions_planned until RootCauseAnalysis.status = “completed” or “approved” if capa_required = true.
- Cannot move to actions_implemented until all CorrectiveActionItem.status ∈ {“completed”, “cancelled”}.
- Cannot close as effective until there is at least one EffectivenessReview with result = “effective”.

This enforces a simple closed-loop CAPA system as recommended in CAPA guidance and ISO‑aligned best practices.

## 5.2 Root Cause Workflow

**RootCauseAnalysis.status:**

- not_started → in_progress → completed → approved

Approval can be optional in small teams but is helpful in audited contexts.

## 5.3 Action Item Workflow

**CorrectiveActionItem.status:**

- not_started → in_progress → completed or cancelled

A lightweight task engine is enough for shops with 1–20 employees.

------

## 6. Quality Metrics and Trending

ISO 9001 requires monitoring and measurement of processes and the effectiveness of actions. For small companies, a minimal metrics set is ideal:

## 6.1 Aggregated Metrics

**Entity: CapaMetricSnapshot** (optional precomputed)

```
json{
  "$id": "CapaMetricSnapshot",
  "type": "object",
  "required": ["id", "period_start", "period_end"],
  "properties": {
    "id": { "type": "string", "format": "uuid" },
    "period_start": { "type": "string", "format": "date-time" },
    "period_end": { "type": "string", "format": "date-time" },
    "total_nonconformances": { "type": "integer" },
    "total_capas": { "type": "integer" },
    "open_capas": { "type": "integer" },
    "overdue_capas": { "type": "integer" },
    "average_closure_days": { "type": "number" },
    "percent_effective_at_first_review": { "type": "number" },
    "by_source_type": {
      "type": "object",
      "description": "Key = source_type, value = count"
    },
    "by_severity": {
      "type": "object",
      "description": "Key = severity, value = count"
    }
  }
}
```

Core trend metrics:

- Number of nonconformances per month by source (complaints, internal audits, production, suppliers).
- CAPA closure time (average days from reported_date to closed_at).
- Overdue CAPAs and high-risk CAPAs still open.
- Effectiveness rate (percentage of CAPAs closed effective on first review).

These metrics can feed dashboards and AI models for effectiveness predictions.

------

## 7. Document Control Integration

Clause 10.2 explicitly expects updating risks, opportunities, and the QMS when nonconformities reveal needed changes. You already have a document control module, so CAPA should only reference it.

## 7.1 Linking CAPA to Documents

- CapaRecord.qms_impact.procedure_change_required → if true, at least one CorrectiveActionItem with type = “corrective_action” should include a DocumentChangeLink.
- DocumentChangeLink.document_id should point to a controlled document (procedure, WI, form).
- Your document control module should allow “Change initiated by CAPA XXX” metadata, closing the loop.

**Minimal integration pattern:**

- From CAPA UI, “Create procedure change” button calls document control service to create a DocumentChangeRequest with a foreign key back to CapaRecord.id.
- DocumentControl stores revision history, approvals, and when published, sends a webhook/notification back to CAPA to mark the related DocumentChangeLink as completed.

This ensures auditors see that CAPAs lead to systemic changes where appropriate.

------

## 8. AI Assistance Design

AI features should stay assistive, not autonomous, and every suggestion should map to fields you already defined.

## 8.1 Root Cause Suggestions

**Input payload example (to your LLM service):**

- problem_statement (from RootCauseAnalysis)
- nonconformance description, product, customer, severity
- recent similar CAPAs (title, primary_root_cause, actions that were effective)
- fishbone categories and any populated factors
- 5‑Why chain so far

**Output mapped into RootCauseAnalysis.ai_assist_metadata:**

- root_cause_suggestions: array of suggested root cause descriptions.
- optional recommended fishbone category assignments and 5‑Why next question.

You store only a small subset:

```
json"ai_assist_metadata": {
  "root_cause_suggestions": [
    "Inadequate work instruction for step 3",
    "No incoming inspection for supplier part ABC"
  ],
  "accepted_suggestion_index": 0
}
```

User acceptance is required; this gives you an audit trail that humans reviewed AI suggestions.

## 8.2 CAPA Action Suggestions

AI can suggest candidate CorrectiveActionItem objects:

- For each root cause, propose 1–3 actions: document updates, training, process checks, supplier actions.
- User can “Add to plan” which creates CorrectiveActionItem records with type and description prefilled.

Keep AI suggestions out of required core fields unless confirmed by a user; store only accepted actions.

## 8.3 Effectiveness Prediction

Using simple models or heuristic rules on your small dataset, you can predict ai_effectiveness_score in EffectivenessReview or directly on CapaRecord.

Input features:

- severity, risk_rating
- number of prior similar CAPAs and their effectiveness
- whether document changes and training are included
- closure time vs target

Output:

- ai_effectiveness_score in
- ai_explanation text like “Similar high‑severity CAPAs without procedure changes were ineffective in 3 of 4 cases; consider updating WI‑003.”

This keeps AI squarely in advisory territory while showing risk-based prioritization.

------

## 9. Minimal Audit‑Ready Design

ISO 9001 auditors primarily want to see that you follow a defined, consistent process for nonconformity and corrective action, and that you retain evidence. For small businesses, a minimal system should:

- Capture:
  - What went wrong (CapaRecord: title, description, source_type, severity).
  - When and who (reported_date, reported_by, owner, audit_trail).
- React:
  - Immediate correction/containment documented as CorrectiveActionItem type = “correction” or “containment”.
- Investigate:
  - RootCauseAnalysis with either 5‑Why or Fishbone artifacts.
- Act:
  - One or more CorrectiveActionItem and/or preventive actions, with responsibilities and due dates.
- Verify:
  - EffectivenessReview with objective criteria and result.
- Update QMS:
  - DocumentChangeLink to procedures or work instructions, plus TrainingActionLink where applicable.
- Monitor:
  - Basic metrics: count, closure time, overdue, effectiveness rate, by source and severity.

If the system can export a “Nonconformance / CAPA Register” listing these data for a date range, you satisfy typical expectations for documented information on nonconformities and corrective actions.

------

## 10. Key Field Definitions (Short List)

Below is a concise table of critical fields and meanings.

| Field                     | Entity                | Purpose                                                      |
| :------------------------ | :-------------------- | :----------------------------------------------------------- |
| number                    | CapaRecord            | Human-readable CAPA/NCR ID for referencing in meetings and audits. |
| source_type               | CapaRecord            | Origin of issue (complaint, internal audit, etc.).           |
| severity                  | CapaRecord            | Impact level driving priority and action depth.              |
| risk_rating               | CapaRecord            | Simple score for risk-based thinking (severity × occurrence). |
| capa_required             | CapaRecord            | Distinguish simple corrections from full corrective action.  |
| method                    | RootCauseAnalysis     | Selected analysis method (5‑Why, Fishbone).                  |
| primary_root_cause        | RootCauseAnalysis     | Short statement of main cause to eliminate.                  |
| type                      | CorrectiveActionItem  | correction / corrective / preventive / containment.          |
| status                    | CapaRecord & Actions  | Drives workflow and dashboards.                              |
| result                    | EffectivenessReview   | effective / ineffective / partially_effective.               |
| procedure_change_required | CapaRecord.qms_impact | Flag that CAPA reveals need for documented process change.   |
| ai_effectiveness_score    | EffectivenessReview   | Optional AI prediction used for prioritization, not compliance. |