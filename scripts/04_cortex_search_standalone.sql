/* =============================================================================
   ALKERMES COMMERCIAL ANALYTICS DEMO
   Script 04 — Cortex Search: Standalone Mode (Direct Query)
   =============================================================================

   CORTEX SEARCH — THREE MODES OVERVIEW
   ─────────────────────────────────────
   Mode 1 │ CS linked to Semantic View dimension  → scripts 02 + 03
          │   Fuzzy SQL literal matching on a dimension column (e.g., HCP name
          │   lookup inside Cortex Analyst queries). Search is invoked implicitly
          │   when Analyst resolves filter values.

   Mode 2 │ CS standalone direct query            → THIS SCRIPT
          │   Query the search service directly via SNOWFLAKE.CORTEX.SEARCH_PREVIEW.
          │   No Analyst, no Agent. Pure fuzzy / semantic matching over any
          │   unstructured or semi-structured text column.

   Mode 3 │ CS as Agent tool (RAG retrieval)      → script 05
          │   The Agent orchestrates Search alongside Analyst: structured SQL for
          │   metrics + semantic retrieval for field intelligence, blended in one
          │   natural-language response.

   WHY STANDALONE SEARCH MATTERS
   ──────────────────────────────
   Cortex Search indexes any TEXT column and serves sub-second semantic results:
     • Tolerates misspellings, synonyms, and partial matches
     • No preprocessing or embedding pipelines to manage
     • Returns ranked JSON results that can be post-processed in SQL
     • Ideal for: HCP lookups, call-note intelligence, formulary issue triage

   SERVICES CREATED IN THIS SCRIPT
   ────────────────────────────────
   1. HCP_PROFILE_SEARCH_SVC  — semantic HCP finder (name, specialty, location)
   2. CALL_INTEL_SEARCH_SVC   — semantic call-note search (field intelligence)

   ============================================================================= */

-- ============================================================
-- CONFIG  (adjust to match your environment)
-- ============================================================
SET demo_db        = 'ALKERMES_DEMO';
SET demo_schema    = 'COMMERCIAL';
SET demo_warehouse = 'COMMERCIAL_AGENT_NON_CONF_R_WH';
SET demo_role      = 'SYSADMIN';

USE ROLE      IDENTIFIER($demo_role);
USE DATABASE  IDENTIFIER($demo_db);
USE SCHEMA    IDENTIFIER($demo_schema);
USE WAREHOUSE IDENTIFIER($demo_warehouse);


-- ============================================================
-- SECTION 1 — HCP PROFILE SEARCH SERVICE
-- ============================================================
-- Indexes a concatenated SEARCH_TEXT column that combines HCP name,
-- specialty, city, and state into a single searchable string.
-- This allows reps or apps to find HCPs by any combination of those
-- fields — including misspellings — in a single fuzzy query.
-- ============================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.HCP_PROFILE_SEARCH_SVC
  ON SEARCH_TEXT
  ATTRIBUTES HCP_ID, HCP_FULL_NAME, SPECIALTY, CITY, STATE, NPI, HCP_TIER
  TARGET_LAG = '1 hour'
  WAREHOUSE  = COMMERCIAL_AGENT_NON_CONF_R_WH
  AS
    SELECT
        HCP_ID,
        HCP_FULL_NAME || ' ' || SPECIALTY || ' ' || CITY || ' ' || STATE AS SEARCH_TEXT,
        HCP_FULL_NAME,
        SPECIALTY,
        CITY,
        STATE,
        NPI,
        HCP_TIER
    FROM ALKERMES_DEMO.COMMERCIAL.HCPS;


-- ============================================================
-- SECTION 2 — CALL INTELLIGENCE SEARCH SERVICE
-- ============================================================
-- Indexes free-text call notes written by field reps after HCP visits.
-- This surfaces formulary issues, competitive intel, patient program
-- feedback, and HCP sentiment buried in unstructured rep notes.
-- NOTE: This same service is used as the FieldIntelligence tool
--       in the Cortex Agent (script 05).
-- ============================================================

