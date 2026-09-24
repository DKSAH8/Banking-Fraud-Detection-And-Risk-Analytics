SELECT *
FROM BANK_TRANS ;


-- Q1. Which payment channels have an average transaction amount higher than the overall bank average, and what is their total fraudulent volume?

WITH global_avg AS (
    SELECT AVG(transaction_amount) AS overall_avg 
    FROM bank_trans
),
channel_summary AS (
    SELECT 
        payment_channel,
        AVG(transaction_amount) AS channel_avg,
        SUM(CASE WHEN fraud_flag = 1 THEN transaction_amount ELSE 0 END) AS total_fraud_amount,
        SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_count
    FROM bank_trans
    GROUP BY payment_channel
)
SELECT 
    c.payment_channel,
    ROUND(c.channel_avg, 2) AS channel_avg,
    ROUND(g.overall_avg, 2) AS overall_avg,
    c.total_fraud_amount,
    c.fraud_count
FROM channel_summary c
CROSS JOIN global_avg g
WHERE c.channel_avg > g.overall_avg;


-- Q2. How do fraud rates differ across customer tenure brackets based on account age?

WITH tenure_segmented AS (
    SELECT 
        transaction_id,
        fraud_flag,
        CASE 
            WHEN account_age_days < 365 THEN 'New (<1 Yr)'
            WHEN account_age_days BETWEEN 365 AND 1825 THEN 'Established (1-5 Yrs)'
            ELSE 'Tenured (>5 Yrs)'
        END AS tenure_bracket
    FROM bank_trans
)
SELECT 
    tenure_bracket,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) AS fraudulent_transactions,
    ROUND(SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct
FROM tenure_segmented
GROUP BY tenure_bracket
ORDER BY fraud_rate_pct DESC;


-- Q3. What is the risk profile of transactions sitting in the top 10% anomaly score bracket?

WITH anomaly_threshold AS (
    SELECT anomaly_score 
    FROM bank_trans
    ORDER BY anomaly_score DESC 
    LIMIT 1 OFFSET 1000 -- approximating 90th percentile for standard MySQL syntax
),
filtered_anomalies AS (
    SELECT b.*
    FROM bank_trans AS b
    WHERE b.anomaly_score >= (SELECT MIN(anomaly_score) FROM anomaly_threshold)
)
SELECT 
    authentication_type,
    COUNT(*) AS high_anomaly_count,
    ROUND(AVG(device_risk_score), 2) AS avg_device_risk,
    SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) AS confirmed_frauds
FROM filtered_anomalies
GROUP BY authentication_type
ORDER BY high_anomaly_count DESC;


-- Q4. What is the 5-transaction moving average of transaction amounts per payment channel?

