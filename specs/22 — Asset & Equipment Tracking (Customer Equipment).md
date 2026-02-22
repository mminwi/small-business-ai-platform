Core data model (entities and relationships)

You want a customer-owned Asset entity linked to Customer, Service Location, Work Orders, Parts, and Contracts.

Key entities (module-level):

Customer

ServiceLocation (site, property, building, unit)

Asset (piece of equipment or vehicle)

AssetAttribute (flex fields)

WorkOrder (job / repair order)

WorkOrderLineItem (labor/part lines)

AssetServiceHistory (denormalized view)

AssetDocument (photos, manuals, warranty)

Part / InventoryItem (separate module, just referenced here)

Contract (maintenance agreement, warranty plan)

ContractCoverage (which assets or locations are covered)

Warranty (manufacturer or extended warranty per asset)

Core relationships:

Customer 1–N ServiceLocation.

ServiceLocation 1–N Asset.

Asset 1–N AssetAttribute.

Asset 1–N AssetServiceHistory (or derived from WorkOrder).

Asset 1–N AssetDocument.

Asset 1–N Warranty.

WorkOrder N–1 ServiceLocation, N–1 Customer.

WorkOrder 0–N related Assets (many-to-many via WorkOrderAsset link, but usually 1 asset for HVAC/vehicle jobs).

WorkOrderLineItem 0–N related Assets (for multi-asset jobs, line items can tie to different assets).

Contract 1–N ContractCoverage; coverage can reference:

A ServiceLocation (all qualifying assets at this address), or

A specific Asset (by id/serial/model).

Cross‑industry “universal” Asset fields:

Identity: id, asset_type (HVAC, vehicle, pool_equipment, elevator, appliance, generic), display_name, status (active/inactive/retired).

Relationship: customer_id, service_location_id.

Physical: manufacturer, model, serial_number, year_of_manufacture, install_date, purchase_date, asset_tag (QR/barcode), external_ids (from other systems).

Operational: current_usage_metric (e.g., mileage, hours), usage_unit (miles, hours, cycles), last_service_date, next_service_due_date.

Lifecycle: condition_rating (1–5 or enum), age_category (new, mid, end_of_life), replacement_recommended (bool).

Warranty summary: manufacturer_warranty_expires_on, in_warranty (bool), extended_warranty_expires_on (optional, can also be normalized in Warranty table).

Meta: created_at, updated_at, created_by, updated_by, notes.

Industry-specific examples handled by AssetAttribute:

HVAC: refrigerant_type, tonnage, seer_rating, filter_size, airflow_cfm, fuel_type (gas/electric/oil), heat_exchanger_condition.

Auto: vin, license_plate, year, trim, engine_size, transmission_type, current_mileage, last_oil_change_mileage.

Pool: pump_hp, filter_type, pool_volume_gallons, sanitizer_type, salt_ppm_history, ph_history.

Appliances: energy_star_rating, capacity_cu_ft, installation_type (freestanding/built-in), power_type (gas/electric).

Elevator: number_of_stops, controller_type, elevator_type (hydraulic/traction), load_capacity, inspection_due_date.

Relation to Work Orders:

WorkOrder references one or more Asset ids; the AssetServiceHistory is a lightweight summary of each completed work order against that asset.

WorkOrderLineItem referencing Part/InventoryItem includes an optional asset_id to record which asset the part was installed on.

This gives:

Service history by asset.

Parts installed history by asset (including serial numbers for serialized parts).

Labor/time spent on that asset.

Relation to Parts/Inventory:

Inventory module owns Part / InventoryItem, with optional serialization.
​

AssetServiceHistory and WorkOrderLineItem store the linkage to part_id and, if applicable, part_serial_number.

This enables:

Warranty lookups for installed parts.

Recall queries (all assets with installed Part X).

Relation to Contracts:

ContractCoverage can point at:

location_id only (all assets of specified types at this site), or

asset_id (explicit inclusion for that serial).

Asset record stores coverage flags/denormalized fields like is_under_contract and contract_id(s) for fast queries.

