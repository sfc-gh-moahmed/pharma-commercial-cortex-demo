/*
╔══════════════════════════════════════════════════════════════════════════════╗
║  PHARMA COMMERCIAL ANALYTICS DEMO — Script 01: Synthetic Data               ║
║  Snowflake Cortex Search + Cortex Analyst + Snowflake Intelligence          ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  CONFIG — Update these values before running                                 ║
║  ─────────────────────────────────────────────────────────────────────────  ║
║  DATABASE : ALKERMES_DEMO       (change to your preferred database name)     ║
║  SCHEMA   : COMMERCIAL          (change to your preferred schema name)       ║
║  WAREHOUSE: COMMERCIAL_AGENT_NON_CONF_R_WH           (change to your warehouse)                   ║
║  ROLE     : COMMERCIAL_AGENT_NON_CONF_R        (change to SYSADMIN or your admin role)      ║
╚══════════════════════════════════════════════════════════════════════════════╝

  Run order: 01 → 02 → 03 → 04 → 05 → 06
  Estimated run time: ~2 minutes
*/

-- ── 0. SETUP ──────────────────────────────────────────────────────────────────
USE ROLE COMMERCIAL_AGENT_NON_CONF_R;

USE WAREHOUSE COMMERCIAL_AGENT_NON_CONF_R_WH;

CREATE DATABASE IF NOT EXISTS ALKERMES_DEMO
    COMMENT = 'Pharma commercial analytics demo database';

CREATE SCHEMA IF NOT EXISTS ALKERMES_DEMO.COMMERCIAL
    COMMENT = 'Commercial analytics schema — field force, HCP, Rx, market access';

USE SCHEMA ALKERMES_DEMO.COMMERCIAL;


-- ── 1. PRODUCTS ───────────────────────────────────────────────────────────────
-- CNS / addiction treatment portfolio (Vivitrol, Aristada, Lybalvi)
CREATE OR REPLACE TABLE PRODUCTS (
    PRODUCT_ID         NUMBER         NOT NULL PRIMARY KEY,
    PRODUCT_NAME       VARCHAR(100)   NOT NULL,
    BRAND_NAME         VARCHAR(100),
    GENERIC_NAME       VARCHAR(200),
    THERAPEUTIC_AREA   VARCHAR(100),
    INDICATION         VARCHAR(500),
    LAUNCH_DATE        DATE,
    LIST_PRICE_USD     NUMBER(10,2),
    DOSAGE_FORM        VARCHAR(100)
);

INSERT INTO PRODUCTS VALUES
    (1, 'VIVITROL',        'Vivitrol',        'Naltrexone 380mg Extended-Release Injectable',
     'Addiction',                  'Alcohol Use Disorder; Opioid Dependence Prevention',
     '2006-04-13', 1850.00, 'Extended-Release Injectable Suspension'),
    (2, 'ARISTADA',        'Aristada',        'Aripiprazole Lauroxil Extended-Release Injectable',
     'CNS - Schizophrenia',        'Schizophrenia in Adults',
     '2015-10-05', 1650.00, 'Extended-Release Injectable Suspension'),
    (3, 'ARISTADA_INITIO', 'Aristada Initio', 'Aripiprazole Lauroxil Initio',
     'CNS - Schizophrenia',        'Initiation dose for Aristada',
     '2018-07-23', 420.00,  'Extended-Release Injectable Suspension'),
    (4, 'LYBALVI',         'Lybalvi',         'Olanzapine/Samidorphan',
     'CNS - Schizophrenia/Bipolar','Schizophrenia; Bipolar I Disorder',
     '2021-06-01', 1400.00, 'Oral Tablet');


-- ── 2. TERRITORIES ────────────────────────────────────────────────────────────
-- 50 US territories across 7 geographic areas
CREATE OR REPLACE TABLE TERRITORIES (
    TERRITORY_ID         NUMBER       NOT NULL PRIMARY KEY,
    TERRITORY_NAME       VARCHAR(100) NOT NULL,
    DISTRICT             VARCHAR(100),
    REGION               VARCHAR(100),
    AREA                 VARCHAR(100),
    PRIMARY_STATE        VARCHAR(5),
    ANNUAL_TARGET_UNITS  NUMBER(10,0)
);

