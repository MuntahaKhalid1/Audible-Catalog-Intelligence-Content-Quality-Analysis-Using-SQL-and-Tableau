<h1 align="left">Audible Catalog Intelligence</h1>
<h3 align="left">A Content Quality and Discovery Analysis Using SQL and Tableau</h3>

<p align="left"><em>What if the best audiobooks on Audible are ones most listeners have never found?</em></p>

## Tools Used

<p align="center">
  <img src="https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=sqlite&logoColor=white"/>
  <img src="https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white"/>
  <img src="https://img.shields.io/badge/Tableau-E97627?style=for-the-badge&logo=tableau&logoColor=white"/>
  <img src="https://img.shields.io/badge/Data-Audible%20Catalog-FF6B35?style=for-the-badge&logoColor=white"/>
  <img src="https://img.shields.io/badge/Focus-Content%20Strategy-8A2BE2?style=for-the-badge&logoColor=white"/>
</p>


## The Business Question

Audible has over 750,000 titles and millions of listeners. But having a large catalog is not the same as having a discoverable one. This project starts with one central question that any content or data team at Audible would care about deeply:

> **Are the right books reaching the right listeners, and what does the data tell us about where the gaps are?**

Using publicly available 2020 catalog data from Kaggle, this analysis examines 1,919 audiobooks across rating, review volume, listening duration, price, and genre to surface three actionable insights for content strategy, recommendation design, and catalog curation.

Note: This analysis is based on 2020 Kaggle data and represents a point-in-time snapshot of the catalog. The findings are intended as strategic directional insights rather than real-time operational metrics.


## What Was Built

A full BI workflow from raw data to interactive executive dashboard, covering every stage a Business Intelligence Engineer owns in production.

**SQL in DB Browser for SQLite**
Raw catalog data was loaded, profiled, cleaned, and transformed entirely in SQL. A single master analytical table was created to power all visualizations from one connected source, ensuring consistency across every chart on the dashboard.

**Tableau Public Dashboard**
Four connected visualizations built from the unified SQL output, covering duration analysis, author quality quadrant mapping, genre landscape, and rating distribution. Every chart filters every other chart through dashboard actions, making the dashboard genuinely interactive rather than just decorative.

**This README**
Written to function as a business brief, not just a technical log, bridging implementation details with strategic context so both technical and non-technical stakeholders can understand what was built and why it matters.


## Technical Approach

The project follows a structured BI workflow that mirrors production analytics practice.

**Data Profiling and Quality Assessment**

Before any analysis, PRAGMA and SELECT queries were run to understand column structures, data types, and anomalies. Key issues identified and resolved include listening time stored as text requiring parsing into numeric minutes, price stored in Indian Rupees requiring conversion to USD at 83 INR to 1 USD, and genre data embedded in a ranked string field requiring extraction logic to isolate the primary genre category per title.

**Master Dataset Creation**

Rather than building three separate aggregated tables that cannot talk to each other in Tableau, all transformations were consolidated into a single flat master table using CREATE TABLE AS. Each row represents one audiobook with all analytical dimensions pre-calculated including duration category, primary genre, USD price, and duration in minutes. This single source powers every chart on the dashboard and enables cross-filtering between all views.

**Key SQL Techniques Used**

Substring extraction for listening time parsing, CASE WHEN logic for duration bucketing, CAST conversion for mixed type numeric columns, NULLIF for division safety, and window functions including RANK and LAG for author quality ranking and year over year comparisons.


## The Three Findings

### Finding One: Long Form Content Drives the Highest Listener Satisfaction

Audiobooks in the 6 to 10 hour range score the highest average listener rating at 4.48, outperforming both shorter titles at 4.43 and very long titles at 4.48. Short books under 3 hours score the lowest. This pattern holds across genres and price points.

**What this means for content strategy:**
The 6 to 10 hour window appears to be the satisfaction sweet spot. Listeners feel they receive full value from the listening experience without the fatigue that can affect very long titles. Content acquisition teams and original production planning could use duration as a leading indicator of listener satisfaction before a title even launches. Commissioning or prioritizing titles in this range may be a low-cost lever for improving overall catalog quality scores.

**New strategy to consider:**
A duration quality signal could be incorporated into the recommendation engine as a soft weighting factor, steering first-time listeners in particular toward titles in this range before expanding their listening patterns.


### Finding Two: Untapped Discoverability: High Quality Authors Waiting to Be Found

The quadrant analysis of author performance reveals a striking pattern. Authors with perfect or near-perfect 5.0 star ratings across multiple titles have fewer than 30 total reviews combined. Meanwhile authors ranked further down by quality with a 4.8 average rating have accumulated thousands of reviews.

This is an untapped opportunity waiting for the right recommendation strategy to unlock it.

**What this means for recommendation design:**
The catalog contains authors whose quality is exceptional but whose audience is negligible. These Hidden Gem authors represent a low-risk, high-reward opportunity. The content already exists. The quality signal is already strong. What is missing is the audience path.

A targeted recommendation intervention, such as surfacing Hidden Gem authors to listeners who have already demonstrated high engagement with similar genres or styles, could convert invisible excellence into mainstream success without acquiring a single new title or spending on new production.

