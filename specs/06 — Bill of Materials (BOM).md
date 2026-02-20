# 06 — Bill of Materials (BOM) Module: Technical Specification

## 1. Executive Overview

This specification defines the BOM module for a manufacturing platform targeting small manufacturers with 1–20 employees. The module supports single-level and multi-level BOMs, revision control, cost rollup, inventory integration, QuickBooks synchronization, and AI-assisted BOM generation. Unlike full ERP BOM systems designed for complex enterprises, this module prioritizes simplicity, speed-to-value, and integration with existing small-business tools.

A multi-level BOM is a hierarchical structure that details the components, subassemblies, and assemblies needed for a final product, organizing parts in a tree-like format where the top level represents the finished product and each lower level delineates increasingly detailed subassemblies and individual parts.

------

## 2. Core Data Structures

## 2.1 Part / Item Master

Every component in the system — raw material, purchased part, sub-assembly, or finished good — is represented as an **Item** in the Item Master. The Item Master is the single source of truth for part identity, independent of any specific BOM.

```
json{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ItemMaster",
  "type": "object",
  "required": ["item_id", "part_number", "description", "item_type", "uom", "status"],
  "properties": {
    "item_id": {
      "type": "string",
      "format": "uuid",
      "description": "System-generated unique identifier"
    },
    "part_number": {
      "type": "string",
      "maxLength": 50,
      "pattern": "^[A-Z0-9\\-\\.]+$",
      "description": "Human-readable part number (e.g., ASM-1000, RAW-AL-6061)"
    },
    "description": {
      "type": "string",
      "maxLength": 255
    },
    "item_type": {
      "type": "string",
      "enum": ["raw_material", "purchased_part", "sub_assembly", "finished_good", "phantom", "consumable"],
      "description": "Classification determining BOM behavior"
    },
    "uom": {
      "type": "string",
      "enum": ["EA", "FT", "IN", "LB", "KG", "GAL", "L", "SQ_FT", "SQ_M", "SHEET", "ROLL"],
      "description": "Base unit of measure for inventory tracking"
    },
    "uom_conversions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "from_uom": { "type": "string" },
          "to_uom": { "type": "string" },
          "factor": { "type": "number", "exclusiveMinimum": 0 }
        }
      }
    },
    "status": {
      "type": "string",
      "enum": ["active", "inactive", "obsolete", "pending_approval"]
    },
    "cost_data": {
      "$ref": "#/definitions/CostData"
    },
    "inventory_data": {
      "$ref": "#/definitions/InventoryData"
    },
    "supplier_links": {
      "type": "array",
      "items": { "$ref": "#/definitions/SupplierLink" }
    },
    "qb_item_ref": {
      "type": "string",
      "description": "QuickBooks Item ID for accounting sync"
    },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  },
  "definitions": {
    "CostData": {
      "type": "object",
      "properties": {
        "standard_cost": { "type": "number", "minimum": 0 },
        "last_purchase_cost": { "type": "number", "minimum": 0 },
        "average_cost": { "type": "number", "minimum": 0 },
        "cost_method": { "type": "string", "enum": ["standard", "average", "last_purchase", "fifo"] },
        "currency": { "type": "string", "default": "USD" }
      }
    },
    "InventoryData": {
      "type": "object",
      "properties": {
        "on_hand_qty": { "type": "number", "minimum": 0 },
        "allocated_qty": { "type": "number", "minimum": 0 },
        "on_order_qty": { "type": "number", "minimum": 0 },
        "reorder_point": { "type": "number", "minimum": 0 },
        "lead_time_days": { "type": "integer", "minimum": 0 },
        "location": { "type": "string" }
      }
    },
    "SupplierLink": {
      "type": "object",
      "properties": {
        "supplier_id": { "type": "string" },
        "supplier_part_number": { "type": "string" },
        "unit_price": { "type": "number", "minimum": 0 },
        "min_order_qty": { "type": "number", "minimum": 0 },
        "lead_time_days": { "type": "integer", "minimum": 0 },
        "is_preferred": { "type": "boolean", "default": false }
      }
    }
  }
}
```

## Field Definitions

| Field         | Type   | Description                                                  |
| :------------ | :----- | :----------------------------------------------------------- |
| `item_id`     | UUID   | Immutable system key; never exposed to users                 |
| `part_number` | String | Intelligent or sequential identifier visible on shop floor (e.g., `RAW-STL-1018-0.5`) |
| `item_type`   | Enum   | Drives BOM explosion logic — `phantom` types are exploded through during MRP; `consumable` items are costed but not tracked in inventory |
| `uom`         | Enum   | Base stocking unit; `uom_conversions` handle purchasing in different units (e.g., buy steel in LB, consume in IN) |
| `cost_method` | Enum   | Determines which cost figure feeds into rollup calculations  |
| `qb_item_ref` | String | Foreign key linking to the QuickBooks Online Item object for two-way sync |

------

## 2.2 Single-Level BOM Schema

A single-level BOM lists all required components without hierarchy — suitable for basic products or as the building block of multi-level structures. Each BOM record has exactly one parent item and a flat list of child components.

