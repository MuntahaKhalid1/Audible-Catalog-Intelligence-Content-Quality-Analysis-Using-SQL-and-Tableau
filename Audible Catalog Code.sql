-- =============================================
-- Audible Catalog Intelligence
-- Complete SQL Analysis File
-- Author: Muntaha Khalid
-- Data: Audible 2020 Catalog via Kaggle
-- Tool: DB Browser for SQLite
-- =============================================


-- =============================================
-- SECTION 1: DATA PROFILING
-- =============================================

-- Preview raw data
SELECT * FROM Audible_2020 LIMIT 5;

-- Total row count
SELECT COUNT(*) FROM Audible_2020;

-- Check for NULLs across all key columns
SELECT
    COUNT(*) as total,
    COUNT("Book Name") as has_name,
    COUNT("Rating") as has_rating,
    COUNT("Number of Reviews") as has_reviews,
    COUNT("Listening Time") as has_duration,
    COUNT("Ranks and Genre") as has_genre
FROM Audible_2020;

-- Understand price range before currency conversion
SELECT
    MIN(CAST("Price" AS REAL)) AS min_price,
    MAX(CAST("Price" AS REAL)) AS max_price,
    ROUND(AVG(CAST("Price" AS REAL)), 2) AS avg_price,
    COUNT(*) AS total
FROM Audible_2020;

-- Check highest priced titles to validate currency assumption
SELECT "Book Name", "Price"
FROM Audible_2020
ORDER BY CAST("Price" AS REAL) DESC
LIMIT 10;


-- =============================================
-- SECTION 2: DATA CLEANING
-- Price stored in Indian Rupees converted at 83 INR per 1 USD
-- =============================================

CREATE TABLE audible_clean AS
SELECT
    "Book Name",
    "Author",
    CAST("Rating" AS REAL)               AS rating,
    CAST("Number of Reviews" AS INTEGER)  AS reviews,
    CAST("Price" AS REAL)                AS price_inr,
    ROUND(CAST("Price" AS REAL) / 83, 2) AS price_usd,
    "Description",
    "Listening Time",
    "Ranks and Genre"
FROM Audible_2020
WHERE "Rating" IS NOT NULL;

-- Verify conversion looks correct
SELECT "Book Name", price_inr, price_usd
FROM audible_clean
LIMIT 10;


-- =============================================
-- SECTION 3: ANALYSIS QUERY 1
-- Duration vs Rating and Popularity
-- Business Question: Does audiobook length drive listener satisfaction?
-- =============================================

WITH duration_calc AS (
    SELECT
        "Book Name",
        rating,
        reviews,
        price_usd,
        CAST(
            CASE
                WHEN "Listening Time" LIKE '%hours%'
                THEN SUBSTR("Listening Time", 1,
                     INSTR("Listening Time", ' hour') - 1)
                ELSE '0'
            END
        AS INTEGER) * 60 +
        CAST(
            CASE
                WHEN "Listening Time" LIKE '%minutes%'
                THEN TRIM(SUBSTR(
                    "Listening Time",
                    INSTR("Listening Time", 'and ') + 4,
                    INSTR("Listening Time", ' minute') -
                    INSTR("Listening Time", 'and ') - 4))
                ELSE '0'
            END
        AS INTEGER) AS total_minutes
    FROM audible_clean
    WHERE "Listening Time" IS NOT NULL
),
bucketed AS (
    SELECT *,
        CASE
            WHEN total_minutes < 180 THEN '1. Short (under 3 hrs)'
            WHEN total_minutes < 360 THEN '2. Medium (3-6 hrs)'
            WHEN total_minutes < 600 THEN '3. Long (6-10 hrs)'
            ELSE                          '4. Very Long (10+ hrs)'
        END AS length_category
    FROM duration_calc
    WHERE total_minutes > 0
)
SELECT
    length_category,
    COUNT(*)                   AS total_books,
    ROUND(AVG(rating), 2)     AS avg_rating,
    ROUND(AVG(reviews), 0)    AS avg_reviews,
    ROUND(AVG(price_usd), 2)  AS avg_price_usd