CREATE OR REPLACE CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.CALL_INTEL_SEARCH_SVC
  ON NOTE_TEXT
  ATTRIBUTES NOTE_ID, NOTE_DATE, HCP_ID, REP_ID
  TARGET_LAG = '1 hour'
  WAREHOUSE  = COMMERCIAL_AGENT_NON_CONF_R_WH
  AS
    SELECT
        NOTE_ID,
        NOTE_TEXT,
        NOTE_DATE,
        HCP_ID,
        REP_ID
    FROM ALKERMES_DEMO.COMMERCIAL.CALL_NOTES;


-- ============================================================
-- SECTION 3 — DEMO QUERIES (STANDALONE SEARCH_PREVIEW)
-- ============================================================
-- SNOWFLAKE.CORTEX.SEARCH_PREVIEW takes four arguments:
--   1. database name
--   2. schema name
--   3. service name
--   4. JSON config string: { query, columns, limit, [filter] }
--
-- Results are returned as a JSON string; wrap in PARSE_JSON to
-- navigate the result set or flatten with LATERAL FLATTEN.
-- ============================================================


-- ──────────────────────────────────────────────────────────────
-- QUERY 1 — Fuzzy name match (typo tolerance)
-- ──────────────────────────────────────────────────────────────
-- DEMONSTRATES: Cortex Search tolerates misspellings.
-- "Andersen" vs "Anderson" — a traditional LIKE or = would miss this.
-- Valuable for CRM lookup UIs where reps type names quickly in the field.
-- ──────────────────────────────────────────────────────────────
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'ALKERMES_DEMO',
        'COMMERCIAL',
        'HCP_PROFILE_SEARCH_SVC',
        OBJECT_CONSTRUCT(
            'query',   'Dr. Andersen',
            'columns', ARRAY_CONSTRUCT('HCP_FULL_NAME', 'SPECIALTY', 'CITY', 'STATE', 'NPI', 'HCP_TIER'),
            'limit',   5
        )::VARCHAR
    )
) AS search_results;
-- Expected: Returns Dr. Anderson (and similar names) despite the misspelling.
-- The semantic index understands phonetic and orthographic similarity.


-- ──────────────────────────────────────────────────────────────
-- QUERY 2 — Multi-field semantic search (specialty + geography)
-- ──────────────────────────────────────────────────────────────
-- DEMONSTRATES: Search across a concatenated text field.
-- A rep can find all addiction specialists in Texas with a single
-- natural-language query — no joins, no WHERE clauses.
-- ──────────────────────────────────────────────────────────────
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'ALKERMES_DEMO',
        'COMMERCIAL',
        'HCP_PROFILE_SEARCH_SVC',
        OBJECT_CONSTRUCT(
            'query',   'addiction specialist Texas',
            'columns', ARRAY_CONSTRUCT('HCP_FULL_NAME', 'SPECIALTY', 'CITY', 'STATE', 'NPI', 'HCP_TIER'),
            'limit',   10
        )::VARCHAR
    )
) AS search_results;
-- Expected: HCPs whose specialty is Addiction Medicine or similar, located in TX cities.
-- "Addiction specialist" also matches Addiction Psychiatry, Substance Use Disorder, etc.


-- ──────────────────────────────────────────────────────────────
-- QUERY 3 — Partial name + specialty combination
-- ──────────────────────────────────────────────────────────────
-- DEMONSTRATES: Partial token matching across name and specialty fields.
-- "Martins" matches "Martinez", "Martin", etc. — helpful for common
-- surname fragments combined with a specialty qualifier.
-- ──────────────────────────────────────────────────────────────
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'ALKERMES_DEMO',
        'COMMERCIAL',
        'HCP_PROFILE_SEARCH_SVC',
        OBJECT_CONSTRUCT(
            'query',   'Dr. Martins psychiatry',
            'columns', ARRAY_CONSTRUCT('HCP_FULL_NAME', 'SPECIALTY', 'CITY', 'STATE', 'NPI', 'HCP_TIER'),
            'limit',   5
        )::VARCHAR
    )
) AS search_results;
-- Expected: Psychiatrists with last name Martinez, Martin, Martinsen, etc.
-- Cortex Search ranks results by combined semantic relevance.


