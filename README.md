# alohas-analytics-case
Analytics Engineer study case for ALOHAS — channel sales performance, late-arriving
returns modeling, and contribution margin analysis on a synthetic BigQuery dataset.

## How to navigate the repo

The work is split into two deliverables:

1. **`Data Quality & Business Analysis.pdf`** — the main report. Walks through data
   quality checks, assumptions, and the three business questions (channel sales,
   net sales / late returns, contribution margin) in order. Section numbering
   matches the code, so a numbered finding or chart in the PDF maps directly to
   the query or script with the same number.
2. **`Dashboard.xlsx`** — the interactive dashboard, built on top of the aggregated
   outputs in `data_exports/`. Meant to be read alongside the PDF, not instead of it.

## What I'd do differently with more time

I'd move this into dbt models following a medallion architecture:

- **Bronze** — the 3 source tables as-is (`dim_product`, `fct_shipment`, `fct_sale_order_line`).
- **Silver** — transformations for each business question (channel sales, returns
  handling, contribution margin), each as its own model so logic stays testable
  and traceable back to a single question.
- **Gold** — the final aggregated tables the dashboard reads from, replacing the
  static `data_exports/` CSVs with something that can actually refresh.

This would also be the natural place to implement the late-returns schema
proposed in the report (rather than sketching it as a design-only answer).
