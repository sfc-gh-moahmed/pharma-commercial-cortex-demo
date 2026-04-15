# Pharma Commercial Analytics Demo
## Snowflake Cortex Search + Cortex Analyst + Snowflake Intelligence

---

### Overview

This demo shows a complete pharma commercial analytics solution built entirely on Snowflake AI. It covers synthetic data for a CNS and addiction medicine product portfolio — **Vivitrol**, **Aristada**, and **Lybalvi** — and demonstrates how Cortex Search, Cortex Analyst, and Snowflake Intelligence work together to give commercial teams natural-language access to both structured prescription data and unstructured field call notes.

The solution requires no external services, no data movement, and no SQL knowledge from end users.

---

### Architecture

```
Synthetic Data Layer          AI Services Layer              Interface Layer
─────────────────────         ──────────────────────         ──────────────────────────
HCPS                    ──►   Cortex Search Services   ──►   Snowflake Intelligence
PRESCRIPTIONS           ──►   (HCP lookup + call notes)      (Natural Language Q&A)
CALL_NOTES              ──►                                   Any user, zero SQL
PRODUCTS                ──►   Semantic View             ──►
TERRITORIES             ──►   (Metrics + dimensions)
MARKET_ACCESS           ──►
SALES_REPS              ──►   Cortex Agent              ──►
QUOTAS                  ──►   (Routes to right tool)
```

**Data flows left to right.** Synthetic data loads into Snowflake tables. Cortex Search indexes both HCP names (for dimension resolution) and call notes (for RAG retrieval). The Semantic View defines business KPIs. The Cortex Agent acts as the router — deciding whether a question needs SQL analytics or semantic search — and Snowflake Intelligence surfaces everything as a chat interface.

---

### Three Cortex Search Demonstrations

This demo shows Cortex Search in three distinct modes to illustrate its full range of use cases.

#### Mode 1: Analyst-Integrated Search (scripts 02–03)

Cortex Search is linked to a dimension in the Semantic View YAML (`search_service_name` field on the `HCP_FULL_NAME` dimension). When Cortex Analyst receives a question containing a misspelled or fuzzy HCP name, it calls the search service to resolve the nearest match before generating SQL.

**Example:** "Show TRx for Dr. Andersen" → CS resolves to "Dr. Anderson" → SQL runs successfully.

**When to use:** Any high-cardinality dimension where end users are likely to misspell values (HCP names, territory codes, rep names).

#### Mode 2: Standalone Search (script 04)

Cortex Search is queried directly via `SELECT * FROM TABLE(CORTEX_SEARCH(...))`. No Semantic View or agent required. Returns ranked results with relevance scores.

**Example:** Search `"addiction psychiatry Texas"` → returns ranked HCP profiles matching that description.

**When to use:** Building custom search UIs, exploratory HCP profiling, or any use case where you want raw semantic search results without going through an agent.

#### Mode 3: Agent Tool Search (script 05)

The Cortex Agent is configured with a `CORTEX_SEARCH_TOOL` named `FieldIntelligence`. When the agent determines a question requires qualitative field intelligence, it calls this tool to retrieve semantically relevant call note excerpts.

**Example:** "Find objection notes for Lybalvi" → agent calls FieldIntelligence → returns ranked call note excerpts with rep, date, and territory.

**When to use:** RAG retrieval over unstructured data inside an agent workflow.

---

### Prerequisites

- Snowflake account with Cortex features enabled in your region
- `ACCOUNTADMIN` role, or `SYSADMIN` with appropriate privilege grants
- Snowflake CLI (`snow`) or SnowSQL for running scripts
- Cortex Search and Cortex Analyst features available in your Snowflake region
- Cortex Agents / Snowflake Intelligence enabled in your account

---

### Setup Instructions

1. **Clone this repository**
   ```bash
   git clone <repo-url>
   cd pharma-commercial-cortex-demo
   ```

2. **Review config blocks** at the top of each script. At minimum, update:
   - `DATABASE_NAME` — defaults to `ALKERMES_DEMO`
   - `WAREHOUSE_NAME` — update to an existing warehouse in your account
   - `ROLE_NAME` — update to the role you will use to run the scripts

3. **Run scripts in order:**
   ```
   01_synthetic_data.sql          → Creates database, schema, tables, loads synthetic data
   02_cortex_search_analyst.sql   → Creates Cortex Search service for HCP name dimension
   03_semantic_view.sql           → Creates Semantic View YAML + uploads to stage
   04_cortex_search_standalone.sql → Creates standalone Cortex Search for call notes
   05_cortex_agent.sql            → Creates Cortex Agent with Analyst + Search tools
   06_snowflake_intelligence.sql  → Configures agent spec + 10 sample questions for SI
   ```

