-- ═══════════════════════════════════════════════════════════════════════════════
-- SCRIPT 03: SEMANTIC VIEW FOR CORTEX ANALYST / SNOWFLAKE INTELLIGENCE
-- Alkermes Pharma Commercial Analytics Demo
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- CONFIG
-- ──────────────────────────────────────────────────────────────────────────────
-- DATABASE  : ALKERMES_DEMO
-- SCHEMA    : COMMERCIAL
-- WAREHOUSE : COMMERCIAL_AGENT_NON_CONF_R_WH        (change to your warehouse)
-- ROLE      : COMMERCIAL_AGENT_NON_CONF_R
-- ──────────────────────────────────────────────────────────────────────────────
--
-- PREREQUISITES
-- ──────────────────────────────────────────────────────────────────────────────
-- 1. All source tables must exist (created in Script 01).
-- 2. Cortex Search services from Script 02 must be ACTIVE:
--      • ALKERMES_DEMO.COMMERCIAL.HCP_NAME_SEARCH_SVC
--      • ALKERMES_DEMO.COMMERCIAL.TERRITORY_SEARCH_SVC
--
-- PURPOSE
-- ──────────────────────────────────────────────────────────────────────────────
-- This script creates COMMERCIAL_ANALYTICS_SV — a SQL-native semantic view that
-- powers natural-language querying via:
--
--   • Cortex Analyst  — REST API / Snowsight NL-to-SQL interface
--   • Snowflake Intelligence — Agentic framework that auto-selects tools
--
-- A semantic view describes the *business meaning* of data: which columns are
-- facts to be measured (TRx, NRx, Revenue), which are dimensions to filter and
-- group by (HCP, Product, Territory), and which are pre-defined metrics
-- (Market Share %, Avg TRx per HCP).  The LLM uses these definitions to
-- generate accurate SQL without hallucinating column names or join paths.
--
-- SEMANTIC VIEW vs. YAML SEMANTIC MODEL
-- ──────────────────────────────────────────────────────────────────────────────
-- Snowflake supports two ways to define semantic metadata for Cortex Analyst:
--
--   YAML semantic model (.yaml file in a stage):
--     → Legacy approach; still supported; requires manual file management.
--
--   SQL semantic view (CREATE SEMANTIC VIEW):
--     → Native SQL DDL; version-controlled in Snowflake; directly queryable;
--       the recommended modern approach as of 2025.
--
-- This demo uses the SQL semantic view approach.
--
-- ═══════════════════════════════════════════════════════════════════════════════

USE ROLE     COMMERCIAL_AGENT_NON_CONF_R;
USE DATABASE ALKERMES_DEMO;
USE SCHEMA   COMMERCIAL;
USE WAREHOUSE COMMERCIAL_AGENT_NON_CONF_R_WH;