```
json{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "SingleLevelBOM",
  "type": "object",
  "required": ["bom_id", "parent_item_id", "revision", "status", "lines"],
  "properties": {
    "bom_id": {
      "type": "string",
      "format": "uuid"
    },
    "parent_item_id": {
      "type": "string",
      "format": "uuid",
      "description": "The assembly or finished good this BOM produces"
    },
    "revision": {
      "type": "string",
      "pattern": "^[A-Z]{1,2}$|^[0-9]+\\.[0-9]+$",
      "description": "Revision identifier (e.g., 'A', 'B', or '1.0', '2.1')"
    },
    "status": {
      "type": "string",
      "enum": ["draft", "pending_review", "approved", "released", "obsolete"]
    },
    "effective_date": {
      "type": "string",
      "format": "date",
      "description": "Date from which this revision is active"
    },
    "expiration_date": {
      "type": ["string", "null"],
      "format": "date"
    },
    "yield_pct": {
      "type": "number",
      "minimum": 0,
      "maximum": 100,
      "default": 100,
      "description": "Expected yield percentage; adjusts required quantities"
    },
    "batch_size": {
      "type": "number",
      "exclusiveMinimum": 0,
      "default": 1,
      "description": "Reference quantity this BOM produces"
    },
    "lines": {
      "type": "array",
      "minItems": 1,
      "items": { "$ref": "#/definitions/BOMLine" }
    },
    "notes": { "type": "string" },
    "created_by": { "type": "string" },
    "approved_by": { "type": ["string", "null"] },
    "created_at": { "type": "string", "format": "date-time" },
    "updated_at": { "type": "string", "format": "date-time" }
  },
  "definitions": {
    "BOMLine": {
      "type": "object",
      "required": ["line_number", "child_item_id", "quantity_per", "uom"],
      "properties": {
        "line_number": {
          "type": "integer",
          "minimum": 1,
          "description": "Sequence for display and shop-floor reference"
        },
        "child_item_id": {
          "type": "string",
          "format": "uuid"
        },
        "quantity_per": {
          "type": "number",
          "exclusiveMinimum": 0,
          "description": "Quantity required per 1 unit of parent (adjusted by batch_size)"
        },
        "uom": {
          "type": "string",
          "description": "Unit of measure for this line (may differ from item base UOM)"
        },
        "scrap_pct": {
          "type": "number",
          "minimum": 0,
          "maximum": 100,
          "default": 0,
          "description": "Expected scrap factor; inflates required quantity"
        },
        "reference_designators": {
          "type": "string",
          "description": "Position references on drawings (e.g., 'R1, R2, R3')"
        },
        "is_critical": {
          "type": "boolean",
          "default": false,
          "description": "Flag for long-lead or single-source components"
        },
        "substitutions": {
          "type": "array",
          "items": { "$ref": "#/definitions/Substitution" }
        },
        "notes": { "type": "string" }
      }
    },
    "Substitution": {
      "type": "object",
      "required": ["substitute_item_id", "priority"],
      "properties": {
        "substitute_item_id": {
          "type": "string",
          "format": "uuid"
        },
        "priority": {
          "type": "integer",
          "minimum": 1,
          "description": "Lower number = preferred substitute"
        },
        "conversion_factor": {
          "type": "number",
          "default": 1.0,
          "description": "Quantity multiplier if substitute differs in size/capacity"
        },
        "approved": {
          "type": "boolean",
          "default": false
        },
        "notes": { "type": "string" }
      }
    }
  }
}
```

The substitution model follows the **alternative** pattern from BOM design — one and only one of the alternatives is selected at the time of manufacture, providing the manufacturer flexibility without exposing the choice to the customer.

------

## 2.3 Multi-Level BOM: Hierarchy Data Patterns

A multi-level BOM captures the actual assembly relationships, showing not just what parts are needed but how those parts fit together and which components depend on others. The system uses a **recursive reference model** where each BOM's child items may themselves have BOMs, forming a directed acyclic graph (DAG).

## Database Model: Adjacency List with Junction Table

The PART table can be a top-assembly, sub-assembly, or leaf part. The BOM junction table models the many-to-many self-relationship, since one sub-assembly or part can be reused in multiple parent assemblies.

```
text┌──────────────────┐          ┌──────────────────────────┐
│   item_master     │         │       bom_header          │
├──────────────────┤          ├──────────────────────────┤
│ item_id (PK)     │◄────┐   │ bom_id (PK)              │
│ part_number      │     │   │ parent_item_id (FK)──────►│
│ description      │     │   │ revision                  │
│ item_type        │     │   │ status                    │
│ uom              │     │   │ effective_date             │
│ ...              │     │   │ batch_size                │
└──────────────────┘     │   └──────────────────────────┘
                         │              │
                         │              │ 1:N
                         │              ▼
                         │   ┌──────────────────────────┐
                         │   │       bom_line            │
                         │   ├──────────────────────────┤
                         │   │ bom_line_id (PK)         │
                         │   │ bom_id (FK)              │
                         │   │ child_item_id (FK)───────┘
                         │   │ line_number               │
                         │   │ quantity_per              │
                         │   │ uom                      │
                         │   │ scrap_pct                │
                         │   └──────────────────────────┘
```

## Multi-Level Explosion Algorithm

To "explode" a multi-level BOM into a full indented parts list, the system performs a recursive depth-first traversal. Phantom assemblies are exploded through — their components roll up to the parent level with quantities multiplied through.

```
textFUNCTION explode_bom(item_id, qty_required=1, level=0, path=[]):
    bom = get_active_bom(item_id)
    IF bom IS NULL:
        RETURN [{item_id, qty_required, level, is_leaf: true}]
    
    result = []
    FOR line IN bom.lines:
        extended_qty = qty_required * line.quantity_per * (1 + line.scrap_pct/100)
        extended_qty = extended_qty / bom.yield_pct * 100
        
        IF line.child_item.item_type == "phantom":
            // Explode through — don't add phantom as its own level
            result += explode_bom(line.child_item_id, extended_qty, level, path + [item_id])
        ELSE IF line.child_item has active BOM:
            result += [{line.child_item_id, extended_qty, level+1, is_leaf: false}]
            result += explode_bom(line.child_item_id, extended_qty, level+1, path + [item_id])
        ELSE:
            result += [{line.child_item_id, extended_qty, level+1, is_leaf: true}]
    
    RETURN result
```

