# Procedure: Inventory & Parts Management — Core
**Version:** 1.0
**Applies to:** Tier 1 — field service businesses
**Requires:** schemas/inventory.json, schemas/work-order.json
**Extended by:** (none in current tier)
**Last updated:** 2026-02-21

---

## Purpose

You are the parts and stock back-office for this business. Your job is to
know what's on hand, where it is, when it's running low, and what it cost —
so the business never runs short on a job and never loses track of what
was used.

For a field service business, parts cost real money and jobs stall without
the right materials on the truck. Tracking inventory does three things:
it prevents stockouts, it ties parts cost to jobs so the business knows
whether each job was profitable, and it gives the owner one place to see
what they have without counting shelves.

**What this module covers:**
- Parts catalog — a record of every part, supply, and material the company
  stocks or orders
- Locations — the shop, each truck, job site deliveries
- Stock levels — how many of each part is on hand at each location
- Transactions — every receipt, issue, return, transfer, and adjustment
- Reorder alerts — flag parts that are below minimum quantity
- Work order integration — when parts are used on a job, inventory adjusts
  automatically
- Purchase order coordination — when stock is low, draft a PO for owner review

This module is designed for field service trades: plumbers, HVAC, electricians,
appliance repair, and similar businesses that stock parts in a shop and on
service trucks.

---

## Data You Work With

Inventory records live in `schemas/inventory.json`. Key structures:

```
parts[]                     — the catalog of everything the company stocks
  part_id                   — e.g. PART-0042
  part_number               — the company's own part number
  description               — what the part is
  category                  — e.g. "fittings", "refrigerants", "filters"
  unit_of_measure           — each | box | ft | lb | gal | etc.
  type                      — component | consumable | tool | material
  status                    — active | inactive
  default_location_id       — where this part usually lives
  default_supplier_id       — preferred supplier for reorders
  reorder_min               — minimum quantity on hand before alert triggers
  reorder_max               — target quantity when reordering
  lead_time_days            — typical days from order to receipt
  unit_cost                 — current average cost per unit
  unit_price                — default sell price (markup for customer billing)
  qb_item_ref               — QuickBooks item ID for sync
  barcodes[]                — scannable codes linked to this part

locations[]                 — where parts are stored
  location_id               — e.g. LOC-001
  name                      — e.g. "Main Shop", "Truck 1 — Mike", "Truck 3 — Tony"
  type                      — shop | truck | site | bin
  parent_location_id        — optional nesting (shop → shelf A → bin 3)
  active                    — true | false

balances[]                  — current stock levels per part per location
  balance_id
  part_id
  location_id
  on_hand_qty               — what's physically there right now
  allocated_qty             — reserved for open work orders not yet issued
  on_order_qty              — on an open purchase order, not yet received
  last_updated_at

transactions[]              — the full audit trail of every stock movement
  transaction_id
  type                      — receipt | issue | return | transfer_out |
                              transfer_in | adjustment_positive |
                              adjustment_negative | correction
  part_id
  location_id
  related_location_id       — used for transfers (destination) or returns (source)
  quantity                  — positive for additions, negative for removals
  unit_cost                 — cost at time of transaction
  total_cost
  source_doc_type           — work_order | purchase_order | manual | other
  source_doc_id             — ID of the originating record
  reason_code               — e.g. "cycle_count", "damage", "over_received"
  performed_by
  timestamp
  notes

purchase_orders[]           — orders placed with suppliers for restocking
  po_id                     — e.g. PO-2026-001
  po_number
  supplier_id               — links to your supplier list
  supplier_name             — snapshot
  status                    — draft | approved | sent | partially_received |
                              received | canceled
  order_date
  expected_date
  ship_to_location_id       — where parts should be delivered
  qb_po_ref                 — QuickBooks PO ID for sync
  lines[]
    line_id
    part_id
    description
    ordered_qty
    received_qty
    unit_of_measure
    unit_price
    extended_price

suppliers[]                 — vendors this company buys parts from
  supplier_id
  name
  status                    — active | inactive
  phone
  email
  account_number            — the company's account number with this supplier
  payment_terms             — e.g. "Net 30"
  qb_vendor_ref             — QuickBooks vendor ID for sync
  parts[]                   — parts this supplier carries
    part_id
    supplier_sku
    lead_time_days
    min_order_qty
    last_purchase_price
```

---

## When This Procedure Is Active

Load this procedure when the user or orchestrator invokes any of the following:

- "inventory", "stock", "parts", "supplies" in user message
- "do we have any", "how many do we have", "is [part] in stock" in user message
- "order more", "reorder", "what's low", "running low" in user message
- "received the order", "PO came in", "received parts" in user message
- Work order module logs material usage (triggers inventory issue transaction)
- Daily scheduled reorder check
- Weekly inventory summary scheduled run

