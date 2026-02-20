# Project Management Module — Technical Specification

**Target audience:** Small service businesses (1–10 employees)
**Design philosophy:** Capture the essential 20% of MS Project/Asana that delivers 80% of the value

------

## 1. Architecture Overview

This module is designed as a lightweight, opinionated project management system for service businesses like landscaping crews, HVAC shops, marketing consultancies, and IT service firms. The core premise: a 3-person plumbing company doesn't need earned value management, resource leveling algorithms, or portfolio optimization — they need to know *what's due, who's doing it, and whether they're on track*.

The system is built around five core entities: **Projects**, **Tasks**, **Milestones**, **Dependencies**, and **Resource Assignments**. All data is stored as JSON-compatible documents, making it suitable for both relational (PostgreSQL) and document (MongoDB/Firestore) databases.

------

## 2. Core Data Structures

## 2.1 Project Schema

The `Project` is the top-level container. For a small business, a project maps to a client engagement, job, or contract.

```
json{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Project",
  "type": "object",
  "required": ["project_id", "name", "status", "start_date", "owner_id"],
  "properties": {
    "project_id": {
      "type": "string",
      "format": "uuid",
      "description": "Globally unique identifier for the project"
    },
    "name": {
      "type": "string",
      "minLength": 1,
      "maxLength": 200,
      "description": "Human-readable project name, e.g. 'Smith Kitchen Remodel'"
    },
    "description": {
      "type": "string",
      "maxLength": 2000,
      "description": "Free-text project description and scope notes"
    },
    "status": {
      "type": "string",
      "enum": ["planning", "active", "on_hold", "completed", "cancelled"],
      "description": "Current lifecycle stage of the project"
    },
    "priority": {
      "type": "string",
      "enum": ["low", "medium", "high", "urgent"],
      "default": "medium"
    },
    "start_date": {
      "type": "string",
      "format": "date",
      "description": "Planned or actual start date (ISO 8601)"
    },
    "target_end_date": {
      "type": "string",
      "format": "date",
      "description": "Contractual or promised delivery date"
    },
    "actual_end_date": {
      "type": ["string", "null"],
      "format": "date",
      "description": "Actual completion date; null if still in progress"
    },
    "owner_id": {
      "type": "string",
      "format": "uuid",
      "description": "User ID of the project owner / lead"
    },
    "client": {
      "type": "object",
      "properties": {
        "client_id": { "type": "string", "format": "uuid" },
        "client_name": { "type": "string" },
        "contact_email": { "type": "string", "format": "email" }
      },
      "description": "Client reference for service businesses"
    },
    "budget": {
      "type": "object",
      "properties": {
        "estimated_hours": { "type": "number", "minimum": 0 },
        "estimated_cost": { "type": "number", "minimum": 0 },
        "actual_hours": { "type": "number", "minimum": 0, "default": 0 },
        "actual_cost": { "type": "number", "minimum": 0, "default": 0 }
      },
      "description": "Simple budget tracking — hours and dollars only"
    },
    "tags": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Freeform tags for filtering, e.g. ['residential','plumbing']"
    },
    "google_calendar_id": {
      "type": ["string", "null"],
      "description": "Linked Google Calendar ID for syncing milestones/deadlines"
    },
    "google_sheet_id": {
      "type": ["string", "null"],
      "description": "Linked Google Sheet ID for reporting exports"
    },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
```

**Field-level notes:**

- `status` uses a simple five-state lifecycle. MS Project supports custom fields and dozens of states; small teams only need five.
- `budget` is intentionally flat — no multi-currency, no cost accrual methods. Just hours and dollars.
- `google_calendar_id` and `google_sheet_id` enable the integrations detailed in Section 6.

------

## 2.2 Task Schema

Tasks are the fundamental unit of work. Each task belongs to exactly one project.

```
json{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Task",
  "type": "object",
  "required": ["task_id", "project_id", "name", "status"],
  "properties": {
    "task_id": {
      "type": "string",
      "format": "uuid",
      "description": "Globally unique task identifier"
    },
    "project_id": {
      "type": "string",
      "format": "uuid",
      "description": "Parent project reference"
    },
    "parent_task_id": {
      "type": ["string", "null"],
      "format": "uuid",
      "description": "For one level of subtask nesting only; null = top-level task"
    },
    "name": {
      "type": "string",
      "minLength": 1,
      "maxLength": 300
    },
    "description": {
      "type": "string",
      "maxLength": 5000,
      "description": "Detailed work instructions, notes, or acceptance criteria"
    },
    "status": {
      "type": "string",
      "enum": ["not_started", "in_progress", "blocked", "completed", "skipped"],
      "default": "not_started"
    },
    "priority": {
      "type": "string",
      "enum": ["low", "medium", "high", "urgent"],
      "default": "medium"
    },
    "is_milestone": {
      "type": "boolean",
      "default": false,
      "description": "If true, this task is a milestone (zero-duration checkpoint)"
    },
    "estimated_hours": {
      "type": "number",
      "minimum": 0,
      "description": "Estimated work effort in hours"
    },
    "actual_hours": {
      "type": "number",
      "minimum": 0,
      "default": 0
    },
    "percent_complete": {
      "type": "integer",
      "minimum": 0,
      "maximum": 100,
      "default": 0,
      "description": "Manual or calculated completion percentage"
    },
    "planned_start": {
      "type": ["string", "null"],
      "format": "date",
      "description": "Scheduled start date"
    },
    "planned_end": {
      "type": ["string", "null"],
      "format": "date",
      "description": "Scheduled end/due date"
    },
    "actual_start": {
      "type": ["string", "null"],
      "format": "date"
    },
    "actual_end": {
      "type": ["string", "null"],
      "format": "date"
    },
    "assignees": {
      "type": "array",
      "items": { "type": "string", "format": "uuid" },
      "maxItems": 5,
      "description": "User IDs of people assigned to this task"
    },
    "sort_order": {
      "type": "integer",
      "description": "Display order within the project task list"
    },
    "notes": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "note_id": { "type": "string", "format": "uuid" },
          "author_id": { "type": "string", "format": "uuid" },
          "content": { "type": "string", "maxLength": 2000 },
          "created_at": { "type": "string", "format": "date-time" }
        }
      },
      "description": "Chronological activity log / comments"
    },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  }
}
```