FROM bucketed
GROUP BY length_category
ORDER BY length_category;


-- =============================================
-- SECTION 4: ANALYSIS QUERY 2
-- Top Authors by Quality and Popularity
-- Business Question: Which authors consistently deliver quality and who are the hidden gems?
-- Uses window functions RANK() to create quality and popularity rankings
-- =============================================

WITH author_stats AS (
    SELECT
        "Author",
        COUNT(*)                   AS total_books,
        ROUND(AVG(rating), 2)     AS avg_rating,
        ROUND(MIN(rating), 1)     AS lowest_rating,
        ROUND(MAX(rating), 1)     AS highest_rating,
        SUM(reviews)               AS total_reviews,
        ROUND(AVG(price_usd), 2)  AS avg_price_usd
    FROM audible_clean
    WHERE rating IS NOT NULL
      AND price_usd > 0
    GROUP BY "Author"
    HAVING COUNT(*) >= 2
),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY avg_rating DESC)    AS quality_rank,
        RANK() OVER (ORDER BY total_reviews DESC) AS popularity_rank
    FROM author_stats
)
SELECT
    quality_rank,
    "Author",
    total_books,
    avg_rating,
    lowest_rating,
    highest_rating,
    total_reviews,
    popularity_rank,
    avg_price_usd
FROM ranked
WHERE quality_rank <= 20
ORDER BY quality_rank;


-- =============================================
-- SECTION 5: ANALYSIS QUERY 3
-- Genre Performance Analysis
-- Business Question: Which genres have the largest and most satisfied audiences?
-- =============================================

WITH genre_extracted AS (
    SELECT
        "Book Name",
        rating,
        reviews,
        CASE
            WHEN "Ranks and Genre" LIKE '%#1 in %'
            THEN TRIM(
                SUBSTR(
                    "Ranks and Genre",
                    INSTR("Ranks and Genre", '#1 in ') + 6,
                    CASE
                        WHEN INSTR(
                            SUBSTR("Ranks and Genre",
                            INSTR("Ranks and Genre", '#1 in ') + 6), ',') > 0
                        THEN INSTR(
                            SUBSTR("Ranks and Genre",
                            INSTR("Ranks and Genre", '#1 in ') + 6), ',') - 1
                        ELSE 100
                    END
                )
            )
            ELSE 'Uncategorized'
        END AS primary_genre
    FROM audible_clean
    WHERE "Ranks and Genre" IS NOT NULL
      AND rating IS NOT NULL
)
SELECT
    primary_genre,
    COUNT(*)                AS total_books,
    ROUND(AVG(rating), 2)  AS avg_rating,
    ROUND(AVG(reviews), 0) AS avg_reviews,
    SUM(reviews)            AS total_reviews
FROM genre_extracted
WHERE primary_genre != 'Uncategorized'
  AND primary_genre NOT LIKE '%Audible Audiobooks%'
  AND LENGTH(primary_genre) > 3
GROUP BY primary_genre
ORDER BY total_books DESC
LIMIT 20;


-- =============================================
-- SECTION 6: MASTER TABLE CREATION
-- Single unified table powering all Tableau visualizations
-- One source of truth ensuring metric consistency across all dashboard views
-- =============================================

DROP TABLE IF EXISTS audible_master;