**Circular reference detection**: The `path` parameter tracks ancestry. If `item_id` appears in `path`, the system raises a `CircularBOMError` and rejects the BOM save.

## Example: Multi-Level BOM JSON Instance

```
json{
  "bom_id": "bom-uuid-001",
  "parent_item_id": "item-uuid-bicycle",
  "parent_part_number": "FG-BIKE-100",
  "description": "Mountain Bike Assembly",
  "revision": "C",
  "status": "released",
  "effective_date": "2026-01-15",
  "batch_size": 1,
  "yield_pct": 100,
  "lines": [
    {
      "line_number": 1,
      "child_item_id": "item-uuid-frame-asm",
      "child_part_number": "ASM-FRAME-200",
      "description": "Frame Assembly",
      "quantity_per": 1,
      "uom": "EA",
      "scrap_pct": 0,
      "has_child_bom": true,
      "child_bom": {
        "bom_id": "bom-uuid-002",
        "revision": "B",
        "lines": [
          {
            "line_number": 1,
            "child_part_number": "RAW-STL-4130",
            "description": "4130 Chromoly Tubing",
            "quantity_per": 3.5,
            "uom": "FT",
            "scrap_pct": 8,
            "has_child_bom": false,
            "substitutions": [
              {
                "substitute_part_number": "RAW-STL-4130-ALT",
                "description": "4130 Tubing (Supplier B)",
                "priority": 1,
                "conversion_factor": 1.0,
                "approved": true
              }
            ]
          },
          {
            "line_number": 2,
            "child_part_number": "PUR-BB-SHELL",
            "description": "Bottom Bracket Shell",
            "quantity_per": 1,
            "uom": "EA",
            "scrap_pct": 2,
            "has_child_bom": false
          },
          {
            "line_number": 3,
            "child_part_number": "PUR-HEAD-TUBE",
            "description": "Head Tube",
            "quantity_per": 1,
            "uom": "EA",
            "scrap_pct": 1,
            "has_child_bom": false
          }
        ]
      }
    },
    {
      "line_number": 2,
      "child_item_id": "item-uuid-wheel-asm",
      "child_part_number": "ASM-WHEEL-300",
      "description": "Wheel Assembly",
      "quantity_per": 2,
      "uom": "EA",
      "scrap_pct": 0,
      "has_child_bom": true
    },
    {
      "line_number": 3,
      "child_part_number": "PUR-SEAT-STD",
      "description": "Standard Saddle",
      "quantity_per": 1,
      "uom": "EA",
      "scrap_pct": 0,
      "has_child_bom": false,
      "substitutions": [
        {
          "substitute_part_number": "PUR-SEAT-GEL",
          "description": "Gel Comfort Saddle",
          "priority": 1,
          "conversion_factor": 1.0,
          "approved": true
        }
      ]
    }
  ]
}
```

## 2.4 Flattened BOM Representation

For MRP, purchasing, and reporting, the hierarchical BOM is often flattened with additional attributes to indicate each item's position in the hierarchy. The flattened view uses a `level` indicator and `path` string:

```
json{
  "flattened_bom": [
    { "level": 0, "path": "/", "part_number": "FG-BIKE-100", "description": "Mountain Bike", "extended_qty": 1, "uom": "EA" },
    { "level": 1, "path": "/FG-BIKE-100", "part_number": "ASM-FRAME-200", "description": "Frame Assembly", "extended_qty": 1, "uom": "EA" },
    { "level": 2, "path": "/FG-BIKE-100/ASM-FRAME-200", "part_number": "RAW-STL-4130", "description": "4130 Chromoly Tubing", "extended_qty": 3.78, "uom": "FT" },
    { "level": 2, "path": "/FG-BIKE-100/ASM-FRAME-200", "part_number": "PUR-BB-SHELL", "description": "Bottom Bracket Shell", "extended_qty": 1.02, "uom": "EA" },
    { "level": 1, "path": "/FG-BIKE-100", "part_number": "ASM-WHEEL-300", "description": "Wheel Assembly", "extended_qty": 2, "uom": "EA" },
    { "level": 1, "path": "/FG-BIKE-100", "part_number": "PUR-SEAT-STD", "description": "Standard Saddle", "extended_qty": 1, "uom": "EA" }
  ]
}
```

------

## 3. BOM Revision Control and Change Management

## 3.1 Revision Model

The revision model supports both linear and branched revision histories. A revision indicates the change history of the item, and because engineers sometimes combine aspects of multiple previous revisions, change history requires a many-to-many relationship between items and revisions.

```
json{
  "title": "BOMRevision",
  "type": "object",
  "required": ["revision_id", "bom_id", "revision_code", "status"],
  "properties": {
    "revision_id": { "type": "string", "format": "uuid" },
    "bom_id": { "type": "string", "format": "uuid" },
    "revision_code": {
      "type": "string",
      "description": "Sequential letter (A, B, C...) or semver (1.0, 1.1, 2.0)"
    },
    "preceding_revisions": {
      "type": "array",
      "items": { "type": "string", "format": "uuid" },
      "description": "Supports branched history — a revision may derive from multiple predecessors"
    },
    "status": {
      "type": "string",
      "enum": ["draft", "in_review", "approved", "released", "superseded", "obsolete"]
    },
    "effective_date": { "type": "string", "format": "date" },
    "expiration_date": { "type": ["string", "null"], "format": "date" },
    "change_order_id": {
      "type": ["string", "null"],
      "format": "uuid",
      "description": "Link to the ECO that authorized this revision"
    },
    "snapshot": {
      "type": "object",
      "description": "Complete frozen copy of BOM lines at time of release"
    },
    "diff_from_previous": {
      "type": "array",
      "items": { "$ref": "#/definitions/BOMDiffEntry" }
    }
  },
  "definitions": {
    "BOMDiffEntry": {
      "type": "object",
      "properties": {
        "change_type": { "type": "string", "enum": ["added", "removed", "modified"] },
        "line_number": { "type": "integer" },
        "field_name": { "type": "string" },
        "old_value": {},
        "new_value": {}
      }
    }
  }
}
```