-- ═══════════════════════════════════════════════════════════════════════════════
-- CREATE SEMANTIC VIEW: COMMERCIAL_ANALYTICS_SV
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- Data model summary:
--
--   PRESCRIPTIONS (fact table)
--       └── HCP_ID        → HCPS         (who prescribed)
--       └── PRODUCT_ID    → PRODUCTS     (what was prescribed)
--       └── TERRITORY_ID  → TERRITORIES  (where it was prescribed)
--                               └── TERRITORY_ID → SALES_REPS (who covers it)
--
-- Note: PRESCRIPTIONS does not carry REP_ID directly.  The relationship to
-- SALES_REPS is resolved through TERRITORIES (both tables share TERRITORY_ID).
-- Cortex Analyst will traverse: prescriptions → territories → sales_reps.
-- ───────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE SEMANTIC VIEW ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_SV

  -- ─────────────────────────────────────────────────────────────────────────────
  -- TABLES: logical aliases for each physical table, with primary key declarations
  -- ─────────────────────────────────────────────────────────────────────────────
  TABLES (
    prescriptions AS ALKERMES_DEMO.COMMERCIAL.PRESCRIPTIONS PRIMARY KEY (PRESCRIPTION_ID),
    hcps          AS ALKERMES_DEMO.COMMERCIAL.HCPS           PRIMARY KEY (HCP_ID),
    products      AS ALKERMES_DEMO.COMMERCIAL.PRODUCTS       PRIMARY KEY (PRODUCT_ID),
    territories   AS ALKERMES_DEMO.COMMERCIAL.TERRITORIES    PRIMARY KEY (TERRITORY_ID),
    sales_reps    AS ALKERMES_DEMO.COMMERCIAL.SALES_REPS     PRIMARY KEY (REP_ID)
  )

  -- ─────────────────────────────────────────────────────────────────────────────
  -- RELATIONSHIPS: foreign-key paths the LLM uses to generate JOIN clauses
  -- Direction: child(FK) REFERENCES parent(PK)
  -- ─────────────────────────────────────────────────────────────────────────────
  RELATIONSHIPS (
    -- Prescription → HCP: who wrote the script
    prescriptions_to_hcps       AS prescriptions(HCP_ID)       REFERENCES hcps(HCP_ID),

    -- Prescription → Product: which brand was prescribed
    prescriptions_to_products   AS prescriptions(PRODUCT_ID)   REFERENCES products(PRODUCT_ID),

    -- Prescription → Territory: which sales territory the prescription occurred in
    prescriptions_to_territories AS prescriptions(TERRITORY_ID) REFERENCES territories(TERRITORY_ID),

    -- Territory → Sales Rep: which rep covers that territory
    -- (PRESCRIPTIONS does not carry REP_ID; this bridge resolves rep attribution)
    sales_reps_to_territories   AS sales_reps(TERRITORY_ID)    REFERENCES territories(TERRITORY_ID)
  )

  -- ─────────────────────────────────────────────────────────────────────────────
  -- FACTS: raw numeric columns that can be aggregated in metric expressions.
  -- Facts are the building blocks for METRICS below.
  -- ─────────────────────────────────────────────────────────────────────────────
  FACTS (
    -- Prescription volume columns
    prescriptions.TRX        AS TRX        COMMENT = 'Total prescriptions (TRx) — all fills including refills',
    prescriptions.NRX        AS NRX        COMMENT = 'New prescriptions (NRx) — first fills only',
    prescriptions.MARKET_TRX AS MARKET_TRX COMMENT = 'Total market TRx across all competitors — denominator for market share',
    prescriptions.REVENUE_USD AS REVENUE_USD COMMENT = 'Estimated net revenue in USD after gross-to-net adjustments'
  )

  -- ─────────────────────────────────────────────────────────────────────────────
  -- DIMENSIONS: categorical / text / date attributes used for filtering and
  -- grouping.  Synonyms teach the LLM how users naturally phrase each concept.
  -- Cortex Search services are attached to high-cardinality name columns so the
  -- LLM can resolve fuzzy / partial string input to canonical stored values.
  -- ─────────────────────────────────────────────────────────────────────────────
  DIMENSIONS (

    -- ── HCP Dimensions ────────────────────────────────────────────────────────

    -- High-cardinality: thousands of physician names.
    -- Cortex Search resolves "Dr. Patel" → "Patel, Arun K MD" automatically.
    hcps.HCP_FULL_NAME AS HCP_FULL_NAME
      COMMENT = 'Full name of the HCP - uses Cortex Search for fuzzy name matching'
      WITH SYNONYMS = ('doctor', 'physician', 'prescriber', 'HCP', 'provider', 'healthcare provider')
      WITH CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.HCP_NAME_SEARCH_SVC,

    hcps.SPECIALTY AS SPECIALTY
      COMMENT = 'Medical specialty of the HCP (e.g. Psychiatry, Neurology, Addiction Medicine)'
      WITH SYNONYMS = ('specialty', 'medical specialty', 'doctor specialty', 'physician specialty'),

    hcps.CITY AS CITY
      WITH SYNONYMS = ('city', 'location', 'practice city', 'HCP city'),

    hcps.STATE AS STATE
      WITH SYNONYMS = ('state', 'practice state', 'HCP state'),

    hcps.HCP_TIER AS HCP_TIER
      COMMENT = 'Commercial tier classification of the HCP (e.g. Tier 1, Tier 2, Tier 3)'
      WITH SYNONYMS = ('tier', 'HCP tier', 'prescriber tier', 'doctor tier', 'account tier'),

    -- ── Product Dimensions ────────────────────────────────────────────────────

    products.PRODUCT_NAME AS PRODUCT
      COMMENT = 'Product brand name (e.g. VIVITROL, ARISTADA)'
      WITH SYNONYMS = ('brand', 'drug', 'medicine', 'product name', 'brand name', 'medication'),

    products.THERAPEUTIC_AREA AS THERAPEUTIC_AREA
      COMMENT = 'Therapeutic area the product belongs to (e.g. Addiction, Schizophrenia)'
      WITH SYNONYMS = ('therapy area', 'TA', 'disease area', 'indication area', 'therapeutic category'),

    -- ── Territory Dimensions ──────────────────────────────────────────────────

    -- High-cardinality: territory names often contain internal codes unknown to
    -- end users.  Cortex Search resolves "Boston territory" → "NE-Boston-114".
    territories.TERRITORY_NAME AS TERRITORY
      COMMENT = 'Sales territory name - uses Cortex Search for fuzzy matching'
      WITH SYNONYMS = ('territory', 'area', 'sales territory', 'territory name', 'field territory')
      WITH CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.TERRITORY_SEARCH_SVC,

    territories.REGION AS REGION
      COMMENT = 'Geographic sales region (e.g. Northeast, Southeast, Midwest, West)'
      WITH SYNONYMS = ('region', 'geographic region', 'sales region', 'national region'),

    territories.DISTRICT AS DISTRICT
      COMMENT = 'Sales district — grouping of territories within a region'
      WITH SYNONYMS = ('district', 'sales district', 'field district'),

    -- ── Sales Rep Dimensions ──────────────────────────────────────────────────

    sales_reps.REP_NAME AS REP_NAME
      COMMENT = 'Full name of the field sales representative'
      WITH SYNONYMS = ('rep', 'sales rep', 'representative', 'field rep', 'territory rep', 'MSL'),

    -- ── Time Dimension ────────────────────────────────────────────────────────

    prescriptions.RX_MONTH AS RX_MONTH
      COMMENT = 'Year-month of the prescription (YYYY-MM format) — use for time-series analysis'
      WITH SYNONYMS = ('month', 'period', 'time period', 'prescription month', 'reporting month', 'month year')
  )

  -- ─────────────────────────────────────────────────────────────────────────────
  -- METRICS: pre-defined aggregations that Cortex Analyst can use directly in
  -- generated SQL without needing to infer the correct aggregation logic.
  -- Defining metrics here ensures consistent calculation across all questions.
  -- ─────────────────────────────────────────────────────────────────────────────
  METRICS (

    -- Total TRx: all prescription fills
    prescriptions.total_trx AS SUM(TRX)
      COMMENT = 'Total prescriptions dispensed (all fills including refills)'
      WITH SYNONYMS = ('total prescriptions', 'TRx', 'scripts', 'total scripts', 'total TRx', 'prescription volume'),

    -- New-to-therapy prescriptions (NRx)
    prescriptions.total_nrx AS SUM(NRX)
      COMMENT = 'New patient prescriptions — first fills only; leading indicator of new patient acquisition'
      WITH SYNONYMS = ('new prescriptions', 'NRx', 'new scripts', 'new patient starts', 'new to therapy'),

    -- Total market volume for share denominator
    prescriptions.total_market_trx AS SUM(MARKET_TRX)
      COMMENT = 'Total market TRx across all competitors — denominator for market share calculation'
      WITH SYNONYMS = ('market size', 'total market', 'market volume', 'class TRx', 'market TRx'),

    -- Net revenue
    prescriptions.total_revenue_usd AS SUM(REVENUE_USD)
      COMMENT = 'Estimated net revenue in USD (post gross-to-net; use as directional indicator)'
      WITH SYNONYMS = ('revenue', 'sales', 'net revenue', 'total revenue', 'net sales', 'gross revenue'),

    -- Unique writing HCPs
    prescriptions.active_hcps AS COUNT(DISTINCT HCP_ID)
      COMMENT = 'Count of unique HCPs who wrote at least one prescription in the period'
      WITH SYNONYMS = ('active doctors', 'writing HCPs', 'active prescribers', 'prescribing physicians', 'unique HCPs'),

    -- Market share percentage
    prescriptions.market_share_pct AS ROUND(SUM(TRX) / NULLIF(SUM(MARKET_TRX), 0) * 100, 2)
      COMMENT = 'Percentage share of total market prescriptions — product TRx ÷ total market TRx × 100'
      WITH SYNONYMS = ('market share', 'share', 'share of market', 'SOM', 'share of voice', 'brand share'),

    -- Average TRx per writing HCP (rep productivity proxy)
    prescriptions.avg_trx_per_hcp AS ROUND(SUM(TRX) / NULLIF(COUNT(DISTINCT HCP_ID), 0), 1)
      COMMENT = 'Average TRx per writing HCP — proxy for prescriber depth and rep call effectiveness'
      WITH SYNONYMS = ('productivity', 'HCP productivity', 'scripts per HCP', 'TRx per doctor', 'writer productivity')
  )

  COMMENT = 'Pharma commercial analytics semantic view - TRx, NRx, market share, revenue by HCP, product, territory and rep';