INSERT INTO TERRITORIES VALUES
-- NORTHEAST AREA
(101,'Boston North',       'New England District',    'Northeast Region','Northeast Area','MA',12000),
(102,'Boston South',       'New England District',    'Northeast Region','Northeast Area','MA',10500),
(103,'Hartford',           'New England District',    'Northeast Region','Northeast Area','CT', 9800),
(104,'Providence',         'New England District',    'Northeast Region','Northeast Area','RI', 8500),
(105,'Portland ME',        'New England District',    'Northeast Region','Northeast Area','ME', 7200),
(106,'NYC Manhattan',      'New York Metro District', 'Northeast Region','Northeast Area','NY',18000),
(107,'NYC Brooklyn',       'New York Metro District', 'Northeast Region','Northeast Area','NY',15000),
(108,'NYC Queens',         'New York Metro District', 'Northeast Region','Northeast Area','NY',14000),
(109,'Long Island',        'New York Metro District', 'Northeast Region','Northeast Area','NY',13000),
(110,'Westchester',        'New York Metro District', 'Northeast Region','Northeast Area','NY',11000),
-- MID-ATLANTIC AREA
(201,'Philadelphia',       'Mid-Atlantic District',   'Southeast Region','Mid-Atlantic Area','PA',14000),
(202,'Pittsburgh',         'Mid-Atlantic District',   'Southeast Region','Mid-Atlantic Area','PA',11000),
(203,'Baltimore',          'Mid-Atlantic District',   'Southeast Region','Mid-Atlantic Area','MD',12500),
(204,'Washington DC',      'Mid-Atlantic District',   'Southeast Region','Mid-Atlantic Area','DC',13000),
(205,'Northern VA',        'Mid-Atlantic District',   'Southeast Region','Mid-Atlantic Area','VA',10000),
(206,'Richmond',           'Mid-Atlantic District',   'Southeast Region','Mid-Atlantic Area','VA', 9000),
-- SOUTHEAST AREA
(301,'Charlotte',          'Southeast District',      'Southeast Region','Southeast Area','NC',11000),
(302,'Raleigh',            'Southeast District',      'Southeast Region','Southeast Area','NC',10500),
(303,'Atlanta North',      'Southeast District',      'Southeast Region','Southeast Area','GA',13000),
(304,'Atlanta South',      'Southeast District',      'Southeast Region','Southeast Area','GA',11500),
(305,'Miami',              'Southeast District',      'Southeast Region','Southeast Area','FL',14000),
(306,'Orlando',            'Southeast District',      'Southeast Region','Southeast Area','FL',12000),
(307,'Tampa',              'Southeast District',      'Southeast Region','Southeast Area','FL',11000),
(308,'Nashville',          'Southeast District',      'Southeast Region','Southeast Area','TN',10000),
-- MIDWEST AREA
(401,'Chicago North',      'Midwest District',        'Midwest Region',  'Midwest Area','IL',13500),
(402,'Chicago South',      'Midwest District',        'Midwest Region',  'Midwest Area','IL',12000),
(403,'Indianapolis',       'Midwest District',        'Midwest Region',  'Midwest Area','IN', 9500),
(404,'Columbus',           'Midwest District',        'Midwest Region',  'Midwest Area','OH',10000),
(405,'Cleveland',          'Midwest District',        'Midwest Region',  'Midwest Area','OH', 9800),
(406,'Detroit',            'Midwest District',        'Midwest Region',  'Midwest Area','MI',11000),
(407,'Minneapolis',        'Midwest District',        'Midwest Region',  'Midwest Area','MN',10500),
(408,'Milwaukee',          'Midwest District',        'Midwest Region',  'Midwest Area','WI', 9000),
(409,'St. Louis',          'Midwest District',        'Midwest Region',  'Midwest Area','MO', 9500),
(410,'Kansas City',        'Midwest District',        'Midwest Region',  'Midwest Area','MO', 8800),
-- SOUTH CENTRAL AREA
(501,'Dallas',             'South Central District',  'South Region',    'South Central Area','TX',13000),
(502,'Houston',            'South Central District',  'South Region',    'South Central Area','TX',14500),
(503,'Austin',             'South Central District',  'South Region',    'South Central Area','TX',11000),
(504,'San Antonio',        'South Central District',  'South Region',    'South Central Area','TX',10000),
(505,'Oklahoma City',      'South Central District',  'South Region',    'South Central Area','OK', 8000),
(506,'New Orleans',        'South Central District',  'South Region',    'South Central Area','LA', 9000),
-- MOUNTAIN AREA
(601,'Denver',             'Mountain District',       'West Region',     'Mountain Area','CO',11000),
(602,'Phoenix',            'Mountain District',       'West Region',     'Mountain Area','AZ',12000),
(603,'Salt Lake City',     'Mountain District',       'West Region',     'Mountain Area','UT', 9000),
(604,'Albuquerque',        'Mountain District',       'West Region',     'Mountain Area','NM', 7500),
(605,'Las Vegas',          'Mountain District',       'West Region',     'Mountain Area','NV',10000),
-- PACIFIC AREA
(701,'Los Angeles North',  'Pacific District',        'West Region',     'Pacific Area','CA',15000),
(702,'Los Angeles South',  'Pacific District',        'West Region',     'Pacific Area','CA',14000),
(703,'San Francisco',      'Pacific District',        'West Region',     'Pacific Area','CA',13500),
(704,'San Diego',          'Pacific District',        'West Region',     'Pacific Area','CA',12000),
(705,'Seattle',            'Pacific District',        'West Region',     'Pacific Area','WA',11000);


