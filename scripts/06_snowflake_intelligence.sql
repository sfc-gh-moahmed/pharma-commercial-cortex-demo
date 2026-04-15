/*
================================================================================
  SCRIPT 06: Snowflake Intelligence Configuration
  Database : ALKERMES_DEMO
  Schema   : COMMERCIAL
  Agent    : ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT
================================================================================
*/

-- ============================================================
-- CONFIG BLOCK
-- Update these variables to match your environment before running
-- ============================================================
SET DATABASE_NAME       = 'ALKERMES_DEMO';
SET SCHEMA_NAME         = 'COMMERCIAL';
SET AGENT_NAME          = 'COMMERCIAL_ANALYTICS_AGENT';
SET WAREHOUSE_NAME      = 'COMMERCIAL_AGENT_NON_CONF_R_WH';
SET ANALYST_MODEL_STAGE = '@ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_MODELS';
SET ANALYST_MODEL_FILE  = 'commercial_analytics.yaml';
SET SEARCH_SERVICE_NAME = 'ALKERMES_DEMO.COMMERCIAL.CALL_NOTES_SEARCH';

USE DATABASE ALKERMES_DEMO;
USE SCHEMA   COMMERCIAL;
USE WAREHOUSE COMMERCIAL_AGENT_NON_CONF_R_WH;

/*
================================================================================
  WHAT IS SNOWFLAKE INTELLIGENCE?
================================================================================
  Snowflake Intelligence is the conversational AI interface built on top of
  Cortex Agents. It provides a no-code, chat-based front end that allows
  business users to ask natural-language questions about their data without
  writing SQL.

  Key capabilities:
    - Routes questions to the appropriate tool (Cortex Analyst for structured
      data, Cortex Search for unstructured text, custom functions, etc.)
    - Renders answers as tables, charts, or plain text based on the result type
    - Surfaces pre-loaded "sample questions" to guide users on what to ask
    - Supports multi-turn conversations with context retention
    - Accessible from Snowsight: AI & ML → Snowflake Intelligence

  This script updates the live agent version with a production-ready
  specification that includes:
    - Full orchestration and model settings
    - Two tools: CommercialAnalyst (Cortex Analyst) and FieldIntelligence
      (Cortex Search)
    - 10 domain-specific sample questions tailored for the Alkermes commercial
      analytics team
================================================================================
*/

-- ============================================================
-- STEP 1: Update the agent LIVE VERSION with full production spec
-- ============================================================
-- This ALTER statement replaces the live agent specification in-place.
-- All users accessing the agent through Snowflake Intelligence will
-- immediately see the updated sample questions and instructions.
-- ============================================================

ALTER AGENT ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT
  MODIFY LIVE VERSION SET SPECIFICATION = $$
description: |
  Commercial analytics AI assistant for the Alkermes commercial team.
  Answers questions about HCP prescribing trends, territory performance,
  sales rep call activity, market access, and field intelligence using
  a combination of structured prescription data and unstructured rep
  call notes.