4. **Access via Snowflake Intelligence:**
   Snowsight → AI & ML → Snowflake Intelligence → select `COMMERCIAL_ANALYTICS_AGENT`

---

### Running Scripts

Using Snowflake CLI:

```bash
snow sql -f scripts/01_synthetic_data.sql
snow sql -f scripts/02_cortex_search_analyst.sql
snow sql -f scripts/03_semantic_view.sql
snow sql -f scripts/04_cortex_search_standalone.sql
snow sql -f scripts/05_cortex_agent.sql
snow sql -f scripts/06_snowflake_intelligence.sql
```

Using SnowSQL:

```bash
snowsql -f scripts/01_synthetic_data.sql
# repeat for each script in order
```

---

### Demo Script (Suggested Flow)

1. **Show the data model** — Run a few SELECTs from script 01 to show the tables: HCPs, prescriptions, call notes. Explain the synthetic CNS portfolio.

2. **Demonstrate standalone Cortex Search (script 04)** — Run the fuzzy HCP lookup. Show how `"Dr. Murrey"` (misspelled) returns `"Dr. Murray"` with a relevance score. Contrast with a plain SQL `WHERE` clause that returns nothing.

3. **Demo Cortex Analyst WITHOUT Cortex Search** — Ask a question using a misspelled HCP name. Show that SQL fails or returns no rows because there is no exact string match.

4. **Demo Cortex Analyst WITH Cortex Search integration (script 03)** — Ask the same misspelled question again. Show that the Semantic View dimension now resolves through the linked search service, and the SQL succeeds.

5. **Open Snowflake Intelligence (script 06)** — Navigate to Snowsight → AI & ML → Snowflake Intelligence → select the agent. Show the 10 pre-loaded sample questions in the UI.

6. **Walk through 3–4 sample questions:**
   - "Which territories are underperforming on Vivitrol TRx vs. target this quarter?" → shows structured analytics, possibly a chart
   - "Find recent field notes about physician objections for Lybalvi" → shows the agent routing to FieldIntelligence, returning call note excerpts
   - "Which reps have the highest call-to-prescription conversion rate?" → shows rep-level ranking table
   - "Compare regional performance across all three products year-to-date" → shows a multi-product comparison chart

---

### File Structure

```
pharma-commercial-cortex-demo/
├── README.md
├── scripts/
│   ├── 01_synthetic_data.sql            # Database, schema, tables, synthetic data load
│   ├── 02_cortex_search_analyst.sql     # Cortex Search service for HCP name dimension
│   ├── 03_semantic_view.sql             # Semantic View YAML + stage upload
│   ├── 04_cortex_search_standalone.sql  # Standalone Cortex Search + example queries
│   ├── 05_cortex_agent.sql              # Cortex Agent with Analyst + Search tools
│   └── 06_snowflake_intelligence.sql    # Snowflake Intelligence config + sample questions
└── presentation/
    └── pharma_cortex_demo_deck.md       # Marp presentation deck (12 slides)
```

---

### Customization for Your Environment

**Change the database/schema:**
All scripts have a `CONFIG BLOCK` at the top. Update `DATABASE_NAME` and `SCHEMA_NAME` to match your environment. The default is `ALKERMES_DEMO.COMMERCIAL`.

**Swap in real data:**
Script 01 uses `INSERT` statements with synthetic data. Replace or supplement with:
- IQVIA or Symphony Health Rx data for real prescription volumes
- Veeva CRM exports for call notes and HCP master data
- Managed care organization (MCO) formulary data for market access

**Adjust warehouse sizes:**
The default is `COMMERCIAL_AGENT_NON_CONF_R_WH`. For production workloads with large prescription datasets, consider an X-Large warehouse for the Cortex Search indexing step (script 02 and 04) and a smaller warehouse for Cortex Analyst queries.

**Modify product names:**
Search for `Vivitrol`, `Aristada`, `Lybalvi` across the scripts and replace with your product portfolio. Update the `PRODUCTS` table insert in script 01 and the Semantic View `PRODUCT_NAME` dimension filters in script 03.

**Add additional Semantic View metrics:**
Open the YAML model in script 03 and add new metrics such as quota attainment percentage, call frequency per HCP, or market share by payer segment.

---

### Cleanup

To remove all demo objects from your Snowflake account:

```sql
DROP DATABASE IF EXISTS ALKERMES_DEMO;
```

This drops all tables, stages, search services, the semantic view, and the agent in a single command.