For “all HVAC at this address”, the logic is: contract_coverage.scope_type=“location”, coverage_asset_type_filter=["HVAC"].

JSON schemas (representative)

These are representative, not exhaustive, and designed to live as JSON files in Google Drive/SharePoint with a stable shape.

2.1 Asset schema

json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Asset",
  "type": "object",
  "required": [
    "id",
    "customer_id",
    "service_location_id",
    "asset_type",
    "display_name",
    "status"
  ],
  "properties": {
    "id": { "type": "string" },
    "customer_id": { "type": "string" },
    "service_location_id": { "type": "string" },

    "asset_type": {
      "type": "string",
      "enum": [
        "HVAC",
        "vehicle",
        "pool_equipment",
        "appliance",
        "elevator",
        "generic"
      ]
    },
    "subtype": {
      "type": "string",
      "description": "e.g. furnace, heat_pump, condenser, pump, filter"
    },
    "display_name": { "type": "string" },
    "status": {
      "type": "string",
      "enum": ["active", "inactive", "retired"]
    },

    "manufacturer": { "type": "string" },
    "model": { "type": "string" },
    "serial_number": { "type": "string" },
    "year_of_manufacture": { "type": ["integer", "null"] },

    "install_date": { "type": ["string", "null"], "format": "date" },
    "purchase_date": { "type": ["string", "null"], "format": "date" },

    "asset_tag": {
      "type": ["string", "null"],
      "description": "Human-readable tag ID printed on barcode/QR"
    },
    "barcode_value": {
      "type": ["string", "null"],
      "description": "Raw value encoded in barcode/QR"
    },

    "current_usage_metric": {
      "type": ["number", "null"],
      "description": "Mileage, hours, cycles, etc."
    },
    "usage_unit": {
      "type": ["string", "null"],
      "enum": ["miles", "hours", "cycles", "none"]
    },

    "last_service_date": { "type": ["string", "null"], "format": "date" },
    "next_service_due_date": { "type": ["string", "null"], "format": "date" },

    "condition_rating": {
      "type": ["integer", "null"],
      "minimum": 1,
      "maximum": 5
    },
    "age_category": {
      "type": ["string", "null"],
      "enum": ["new", "mid_life", "end_of_life"]
    },
    "replacement_recommended": { "type": "boolean", "default": false },

    "manufacturer_warranty_expires_on": {
      "type": ["string", "null"],
      "format": "date"
    },
    "extended_warranty_expires_on": {
      "type": ["string", "null"],
      "format": "date"
    },
    "in_warranty": { "type": "boolean", "default": false },

    "contract_ids": {
      "type": "array",
      "items": { "type": "string" }
    },

    "attributes": {
      "type": "array",
      "items": { "$ref": "#/definitions/AssetAttribute" }
    },

    "meta": {
      "type": "object",
      "properties": {
        "created_at": { "type": "string", "format": "date-time" },
        "created_by": { "type": "string" },
        "updated_at": { "type": "string", "format": "date-time" },
        "updated_by": { "type": "string" }
      }
    },

    "notes": { "type": "string" }
  },
  "definitions": {
    "AssetAttribute": {
      "type": "object",
      "required": ["key", "value"],
      "properties": {
        "key": { "type": "string" },
        "value": { "type": ["string", "number", "boolean", "null"] },
        "unit": { "type": ["string", "null"] },
        "source": {
          "type": ["string", "null"],
          "description": "manual, scanned, imported"
        }
      }
    }
  }
}
2.2 AssetAttribute as a standalone schema

If you store attributes as separate JSON objects (e.g., in their own file or collection):

json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AssetAttribute",
  "type": "object",
  "required": ["id", "asset_id", "key", "value"],
  "properties": {
    "id": { "type": "string" },
    "asset_id": { "type": "string" },
    "key": { "type": "string" },
    "value": { "type": ["string", "number", "boolean", "null"] },
    "unit": { "type": ["string", "null"] },
    "source": {
      "type": ["string", "null"],
      "enum": ["manual", "scanned", "imported", "system"]
    },
    "created_at": { "type": "string", "format": "date-time" },
    "created_by": { "type": "string" },
    "updated_at": { "type": "string", "format": "date-time" },
    "updated_by": { "type": "string" }
  }
}
2.3 AssetServiceHistory schema (summary per work order)