-- ── 3. SALES REPS ─────────────────────────────────────────────────────────────
-- 50 reps, one per territory, with realistic names
CREATE OR REPLACE TABLE SALES_REPS AS
WITH TERRITORY_LIST AS (
    SELECT TERRITORY_ID, TERRITORY_NAME, DISTRICT, REGION, ANNUAL_TARGET_UNITS,
           ROW_NUMBER() OVER (ORDER BY TERRITORY_ID) AS RN
    FROM TERRITORIES
),
FIRST_NAMES AS (
    SELECT VALUE::STRING AS FNAME, INDEX AS FN_IDX
    FROM TABLE(FLATTEN(ARRAY_CONSTRUCT(
        'Alex','Brianna','Carlos','Diana','Ethan',
        'Fiona','George','Hannah','Ivan','Julia',
        'Kevin','Laura','Marcus','Nina','Oscar',
        'Priya','Quinn','Rachel','Samuel','Tara',
        'Usman','Vanessa','Wade','Xena','Yusuf',
        'Zoe','Aaron','Beth','Cole','Dena',
        'Erik','Faith','Grant','Holly','Ian',
        'Jade','Kyle','Lena','Miles','Nora',
        'Owen','Paula','Reed','Sofia','Troy',
        'Uma','Victor','Wendy','Xavier','Yvette'
    )))
),
LAST_NAMES AS (
    SELECT VALUE::STRING AS LNAME, INDEX AS LN_IDX
    FROM TABLE(FLATTEN(ARRAY_CONSTRUCT(
        'Adams','Baker','Chen','Davis','Evans',
        'Foster','Green','Hayes','Irving','Jensen',
        'Kim','Lopez','Murphy','Nelson','Ortega',
        'Patel','Quinn','Rivera','Smith','Torres',
        'Ueda','Vasquez','Walsh','Xu','Young',
        'Zhang','Allen','Brooks','Carter','Dixon',
        'Edwards','Flynn','Garcia','Hill','Jones',
        'King','Lane','Morgan','Nash','Owen',
        'Park','Reed','Santos','Turner','Upton',
        'Vega','Webb','Xiong','York','Zuniga'
    )))
),
MANAGERS AS (
    SELECT VALUE::STRING AS MGR, INDEX AS MGR_IDX
    FROM TABLE(FLATTEN(ARRAY_CONSTRUCT(
        'Jennifer Walsh - NE District Mgr',
        'Michael Torres - Mid-Atlantic District Mgr',
        'Sandra Garcia - SE District Mgr',
        'Robert Chen - Midwest District Mgr',
        'Angela Rivera - South Central District Mgr',
        'David Kim - Mountain District Mgr',
        'Patricia Lopez - Pacific District Mgr'
    )))
)
SELECT
    t.RN                                                      AS REP_ID,
    f.FNAME || ' ' || l.LNAME                                AS REP_NAME,
    t.TERRITORY_ID,
    t.REGION,
    t.DISTRICT,
    DATEADD('day', -FLOOR(UNIFORM(180, 2190, RANDOM())), CURRENT_DATE()) AS HIRE_DATE,
    ROUND(t.ANNUAL_TARGET_UNITS * UNIFORM(0.9, 1.1, RANDOM()))           AS ANNUAL_QUOTA_UNITS,
    m.MGR                                                     AS MANAGER_NAME
FROM TERRITORY_LIST t
JOIN FIRST_NAMES  f ON t.RN - 1 = f.FN_IDX
JOIN LAST_NAMES   l ON t.RN - 1 = l.LN_IDX
JOIN MANAGERS     m ON MOD(t.RN - 1, 7) = m.MGR_IDX;

ALTER TABLE SALES_REPS ADD CONSTRAINT PK_SALES_REPS PRIMARY KEY (REP_ID);
ALTER TABLE SALES_REPS ADD CONSTRAINT FK_SALES_REPS_TERRITORY
    FOREIGN KEY (TERRITORY_ID) REFERENCES TERRITORIES(TERRITORY_ID);