-- ═══════════════════════════════════════════════════════════════════════════════
-- VERIFICATION QUERIES
-- ═══════════════════════════════════════════════════════════════════════════════
-- Run these to confirm the semantic view was created and is queryable.
-- ───────────────────────────────────────────────────────────────────────────────

-- 1. Confirm the semantic view appears in the account catalog
SHOW SEMANTIC VIEWS IN SCHEMA ALKERMES_DEMO.COMMERCIAL;

-- 2. Inspect the full definition: tables, relationships, facts, dimensions, metrics
DESCRIBE SEMANTIC VIEW ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_SV;

-- 3. Direct SEMANTIC_VIEW() query — test that metrics and dimensions resolve correctly.
--    Returns total TRx by product and region, ordered highest to lowest.
SELECT *
FROM SEMANTIC_VIEW(
  ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_SV
  DIMENSIONS  products.PRODUCT,
              territories.REGION
  METRICS     prescriptions.total_trx
)
ORDER BY total_trx DESC;

-- 4. Market share by product across all time — confirms the ratio metric works
SELECT *
FROM SEMANTIC_VIEW(
  ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_SV
  DIMENSIONS  products.PRODUCT
  METRICS     prescriptions.total_trx,
              prescriptions.total_market_trx,
              prescriptions.market_share_pct
)
ORDER BY market_share_pct DESC;

