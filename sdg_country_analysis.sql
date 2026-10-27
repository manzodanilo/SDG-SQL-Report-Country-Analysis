/* =====================================================================
   SDG & SQL Report - Country Analysis
   Author:   Danilo Manzo
   Database: PostgreSQL

   Datasets:
     - Global Country Information Dataset 2023
         -> table: global_country_information_2023
     - Global Data on Sustainable Energy (2000-2020)
         -> table: data_on_sustainable_energy

   Scope: SDG 3, 7, 8, 10 and 13, analysed for the 20 countries with the
   highest GDP in 2023 and, where stated, for all countries in the datasets.

   Note: table names, column names, aliases, CTE names and the text labels
   inside the CASE expressions (e.g. 'Segnali favorevoli') are kept exactly
   as used when the queries were run. Only the comments are in English.
   ===================================================================== */


/* ---------------------------------------------------------------------
   0. Analysis dataset: materialized view
   ---------------------------------------------------------------------
   Goal:     define an analysis sample made of the 20 countries with the
             highest total GDP in 2023.
   Expected: a table mv_top_20_countries_gdp with 20 rows, containing
             economic, demographic and social indicators of the countries
             most relevant for the SDG analysis.
   --------------------------------------------------------------------- */

CREATE MATERIALIZED VIEW mv_top_20_countries_gdp AS
SELECT *
FROM global_country_information_2023
WHERE gdp IS NOT NULL
ORDER BY gdp DESC
LIMIT 20;

-- Quick check of the materialized view
SELECT *
FROM mv_top_20_countries_gdp;


/* =====================================================================
   GOAL 8 - Decent work and economic growth
   ===================================================================== */

/* ---------------------------------------------------------------------
   Query 1: Labor force participation
   Goal:     retrieve the labor force participation rate of each
             country's population.
   Expected: the highest values for the countries at the top of the
             world economy.
   --------------------------------------------------------------------- */

SELECT country, population_labor_force_participation_percent AS labor_force_participation
FROM mv_top_20_countries_gdp
ORDER BY labor_force_participation DESC;


/* ---------------------------------------------------------------------
   Query 2: Unemployment rate
   Goal:     identify the unemployment rate of the countries analysed.
   Expected: the countries at the top of the world economy should have
             lower unemployment rates.
   --------------------------------------------------------------------- */

SELECT country, unemployment_rate
FROM mv_top_20_countries_gdp
ORDER BY unemployment_rate ASC;


/* ---------------------------------------------------------------------
   Query 3: Total tax rate
   Goal:     show in a bar chart the share of business profits taken by
             taxes.
   Expected: check whether countries known for a strong entrepreneurial
             spirit, such as the United States, the United Kingdom and
             Japan, actually have a low tax rate on business profits.
   --------------------------------------------------------------------- */

SELECT country, total_tax_rate_percent
FROM mv_top_20_countries_gdp
ORDER BY total_tax_rate_percent ASC;


/* ---------------------------------------------------------------------
   Query 4: Average annual GDP growth (2000-2020)
   Goal:     compute the average GDP growth per country over 2000-2020.
   Expected: the top positions should be held by countries whose economy
             was less mature than those already heavily industrialised.
   --------------------------------------------------------------------- */

SELECT gl.country, AVG(gl.gdp_growth) AS avg_gdp_growth
FROM data_on_sustainable_energy gl
JOIN mv_top_20_countries_gdp mv ON gl.country = mv.country
GROUP BY gl.country
ORDER BY AVG(gl.gdp_growth) DESC;


/* =====================================================================
   GOALS 3 and 10 - Good health and reduced inequalities
   ===================================================================== */

/* ---------------------------------------------------------------------
   Query 5: Tertiary education and economic well-being
   Goal:     highlight a possible association between gross tertiary
             education enrollment and GDP per capita.
   Expected: check whether higher tertiary enrollment goes together with
             higher GDP per capita.
   --------------------------------------------------------------------- */

SELECT gross_tertiary_education_enrollment_percent AS gross_tertiary_education_enrollment,
       gdp / population AS PIL_procapite,
       country