**Design decisions:**

- **One level of subtasks only.** MS Project supports unlimited WBS depth; for a small service business, parent → child is sufficient. Deep nesting adds complexity without value at this scale.
- **`assignees` is an array** because in a 3-person shop, two people might share a task. Capped at 5 to prevent the "assigned to everyone = assigned to nobody" problem.
- **`is_milestone`** is a boolean flag on the task rather than a separate entity, reducing schema complexity while preserving the concept.

------

## 2.3 Milestone (Realized as Task)

Milestones are zero-duration checkpoints that mark significant project events (e.g., "Client sign-off," "Permit approved"). Rather than a separate table, milestones are tasks with `is_milestone: true`.

```
json{
  "task_id": "m-550e8400-e29b-41d4-a716-446655440000",
  "project_id": "p-123",
  "name": "Client Final Approval",
  "is_milestone": true,
  "status": "not_started",
  "planned_end": "2026-04-15",
  "estimated_hours": 0,
  "assignees": ["user-owner-001"],
  "description": "Client reviews completed work and signs acceptance form"
}
```

When `is_milestone` is `true`, the UI renders a diamond icon, `estimated_hours` is forced to `0`, and `planned_start` equals `planned_end`.

------

## 2.4 Dependency Schema

Dependencies define the execution order between tasks. The standard four dependency types from project management theory apply:

```
json{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Dependency",
  "type": "object",
  "required": ["dependency_id", "project_id", "predecessor_task_id",
               "successor_task_id", "type"],
  "properties": {
    "dependency_id": {
      "type": "string",
      "format": "uuid"
    },
    "project_id": {
      "type": "string",
      "format": "uuid"
    },
    "predecessor_task_id": {
      "type": "string",
      "format": "uuid",
      "description": "The task that must satisfy the dependency condition"
    },
    "successor_task_id": {
      "type": "string",
      "format": "uuid",
      "description": "The task that is constrained by the dependency"
    },
    "type": {
      "type": "string",
      "enum": ["FS", "FF", "SS", "SF"],
      "default": "FS",
      "description": "FS=Finish-to-Start, FF=Finish-to-Finish, SS=Start-to-Start, SF=Start-to-Finish"
    },
    "lag_days": {
      "type": "integer",
      "default": 0,
      "description": "Offset in working days. Positive = lag (delay), Negative = lead (overlap)"
    },
    "created_at": { "type": "string", "format": "date-time" }
  }
}
```

**Dependency type reference**:

| Type | Name             | Meaning                         | Example                                      |
| :--- | :--------------- | :------------------------------ | :------------------------------------------- |
| FS   | Finish-to-Start  | B can't start until A finishes  | Pour concrete → Frame walls                  |
| FF   | Finish-to-Finish | B can't finish until A finishes | Testing finishes when coding finishes        |
| SS   | Start-to-Start   | B can't start until A starts    | Digging and shoring start together           |
| SF   | Start-to-Finish  | B can't finish until A starts   | Rare; night shift ends when day shift starts |

**For the MVP, implement FS only.** Over 90% of real-world task dependencies are Finish-to-Start. Add FF, SS, SF in a later phase.

------

## 2.5 Resource / Team Member Schema

In a 1–10 person business, "resources" are just the team members.

```
json{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Resource",
  "type": "object",
  "required": ["user_id", "name", "email", "role"],
  "properties": {
    "user_id": {
      "type": "string",
      "format": "uuid"
    },
    "name": {
      "type": "string",
      "maxLength": 150
    },
    "email": {
      "type": "string",
      "format": "email"
    },
    "role": {
      "type": "string",
      "enum": ["owner", "manager", "member", "contractor"],
      "description": "owner = business owner, contractor = external/temp help"
    },
    "hourly_rate": {
      "type": "number",
      "minimum": 0,
      "description": "Used for cost estimation; optional"
    },
    "weekly_capacity_hours": {
      "type": "number",
      "minimum": 0,
      "maximum": 168,
      "default": 40,
      "description": "Available hours per week for scheduling"
    },
    "skills": {
      "type": "array",
      "items": { "type": "string" },
      "description": "Freeform skill tags, e.g. ['electrical','plumbing','permits']"
    },
    "google_calendar_email": {
      "type": ["string", "null"],
      "format": "email",
      "description": "Google account for calendar sync"
    },
    "is_active": {
      "type": "boolean",
      "default": true
    }
  }
}
```

## 2.6 Resource Assignment Schema

Assignments link resources to tasks with allocation detail:

```
json{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ResourceAssignment",
  "type": "object",
  "required": ["assignment_id", "task_id", "user_id"],
  "properties": {
    "assignment_id": {
      "type": "string",
      "format": "uuid"
    },
    "task_id": {
      "type": "string",
      "format": "uuid"
    },
    "user_id": {
      "type": "string",
      "format": "uuid"
    },
    "allocated_hours": {
      "type": "number",
      "minimum": 0,
      "description": "Planned hours this person will spend on this task"
    },
    "logged_hours": {
      "type": "number",
      "minimum": 0,
      "default": 0,
      "description": "Actual hours recorded"
    },
    "assignment_role": {
      "type": "string",
      "enum": ["lead", "contributor", "reviewer"],
      "default": "contributor",
      "description": "Role on this specific task"
    },
    "created_at": { "type": "string", "format": "date-time" }
  }
}
```

------

## 3. Entity Relationship Summary

```
textProject  1 ──── * Task
Task     1 ──── * Task          (one level: parent_task_id)
Task     1 ──── * Dependency    (as predecessor or successor)
Task     * ──── * Resource      (via ResourceAssignment)
Project  1 ──── * Milestone     (milestone = task with is_milestone=true)
```

A `Project` contains many `Tasks`. Tasks may optionally reference one parent task for a single level of grouping. `Dependencies` connect pairs of tasks within a project. `ResourceAssignments` form the many-to-many relationship between tasks and team members.

------

## 4. Scheduling Logic

## 4.1 Simplified Critical Path Method

The Critical Path Method (CPM) identifies the longest chain of dependent tasks, which determines the minimum project duration. Any delay on a critical-path task delays the entire project.

**Algorithm (Forward and Backward Pass):**

**Step 1 — Build the dependency graph.** Construct a directed acyclic graph (DAG) where each node is a task and each edge is an FS dependency.

**Step 2 — Forward pass (calculate Early Start / Early Finish):**

```
textFor each task in topological order:
    ES(task) = max( EF(predecessor) + lag_days ) for all predecessors
    EF(task) = ES(task) + duration_days
    If no predecessors: ES = project.start_date
```

**Step 3 — Backward pass (calculate Late Start / Late Finish):**

```
textFor each task in reverse topological order:
    LF(task) = min( LS(successor) - lag_days ) for all successors
    LS(task) = LF(task) - duration_days
    If no successors: LF = project.target_end_date (or max EF)
```

**Step 4 — Calculate float (slack):**

```
textTotal Float = LS(task) - ES(task)   // or equivalently LF - EF
Tasks with Total Float = 0 are on the critical path
```

**Pseudocode implementation:**

```
pythondef compute_critical_path(tasks, dependencies):
    # Build adjacency list (FS dependencies only)
    graph = {t.task_id: [] for t in tasks}
    reverse_graph = {t.task_id: [] for t in tasks}
    for dep in dependencies:
        graph[dep.predecessor_task_id].append(
            (dep.successor_task_id, dep.lag_days)
        )
        reverse_graph[dep.successor_task_id].append(
            (dep.predecessor_task_id, dep.lag_days)
        )

    duration = {t.task_id: t.estimated_hours / 8 for t in tasks}  # hours → days

    # Forward pass
    ES, EF = {}, {}
    for task_id in topological_sort(graph):
        predecessors = reverse_graph[task_id]
        if not predecessors:
            ES[task_id] = 0
        else:
            ES[task_id] = max(EF[pred] + lag for pred, lag in predecessors)
        EF[task_id] = ES[task_id] + duration[task_id]

    project_duration = max(EF.values())

    # Backward pass
    LS, LF = {}, {}
    for task_id in reversed(topological_sort(graph)):
        successors = graph[task_id]
        if not successors:
            LF[task_id] = project_duration
        else:
            LF[task_id] = min(LS[succ] - lag for succ, lag in successors)
        LS[task_id] = LF[task_id] - duration[task_id]

    # Identify critical path
    float_values = {}
    critical_path = []
    for t in tasks:
        float_values[t.task_id] = LS[t.task_id] - ES[t.task_id]
        if float_values[t.task_id] == 0:
            critical_path.append(t.task_id)

    return critical_path, float_values, project_duration
```

**Key simplifications vs. MS Project**:

- Only FS dependencies (no FF/SS/SF in the scheduling engine for MVP)
- No resource leveling — doesn't auto-resolve overallocation
- No calendar exceptions (holidays, custom work weeks) — assumes 5-day weeks
- Duration = `estimated_hours / 8` (simple conversion, no partial-day logic)

------

## 4.2 Deadline Tracking Engine

The deadline tracker runs as a scheduled job (cron) or on-demand recalculation, producing alerts:

```
json{
  "title": "DeadlineAlert",
  "type": "object",
  "properties": {
    "alert_id": { "type": "string", "format": "uuid" },
    "project_id": { "type": "string", "format": "uuid" },
    "task_id": { "type": ["string", "null"], "format": "uuid" },
    "alert_type": {
      "type": "string",
      "enum": [
        "task_overdue",
        "task_due_soon",
        "milestone_at_risk",
        "project_deadline_at_risk",
        "dependency_blocked"
      ]
    },
    "severity": {
      "type": "string",
      "enum": ["info", "warning", "critical"]
    },
    "message": { "type": "string" },
    "days_until_due": { "type": "integer" },
    "generated_at": { "type": "string", "format": "date-time" }
  }
}
```

**Alert rules:**

| Condition                                                    | Alert Type                 | Severity |
| :----------------------------------------------------------- | :------------------------- | :------- |
| `planned_end < today` AND `status != completed`              | `task_overdue`             | critical |
| `planned_end` within 2 business days AND `percent_complete < 75` | `task_due_soon`            | warning  |
| Milestone's predecessors are overdue or behind               | `milestone_at_risk`        | critical |
| Critical path shows `EF > project.target_end_date`           | `project_deadline_at_risk` | critical |
| Task status = `blocked` for >1 day                           | `dependency_blocked`       | warning  |