-- 5. HCP productivity by territory — confirms cross-table dimension resolution
SELECT *
FROM SEMANTIC_VIEW(
  ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_SV
  DIMENSIONS  territories.TERRITORY,
              territories.REGION
  METRICS     prescriptions.total_trx,
              prescriptions.active_hcps,
              prescriptions.avg_trx_per_hcp
)
ORDER BY avg_trx_per_hcp DESC
LIMIT 20;

-- ═══════════════════════════════════════════════════════════════════════════════
-- HOW TO CONNECT TO CORTEX ANALYST / SNOWFLAKE INTELLIGENCE
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- CORTEX ANALYST (Snowsight UI)
-- ─────────────────────────────
-- 1. In Snowsight, navigate to AI & ML → Cortex Analyst.
-- 2. Click "New Conversation" → select "Semantic View" as the source type.
-- 3. Choose ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_SV.
-- 4. The "Connect Cortex Search" button will appear automatically for dimensions
--    that have WITH CORTEX SEARCH SERVICE defined (HCP_FULL_NAME, TERRITORY).
-- 5. Start asking questions in plain English:
--      "What is the TRx trend for VIVITROL in the Northeast region this year?"
--      "Show me top 10 HCPs by NRx in the Psychiatry specialty"
--      "Which territories have market share above 20%?"
--      "Compare rep productivity across districts"
--
-- CORTEX ANALYST (REST API)
-- ─────────────────────────
-- POST to /api/v2/cortex/analyst/message with body:
-- {
--   "messages": [{"role": "user", "content": [{"type": "text", "text": "..."}]}],
--   "semantic_model_file": "@ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_SV"
-- }
-- Note: use the semantic view reference format, not a YAML stage path.
--
-- SNOWFLAKE INTELLIGENCE
-- ──────────────────────
-- Snowflake Intelligence agents can reference this semantic view as a tool.
-- When an agent receives a business question about prescriptions, TRx, or
-- market share, it will automatically use COMMERCIAL_ANALYTICS_SV to generate
-- and execute the correct SQL — with full Cortex Search resolution for HCP
-- and territory names.
--
-- ═══════════════════════════════════════════════════════════════════════════════
-- CORTEX SEARCH INTEGRATION RECAP
-- ═══════════════════════════════════════════════════════════════════════════════
-- The two services created in Script 02 are wired into this semantic view:
--
--   HCP_FULL_NAME dimension
--     → WITH CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.HCP_NAME_SEARCH_SVC
--     → Enables: "Show me TRx for Dr. Johnson" even if user doesn't know the
--       exact stored name format
--
--   TERRITORY dimension
--     → WITH CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.TERRITORY_SEARCH_SVC
--     → Enables: "How is the Chicago area performing?" resolving to the
--       canonical internal territory name
--
-- If either search service is dropped or becomes inactive, Cortex Analyst will
-- fall back to exact string matching for those dimensions.  Re-run Script 02
-- to restore the services.
--
-- ═══════════════════════════════════════════════════════════════════════════════
-- SETUP COMPLETE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Scripts executed:
--   01_setup_tables.sql         → Source tables populated
--   02_cortex_search_analyst.sql → Cortex Search services active
--   03_semantic_view.sql         → Semantic view live  ← YOU ARE HERE
--
-- The demo environment is ready for Cortex Analyst and Snowflake Intelligence.
-- ═══════════════════════════════════════════════════════════════════════════════