## 3.2 Simplified Change Management Workflow

Full ECO processes involve ECR creation, CCB review, multi-stakeholder sign-off, and formal implementation. For small manufacturers, this is simplified to a three-stage process while preserving traceability:

**Stage 1: Change Request (lightweight ECR)**

- Any user creates a change request describing what needs to change and why
- Captures affected BOMs, estimated cost impact, and urgency

**Stage 2: Change Order (simplified ECO)**

- The owner/lead engineer reviews, modifies the BOM in draft, and attaches the change rationale
- The BOM, CAD files, drawings, and all documentation must reference the same revision level
- System auto-generates a diff showing exactly what changed

**Stage 3: Approval and Release**

- One or two designated approvers sign off (configurable per company)
- Upon approval, the old revision is marked `superseded`, the new revision becomes `released`, and the effective date is set
- Downstream systems (inventory, costing, QuickBooks) are notified via events

```
json{
  "title": "ChangeOrder",
  "type": "object",
  "properties": {
    "eco_id": { "type": "string", "format": "uuid" },
    "eco_number": { "type": "string", "pattern": "^ECO-[0-9]{6}$" },
    "title": { "type": "string" },
    "reason_code": {
      "type": "string",
      "enum": ["cost_reduction", "quality_improvement", "supplier_change", "design_update", "regulatory", "customer_request", "obsolescence"]
    },
    "description": { "type": "string" },
    "priority": { "type": "string", "enum": ["low", "normal", "high", "critical"] },
    "affected_boms": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "bom_id": { "type": "string", "format": "uuid" },
          "current_revision": { "type": "string" },
          "proposed_revision": { "type": "string" }
        }
      }
    },
    "status": {
      "type": "string",
      "enum": ["draft", "submitted", "approved", "rejected", "implemented", "cancelled"]
    },
    "requested_by": { "type": "string" },
    "approved_by": { "type": ["string", "null"] },
    "cost_impact_estimate": { "type": "number" },
    "implementation_date": { "type": ["string", "null"], "format": "date" },
    "created_at": { "type": "string", "format": "date-time" }
  }
}
```

## 3.3 Revision State Machine

```
textdraft ──► in_review ──► approved ──► released ──► superseded
  │           │                                        │
  ▼           ▼                                        ▼
cancelled  rejected                                 obsolete
```

**Business rules:**

- Only one revision per BOM can be in `released` status at any time
- Releasing a new revision automatically supersedes the current released revision
- `released` revisions are immutable — any change requires a new revision
- `draft` and `in_review` revisions are editable

------

## 4. Cost Rollup Logic

## 4.1 Cost Element Structure

The cost rollup follows a bottom-up accumulation pattern where costs are totaled for each subassembly and phantom assembly in the product structure, then multiplied by each assembly's indented usage quantity, and those lower-level costs are added to the parent to arrive at total cost.

Five cost elements are tracked:

| Element          | Source                                 | Calculation                                                |
| :--------------- | :------------------------------------- | :--------------------------------------------------------- |
| **Material**     | Purchased item cost × usage qty        | Sum of all `purchased_part` and `raw_material` line costs  |
| **Labor**        | Routing hours × work center labor rate | `(hours_per_process / items_per_process) × hourly_rate`    |
| **Setup**        | Setup hours × setup rate ÷ run size    | Amortized per-unit cost that decreases with larger batches |
| **Mfg Overhead** | (Setup + labor hours) × OH rate        | Applied via work center overhead rate                      |
| **Subcontract**  | External processing cost per unit      | Fixed cost per operation outsourced                        |

## 4.2 Rollup Algorithm

```
textFUNCTION cost_rollup(item_id, batch_size=1):
    bom = get_active_bom(item_id)
    IF bom IS NULL:
        // Leaf node (purchased item) — return its direct cost
        RETURN item.cost_data[item.cost_method]

    cost = {
        material: 0, labor: 0, setup: 0, 
        mfg_overhead: 0, subcontract: 0,
        lower_levels: 0, total: 0
    }

    // Accumulate material costs from BOM lines
    FOR line IN bom.lines:
        adjusted_qty = line.quantity_per * (1 + line.scrap_pct / 100)
        child_item = get_item(line.child_item_id)

        IF child_item.item_type IN ("raw_material", "purchased_part"):
            line_cost = child_item.cost_data[child_item.cost_method] * adjusted_qty
            cost.material += line_cost
        ELSE:
            // Sub-assembly: recurse
            sub_cost = cost_rollup(line.child_item_id, bom.batch_size)
            cost.lower_levels += sub_cost.total * adjusted_qty

    // Add routing costs (direct to this level)
    routing = get_routing(item_id)
    IF routing:
        FOR step IN routing.steps:
            wc = get_work_center(step.work_center_id)
            labor_hrs = step.hours_per_process / step.items_per_process
            cost.labor += labor_hrs * wc.labor_rate
            cost.setup += (step.setup_hours * wc.setup_rate) / batch_size
            cost.mfg_overhead += (labor_hrs + step.setup_hours) * wc.overhead_rate
            IF step.is_subcontract:
                cost.subcontract += step.subcontract_cost

    // Apply yield factor
    IF bom.yield_pct < 100:
        yield_factor = 100 / bom.yield_pct
        cost.material *= yield_factor
        cost.lower_levels *= yield_factor

    cost.total = cost.material + cost.labor + cost.setup 
                 + cost.mfg_overhead + cost.subcontract + cost.lower_levels
    
    RETURN cost
```