-- ── 4. HCPS ───────────────────────────────────────────────────────────────────
-- 500 Healthcare Providers: psychiatrists, addiction specialists, and others
-- Uses 25 first names × 20 last names for 500 unique "Dr. First Last" combos
CREATE OR REPLACE TABLE HCPS AS
WITH FIRST_NAMES AS (
    SELECT VALUE::STRING AS FNAME, INDEX AS FN_IDX
    FROM TABLE(FLATTEN(ARRAY_CONSTRUCT(
        'James','Maria','David','Jennifer','Michael',
        'Patricia','Robert','Linda','William','Barbara',
        'Richard','Susan','Joseph','Jessica','Thomas',
        'Sarah','Charles','Karen','Christopher','Lisa',
        'Daniel','Nancy','Matthew','Betty','Anthony'
    )))
),
LAST_NAMES AS (
    SELECT VALUE::STRING AS LNAME, INDEX AS LN_IDX
    FROM TABLE(FLATTEN(ARRAY_CONSTRUCT(
        'Anderson','Garcia','Martinez','Johnson','Williams',
        'Jones','Brown','Davis','Miller','Wilson',
        'Moore','Taylor','Thomas','Jackson','White',
        'Harris','Martin','Thompson','Robinson','Clark'
    )))
),
NUMS AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS N
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
),
TERRITORY_MAP AS (
    SELECT TERRITORY_ID, ROW_NUMBER() OVER (ORDER BY TERRITORY_ID) - 1 AS T_IDX
    FROM TERRITORIES
),
CITIES AS (
    SELECT VALUE::STRING AS CITY_VAL, INDEX AS CITY_IDX
    FROM TABLE(FLATTEN(ARRAY_CONSTRUCT(
        'Boston','New York','Philadelphia','Baltimore','Washington',
        'Charlotte','Atlanta','Miami','Chicago','Indianapolis',
        'Columbus','Detroit','Minneapolis','Dallas','Houston',
        'Austin','Denver','Phoenix','Los Angeles','Seattle',
        'San Francisco','Nashville','Orlando','Pittsburgh','Tampa',
        'Kansas City','St. Louis','New Orleans','San Diego','Portland'
    )))
)
SELECT
    n.N                                              AS HCP_ID,
    'Dr. ' || fn.FNAME || ' ' || ln.LNAME           AS HCP_FULL_NAME,
    LPAD(CAST(1000000000 + n.N AS VARCHAR), 10, '0')AS NPI,
    CASE MOD(n.N, 5)
        WHEN 0 THEN 'Psychiatry'
        WHEN 1 THEN 'Addiction Medicine'
        WHEN 2 THEN 'Internal Medicine'
        WHEN 3 THEN 'Family Medicine'
        ELSE        'Neurology'
    END                                              AS SPECIALTY,
    c.CITY_VAL                                       AS CITY,
    ter.PRIMARY_STATE                                AS STATE,
    LPAD(CAST(10000 + MOD(n.N * 37, 89999) AS VARCHAR), 5, '0') AS ZIP,
    t.TERRITORY_ID,
    CASE MOD(n.N, 5)
        WHEN 0 THEN 'HIGH'
        WHEN 1 THEN 'MEDIUM'
        WHEN 2 THEN 'MEDIUM'
        ELSE        'LOW'
    END                                              AS HCP_TIER,
    MOD(n.N, 5) = 0                                 AS IS_KEY_ACCOUNT,
    5 + MOD(n.N * 13, 30)                           AS YEARS_IN_PRACTICE
FROM NUMS n
JOIN FIRST_NAMES  fn ON MOD(n.N - 1, 25) = fn.FN_IDX
JOIN LAST_NAMES   ln ON FLOOR((n.N - 1) / 25) = ln.LN_IDX
JOIN TERRITORY_MAP t  ON MOD(n.N - 1, 50) = t.T_IDX
JOIN TERRITORIES  ter ON t.TERRITORY_ID = ter.TERRITORY_ID
JOIN CITIES       c   ON MOD(n.N - 1, 30) = c.CITY_IDX;

ALTER TABLE HCPS ADD CONSTRAINT PK_HCPS PRIMARY KEY (HCP_ID);


-- ── 5. PRESCRIPTIONS ──────────────────────────────────────────────────────────
-- Monthly TRx/NRx by HCP × Product, Jan 2024 – Dec 2025 (~12,000 rows)
-- Products 1 (VIVITROL), 2 (ARISTADA), 4 (LYBALVI) — skip ARISTADA_INITIO
CREATE OR REPLACE TABLE PRESCRIPTIONS AS
WITH MONTHS AS (
    SELECT DATEADD('month', -(N - 1), '2025-12-01'::DATE) AS RX_MONTH
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS N
          FROM TABLE(GENERATOR(ROWCOUNT => 24)))
),
PRODUCT_SET AS (
    SELECT PRODUCT_ID, LIST_PRICE_USD
    FROM PRODUCTS
    WHERE PRODUCT_ID IN (1, 2, 4)
),
COMBOS AS (
    SELECT
        h.HCP_ID,
        h.HCP_TIER,
        h.SPECIALTY,
        h.TERRITORY_ID,
        p.PRODUCT_ID,
        p.LIST_PRICE_USD,
        m.RX_MONTH,
        ROW_NUMBER() OVER (ORDER BY h.HCP_ID, p.PRODUCT_ID, m.RX_MONTH) AS RN
    FROM HCPS h
    CROSS JOIN PRODUCT_SET p
    CROSS JOIN MONTHS m
    -- ~70% fill rate: not every HCP writes every product every month
    WHERE MOD(h.HCP_ID + p.PRODUCT_ID * 7 + MONTH(m.RX_MONTH), 10) < 7
)
SELECT
    RN                                                  AS PRESCRIPTION_ID,
    HCP_ID,
    PRODUCT_ID,
    TERRITORY_ID,
    LAST_DAY(RX_MONTH)                                  AS RX_DATE,
    RX_MONTH,
    CASE HCP_TIER
        WHEN 'HIGH'   THEN 5  + MOD(HCP_ID, 8)
        WHEN 'MEDIUM' THEN 2  + MOD(HCP_ID, 5)
        ELSE               1  + MOD(HCP_ID, 3)
    END                                                 AS TRX,
    GREATEST(1, ROUND(
        CASE HCP_TIER
            WHEN 'HIGH'   THEN 5  + MOD(HCP_ID, 8)
            WHEN 'MEDIUM' THEN 2  + MOD(HCP_ID, 5)
            ELSE               1  + MOD(HCP_ID, 3)
        END * (0.2 + MOD(HCP_ID, 3) * 0.1)
    ))                                                  AS NRX,
    -- Market TRx = total market volume (competitive context)
    (CASE HCP_TIER
        WHEN 'HIGH'   THEN 5  + MOD(HCP_ID, 8)
        WHEN 'MEDIUM' THEN 2  + MOD(HCP_ID, 5)
        ELSE               1  + MOD(HCP_ID, 3)
    END) * (6 + MOD(HCP_ID, 6))                        AS MARKET_TRX,
    -- Revenue estimate
    (CASE HCP_TIER
        WHEN 'HIGH'   THEN 5  + MOD(HCP_ID, 8)
        WHEN 'MEDIUM' THEN 2  + MOD(HCP_ID, 5)
        ELSE               1  + MOD(HCP_ID, 3)
    END) * LIST_PRICE_USD                               AS REVENUE_USD