FROM mv_top_20_countries_gdp
ORDER BY PIL_procapite DESC, gross_tertiary_education_enrollment DESC;


/* ---------------------------------------------------------------------
   Query 6: Physicians per 1,000 inhabitants vs. life expectancy and
            maternal mortality, across all countries in the dataset
   Goal:     understand whether physician density is associated with
             better health outcomes (life expectancy, maternal
             mortality).
   Expected: check visually whether health indicators improve as
             physician density increases.
   --------------------------------------------------------------------- */

SELECT country, physicians_per_thousand, life_expectancy, maternal_mortality_ratio
FROM global_country_information_2023
WHERE physicians_per_thousand IS NOT NULL
  AND life_expectancy IS NOT NULL
  AND maternal_mortality_ratio IS NOT NULL
ORDER BY country;


/* =====================================================================
   GOALS 7 and 13 - Clean energy and climate action
   ===================================================================== */

/* ---------------------------------------------------------------------
   Query 7: Average GDP growth vs. percentage change in CO2 emissions
            (2000-2019)
   Goal:     extract the average annual GDP growth and compare it with
             the percentage change in emissions for the top 20
             economies by GDP over 2000-2019.
   Expected: check whether countries once classified as developing
             economies show higher average economic growth and a
             positive percentage change in CO2 emissions between 2019
             and 2000, and the opposite for advanced economies.
   --------------------------------------------------------------------- */

WITH confronto_co2 AS (
    SELECT gl.country,
           MAX(
               CASE
                   WHEN year = 2019
                   THEN gl.value_co2_emissions_kt_by_country
               END
           ) AS co2_2019,
           MAX(
               CASE
                   WHEN year = 2000
                   THEN gl.value_co2_emissions_kt_by_country
               END
           ) AS co2_2000
    FROM data_on_sustainable_energy gl
    JOIN mv_top_20_countries_gdp mv
        ON gl.country = mv.country
    WHERE gl.year IN (2019, 2000)
    GROUP BY gl.country
),
crescita_pil AS (
    SELECT gl.country,
           AVG(gl.gdp_growth) AS avg_gdp_growth_2000_2019
    FROM data_on_sustainable_energy gl
    JOIN mv_top_20_countries_gdp mv
        ON gl.country = mv.country
    WHERE gl.year BETWEEN 2000 AND 2019
        AND gl.gdp_growth IS NOT NULL
    GROUP BY gl.country
)
SELECT
    p.country,
    ROUND(p.avg_gdp_growth_2000_2019::numeric, 2) AS avg_gdp_growth_2000_2019_pct,
    ROUND((((c.co2_2019/NULLIF(c.co2_2000, 0))-1)*100),2) AS var_co2_2019_2000_pct
FROM crescita_pil p
JOIN confronto_co2 c
    ON p.country = c.country
WHERE c.co2_2000 IS NOT NULL
  AND c.co2_2019 IS NOT NULL
ORDER BY avg_gdp_growth_2000_2019_pct DESC;


/* ---------------------------------------------------------------------
   Query 8: Sustainability profiles for the 20 largest economies
   Goal:     classify the 20 largest economies into four sustainability
             profiles using three indicators: share of electricity from
             low-carbon sources in 2019, percentage change in CO2
             emissions between 2000 and 2019, and average annual GDP
             growth over the same period.
   Expected: mature economies should mostly fall under 'Segnali
             favorevoli' (Encouraging signs), while developing
             economies should fall under 'In transizione' (In
             transition) or 'Critici' (Critical).
   --------------------------------------------------------------------- */