CREATE TABLE audible_master AS
WITH base AS (
    SELECT
        "Book Name"                                    AS book_name,
        "Author"                                       AS author,
        CAST("Rating" AS REAL)                        AS rating,
        CAST("Number of Reviews" AS INTEGER)           AS reviews,
        ROUND(CAST("Price" AS REAL) / 83, 2)         AS price_usd,

        -- Convert listening time text to total minutes
        CAST(
            CASE
                WHEN "Listening Time" LIKE '%hours%'
                THEN SUBSTR("Listening Time", 1,
                     INSTR("Listening Time", ' hour') - 1)
                ELSE '0'
            END
        AS INTEGER) * 60 +
        CAST(
            CASE
                WHEN "Listening Time" LIKE '%minutes%'
                THEN TRIM(SUBSTR(
                    "Listening Time",
                    INSTR("Listening Time", 'and ') + 4,
                    INSTR("Listening Time", ' minute') -
                    INSTR("Listening Time", 'and ') - 4))
                ELSE '0'
            END
        AS INTEGER)                                   AS duration_mins,

        -- Extract primary genre
        -- Skip first Audible Audiobooks overall ranking entry
        -- Take second # occurrence which is the first real genre category
        CASE
            WHEN LENGTH("Ranks and Genre") -
                 LENGTH(REPLACE("Ranks and Genre", '#', '')) >= 2
            THEN
                TRIM(SUBSTR(
                    "Ranks and Genre",
                    INSTR(SUBSTR("Ranks and Genre",
                        INSTR("Ranks and Genre", '#') + 1), '#') +
                        INSTR("Ranks and Genre", '#') + 1 +
                    INSTR(SUBSTR("Ranks and Genre",
                        INSTR(SUBSTR("Ranks and Genre",
                        INSTR("Ranks and Genre", '#') + 1), '#') +
                        INSTR("Ranks and Genre", '#') + 1), ' in ') + 2,
                    CASE
                        WHEN INSTR(SUBSTR("Ranks and Genre",
                            INSTR(SUBSTR("Ranks and Genre",
                            INSTR("Ranks and Genre", '#') + 1), '#') +
                            INSTR("Ranks and Genre", '#') + 1 +
                            INSTR(SUBSTR("Ranks and Genre",
                            INSTR(SUBSTR("Ranks and Genre",
                            INSTR("Ranks and Genre", '#') + 1), '#') +
                            INSTR("Ranks and Genre", '#') + 1), ' in ') + 2), ',') > 0
                        THEN INSTR(SUBSTR("Ranks and Genre",
                            INSTR(SUBSTR("Ranks and Genre",
                            INSTR("Ranks and Genre", '#') + 1), '#') +
                            INSTR("Ranks and Genre", '#') + 1 +
                            INSTR(SUBSTR("Ranks and Genre",
                            INSTR(SUBSTR("Ranks and Genre",
                            INSTR("Ranks and Genre", '#') + 1), '#') +
                            INSTR("Ranks and Genre", '#') + 1), ' in ') + 2), ',') - 1
                        ELSE 60
                    END
                ))
            ELSE 'General'
        END                                           AS primary_genre

    FROM Audible_2020
    WHERE CAST("Rating" AS REAL) > 0
      AND "Listening Time" IS NOT NULL
      AND CAST("Price" AS REAL) > 0
)
SELECT
    book_name,
    author,
    rating,
    reviews,
    price_usd,
    duration_mins,
    CASE
        WHEN duration_mins < 180  THEN 'Short (under 3 hrs)'
        WHEN duration_mins < 360  THEN 'Medium (3-6 hrs)'
        WHEN duration_mins < 600  THEN 'Long (6-10 hrs)'
        ELSE                           'Very Long (10+ hrs)'
    END                                               AS duration_category,
    CASE
        WHEN primary_genre LIKE '%See Top%'
          OR primary_genre LIKE '%Audible Audiobooks%'
          OR primary_genre LIKE '%Originals%'
          OR LENGTH(TRIM(primary_genre)) < 3
        THEN 'General'
        ELSE primary_genre
    END                                               AS primary_genre
FROM base
WHERE duration_mins > 0;


-- =============================================
-- SECTION 7: VALIDATION QUERIES
-- Run after master table creation to confirm data quality
-- =============================================

-- Confirm row count
SELECT COUNT(*) FROM audible_master;

-- Preview master table
SELECT * FROM audible_master LIMIT 5;

-- Check genre distribution
SELECT primary_genre, COUNT(*) as total
FROM audible_master
GROUP BY primary_genre
ORDER BY total DESC
LIMIT 15;