**New strategy to consider:**
A Hidden Gem editorial program similar to what Spotify does with its Fresh Finds playlist could surface algorithmically identified high-quality low-discovery titles through curated email campaigns, homepage placement, or a dedicated discovery shelf within the app. This is a measurable experiment with a clear before and after metric: review volume growth for the featured titles.


### Finding Three: Beyond Star Ratings: A Richer Signal for Content Quality

The rating distribution analysis reveals that 1,799 out of 1,919 titles in this dataset rate between 4.0 and 5.0. Only 120 titles sit below 4.0. In practical terms this means star rating alone cannot differentiate a good audiobook from an exceptional one. The scale has compressed.

**What this means for data governance and metrics design:**
Combining star rating with review volume creates a richer and more actionable quality signal that gives content teams a more complete picture of listener engagement. A 4.2 star book and a 4.8 star book appear close on a 5 point scale but may represent dramatically different listener experiences.

Review volume by contrast is not inflated. An author with 10,000 reviews at 4.6 stars represents a fundamentally different quality signal than an author with 8 reviews at 4.9 stars. Weighting recommendations and performance metrics by a combined score of rating multiplied by log of review volume would produce a more honest and actionable quality rank.

**New strategy to consider:**
Redefine the internal catalog quality score from raw star rating to a weighted engagement score that incorporates review volume, completion rate where available, and listening session depth. This would give content teams and leadership a more accurate picture of which titles are genuinely performing versus which are simply unreviewed.


## The Overall Strategic Recommendation

Audible is sitting on a significant opportunity, the quality is already there in the catalog and smarter infrastructure to surface it could meaningfully improve listener satisfaction without acquiring a single new title.

The three findings point to the same underlying opportunity: a recommendation and discovery layer that uses quality signals more intelligently would improve satisfaction metrics, unlock value from high-quality hidden titles, and give the data team better leading indicators for content performance. This is a data infrastructure problem as much as it is a product problem, and it sits directly within the remit of a Business Intelligence team that owns KPI design, metric governance, and insight delivery to leadership.


## Dashboard

View the interactive Tableau dashboard here:

[Audible Catalog Intelligence Dashboard](https://public.tableau.com/app/profile/muntaha.khalid/viz/Audible_Insights/AudibleCatalogIntelligence?publish=yes)

The dashboard includes four connected views. Clicking any genre in the treemap filters all other charts simultaneously. The author quadrant chart maps every author into one of four strategic categories: Stars, Hidden Gems, Crowd Pleasers, and Underperformers based on the intersection of quality and audience size.


## Data Source

**Audible Complete Catalog Dataset Kaggle (2020)**

Source: Amritvirsingh, Kaggle Public Dataset

The dataset contains 4,465 audiobook records with the following fields used in this analysis: Book Name, Author, Star Rating, Number of Reviews, Price in INR, Listening Time as text, and Ranks and Genre as a combined string field.

After cleaning and filtering for valid duration, price, and genre extraction, the analytical master table contains 1,919 records.


## Data Quality Notes

Listening time was stored as plain text requiring substring parsing to extract hours and minutes separately before converting to total minutes. Price was stored in Indian Rupees and converted to USD at 83 INR per 1 USD reflecting approximate 2020 exchange rates. Genre was embedded in a ranking string containing multiple categories and required extraction logic to isolate the most specific primary genre per title. Books with ambiguous genre extraction defaulted to a General category and were excluded from genre-level analysis. All data quality decisions are documented in the SQL files and were made with the goal of preserving analytical integrity rather than optimizing for cleaner-looking outputs.


## Skills Demonstrated

### Data Engineering and Analysis

🔹 Data profiling and quality assessment using PRAGMA and exploratory SELECT queries

🔹 Text parsing using SUBSTR and INSTR to extract hours and minutes from unstructured listening time fields

🔹 Data type conversion using CAST for mixed type numeric columns stored as text

🔹 Currency standardization converting Indian Rupees to USD at 83 INR per 1 USD

🔹 Conditional logic using CASE WHEN for duration bucketing and genre classification

🔹 Aggregation using GROUP BY, COUNT, SUM, and AVG across multiple dimensions

🔹 Advanced SQL using window functions including RANK and LAG for author quality ranking

🔹 Master dataset creation using CREATE TABLE AS consolidating all transformations into one unified source

### Business Intelligence and Tableau

🔹 Single source dashboard architecture enabling full cross-chart interactivity from one CSV

🔹 Four chart types built from one data source: bar chart, scatter plot, treemap, and histogram

🔹 Dashboard actions configured so clicking any genre filters all other charts simultaneously

🔹 Author quadrant framework mapping quality against audience size across four strategic categories

🔹 KPI tile design for at-a-glance executive reporting on total titles, average rating, and total reviews

🔹 Color encoding using diverging red to green palette for immediate quality signal recognition

### Strategic Thinking and Business Acumen

🔹 Three business questions framed before any query was written to keep analysis outcome-driven

🔹 Each finding paired with a concrete actionable recommendation and a new strategy to test

🔹 Insight communication written for both technical and non-technical executive audiences

🔹 README structured as a business brief rather than a technical log to maximize stakeholder clarity

🔹 Problem framing designed to anticipate leadership questions before they are asked