json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AssetServiceHistory",
  "type": "object",
  "required": ["id", "asset_id", "work_order_id", "service_date"],
  "properties": {
    "id": { "type": "string" },
    "asset_id": { "type": "string" },
    "work_order_id": { "type": "string" },
    "customer_id": { "type": "string" },
    "service_location_id": { "type": "string" },

    "service_date": { "type": "string", "format": "date-time" },
    "technician_ids": {
      "type": "array",
      "items": { "type": "string" }
    },

    "summary": {
      "type": "string",
      "description": "Short natural-language summary of work performed"
    },
    "problem_description": { "type": ["string", "null"] },
    "cause_description": { "type": ["string", "null"] },
    "resolution_description": { "type": ["string", "null"] },

    "usage_at_service": {
      "type": ["number", "null"],
      "description": "Mileage, hours, etc. at time of service"
    },
    "usage_unit": {
      "type": ["string", "null"],
      "enum": ["miles", "hours", "cycles", "none"]
    },

    "readings": {
      "type": "array",
      "description": "Measurements taken during service",
      "items": {
        "type": "object",
        "required": ["name", "value"],
        "properties": {
          "name": { "type": "string" },
          "value": { "type": ["number", "string"] },
          "unit": { "type": ["string", "null"] }
        }
      }
    },

    "parts_installed": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["part_id", "quantity"],
        "properties": {
          "part_id": { "type": "string" },
          "part_name": { "type": "string" },
          "quantity": { "type": "number" },
          "part_serial_number": { "type": ["string", "null"] },
          "under_part_warranty": { "type": "boolean", "default": false }
        }
      }
    },

    "labor_hours": { "type": ["number", "null"] },
    "condition_rating_after_service": {
      "type": ["integer", "null"],
      "minimum": 1,
      "maximum": 5
    },
    "follow_up_recommended": { "type": "boolean", "default": false },
    "next_recommended_service_date": {
      "type": ["string", "null"],
      "format": "date"
    },

    "attachments": {
      "type": "array",
      "items": { "type": "string" },
      "description": "IDs of AssetDocument or WorkOrderDocument entries"
    }
  }
}
2.4 AssetDocument schema

json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "AssetDocument",
  "type": "object",
  "required": ["id", "asset_id", "document_type", "storage_url"],
  "properties": {
    "id": { "type": "string" },
    "asset_id": { "type": "string" },
    "customer_id": { "type": ["string", "null"] },
    "service_location_id": { "type": ["string", "null"] },

    "document_type": {
      "type": "string",
      "enum": [
        "photo",
        "installation_photo",
        "nameplate_photo",
        "wiring_diagram",
        "manual",
        "invoice",
        "warranty_card",
        "other"
      ]
    },
    "title": { "type": "string" },
    "description": { "type": ["string", "null"] },

    "storage_provider": {
      "type": "string",
      "enum": ["google_drive", "sharepoint", "other"]
    },
    "storage_url": { "type": "string" },
    "file_mime_type": { "type": ["string", "null"] },

    "tags": {
      "type": "array",
      "items": { "type": "string" }
    },

    "uploaded_at": { "type": "string", "format": "date-time" },
    "uploaded_by": { "type": "string" }
  }
}
Asset identification (barcode/QR, serial, “not found” flow)

Best practices from asset tracking/CMMS:

Use unique asset tags with barcodes/QR to identify each asset.

Support both system-generated tags and manufacturer nameplate / serial recognition.

Recommended flows:

AssetTag:

Each asset has asset_tag (human-readable ID) and barcode_value (what’s encoded).

Technician in the field:

Scans QR or barcode.

Client matches barcode_value to an Asset record.