-- ──────────────────────────────────────────────────────────────
-- QUERY 4 — HCP tier + specialty (value segmentation)
-- ──────────────────────────────────────────────────────────────
-- DEMONSTRATES: Searching across structured tier data + specialty text.
-- Helps identify high-value targets in a given therapy area without
-- needing to know exact tier codes or specialty strings.
-- ──────────────────────────────────────────────────────────────
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'ALKERMES_DEMO',
        'COMMERCIAL',
        'HCP_PROFILE_SEARCH_SVC',
        OBJECT_CONSTRUCT(
            'query',   'Tier 1 psychiatrist high value',
            'columns', ARRAY_CONSTRUCT('HCP_FULL_NAME', 'SPECIALTY', 'CITY', 'STATE', 'NPI', 'HCP_TIER'),
            'limit',   10
        )::VARCHAR
    )
) AS search_results;
-- Expected: Top-tier psychiatrists ranked by semantic closeness to "Tier 1 high value".
-- Useful for territory planning and key account prioritization.


-- ──────────────────────────────────────────────────────────────
-- QUERY 5 — Call notes: formulary access issues
-- ──────────────────────────────────────────────────────────────
-- DEMONSTRATES: Semantic retrieval from free-text field notes.
-- Surfacing formulary barriers buried in unstructured rep notes
-- enables Market Access teams to identify payer-specific issues fast.
-- ──────────────────────────────────────────────────────────────
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'ALKERMES_DEMO',
        'COMMERCIAL',
        'CALL_INTEL_SEARCH_SVC',
        OBJECT_CONSTRUCT(
            'query',   'access barriers Blue Cross formulary',
            'columns', ARRAY_CONSTRUCT('NOTE_TEXT', 'NOTE_DATE', 'HCP_ID', 'REP_ID'),
            'limit',   5
        )::VARCHAR
    )
) AS search_results;
-- Expected: Call notes mentioning BCBS, formulary restrictions, prior auth requirements,
-- step therapy, or similar access-related friction. Semantic matching finds
-- synonyms: "coverage denial", "PA required", "not on formulary", etc.


-- ──────────────────────────────────────────────────────────────
-- QUERY 6 — Call notes: competitive intelligence
-- ──────────────────────────────────────────────────────────────
-- DEMONSTRATES: Mining rep notes for competitive signals.
-- Strategy teams can identify which competitors are gaining share
-- and where HCPs are expressing switching intent — without surveys.
-- ──────────────────────────────────────────────────────────────
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'ALKERMES_DEMO',
        'COMMERCIAL',
        'CALL_INTEL_SEARCH_SVC',
        OBJECT_CONSTRUCT(
            'query',   'physician preference competitor switching',
            'columns', ARRAY_CONSTRUCT('NOTE_TEXT', 'NOTE_DATE', 'HCP_ID', 'REP_ID'),
            'limit',   5
        )::VARCHAR
    )
) AS search_results;
-- Expected: Notes where reps recorded HCP preferences for competing products,
-- intent to switch, or objections raised during competitive detailing.
-- Finds semantically related phrases like "prefers [competitor]", "switching patients to".


