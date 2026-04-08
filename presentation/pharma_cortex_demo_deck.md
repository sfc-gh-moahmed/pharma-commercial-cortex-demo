---
marp: true
theme: default
paginate: true
backgroundColor: #ffffff
color: #1a1a1a
style: |
  section {
    font-family: 'Segoe UI', Arial, sans-serif;
    padding: 40px 60px;
  }
  h1 { color: #29B5E8; }
  h2 { color: #1A73E8; }
  h3 { color: #1a1a1a; }
  .highlight { background: #E3F2FD; padding: 10px; border-radius: 5px; }
  table { width: 100%; border-collapse: collapse; font-size: 0.85em; }
  th { background: #29B5E8; color: white; padding: 8px 12px; text-align: left; }
  td { padding: 7px 12px; border-bottom: 1px solid #e0e0e0; }
  tr:nth-child(even) { background: #f5f5f5; }
  code { background: #f0f4f8; padding: 2px 6px; border-radius: 3px; font-size: 0.9em; }
  pre { background: #1e2a3a; color: #e8f4fd; padding: 16px; border-radius: 8px; font-size: 0.78em; }
---

# Snowflake AI for Commercial Analytics
## Cortex Search · Cortex Analyst · Snowflake Intelligence

---

**Pharma Commercial Team Demo | 2025**

> *Vivitrol · Aristada · Lybalvi*

Built on Snowflake — no external AI services, no data movement, no SQL required for end users.

---

## The Commercial Analytics Challenge

### Today's pain points

- **Fragmented HCP data** — prescriber information lives in multiple systems with inconsistent name formatting; a single query fails on a misspelling
- **Rep call notes in CRM silos** — qualitative field intelligence is locked in free-text fields that traditional BI tools cannot search
- **Formulary data is static** — market access spreadsheets go stale; payer barriers surface only in field reports
- **Business questions require the data team** — any question beyond a canned dashboard requires a SQL request and a waiting queue
- **No unified search across structured + unstructured data** — Rx metrics live in tables; objection notes live in text; no tool bridges both

---

> *A territory manager should be able to ask "which psychiatrists in Texas haven't had a call in 60 days?" and get an answer in seconds — not a ticket.*

---

## Solution Architecture

```
┌─────────────────────────┐   ┌──────────────────────────┐   ┌─────────────────────────────┐
│   Synthetic Data Layer  │   │    AI Services Layer      │   │      Interface Layer        │
│─────────────────────────│   │──────────────────────────│   │─────────────────────────────│
│  HCPS                   │──►│  Cortex Search           │──►│  Snowflake Intelligence     │
│  PRESCRIPTIONS          │   │  (HCP names + call notes)│   │  ● Chat-based Q&A           │
│  CALL_NOTES             │──►│                          │   │  ● Zero SQL for users       │
│  PRODUCTS               │   │  Semantic View           │──►│  ● Tables, charts, text     │
│  TERRITORIES            │──►│  (Business KPIs + dims)  │   │  ● Pre-loaded sample Qs     │
│  MARKET_ACCESS          │   │                          │   └─────────────────────────────┘
│  SALES_REPS             │──►│  Cortex Agent            │
│  QUOTAS                 │   │  (Routes to right tool)  │
└─────────────────────────┘   └──────────────────────────┘
```

**One platform. All data + AI in Snowflake. No external services.**

---

## Data Model

| Table | Contents |
|-------|----------|
| `HCPS` | Prescriber master — name, specialty, state, HCP type, tier |
| `PRESCRIPTIONS` | Monthly TRx and NRx by HCP, product, territory, and rep |
| `CALL_NOTES` | Free-text rep call notes — observations, objections, access issues |
| `PRODUCTS` | Product catalog — Vivitrol, Aristada, Lybalvi with therapeutic areas |
| `TERRITORIES` | Territory hierarchy — territory → region → national with rep assignments |
| `MARKET_ACCESS` | Payer formulary status by product and plan — coverage tier, PA required |
| `SALES_REPS` | Rep master — name, district, region, hire date |
| `QUOTAS` | Annual TRx targets by rep, territory, and product |

---

**~5,000 synthetic HCPs · ~24 months of Rx history · ~8,000 call notes**
Realistic distributions across CNS / addiction medicine specialties and all U.S. regions.

---

## Cortex Search: Three Ways to Use It

| Mode | What It Does | Best For | Demo Example |
|------|-------------|----------|--------------|
| **Mode 1: Analyst-Integrated** | Links CS to a Semantic View dimension for fuzzy name resolution | High-cardinality dims (HCP names, territory codes) | `"Dr. Murrey"` → resolves to `"Dr. Murray"` → SQL succeeds |
| **Mode 2: Standalone** | Direct semantic search via `CORTEX_SEARCH()` SQL function | Custom search UIs, exploratory HCP profiling | `"addiction psychiatry Texas"` → ranked HCP list with scores |
| **Mode 3: Agent Tool** | CS as a RAG retrieval tool inside a Cortex Agent | Unstructured field intelligence, call note search | `"formulary barriers Vivitrol"` → ranked call note excerpts |

---

Each mode is independently useful. Together they cover the full spectrum from pure structured analytics to pure unstructured retrieval — with the agent intelligently routing between them.

---

## Demo: Cortex Search Mode 1 — Analyst Integration

### The Problem: Exact String Matching Fails on HCP Names

```sql
-- WITHOUT Cortex Search: question returns no rows
-- User asks: "Show TRx for Dr. Andersen in Q3"
-- Cortex Analyst generates:
SELECT SUM(trx) FROM prescriptions p
JOIN hcps h ON p.hcp_id = h.hcp_id
WHERE h.hcp_full_name = 'Dr. Andersen'   -- ← no match, 0 rows
  AND quarter = 'Q3';
```

### The Fix: Cortex Search Resolves the Name First

```sql
-- WITH Cortex Search linked to hcp_full_name dimension:
-- CS resolves "Dr. Andersen" → "Dr. Anderson, Robert M."
-- Cortex Analyst now generates correct SQL → result: 42 TRx
```

---

**Key message:** Linking Cortex Search to high-cardinality Semantic View dimensions eliminates the #1 cause of Cortex Analyst returning empty results — name mismatches.

---

## Demo: Cortex Search Mode 2 — Standalone

### Direct Semantic Search on HCP Profiles

```sql
SELECT *
FROM TABLE(
  ALKERMES_DEMO.COMMERCIAL.HCP_SEARCH(
    QUERY       => 'addiction medicine psychiatrist high volume',
    COLUMNS     => ['HCP_FULL_NAME','SPECIALTY','STATE','HCP_TYPE'],
    LIMIT       => 10
  )
);
```

**Example results:**

| HCP Name | Specialty | State | Score |
|----------|-----------|-------|-------|
| Dr. Sarah Mitchell | Addiction Medicine | TX | 0.94 |
| Dr. James Okafor | Psychiatry | TX | 0.89 |
| Dr. Rachel Kim | Addiction Psychiatry | TX | 0.87 |

---

**Key message:** Snowflake-native fuzzy and semantic search — no Elasticsearch, no OpenSearch, no external vector database needed.

---

## Semantic View: The Business Metric Layer

### Metrics defined once, queryable in plain English

| Metric | Definition |
|--------|-----------|
| `TOTAL_TRX` | Sum of total prescriptions dispensed |
| `TOTAL_NRX` | Sum of new prescriptions written |
| `MARKET_SHARE_PCT` | Product TRx ÷ total market TRx × 100 |
| `TOTAL_REVENUE` | TRx × product WAC price |
| `ACTIVE_HCP_COUNT` | HCPs with ≥1 TRx in the period |
| `CALL_TO_RX_RATE` | Rep calls ÷ resulting TRx |

### Key dimensions (all searchable)

`HCP_FULL_NAME` (CS-linked) · `PRODUCT_NAME` · `TERRITORY_NAME` · `REGION_NAME` · `REP_NAME` · `SPECIALTY` · `QUARTER` · `MONTH`

---

**Key message:** Define business logic once. Every Cortex Analyst question gets the same correct calculation — no conflicting definitions across reports.

---

## Demo: Cortex Agent in Action

### The agent routes automatically — no user configuration needed

---

**Question: "Which territories underperform on Vivitrol TRx this quarter?"**
→ Agent selects **CommercialAnalyst** (structured metrics question)
→ Generates SQL on semantic view → returns ranked territory table + bar chart

---

**Question: "Find field notes about objections or access issues for Lybalvi"**
→ Agent selects **FieldIntelligence** (unstructured text retrieval)
→ Runs semantic search on CALL_NOTES_SEARCH → returns top 5 excerpts with rep, date, and territory

---

**Question: "Which territories underperform AND why based on field notes?"**
→ Agent calls **CommercialAnalyst first** for metrics, then **FieldIntelligence** for qualitative context
→ Combines both into a single coherent answer

---

**Key message:** The agent acts as an intelligent router. Users never need to know which tool to call — they just ask the business question.

---

## Snowflake Intelligence: Pre-Loaded Sample Questions

Navigate to: **Snowsight → AI & ML → Snowflake Intelligence → COMMERCIAL_ANALYTICS_AGENT**

### 10 questions ready for the commercial team:

1. Which territories are underperforming on Vivitrol TRx vs. target this quarter?
2. Show me HCP prescribing trends for Aristada in the Northeast over the last 12 months
3. Find all psychiatrists in Texas who haven't had a rep call in the last 60 days
4. What is the formulary access rate for Vivitrol on commercial insurance plans?
5. Which reps have the highest call-to-prescription conversion rate?
6. Show me market share by product across all regions for the current year
7. Find recent field notes about physician objections or access barriers for Lybalvi
8. Which HCPs in the Midwest have the highest Aristada TRx growth in the last 6 months?
9. Compare regional performance across all three products year-to-date
10. Which payers are creating the most access barriers based on rep field reports?

---

**Key message:** Zero-SQL self-service for commercial team members — click a question, get an answer.

---

## Why Snowflake for Commercial Analytics

- **All data + AI on one platform** — no ETL to external AI services, no API keys to manage, no data copies leaving Snowflake governance
- **No data movement** — Cortex Search indexes live Snowflake tables; Cortex Analyst queries the semantic view directly
- **HIPAA-eligible infrastructure** — Snowflake's Business Associate Agreement (BAA) covers the full stack including AI services
- **Enterprise governance built in** — Role-based access control applies to the agent, the search service, and the underlying tables
- **Cortex Search replaces external vector databases** — no Pinecone, no Weaviate, no custom embedding pipelines to maintain
- **Scales with your territory footprint** — add new regions, products, or reps by adding rows to tables; no model retraining required
- **Auditability** — every agent query is logged in `ACCOUNT_USAGE.QUERY_HISTORY`

---

## Next Steps

1. **Run the demo scripts** in your Snowflake account — all six scripts run in under 10 minutes with synthetic data

2. **Connect real commercial data** — replace synthetic inserts with IQVIA/Symphony Health Rx feeds, Veeva CRM call exports, and MCO formulary files

3. **Extend the Semantic View** — add quota attainment %, call frequency targets, reach and frequency metrics, managed care penetration

4. **Deploy to the commercial team** — grant `USAGE` on the agent to your commercial analyst role; share the Snowflake Intelligence URL

5. **Iterate on sample questions** — after the first week of usage, review the most common questions and refine the agent instructions and sample question list

---

*Contact your Snowflake account team or SE to get started.*

`ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT`
