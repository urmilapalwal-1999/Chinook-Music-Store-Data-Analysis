# Chinook Music Store — SQL Data Analysis
**Customer Insights, Revenue Trends & Strategic Recommendations from an 11-Table Relational Database**

---

## Overview

Chinook Music is a full-service music retailer selling instruments, accessories, and digital music across 22 countries. Working as the data analyst, the objective was to mine the company's relational sales database for actionable insight — revenue patterns, top-performing genres, regional performance, customer churn, and lifetime value — and translate the findings into strategic recommendations for the business.

## Problem Statement

Analyze music record sales data to understand revenue patterns, top-selling genres, and regional performance, profile customer spending habits and churn behavior, and make data-backed recommendations for marketing and product strategy.

## Data & Methodology

**Database:** 11 interconnected tables (Customer, Invoice, Invoice Line, Track, Album, Artist, Genre, Media Type, Playlist, Playlist Track, Employee) forming a star schema around the Track and Invoice entities.

**Data cleaning**
- Audited every table for duplicate primary keys using `GROUP BY ... HAVING COUNT(*) > 1`
- Handled nulls contextually rather than blanket-deleting: missing company, state, postal code, phone, and fax fields were flagged with placeholder values instead of dropped, preserving row-level data for revenue analysis
- Standardized the `composer` field with a chained `REGEXP_REPLACE` to normalize inconsistent delimiters (`/`, `&`, `;`) into a single comma-separated format

**Analysis approach** — 25+ queries built with CTEs, window functions, multi-table joins (up to 5 tables deep), and date-diff logic:
- Revenue and customer counts broken out by country, state, and city
- Top genres and top artists by revenue within a market (USA deep-dive)
- Customer segmentation into New / Mid-Term / Long-Term cohorts, comparing average spend, order count, and average order value across each
- Churn analysis using `TIMESTAMPDIFF()` to flag customers inactive for 3+ months, broken out by country
- Customer Lifetime Value (CLV) segmentation (High / Mid / Churned) based on recency and order-count thresholds
- Genre co-purchase (market basket) analysis to find which genres are most frequently bought together
- A three-tier customer risk profile (Low / Medium / High risk) based on months since last purchase

## Key Insights

- **The USA is the largest market by far** — $1,040 in revenue from 13 customers ($80 average per customer) — but also carries a 38.5% churn rate, showing that acquisition strength hasn't translated into retention.
- **Rock dominates globally** — it's the #1 genre in every one of the 22 countries served, taking 53% of USA revenue alone; Rock, Metal, and Alternative & Punk together account for the large majority of sales.
- **Loyalty compounds revenue, not just frequency** — long-term customers spend 71% more and place 84% more orders than new customers, while their average order value barely moves — the gain comes from repeat purchases, not bigger baskets.
- **Churn is binary in small markets** — single-customer countries like Belgium, Denmark, and Chile show 100% churn, while the overall churn rate sits at 33.9%.
- **Genres are frequently cross-purchased** — Metal + Rock is the strongest pairing (268 co-purchases), pointing to clear bundling and cross-promotion opportunities.
- **CLV splits cleanly by engagement tier** — High-value customers ($87.93 avg CLV, 10+ orders, active within 3 months) significantly outperform mid-value and churned segments, validating recency and order count as segmentation criteria.

## Strategic Recommendations

1. **Double down on high-value markets** — increase marketing spend in the USA, Canada, Germany, and UK, where purchasing power and loyalty are already strongest.
2. **Localize pricing for price-sensitive markets** — introduce regional pricing and budget bundles in India, Brazil, and Argentina rather than applying a single global price point.
3. **Build a loyalty program around the 71%/84% loyalty lift** — reward long-term customers with points, exclusive content, and early access rather than only chasing new sign-ups.
4. **Lead the catalog with Rock, Metal, and Alt/Punk** — these genres carry 77% of US revenue and dominate every regional market.
5. **Target retention in high-churn countries** — deploy inactivity-triggered win-back campaigns in Belgium, Denmark, Chile, and the USA specifically, rather than a one-size-fits-all retention approach.

## Tools Used

SQL (MySQL — CTEs, window functions, multi-table joins, date functions, regex cleaning), PowerPoint (stakeholder presentation)

## Skills Demonstrated

Relational database querying · Data cleaning at scale · Cohort & churn analysis · Customer lifetime value modeling · Market basket analysis · Business storytelling from data
