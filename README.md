# 🛡️ Banking Fraud Detection & Risk Analytics: A Comprehensive Analysis

![Excel](https://img.shields.io/badge/Excel-2608-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.13.9-blue?style=for-the-badge&logo=python)
![SQL](https://img.shields.io/badge/SQL-MySQL-orange?style=for-the-badge&logo=mysql)
![Power BI](https://img.shields.io/badge/Power%20BI-2.157.1354.0-yellow?style=for-the-badge&logo=powerbi&logoColor=black)
![NumPy](https://img.shields.io/badge/NumPy-2.3.5-013243?style=for-the-badge&logo=numpy)
![Pandas](https://img.shields.io/badge/Pandas-2.3.3-150458?style=for-the-badge&logo=pandas)
![Matplotlib](https://img.shields.io/badge/Matplotlib-3.10.6-blue?style=for-the-badge&logo=matplotlib)
![Seaborn](https://img.shields.io/badge/Seaborn-0.13.2-3776AB?style=for-the-badge&logo=seaborn)
![Scipy](https://img.shields.io/badge/SciPy-1.16.3-8CAAE6?style=for-the-badge&logo=scipy)
![Status](https://img.shields.io/badge/Status-Complete-success?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)

## 📋 Executive Summary

This project provides a deep-dive exploratory data analysis (EDA) of a banking transaction dataset to identify key fraud indicators and risk factors. The primary objective is to deliver **actionable, data-driven recommendations** to strengthen fraud detection systems, mitigate financial risk, and optimize verification processes. The analysis reveals that while fraud is widespread across all channels, the **`anomaly_score` is the single most powerful predictor of fraudulent activity**, laying the groundwork for a more sophisticated, behavior-based detection strategy.

## 🎯 Business Problem

Financial institutions face a constant and evolving threat from fraudulent transactions. The challenge is not just to detect fraud but to do so efficiently without hindering legitimate customer activity. This analysis addresses the following critical business questions:

1.  **What are the most significant factors** that indicate a transaction is fraudulent?
2.  **How do fraud patterns vary** across different customer segments, payment channels, and authentication methods?
3.  **What are the specific risk profiles** of fraudulent transactions compared to legitimate ones?
4.  **How can the organization strategically allocate resources** to build a more resilient and intelligent fraud prevention system?

## 📊 Dataset Overview

The analysis is based on a synthetic banking transaction dataset provided in `banking__transactions.csv`.

- **Total Transactions:** 10,000
- **Features:** 23 columns, including transaction details, customer behavior metrics, and device/geographic risk indicators.
- **Target Variable:** `fraud_flag` (Boolean: True/False)

### Key Feature Categories

| Category                | Features                                                                                                          |
| ----------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Transaction Details** | `transaction_id`, `transaction_amount`, `transaction_time_hour`, `payment_channel`, `authentication_type`         |
| **Customer Behavior**   | `login_attempts`, `account_age_days`, `daily_transaction_count`, `session_duration_minutes`, `transfer_frequency` |
| **Risk Indicators**     | `anomaly_score`, `device_risk_score`, `failed_transactions_last_30d`, `geo_distance_km`, `suspicious_ip_flag`     |
| **Outcome Variable**    | `fraud_flag`                                                                                                      |

## 🔬 Methodology & Tools

The analysis was conducted using Python, leveraging its powerful data science ecosystem for end-to-end processing and visualization.

- **Data Manipulation & Cleaning:** `Pandas`, `NumPy`
- **Data Visualization:** `Matplotlib`, `Seaborn`
- **Statistical Analysis:** `SciPy` (T-Tests)

The project followed a structured analytical workflow:
1.  **Data Exploration & Cleaning:** Initial assessment of data shape, types, and missing values.
2.  **Exploratory Data Analysis (EDA):** Univariate, bivariate, and multivariate analysis to uncover patterns and relationships.
3.  **Statistical Hypothesis Testing:** T-tests were performed to statistically validate differences between fraudulent and non-fraudulent groups.
4.  **Insight Generation:** Synthesis of findings into clear business insights and strategic recommendations.

## 🔍 Key Findings & Visualizations

### 1. Fraud Rate & Class Imbalance

The dataset exhibits a significant class imbalance, with a **fraud rate of 12.51%**. This is substantially higher than real-world rates (often 0.1%–0.2%) but serves as a clear indicator of the dataset's synthetic nature and the problem's severity.

![Fraud Rate Distribution](https://i.imgur.com/your-image-here.png) <!-- Placeholder for your fraud distribution plot -->

### 2. Anomaly Score: The Strongest Predictor

Statistical analysis confirms that the **`anomaly_score` is the most critical feature** for distinguishing fraud. Fraudulent transactions have a significantly higher average anomaly score (0.77) compared to legitimate ones (0.29), with a p-value of ≈ 0.0000.

| Metric            | Fraud Transactions | Legitimate Transactions | P-Value |
| ----------------- | ------------------ | ----------------------- | ------- |
| **Anomaly Score** | **0.77**           | **0.29**                | **0.0000** |

### 3. Fraud Vectors: Channels, Authentication, and IPs

- **Payment Channels:** Fraud is evenly distributed across all channels (**ATM, Mobile App, Web Banking, POS Terminal**), indicating that no single channel is inherently safer than another.
- **Authentication Types:** All authentication methods are vulnerable. Interestingly, `Two-Factor Authentication` (13.08%) and `OTP` (12.28%) show only marginally different fraud rates, suggesting that other factors are more critical.
- **Suspicious IPs:** Transactions originating from a **suspicious IP flag are 13.10% likely to be fraudulent**, compared to 11.93% for normal IPs, reinforcing it as a useful, though not definitive, risk signal.

![Fraud Rate by Category](https://i.imgur.com/your-other-image-here.png) <!-- Placeholder for your categorical fraud rate plot -->

### 4. Weak Correlation of Other Features

The correlation heatmap confirms that no other numerical feature (e.g., `transaction_amount`, `device_risk_score`) has a strong linear relationship with `fraud_flag`. This highlights the complexity of fraud and the need for multi-variable, non-linear models.

## 💡 Strategic Business Recommendations

Based on the analysis, the following data-driven recommendations are proposed to enhance the organization's fraud detection framework:

1.  **🎯 Prioritize `anomaly_score` in Fraud Rules:** Implement a tiered review system where transactions with an `anomaly_score > 0.6` are automatically flagged for manual review. This will significantly improve the efficiency of fraud analyst teams.

2.  **🛡️ Enhance Verification for High-Risk Vectors:** Introduce step-up authentication (e.g., a security question or a phone call) for transactions originating from `suspicious IPs` or exhibiting high-risk behaviors, even if the primary authentication was successful.

3.  **🚫 Move Beyond Single-Factor Rules:** The analysis proves that relying solely on numerical values like `transaction_amount` or `login_attempts` is insufficient. The strategy should focus on **behavioral analytics** and anomaly detection rather than static thresholds.

4.  **🤖 Adopt a Multi-Layered Detection Strategy:** Since fraud is pervasive across all channels and authentication types, a robust defense must combine rule-based systems (e.g., flagging suspicious IPs) with machine learning models that can adapt to new fraud patterns.

5.  **📈 Address Class Imbalance for Modeling:** Before building any predictive models, the significant class imbalance (12.51% fraud) should be addressed using techniques like **SMOTE (Synthetic Minority Over-sampling Technique)** or **class weighting** to prevent model bias towards the majority class.

## 📁 Repository Structure

Banking-Fraud-Detection-And-Risk-Analytics/
│
├── 📂 data/
│ └── Banking Fraud Detection & Risk Analytics.csv # Raw dataset (10,000 rows, 14 columns)
│
├── 📂 notebooks/
│ └── Banking Fraud Detection & Risk Analytics.ipynb # Full EDA, cleaning & visualizations
│
├── 📂 pdf/
│ └── Banking Fraud Detection & Risk Analytics.pdf # Screenshots of Analysis
|
├── 📂 power bi/
│ └── Banking Fraud Detection & Risk Analytics. pbix # Executive summary report, etc.
│
├── 📂 sql/
│ └── Banking Fraud Detection & Risk Analytics.sql # Executive summary report # 25 business queries (joins, CTEs, window functions)
│
├── gitignore LICENSE
├── LICENSE
└── README.md