If multiple matches (rare), AI asks for disambiguation (location, type).

If no match:

AI prompts: “This unit isn’t in the system. Do you want to create a new asset linked to [customer/location]?” and pre-fills data from:

Work order context (customer, location).

Previous assets at that site (guess type).

Computer vision/nameplate OCR (if you add that later).

Serial number lookup:

Allow search by serial_number, model + serial, or VIN for vehicles.

AI can normalize formats (e.g., strip spaces, handle leading zeros).

AI behavior when asset not found:

Confirm context:

“Are you servicing this at [123 Main St, Unit 3B] for [Customer]?”

Suggest asset type:

Based on work order job type (AC repair → asset_type=HVAC, subtype=condenser).

Ask minimal required fields:

Manufacturer, model, serial, install date (if known).

Optional photo of nameplate/manual.

Create asset JSON record:

Fill id, customer_id, service_location_id, asset_type, display_name, status="active".

Add auto-created AssetDocument entries for photos.

Attach new asset_id to current WorkOrder and subsequent AssetServiceHistory.

You can implement a “draft asset” state (status="pending_details") if tech doesn’t have all info; AI later prompts office/admin to complete missing data.

Service history capture on asset

When a work order is completed, you want a complete, structured maintenance record for the asset.

Capture at minimum:

Linkage:

asset_id(s), work_order_id, customer_id, service_location_id, technician_ids.

Time and usage:

service_date/time.

usage_at_service (mileage/hours) and unit.

Operational readings:

Generic readings array in AssetServiceHistory:

For HVAC: suction_pressure, head_pressure, superheat, subcool, return_air_temp, supply_air_temp, delta_t.

For vehicles: oil_pressure, tire_tread_depth, brake_pad_thickness, battery_voltage.

For pool: chlorine_ppm, ph, alkalinity.

AI can parse technician free-text “notes” into normalized readings when possible.

Work summary:

problem_description (customer complaint).

cause_description.

resolution_description.

short summary for quick view.

Parts installed and removed:

part_id, part_name, quantity.

part_serial_number (for serialized parts).
​

whether each part is under manufacturer or parts warranty.

Condition:

condition_rating_after_service (1–5, or enum).

recommended_actions, follow_up_recommended, next_recommended_service_date.

Warranty impact:

Whether work was warranty labor, whether replacement part is warranty replacement.

Any notes that might impact future warranty claims.

Persist these as:

WorkOrder primary record (for billing and job management).

One AssetServiceHistory per asset involved (denormalized, light but fast to query).

Optionally, AI-generated “service summary” text for customer-facing communication.

Warranty tracking (manufacturer and extended)

You need both date-based and usage-based warranty logic.
​

Model:

Warranty entity (normalized), referenced from Asset and sometimes Part:

warranty_type: manufacturer, extended, service, parts_only, labor_only.

asset_id (optional, for asset-level warranties).

part_id / part_serial_number (for component warranties).

provider_name, provider_contact.

start_date, end_date (for date-based).

usage_limit (e.g., 100000 miles).

coverage_description, exclusions.

Asset-level denormalized fields:

manufacturer_warranty_expires_on.

extended_warranty_expires_on.

in_warranty (derived from today vs end_date and usage).

Logic:

For date-based warranties:

Determine start_date from install_date or purchase_date.

Store warranty_duration_months or explicit end_date.

For usage-based warranties:

Store usage_limit and usage_unit (miles/hours).

Evaluate in_warranty if current_usage_metric <= usage_limit.

Service-time evaluation:

When generating a work order or closing one, AI should:

Check asset’s warranty records and parts warranties.

Flag if work should be coded as warranty.

Alerts:

Background scheduler scanning assets where:

warranty_expires_on within next N days (e.g., 30/60/90).

usage_metric within 10% of usage_limit.

Creates tasks or sends messages like:

“Warranty on your AC unit at 123 Main St ends on 2026‑06‑15; would you like an extended plan?”

Extended warranties and service plans:

Represent as Contract records with coverage rules; also create associated Warranty documents so they’re discoverable in the asset record.

Integration with work orders (UX + AI behavior)

Best practice from field service and auto shop tools is to surface equipment history at job open and during inspections.

When a technician opens a WorkOrder:

Pre-load asset context:

If work order already has asset_id(s):

Display core asset info: model, serial, age, last_service_date, warranty status.

Show key attributes (e.g., VIN, refrigerant type).

If no asset bound:

Prompt to select from asset list at this location or create new via scan.

AI proactive history:

Short timeline of last 3–5 service visits on that asset:

Date, summary, parts installed, condition rating.

Highlight open issues:

Prior “deferred repairs” or “monitor” notes (e.g., “Heat exchanger cracked, recommended replacement”).

Example AI hint:

“This furnace was serviced 6 months ago; the tech noted a cracked heat exchanger and recommended replacement. Confirm whether this was completed before proceeding.”

During diagnosis:

AI can suggest checks based on asset type, age, and repeated issues (e.g., repeated lockouts).

At work order close:

AI reads technician notes, line items, and readings, and writes structured AssetServiceHistory plus an updated Asset snapshot:

Updates last_service_date, current_usage_metric, condition_rating, next_service_due_date.

Integration with recurring contracts

Contracts/maintenance agreements are a major value driver in systems like ServiceTitan and Jobber.

Model:

Contract:

id, customer_id.

contract_type: maintenance, extended_warranty, inspection_only.

start_date, end_date, auto_renew.

billing_terms (monthly, annual, per-visit).

ContractCoverage:

id, contract_id.

scope_type: "location" or "asset".

service_location_id (if scope_type="location").

asset_id (if scope_type="asset").

asset_type_filter (optional list, e.g. ["HVAC"]).

include_new_assets_automatically (bool).

How the asset module uses this:

On asset creation:

Check contracts for that customer/location where:

scope_type="location".

asset_type_filter is null or includes this asset_type.

If include_new_assets_automatically=true, mark asset as covered and append contract_id.

On contract creation:

AI proposes a coverage list:

“This HVAC maintenance agreement could cover the following 3 units at 123 Main St. Confirm which to include.”

When scheduling recurring work:

Jobs generated from Contract reference included assets.

Each recurring visit gets associated AssetServiceHistory entries.

Multi-location and multi-asset customers

Goal: handle property managers or fleet customers with many assets but stay simple.

Data model patterns:

ServiceLocation includes hierarchy:

property_id (optional), unit_identifier (e.g., “Apt 3B” or “Suite 210”), geo coordinates.

Asset grouping:

For HVAC: fields like building_id, floor, zone, system_group_name (e.g., “RTU-1”).

For fleet: fleet_id or grouping by customer with tag “fleet_vehicle”.

Bulk operations:

Queries to list all assets for:

a customer.

a location.

a property group (e.g., all units in building).

Actions:

Bulk status change (retire older units).

Bulk contract coverage assignment.

Bulk alerts for overdue service.

You can keep this from turning into full ERP by:

Not modeling arbitrary hierarchies; stick to Customer → Location → Asset.

Use tags or simple grouping attributes instead of complex parent-child relationships between assets.

Keep bulk operations simple: filtered lists + mass-select actions.

Example JSON pattern for a multi-asset customer:

One Customer JSON.

Many ServiceLocation JSON entries (per property or per unit).

Many Asset JSON entries referencing each ServiceLocation; each with attributes for identification (e.g., “Building 5 – Roof – RTU 3”).

AI assistance opportunities

There are strong opportunities to leverage Claude across the lifecycle.

Key use cases:

Data ingestion and normalization:

Parse technician notes into structured readings, problem/cause/resolution.

Extract manufacturer/model/serial from nameplate photos or scanned documents (using OCR + Claude).

Normalize VINs, plate numbers, refrigerant types, filter sizes into standardized values.

Proactive maintenance recommendations:

Use rules plus simple heuristics:

“For residential split AC, recommend annual tune-up; for vehicles, oil changes every X miles.”