FROM COMBOS;

ALTER TABLE PRESCRIPTIONS ADD CONSTRAINT PK_PRESCRIPTIONS PRIMARY KEY (PRESCRIPTION_ID);


-- ── 6. CALL ACTIVITY ──────────────────────────────────────────────────────────
-- Field rep calls on HCPs, Jan 2023 – Jun 2025 (~15,000 rows)
CREATE OR REPLACE TABLE CALL_ACTIVITY AS
WITH CALL_DATES AS (
    SELECT DATEADD('day', -(N - 1) * 3, '2025-06-30'::DATE) AS CALL_DATE
    FROM (SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS N
          FROM TABLE(GENERATOR(ROWCOUNT => 270)))  -- ~270 business periods
),
CALL_TYPES   AS (SELECT VALUE::STRING AS CT, INDEX AS CT_IDX FROM TABLE(FLATTEN(ARRAY_CONSTRUCT('In-Person','Virtual','Phone','In-Person','In-Person')))),
OUTCOMES     AS (SELECT VALUE::STRING AS OC, INDEX AS OC_IDX FROM TABLE(FLATTEN(ARRAY_CONSTRUCT('Completed','Completed','Completed','No See','Left Materials')))),
PRODUCTS_D   AS (SELECT VALUE::STRING AS PD, INDEX AS PD_IDX FROM TABLE(FLATTEN(ARRAY_CONSTRUCT('Vivitrol','Aristada','Lybalvi','Vivitrol, Aristada','Vivitrol, Lybalvi')))),
COMBOS AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY h.HCP_ID, d.CALL_DATE) AS CALL_ID,
        r.REP_ID,
        h.HCP_ID,
        h.TERRITORY_ID,
        d.CALL_DATE
    FROM HCPS h
    JOIN SALES_REPS r ON h.TERRITORY_ID = r.TERRITORY_ID
    CROSS JOIN CALL_DATES d
    -- ~2-4 calls per HCP per year
    WHERE MOD(h.HCP_ID + DAYOFYEAR(d.CALL_DATE), 30) < 4
    LIMIT 15000
)
SELECT
    c.CALL_ID,
    c.REP_ID,
    c.HCP_ID,
    c.TERRITORY_ID,
    c.CALL_DATE,
    ct.CT                                           AS CALL_TYPE,
    oc.OC                                           AS CALL_OUTCOME,
    pd.PD                                           AS PRODUCTS_DISCUSSED,
    CASE WHEN oc.OC = 'Completed' THEN MOD(c.HCP_ID, 3) ELSE 0 END AS SAMPLES_LEFT,
    CASE ct.CT
        WHEN 'In-Person' THEN 15 + MOD(c.HCP_ID, 20)
        WHEN 'Virtual'   THEN 10 + MOD(c.HCP_ID, 15)
        ELSE                   5 + MOD(c.HCP_ID, 10)
    END                                             AS CALL_DURATION_MIN
FROM COMBOS c
JOIN CALL_TYPES  ct ON MOD(c.HCP_ID + c.CALL_ID, 5) = ct.CT_IDX
JOIN OUTCOMES    oc ON MOD(c.HCP_ID * 3 + c.CALL_ID, 5) = oc.OC_IDX
JOIN PRODUCTS_D  pd ON MOD(c.HCP_ID + MONTH(c.CALL_DATE), 5) = pd.PD_IDX;

ALTER TABLE CALL_ACTIVITY ADD CONSTRAINT PK_CALL_ACTIVITY PRIMARY KEY (CALL_ID);


