---
title: "Snowflake AI for Pharma Commercial Analytics"
author: "Snowflake"
marp: true
theme: default
paginate: true
style: |
  section {
    font-family: 'Segoe UI', Arial, sans-serif;
    padding: 20px 32px 14px 32px;
    font-size: 18px;
    color: #1a1a1a;
  }
  h1 { color: #0E5FA5; font-size: 34px; margin: 0 0 6px 0; }
  h2 { color: #0E5FA5; font-size: 26px; margin: 0 0 8px 0; }
  h3 { font-size: 18px; margin: 0 0 4px 0; color: #1a1a1a; }
  p  { margin: 4px 0; font-size: 16px; }
  ul, ol { margin: 4px 0; padding-left: 22px; }
  li { margin: 3px 0; font-size: 16px; line-height: 1.35; }
  table { width: 100%; border-collapse: collapse; font-size: 13px; margin: 5px 0; }
  th { background: #0E5FA5; color: #ffffff; padding: 6px 10px; text-align: left; font-size: 13px; font-weight: 600; }
  td { padding: 5px 9px; border-bottom: 1px solid #c8d6e5; vertical-align: top;
       line-height: 1.3; color: #1a1a1a; }
  tr:nth-child(even) td { background: #f0f4f8; }
  tr:nth-child(odd) td { background: #ffffff; }
  code { background: #e4ecf5; padding: 1px 5px; border-radius: 3px; font-size: 13px; color: #0a3d6b; }
  pre { background: #f5f7fa; color: #1a1a1a; padding: 10px 13px; border-radius: 6px;
        border: 1px solid #d0d9e4;
        font-size: 12px; margin: 4px 0; line-height: 1.4; overflow: hidden; }
  pre code { background: none; color: #1a1a1a; padding: 0; font-size: 12px; }
  blockquote { border-left: 4px solid #0E5FA5; padding: 5px 12px; margin: 6px 0;
               font-style: italic; color: #333; font-size: 15px; background: #edf2f8; border-radius: 0 4px 4px 0; }
  .columns { display: flex; gap: 18px; }
  .col { flex: 1; }
  .label { display: inline-block; background: #c0392b; color: #ffffff;
           padding: 2px 8px; border-radius: 3px; font-size: 12px; font-weight: bold; }
  .label-green { display: inline-block; background: #1a7a3a; color: #ffffff;
                 padding: 2px 8px; border-radius: 3px; font-size: 12px; font-weight: bold; }
  section.title { text-align: center; }
  section.title h1 { font-size: 38px; margin-top: 60px; color: #0E5FA5; }
  section.title h2 { font-size: 22px; color: #444; border: none; }
---

<!-- _class: title -->

# Snowflake AI for Commercial Analytics

## Cortex Search · Cortex Analyst · Snowflake Intelligence

<br>

**Pharma Commercial Team Demo &nbsp;|&nbsp; 2026**

*Vivitrol · Aristada · Lybalvi*

All data + AI in Snowflake — no external services, no data movement, zero SQL for end users.

---

## The Commercial Analytics Challenge

- **Fragmented HCP data** — prescriber info lives in multiple systems; a single misspelling breaks a query
- **Rep call notes siloed in CRM** — qualitative field intelligence locked in free-text, invisible to BI tools
- **Formulary data goes stale** — payer barriers surface only in field reports, not dashboards
- **Business questions require the data team** — every insight becomes a SQL ticket with a waiting queue
- **No bridge between structured + unstructured data** — Rx metrics live in tables; physician objections live in text

<br>

> *"Which psychiatrists in Texas haven't had a rep call in 60 days?" should take seconds — not a ticket.*

---

## Solution Architecture

![w:920 Architecture Diagram](https://kroki.io/mermaid/svg/eNpVkc9qwzAMxu9-CpHDboXtBQaum7FCmrVOKGylBOOqqaljB9npnyfbfU-2JC2j08XiQ_rps1STag-QSQZ98E0yU1FBpq5I7F0sA_x8w5L8rtMxsBKJTPRkcNQltoEtCYMm00bjXWBCWQu5jxiSLUwmrzDdJMJTxAsUqEgfBmiV80VaFSmX4r0q1oKVqZTz8kN-PoqCZ1k1z8s0e1CT7c3nyBabpMBGuWg0rA2eWSkvg6_89iwUHTFCcVCETOIJXYeDznU0J4Thd4yfahi6WqRBuOOnI372Z53X6CITvmmQtFGWO2WvIbI3g3Y3dxGtNX2JRrbrt1dFX-l-aLzTxI025rMxT3vjzp_3Vh0R_vXnKnakbH8AV3eqRlg9cfaF5KFYZbD3BF1ACuzlGQrVtLYv6DCMu0-2v6NglGA=)

**One platform. All data + AI in Snowflake. No external services, no API keys, no data movement.**

---

## Data Model

| Table | Contents | ~Rows |
|-------|----------|------:|
| `HCPS` | 500 HCPs — name, NPI, specialty, city, state, tier | 500 |
| `PRESCRIPTIONS` | Monthly TRx & NRx by HCP, product, and territory | ~12,000 |
| `CALL_ACTIVITY` | Rep-HCP calls — type, outcome, products discussed | ~15,000 |
| `CALL_NOTES` | Rich free-text rep field notes — access issues, objections, feedback | 30 |
| `PRODUCTS` | Vivitrol, Aristada, Aristada Initio, Lybalvi catalog | 4 |
| `TERRITORIES` | 50 US territories → district → region hierarchy | 50 |
| `SALES_REPS` | 50 field reps with territory and district assignments | 50 |
| `MARKET_ACCESS` | Payer formulary status by product & plan (50 payers) | ~600 |

Synthetic data modeled on CNS / addiction medicine specialties across all U.S. regions.

---

## Cortex Search: Three Ways to Use It

| Mode | What It Does | Key Demo Moment |
|------|-------------|----------------|
| **1 — Analyst-Integrated** | CS linked to a Semantic View dimension; fuzzy name resolution before SQL generation | "TRx for Dr. Andersen" → CS resolves to "Dr. Anderson" → SQL returns 42 TRx *(instead of 0)* |
| **2 — Standalone** | Direct `SEARCH_PREVIEW()` for semantic/fuzzy search on HCP profiles and call notes | "addiction psychiatry Texas" → ranked HCP list with scores, no exact match required |
| **3 — Agent Tool** | CS as a RAG retrieval tool inside the Cortex Agent, alongside Cortex Analyst | "Vivitrol formulary barriers" → agent retrieves top 5 matching rep call note excerpts |

<br>

Each mode is independently valuable. Together they cover the full spectrum — structured analytics to pure unstructured retrieval — with the agent routing automatically between them.

---

## Demo: Mode 1 — Cortex Search Inside Cortex Analyst

<div class="columns">
<div class="col">

<span class="label">WITHOUT Cortex Search</span>

```sql
-- User asks: "Show TRx for Dr. Andersen"
-- Analyst generates exact string match:

WHERE hcp_full_name = 'Dr. Andersen'
-- ↑ no exact match in database

-- Result: 0 rows returned ✗
```

Name misspelling → broken query → user thinks there's no data.

</div>
<div class="col">

<span class="label-green">WITH Cortex Search on hcp_name dimension</span>

```sql
-- CS resolves at query time:
--   "Dr. Andersen"
--     → "Dr. James Anderson"
-- Analyst generates correct SQL:

WHERE hcp_full_name = 'Dr. James Anderson'
-- ↑ fuzzy match resolved ✓

-- Result: 42 TRx returned ✓
```

Same question. Correct answer.

</div>
</div>

> **How:** `WITH CORTEX SEARCH SERVICE HCP_NAME_SEARCH_SVC` in the Semantic View DDL links the service to the `hcp_name` dimension. Cortex Analyst calls it at query time to resolve literal values before generating SQL.

---

## Demo: Mode 2 — Standalone Cortex Search

<div class="columns">
<div class="col">

**Query HCP profile search service directly**

```sql
SELECT PARSE_JSON(
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'ALKERMES_DEMO', 'COMMERCIAL',
    'HCP_PROFILE_SEARCH_SVC',
    OBJECT_CONSTRUCT(
      'query', 'addiction medicine Texas',
      'columns', ARRAY_CONSTRUCT(
        'HCP_FULL_NAME', 'SPECIALTY', 'CITY'),
      'limit', 5
    )::VARCHAR
  )
) AS results;
```

No exact match required. Works with partial names, specialties, and location combinations.

</div>
<div class="col">

**Example results**

| HCP Name | Specialty | City |
|----------|-----------|------|
| Dr. Sarah Martinez | Addiction Medicine | Dallas |
| Dr. James Brown | Psychiatry | Houston |
| Dr. Patricia Davis | Addiction Medicine | Austin |
| Dr. Thomas Garcia | Addiction Psychiatry | San Antonio |

**Key message:** Snowflake-native semantic search — no Elasticsearch, no vector database, no custom embedding pipelines needed.

</div>
</div>

---

## Semantic View: The Business Metric Layer

<div class="columns">
<div class="col">

**Metrics** — defined once, queryable in plain English

| Metric | Definition |
|--------|-----------|
| `TOTAL_TRX` | Total prescriptions dispensed |
| `TOTAL_NRX` | New patient prescriptions written |
| `MARKET_SHARE_PCT` | Product TRx ÷ total market TRx × 100 |
| `TOTAL_REVENUE_USD` | TRx × product list price |
| `ACTIVE_HCPS` | HCPs with ≥ 1 TRx in period |
| `AVG_TRX_PER_HCP` | TRx ÷ active HCP count |

</div>
<div class="col">

**Dimensions** — with synonyms & Cortex Search linkage

| Dimension | Cortex Search |
|-----------|:---:|
| `HCP_NAME` | ✅ `HCP_NAME_SEARCH_SVC` |
| `TERRITORY` | ✅ `TERRITORY_SEARCH_SVC` |
| `PRODUCT` | sample values |
| `SPECIALTY` | sample values |
| `REGION` | sample values |
| `REP_NAME` | — |
| `RX_MONTH` | — |

</div>
</div>

> Define business logic once — no conflicting metric definitions across reports. Every Cortex Analyst question uses the same correct calculation.

---

## Demo: Cortex Agent Routing

The agent selects the right tool automatically — no user configuration required.

| User Question | Tool Used | What Happens |
|---------------|-----------|-------------|
| "Which territories underperform on Vivitrol TRx this quarter?" | **CommercialAnalyst** | Text-to-SQL on semantic view → ranked territory table + bar chart |
| "Find field notes about physician objections to Lybalvi" | **FieldIntelligence** | Semantic search on `CALL_INTEL_SEARCH_SVC` → top 5 rep note excerpts with date and territory |
| "Which territories underperform AND what are reps saying?" | **Both tools** | Analyst returns metrics; Search retrieves qualitative context; combined into one answer |

<br>

> Routing instruction in agent spec: *"Use CommercialAnalyst for quantitative questions about TRx, NRx, revenue, market share. Use FieldIntelligence for field intelligence, objections, access barriers, and HCP sentiment."*

---

## Snowflake Intelligence: Pre-Loaded Sample Questions

Navigate to: **Snowsight → AI & ML → Snowflake Intelligence → COMMERCIAL_ANALYTICS_AGENT**

<div class="columns">
<div class="col">

1. Which territories are underperforming on Vivitrol TRx vs. target this quarter?
2. Show HCP prescribing trends for Aristada in the Northeast over 12 months
3. Find all psychiatrists in Texas with no rep call in the last 60 days
4. What is the formulary access rate for Vivitrol on commercial plans?
5. Which reps have the highest call-to-prescription conversion rate?

</div>
<div class="col">

6. Show market share by product across all regions year-to-date
7. Find recent field notes about physician objections or access barriers for Lybalvi
8. Which HCPs in the Midwest have the highest Aristada TRx growth in 6 months?
9. Compare regional performance across all three products YTD with a chart
10. Which payers are creating the most access barriers per rep field reports?

</div>
</div>

**Zero-SQL self-service for the commercial team — click a question, get an answer.**

---

## Why Snowflake for Commercial Analytics

- **All data + AI on one platform** — no ETL to external AI services, no API keys, no data copies leaving Snowflake governance
- **No data movement** — Cortex Search indexes live Snowflake tables; Cortex Analyst queries the semantic view directly
- **HIPAA-eligible infrastructure** — Snowflake's BAA covers the full stack including Cortex AI services
- **Enterprise governance built in** — RBAC applies uniformly to the agent, search service, and underlying tables
- **Replaces external vector databases** — no Pinecone, Weaviate, or custom embedding pipelines to maintain or pay for separately
- **Scales with your territory footprint** — add regions, products, or reps by adding rows; no model retraining required
- **Full auditability** — every agent query is logged in `ACCOUNT_USAGE.QUERY_HISTORY`

---

## Next Steps

1. **Run the demo scripts** — six numbered SQL scripts run in under 10 minutes on your Snowflake account

2. **Connect real commercial data** — replace synthetic inserts with IQVIA/Symphony Rx feeds, Veeva CRM call exports, and MCO formulary files

3. **Extend the Semantic View** — add quota attainment %, call frequency targets, reach & frequency metrics, managed care penetration

4. **Deploy to the commercial team** — `GRANT USAGE ON AGENT` to your commercial analyst role; share the Snowflake Intelligence URL

5. **Iterate on sample questions** — after the first week, review top questions and refine the agent instructions and sample question list

<br>

*Contact your Snowflake account team to get started.*
&nbsp;&nbsp;`github.com/sfc-gh-moahmed/pharma-commercial-cortex-demo`
