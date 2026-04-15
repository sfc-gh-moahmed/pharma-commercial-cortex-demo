/* =============================================================================
   ALKERMES COMMERCIAL ANALYTICS DEMO
   Script 05 — Cortex Agent: Blended Structured + Unstructured Analytics
   =============================================================================

   CORTEX SEARCH — THREE MODES RECAP
   ─────────────────────────────────────────────────────────────────────────────
   Mode 1 │ CS linked to Semantic View dimension         → scripts 02 + 03
          │   Fuzzy SQL literal matching on a Semantic View dimension column.
          │   Search resolves filter values (e.g., HCP names, territory IDs)
          │   implicitly when Cortex Analyst translates natural-language to SQL.
          │   Invoked: automatically, inside Analyst query generation.

   Mode 2 │ CS standalone direct query                   → script 04
          │   SNOWFLAKE.CORTEX.SEARCH_PREVIEW called directly in SQL.
          │   No Analyst. No Agent. Pure semantic search over a text corpus.
          │   Invoked: explicitly, by application or analyst via SQL.

   Mode 3 │ CS as Agent tool (RAG retrieval)             → THIS SCRIPT
          │   The Cortex Agent orchestrates two tools in a single conversation:
          │     • CommercialAnalyst (Cortex Analyst → SQL → structured metrics)
          │     • FieldIntelligence (Cortex Search → semantic note retrieval)
          │   The agent decides which tool (or both) to call based on question
          │   intent, blending quantitative analytics with qualitative field
          │   intelligence into a coherent, grounded natural-language response.
          │   Invoked: by the agent's orchestration layer, transparently to user.
   ─────────────────────────────────────────────────────────────────────────────

   ARCHITECTURE OF THE COMMERCIAL ANALYTICS AGENT
   ────────────────────────────────────────────────
   ┌────────────────────────────────────────────────┐
   │         COMMERCIAL_ANALYTICS_AGENT             │
   │                                                │
   │  ┌──────────────────────────────────────────┐  │
   │  │  CommercialAnalyst (Cortex Analyst Tool) │  │
   │  │  → Semantic View: COMMERCIAL_ANALYTICS_SV│  │
   │  │  → Answers: TRx, NRx, revenue, market    │  │
   │  │    share, territory perf, rep productivity│  │
   │  └──────────────────────────────────────────┘  │
   │                                                │
   │  ┌──────────────────────────────────────────┐  │
   │  │  FieldIntelligence (Cortex Search Tool)  │  │
   │  │  → Service: CALL_INTEL_SEARCH_SVC        │  │
   │  │  → Answers: formulary access issues,     │  │
   │  │    HCP sentiment, competitive intel,     │  │
   │  │    patient program feedback, rep notes   │  │
   │  └──────────────────────────────────────────┘  │
   │                                                │
   │  ┌──────────────────────────────────────────┐  │
   │  │  data_to_chart (Visualization Tool)      │  │
   │  │  → Converts tabular query results into   │  │
   │  │    charts for use in Snowflake UI         │  │
   │  └──────────────────────────────────────────┘  │
   └────────────────────────────────────────────────┘

   ============================================================================= */

-- ============================================================
-- CONFIG  (adjust to match your environment)
-- ============================================================
SET demo_db        = 'ALKERMES_DEMO';
SET demo_schema    = 'COMMERCIAL';
SET demo_warehouse = 'COMMERCIAL_AGENT_NON_CONF_R_WH';
SET demo_role      = 'COMMERCIAL_AGENT_NON_CONF_R';

USE ROLE      IDENTIFIER($demo_role);
USE DATABASE  IDENTIFIER($demo_db);
USE SCHEMA    IDENTIFIER($demo_schema);
USE WAREHOUSE IDENTIFIER($demo_warehouse);


-- ============================================================
-- SECTION 1 — CREATE COMMERCIAL ANALYTICS AGENT
-- ============================================================
-- The agent spec below defines:
--   • Model: claude-4-sonnet for orchestration
--   • Budget: 60-second / 32k-token cap per conversation turn
--   • System instruction: pharma commercial context + tool routing rules
--   • Orchestration instruction: when to use each tool
--   • Sample questions: pre-seeded examples for Snowflake Intelligence UI
--   • Tools: CommercialAnalyst, FieldIntelligence, data_to_chart
--   • Tool resources: semantic view binding + search service binding
-- ============================================================