-- ── 7. MARKET ACCESS ──────────────────────────────────────────────────────────
-- Formulary status by payer × product (~600 rows)
CREATE OR REPLACE TABLE MARKET_ACCESS AS
WITH PAYERS AS (
    SELECT VALUE::STRING AS PAYER, INDEX AS P_IDX
    FROM TABLE(FLATTEN(ARRAY_CONSTRUCT(
        'Aetna Commercial','UnitedHealthcare Commercial','BCBS Massachusetts',
        'BCBS Illinois','BCBS Texas','BCBS Florida','Cigna Commercial',
        'Humana Commercial','Anthem Commercial','Centene Commercial',
        'Molina Healthcare','WellCare','Medicaid - Massachusetts','Medicaid - New York',
        'Medicaid - Texas','Medicaid - Florida','Medicaid - California',
        'Medicare Part D - Aetna','Medicare Part D - UHC','Medicare Part D - Cigna',
        'Highmark BCBS','Independence Blue Cross','Tufts Health Plan',
        'Harvard Pilgrim','Premera Blue Cross','Regence BCBS','HealthMarket',
        'Oscar Health','Bright Health','Friday Health Plans',
        'Optum Health','Magellan Health','Beacon Health','Evernorth',
        'Carelon','Evolent Health','AlohaCare','UPMC Health Plan',
        'Geisinger Health Plan','Capital BlueCross','CareFirst BCBS',
        'CareSource','Meridian Health','Ambetter','Alliant Health Plans',
        'Community Health Options','CHRISTUS Health','Banner Health',
        'Horizon BCBS NJ','ConnectiCare'
    )))
),
FORMULARY_STATUS AS (
    SELECT VALUE::STRING AS FS, INDEX AS FS_IDX
    FROM TABLE(FLATTEN(ARRAY_CONSTRUCT('Preferred','Non-Preferred','PA Required','Not Covered','Preferred')))
),
PRODUCTS_A AS (
    SELECT PRODUCT_ID FROM PRODUCTS
),
QUARTERS AS (
    SELECT VALUE::STRING AS QTR, INDEX AS Q_IDX
    FROM TABLE(FLATTEN(ARRAY_CONSTRUCT('2024-Q3','2024-Q4','2025-Q1','2025-Q2')))
)
SELECT
    ROW_NUMBER() OVER (ORDER BY py.P_IDX, pr.PRODUCT_ID, q.Q_IDX) AS ACCESS_ID,
    py.PAYER                                    AS PAYER_NAME,
    CASE WHEN py.P_IDX < 12 THEN 'Commercial'
         WHEN py.P_IDX < 17 THEN 'Medicaid'
         ELSE 'Medicare'
    END                                         AS PLAN_TYPE,
    pr.PRODUCT_ID,
    fs.FS                                       AS FORMULARY_STATUS,
    TO_DATE('2024-07-01') + (q.Q_IDX * 90)     AS EFFECTIVE_DATE,
    CASE WHEN py.P_IDX < 20 THEN
             ARRAY_CONSTRUCT('MA','NY','TX','FL','CA')[MOD(py.P_IDX,5)]::STRING
         ELSE 'National'
    END                                         AS COVERAGE_STATE,
    CASE fs.FS
        WHEN 'Preferred'     THEN NULL
        WHEN 'Non-Preferred' THEN NULL
        WHEN 'PA Required'   THEN 'Medical necessity required; step therapy with oral naltrexone'
        ELSE NULL
    END                                         AS PA_CRITERIA
FROM PAYERS py
CROSS JOIN PRODUCTS_A pr
CROSS JOIN QUARTERS q
JOIN FORMULARY_STATUS fs ON MOD(py.P_IDX + pr.PRODUCT_ID * 3 + q.Q_IDX, 5) = fs.FS_IDX;

ALTER TABLE MARKET_ACCESS ADD CONSTRAINT PK_MARKET_ACCESS PRIMARY KEY (ACCESS_ID);


-- ── 8. CALL NOTES ─────────────────────────────────────────────────────────────
-- Rich free-text rep field notes — used by Cortex Search (standalone + agent tool)
-- Intentional misspellings included to demonstrate fuzzy search value
CREATE OR REPLACE TABLE CALL_NOTES (
    NOTE_ID    NUMBER        NOT NULL PRIMARY KEY,
    REP_ID     NUMBER        REFERENCES SALES_REPS(REP_ID),
    HCP_ID     NUMBER        REFERENCES HCPS(HCP_ID),
    NOTE_DATE  DATE,
    NOTE_TEXT  VARCHAR(2000)
);

INSERT INTO CALL_NOTES (NOTE_ID, REP_ID, HCP_ID, NOTE_DATE, NOTE_TEXT) VALUES
(1, 1, 1, '2025-03-12',
 'Met with Dr. Anderson at Boston clinic. She expressed strong interest in expanding Vivitrol use for opioid dependence patients. Key concern: Blue Cross MA requiring prior authorization for new patients. She currently writes 5-6 scripts/month but could double with better PA support. Will follow up with formulary team.'),
(2, 2, 26, '2025-03-14',
 'Called on Dr. Garcia in NYC. He specializes in addiction medicine at a community health center. Mentioned that United Healthcare commercial has eased Vivitrol access - now preferred on formulary. Patient volume is high. Left 2 samples. Strong advocate, key account to nurture.'),