WITH confronto_co2 AS (
    SELECT gl.country,
           MAX(
               CASE
                   WHEN year = 2019
                   THEN gl.value_co2_emissions_kt_by_country
               END
           ) AS co2_2019,
           MAX(
               CASE
                   WHEN year = 2000
                   THEN gl.value_co2_emissions_kt_by_country
               END
           ) AS co2_2000
    FROM data_on_sustainable_energy gl
    JOIN mv_top_20_countries_gdp mv
        ON gl.country = mv.country
    WHERE gl.year IN (2019, 2000)
    GROUP BY gl.country
),
crescita_pil AS (
    SELECT gl.country,
           AVG(gl.gdp_growth) AS avg_gdp_growth_2000_2019
    FROM data_on_sustainable_energy gl
    JOIN mv_top_20_countries_gdp mv
        ON gl.country = mv.country
    WHERE gl.year BETWEEN 2000 AND 2019
        AND gl.gdp_growth IS NOT NULL
    GROUP BY gl.country
),
indicatori AS (
    SELECT
        p.country,
        gl.low_carbon_electricity_percent AS low_carbon_2019,
        ROUND(
            (
                (
                    c.co2_2019 / NULLIF(c.co2_2000, 0)
                ) - 1
            ) * 100,
            2
        ) AS var_co2_2019_2000_pct,
        ROUND(
            p.avg_gdp_growth_2000_2019::numeric,
            2
        ) AS avg_gdp_growth_2000_2019_pct
    FROM crescita_pil p
    JOIN confronto_co2 c
        ON p.country = c.country
    JOIN data_on_sustainable_energy gl
        ON c.country = gl.country
       AND gl.year = 2019
    WHERE c.co2_2000 IS NOT NULL
      AND c.co2_2019 IS NOT NULL
)
SELECT
    country,
    low_carbon_2019,
    var_co2_2019_2000_pct,
    avg_gdp_growth_2000_2019_pct,
    CASE
        WHEN var_co2_2019_2000_pct >= 0
             AND avg_gdp_growth_2000_2019_pct <= 0
        THEN 'A rischio'  -- At risk
        WHEN low_carbon_2019 > 75
             AND var_co2_2019_2000_pct < 0
             AND avg_gdp_growth_2000_2019_pct > 0
        THEN 'Segnali favorevoli'  -- Encouraging signs
        WHEN avg_gdp_growth_2000_2019_pct > 0
             AND (
                 low_carbon_2019 BETWEEN 25 AND 75
                 OR (
                     low_carbon_2019 > 75
                     AND var_co2_2019_2000_pct >= 0
                 )
                 OR (
                     low_carbon_2019 < 25
                     AND var_co2_2019_2000_pct < 0
                 )
             )
        THEN 'In transizione'  -- In transition
        WHEN low_carbon_2019 < 25
             AND var_co2_2019_2000_pct >= 0
        THEN 'Critici'  -- Critical
        ELSE 'Non classificato / dati da verificare'  -- Not classified / data to be checked
    END AS profilo_sostenibilita
FROM indicatori
ORDER BY profilo_sostenibilita, country;


/* ---------------------------------------------------------------------
   Query 9: Classification of all countries in the dataset
   Goal:     extend the previous classification to every country and
             keep only the two most representative countries for each
             label.
   Expected: countries labelled 'Segnali favorevoli' (Encouraging
             signs) should be mature, developed economies; 'Critici'
             (Critical) should be developing economies; 'A rischio' (At
             risk) should be economies in recession whose environmental
             policies have not delivered the expected results.
             'In transizione' (In transition) can include a wide variety
             of countries, because the indicators were combined in
             different, non-unique ways.
   --------------------------------------------------------------------- */