CREATE OR REPLACE AGENT ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT
  COMMENT = 'Alkermes commercial analytics agent — blends structured TRx/revenue analytics with unstructured field intelligence from rep call notes'
  FROM SPECIFICATION
  $$
  models:
    orchestration: claude-4-sonnet

  orchestration:
    budget:
      seconds: 60
      tokens: 32000

  instructions:
    system: |
      You are a commercial analytics assistant for Alkermes, a specialty pharmaceutical
      company focused on treatments for alcohol dependence, opioid dependence, and
      schizophrenia. Your primary products are Vivitrol (naltrexone), Aristada
      (aripiprazole lauroxil), and Lybalvi (olanzapine/samidorphan).

      You help field sales representatives, regional business managers, and commercial
      analytics teams answer questions about prescriber performance, territory trends,
      market share, and field intelligence from rep call notes.

      You have access to two complementary data sources:
        1. Structured prescription and revenue data (via CommercialAnalyst)
        2. Unstructured field intelligence from rep call notes (via FieldIntelligence)

      Always provide clear, actionable insights grounded in the data. When presenting
      metrics, include relevant context (e.g., prior period comparison, territory
      benchmark). When presenting call note excerpts, cite the note date and indicate
      the rep and HCP involved where available.

      Do not speculate beyond the data available. If a question cannot be answered
      with the available tools, say so clearly and suggest what data would be needed.

    orchestration: |
      Use CommercialAnalyst for quantitative questions about TRx, NRx, revenue,
      market share, territory performance, rep productivity, and HCP prescribing data.

      Use FieldIntelligence for qualitative questions about field intelligence, rep
      call notes, HCP sentiment, formulary access issues, competitive activity, and
      patient program feedback.

      Use data_to_chart to visualize any tabular data returned by CommercialAnalyst.

      For questions that span both structured metrics and qualitative context — for
      example, "which territories are underperforming AND why based on field notes" —
      call both tools and synthesize the results into a single cohesive response.

      Prefer CommercialAnalyst when the question contains numeric thresholds, ranking,
      comparison operators (top N, highest, lowest, vs. prior period), or explicit
      metric names (TRx, NRx, revenue, market share).

      Prefer FieldIntelligence when the question contains sentiment language, refers
      to HCP feedback, mentions payer names, competitor names, patient programs, or
      asks what reps are "saying" or "hearing."

    response: |
      Structure responses clearly:
        - Lead with a direct answer or key finding
        - Support with data (table, chart, or quoted note excerpts as appropriate)
        - Close with a recommended action or next question where relevant

      When showing prescription data, always include the product name, time period,
      and relevant geography (territory or region).

      When quoting call notes, use block-quote formatting and include the note date.

      Keep responses concise and executive-ready unless the user asks for detail.

    sample_questions:
      - question: "Which territories are underperforming on Vivitrol TRx vs last quarter?"
        answer: |
          I'll pull TRx data by territory for Vivitrol and compare the current quarter
          to the prior quarter to identify territories with declining or below-benchmark
          performance. I'll flag any with a quarter-over-quarter decline greater than 10%.

      - question: "Show me market share by product for the Northeast region"
        answer: |
          I'll query market share (product TRx / total market TRx) broken down by
          Alkermes product for all territories in the Northeast region, then render
          a bar chart comparing Vivitrol, Aristada, and Lybalvi share side by side.

      - question: "Find any field notes about formulary access issues with Blue Cross plans"
        answer: |
          I'll search the field intelligence database for rep call notes mentioning
          Blue Cross formulary barriers, prior authorization requirements, step
          therapy restrictions, or coverage denials. Results will include note date,
          HCP, and rep for follow-up action.

      - question: "Which HCPs in Texas specialize in addiction medicine and have the highest TRx for Vivitrol?"
        answer: |
          I'll identify addiction medicine specialists in Texas from the HCP data,
          then rank them by Vivitrol TRx volume over the last 12 months. I'll also
          pull any recent call notes for the top prescribers to provide field context.

      - question: "What are reps saying about physician objections to Aristada?"
        answer: |
          I'll search all call notes for mentions of Aristada-related objections,
          hesitations, or concerns expressed by physicians during rep visits.
          Common themes — efficacy questions, injection logistics, insurance coverage,
          patient adherence — will be surfaced with supporting note excerpts.

      - question: "Compare rep productivity across all regions by call-to-prescription conversion"
        answer: |
          I'll calculate call volume per rep and corresponding TRx generated in each
          region to derive a call-to-prescription conversion metric. Results will be
          visualized as a regional heatmap to highlight where rep activity is
          translating most efficiently into prescriptions.

  tools:
    - tool_spec:
        type: cortex_analyst_text_to_sql
        name: CommercialAnalyst
        description: |
          Answers quantitative questions about Alkermes commercial performance.
          Use for: TRx trends, NRx volume, revenue by product/territory/period,
          market share analysis, territory ranking and comparison, HCP prescribing
          behavior, rep call activity, and any question requiring aggregation,
          filtering, or time-series analysis over structured prescription data.
          Backed by the COMMERCIAL_ANALYTICS_SV semantic view which contains
          verified business definitions for all key commercial metrics.

    - tool_spec:
        type: cortex_search
        name: FieldIntelligence
        description: |
          Retrieves relevant excerpts from field rep call notes using semantic search.
          Use for: HCP sentiment and feedback, formulary and payer access issues,
          competitive intelligence, physician objections, patient program awareness,
          sample and starter kit requests, and any question about what reps observed
          or discussed during HCP visits. Returns ranked note excerpts with metadata.

    - tool_spec:
        type: data_to_chart
        name: data_to_chart
        description: Generates visualizations from tabular data returned by other tools.

  tool_resources:
    CommercialAnalyst:
      semantic_view: "ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_SV"
      execution_environment:
        type: warehouse
        warehouse: COMMERCIAL_AGENT_NON_CONF_R_WH

    FieldIntelligence:
      name: "ALKERMES_DEMO.COMMERCIAL.CALL_INTEL_SEARCH_SVC"
      max_results: "5"
      title_column: "NOTE_TEXT"
      id_column: "NOTE_ID"
      columns_and_descriptions:
        NOTE_TEXT:
          description: >
            Free-text field rep call notes capturing HCP feedback, formulary and
            access barriers, competitive intelligence, patient case discussions,
            objection handling, and patient support program conversations.
          type: string
          searchable: true
          filterable: false
        NOTE_DATE:
          description: Date the call note was written by the field representative.
          type: string
          searchable: false
          filterable: false
        HCP_ID:
          description: Unique identifier of the HCP visited during the call.
          type: string
          searchable: false
          filterable: true
        REP_ID:
          description: Unique identifier of the field representative who wrote the note.
          type: string
          searchable: false
          filterable: true
  $$;