Combine asset age, service history, and usage to suggest:

“This 14‑year-old furnace with repeated ignition failures might be better replaced. Draft a replacement quote.”

Overdue and upcoming service:

Periodic process to:

Identify assets past next_service_due_date or with long time since last_service_date.

Rank by risk (asset type, condition, contract status).

Draft outreach emails/SMS for the owner.

Warranty and upsell intelligence:

Detect warranties expiring within 30–90 days.

Draft offers:

“Your vehicle powertrain warranty ends in 30 days; here’s an extended warranty option.”

Suggest extended service plans for high-failure brands or models.

Pattern analysis:

Across JSON history:

Compute MTBF (mean time between failures) per brand/model.

Identify patterns like “Brand X 3‑ton condensers at 8–10 years show rising compressor failures.”

Feed these into:

Internal advisories (“Consider carrying extra compressors for Brand X”) and customer recommendations (“We see higher failure rates for this unit at your age”).

Technician guidance in the field:

Context-aware prompts:

“Tech John is at elevator #2; show last inspection items and open deficiencies.”

Interactive checklists based on asset type and history.

Comparison and minimum viable implementation

High-level comparison of how major tools approach equipment tracking (simplified):

Platform	Customer equipment tracking focus	Key capabilities (relevant here)	Target scale/use case
ServiceTitan	Strong equipment module	Customer equipment records per location, warranties, service history, forms, scanning, contract integration.
Mid–large HVAC/plumbing/electrical shops
Jobber	Simpler equipment tracking	Basic equipment records and history; less deep inventory/equipment integration.
​	Small service businesses needing light tracking
RepairShopr	Focus on inventory/repair	RMA and inventory integration; tracks serialized inventory and repairs more than long-lived installed equipment.
Computer/IT repair, mixed inventory-heavy shops
Shop-Ware	Vehicle-centric history	Vehicle record + digital inspections + detailed history visible inside workflow.
Auto repair shops of various sizes
Minimum viable implementation (MVP) for your target users

For a 3-person HVAC shop:

Data model:

Asset with basic fields: asset_type, manufacturer, model, serial_number, install_date, location, notes.

Simple attributes: refrigerant_type, filter_size, tonnage.

Workflows:

Create assets when booking or at first visit (with AI assistance).

Associate work orders to a single asset.

On work order close:

Capture basic service summary and date.

Record a few key readings and parts installed.

Warranty:

Single date-based manufacturer_warranty_expires_on field and simple in_warranty flag.

Identification:

Manual search by customer/location + equipment nickname.

Optional QR/label printing if they want it – but not required for MVP.

UI/AI:

“Customer equipment” tab per location listing units and last service date.

AI-generated “last visit summary” when opening a job for an asset.

For a 10-person auto repair shop:

Data model:

Asset with asset_type="vehicle"; required fields: vin, year, make, model, license_plate, current_mileage.

Service history with mileage at each visit.

Workflows:

Vehicle created at first appointment (ideally via VIN decode in future).

Each work order tied to one vehicle.

On close:

Record odometer, main complaint, cause, correction.

Parts installed with part_serial_number where relevant.

Warranty:

Track vehicle warranty where applicable plus parts/labor warranty durations.

Identification:

Search by customer, license plate, VIN, last 8 of VIN.

UI/AI:

“Vehicle profile” view with maintenance history, recommended services (oil change, tires, brakes).

AI to propose maintenance packages based on mileage and history, similar to how digital vehicle inspection tools present recommended work.

For both cases you can phase in complexity:

Phase 1: Basic equipment/vehicle records + manual history entries.

Phase 2: Structured service history with parts and readings + simple warranties.

Phase 3: Contract integration, QR scanning, and AI-driven recommendations and outreach.

This spec gives you a concrete data model (Asset + attributes + history + documents), JSON schemas, and the integration touchpoints with work orders, contracts, and AI flows that map cleanly onto small service-business workflows while leaving room to grow toward more ServiceTitan-like depth over time.