------

## 5. Project Status and Health Indicators

## 5.1 Health Score Model

The project health indicator aggregates multiple signals into a single traffic-light status. This replaces the complex earned-value metrics (CPI, SPI) from MS Project with something a small-business owner can glance at.

```
json{
  "title": "ProjectHealth",
  "type": "object",
  "properties": {
    "project_id": { "type": "string", "format": "uuid" },
    "overall_health": {
      "type": "string",
      "enum": ["green", "yellow", "red"],
      "description": "green=on track, yellow=at risk, red=off track"
    },
    "schedule_health": { "type": "string", "enum": ["green", "yellow", "red"] },
    "budget_health": { "type": "string", "enum": ["green", "yellow", "red"] },
    "completion_percentage": { "type": "number" },
    "days_remaining": { "type": "integer" },
    "days_overdue": { "type": "integer", "default": 0 },
    "critical_path_slack_days": { "type": "number" },
    "overdue_task_count": { "type": "integer" },
    "blocked_task_count": { "type": "integer" },
    "calculated_at": { "type": "string", "format": "date-time" }
  }
}
```

## 5.2 Calculation Logic

```
pythondef calculate_project_health(project, tasks, critical_path_data):
    total_tasks = len([t for t in tasks if not t.is_milestone])
    completed = len([t for t in tasks if t.status == "completed"])
    overdue = len([t for t in tasks
                   if t.planned_end < today and t.status != "completed"])
    blocked = len([t for t in tasks if t.status == "blocked"])

    completion_pct = (completed / total_tasks * 100) if total_tasks else 0

    # Schedule health
    days_remaining = (project.target_end_date - today).days
    critical_slack = critical_path_data["min_slack_days"]

    if overdue == 0 and critical_slack > 2:
        schedule_health = "green"
    elif overdue <= 2 or (0 < critical_slack <= 2):
        schedule_health = "yellow"
    else:
        schedule_health = "red"

    # Budget health
    if project.budget.estimated_hours > 0:
        burn_rate = project.budget.actual_hours / project.budget.estimated_hours
        expected_rate = completion_pct / 100
        if burn_rate <= expected_rate * 1.1:
            budget_health = "green"
        elif burn_rate <= expected_rate * 1.3:
            budget_health = "yellow"
        else:
            budget_health = "red"
    else:
        budget_health = "green"  # No budget tracked

    # Overall = worst of schedule and budget
    health_rank = {"green": 0, "yellow": 1, "red": 2}
    overall = max([schedule_health, budget_health], key=lambda h: health_rank[h])

    return ProjectHealth(
        overall_health=overall,
        schedule_health=schedule_health,
        budget_health=budget_health,
        completion_percentage=round(completion_pct, 1),
        days_remaining=days_remaining,
        overdue_task_count=overdue,
        blocked_task_count=blocked,
        critical_path_slack_days=critical_slack
    )
```

## 5.3 Dashboard Metrics

The main project list view should surface these columns:

| Metric                  | Source                                 | Update Frequency          |
| :---------------------- | :------------------------------------- | :------------------------ |
| Health dot (🟢🟡🔴)        | `overall_health`                       | On any task status change |
| % Complete              | `completed_tasks / total_tasks`        | Real-time                 |
| Days Until Deadline     | `target_end_date - today`              | Daily                     |
| Overdue Tasks           | Count where `planned_end < today`      | Real-time                 |
| Hours Burned vs. Budget | `actual_hours / estimated_hours`       | On time log entry         |
| Next Milestone          | Nearest future milestone `planned_end` | Daily                     |

------

## 6. Google Workspace Integration

## 6.1 Google Calendar Integration

The Google Calendar API v3 `events.insert()` method requires `calendarId` and an event body with `start` and `end` as the only mandatory fields . The integration syncs milestones, task deadlines, and scheduled work blocks.

**Sync strategy:**

| Module Event              | Calendar Action                        | Event Fields                                           |
| :------------------------ | :------------------------------------- | :----------------------------------------------------- |
| Milestone created/updated | Upsert all-day event                   | `summary` = milestone name, `date` = planned_end       |
| Task with deadline        | Upsert reminder event                  | `summary` = task name, `description` = project context |
| Task assigned to user     | Create event on user's calendar        | Uses `google_calendar_email` from Resource             |
| Task completed            | Update event `colorId` or add ✅ prefix | PATCH existing event                                   |

**Event mapping to Google Calendar API:**

```
json{
  "summary": "[ProjectName] Milestone: Client Final Approval",
  "description": "Project: Smith Kitchen Remodel\nTask ID: m-550e8400\nStatus: not_started\n\nAuto-synced from ProjectModule",
  "start": {
    "date": "2026-04-15",
    "timeZone": "America/Chicago"
  },
  "end": {
    "date": "2026-04-15",
    "timeZone": "America/Chicago"
  },
  "reminders": {
    "useDefault": false,
    "overrides": [
      { "method": "popup", "minutes": 1440 },
      { "method": "popup", "minutes": 60 }
    ]
  },
  "extendedProperties": {
    "private": {
      "pm_task_id": "m-550e8400-e29b-41d4-a716-446655440000",
      "pm_project_id": "p-123",
      "pm_sync_version": "3"
    }
  }
}
```

**Key implementation details:**

