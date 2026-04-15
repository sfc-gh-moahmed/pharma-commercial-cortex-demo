-- ═══════════════════════════════════════════════════════════════════════════════
-- SCRIPT 02: CORTEX SEARCH SERVICES FOR CORTEX ANALYST
-- Alkermes Pharma Commercial Analytics Demo
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- CONFIG
-- ──────────────────────────────────────────────────────────────────────────────
-- DATABASE  : ALKERMES_DEMO
-- SCHEMA    : COMMERCIAL
-- WAREHOUSE : COMPUTE_WH        (change to your warehouse)
-- ROLE      : SYSADMIN           (or a role with CREATE CORTEX SEARCH SERVICE)
-- ──────────────────────────────────────────────────────────────────────────────
--
-- PURPOSE
-- ──────────────────────────────────────────────────────────────────────────────
-- This script creates Cortex Search services that are linked to high-cardinality
-- dimension columns in the semantic view (Script 03).  When Cortex Analyst
-- (or Snowflake Intelligence) receives a natural-language question containing a
-- literal string — e.g. "Show me TRx for Dr. Patterson" — it needs to resolve
-- that string to an exact value in the underlying table.
--
-- Without Cortex Search, the LLM must generate an exact SQL LIKE / = clause,
-- which fails when the user's phrasing differs slightly from the stored value
-- (spelling variants, first-name-only input, partial names, etc.).
--
-- With Cortex Search attached to a dimension, Cortex Analyst calls the search
-- service at query time to find the closest matching value, then substitutes
-- the canonical stored string into the generated SQL.  The result is
-- accurate fuzzy / semantic matching with no hallucinated names.
--
-- WHEN TO USE CORTEX SEARCH vs. SAMPLE VALUES
-- ──────────────────────────────────────────────────────────────────────────────
-- Snowflake recommends two strategies for helping Cortex Analyst understand
-- the possible values of a dimension:
--
--   LOW-CARDINALITY columns (e.g. REGION, THERAPEUTIC_AREA, HCP_TIER):
--     → List sample values directly in the semantic view COMMENT or via the
--       "sample_values" property.  Cortex Analyst embeds them in the prompt.
--       Works well when there are < ~50 distinct values.
--
--   HIGH-CARDINALITY columns (e.g. HCP_FULL_NAME with thousands of doctors,
--     TERRITORY_NAME with hundreds of territories):
--     → Attach a Cortex Search service.  The values are indexed in a vector
--       store; Cortex Analyst retrieves the top-k matches at query time.
--       This avoids bloating the prompt and provides far better recall.
--
-- This script creates services for the two high-cardinality columns used in
-- the COMMERCIAL_ANALYTICS_SV semantic view:
--
--   • HCP_FULL_NAME  (thousands of unique physician names)
--   • TERRITORY_NAME (hundreds of sales territories with internal codes)
--
-- ═══════════════════════════════════════════════════════════════════════════════

USE ROLE    SYSADMIN;
USE DATABASE ALKERMES_DEMO;
USE SCHEMA   COMMERCIAL;
USE WAREHOUSE COMPUTE_WH;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 1: HCP NAME SEARCH SERVICE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Indexes every distinct HCP_FULL_NAME in the HCPS table.
--
-- Use cases resolved by this service:
--   "What is Dr. Anderson's TRx this quarter?"
--     → fuzzy-matches "Dr. Anderson" → "Anderson, Michael J MD"
--   "Show prescriptions for Patel"
--     → resolves partial surname to full stored name
--   "Top 10 HCPs in Psychiatry" (no literal match needed — no overhead)
--
-- TARGET_LAG = '1 hour' keeps the index fresh as new HCPs are onboarded.
-- For a demo dataset this can be increased to '1 day' to reduce costs.
-- ───────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.HCP_NAME_SEARCH_SVC
  ON HCP_FULL_NAME
  WAREHOUSE = COMPUTE_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT DISTINCT HCP_FULL_NAME
  FROM ALKERMES_DEMO.COMMERCIAL.HCPS
  WHERE HCP_FULL_NAME IS NOT NULL
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 2: TERRITORY NAME SEARCH SERVICE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Indexes every distinct TERRITORY_NAME in the TERRITORIES table.
--
-- Territory names in pharma often contain internal codes that users do not
-- know (e.g. "NE-Boston-114").  A rep or analyst might ask:
--   "What are TRx trends in the Boston territory?"
--     → fuzzy-matches "Boston territory" → "NE-Boston-114"
--   "Show me performance in the Southeast Ohio area"
--     → resolves regional keyword to the canonical territory name
--
-- ───────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.TERRITORY_SEARCH_SVC
  ON TERRITORY_NAME
  WAREHOUSE = COMPUTE_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT DISTINCT TERRITORY_NAME
  FROM ALKERMES_DEMO.COMMERCIAL.TERRITORIES
  WHERE TERRITORY_NAME IS NOT NULL
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 3: VERIFICATION — SHOW SERVICES
-- ═══════════════════════════════════════════════════════════════════════════════
-- Confirm both services are registered and note their status.
-- Status will show as 'INITIALIZING' while the first index build runs,
-- then 'ACTIVE' once ready.  Allow ~1–2 minutes for a small dataset.
-- ───────────────────────────────────────────────────────────────────────────────

