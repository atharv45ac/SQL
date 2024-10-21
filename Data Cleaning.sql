-- SQL Project Data Cleaning

-- DataSet that are used =
-- https://www.kaggle.com/datasets/swaptr/layoffs-2022



SELECT *
FROM layoffs;


-- first thing we want to do is create a staging table. This is the one we will work in and clean the data. We want a table with the raw data in case something happens


CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- now when we are data cleaning we usually follow a few steps
-- 1. check for duplicates and remove any
-- 2. standardize data and fix errors
-- 3. Look at null values and see what 
-- 4. remove any columns and rows that are not necessary - few ways


-- 1. Remove Duplicates 

# First let's check for duplicates


SELECT *
FROM layoffs_staging;

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) AS row_num
FROM layoffs_staging;


WITH duplicate_cte AS (
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;


-- one solution, which I think is a good one. Is to create a new column and add those row numbers in. Then delete where row numbers are over 2, then delete that column
-- so let's do it!!

SELECT *
FROM layoffs_staging;

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


SELECT *
FROM layoffs_staging2;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location,industry,total_laid_off,percentage_laid_off,'date',stage,country,funds_raised_millions) AS row_num
FROM layoffs_staging;


-- now that we have this we can delete rows were row_num is greater than 1

DELETE
FROM layoffs_staging2
WHERE row_num > 1;



-- 2. Standardize the data.


SELECT *
FROM layoffs_staging2;

-- if we look at industry it looks like we have some null and empty rows, let's take a look at these

SELECT distinct industry
FROM layoffs_staging2;

-- Remove unwanted spaces.

SELECT company, trim(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = trim(company);

SELECT *
FROM layoffs_staging2;

-- I also noticed the Crypto has multiple different variations. We need to standardize that - let's say all to Crypto

SELECT industry
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%'
GROUP BY industry;

UPDATE layoffs_staging2
SET industry = 'crypto'
WHERE industry LIKE 'crypto%';

-- everything looks good except apparently we have some "United States" and some "United States." with a period at the end. Let's standardize this.

SELECT distinct country
FROM layoffs_staging2
ORDER BY 1;

SELECT country
FROM layoffs_staging2
WHERE country LIKE 'United States%'
GROUP BY country;

UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';

-- Let's also fix the date columns:
-- change the date format text to date

SELECT date, 
str_to_date(date, '%m/%d/%Y')
FROM layoffs_staging2;

-- we can use str to date to update this field
UPDATE layoffs_staging2
SET date = str_to_date(date, '%m/%d/%Y');

-- now we can convert the data type properly
ALTER TABLE layoffs_staging2
MODIFY COLUMN date DATE;


-- 3. Find and Replace Null values or blank values.

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL AND percentage_laid_off IS NULL;

-- if we look at industry it looks like we have some null and empty rows, let's take a look at these

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL 
OR industry = '';

-- let's take a look at these

SELECT *
FROM layoffs_staging2
WHERE company ='Airbnb';

-- it looks like airbnb is a travel, but this one just isn't populated.
-- I'm sure it's the same for the others. What we can do is
-- write a query that if there is another row with the same company name, it will update it to the non-null industry values
-- makes it easy so if there were thousands we wouldn't have to manually check them all

SELECT t1.company, t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company AND
    t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- we should set the blanks to nulls since those are typically easier to work with

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry ='';

-- now we need to populate those nulls if possible

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- remove any columns and rows we need to

SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

-- Delete Useless data we can't really use

DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging2;