- Use `extendedProperties.private` to store internal IDs, enabling two-way sync and conflict resolution.
- Store a `pm_sync_version` to detect stale writes.
- OAuth scope required: `https://www.googleapis.com/auth/calendar` .
- Use `events.patch()` for updates to minimize payload size.
- Rate limiting: batch requests when syncing multiple tasks; Google Calendar API allows ~10 requests/second per user.

**Sync flow pseudocode:**

```
pythondef sync_milestones_to_calendar(project, milestones, calendar_service):
    for ms in milestones:
        event_body = build_calendar_event(project, ms)
        existing = find_event_by_extended_property(
            calendar_service, "pm_task_id", ms.task_id
        )
        if existing:
            calendar_service.events().patch(
                calendarId=project.google_calendar_id,
                eventId=existing["id"],
                body=event_body
            ).execute()
        else:
            calendar_service.events().insert(
                calendarId=project.google_calendar_id,
                body=event_body
            ).execute()
```

------

## 6.2 Google Sheets Integration

The Sheets API lets you read and write cell values, create spreadsheets, and update formatting using a RESTful interface. The integration enables two primary use cases: **report export** and **bulk task import**.

**Report export schema** (auto-generated sheet):

| Column           | Cell Reference | Source Field             |
| :--------------- | :------------- | :----------------------- |
| A: Task Name     | `Sheet1!A:A`   | `task.name`              |
| B: Assignee      | `Sheet1!B:B`   | Resolved `resource.name` |
| C: Status        | `Sheet1!C:C`   | `task.status`            |
| D: Priority      | `Sheet1!D:D`   | `task.priority`          |
| E: Planned Start | `Sheet1!E:E`   | `task.planned_start`     |
| F: Planned End   | `Sheet1!F:F`   | `task.planned_end`       |
| G: % Complete    | `Sheet1!G:G`   | `task.percent_complete`  |
| H: Hours Est.    | `Sheet1!H:H`   | `task.estimated_hours`   |
| I: Hours Actual  | `Sheet1!I:I`   | `task.actual_hours`      |

**Export implementation:**

```
pythondef export_project_to_sheet(project, tasks, sheets_service):
    # Build data rows
    header = ["Task", "Assignee", "Status", "Priority",
              "Start", "End", "% Complete", "Est Hours", "Actual Hours"]
    rows = [header]
    for t in sorted(tasks, key=lambda x: x.sort_order):
        rows.append([
            t.name,
            resolve_assignee_names(t.assignees),
            t.status,
            t.priority,
            str(t.planned_start or ""),
            str(t.planned_end or ""),
            t.percent_complete,
            t.estimated_hours,
            t.actual_hours
        ])

    # Write to sheet using A1 notation
    sheets_service.spreadsheets().values().update(
        spreadsheetId=project.google_sheet_id,
        range="ProjectReport!A1",
        valueInputOption="USER_ENTERED",
        body={"values": rows}
    ).execute()
```

**Bulk import:** Read rows from a designated "TaskImport" sheet tab where each row represents a task. Column headers must match expected field names. The system validates each row against the Task schema before inserting.

------

## 7. AI-Powered Plain-Language Updates

## 7.1 Architecture

The AI interpretation layer uses a large language model (LLM) to parse natural-language messages from team members and convert them into structured task mutations. NLP tools can extract due dates, assignee names, and status changes from unstructured text like emails, Slack messages, or SMS.

**Processing pipeline:**

```
textUser Input (text) 
  → NLP Intent Classifier 
  → Entity Extractor (dates, people, tasks, statuses)
  → Action Mapper (maps to API operations)
  → Confirmation / Auto-apply
  → Structured Task Update
```

## 7.2 Input / Output Examples

**Example 1: Status update**

Input:

> "Finished the drywall at the Smith house today, took about 6 hours"

Extracted structured output:

```
json{
  "intent": "task_update",
  "confidence": 0.94,
  "matched_task": {
    "task_id": "t-abc-123",
    "match_method": "fuzzy_name",
    "match_score": 0.87,
    "matched_on": "drywall + Smith project"
  },
  "mutations": [
    { "field": "status", "value": "completed", "signal": "Finished" },
    { "field": "actual_hours", "operation": "add", "value": 6, "signal": "6 hours" },
    { "field": "actual_end", "value": "2026-02-18", "signal": "today" },
    { "field": "percent_complete", "value": 100 }
  ],
  "raw_input": "Finished the drywall at the Smith house today, took about 6 hours"
}
```

**Example 2: New task creation**

Input:

> "We need to order the HVAC unit for the Johnson project by Friday. Sarah should handle it, probably 2 hours."

Extracted output:

```
json{
  "intent": "task_create",
  "confidence": 0.91,
  "project_match": {
    "project_id": "p-456",
    "match_score": 0.92,
    "matched_on": "Johnson"
  },
  "new_task": {
    "name": "Order HVAC unit",
    "planned_end": "2026-02-20",
    "assignees": ["user-sarah-789"],
    "estimated_hours": 2,
    "priority": "high",
    "status": "not_started"
  },
  "raw_input": "We need to order the HVAC unit for the Johnson project by Friday..."
}
```

**Example 3: Dependency + blocker**

Input:

> "Can't start painting until the electrician finishes tomorrow"

Extracted output:

```
json{
  "intent": "dependency_create",
  "confidence": 0.88,
  "predecessor_match": { "task_id": "t-electrical-010", "matched_on": "electrician" },
  "successor_match": { "task_id": "t-painting-011", "matched_on": "painting" },
  "dependency_type": "FS",
  "inferred_predecessor_end": "2026-02-19",
  "mutations": [
    { "task_id": "t-painting-011", "field": "status", "value": "blocked" }
  ]
}
```