(3, 3, 51, '2025-03-10',
 'Visit with Dr. Martines (addiction medicine, Philadelphia). Note: difficult to get past front desk - suggest morning calls. He raised concern about Aristada vs. competitor oral option - patient adherence is key differentiator. Showed injection adherence data, seemed receptive. Follow-up scheduled April.'),
(4, 4, 76, '2025-02-28',
 'Dr. Johnston in Baltimore - psychiatry. Lybalvi discussion. She is concerned about samidorphan component and opioid-dependent patients - good scientific discussion around prescribing considerations. Very knowledgeable. Will likely be a targeted prescriber for non-opioid bipolar patients. Left Lybalvi PI and MOA card.'),
(5, 5, 101, '2025-03-18',
 'Dr. Williams in DC - high volume psychiatrist. Frustrated with Cigna commercial PA process for Aristada. States it takes 2-3 weeks and many patients abandon treatment. Competitive issue: haloperidol decanoate being recommended by Cigna formulary team. Escalated to market access team.'),
(6, 6, 126, '2025-03-05',
 'Called on Dr. Jones (Charlotte, NC - addiction medicine). Very enthusiastic about Vivitrol. His practice just signed a REMS agreement. Expects to write 8-10 new Vivitrol scripts per month once REMS certified. Key champion - schedule quarterly business review. Region opportunity.'),
(7, 7, 151, '2025-02-20',
 'Dr. Brown in Atlanta - psychiatry. Raised formulary issues with Aetna commercial for Lybalvi - classified as non-preferred, requiring step therapy with generic olanzapine. Many of her patients fail generic first. Working with Aetna medical director to improve tier placement.'),
(8, 8, 176, '2025-03-22',
 'Visit with Dr. Davis (Miami, FL - psychiatry). Strong Aristada user. Mentioned Humana Medicare Part D now covering Aristada with PA - significant because 60% of his patient panel is Medicare. Should drive TRx growth Q2. Shared patient support program details.'),
(9, 9, 201, '2025-01-15',
 'Dr. Miller in Chicago - addiction medicine specialist. Expressed frustration that some emergency departments in his hospital system are not referring patients for Vivitrol after naloxone administration. Working with hospital pharmacy to add Vivitrol to discharge protocol. Huge opportunity if successful.'),
(10, 10, 226, '2025-03-08',
 'Dr. Wilson in Indianapolis - Lybalvi discussion. He was unaware of the new copay card reducing patient OOP to $0 for eligible patients. Very excited - said this removes his primary objection. Expect meaningful script growth. Updated him on BCBS Indiana preferred tier status.'),
(11, 11, 251, '2025-02-10',
 'Dr. Moore in Columbus - psychiatry. Competitive call - she has been writing primarily oral aripiprazole due to lack of prior auth hassle. Discussed long-acting injectable benefits: adherence data, reduced hospitalization rates. Showed QUALIFY study. Left Aristada savings card.'),
(12, 12, 276, '2025-03-25',
 'Called on Dr. Taylor in Dallas (addiction medicine). His clinic serves a high Medicaid population. Texas Medicaid currently requires PA for Vivitrol - approvals take 10+ business days. Several patients have dropped off before approval. Escalated to state Medicaid team for access improvement.'),
(13, 13, 301, '2025-03-01',
 'Dr. Thomas in Houston - psychiatry. Interested in Lybalvi for treatment-resistant bipolar patients. Key objection: once-daily oral dosing is not differentiated enough from generic combo. Discussed samidorphan MOA and weight gain differentiation vs standard olanzapine. Left MOA data.'),
(14, 14, 326, '2025-02-14',
 'Dr. Jackson in Phoenix - addiction medicine. Major patient assistance program conversation. Several uninsured patients need Vivitrol. Walked through Vivitrol Bridge Program - he was not aware. Will enroll 3 patients immediately. This rep needs patient access materials for this territory.'),
(15, 15, 351, '2025-03-19',
 'Dr. White in Denver - psychiatry. Expressed concern about Aristada initiation complexity vs. competitor Invega Sustenna. Reviewed Aristada INITIO simplification - same-day start without oral overlap for most patients. He was impressed. Will pilot with 2 new patients next week.'),