A 10% cost increase for a component used in multiple subassemblies can have a multiplied effect on total product cost — so the system should flag items with the greatest cost leverage across all BOMs.

## 4.3 Cost Rollup Output Schema

```
json{
  "title": "CostRollupResult",
  "type": "object",
  "properties": {
    "item_id": { "type": "string", "format": "uuid" },
    "part_number": { "type": "string" },
    "bom_revision": { "type": "string" },
    "batch_size": { "type": "number" },
    "cost_method": { "type": "string" },
    "rollup_timestamp": { "type": "string", "format": "date-time" },
    "cost_breakdown": {
      "type": "object",
      "properties": {
        "routing_costs": {
          "type": "object",
          "properties": {
            "labor": { "type": "number" },
            "setup": { "type": "number" },
            "mfg_overhead": { "type": "number" },
            "subcontract": { "type": "number" }
          }
        },
        "lower_level_costs": {
          "type": "object",
          "description": "Material costs for this level plus all routing/material costs from sub-assemblies",
          "properties": {
            "material": { "type": "number" },
            "labor": { "type": "number" },
            "setup": { "type": "number" },
            "mfg_overhead": { "type": "number" },
            "subcontract": { "type": "number" }
          }
        },
        "total_cost": { "type": "number" }
      }
    },
    "line_details": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "part_number": { "type": "string" },
          "description": { "type": "string" },
          "level": { "type": "integer" },
          "extended_qty": { "type": "number" },
          "unit_cost": { "type": "number" },
          "extended_cost": { "type": "number" },
          "cost_pct_of_total": { "type": "number" }
        }
      }
    }
  }
}
```

## 4.4 Batch Cost Rollup

A scheduled or on-demand **Batch Cost Rollup** recalculates all active BOMs when purchase prices change. This is triggered after MRP purchase price updates are confirmed, and the updated costs can be optionally applied to unreleased jobs.

------

## 5. Inventory Integration for Material Availability

## 5.1 Availability Check Logic

The BOM module integrates with inventory to answer: *"Can we build N units of this assembly right now?"* The availability check performs a recursive BOM explosion and compares required quantities against available stock.

```
textFUNCTION check_availability(item_id, qty_to_build):
    explosion = explode_bom(item_id, qty_to_build)
    leaf_items = filter(explosion, is_leaf=true)
    
    // Aggregate demand by item (same part may appear multiple times)
    demand_map = {}
    FOR item IN leaf_items:
        demand_map[item.item_id] += item.extended_qty
    
    results = []
    max_buildable = INFINITY
    
    FOR item_id, required_qty IN demand_map:
        inv = get_inventory(item_id)
        available = inv.on_hand_qty - inv.allocated_qty + inv.on_order_qty
        
        shortage = MAX(0, required_qty - available)
        buildable_from_this = FLOOR(available / (required_qty / qty_to_build))
        max_buildable = MIN(max_buildable, buildable_from_this)
        
        results.append({
            item_id, part_number, required_qty, 
            on_hand: inv.on_hand_qty,
            allocated: inv.allocated_qty,
            on_order: inv.on_order_qty,
            available,
            shortage,
            has_substitutes: check_substitutes(item_id),
            lead_time_days: inv.lead_time_days
        })
    
    RETURN {
        can_build: ALL(r.shortage == 0 FOR r IN results),
        max_buildable_qty: max_buildable,
        shortages: filter(results, shortage > 0),
        full_report: results
    }
```

## 5.2 Availability Response Schema

```
json{
  "title": "AvailabilityCheckResult",
  "type": "object",
  "properties": {
    "item_id": { "type": "string" },
    "requested_qty": { "type": "number" },
    "can_build": { "type": "boolean" },
    "max_buildable_qty": { "type": "number" },
    "check_timestamp": { "type": "string", "format": "date-time" },
    "shortages": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "part_number": { "type": "string" },
          "description": { "type": "string" },
          "required_qty": { "type": "number" },
          "available_qty": { "type": "number" },
          "shortage_qty": { "type": "number" },
          "has_approved_substitute": { "type": "boolean" },
          "substitute_available_qty": { "type": "number" },
          "estimated_arrival_date": { "type": ["string", "null"], "format": "date" },
          "lead_time_days": { "type": "integer" }
        }
      }
    },
    "substitute_resolution": {
      "type": "array",
      "description": "Auto-resolved shortages using approved substitutes",
      "items": {
        "type": "object",
        "properties": {
          "original_part": { "type": "string" },
          "substitute_part": { "type": "string" },
          "qty_from_substitute": { "type": "number" },
          "cost_delta": { "type": "number" }
        }
      }
    }
  }
}
```

## 5.3 Allocation and Reservation

When a work order is created from a BOM, materials are **allocated** (soft reserve) and then **issued** (hard consume):

1. **Allocation**: `allocated_qty` increases on each component; `available = on_hand - allocated`
2. **Picking**: Materials are issued to the work order; `on_hand_qty` decreases, `allocated_qty` decreases
3. **Backflush option**: For small shops, materials can be auto-consumed upon work order completion rather than individually picked

------

## 6. QuickBooks Cost Accounting Integration