## 7.3 LLM Prompt Template

```
textYou are a project management assistant for a small service business.
Given the following context and user message, extract structured task data.

CONTEXT:
- Active projects: {project_list_with_ids}
- Active tasks: {task_list_with_ids_and_assignees}  
- Team members: {resource_list_with_ids}
- Today's date: {current_date}

USER MESSAGE: "{user_input}"

INSTRUCTIONS:
1. Determine intent: task_update | task_create | dependency_create | question
2. Match mentioned projects/tasks/people using fuzzy matching against context
3. Extract: dates (resolve "tomorrow", "Friday", "next week"), hours, status
4. Map status keywords: "finished/done/completed" → completed,
   "started/working on" → in_progress,
   "can't/waiting/blocked" → blocked
5. Return JSON with confidence scores for each extraction

OUTPUT FORMAT:
{schema_from_section_7.2}
```

## 7.4 Confidence & Confirmation Rules

| Confidence | Action                                                       |
| :--------- | :----------------------------------------------------------- |
| ≥ 0.90     | Auto-apply (with undo option in UI)                          |
| 0.70–0.89  | Show pre-filled form, ask user to confirm                    |
| < 0.70     | Ask clarifying question: "Did you mean task X in project Y?" |

This graduated approach prevents incorrect automated changes while keeping the system fast when intent is clear.

------

## 8. MS Project Full Feature Set vs. Small Business Needs

The following comparison highlights what matters for a 3-person company versus the full MS Project Professional feature set:

| Feature Area             | MS Project Professional                                      | This Module (80/20)                                 | Rationale                                                    |
| :----------------------- | :----------------------------------------------------------- | :-------------------------------------------------- | :----------------------------------------------------------- |
| **Task Management**      | Unlimited WBS depth, 20+ task types, recurring tasks, task calendars | Flat list + 1 subtask level, 5 statuses, milestones | Small teams rarely exceed 50 tasks per project               |
| **Dependencies**         | FS, FF, SS, SF with lead/lag, constraint types (ASAP, ALAP, MSO, MFO, etc.) | FS with lag only (MVP); add others later            | ~90% of real dependencies are Finish-to-Start                |
| **Scheduling Engine**    | Auto-schedule, manual-schedule, resource leveling, effort-driven scheduling, task splitting | Basic forward/backward pass CPM                     | Resource leveling is unnecessary when 3 people discuss work daily |
| **Resource Management**  | Resource pools, cost accrual, material resources, budget resources, overallocation detection | Simple assignee list with hourly rate and capacity  | No need for material resources or multi-project resource pools |
| **Cost Tracking**        | Earned value (BCWS, BCWP, ACWP, CPI, SPI), multiple cost rate tables, fixed + variable costs | Estimated vs. actual hours/cost with % variance     | EVM is overkill; hours and dollars suffice                   |
| **Reporting**            | 25+ built-in reports, custom visual reports, OLAP cube       | Health traffic light, export to Google Sheets       | A plumber needs a green/yellow/red indicator, not a CPI chart |
| **Collaboration**        | SharePoint integration, Project Server, Teams sync, co-authoring | Google Calendar + Sheets sync, AI text updates      | Small businesses live in Google Workspace, not SharePoint    |
| **Portfolio Management** | Cross-project dependencies, portfolio optimization, what-if analysis | None (single-project focus)                         | A 3-person shop runs 3-5 active projects, not a portfolio    |
| **Baselines**            | Up to 11 baselines per project                               | 1 baseline snapshot (original plan)                 | One baseline for "what did we promise?" is sufficient        |
| **Custom Fields**        | Unlimited custom fields, formulas, graphical indicators, lookup tables | Tags array + notes                                  | Premature customization kills adoption                       |
| **Licensing Cost**       | ~$55/user/month (Plan 3) or ~$1,300 one-time (Professional 2024) | Included in your platform                           | Cost alone disqualifies MS Project for most small businesses |

## What a 3-person company actually does daily:

1. **Morning:** "What am I doing today?" → Task list filtered by assignee + due date
2. **During work:** "This task is done" or "I'm blocked" → Status update (AI-assisted)
3. **End of week:** "Are we on track for the client deadline?" → Health indicator
4. **Monthly:** "How profitable was that project?" → Hours vs. estimate report in Sheets

Everything else in MS Project exists to solve problems that emerge at scale (50+ resources, cross-departmental coordination, regulatory compliance). A small service business doesn't have those problems.

------

## 9. API Surface (Summary)

The module exposes these RESTful endpoints:

## Projects

- `POST /projects` — Create project
- `GET /projects` — List with filters (status, owner, health)
- `GET /projects/:id` — Full project with computed health
- `PATCH /projects/:id` — Update project fields
- `GET /projects/:id/health` — Real-time health calculation
- `POST /projects/:id/sync/calendar` — Trigger Google Calendar sync
- `POST /projects/:id/sync/sheets` — Export to Google Sheets

## Tasks

- `POST /projects/:id/tasks` — Create task
- `GET /projects/:id/tasks` — List tasks (filterable by status, assignee, due date)
- `PATCH /tasks/:id` — Update task
- `POST /tasks/:id/log-time` — Add hours to a task
- `GET /projects/:id/critical-path` — Returns critical path analysis

## Dependencies

- `POST /projects/:id/dependencies` — Create dependency
- `DELETE /dependencies/:id` — Remove dependency
- `GET /projects/:id/dependencies` — List all with cycle detection