SELECT 
    transaction_id,
    payment_channel,
    transaction_amount,
    ROUND(AVG(transaction_amount) OVER (
        PARTITION BY payment_channel 
        ORDER BY transaction_id 
        ROWS BETWEEN 4 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_amount
FROM bank_trans;


-- Q5. How do device risk scores rank as a percentage relative to each payment channel?

SELECT 
    transaction_id,
    payment_channel,
    device_risk_score,
    ROUND(PERCENT_RANK() OVER (PARTITION BY payment_channel ORDER BY device_risk_score), 4) AS risk_percent_rank
FROM bank_trans
ORDER BY payment_channel, device_risk_score DESC;


-- Q6. How does each transaction's session duration compare to the prior one in the same channel?

SELECT 
    transaction_id,
    payment_channel,
    session_duration_minutes AS current_session_duration,
    LAG(session_duration_minutes, 1) OVER (PARTITION BY payment_channel ORDER BY transaction_id) AS prev_session_duration,
    session_duration_minutes - LAG(session_duration_minutes, 1) OVER (PARTITION BY payment_channel ORDER BY transaction_id) AS duration_diff
FROM bank_trans;


-- Q7. Which fraudulent transactions originated from accounts with above-average monthly balances?

SELECT 
    transaction_id,
    transaction_amount,
    avg_monthly_balance,
    payment_channel
FROM bank_trans
WHERE fraud_flag = true 
  AND avg_monthly_balance > (SELECT AVG(avg_monthly_balance) FROM bank_trans)
ORDER BY avg_monthly_balance DESC;


-- Q8. Can we pull the single riskiest transaction (by device risk) for each payment channel?

SELECT
    transaction_id,
    payment_channel,
    device_risk_score,
    transaction_amount
FROM (
    SELECT
        transaction_id,
        payment_channel,
        device_risk_score,
        transaction_amount,
        MAX(device_risk_score) OVER (
            PARTITION BY payment_channel
        ) AS max_risk
    FROM bank_trans
) AS t
WHERE device_risk_score = max_risk
LIMIT 1000;



-- Q9. Which payment channels maintain an average anomaly score higher than the bank-wide baseline?

SELECT 
    payment_channel,
    ROUND(AVG(anomaly_score), 4) AS avg_channel_anomaly
FROM bank_trans
GROUP BY payment_channel
HAVING AVG(anomaly_score) > (SELECT AVG(anomaly_score) FROM bank_trans);


-- Q10. Are there concurrent transactions with suspicious IPs in the same channel and hour?

SELECT 
    t1.transaction_id AS txn_1,
    t2.transaction_id AS txn_2,
    t1.payment_channel,
    t1.transaction_time_hour
FROM bank_trans AS t1
JOIN bank_trans AS t2 
  ON t1.payment_channel = t2.payment_channel
  AND t1.transaction_time_hour = t2.transaction_time_hour
  AND t1.transaction_id < t2.transaction_id
WHERE t1.suspicious_ip_flag = 1 
  AND t2.suspicious_ip_flag = 1
LIMIT 50;


-- Q11. How do transaction volumes and fraud counts break down across custom risk score tiers?

SELECT 
    r.risk_tier,
    COUNT(b.transaction_id) AS total_transactions,
    SUM(CASE WHEN b.fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(SUM(b.transaction_amount), 2) AS total_volume
FROM bank_trans AS b
JOIN (
    SELECT 'Low' AS risk_tier, 0 AS min_score, 30 AS max_score UNION ALL
    SELECT 'Medium', 31, 70 UNION ALL
    SELECT 'High', 71, 100
) r ON b.device_risk_score BETWEEN r.min_score AND r.max_score
GROUP BY r.risk_tier
ORDER BY total_volume DESC;


-- Q12. How do Web Banking and POS Terminal risk metrics compare side-by-side?

WITH web_stats AS (
    SELECT AVG(anomaly_score) AS web_anomaly, AVG(device_risk_score) AS web_risk
    FROM bank_trans 
    WHERE payment_channel = 'Web Banking'
),
pos_stats AS (
    SELECT AVG(anomaly_score) AS pos_anomaly, AVG(device_risk_score) AS pos_risk
    FROM bank_trans 
    WHERE payment_channel = 'POS Terminal'
)
SELECT 
    ROUND(w.web_anomaly, 4) AS web_anomaly,
    ROUND(p.pos_anomaly, 4) AS pos_anomaly,
    ROUND(w.web_risk, 2) AS web_risk,
    ROUND(p.pos_risk, 2) AS pos_risk
FROM web_stats w
CROSS JOIN pos_stats p;


-- Q13. What is the standard rank of transaction amounts within each payment channel?

SELECT 
    transaction_id,
    payment_channel,
    transaction_amount,
    RANK() OVER (PARTITION BY payment_channel ORDER BY transaction_amount DESC) AS amount_rank
FROM bank_trans;


-- Q14. What is the dense rank of device risk scores grouped by authentication type?

SELECT 
    transaction_id,
    authentication_type,
    device_risk_score,
    DENSE_RANK() OVER (PARTITION BY authentication_type ORDER BY device_risk_score DESC) AS dense_risk_rank
FROM bank_trans;


-- Q15. What are the top 3 riskiest transactions per authentication type based on anomaly score?

WITH ranked_anomalies AS (
    SELECT 
        transaction_id,
        authentication_type,
        anomaly_score,
        ROW_NUMBER() OVER (PARTITION BY authentication_type ORDER BY anomaly_score DESC) AS rn
    FROM bank_trans
)
SELECT 
    transaction_id,
    authentication_type,
    anomaly_score
FROM ranked_anomalies
WHERE rn <= 3;


-- Q16. What is the running total of transaction amounts accumulated across all confirmed frauds?

SELECT 
    transaction_id,
    transaction_amount,
    SUM(transaction_amount) OVER (
        ORDER BY transaction_id 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_fraud_volume
FROM bank_trans
WHERE fraud_flag = true;


-- Q17. How do login attempts accumulate over account age, partitioned by payment channel?

SELECT 
    transaction_id,
    payment_channel,
    account_age_days,
    login_attempts,
    SUM(login_attempts) OVER (
        PARTITION BY payment_channel 
        ORDER BY account_age_days 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_login_attempts
FROM bank_trans;


-- Q18. What is the simulated Month-over-Month (MoM) growth trajectory of transaction volume?

WITH monthly_volume AS (
    SELECT 
        MOD(transaction_id, 12) + 1 AS txn_month,
        SUM(transaction_amount) AS total_amount
    FROM bank_trans
    GROUP BY MOD(transaction_id, 12) + 1
)
SELECT 
    txn_month,
    ROUND(total_amount, 2) AS current_month_amount,
    ROUND(LAG(total_amount, 1) OVER (ORDER BY txn_month), 2) AS prev_month_amount,
    ROUND((total_amount - LAG(total_amount, 1) OVER (ORDER BY txn_month)) * 100.0 / 
          LAG(total_amount, 1) OVER (ORDER BY txn_month), 2) AS mom_growth_pct
FROM monthly_volume;


-- Q19. What is the simulated Year-over-Year (YoY) difference in fraud counts?

WITH yearly_fraud AS (
    SELECT 
        MOD(transaction_id, 3) + 2024 AS txn_year,
        SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_count
    FROM bank_trans
    GROUP BY MOD(transaction_id, 3) + 2024
)
SELECT 
    txn_year,
    fraud_count,
    LAG(fraud_count, 1) OVER (ORDER BY txn_year) AS prev_year_fraud,
    fraud_count - LAG(fraud_count, 1) OVER (ORDER BY txn_year) AS yoy_fraud_diff
FROM yearly_fraud;


-- Q20. How do account age cohorts (in 1,000-day blocks) correlate with fraud rates and balances?

WITH account_cohorts AS (
    SELECT 
        FLOOR(account_age_days / 1000) * 1000 AS cohort_start_day,
        fraud_flag,
        avg_monthly_balance
    FROM bank_trans
)
SELECT 
    CONCAT(cohort_start_day, ' - ', cohort_start_day + 999, ' days') AS tenure_cohort,
    COUNT(*) AS total_accounts,
    ROUND(SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS fraud_rate_pct,
    ROUND(AVG(avg_monthly_balance), 2) AS avg_cohort_balance
FROM account_cohorts
GROUP BY cohort_start_day
ORDER BY cohort_start_day;


-- Q21. How do customer engagement metrics behave across transfer frequency quartiles?

WITH frequency_quartiles AS (
    SELECT 
        transfer_frequency,
        session_duration_minutes,
        daily_transaction_count,
        NTILE(4) OVER (ORDER BY transfer_frequency) AS freq_quartile
    FROM bank_trans
)
SELECT 
    freq_quartile,
    MIN(transfer_frequency) AS min_transfer_freq,
    MAX(transfer_frequency) AS max_transfer_freq,
    ROUND(AVG(session_duration_minutes), 2) AS avg_session_duration,
    ROUND(AVG(daily_transaction_count), 2) AS avg_daily_txns
FROM frequency_quartiles
GROUP BY freq_quartile
ORDER BY freq_quartile;


-- Q22. How do device risk and anomaly scores progress across broader account age cohorts?

SELECT 
    CASE 
        WHEN account_age_days <= 1000 THEN 'Cohort 0-1k Days'
        WHEN account_age_days <= 3000 THEN 'Cohort 1k-3k Days'
        ELSE 'Cohort 3k+ Days'
    END AS cohort_group,
    COUNT(*) AS transaction_count,
    ROUND(AVG(device_risk_score), 2) AS avg_device_risk,
    ROUND(AVG(anomaly_score), 4) AS avg_anomaly_score
FROM bank_trans
GROUP BY cohort_group
ORDER BY avg_device_risk DESC;


-- Q23. Can we flag and tier high-risk transactions meeting multi-variable threshold criteria?Can we flag and tier high-risk 
--       transactions meeting multi-variable threshold criteria?

SELECT 
    transaction_id,
    payment_channel,
    device_risk_score,
    anomaly_score,
    failed_transactions_last_30d,
    CASE 
        WHEN device_risk_score > 85 AND anomaly_score > 0.85 THEN 'Critical Risk'
        WHEN device_risk_score > 75 AND failed_transactions_last_30d > 15 THEN 'High Risk'
        ELSE 'Elevated Risk'
    END AS risk_severity_tier,
    fraud_flag
FROM bank_trans
WHERE (device_risk_score > 75 OR anomaly_score > 0.70)
  AND failed_transactions_last_30d > 10
ORDER BY anomaly_score DESC, device_risk_score DESC;


-- Q24. Which authentication and channel feature combinations exhibit the highest fraud vulnerability?

SELECT 
    authentication_type,
    card_present_flag,
    international_transaction_flag,
    COUNT(*) AS total_txns,
    SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) AS confirmed_frauds,
    ROUND(SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS vulnerability_pct
FROM bank_trans
GROUP BY authentication_type, card_present_flag, international_transaction_flag
HAVING total_txns > 50
ORDER BY vulnerability_pct DESC;


-- Q25. What is the financial exposure and fraud rate across a velocity vs. risk matrix?

WITH risk_matrix AS (
    SELECT 
        transaction_amount,
        fraud_flag,
        CASE 
            WHEN transaction_velocity_score < 33 THEN 'Low Velocity'
            WHEN transaction_velocity_score BETWEEN 33 AND 66 THEN 'Med Velocity'
            ELSE 'High Velocity'
        END AS velocity_tier,
        CASE 
            WHEN device_risk_score < 33 THEN 'Low Risk Score'
            WHEN device_risk_score BETWEEN 33 AND 66 THEN 'Med Risk Score'
            ELSE 'High Risk Score'
        END AS device_risk_tier
    FROM bank_trans
)
SELECT 
    velocity_tier,
    device_risk_tier,
    COUNT(*) AS transaction_count,
    ROUND(SUM(transaction_amount), 2) AS total_financial_exposure,
    SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(SUM(CASE WHEN fraud_flag = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cell_fraud_rate_pct
FROM risk_matrix
GROUP BY velocity_tier, device_risk_tier
ORDER BY total_financial_exposure DESC;