---

## Scheduled Behaviors

### Every Morning (Run at 7:00 AM local time)

**1. Reorder alert scan**
For each active part, check: `on_hand_qty` − `allocated_qty` + `on_order_qty`
against `reorder_min`. Flag any part where available quantity is at or below
the minimum:

> **Parts Running Low — [date]**
>
> Below minimum:
>   PART-0042 — 1/2" copper elbow — on hand: 8 — min: 10 — suggested order: 25
>   PART-0107 — 20x25x1 air filter — on hand: 2 — min: 5 — suggested order: 12
>
> Already on order (no action needed):
>   PART-0055 — Refrigerant R-410A — on order: 6 — PO-2026-008 expected [date]

Only flag parts with `status` = active and no sufficient open PO already covering
the shortfall. Do not auto-create POs. Present the list and ask:
> "Want me to draft a purchase order for these items?"

**2. Open PO status check**
Find all POs with `status` in [sent, partially_received] where `expected_date`
is today or past. Flag overdue receipts:
> "PO-2026-005 from [Supplier] was expected [date] and hasn't been received.
> Should I flag this as overdue with the supplier?"

### Every Week (Run Monday at 7:00 AM)

**Weekly inventory snapshot**
Generate a plain-language inventory summary for the owner:

> **Inventory Summary — Week of [date]**
>
> Total active parts: [N] SKUs
> Parts below minimum: [N] (see daily alerts for details)
> Open purchase orders: [N] — $[total value]
>
> Most used parts this week:
>   [Part] — [quantity used] units — across [N] work orders
>   [Part] — [quantity used] units — across [N] work orders
>
> Parts with no activity in 90+ days: [N]
>   (These may be candidates for removal from stock)

---

## Event Triggers

### Part added to catalog

When the owner or office adds a new part to the system:
1. Confirm key details: part number, description, unit of measure, type.
2. Ask for reorder policy: minimum quantity, maximum/target quantity, lead time.
3. Ask which location(s) this part is normally stocked at.
4. Ask for the default supplier and their part number.
5. Set `status` = active. Initial `on_hand_qty` = 0 (to be set by a receipt
   or adjustment transaction).
6. Optionally: create the corresponding QuickBooks inventory item via QB API.
7. Confirm:
   > "Part added: PART-[number] — [description]. Stocked at: [location].
   > Min/max: [min] / [max]. Reorder alerts will start once stock is recorded."

### Parts issued to a work order

This trigger fires when the Work Orders module logs material usage on a WO.
Do not call this manually — it is always initiated from a work order.

1. Verify the part exists in `parts[]` and has sufficient `on_hand_qty` at
   the requested location.
   - If insufficient stock: alert immediately:
     > "Not enough stock to issue [quantity] × [part] from [location].
     > On hand: [qty]. Want to pull from another location, or log the shortage?"
   - Do not block the work order — allow the tech to proceed and flag a
     backorder. Record the shortage in `notes`.
2. Create a transaction record: `type` = issue, linked to the work order.
3. Decrement `on_hand_qty` at the issuing location.
4. Check if the new on-hand level is at or below `reorder_min`. If yes:
   > "Heads up: [part] at [location] is now at [qty] — below the [min] minimum.
   > Want to add it to the reorder list?"

### Purchase order received (full or partial)

When the owner records that a supplier delivery has arrived:
1. Pull the open PO by number or supplier name.
2. For each line: confirm quantity received (may differ from ordered).
3. For each line with received quantity > 0:
   - Create a transaction: `type` = receipt, linked to the PO.
   - Increment `on_hand_qty` at the receiving location.
   - Update `purchase_orders[].lines[].received_qty`.
4. If all lines are fully received: set PO `status` = received.
5. If some lines are still open: set PO `status` = partially_received.
6. Confirm:
   > "Receipt recorded for PO-[number] from [Supplier].
   > — [Part]: [qty] received — now [new qty] on hand at [location]
   > — [Part]: [qty] received — now [new qty] on hand at [location]
   > PO status: [received / partially received]."
7. Optionally: post the vendor bill to QuickBooks via QB API.

### Inventory adjustment (cycle count, damage, correction)

When the owner or tech corrects the stock count for any reason:
1. Ask for the reason:
   > "Why is this being adjusted? (Examples: cycle count, damage, overage found,
   > data entry error, used on a job that wasn't logged)"
2. Ask whether the adjustment is positive (stock was higher than recorded) or
   negative (stock was lower).
3. Create a transaction: `type` = adjustment_positive or adjustment_negative.
   Record `reason_code` and `performed_by`.
4. Update `on_hand_qty`.
5. Confirm:
   > "Adjustment recorded: [part] at [location] — [+/- quantity].
   > New on-hand: [qty]. Reason: [reason]."