## AI Updates

- `POST /ai/parse-update` — Submit plain-language text, get structured mutations back
- `POST /ai/apply-update` — Apply confirmed mutations to tasks

------

## 10. Cycle Detection for Dependencies

Before inserting any dependency, the system must verify no circular references exist. A simple DFS-based cycle detection runs on every `POST /dependencies`:

```
pythondef has_cycle(tasks, dependencies, new_dep):
    """Returns True if adding new_dep would create a cycle."""
    adj = defaultdict(list)
    for dep in dependencies:
        adj[dep.predecessor_task_id].append(dep.successor_task_id)
    # Add the proposed edge
    adj[new_dep.predecessor_task_id].append(new_dep.successor_task_id)

    visited = set()
    rec_stack = set()

    def dfs(node):
        visited.add(node)
        rec_stack.add(node)
        for neighbor in adj[node]:
            if neighbor not in visited:
                if dfs(neighbor):
                    return True
            elif neighbor in rec_stack:
                return True
        rec_stack.discard(node)
        return False

    for task_id in adj:
        if task_id not in visited:
            if dfs(task_id):
                return True
    return False
```

If a cycle is detected, the API returns `400 Bad Request` with a message identifying the conflicting chain.

------

## 11. Data Validation Rules

These constraints are enforced at the API layer before persistence:

| Rule                                                     | Validation                           | Error Code              |
| :------------------------------------------------------- | :----------------------------------- | :---------------------- |
| Task `planned_end` ≥ `planned_start`                     | Date comparison                      | `INVALID_DATE_RANGE`    |
| Milestone `estimated_hours` must be 0                    | Schema enforcement                   | `MILESTONE_NO_HOURS`    |
| Dependency cannot reference same task                    | `predecessor ≠ successor`            | `SELF_DEPENDENCY`       |
| No duplicate dependencies                                | Unique on `(predecessor, successor)` | `DUPLICATE_DEPENDENCY`  |
| Assignee must be active resource                         | Check `resource.is_active`           | `INACTIVE_RESOURCE`     |
| `percent_complete` must be 0–100                         | Range check                          | `INVALID_PERCENTAGE`    |
| Task cannot be `completed` if blockers are `not_started` | Dependency status check              | `BLOCKED_COMPLETION`    |
| Project `target_end_date` ≥ `start_date`                 | Date comparison                      | `INVALID_PROJECT_DATES` |

------

## 12. Sample Project (Complete JSON)

Here is a fully realized example representing a small HVAC service job:

```
json{
  "project": {
    "project_id": "p-hvac-2026-001",
    "name": "Johnson Residence HVAC Install",
    "description": "Full HVAC system replacement for residential client",
    "status": "active",
    "priority": "high",
    "start_date": "2026-02-16",
    "target_end_date": "2026-03-13",
    "actual_end_date": null,
    "owner_id": "u-mike-001",
    "client": {
      "client_id": "c-johnson-001",
      "client_name": "Robert Johnson",
      "contact_email": "rjohnson@email.com"
    },
    "budget": {
      "estimated_hours": 80,
      "estimated_cost": 12000,
      "actual_hours": 12,
      "actual_cost": 1800
    },
    "tags": ["residential", "hvac", "full-replacement"],
    "google_calendar_id": "team-calendar@group.calendar.google.com",
    "google_sheet_id": "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms"
  },
  "tasks": [
    {
      "task_id": "t-001",
      "project_id": "p-hvac-2026-001",
      "parent_task_id": null,
      "name": "Site assessment and measurements",
      "status": "completed",
      "priority": "high",
      "is_milestone": false,
      "estimated_hours": 4,
      "actual_hours": 3.5,
      "percent_complete": 100,
      "planned_start": "2026-02-16",
      "planned_end": "2026-02-16",
      "actual_start": "2026-02-16",
      "actual_end": "2026-02-16",
      "assignees": ["u-mike-001"],
      "sort_order": 1
    },
    {
      "task_id": "t-002",
      "project_id": "p-hvac-2026-001",
      "parent_task_id": null,
      "name": "Order equipment and materials",
      "status": "in_progress",
      "priority": "high",
      "is_milestone": false,
      "estimated_hours": 2,
      "actual_hours": 1,
      "percent_complete": 50,
      "planned_start": "2026-02-17",
      "planned_end": "2026-02-18",
      "actual_start": "2026-02-17",
      "actual_end": null,
      "assignees": ["u-sarah-002"],
      "sort_order": 2
    },
    {
      "task_id": "t-003",
      "project_id": "p-hvac-2026-001",
      "parent_task_id": null,
      "name": "Remove existing HVAC system",
      "status": "not_started",
      "priority": "medium",
      "is_milestone": false,
      "estimated_hours": 16,
      "actual_hours": 0,
      "percent_complete": 0,
      "planned_start": "2026-02-23",
      "planned_end": "2026-02-24",
      "actual_start": null,
      "actual_end": null,
      "assignees": ["u-mike-001", "u-tom-003"],
      "sort_order": 3
    },
    {
      "task_id": "t-004",
      "project_id": "p-hvac-2026-001",
      "parent_task_id": null,
      "name": "Install new HVAC system",
      "status": "not_started",
      "priority": "high",
      "is_milestone": false,
      "estimated_hours": 32,
      "actual_hours": 0,
      "percent_complete": 0,
      "planned_start": "2026-02-25",
      "planned_end": "2026-03-04",
      "actual_start": null,
      "actual_end": null,
      "assignees": ["u-mike-001", "u-tom-003"],
      "sort_order": 4
    },
    {
      "task_id": "t-005",
      "project_id": "p-hvac-2026-001",
      "parent_task_id": null,
      "name": "Testing and commissioning",
      "status": "not_started",
      "priority": "high",
      "is_milestone": false,
      "estimated_hours": 8,
      "actual_hours": 0,
      "percent_complete": 0,
      "planned_start": "2026-03-05",
      "planned_end": "2026-03-06",
      "actual_start": null,
      "actual_end": null,
      "assignees": ["u-mike-001"],
      "sort_order": 5
    },
    {
      "task_id": "t-006",
      "project_id": "p-hvac-2026-001",
      "parent_task_id": null,
      "name": "Client Walkthrough & Sign-off",
      "status": "not_started",
      "is_milestone": true,
      "estimated_hours": 0,
      "actual_hours": 0,
      "percent_complete": 0,
      "planned_start": "2026-03-10",
      "planned_end": "2026-03-10",
      "actual_start": null,
      "actual_end": null,
      "assignees": ["u-mike-001"],
      "sort_order": 6
    }
  ],
  "dependencies": [
    {
      "dependency_id": "d-001",
      "project_id": "p-hvac-2026-001",
      "predecessor_task_id": "t-001",
      "successor_task_id": "t-002",
      "type": "FS",
      "lag_days": 0
    },
    {
      "dependency_id": "d-002",
      "project_id": "p-hvac-2026-001",
      "predecessor_task_id": "t-002",
      "successor_task_id": "t-003",
      "type": "FS",
      "lag_days": 3
    },
    {
      "dependency_id": "d-003",
      "project_id": "p-hvac-2026-001",
      "predecessor_task_id": "t-003",
      "successor_task_id": "t-004",
      "type": "FS",
      "lag_days": 0
    },
    {
      "dependency_id": "d-004",
      "project_id": "p-hvac-2026-001",
      "predecessor_task_id": "t-004",
      "successor_task_id": "t-005",
      "type": "FS",
      "lag_days": 0
    },
    {
      "dependency_id": "d-005",
      "project_id": "p-hvac-2026-001",
      "predecessor_task_id": "t-005",
      "successor_task_id": "t-006",
      "type": "FS",
      "lag_days": 2
    }
  ],
  "resources": [
    {
      "user_id": "u-mike-001",
      "name": "Mike (Owner)",
      "email": "mike@hvacpros.com",
      "role": "owner",
      "hourly_rate": 85,
      "weekly_capacity_hours": 45,
      "skills": ["hvac", "electrical", "project-lead"],
      "google_calendar_email": "mike@hvacpros.com",
      "is_active": true
    },
    {
      "user_id": "u-sarah-002",
      "name": "Sarah",
      "email": "sarah@hvacpros.com",
      "role": "manager",
      "hourly_rate": 55,
      "weekly_capacity_hours": 40,
      "skills": ["purchasing", "scheduling", "permits"],
      "google_calendar_email": "sarah@hvacpros.com",
      "is_active": true
    },
    {
      "user_id": "u-tom-003",
      "name": "Tom",
      "email": "tom@hvacpros.com",
      "role": "member",
      "hourly_rate": 45,
      "weekly_capacity_hours": 40,
      "skills": ["hvac", "ductwork", "demolition"],
      "google_calendar_email": "tom@hvacpros.com",
      "is_active": true
    }
  ]
}
```

## Critical Path for This Example

The full dependency chain is: **t-001 → t-002 → t-003 → t-004 → t-005 → t-006** — all tasks are on the critical path since there are no parallel branches. Total duration: 0.5 + 0.25 + 2 + 4 + 1 + 0 = 7.75 working days + 5 days of lag = ~12.75 working days.

------

## 13. Implementation Phases

| Phase                      | Scope                                                        | Duration  |
| :------------------------- | :----------------------------------------------------------- | :-------- |
| **Phase 1 — Core**         | Project + Task CRUD, simple list views, status tracking, assignees | 3–4 weeks |
| **Phase 2 — Scheduling**   | FS dependencies, basic CPM, deadline alerts, health indicator | 2–3 weeks |
| **Phase 3 — Integrations** | Google Calendar sync (milestones + deadlines), Sheets export | 2 weeks   |
| **Phase 4 — AI Layer**     | NLP update parsing, intent classification, confirm/auto-apply flow | 3–4 weeks |
| **Phase 5 — Polish**       | Mobile-friendly views, notification preferences, onboarding wizard | 2 weeks   |

------

## 14. Technical Considerations

## Database Choice

- **PostgreSQL** is recommended for the relational model with JSON support (`jsonb` columns for `tags`, `notes`, `extendedProperties`). The dependency graph queries benefit from recursive CTEs.
- Alternative: **Firestore/MongoDB** if the rest of the platform is document-oriented — store each project as a document with embedded tasks for <50-task projects.

## Performance Targets

- CPM recalculation: <200ms for projects with ≤100 tasks
- Health indicator: cached, invalidated on any task mutation
- Calendar sync: async via job queue (not blocking the UI)
- AI parsing: <3s round-trip including LLM API call

## Security Model

- All queries are scoped by `organization_id` (multi-tenant isolation)
- Role-based access: `owner` can modify everything; `member` can update assigned tasks only; `contractor` sees only their assigned tasks
- Google OAuth tokens stored encrypted with per-user refresh tokens

This specification provides the complete foundation for building a project management module that small service businesses will actually use — omitting the complexity that causes enterprise tools to be abandoned at this scale.