instructions: |
  You are a commercial analytics assistant for a pharmaceutical company
  specializing in CNS and addiction medicine products: Vivitrol, Aristada,
  and Lybalvi.

  Your primary users are commercial operations analysts, regional business
  managers, and sales leadership who need fast, accurate answers about
  field performance.

  ## Tool Routing Guidelines

  Use the **CommercialAnalyst** tool when the question involves:
  - Prescription volumes (TRx, NRx) by HCP, territory, region, or product
  - Performance vs. quota or annual targets
  - Sales rep call activity, call frequency, or conversion rates
  - Market share calculations by product, region, or time period
  - Revenue or account-level financial metrics
  - Rankings, trends, and comparisons across structured dimensions

  Use the **FieldIntelligence** tool when the question involves:
  - Rep call notes, field observations, or CRM narrative entries
  - Physician objections, concerns, or feedback captured in the field
  - Payer access barriers, prior authorization issues, or formulary status
  - Qualitative territory intelligence that is not captured in structured data
  - Any question that requires searching free-text field notes

  ## Response Guidelines

  - Present data in clean tables when comparing multiple entities
  - Generate charts automatically when the question involves trends over
    time or comparisons across regions or products
  - Be concise and lead with the most actionable finding
  - When surfacing field intelligence, cite the rep name, call date, and
    territory so results can be verified in the CRM
  - If a question spans both tools (e.g., "which territories underperform
    AND why?"), call CommercialAnalyst first for metrics, then
    FieldIntelligence for qualitative context
  - Use business-friendly language; avoid SQL or technical jargon in answers

models:
  - model_name: claude-3-5-sonnet

orchestration:
  type: cot

tools:
  - tool_name: CommercialAnalyst
    tool_type: CORTEX_ANALYST_TOOL
    description: |
      Answers structured data questions about HCP prescribing (TRx, NRx),
      territory performance vs. targets, sales rep call activity and
      conversion rates, product-level market share, and revenue metrics.
      Backed by a semantic view that defines all commercial KPIs.
      Use this tool for any question requiring quantitative analysis or
      SQL-based aggregation over the commercial data model.
    tool_spec:
      semantic_model_path: "@ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_MODELS/commercial_analytics.yaml"

  - tool_name: FieldIntelligence
    tool_type: CORTEX_SEARCH_TOOL
    description: |
      Searches unstructured rep call notes and field intelligence reports
      using semantic similarity. Use this tool for qualitative questions
      about physician objections, payer access barriers, formulary issues,
      and field observations captured by sales representatives during
      customer calls. Returns ranked excerpts with rep name, date, and
      territory context.
    tool_spec:
      service_name: ALKERMES_DEMO.COMMERCIAL.CALL_NOTES_SEARCH
      columns:
        - CALL_NOTE_TEXT
        - REP_NAME
        - CALL_DATE
        - TERRITORY_NAME
        - PRODUCT_NAME
        - HCP_NAME
      max_results: 5

sample_questions:
  - question: "Which territories are underperforming on Vivitrol TRx vs. target this quarter?"
    default_answer: "I'll analyze territory-level prescription data against annual targets to identify gaps."

  - question: "Show me HCP prescribing trends for Aristada in the Northeast over the last 12 months"
    default_answer: "I'll pull monthly NRx and TRx data for Aristada filtered to the Northeast region."

  - question: "Find all psychiatrists in Texas who haven't had a rep call in the last 60 days"
    default_answer: "I'll identify HCPs in Texas with specialty Psychiatry and check call activity recency."

  - question: "What is the formulary access rate for Vivitrol on commercial insurance plans?"
    default_answer: "I'll search field intelligence notes and market access data for Vivitrol formulary coverage."

  - question: "Which reps have the highest call-to-prescription conversion rate?"
    default_answer: "I'll calculate the ratio of rep call activity to resulting TRx by sales rep."

  - question: "Show me market share by product across all regions for the current year"
    default_answer: "I'll compute TRx market share percentages by product and region for 2025."

  - question: "Find recent field notes about physician objections or access barriers for Lybalvi"
    default_answer: "I'll search rep call notes for mentions of objections, barriers, or formulary issues related to Lybalvi."

  - question: "Which HCPs in the Midwest have the highest Aristada TRx growth in the last 6 months?"
    default_answer: "I'll identify top-growing Aristada prescribers in Midwest territories over the recent 6-month period."

  - question: "Compare regional performance across all three products year-to-date"
    default_answer: "I'll summarize TRx, NRx, and revenue by region and product for the YTD period and generate a chart."

  - question: "Which payers are creating the most access barriers based on rep field reports?"
    default_answer: "I'll search call intelligence notes for payer-specific access barrier mentions and rank them by frequency."
$$;

/*
================================================================================
  STEP 2: Grant access to commercial team users
================================================================================
  To make the agent available to business users in Snowflake Intelligence,
  grant USAGE on the agent to the appropriate role(s).

  Replace <user_role> with the role assigned to your commercial team,
  for example COMMERCIAL_ANALYST_ROLE or SYSADMIN for demo purposes.

  To access via Snowflake Intelligence:
    Snowsight → AI & ML → Snowflake Intelligence → select agent

  Share agent with users:
    GRANT USAGE ON AGENT ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT
      TO ROLE <user_role>;

  Grant read access to the underlying objects if not already granted:
    GRANT USAGE ON DATABASE ALKERMES_DEMO TO ROLE <user_role>;
    GRANT USAGE ON SCHEMA ALKERMES_DEMO.COMMERCIAL TO ROLE <user_role>;
    GRANT SELECT ON ALL TABLES IN SCHEMA ALKERMES_DEMO.COMMERCIAL TO ROLE <user_role>;
    GRANT USAGE ON CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.CALL_NOTES_SEARCH
      TO ROLE <user_role>;
================================================================================
*/

-- Uncomment and run after replacing <user_role>:
-- GRANT USAGE ON AGENT ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT
--   TO ROLE <user_role>;


-- ============================================================
-- STEP 3: Verify agent configuration
-- ============================================================

SHOW AGENTS IN SCHEMA ALKERMES_DEMO.COMMERCIAL;

-- Describe the agent to confirm the live version spec was applied:
DESCRIBE AGENT ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT;