SHOW CORTEX SEARCH SERVICES IN SCHEMA ALKERMES_DEMO.COMMERCIAL;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SECTION 4: DEMO QUERIES — DIRECT SERVICE PREVIEW
-- ═══════════════════════════════════════════════════════════════════════════════
-- Use SNOWFLAKE.CORTEX.SEARCH_PREVIEW to query a service directly from SQL.
-- This is the same call Cortex Analyst makes internally when resolving a
-- literal string in a user question.  Run these to confirm fuzzy matching works.
--
-- NOTE: SEARCH_PREVIEW requires the service to be in ACTIVE status.
-- ───────────────────────────────────────────────────────────────────────────────

-- Demo 4a: Fuzzy HCP name lookup — simulates "Show TRx for Dr. Andersen"
-- The user typed "Dr. Andersen"; the service resolves to matching stored names.
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
  'ALKERMES_DEMO.COMMERCIAL.HCP_NAME_SEARCH_SVC',
  OBJECT_CONSTRUCT(
    'query',   'Dr. Andersen',
    'columns', ARRAY_CONSTRUCT('HCP_FULL_NAME'),
    'limit',   5
  )::VARCHAR
) AS hcp_search_result;

-- Demo 4b: Partial surname lookup — simulates "Prescriptions for Patel"
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
  'ALKERMES_DEMO.COMMERCIAL.HCP_NAME_SEARCH_SVC',
  OBJECT_CONSTRUCT(
    'query',   'Patel psychiatrist',
    'columns', ARRAY_CONSTRUCT('HCP_FULL_NAME'),
    'limit',   5
  )::VARCHAR
) AS hcp_search_result;

-- Demo 4c: Territory fuzzy lookup — simulates "Boston territory performance"
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
  'ALKERMES_DEMO.COMMERCIAL.TERRITORY_SEARCH_SVC',
  OBJECT_CONSTRUCT(
    'query',   'Boston territory',
    'columns', ARRAY_CONSTRUCT('TERRITORY_NAME'),
    'limit',   5
  )::VARCHAR
) AS territory_search_result;

-- Demo 4d: Territory lookup by region keyword
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
  'ALKERMES_DEMO.COMMERCIAL.TERRITORY_SEARCH_SVC',
  OBJECT_CONSTRUCT(
    'query',   'Southeast Ohio',
    'columns', ARRAY_CONSTRUCT('TERRITORY_NAME'),
    'limit',   5
  )::VARCHAR
) AS territory_search_result;

-- ═══════════════════════════════════════════════════════════════════════════════
-- NEXT STEP
-- ═══════════════════════════════════════════════════════════════════════════════
-- Both Cortex Search services are now live and indexed.
--
-- These services are referenced in the semantic view created in the next script:
--
--   03_semantic_view.sql
--
-- Inside that script, the DIMENSIONS clause attaches each service to its
-- corresponding column using the syntax:
--
--   hcps.HCP_FULL_NAME AS HCP_FULL_NAME
--     WITH SYNONYMS = ('doctor', 'physician', 'prescriber', ...)
--     WITH CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.HCP_NAME_SEARCH_SVC
--     COMMENT = '...'
--
-- The services MUST exist and be in ACTIVE status before running Script 03,
-- otherwise the CREATE SEMANTIC VIEW statement will fail.
--
-- Run 03_semantic_view.sql to complete the setup.
-- ═══════════════════════════════════════════════════════════════════════════════
