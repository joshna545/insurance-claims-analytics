-- ================================================================
-- Insurance Claims Analytics — SQL Queries
-- Author  : Prajoshna Aare
-- Dataset : 10,000+ insurance records
-- Table   : insurance_data
-- Columns : PolicyNumber, CustomerID, Gender, Age, PolicyType,
--           PolicyStartDate, PolicyEndDate, PremiumAmount,
--           CoverageAmount, ClaimNumber, ClaimDate,
--           ClaimAmount, ClaimStatus
-- ================================================================


-- Q1. How many policies exist for each policy type?
-- Simple frequency count — understand product distribution.
SELECT PolicyType,
       COUNT(*) AS total_policies
FROM insurance_data
GROUP BY PolicyType
ORDER BY total_policies DESC;


-- Q2. What is the total premium collected by gender?
-- Mirrors revenue-by-gender pattern; shows demographic premium split.
SELECT Gender,
       ROUND(SUM(PremiumAmount), 2) AS total_premium
FROM insurance_data
GROUP BY Gender;


-- Q3. Which customers filed a claim that was rejected?
-- Filters for a specific status — clean and practical lookup query.
SELECT CustomerID,
       PolicyNumber,
       PolicyType,
       ClaimAmount
FROM insurance_data
WHERE ClaimStatus = 'Rejected'
ORDER BY ClaimAmount DESC;


-- Q4. Do subscribed (active) policies have higher average premiums?
-- Swap in PolicyEndDate to mimic subscription-status comparison.
SELECT
    CASE
        WHEN PolicyEndDate >= CURDATE() THEN 'Active'
        ELSE 'Expired'
    END AS policy_status,
    COUNT(*)                         AS total_policies,
    ROUND(AVG(PremiumAmount), 2)     AS avg_premium,
    ROUND(SUM(PremiumAmount), 2)     AS total_premium
FROM insurance_data
GROUP BY policy_status;


-- Q5. What is the average claim amount for each claim status?
-- Core aggregation — shows how settled vs pending vs rejected differ.
SELECT ClaimStatus,
       COUNT(*)                      AS total_claims,
       ROUND(AVG(ClaimAmount), 2)    AS avg_claim_amount,
       ROUND(SUM(ClaimAmount), 2)    AS total_claim_amount
FROM insurance_data
GROUP BY ClaimStatus
ORDER BY avg_claim_amount DESC;


-- Q6. Which policy types have the highest claim rejection rate?
-- CASE WHEN percentage — mirrors discount-rate query style.
SELECT PolicyType,
       COUNT(*)                                                          AS total_claims,
       ROUND(
           100.0 * SUM(CASE WHEN ClaimStatus = 'Rejected' THEN 1 ELSE 0 END)
           / COUNT(*), 2
       )                                                                 AS rejection_rate_pct
FROM insurance_data
GROUP BY PolicyType
ORDER BY rejection_rate_pct DESC;


-- Q7. Which customers filed a claim higher than the average claim amount?
-- Subquery pattern — mirrors the "above average purchase" query.
SELECT CustomerID,
       PolicyType,
       ClaimAmount,
       ClaimStatus
FROM insurance_data
WHERE ClaimAmount > (SELECT AVG(ClaimAmount) FROM insurance_data)
ORDER BY ClaimAmount DESC;


-- Q8. Segment customers by age group and compare their average premium.
-- CASE WHEN bucketing — one of the most common interview patterns.
SELECT
    CASE
        WHEN Age BETWEEN 18 AND 30 THEN '18–30'
        WHEN Age BETWEEN 31 AND 45 THEN '31–45'
        WHEN Age BETWEEN 46 AND 60 THEN '46–60'
        ELSE '60+'
    END                              AS age_group,
    COUNT(*)                         AS total_customers,
    ROUND(AVG(PremiumAmount), 2)     AS avg_premium,
    ROUND(AVG(ClaimAmount),   2)     AS avg_claim_amount
FROM insurance_data
GROUP BY age_group
ORDER BY age_group;


-- Q9. What are the top 3 most claimed policy types within each gender?
-- Window function (ROW_NUMBER) — mirrors top-products-per-category query.
WITH ranked_claims AS (
    SELECT Gender,
           PolicyType,
           COUNT(*) AS total_claims,
           ROW_NUMBER() OVER (
               PARTITION BY Gender
               ORDER BY COUNT(*) DESC
           ) AS claim_rank
    FROM insurance_data
    WHERE ClaimStatus = 'Settled'
    GROUP BY Gender, PolicyType
)
SELECT claim_rank,
       Gender,
       PolicyType,
       total_claims
FROM ranked_claims
WHERE claim_rank <= 3;


-- Q10. What is the revenue (premium) contribution of each age group?
-- Direct parallel to the age-group revenue query in reference file.
SELECT
    CASE
        WHEN Age BETWEEN 18 AND 30 THEN '18–30'
        WHEN Age BETWEEN 31 AND 45 THEN '31–45'
        WHEN Age BETWEEN 46 AND 60 THEN '46–60'
        ELSE '60+'
    END                              AS age_group,
    ROUND(SUM(PremiumAmount), 2)     AS total_premium_revenue
FROM insurance_data
GROUP BY age_group
ORDER BY total_premium_revenue DESC;


-- Q11. Are repeat claimants (multiple policies with settled claims)
--      also paying higher premiums? 
-- Mirrors repeat-buyer subscription query; uses HAVING for filtering.
SELECT CustomerID,
       COUNT(PolicyNumber)           AS total_policies,
       ROUND(AVG(PremiumAmount), 2)  AS avg_premium_paid,
       SUM(CASE WHEN ClaimStatus = 'Settled' THEN 1 ELSE 0 END) AS settled_claims
FROM insurance_data
GROUP BY CustomerID
HAVING settled_claims > 1
ORDER BY settled_claims DESC;


-- Q12. What is the monthly trend of claims filed?
-- Time-series aggregation — important for reporting dashboards.
SELECT DATE_FORMAT(ClaimDate, '%Y-%m')  AS claim_month,
       COUNT(*)                         AS total_claims,
       ROUND(SUM(ClaimAmount), 2)       AS total_claim_value
FROM insurance_data
WHERE ClaimDate IS NOT NULL
  AND ClaimDate <> ''
GROUP BY claim_month
ORDER BY claim_month;


-- Q13. What is the loss ratio (claims paid vs premiums collected)
--      for each policy type?
-- Key insurance KPI — shows business domain understanding.
SELECT PolicyType,
       ROUND(SUM(PremiumAmount), 2)   AS total_premium,
       ROUND(SUM(CASE WHEN ClaimStatus = 'Settled'
                      THEN ClaimAmount ELSE 0 END), 2) AS total_settled,
       ROUND(
           100.0 * SUM(CASE WHEN ClaimStatus = 'Settled'
                            THEN ClaimAmount ELSE 0 END)
           / NULLIF(SUM(PremiumAmount), 0), 2
       )                              AS loss_ratio_pct
FROM insurance_data
GROUP BY PolicyType
ORDER BY loss_ratio_pct DESC;
