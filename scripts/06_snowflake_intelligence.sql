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
SET SEARCH_SERVICE_NAME = 'ALKERMES_DEMO.COMMERCIAL.CALL_INTEL_SEARCH_SVC';

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
models:
  orchestration: claude-4-sonnet

orchestration:
  budget:
    seconds: 60
    tokens: 32000

instructions:
  system: |
    You are a commercial analytics assistant for a specialty pharmaceutical
    company focused on CNS and addiction medicine. Primary products are
    Vivitrol (naltrexone), Aristada (aripiprazole lauroxil), and Lybalvi
    (olanzapine/samidorphan).

    You help field sales reps, regional business managers, and commercial
    analytics teams answer questions about prescriber performance, territory
    trends, market share, and field intelligence from rep call notes.

    Always provide clear, actionable insights grounded in the data.

  orchestration: |
    Use CommercialAnalyst for quantitative questions about TRx, NRx, revenue,
    market share, territory performance, rep productivity, and HCP prescribing.

    Use FieldIntelligence for qualitative questions about field intelligence,
    rep call notes, HCP sentiment, formulary access issues, competitive
    activity, and patient program feedback.

    Use data_to_chart to visualize any tabular data returned.

    For questions spanning both structured metrics and qualitative context,
    call both tools and synthesize results into a single cohesive response.

  response: |
    Structure responses clearly. Lead with the key finding, support with data,
    close with a recommended action. Keep responses concise and executive-ready.

  sample_questions:
    - question: "Which territories are underperforming on Vivitrol TRx vs. target this quarter?"
      answer: "I'll analyze territory-level prescription data against annual targets to identify gaps."

    - question: "Show me HCP prescribing trends for Aristada in the Northeast over the last 12 months"
      answer: "I'll pull monthly NRx and TRx data for Aristada filtered to the Northeast region."

    - question: "Find all psychiatrists in Texas who haven't had a rep call in the last 60 days"
      answer: "I'll identify HCPs in Texas with specialty Psychiatry and check call activity recency."

    - question: "What is the formulary access rate for Vivitrol on commercial insurance plans?"
      answer: "I'll search field intelligence notes and market access data for Vivitrol formulary coverage."

    - question: "Which reps have the highest call-to-prescription conversion rate?"
      answer: "I'll calculate the ratio of rep call activity to resulting TRx by sales rep."

    - question: "Show me market share by product across all regions for the current year"
      answer: "I'll compute TRx market share percentages by product and region."

    - question: "Find recent field notes about physician objections or access barriers for Lybalvi"
      answer: "I'll search rep call notes for mentions of objections, barriers, or formulary issues related to Lybalvi."

    - question: "Which HCPs in the Midwest have the highest Aristada TRx growth in the last 6 months?"
      answer: "I'll identify top-growing Aristada prescribers in Midwest territories."

    - question: "Compare regional performance across all three products year-to-date"
      answer: "I'll summarize TRx, NRx, and revenue by region and product for YTD and generate a chart."

    - question: "Which payers are creating the most access barriers based on rep field reports?"
      answer: "I'll search call intelligence notes for payer-specific access barrier mentions."

tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: CommercialAnalyst
      description: |
        Answers quantitative questions about commercial performance.
        Use for TRx trends, NRx volume, revenue, market share, territory
        ranking, HCP prescribing, and any aggregation over structured data.

  - tool_spec:
      type: cortex_search
      name: FieldIntelligence
      description: |
        Retrieves relevant excerpts from field rep call notes using semantic
        search. Use for HCP sentiment, formulary access issues, competitive
        intelligence, physician objections, and field observations.

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
        description: "Free-text field rep call notes - HCP feedback, formulary barriers, competitive intel, patient programs."
        type: string
        searchable: true
        filterable: false
      NOTE_DATE:
        description: "Date the call note was written."
        type: string
        searchable: false
        filterable: false
      HCP_ID:
        description: "HCP identifier."
        type: string
        searchable: false
        filterable: true
      REP_ID:
        description: "Field rep identifier."
        type: string
        searchable: false
        filterable: true
$$;

/*
================================================================================
  STEP 2: Grant access to commercial team users
================================================================================
  To make the agent available to business users in Snowflake Intelligence,
  grant USAGE on the agent to the appropriate role(s).

  Replace COMMERCIAL_AGENT_NON_CONF_R with the role assigned to your commercial team,
  for example COMMERCIAL_ANALYST_ROLE or SYSADMIN for demo purposes.

  To access via Snowflake Intelligence:
    Snowsight → AI & ML → Snowflake Intelligence → select agent

  Share agent with users:
    GRANT USAGE ON AGENT ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT
      TO ROLE COMMERCIAL_AGENT_NON_CONF_R;

  Grant read access to the underlying objects if not already granted:
    GRANT USAGE ON DATABASE ALKERMES_DEMO TO ROLE COMMERCIAL_AGENT_NON_CONF_R;
    GRANT USAGE ON SCHEMA ALKERMES_DEMO.COMMERCIAL TO ROLE COMMERCIAL_AGENT_NON_CONF_R;
    GRANT SELECT ON ALL TABLES IN SCHEMA ALKERMES_DEMO.COMMERCIAL TO ROLE COMMERCIAL_AGENT_NON_CONF_R;
    GRANT USAGE ON CORTEX SEARCH SERVICE ALKERMES_DEMO.COMMERCIAL.CALL_INTEL_SEARCH_SVC
      TO ROLE COMMERCIAL_AGENT_NON_CONF_R;
================================================================================
*/

-- Uncomment and run after replacing COMMERCIAL_AGENT_NON_CONF_R:
-- GRANT USAGE ON AGENT ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT
--   TO ROLE COMMERCIAL_AGENT_NON_CONF_R;


-- ============================================================
-- STEP 3: Verify agent configuration
-- ============================================================

SHOW AGENTS IN SCHEMA ALKERMES_DEMO.COMMERCIAL;

-- Describe the agent to confirm the live version spec was applied:
DESCRIBE AGENT ALKERMES_DEMO.COMMERCIAL.COMMERCIAL_ANALYTICS_AGENT;
