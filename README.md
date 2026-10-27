# SDG & SQL Report: Country Analysis

**Benchmarking the world's 20 largest economies on growth, health, inequality and climate, using PostgreSQL.**

`PostgreSQL` `CTEs` `Window Functions` `Materialized Views` `Excel` `Google Sheets` `Data Visualization`

## Overview

This project analyses the 20 countries with the highest GDP in 2023 against five UN Sustainable Development Goals (SDG 3, 7, 8, 10 and 13), using comparable quantitative indicators. Where a larger sample makes the analysis more meaningful, it is extended to every country in the datasets.

The aim is to identify countries that stand out positively in terms of economic performance, social outcomes and environmental sustainability, and countries that deserve a closer look.

## Questions answered

| SDG | Question | Indicators |
|---|---|---|
| **8** Decent work and economic growth | How do the largest economies compare on employment, taxation and growth? | Labor force participation, unemployment rate, total tax rate, average GDP growth |
| **10** Reduced inequalities | Is higher tertiary education enrollment associated with higher GDP per capita? | Gross tertiary enrollment, GDP per capita |
| **3** Good health and well-being | Is physician density associated with better health outcomes (all countries)? | Physicians per 1,000, life expectancy, maternal mortality |
| **7 and 13** Clean energy and climate action | Can economic growth coexist with falling CO₂ emissions? Which countries show encouraging signs? | Low-carbon electricity share (2019), change in CO₂ emissions (2000–2019), average GDP growth |

## Data

- **Global Country Information Dataset 2023** (table `global_country_information_2023`)
- **Global Data on Sustainable Energy, 2000–2020** (table `data_on_sustainable_energy`)

## Method

1. Built a **materialized view** (`mv_top_20_countries_gdp`) with the 20 countries with the highest GDP in 2023.
2. Wrote **nine SQL queries**, each with a stated goal and expected result, covering ranking, joins between the two datasets, year-over-year comparisons and conditional classification.
3. Used **CTEs** to compute indicators step by step, `CASE` expressions to assign sustainability profiles, and `ROW_NUMBER()` to pick the most representative countries for each profile.
4. Exported results to **Excel and Google Sheets** for charts and for the correlation between tertiary enrollment and GDP per capita.

### Sustainability profiles

Countries are labelled with rules evaluated in this order:

| Profile | Low-carbon electricity (2019) | Change in CO₂ emissions (2000–2019) | Average GDP growth (2000–2019) |
|---|---|---|---|
| At risk | any | ≥ 0% | ≤ 0% |
| Encouraging signs | > 75% | < 0% | > 0% |
| In transition | 25–75%, or > 75% with CO₂ not falling, or < 25% with CO₂ falling | see previous column | > 0% |
| Critical | < 25% | ≥ 0% | any (remaining cases) |

The labels inside the SQL code are in Italian (`A rischio`, `Segnali favorevoli`, `In transizione`, `Critici`), with an English comment next to each one.

## Key findings

- **Labor force participation:** Switzerland, China and Indonesia lead among the top 20 economies, at 68.3%, 68.0% and 67.5%.
- **Growth, 2000–2020:** China, India, Indonesia, Turkey and Saudi Arabia had the highest average GDP growth, with China well ahead (18 of the 20 countries, as Russia and South Korea are not in the energy dataset).
- **Education and income:** among the top 20 economies, gross tertiary enrollment and GDP per capita show a moderate positive correlation (r ≈ 0.60, R² = 0.364). This is an association, not proof of a causal link.
- **Health:** across all countries, higher physician density tends to go with higher life expectancy and lower maternal mortality (descriptive analysis).
- **Growth and emissions:** between 2000 and 2019, several Western economies (United States, Switzerland, Spain, United Kingdom) grew while reducing CO₂ emissions, whereas China, India, Indonesia and Saudi Arabia show the largest increases.
- **Sustainability profiles (17 of the 20 largest economies):** Switzerland (94.6% low-carbon electricity) and France (90.5%) show encouraging signs; Mexico, India, Australia, Indonesia and Saudi Arabia are classified as critical.
- **All countries:** Iceland and Sweden (encouraging signs), Belgium and Slovenia (in transition), Comoros and Kiribati (critical) are the most representative examples.

## Limitations

- The two datasets are not perfectly aligned, and coverage of the SDG indicators is partial.
- Russia and South Korea are missing from the energy dataset, and Turkey lacks some indicators for 2000–2019, so some analyses cover 17 or 18 countries.
- 2020 is excluded from the emissions comparison because of missing CO₂ data and to limit distortion from the pandemic.
- Low-carbon share refers to electricity generation only, not to transport, industry, heating, land use or deforestation.
- All findings are descriptive. A more complete dataset would be needed to verify the profiles.

## Repository contents

```
.
├── README.md
├── sdg_country_analysis.sql      # all queries, commented
└── SDG_SQL_Report.pdf            # full report with charts
```

## How to reproduce

1. Download the two datasets and load them into PostgreSQL as `global_country_information_2023` and `data_on_sustainable_energy`.
2. Run `sdg_country_analysis.sql` from top to bottom. The materialized view is created first and used by the following queries.

## Author

**Danilo Manzo**: junior Data Analyst (Excel, SQL, Python)
Email: manzodanilo1@gmail.com
LinkedIn: [linkedin.com/in/danilomanzo](https://www.linkedin.com/in/danilomanzo)