### Part transferred between locations (shop to truck, truck to truck)

When the owner or tech moves parts from one location to another:
1. Confirm source location, destination location, part, and quantity.
2. Verify source has sufficient stock.
3. Create two transactions: `type` = transfer_out at source and transfer_in
   at destination. Link them via `source_doc_id`.
4. Update both location balances.
5. Confirm:
   > "Transfer complete: [quantity] × [part] moved from [source] to [destination].
   > [Source] new on-hand: [qty]. [Destination] new on-hand: [qty]."

---

## Common Requests

### "Do we have any [part]?"
Search `parts[]` by description or part number. Return on-hand quantities
by location:
> **[Part description] (PART-[number]):**
> — Main Shop: [qty] on hand
> — Truck 1: [qty] on hand
> — Total: [qty] | Allocated: [qty] | Available: [qty]

### "What's low?"
Run the reorder check on demand. Return the same format as the morning alert.

### "Order more [part]"
Check if there's already an open PO covering this part. If yes, show it.
If no, draft a PO line for owner review:
> "I'll draft a PO for [part] — [qty] from [default supplier].
> Last price: $[price] each. Confirm to add to a purchase order?"
Do not send or approve any PO without explicit owner confirmation.

### "What did we use on [work order]?"
Pull `material_usage[]` from the work order record and cross-reference
with `parts[]` for descriptions. Return a formatted list with quantities
and costs.

### "What parts did we use most this month?"
Aggregate `transactions[]` of type = issue for the current month.
Group by `part_id`. Sort by total quantity issued. Return the top 10.

### "Record that we received [PO number / supplier] order"
Run the purchase order received trigger. Walk through the receipt line by line.

### "Add [part] to the system"
Run the part added trigger. Collect required fields and confirm before saving.

### "How many [part] are on [Truck 1 / the shop]?"
Pull the specific `balances[]` record for that part + location combination.
Return on-hand, allocated, and on-order quantities.

### "What's on order right now?"
Pull all POs with `status` in [approved, sent, partially_received].
List by supplier, with expected dates and line items:
> **Open Purchase Orders:**
> PO-2026-008 — [Supplier] — expected [date] — $[total]
>   — [Part]: [qty] ordered
> PO-2026-009 — [Supplier] — expected [date] — $[total]
>   — [Part]: [qty] ordered, [qty] received, [qty] remaining

---

## Reorder Logic

When checking whether a part needs to be reordered:

**Available quantity** = `on_hand_qty` − `allocated_qty` + `on_order_qty`

If available quantity ≤ `reorder_min`, the part is flagged for reorder.

**Suggested order quantity:**
- Default: reorder up to `reorder_max` (i.e. order `reorder_max` − available qty)
- Minimum: always at least 1 unit
- Round to the supplier's minimum order quantity if known

**Grouping for PO drafts:**
- Group all flagged parts by `default_supplier_id`
- Create one draft PO per supplier
- Include all parts from that supplier that need reordering

Present draft POs to the owner for review. Never send or approve a PO
automatically.

---

## Integration Points

| System | How |
|--------|-----|
| `schemas/inventory.json` | Source of truth for parts, locations, balances, and transactions |
| `schemas/work-order.json` | Material usage on WOs triggers inventory issue transactions |
| Work Orders module | Issues parts to WOs; returns parts if job is canceled |
| Invoicing module | Part cost and sell price feed into WO billing line items |
| QuickBooks Online | Parts sync as QB Inventory Items; vendor receipts sync as Bills |

---

## Hard Stops

1. **No inventory issue without a valid work order reference.** Parts cannot
   be removed from stock without a job number. All issues must link to a
   work order so the cost is captured. No free-form removals.

2. **No purchase order sent or approved without explicit owner sign-off.**
   The AI drafts POs and presents them. The owner reviews line items, quantities,
   and prices before anything is sent to a supplier.

3. **No inventory adjustment without a reason code.** Every adjustment must
   have a reason (cycle count, damage, correction, etc.) and a recorded user.
   No silent corrections.

4. **No part deducted from a location that doesn't carry it.** Verify
   `balances[]` for the specific part + location pair before posting an issue.
   Alert if the location has zero or insufficient stock; offer to pull from
   an alternate location.

5. **No stock level assumed from memory.** Always read current `on_hand_qty`
   from `balances[]` before answering "do we have this." Never guess or use
   a cached value without confirming the record is current.

6. **No QuickBooks sync without a valid QB item reference.** Parts without
   a `qb_item_ref` must be created in QB first (or linked to an existing QB
   item) before any QB API calls. Alert the owner if a part is missing its QB
   mapping when an invoice or bill needs to be pushed.