## 6.1 Integration Architecture

The integration follows the pattern used by manufacturing add-ons like Fishbowl, Katana, and Digit — the BOM system acts as the manufacturing system of record while QuickBooks Online (QBO) remains the financial system of record.

```
text┌─────────────────────┐        REST API        ┌──────────────────┐
│   BOM/MFG Module    │◄──────────────────────►│  QuickBooks Online│
│                     │                         │                  │
│ • Item Master       │  ──── Items ────►       │ • Products/Svcs  │
│ • Work Orders       │  ──── COGS Journal ──►  │ • Journal Entries│
│ • Purchase Orders   │  ──── Bills ────►       │ • Bills          │
│ • Cost Rollups      │  ──── Inv Adjust ──►    │ • Inventory Adj  │
│ • Sales Shipments   │  ──── COGS ────►        │ • Expense Accts  │
└─────────────────────┘                         └──────────────────┘
```

## 6.2 Account Mapping

| Manufacturing Event   | QBO Account (Debit)             | QBO Account (Credit)            | Trigger              |
| :-------------------- | :------------------------------ | :------------------------------ | :------------------- |
| Raw material purchase | Inventory Asset (Raw Materials) | Accounts Payable                | PO receipt           |
| Material issued to WO | WIP Inventory                   | Inventory Asset (Raw Materials) | Work order pick      |
| Labor recorded        | WIP Inventory                   | Accrued Labor                   | Timecard entry       |
| WO completed          | Finished Goods Inventory        | WIP Inventory                   | Work order close     |
| Product shipped/sold  | COGS                            | Finished Goods Inventory        | Sales order delivery |

## 6.3 Sync Operations

**Item Sync (Bidirectional)**

```
json{
  "operation": "sync_item",
  "direction": "bom_to_qbo",
  "mapping": {
    "part_number": "Sku",
    "description": "Name",
    "item_type_map": {
      "raw_material": "Inventory",
      "purchased_part": "Inventory",
      "finished_good": "Inventory",
      "consumable": "NonInventory",
      "sub_assembly": "Inventory"
    },
    "standard_cost": "PurchaseCost",
    "sale_price": "UnitPrice",
    "asset_account": "Inventory Asset",
    "expense_account": "Cost of Goods Sold",
    "income_account": "Sales Revenue"
  }
}
```

**COGS Sync**: When sales orders are delivered, COGS is automatically sent to QuickBooks — the selected expense account increases and the inventory asset account decreases. The cost value is derived from the BOM cost rollup, ensuring the COGS posted to QBO reflects actual material, labor, and overhead costs rather than a simple purchase price.

**WIP Tracking**: For small manufacturers, a simplified two-account WIP model is recommended:

- **WIP Inventory** — debited as materials and labor are consumed
- **Finished Goods Inventory** — debited when the work order completes, WIP credited

## 6.4 Sync Configuration Schema

```
json{
  "title": "QuickBooksIntegrationConfig",
  "type": "object",
  "properties": {
    "qbo_realm_id": { "type": "string" },
    "sync_frequency": { "type": "string", "enum": ["real_time", "hourly", "daily"] },
    "account_mappings": {
      "type": "object",
      "properties": {
        "raw_material_asset_account": { "type": "string", "default": "Inventory Asset" },
        "wip_account": { "type": "string", "default": "Work in Progress" },
        "finished_goods_account": { "type": "string", "default": "Finished Goods" },
        "cogs_account": { "type": "string", "default": "Cost of Goods Sold" },
        "labor_expense_account": { "type": "string", "default": "Direct Labor" },
        "overhead_expense_account": { "type": "string", "default": "Manufacturing Overhead" }
      }
    },
    "sync_options": {
      "type": "object",
      "properties": {
        "auto_sync_items": { "type": "boolean", "default": true },
        "auto_sync_cogs": { "type": "boolean", "default": true },
        "auto_sync_inventory_adjustments": { "type": "boolean", "default": true },
        "create_journal_entries_for_wip": { "type": "boolean", "default": false },
        "use_standard_cost_for_cogs": { "type": "boolean", "default": true }
      }
    },
    "conflict_resolution": {
      "type": "string",
      "enum": ["bom_wins", "qbo_wins", "manual_review"],
      "default": "bom_wins",
      "description": "When item data conflicts between systems"
    }
  }
}
```

------

## 7. AI-Assisted BOM Generation and Validation

## 7.1 Capabilities Overview

AI tools now automate BOM creation by reading design data, recognizing components, relationships, and quantities with high accuracy. For small manufacturers, AI assistance focuses on two high-value use cases: generating BOMs from plain-language descriptions and validating existing BOMs for errors and optimization opportunities.

## 7.2 BOM Generation from Natural Language

**Input**: A user describes a product in plain English.

**Processing Pipeline**:

1. **NLP Extraction** — Parse the description to identify components, quantities, materials, and relationships using natural language processing
2. **Part Matching** — Match extracted part names to existing Item Master entries using fuzzy matching and NLP-based SKU matching
3. **Hierarchy Inference** — Determine parent-child assembly relationships from context clues ("attached to," "inside of," "bolted onto")
4. **Quantity and UOM Resolution** — Extract or infer quantities and units
5. **Validation Pass** — Verify generated part numbers conform to predefined coding logic and that references match existing master data
6. **Human Review** — Present the draft BOM for user confirmation before saving. Human-in-the-loop verification is required before final approval, focusing on cases flagged where confidence is low or new component categories emerge

**Example Interaction**:

```
textUSER INPUT:
"I need a BOM for our standard wall-mount bracket. It's made from 
16-gauge steel sheet, about 8x10 inches. We use four 1/4-20 hex bolts 
with lock washers and nuts. There's also a rubber gasket between the 
bracket and the wall plate. Oh and we powder coat the bracket."

AI OUTPUT (Draft BOM):
{
  "ai_confidence": 0.87,
  "suggested_bom": {
    "parent": {
      "part_number": "ASM-BRKT-WALL-001",
      "description": "Standard Wall-Mount Bracket Assembly",
      "item_type": "finished_good"
    },
    "lines": [
      {
        "line": 1,
        "part_number_suggestion": "RAW-STL-16GA",
        "matched_existing": "RAW-STL-1018-16GA",
        "match_confidence": 0.92,
        "description": "16 Gauge Steel Sheet",
        "quantity_per": 0.556,
        "uom": "SQ_FT",
        "notes": "Calculated from 8x10 inch cut size + 10% scrap"
      },
      {
        "line": 2,
        "part_number_suggestion": "PUR-BOLT-0.25-20-HEX",
        "matched_existing": "PUR-HW-BOLT-1420",
        "match_confidence": 0.95,
        "description": "1/4-20 Hex Bolt",
        "quantity_per": 4,
        "uom": "EA"
      },
      {
        "line": 3,
        "part_number_suggestion": "PUR-WASH-LOCK-0.25",
        "matched_existing": null,
        "match_confidence": 0,
        "description": "1/4\" Lock Washer",
        "quantity_per": 4,
        "uom": "EA",
        "flags": ["NEW_ITEM_REQUIRED"]
      },
      {
        "line": 4,
        "part_number_suggestion": "PUR-NUT-0.25-20",
        "matched_existing": "PUR-HW-NUT-1420",
        "match_confidence": 0.94,
        "description": "1/4-20 Hex Nut",
        "quantity_per": 4,
        "uom": "EA"
      },
      {
        "line": 5,
        "part_number_suggestion": "PUR-GSKT-RBR-WALL",
        "matched_existing": null,
        "match_confidence": 0,
        "description": "Rubber Gasket - Wall Mount",
        "quantity_per": 1,
        "uom": "EA",
        "flags": ["NEW_ITEM_REQUIRED"]
      },
      {
        "line": 6,
        "part_number_suggestion": "SVC-PWDRCOAT",
        "matched_existing": "SVC-FINISH-POWDER",
        "match_confidence": 0.88,
        "description": "Powder Coat Finish",
        "quantity_per": 1,
        "uom": "EA",
        "item_type": "subcontract"
      }
    ],
    "warnings": [
      "Wall plate mentioned but not included — is it a separate assembly?",
      "Bolt length not specified — defaulting to 1\". Please verify.",
      "2 new items would need to be created in Item Master."
    ]
  }
}
```

## 7.3 AI BOM Validation Rules

The validation engine checks existing BOMs against learned patterns and rules:

| Validation Category | Checks Performed                                             |
| :------------------ | :----------------------------------------------------------- |
| **Structural**      | Circular references, orphan items, missing leaf nodes, phantom BOMs with no children |
| **Quantity**        | Zero or negative quantities, unusually high quantities (>3σ from historical), fractional quantities for integer-UOM items |
| **Completeness**    | Missing fasteners/hardware for assemblies with mechanical joints, missing consumables (adhesive, solder, paint) |
| **Cost**            | Cost outliers vs. similar BOMs, missing cost data on any line, cost exceeding target margin |
| **Substitution**    | Substitutes with different UOM but no conversion factor, unapproved substitutes on released BOMs |
| **Inventory**       | Components with zero inventory and no supplier, obsolete components still in active BOMs |

## 7.4 AI Implementation Architecture

```
text┌──────────────────┐    ┌───────────────────┐    ┌──────────────────┐
│  User Input      │    │   LLM + RAG       │    │  Validation      │
│  (plain text,    │───►│                   │───►│  Engine          │
│   voice, paste)  │    │ • Item Master KB  │    │                  │
│                  │    │ • Historical BOMs │    │ • Rule checks    │
└──────────────────┘    │ • Industry data   │    │ • Anomaly detect │
                        └───────────────────┘    │ • Confidence     │
                                                 │   scoring        │
                                                 └───────┬──────────┘
                                                         │
                                                         ▼
                                                 ┌──────────────────┐
                                                 │  Human Review    │
                                                 │  UI              │
                                                 │                  │
                                                 │ • Accept/reject  │
                                                 │ • Edit lines     │
                                                 │ • Create new     │
                                                 │   items          │
                                                 └──────────────────┘
```

The system uses Retrieval-Augmented Generation (RAG) with the company's own Item Master and historical BOMs as the knowledge base, combined with a general LLM for language understanding. Unlike rule-based systems, AI models trained on past designs and sourcing logs can make intelligent decisions like selecting compatible or cost-effective parts.

------

## 8. Full ERP BOM vs. Small Manufacturer Needs

Full-function ERP systems include extensive BOM modules with features like configurable BOMs, planning BOMs, multi-site BOM-by-site management, and deep integration with MRP II scheduling. Small manufacturers need a subset that delivers 80% of the value at 20% of the complexity.