-- ============================================================
-- SECTION 2 — VERIFY AGENT
-- ============================================================

SHOW AGENTS IN SCHEMA ALKERMES_DEMO.COMMERCIAL;

DESCRIBE AGENT ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT;


-- ============================================================
-- SECTION 3 — GRANT ACCESS
-- ============================================================
-- Grant USAGE so other roles can invoke the agent.
-- Repeat the GRANT block for any custom roles that need access
-- (e.g., a SALES_ANALYTICS_ROLE or FIELD_REP_ROLE).
-- ============================================================

GRANT USAGE ON AGENT ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT
    TO ROLE COMMERCIAL_AGENT_NON_CONF_R;

-- Example: grant to a custom analytics role
-- GRANT USAGE ON AGENT ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT
--     TO ROLE COMMERCIAL_ANALYTICS_ROLE;

-- The agent also requires the invoking role to have USAGE on:
--   • The semantic view: ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_SV
--   • The search service: ALKERMES_DEMO.COMMERCIAL.CALL_INTEL_SEARCH_SVC
--   • The warehouse: COMMERCIAL_AGENT_NON_CONF_R_WH
-- Ensure those grants are in place for any downstream role.


-- ============================================================
-- SECTION 4 — TEST THE AGENT VIA SQL
-- ============================================================
-- DATA_AGENT_RUN invokes the agent programmatically from SQL.
-- The second argument is a JSON array of conversation messages.
-- Useful for: automated testing, embedding agent calls in
-- stored procedures, and pipeline-driven analytics workflows.
-- ============================================================

-- Test 1: Quantitative question (routes to CommercialAnalyst)
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT',
    '[{"role": "user", "content": "Which products had the highest TRx growth in the last 6 months?"}]'
) AS agent_response;


-- Test 2: Qualitative question (routes to FieldIntelligence)
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT',
    '[{"role": "user", "content": "What are field reps reporting about formulary access barriers for Vivitrol?"}]'
) AS agent_response;


-- Test 3: Blended question (routes to both tools)
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT',
    '[{"role": "user", "content": "Which territories are underperforming on Aristada TRx, and what are reps saying in those territories?"}]'
) AS agent_response;


-- Test 4: Multi-turn conversation (pass prior context in the messages array)
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT',
    '[{"role": "user", "content": "Show me top 10 Vivitrol prescribers in the Southeast"}, {"role": "assistant", "content": "[prior response from agent here]"}, {"role": "user", "content": "Now pull any call notes for those HCPs from the last 90 days"}]'
) AS agent_response;
-- Multi-turn passes the full conversation history so the agent can maintain
-- context across follow-up questions — essential for drill-down workflows.


-- ============================================================
-- SECTION 5 — SNOWFLAKE INTELLIGENCE UI
-- ============================================================
-- The agent is also accessible via Snowflake Intelligence (SI):
--
--   1. Navigate to Snowflake > Snowflake Intelligence in Snowsight
--   2. The COMMERCIAL_ANALYTICS_AGENT will appear automatically
--      once USAGE is granted to the active role
--   3. Sample questions from the spec appear as suggested prompts
--   4. Charts rendered by data_to_chart appear inline in the chat
--
-- The SI interface is the recommended entry point for business
-- users (RBMs, field reps, brand teams) who do not write SQL.
--
-- For embedded applications, use DATA_AGENT_RUN (Section 4 above)
-- to integrate the agent into CRM tools, rep portals, or dashboards.
-- ============================================================