(16, 16, 376, '2025-01-30',
 'Dr. Hariss (note: Dr. Harris) in LA - high volume prescriber. Anthem commercial is blocking Aristada for patients who haven't tried 2 oral antipsychotics first. This step therapy requirement is causing delays of 4-6 weeks. Patients often decompensate during that period. Very frustrated.'),
(17, 17, 401, '2025-03-11',
 'Dr. Martin in San Francisco - addiction medicine. Huge Vivitrol champion. He has worked with SF Dept of Public Health to include Vivitrol in their opioid treatment program. Prescribes 15+ scripts monthly. Invited to participate in speaker program. Regional KOL opportunity.'),
(18, 18, 426, '2025-02-05',
 'Dr. Thompsen (note: Dr. Thompson) in Seattle - psychiatry. First call. She was not familiar with Lybalvi. Good introductory discussion. Left full PI and MOA materials. She sees 80 patients/week - significant opportunity. Follow-up in 3 weeks with patient cases and clinical data.'),
(19, 19, 451, '2025-03-28',
 'Dr. Robinson in Minneapolis - addiction medicine. State Medicaid recently added Vivitrol to preferred formulary in Minnesota - great news. He sees 40+ patients/month in his MAT clinic. Expecting TRx to grow significantly H2 2025. Key territory win for this region.'),
(20, 20, 476, '2025-02-18',
 'Dr. Clark in Kansas City - psychiatry. Raised concerns about Lybalvi patient copay burden. Average commercial patient paying $200+/month. Reviewed copay assistance card - reduces to $0. He was receptive. Also discussed Lybalvi ENLIGHTEN-1 efficacy data vs standard olanzapine.'),
(21, 21, 491, '2025-03-14',
 'Dr. Roberts (note: misspelled in CRM as Robers) in Oklahoma City - addiction medicine. Very engaged with Vivitrol data for alcohol use disorder. Mentioned that competitor naltrexone ER is being pushed by local PBM. Shared Vivitrol dosing convenience and pharmacokinetic data.'),
(22, 22, 492, '2025-01-25',
 'Dr. Gonzalez in New Orleans - psychiatry. High Medicaid population. Concerned about access for Aristada with Louisiana Medicaid step-therapy requirement. Connected him with Alkermes patient access team. Plans to use Aristada for privately insured patients while working access issues.'),
(23, 23, 75, '2025-03-07',
 'Called on Dr. Lee in Baltimore - internal medicine (not traditional prescriber). Discussing referral relationships with addiction specialists. This is a referral opportunity - he sees patients post-hospitalization for overdose. Can channel patients to addiction specialists who prescribe Vivitrol.'),
(24, 24, 100, '2025-02-22',
 'Dr. Rodriguez in NYC - psychiatry. Major account. He runs a large group practice. Currently using Aristada for about 30% of his LAI patients. Primary barrier: nursing staff not trained on injection technique. Arranged in-service training with district manager. High value account.'),
(25, 25, 125, '2025-03-17',
 'Dr. Nguyen in Philadelphia - addiction medicine. Relatively new practice, just 2 years in. Building patient panel from scratch. Very receptive to Vivitrol education. Enrolled in Vivitrol REMS. Expect script volume to grow over next 6-12 months as panel grows.'),
(26, 26, 150, '2025-02-28',
 'Dr. Kim in Chicago - psychiatry. Competitive intelligence: hearing that a new LAI competitor is launching in Q3 2025. She is interested in staying current. Reviewed Aristada durability data and patient satisfaction scores. Positioned strong clinical differentiation.'),
(27, 27, 175, '2025-03-20',
 'Dr. Perez in Dallas - addiction medicine. Practice serves predominantly Hispanic patient population. Language barrier is a real issue - several patients do not speak English. Requested Spanish-language patient education materials for Vivitrol. Will follow up with Spanish materials.'),
(28, 28, 200, '2025-01-10',
 'Dr. Stewart in Houston - psychiatry. Asked about Lybalvi for patients with history of opioid use disorder. This is a key differentiator - Lybalvi can be used in patients with current or recent opioid use (with caveats) unlike standard olanzapine. Great clinical conversation.'),
(29, 29, 225, '2025-03-03',
 'Dr. Flores in Phoenix - addiction medicine. BCBS Arizona recently issued step therapy guidance requiring 30-day oral naltrexone trial before approving Vivitrol. He sees this as a major barrier since oral adherence is exactly what these patients struggle with. Will advocate with payer.'),
(30, 30, 250, '2025-02-12',
 'Dr. Mitchell in Denver - psychiatry. Asked about data comparing Aristada 1064mg monthly vs every-6-weeks dosing. Reviewed dosing flexibility benefit. She has several patients who struggle with monthly injection schedules. Every-6-week dosing is a real differentiator for her practice.');


-- ── 9. VERIFICATION ───────────────────────────────────────────────────────────
SELECT 'PRODUCTS'     AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM PRODUCTS
UNION ALL
SELECT 'TERRITORIES',  COUNT(*) FROM TERRITORIES
UNION ALL
SELECT 'SALES_REPS',   COUNT(*) FROM SALES_REPS
UNION ALL
SELECT 'HCPS',         COUNT(*) FROM HCPS
UNION ALL
SELECT 'PRESCRIPTIONS',COUNT(*) FROM PRESCRIPTIONS
UNION ALL
SELECT 'CALL_ACTIVITY',COUNT(*) FROM CALL_ACTIVITY
UNION ALL
SELECT 'MARKET_ACCESS',COUNT(*) FROM MARKET_ACCESS
UNION ALL
SELECT 'CALL_NOTES',   COUNT(*) FROM CALL_NOTES
ORDER BY TABLE_NAME;