-- ──────────────────────────────────────────────────────────────
-- QUERY 7 — Call notes: patient support program mentions
-- ──────────────────────────────────────────────────────────────
-- DEMONSTRATES: Tracking patient support program awareness and utilization.
-- Patient Services teams can identify HCPs actively using (or unaware of)
-- copay assistance and patient assistance programs via rep-captured notes.
-- ──────────────────────────────────────────────────────────────
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'ALKERMES_DEMO',
        'COMMERCIAL',
        'CALL_INTEL_SEARCH_SVC',
        OBJECT_CONSTRUCT(
            'query',   'patient assistance copay program',
            'columns', ARRAY_CONSTRUCT('NOTE_TEXT', 'NOTE_DATE', 'HCP_ID', 'REP_ID'),
            'limit',   5
        )::VARCHAR
    )
) AS search_results;
-- Expected: Notes referencing VIVITROL Savings Card, patient assistance programs,
-- bridge programs, free starter doses, or similar support resources.
-- Helps Patient Services measure program awareness and close education gaps.


-- ──────────────────────────────────────────────────────────────
-- QUERY 8 — Call notes: sample / starter kit requests
-- ──────────────────────────────────────────────────────────────
-- DEMONSTRATES: Intent-based signal extraction from rep notes.
-- Identifying HCPs who have requested samples or starter kits is a
-- leading indicator of new patient trial intent — valuable for
-- forecasting and rep follow-up prioritization.
-- ──────────────────────────────────────────────────────────────
SELECT PARSE_JSON(
    SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'ALKERMES_DEMO',
        'COMMERCIAL',
        'CALL_INTEL_SEARCH_SVC',
        OBJECT_CONSTRUCT(
            'query',   'sample request Vivitrol starter pack',
            'columns', ARRAY_CONSTRUCT('NOTE_TEXT', 'NOTE_DATE', 'HCP_ID', 'REP_ID'),
            'limit',   5
        )::VARCHAR
    )
) AS search_results;
-- Expected: Notes where reps recorded HCP requests for starter kits,
-- patient samples, or Vivitrol induction doses.
-- High match rate in this query = active pipeline for new patient starts.


-- ============================================================
-- SECTION 4 — PARSING RESULTS IN SQL
-- ============================================================
-- BONUS: Use LATERAL FLATTEN to unnest results into rows for
-- further filtering, joining back to structured tables, etc.
-- ============================================================

SELECT
    result.value:HCP_FULL_NAME::VARCHAR  AS hcp_name,
    result.value:SPECIALTY::VARCHAR      AS specialty,
    result.value:CITY::VARCHAR           AS city,
    result.value:STATE::VARCHAR          AS state,
    result.value:NPI::VARCHAR            AS npi,
    result.value:HCP_TIER::VARCHAR       AS tier
FROM
    LATERAL FLATTEN(
        INPUT => PARSE_JSON(
            SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
                'ALKERMES_DEMO',
                'COMMERCIAL',
                'HCP_PROFILE_SEARCH_SVC',
                OBJECT_CONSTRUCT(
                    'query',   'addiction medicine Ohio',
                    'columns', ARRAY_CONSTRUCT('HCP_FULL_NAME', 'SPECIALTY', 'CITY', 'STATE', 'NPI', 'HCP_TIER'),
                    'limit',   10
                )::VARCHAR
            )
        ):results
    ) AS result;
-- Flattening the JSON makes it easy to JOIN back to PRESCRIPTIONS or
-- HCPS for enriched downstream analysis — e.g., show search results
-- alongside TRx performance.


-- ============================================================
-- VERIFY SERVICES
-- ============================================================
SHOW CORTEX SEARCH SERVICES IN SCHEMA ALKERMES_DEMO.COMMERCIAL;

DESCRIBE CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.HCP_PROFILE_SEARCH_SVC;
DESCRIBE CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.CALL_INTEL_SEARCH_SVC;


-- ============================================================
-- NEXT STEP
-- ============================================================
-- CALL_INTEL_SEARCH_SVC is used as the "FieldIntelligence" tool
-- in the Cortex Agent (05_cortex_agent.sql).
-- The Agent orchestrates this service alongside CommercialAnalyst
-- (backed by the semantic view) to answer blended structured +
-- unstructured questions in a single natural-language interaction.
-- ============================================================