| Capability                 | Full ERP (SAP, Oracle, Sage X3)                              | Small Mfg Module (This Spec)                                 | Rationale                                                    |
| :------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| **BOM levels**             | Unlimited depth, multi-site                                  | Up to 5 levels, single-site                                  | Small shops rarely exceed 3–4 levels                         |
| **BOM types**              | Production, Phantom, Planning, Configurable, Design          | Production, Phantom only                                     | Planning BOMs require full MRP II; configurable BOMs need CPQ engine |
| **Revision control**       | Full ECR → ECO → CCB workflow with multi-department approval chains | Simplified 3-stage change process with 1–2 approvers         | Small teams don't have separate CCBs                         |
| **Cost rollup**            | 7+ cost elements, multi-currency, transfer pricing, activity-based costing | 5 cost elements, single currency, standard/average costing   | Eliminates unnecessary complexity                            |
| **Routing integration**    | Detailed work center scheduling, capacity planning, finite scheduling | Simple sequential routing for costing only                   | Small shops schedule on whiteboards or simple Gantt charts   |
| **Inventory**              | Multi-warehouse, lot/serial tracking, bin management, cycle counting | Single location, optional lot tracking, reorder points       | One building, one stockroom                                  |
| **Substitutions**          | Form-fit-function analysis, approved vendor lists, qualification tracking | Simple priority-ranked substitutes with approval flag        | No formal qualification process                              |
| **MRP/MPS**                | Full Material Requirements Planning and Master Production Scheduling | Simple "can we build this?" availability check + shortage report | MRP is overkill for job shops doing 5–20 orders/week         |
| **Accounting integration** | Native GL, multi-entity, intercompany transactions           | QuickBooks Online sync for COGS, inventory valuation, and WIP | QuickBooks is the dominant SMB accounting platform           |
| **AI/Automation**          | PLM integration, automated EBOM-to-MBOM conversion           | NLP-based BOM generation from plain text, validation rules   | Targets the "no CAD/PLM" small manufacturer                  |
| **Document management**    | Integrated PLM with version-controlled CAD files, drawings, specs | File attachments linked to BOM revisions                     | Small shops don't have PLM                                   |
| **Compliance**             | Full audit trail, FDA 21 CFR Part 11, AS9100, ITAR           | Basic audit log (who changed what, when)                     | Most small shops are not in regulated industries             |
| **Implementation time**    | 6–18 months                                                  | 1–2 weeks                                                    | Critical differentiator for adoption                         |

## Where Small Manufacturers Should Not Compromise

Despite simplification, certain capabilities remain essential even for 1–20 employee shops:

- **Accurate cost rollups** — Without knowing true product cost, pricing becomes guesswork and margins erode invisibly
- **Revision traceability** — Even informal shops need to know which version of a BOM was used for which customer order
- **Substitution management** — Supply chain disruptions hit small manufacturers hardest; pre-approved alternates keep production moving
- **Real-time inventory visibility** — A centralized BOM integrated with inventory keeps all teams on the same page and reduces production delays

------

## 9. API Endpoints Summary

| Endpoint                                    | Method           | Description                                      |
| :------------------------------------------ | :--------------- | :----------------------------------------------- |
| `/api/v1/items`                             | GET, POST        | List/create items in Item Master                 |
| `/api/v1/items/{id}`                        | GET, PUT, DELETE | Retrieve/update/deactivate a single item         |
| `/api/v1/boms`                              | GET, POST        | List/create BOMs                                 |
| `/api/v1/boms/{id}`                         | GET, PUT         | Retrieve/update a BOM (draft only)               |
| `/api/v1/boms/{id}/explode`                 | GET              | Multi-level explosion with `?levels=N` parameter |
| `/api/v1/boms/{id}/flatten`                 | GET              | Flattened indented BOM output                    |
| `/api/v1/boms/{id}/cost-rollup`             | POST             | Execute cost rollup; returns breakdown           |
| `/api/v1/boms/{id}/availability`            | POST             | Check material availability for `qty` units      |
| `/api/v1/boms/{id}/revisions`               | GET, POST        | List revisions / create new revision             |
| `/api/v1/boms/{id}/revisions/{rev}/diff`    | GET              | Compare two revisions                            |
| `/api/v1/boms/{id}/revisions/{rev}/release` | POST             | Release a revision (requires approval)           |
| `/api/v1/change-orders`                     | GET, POST        | List/create ECOs                                 |
| `/api/v1/change-orders/{id}/approve`        | POST             | Approve an ECO                                   |
| `/api/v1/ai/generate-bom`                   | POST             | Generate BOM from plain-text description         |
| `/api/v1/ai/validate-bom`                   | POST             | Validate an existing BOM                         |
| `/api/v1/sync/quickbooks/push`              | POST             | Push items, COGS, inventory to QBO               |
| `/api/v1/sync/quickbooks/status`            | GET              | Sync health and last-sync timestamps             |

------

## 10. Data Integrity and Business Rules

1. **No circular references** — The system must detect and reject any BOM save that would create a cycle in the assembly graph
2. **Single active revision** — Only one `released` revision per BOM at any time; releasing a new version auto-supersedes the prior one
3. **Immutable releases** — Released BOM revisions cannot be edited; changes require a new revision via ECO
4. **Cascade awareness** — Changing a sub-assembly BOM triggers notifications to all parent BOMs that reference it; cost rollups for parents are flagged as stale
5. **UOM consistency** — BOM line UOM must be convertible to the child item's base UOM via defined conversion factors
6. **Orphan detection** — Nightly job identifies items in the Item Master that are not referenced by any active BOM and have zero inventory
7. **Cost staleness** — Cost rollups older than a configurable threshold (default: 7 days) are visually flagged as potentially outdated
8. **Substitution constraints** — Substitutes must share the same `item_type` classification or be explicitly approved with a conversion factor

------

This specification provides a complete technical foundation for implementing a BOM module that balances manufacturing rigor with the practical constraints of small shops. The architecture supports growth from simple single-level BOMs to multi-level assemblies with full cost visibility, while keeping the daily workflow accessible to non-engineers who may be building, purchasing, and accounting in the same afternoon.