WITH confronto_co2 AS (
    SELECT gl.country,
           MAX(
               CASE
                   WHEN year = 2019
                   THEN gl.value_co2_emissions_kt_by_country
               END
           ) AS co2_2019,
           MAX(
               CASE
                   WHEN year = 2000
                   THEN gl.value_co2_emissions_kt_by_country
               END
           ) AS co2_2000
    FROM data_on_sustainable_energy gl
    WHERE gl.year IN (2019, 2000)
    GROUP BY gl.country
),
crescita_pil AS (
    SELECT gl.country,
           AVG(gl.gdp_growth) AS avg_gdp_growth_2000_2019
    FROM data_on_sustainable_energy gl
    WHERE gl.year BETWEEN 2000 AND 2019
        AND gl.gdp_growth IS NOT NULL
    GROUP BY gl.country
),
indicatori AS (
    SELECT
        p.country,
        gl.low_carbon_electricity_percent AS low_carbon_2019,
        ROUND(
            (
                (
                    c.co2_2019 / NULLIF(c.co2_2000, 0)
                ) - 1
            ) * 100,
            2
        ) AS var_co2_2019_2000_pct,
        ROUND(
            p.avg_gdp_growth_2000_2019::numeric,
            2
        ) AS avg_gdp_growth_2000_2019_pct
    FROM crescita_pil p
    JOIN confronto_co2 c
        ON p.country = c.country
    JOIN data_on_sustainable_energy gl
        ON c.country = gl.country
       AND gl.year = 2019
    WHERE c.co2_2000 IS NOT NULL
      AND c.co2_2019 IS NOT NULL
),
classifica AS (
    SELECT
        country,
        low_carbon_2019,
        var_co2_2019_2000_pct,
        avg_gdp_growth_2000_2019_pct,
        CASE
            WHEN var_co2_2019_2000_pct >= 0
                 AND avg_gdp_growth_2000_2019_pct <= 0
            THEN 'A rischio'  -- At risk
            WHEN low_carbon_2019 > 75
                 AND var_co2_2019_2000_pct < 0
                 AND avg_gdp_growth_2000_2019_pct > 0
            THEN 'Segnali favorevoli'  -- Encouraging signs
            WHEN avg_gdp_growth_2000_2019_pct > 0
                 AND (
                     low_carbon_2019 BETWEEN 25 AND 75
                     OR (
                         low_carbon_2019 > 75
                         AND var_co2_2019_2000_pct >= 0
                     )
                     OR (
                         low_carbon_2019 < 25
                         AND var_co2_2019_2000_pct < 0
                     )
                 )
            THEN 'In transizione'  -- In transition
            WHEN low_carbon_2019 < 25
                 AND var_co2_2019_2000_pct >= 0
            THEN 'Critici'  -- Critical
            ELSE 'Non classificato / dati da verificare'  -- Not classified / data to be checked
        END AS profilo_sostenibilita
    FROM indicatori
),
posizione AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY profilo_sostenibilita
            ORDER BY
                CASE
                    WHEN profilo_sostenibilita = 'Critici'
                    THEN low_carbon_2019
                    WHEN profilo_sostenibilita IN (
                        'Segnali favorevoli',
                        'In transizione'
                    )
                    THEN -low_carbon_2019
                END ASC,
                CASE
                    WHEN profilo_sostenibilita IN (
                        'Critici',
                        'A rischio'
                    )
                    THEN -var_co2_2019_2000_pct
                    WHEN profilo_sostenibilita IN (
                        'Segnali favorevoli',
                        'In transizione'
                    )
                    THEN var_co2_2019_2000_pct
                END ASC,
                CASE
                    WHEN profilo_sostenibilita IN (
                        'Segnali favorevoli',
                        'In transizione'
                    )
                    THEN -avg_gdp_growth_2000_2019_pct
                    WHEN profilo_sostenibilita = 'A rischio'
                    THEN avg_gdp_growth_2000_2019_pct
                END ASC,
                country ASC
        ) AS posizione
    FROM classifica
    WHERE profilo_sostenibilita <> 'Non classificato / dati da verificare'
        AND low_carbon_2019 IS NOT NULL
        AND var_co2_2019_2000_pct IS NOT NULL
        AND avg_gdp_growth_2000_2019_pct IS NOT NULL
        AND (
            profilo_sostenibilita <> 'In transizione'
            OR (
                low_carbon_2019 >= 25
                AND low_carbon_2019 <= 75
                AND var_co2_2019_2000_pct < 0
            )
        )
)
SELECT
    country,
    low_carbon_2019,
    var_co2_2019_2000_pct,
    avg_gdp_growth_2000_2019_pct,
    profilo_sostenibilita
FROM posizione
WHERE posizione <= 2
ORDER BY profilo_sostenibilita, country;
