-- ============================================
-- TEMEL METRİKLER VIEWS (1-4)
-- ============================================

-- VIEW 1: Toplam Satış Metrikleri
CREATE VIEW vw_total_sales_metrics AS
SELECT 
    SUM(close_value) as total_revenue,
    COUNT(DISTINCT opportunity_id) as total_deals,
    AVG(close_value) as average_deal_size,
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) as won_deals,
    COUNT(CASE WHEN is_lost = TRUE THEN 1 END) as lost_deals,
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) * 100.0 / COUNT(*) as overall_win_rate
FROM sales_pipeline
WHERE is_won = TRUE;

-- VIEW 2: Aylık Satış Trendi
CREATE VIEW vw_monthly_sales_trend AS
SELECT 
    close_year,
    close_month,
    SUM(close_value) as monthly_revenue,
    COUNT(DISTINCT opportunity_id) as deal_count,
    AVG(close_value) as avg_deal_value,
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) as won_deals,
    COUNT(CASE WHEN is_lost = TRUE THEN 1 END) as lost_deals,
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) as win_rate
FROM sales_pipeline
WHERE is_won = TRUE
GROUP BY close_year, close_month;

-- VIEW 3: Çeyreklik Performans
CREATE VIEW vw_quarterly_performance AS
SELECT 
    close_year,
    close_quarter,
    SUM(close_value) as quarterly_revenue,
    COUNT(DISTINCT opportunity_id) as deals_closed,
    AVG(close_value) as avg_deal_size,
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) as won_deals,
    COUNT(CASE WHEN is_lost = TRUE THEN 1 END) as lost_deals
FROM sales_pipeline
WHERE is_won = TRUE
GROUP BY close_year, close_quarter;

-- VIEW 4: Genel Kazanma Oranları
CREATE VIEW vw_overall_win_rates AS
SELECT 
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) * 100.0 / COUNT(*) as win_rate_percentage,
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) as won_deals,
    COUNT(CASE WHEN is_lost = TRUE THEN 1 END) as lost_deals,
    COUNT(*) as total_opportunities,
    SUM(CASE WHEN is_won = TRUE THEN close_value ELSE 0 END) as won_revenue,
    SUM(CASE WHEN is_lost = TRUE THEN close_value ELSE 0 END) as lost_revenue
FROM sales_pipeline;

-- ============================================
-- ÜRÜN ANALİZİ VIEWS (5-8)
-- ============================================

-- VIEW 5: Ürün Performansı
CREATE VIEW vw_product_performance AS
SELECT 
    p.product,
    p.series,
    COUNT(DISTINCT sp.opportunity_id) as opportunities,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as product_revenue,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as deals_won,
    AVG(p.sales_price) as avg_sales_price,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) as win_rate,
    AVG(CASE WHEN sp.is_won = TRUE THEN DATEDIFF(day, sp.engage_date, sp.close_date) END) as avg_sales_cycle_days
FROM products p
LEFT JOIN sales_pipeline sp ON p.product = sp.product
GROUP BY p.product, p.series;

-- VIEW 6: Seri Bazında Analiz
CREATE VIEW vw_series_analysis AS
SELECT 
    p.series,
    COUNT(DISTINCT p.product) as product_count,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as series_revenue,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as deals_won,
    AVG(CASE WHEN sp.is_won = TRUE THEN sp.close_value END) as avg_deal_value,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as win_rate
FROM products p
LEFT JOIN sales_pipeline sp ON p.product = sp.product
GROUP BY p.series;

-- VIEW 7: Ürüne Göre Kazanma Oranı
CREATE VIEW vw_win_rate_by_product AS
SELECT 
    p.product,
    p.series,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) as win_rate,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as revenue,
    COUNT(*) as total_opportunities,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as won_count,
    COUNT(CASE WHEN sp.is_lost = TRUE THEN 1 END) as lost_count
FROM sales_pipeline sp
JOIN products p ON sp.product = p.product
GROUP BY p.product, p.series;

-- VIEW 8: Önerilen vs Gerçekleşen Fiyat
CREATE VIEW vw_price_comparison AS
SELECT 
    p.product,
    p.series,
    p.sales_price as suggested_price,
    AVG(sp.close_value) as avg_actual_price,
    ((AVG(sp.close_value) - p.sales_price) * 100.0 / NULLIF(p.sales_price, 0)) as price_difference_pct,
    COUNT(*) as total_sales,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as total_revenue
FROM products p
LEFT JOIN sales_pipeline sp ON p.product = sp.product
WHERE sp.is_won = TRUE
GROUP BY p.product, p.series, p.sales_price;

-- ============================================
-- SATIŞ TEMSİLCİSİ PERFORMANS VIEWS (9-13)
-- ============================================

-- VIEW 9: Satış Temsilcisi Performansı
CREATE VIEW vw_sales_agent_performance AS
SELECT 
    st.sales_agent,
    st.manager,
    st.regional_office,
    COUNT(DISTINCT sp.opportunity_id) as total_opportunities,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as won_deals,
    COUNT(CASE WHEN sp.is_lost = TRUE THEN 1 END) as lost_deals,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) as win_rate,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as total_revenue,
    AVG(CASE WHEN sp.is_won = TRUE THEN sp.close_value END) as avg_deal_size,
    (SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) * 100.0 / 
        NULLIF((SELECT SUM(close_value) FROM sales_pipeline WHERE is_won = TRUE), 0)) as share_of_total_revenue
FROM sales_teams st
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
GROUP BY st.sales_agent, st.manager, st.regional_office;

-- VIEW 10: Top Performerlar
CREATE VIEW vw_top_sales_agents AS
SELECT 
    st.sales_agent,
    st.manager,
    st.regional_office,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as sales,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as won_deals,
    (SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) * 100.0 / 
        NULLIF((SELECT SUM(close_value) FROM sales_pipeline WHERE is_won = TRUE), 0)) as share_of_total_revenue,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as win_rate
FROM sales_teams st
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
GROUP BY st.sales_agent, st.manager, st.regional_office
HAVING COUNT(sp.opportunity_id) > 0
ORDER BY sales DESC;

-- VIEW 11: Düşük Performans Gösterenler
CREATE VIEW vw_bottom_sales_agents AS
SELECT 
    st.sales_agent,
    st.regional_office,
    st.manager,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as sales,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as won_deals,
    (SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) * 100.0 / 
        NULLIF((SELECT SUM(close_value) FROM sales_pipeline WHERE is_won = TRUE), 0)) as share_of_total_revenue,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as win_rate
FROM sales_teams st
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
GROUP BY st.sales_agent, st.regional_office, st.manager
HAVING COUNT(sp.opportunity_id) > 0
ORDER BY sales ASC;

-- VIEW 12: Yönetici Bazında Takım Performansı
CREATE VIEW vw_manager_team_performance AS
SELECT 
    st.manager,
    st.regional_office,
    COUNT(DISTINCT st.sales_agent) as team_size,
    COUNT(DISTINCT sp.opportunity_id) as total_opportunities,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as team_revenue,
    AVG(CASE WHEN sp.is_won = TRUE THEN sp.close_value END) as avg_deal_size,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as team_win_rate,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as won_deals
FROM sales_teams st
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
GROUP BY st.manager, st.regional_office;

-- VIEW 13: Bölgesel Ofis Performansı
CREATE VIEW vw_regional_office_performance AS
SELECT 
    st.regional_office,
    COUNT(DISTINCT st.sales_agent) as sales_agents,
    COUNT(DISTINCT st.manager) as managers,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as office_revenue,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as deals_won,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as win_rate,
    AVG(CASE WHEN sp.is_won = TRUE THEN DATEDIFF(day, sp.engage_date, sp.close_date) END) as avg_sales_cycle_days,
    (SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) * 100.0 / 
        NULLIF((SELECT SUM(close_value) FROM sales_pipeline WHERE is_won = TRUE), 0)) as share_of_total_revenue
FROM sales_teams st
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
GROUP BY st.regional_office;

-- ============================================
-- MÜŞTERİ VE PAZAR ANALİZİ VIEWS (14-18)
-- ============================================

-- VIEW 14: Hesap Bazında Satış
CREATE VIEW vw_sales_by_account AS
SELECT 
    ac.account,
    ac.sector,
    ac.year_established,
    ac.revenue as account_revenue,
    ac.employees,
    ac.office_location,
    COUNT(DISTINCT sp.opportunity_id) as opportunities,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as sales_revenue,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as deals_won,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) as win_rate,
    (2025 - ac.year_established) as company_age
FROM accounts ac
LEFT JOIN sales_pipeline sp ON ac.account = sp.account
GROUP BY ac.account, ac.sector, ac.year_established, ac.revenue, ac.employees, ac.office_location;

-- VIEW 15: Sektör Analizi
CREATE VIEW vw_sector_analysis AS
SELECT 
    ac.sector,
    COUNT(DISTINCT ac.account) as account_count,
    SUM(ac.revenue) as total_account_revenue,
    AVG(ac.employees) as avg_employees,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as sales_revenue,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as deals_won,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as win_rate,
    AVG(CASE WHEN sp.is_won = TRUE THEN DATEDIFF(day, sp.engage_date, sp.close_date) END) as avg_sales_cycle_days
FROM accounts ac
LEFT JOIN sales_pipeline sp ON ac.account = sp.account
GROUP BY ac.sector;

-- VIEW 16: Ülke Bazında Analiz
CREATE VIEW vw_country_analysis AS
SELECT 
    ac.office_location as country,
    COUNT(DISTINCT ac.account) as account_count,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as total_revenue,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as won_deals,
    AVG(CASE WHEN sp.is_won = TRUE THEN sp.close_value END) as avg_deal_size,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as win_rate
FROM accounts ac
LEFT JOIN sales_pipeline sp ON ac.account = sp.account
GROUP BY ac.office_location;

-- VIEW 17: Müşteri Yaşına Göre Analiz
CREATE VIEW vw_company_age_analysis AS
SELECT 
    CASE 
        WHEN (2025 - ac.year_established) <= 5 THEN '0-5 yıl'
        WHEN (2025 - ac.year_established) <= 10 THEN '6-10 yıl'
        WHEN (2025 - ac.year_established) <= 20 THEN '11-20 yıl'
        WHEN (2025 - ac.year_established) <= 50 THEN '21-50 yıl'
        ELSE '50+ yıl'
    END as company_age_group,
    COUNT(DISTINCT ac.account) as account_count,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as revenue,
    AVG(CASE WHEN sp.is_won = TRUE THEN sp.close_value END) as avg_deal_size,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as win_rate
FROM accounts ac
LEFT JOIN sales_pipeline sp ON ac.account = sp.account
GROUP BY 
    CASE 
        WHEN (2025 - ac.year_established) <= 5 THEN '0-5 yıl'
        WHEN (2025 - ac.year_established) <= 10 THEN '6-10 yıl'
        WHEN (2025 - ac.year_established) <= 20 THEN '11-20 yıl'
        WHEN (2025 - ac.year_established) <= 50 THEN '21-50 yıl'
        ELSE '50+ yıl'
    END;

-- VIEW 18: Müşteri Yaşam Boyu Değeri
CREATE VIEW vw_customer_lifetime_value AS
SELECT 
    ac.account,
    ac.sector,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as total_purchases,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as total_spent,
    AVG(CASE WHEN sp.is_won = TRUE THEN sp.close_value END) as avg_purchase_value,
    MAX(sp.close_date) as last_purchase_date,
    MIN(sp.engage_date) as first_contact_date,
    DATEDIFF(month, MIN(sp.engage_date), MAX(sp.close_date)) as customer_tenure_months
FROM accounts ac
JOIN sales_pipeline sp ON ac.account = sp.account
WHERE sp.is_won = TRUE
GROUP BY ac.account, ac.sector
HAVING COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) > 0;

-- ============================================
-- SATIŞ HUNISI VE PİPELINE VIEWS (19-22)
-- ============================================

-- VIEW 19: Satış Hunisi
CREATE VIEW vw_sales_funnel AS
SELECT 
    deal_stage,
    COUNT(DISTINCT opportunity_id) as opportunities,
    SUM(close_value) as pipeline_value,
    AVG(close_value) as avg_opportunity_value,
    COUNT(DISTINCT opportunity_id) * 100.0 / (SELECT COUNT(DISTINCT opportunity_id) FROM sales_pipeline) as percentage_of_total,
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) as won_count,
    COUNT(CASE WHEN is_lost = TRUE THEN 1 END) as lost_count
FROM sales_pipeline
GROUP BY deal_stage;

-- VIEW 20: Aktif Pipeline Değeri
CREATE VIEW vw_active_pipeline AS
SELECT 
    SUM(CASE WHEN is_won = FALSE AND is_lost = FALSE THEN close_value ELSE 0 END) as active_pipeline_value,
    COUNT(CASE WHEN is_won = FALSE AND is_lost = FALSE THEN 1 END) as active_opportunities,
    AVG(CASE WHEN is_won = FALSE AND is_lost = FALSE THEN close_value END) as avg_active_deal_size,
    SUM(CASE WHEN is_won = TRUE THEN close_value ELSE 0 END) as closed_won_value,
    SUM(CASE WHEN is_lost = TRUE THEN close_value ELSE 0 END) as closed_lost_value
FROM sales_pipeline;

-- VIEW 21: Aşamaya Göre Dönüşüm Oranı
CREATE VIEW vw_conversion_by_stage AS
SELECT 
    deal_stage,
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) as conversion_rate,
    COUNT(*) as opportunities_in_stage,
    AVG(close_value) as avg_value_in_stage,
    SUM(CASE WHEN is_won = TRUE THEN close_value ELSE 0 END) as won_value,
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) as won_count,
    COUNT(CASE WHEN is_lost = TRUE THEN 1 END) as lost_count
FROM sales_pipeline
GROUP BY deal_stage;

-- VIEW 22: Çeyrek Bazında Fırsat Dağılımı
CREATE VIEW vw_opportunities_by_quarter_stage AS
SELECT 
    close_year,
    close_quarter,
    deal_stage,
    COUNT(DISTINCT opportunity_id) as opportunity_count,
    SUM(close_value) as pipeline_value,
    AVG(close_value) as avg_deal_value
FROM sales_pipeline
GROUP BY close_year, close_quarter, deal_stage;

-- ============================================
-- ZAMAN BAZLI ANALİZ VIEWS (23-27)
-- ============================================

-- VIEW 23: Satış Döngüsü Süresi (Ürün Bazında)
CREATE VIEW vw_sales_cycle_by_product AS
SELECT 
    p.product,
    p.series,
    AVG(DATEDIFF(day, sp.engage_date, sp.close_date)) as avg_days_to_close,
    MIN(DATEDIFF(day, sp.engage_date, sp.close_date)) as min_days_to_close,
    MAX(DATEDIFF(day, sp.engage_date, sp.close_date)) as max_days_to_close,
    COUNT(*) as deal_count
FROM sales_pipeline sp
JOIN products p ON sp.product = p.product
WHERE sp.is_won = TRUE AND sp.engage_date IS NOT NULL AND sp.close_date IS NOT NULL
GROUP BY p.product, p.series;

-- VIEW 24: Satış Döngüsü (Sektör Bazında)
CREATE VIEW vw_sales_cycle_by_sector AS
SELECT 
    ac.sector,
    AVG(DATEDIFF(day, sp.engage_date, sp.close_date)) as avg_sales_cycle_days,
    MIN(DATEDIFF(day, sp.engage_date, sp.close_date)) as min_cycle_days,
    MAX(DATEDIFF(day, sp.engage_date, sp.close_date)) as max_cycle_days,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as won_deals
FROM accounts ac
JOIN sales_pipeline sp ON ac.account = sp.account
WHERE sp.is_won = TRUE AND sp.engage_date IS NOT NULL AND sp.close_date IS NOT NULL
GROUP BY ac.sector;

-- VIEW 25: Satış Döngüsü (Bölge Bazında)
CREATE VIEW vw_sales_cycle_by_office AS
SELECT 
    st.regional_office,
    AVG(DATEDIFF(day, sp.engage_date, sp.close_date)) as avg_sales_cycle_days,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as won_deals,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as total_revenue,
    MIN(DATEDIFF(day, sp.engage_date, sp.close_date)) as fastest_deal,
    MAX(DATEDIFF(day, sp.engage_date, sp.close_date)) as slowest_deal
FROM sales_teams st
JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
WHERE sp.is_won = TRUE AND sp.engage_date IS NOT NULL AND sp.close_date IS NOT NULL
GROUP BY st.regional_office;

-- VIEW 26: Yıllık Büyüme Analizi
CREATE VIEW vw_year_over_year_growth AS
WITH yearly_sales AS (
    SELECT 
        close_year,
        SUM(close_value) as yearly_revenue,
        COUNT(DISTINCT opportunity_id) as deals_count,
        AVG(close_value) as avg_deal_size
    FROM sales_pipeline
    WHERE is_won = TRUE
    GROUP BY close_year
)
SELECT 
    y1.close_year as current_year,
    y1.yearly_revenue as current_revenue,
    y2.yearly_revenue as previous_revenue,
    ((y1.yearly_revenue - y2.yearly_revenue) * 100.0 / NULLIF(y2.yearly_revenue, 0)) as yoy_growth_percentage,
    y1.deals_count as current_deals,
    y2.deals_count as previous_deals,
    ((y1.deals_count - y2.deals_count) * 100.0 / NULLIF(y2.deals_count, 0)) as deals_growth_percentage
FROM yearly_sales y1
LEFT JOIN yearly_sales y2 ON y1.close_year = y2.close_year + 1;

-- VIEW 27: Çeyreklik Büyüme Analizi
CREATE VIEW vw_quarter_over_quarter_growth AS
WITH quarterly_data AS (
    SELECT 
        close_year::integer,
        close_quarter::integer,
        SUM(close_value) as quarterly_revenue,
        COUNT(CASE WHEN is_won = TRUE THEN 1 END) as won_deals,
        AVG(close_value) as avg_deal_size
    FROM sales_pipeline
    WHERE is_won = TRUE
    GROUP BY close_year::integer, close_quarter::integer
)
SELECT 
    q1.close_year,
    q1.close_quarter,
    q1.quarterly_revenue as current_quarter_revenue,
    q2.quarterly_revenue as previous_quarter_revenue,
    ((q1.quarterly_revenue - q2.quarterly_revenue) * 100.0 / NULLIF(q2.quarterly_revenue, 0)) as qoq_growth_pct,
    q1.won_deals as current_deals,
    q2.won_deals as previous_deals,
    ((q1.won_deals - q2.won_deals) * 100.0 / NULLIF(q2.won_deals, 0)) as deals_growth_pct
FROM quarterly_data q1
LEFT JOIN quarterly_data q2 ON 
    (q1.close_year = q2.close_year AND q1.close_quarter = q2.close_quarter + 1)
    OR (q1.close_year = q2.close_year + 1 AND q1.close_quarter = 1 AND q2.close_quarter = 4);

-- ============================================
-- GELİŞMİŞ PERFORMANS ANALİZ VIEWS (28-30)
-- ============================================

-- VIEW 28: Satış Üretkenliği
CREATE VIEW vw_sales_productivity AS
SELECT 
    st.sales_agent,
    st.regional_office,
    st.manager,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as deals_won,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as total_revenue,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) / 
        NULLIF(COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END), 0) as revenue_per_deal,
    COUNT(DISTINCT sp.opportunity_id) as total_opportunities,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as win_rate,
    AVG(CASE WHEN sp.is_won = TRUE THEN DATEDIFF(day, sp.engage_date, sp.close_date) END) as avg_sales_cycle
FROM sales_teams st
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
GROUP BY st.sales_agent, st.regional_office, st.manager
HAVING COUNT(sp.opportunity_id) > 0;

-- VIEW 29: Performans Kategorileri
CREATE VIEW vw_performance_categories AS
WITH agent_stats AS (
    SELECT 
        st.sales_agent,
        st.regional_office,
        SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as revenue,
        COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as deals_won,
        COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as win_rate
    FROM sales_teams st
    LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
    GROUP BY st.sales_agent, st.regional_office
),
avg_stats AS (
    SELECT 
        AVG(revenue) as avg_revenue,
        AVG(deals_won) as avg_deals,
        AVG(win_rate) as avg_win_rate
    FROM agent_stats
)
SELECT 
    a.sales_agent,
    a.regional_office,
    a.revenue,
    a.deals_won,
    a.win_rate,
    av.avg_revenue,
    av.avg_deals,
    av.avg_win_rate,
    ((a.revenue - av.avg_revenue) * 100.0 / NULLIF(av.avg_revenue, 0)) as revenue_vs_avg_pct,
    CASE 
        WHEN a.revenue > av.avg_revenue * 1.5 THEN 'Top Performer'
        WHEN a.revenue > av.avg_revenue THEN 'Above Average'
        WHEN a.revenue > av.avg_revenue * 0.5 THEN 'Average'
        ELSE 'Below Average'
    END as performance_category
FROM agent_stats a, avg_stats av;

-- VIEW 30: En İyi Performans Segmentleri
CREATE VIEW vw_best_segments AS
SELECT 
    'Product' as segment_type,
    p.product as segment_name,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as revenue,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) as win_rate,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as deals_won
FROM products p
LEFT JOIN sales_pipeline sp ON p.product = sp.product
GROUP BY p.product
UNION ALL
SELECT 
    'Sector' as segment_type,
    ac.sector as segment_name,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as revenue,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as win_rate,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as deals_won
FROM accounts ac
LEFT JOIN sales_pipeline sp ON ac.account = sp.account
GROUP BY ac.sector;

-- ============================================
-- ÖZETLEYİCİ VE DASHBOARD VIEWS (31-33)
-- ============================================

-- VIEW 31: Executive Summary Dashboard
CREATE VIEW vw_executive_summary AS
SELECT 
    (SELECT SUM(close_value) FROM sales_pipeline WHERE is_won = TRUE) as total_revenue,
    (SELECT COUNT(DISTINCT opportunity_id) FROM sales_pipeline) as total_opportunities,
    (SELECT COUNT(DISTINCT opportunity_id) FROM sales_pipeline WHERE is_won = TRUE) as total_won_deals,
    (SELECT COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM sales_pipeline), 0) 
     FROM sales_pipeline WHERE is_won = TRUE) as overall_success_rate,
    (SELECT SUM(close_value) FROM sales_pipeline WHERE is_won = FALSE AND is_lost = FALSE) as active_pipeline_value,
    (SELECT COUNT(*) FROM sales_pipeline WHERE is_won = FALSE AND is_lost = FALSE) as active_opportunities,
    (SELECT AVG(close_value) FROM sales_pipeline WHERE is_won = TRUE) as avg_deal_size,
    (SELECT AVG(DATEDIFF(day, engage_date, close_date)) 
     FROM sales_pipeline WHERE is_won = TRUE AND engage_date IS NOT NULL) as avg_sales_cycle_days,
    (SELECT SUM(close_value) FROM sales_pipeline 
     WHERE is_won = TRUE AND close_year = YEAR(GETDATE()) 
     AND close_quarter = DATEPART(QUARTER, GETDATE())) as current_quarter_revenue,
    (SELECT SUM(close_value) FROM sales_pipeline 
     WHERE is_won = TRUE AND close_year = YEAR(DATEADD(QUARTER, -1, GETDATE())) 
     AND close_quarter = DATEPART(QUARTER, DATEADD(QUARTER, -1, GETDATE()))) as previous_quarter_revenue;

-- VIEW 32: KPI Özet Tablosu
CREATE VIEW vw_kpi_summary AS
SELECT 
    'Total Revenue' as kpi_name,
    'Financial' as category,
    SUM(close_value) as value,
    'USD' as unit,
    NULL as target,
    NULL as vs_target_pct
FROM sales_pipeline WHERE is_won = TRUE
UNION ALL
SELECT 
    'Win Rate',
    'Performance',
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0),
    '%',
    65.0,
    (COUNT(CASE WHEN is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0)) - 65.0
FROM sales_pipeline
UNION ALL
SELECT 
    'Average Deal Size',
    'Financial',
    AVG(close_value),
    'USD',
    NULL,
    NULL
FROM sales_pipeline WHERE is_won = TRUE
UNION ALL
SELECT 
    'Sales Cycle Days',
    'Efficiency',
    AVG(DATEDIFF(day, engage_date, close_date)),
    'Days',
    45.0,
    45.0 - AVG(DATEDIFF(day, engage_date, close_date))
FROM sales_pipeline WHERE is_won = TRUE AND engage_date IS NOT NULL
UNION ALL
SELECT 
    'Active Pipeline Value',
    'Pipeline',
    SUM(close_value),
    'USD',
    NULL,
    NULL
FROM sales_pipeline WHERE is_won = FALSE AND is_lost = FALSE;

-- VIEW 33: Master KPI Dashboard
CREATE VIEW vw_master_kpi_dashboard AS
SELECT 
    (SELECT SUM(close_value) FROM sales_pipeline WHERE is_won = TRUE) as total_revenue,
    (SELECT AVG(close_value) FROM sales_pipeline WHERE is_won = TRUE) as avg_deal_size,
    (SELECT SUM(close_value) FROM sales_pipeline WHERE is_won = FALSE AND is_lost = FALSE) as pipeline_value,
    (SELECT COUNT(DISTINCT opportunity_id) FROM sales_pipeline) as total_opportunities,
    (SELECT COUNT(DISTINCT opportunity_id) FROM sales_pipeline WHERE is_won = TRUE) as won_opportunities,
    (SELECT COUNT(DISTINCT opportunity_id) FROM sales_pipeline WHERE is_lost = TRUE) as lost_opportunities,
    (SELECT COUNT(DISTINCT opportunity_id) FROM sales_pipeline WHERE is_won = FALSE AND is_lost = FALSE) as active_opportunities,
    (SELECT COUNT(*) * 100.0 / NULLIF((SELECT COUNT(*) FROM sales_pipeline), 0) 
     FROM sales_pipeline WHERE is_won = TRUE) as win_rate,
    (SELECT AVG(DATEDIFF(day, engage_date, close_date)) 
     FROM sales_pipeline WHERE is_won = TRUE AND engage_date IS NOT NULL) as avg_sales_cycle,
    (SELECT COUNT(DISTINCT sales_agent) FROM sales_teams) as total_agents,
    (SELECT COUNT(DISTINCT manager) FROM sales_teams) as total_managers,
    (SELECT COUNT(DISTINCT regional_office) FROM sales_teams) as total_offices,
    (SELECT COUNT(DISTINCT account) FROM accounts) as total_accounts,
    (SELECT COUNT(DISTINCT sector) FROM accounts) as total_sectors,
    (SELECT COUNT(DISTINCT product) FROM products) as total_products,
    (SELECT COUNT(DISTINCT series) FROM products) as total_series,
    (SELECT TOP 1 product FROM (
        SELECT p.product, SUM(sp.close_value) as rev 
        FROM products p 
        JOIN sales_pipeline sp ON p.product = sp.product 
        WHERE sp.is_won = TRUE 
        GROUP BY p.product 
        ORDER BY rev DESC
    ) t) as top_product,
    (SELECT TOP 1 sector FROM (
        SELECT ac.sector, SUM(sp.close_value) as rev 
        FROM accounts ac 
        JOIN sales_pipeline sp ON ac.account = sp.account 
        WHERE sp.is_won = TRUE 
        GROUP BY ac.sector 
        ORDER BY rev DESC
    ) t) as top_sector,
    (SELECT TOP 1 regional_office FROM (
        SELECT st.regional_office, SUM(sp.close_value) as rev 
        FROM sales_teams st 
        JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent 
        WHERE sp.is_won = TRUE 
        GROUP BY st.regional_office 
        ORDER BY rev DESC
    ) t) as top_office;

-- ============================================
-- YENİ EKLENEN KPI VIEWS (34-48)
-- ============================================

-- VIEW 34: Müşteri Segmentasyonu
CREATE VIEW vw_customer_segmentation AS
WITH customer_metrics AS (
    SELECT 
        ac.account,
        ac.sector,
        ac.revenue as account_revenue,
        COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as purchase_frequency,
        SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as total_monetary_value,
        MAX(sp.close_date) as last_purchase_date,
        DATEDIFF(day, MAX(sp.close_date), GETDATE()) as days_since_last_purchase
    FROM accounts ac
    LEFT JOIN sales_pipeline sp ON ac.account = sp.account
    GROUP BY ac.account, ac.sector, ac.revenue
)
SELECT 
    account,
    sector,
    purchase_frequency,
    total_monetary_value,
    days_since_last_purchase,
    CASE 
        WHEN days_since_last_purchase <= 90 AND purchase_frequency >= 5 AND total_monetary_value >= 100000 THEN 'VIP - Champions'
        WHEN days_since_last_purchase <= 90 AND purchase_frequency >= 3 THEN 'Loyal Customers'
        WHEN days_since_last_purchase <= 180 AND total_monetary_value >= 50000 THEN 'Potential Loyalists'
        WHEN days_since_last_purchase > 365 AND purchase_frequency >= 3 THEN 'At Risk'
        WHEN days_since_last_purchase > 365 AND purchase_frequency < 3 THEN 'Hibernating'
        WHEN purchase_frequency = 1 THEN 'New Customers'
        ELSE 'Regular Customers'
    END as customer_segment
FROM customer_metrics
WHERE purchase_frequency > 0;

-- VIEW 35: Müşteri Churn Riski
CREATE VIEW vw_customer_churn_risk AS
SELECT 
    ac.account,
    ac.sector,
    MAX(sp.close_date) as last_purchase_date,
    DATEDIFF(day, MAX(sp.close_date), GETDATE()) as days_inactive,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as total_purchases,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as lifetime_value,
    CASE 
        WHEN DATEDIFF(day, MAX(sp.close_date), GETDATE()) > 365 THEN 'High Risk'
        WHEN DATEDIFF(day, MAX(sp.close_date), GETDATE()) > 180 THEN 'Medium Risk'
        WHEN DATEDIFF(day, MAX(sp.close_date), GETDATE()) > 90 THEN 'Low Risk'
        ELSE 'Active'
    END as churn_risk_level
FROM accounts ac
LEFT JOIN sales_pipeline sp ON ac.account = sp.account
WHERE sp.is_won = TRUE
GROUP BY ac.account, ac.sector
HAVING MAX(sp.close_date) IS NOT NULL;

-- VIEW 36: Cross-Sell Fırsatları
CREATE VIEW vw_cross_sell_opportunities AS
WITH customer_products AS (
    SELECT 
        sp.account,
        COUNT(DISTINCT p.product) as unique_products_bought,
        COUNT(DISTINCT p.series) as unique_series_bought,
        STRING_AGG(DISTINCT p.series, ', ') as purchased_series,
        SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as total_spent
    FROM sales_pipeline sp
    JOIN products p ON sp.product = p.product
    WHERE sp.is_won = TRUE
    GROUP BY sp.account
)
SELECT 
    cp.account,
    cp.unique_products_bought,
    cp.unique_series_bought,
    cp.purchased_series,
    cp.total_spent,
    (SELECT COUNT(DISTINCT series) FROM products) - cp.unique_series_bought as unpurchased_series_count,
    CASE 
        WHEN cp.unique_series_bought = 1 THEN 'High Cross-Sell Potential'
        WHEN cp.unique_series_bought <= 3 THEN 'Medium Cross-Sell Potential'
        ELSE 'Low Cross-Sell Potential'
    END as cross_sell_potential,
    CASE 
        WHEN cp.total_spent < 50000 THEN 'High Up-Sell Potential'
        WHEN cp.total_spent < 100000 THEN 'Medium Up-Sell Potential'
        ELSE 'Low Up-Sell Potential'
    END as upsell_potential
FROM customer_products cp;

-- VIEW 37: Satış Tahmin Doğruluğu
CREATE VIEW vw_forecast_accuracy AS
WITH quarterly_forecast AS (
    SELECT 
        close_year,
        close_quarter,
        SUM(close_value) as forecasted_value,
        COUNT(*) as forecasted_deals
    FROM sales_pipeline
    WHERE is_won = FALSE AND is_lost = FALSE
    GROUP BY close_year, close_quarter
),
quarterly_actual AS (
    SELECT 
        close_year,
        close_quarter,
        SUM(close_value) as actual_value,
        COUNT(*) as actual_deals
    FROM sales_pipeline
    WHERE is_won = TRUE
    GROUP BY close_year, close_quarter
)
SELECT 
    f.close_year,
    f.close_quarter,
    f.forecasted_value,
    a.actual_value,
    ((a.actual_value - f.forecasted_value) * 100.0 / NULLIF(f.forecasted_value, 0)) as variance_percentage,
    f.forecasted_deals,
    a.actual_deals,
    CASE 
        WHEN ABS((a.actual_value - f.forecasted_value) * 100.0 / NULLIF(f.forecasted_value, 0)) <= 10 THEN 'Accurate'
        WHEN ABS((a.actual_value - f.forecasted_value) * 100.0 / NULLIF(f.forecasted_value, 0)) <= 20 THEN 'Moderate'
        ELSE 'Poor'
    END as forecast_accuracy_rating
FROM quarterly_forecast f
LEFT JOIN quarterly_actual a ON f.close_year = a.close_year AND f.close_quarter = a.close_quarter;

-- VIEW 38: Müşteri Kazanma Maliyeti
CREATE VIEW vw_customer_acquisition_metrics AS
SELECT 
    st.regional_office,
    st.manager,
    COUNT(DISTINCT ac.account) as new_customers_acquired,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as revenue_from_new_customers,
    COUNT(DISTINCT sp.opportunity_id) * 500 as estimated_acquisition_cost,
    (COUNT(DISTINCT sp.opportunity_id) * 500) / NULLIF(COUNT(DISTINCT ac.account), 0) as cac_per_customer,
    (SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END)) / 
        NULLIF((COUNT(DISTINCT sp.opportunity_id) * 500), 0) as revenue_to_cac_ratio
FROM sales_teams st
JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
JOIN accounts ac ON sp.account = ac.account
GROUP BY st.regional_office, st.manager;

-- VIEW 39: Müşteri Tutma Oranı
CREATE VIEW vw_customer_retention AS
WITH yearly_customers AS (
    SELECT 
        YEAR(sp.close_date) as purchase_year,
        sp.account,
        COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as purchases_in_year
    FROM sales_pipeline sp
    WHERE sp.is_won = TRUE
    GROUP BY YEAR(sp.close_date), sp.account
)
SELECT 
    y1.purchase_year as year,
    COUNT(DISTINCT y1.account) as customers_in_year,
    COUNT(DISTINCT y2.account) as retained_customers_next_year,
    (COUNT(DISTINCT y2.account) * 100.0 / NULLIF(COUNT(DISTINCT y1.account), 0)) as retention_rate_pct,
    COUNT(DISTINCT y1.account) - COUNT(DISTINCT y2.account) as churned_customers
FROM yearly_customers y1
LEFT JOIN yearly_customers y2 ON y1.account = y2.account AND y2.purchase_year = y1.purchase_year + 1
GROUP BY y1.purchase_year;

-- VIEW 40: Satış Verimliliği Oranı
CREATE VIEW vw_sales_efficiency_ratio AS
SELECT 
    st.sales_agent,
    st.regional_office,
    SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as total_revenue,
    COUNT(DISTINCT sp.opportunity_id) as total_activities,
    (SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END)) / 
        NULLIF(COUNT(DISTINCT sp.opportunity_id), 0) as revenue_per_activity,
    AVG(CASE WHEN sp.is_won = TRUE THEN DATEDIFF(day, sp.engage_date, sp.close_date) END) as avg_days_to_close,
    (SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END)) / 
        NULLIF(AVG(CASE WHEN sp.is_won = TRUE THEN DATEDIFF(day, sp.engage_date, sp.close_date) END), 0) as revenue_per_day,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(sp.opportunity_id), 0) as win_rate
FROM sales_teams st
LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
GROUP BY st.sales_agent, st.regional_office
HAVING COUNT(sp.opportunity_id) > 0;

-- VIEW 41: Satış Hızı
CREATE VIEW vw_sales_velocity AS
SELECT 
    close_year,
    close_quarter,
    COUNT(DISTINCT opportunity_id) as number_of_deals,
    AVG(close_value) as avg_deal_size,
    AVG(DATEDIFF(day, engage_date, close_date)) as avg_sales_cycle_days,
    COUNT(CASE WHEN is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0) as win_rate,
    ((COUNT(CASE WHEN is_won = TRUE THEN 1 END) * AVG(close_value) * 
        (COUNT(CASE WHEN is_won = TRUE THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0))) / 
        NULLIF(AVG(DATEDIFF(day, engage_date, close_date)), 0)) / 100 as sales_velocity_score
FROM sales_pipeline
WHERE engage_date IS NOT NULL AND close_date IS NOT NULL
GROUP BY close_year, close_quarter;

-- VIEW 42: Gelir Konsantrasyonu
CREATE VIEW vw_revenue_concentration AS
WITH customer_revenue AS (
    SELECT 
        sp.account,
        SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as customer_revenue,
        (SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) * 100.0 / 
            (SELECT SUM(close_value) FROM sales_pipeline WHERE is_won = TRUE)) as revenue_share_pct
    FROM sales_pipeline sp
    WHERE sp.is_won = TRUE
    GROUP BY sp.account
),
ranked_customers AS (
    SELECT 
        account,
        customer_revenue,
        revenue_share_pct,
        ROW_NUMBER() OVER (ORDER BY customer_revenue DESC) as revenue_rank,
        SUM(revenue_share_pct) OVER (ORDER BY customer_revenue DESC) as cumulative_revenue_pct
    FROM customer_revenue
)
SELECT 
    account,
    customer_revenue,
    revenue_share_pct,
    revenue_rank,
    cumulative_revenue_pct,
    CASE 
        WHEN cumulative_revenue_pct <= 80 THEN 'Top 80% Revenue (A Customers)'
        WHEN cumulative_revenue_pct <= 95 THEN 'Next 15% Revenue (B Customers)'
        ELSE 'Bottom 5% Revenue (C Customers)'
    END as pareto_classification
FROM ranked_customers;

-- VIEW 43: Ürün Penetrasyonu
CREATE VIEW vw_product_penetration AS
WITH total_accounts AS (
    SELECT COUNT(DISTINCT account) as total_count FROM accounts
),
product_adoption AS (
    SELECT 
        p.product,
        p.series,
        COUNT(DISTINCT sp.account) as accounts_using_product,
        SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as product_revenue
    FROM products p
    LEFT JOIN sales_pipeline sp ON p.product = sp.product
    WHERE sp.is_won = TRUE
    GROUP BY p.product, p.series
)
SELECT 
    pa.product,
    pa.series,
    pa.accounts_using_product,
    ta.total_count as total_accounts,
    (pa.accounts_using_product * 100.0 / ta.total_count) as penetration_rate_pct,
    pa.product_revenue,
    CASE 
        WHEN (pa.accounts_using_product * 100.0 / ta.total_count) >= 50 THEN 'High Penetration'
        WHEN (pa.accounts_using_product * 100.0 / ta.total_count) >= 25 THEN 'Medium Penetration'
        ELSE 'Low Penetration'
    END as penetration_level
FROM product_adoption pa
CROSS JOIN total_accounts ta;

-- VIEW 44: Satış Momentum
CREATE VIEW vw_sales_momentum AS
WITH monthly_performance AS (
    SELECT 
        close_year,
        close_month,
        SUM(close_value) as monthly_revenue,
        COUNT(CASE WHEN is_won = TRUE THEN 1 END) as deals_won,
        LAG(SUM(close_value), 1) OVER (ORDER BY close_year, close_month) as prev_month_revenue,
        LAG(COUNT(CASE WHEN is_won = TRUE THEN 1 END), 1) OVER (ORDER BY close_year, close_month) as prev_month_deals
    FROM sales_pipeline
    WHERE is_won = TRUE
    GROUP BY close_year, close_month
)
SELECT 
    close_year,
    close_month,
    monthly_revenue,
    deals_won,
    prev_month_revenue,
    ((monthly_revenue - prev_month_revenue) * 100.0 / NULLIF(prev_month_revenue, 0)) as mom_revenue_growth,
    ((deals_won - prev_month_deals) * 100.0 / NULLIF(prev_month_deals, 0)) as mom_deals_growth,
    CASE 
        WHEN ((monthly_revenue - prev_month_revenue) * 100.0 / NULLIF(prev_month_revenue, 0)) > 10 THEN 'Strong Positive'
        WHEN ((monthly_revenue - prev_month_revenue) * 100.0 / NULLIF(prev_month_revenue, 0)) > 0 THEN 'Positive'
        WHEN ((monthly_revenue - prev_month_revenue) * 100.0 / NULLIF(prev_month_revenue, 0)) > -10 THEN 'Negative'
        ELSE 'Strong Negative'
    END as momentum_trend
FROM monthly_performance
WHERE prev_month_revenue IS NOT NULL;

-- VIEW 45: Kota Başarısı
CREATE VIEW vw_quota_attainment AS
WITH quarterly_targets AS (
    SELECT 
        st.sales_agent,
        st.regional_office,
        sp.close_year,
        sp.close_quarter,
        AVG(sp.close_value) * 1.2 * COUNT(*) as quarterly_quota,
        SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as actual_revenue
    FROM sales_teams st
    JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
    GROUP BY st.sales_agent, st.regional_office, sp.close_year, sp.close_quarter
)
SELECT 
    sales_agent,
    regional_office,
    close_year,
    close_quarter,
    quarterly_quota,
    actual_revenue,
    (actual_revenue * 100.0 / NULLIF(quarterly_quota, 0)) as quota_attainment_pct,
    CASE 
        WHEN (actual_revenue * 100.0 / NULLIF(quarterly_quota, 0)) >= 100 THEN 'Quota Met'
        WHEN (actual_revenue * 100.0 / NULLIF(quarterly_quota, 0)) >= 80 THEN 'Near Quota'
        ELSE 'Below Quota'
    END as quota_status
FROM quarterly_targets;

-- VIEW 46: Win/Loss Analizi
CREATE VIEW vw_win_loss_analysis AS
SELECT 
    p.product,
    p.series,
    ac.sector,
    st.regional_office,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as wins,
    COUNT(CASE WHEN sp.is_lost = TRUE THEN 1 END) as losses,
    COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) * 100.0 / 
        NULLIF(COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) + COUNT(CASE WHEN sp.is_lost = TRUE THEN 1 END), 0) as win_rate,
    AVG(CASE WHEN sp.is_won = TRUE THEN sp.close_value END) as avg_won_deal_size,
    AVG(CASE WHEN sp.is_lost = TRUE THEN sp.close_value END) as avg_lost_deal_size,
    AVG(CASE WHEN sp.is_won = TRUE THEN DATEDIFF(day, sp.engage_date, sp.close_date) END) as avg_won_cycle_days,
    AVG(CASE WHEN sp.is_lost = TRUE THEN DATEDIFF(day, sp.engage_date, sp.close_date) END) as avg_lost_cycle_days
FROM sales_pipeline sp
JOIN products p ON sp.product = p.product
JOIN accounts ac ON sp.account = sp.account
JOIN sales_teams st ON sp.sales_agent = sp.sales_agent
WHERE sp.is_won = TRUE OR sp.is_lost = TRUE
GROUP BY p.product, p.series, ac.sector, st.regional_office;

-- VIEW 47: Gelir Kalitesi
CREATE VIEW vw_revenue_quality AS
WITH customer_metrics AS (
    SELECT 
        sp.account,
        COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as repeat_purchases,
        SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as total_revenue,
        AVG(sp.close_value) as avg_deal_size,
        MIN(sp.close_date) as first_purchase,
        MAX(sp.close_date) as last_purchase
    FROM sales_pipeline sp
    WHERE sp.is_won = TRUE
    GROUP BY sp.account
)
SELECT 
    account,
    repeat_purchases,
    total_revenue,
    avg_deal_size,
    CASE 
        WHEN repeat_purchases >= 5 THEN 'High Quality - Recurring'
        WHEN repeat_purchases >= 2 THEN 'Medium Quality - Repeat'
        ELSE 'Low Quality - One-Time'
    END as revenue_quality_category,
    DATEDIFF(month, first_purchase, last_purchase) as customer_lifetime_months,
    total_revenue / NULLIF(DATEDIFF(month, first_purchase, last_purchase), 0) as monthly_revenue_rate
FROM customer_metrics;

-- VIEW 48: Bölgesel Pazar Payı
CREATE VIEW vw_market_share_by_region AS
WITH regional_totals AS (
    SELECT 
        st.regional_office,
        SUM(CASE WHEN sp.is_won = TRUE THEN sp.close_value ELSE 0 END) as office_revenue,
        COUNT(DISTINCT ac.account) as office_customers,
        COUNT(CASE WHEN sp.is_won = TRUE THEN 1 END) as office_deals
    FROM sales_teams st
    LEFT JOIN sales_pipeline sp ON st.sales_agent = sp.sales_agent
    LEFT JOIN accounts ac ON sp.account = ac.account
    GROUP BY st.regional_office
),
total_market AS (
    SELECT 
        SUM(office_revenue) as total_revenue,
        SUM(office_customers) as total_customers,
        SUM(office_deals) as total_deals
    FROM regional_totals
)
SELECT 
    rt.regional_office,
    rt.office_revenue,
    rt.office_customers,
    rt.office_deals,
    (rt.office_revenue * 100.0 / tm.total_revenue) as revenue_market_share_pct,
    (rt.office_customers * 100.0 / tm.total_customers) as customer_market_share_pct,
    (rt.office_deals * 100.0 / tm.total_deals) as deals_market_share_pct
FROM regional_totals rt
CROSS JOIN total_market tm;

-- ============================================
-- TÜM VIEWS KATALOĞU
-- ============================================

CREATE VIEW vw_all_views_catalog AS
SELECT 'vw_total_sales_metrics' as view_name, 'Temel Metrikler' as category, 'Toplam satış metrikleri' as description
UNION ALL SELECT 'vw_monthly_sales_trend', 'Temel Metrikler', 'Aylık satış trendi'
UNION ALL SELECT 'vw_quarterly_performance', 'Temel Metrikler', 'Çeyreklik performans'
UNION ALL SELECT 'vw_overall_win_rates', 'Temel Metrikler', 'Genel kazanma oranları'
UNION ALL SELECT 'vw_product_performance', 'Ürün Analizi', 'Ürün performansı detaylı'
UNION ALL SELECT 'vw_series_analysis', 'Ürün Analizi', 'Seri bazında analiz'
UNION ALL SELECT 'vw_win_rate_by_product', 'Ürün Analizi', 'Ürüne göre kazanma oranı'
UNION ALL SELECT 'vw_price_comparison', 'Ürün Analizi', 'Önerilen vs gerçekleşen fiyat'
UNION ALL SELECT 'vw_sales_agent_performance', 'Takım Performansı', 'Satış temsilcisi performansı'
UNION ALL SELECT 'vw_top_sales_agents', 'Takım Performansı', 'En iyi performans gösterenler'
UNION ALL SELECT 'vw_bottom_sales_agents', 'Takım Performansı', 'Düşük performans gösterenler'
UNION ALL SELECT 'vw_manager_team_performance', 'Takım Performansı', 'Yönetici takım performansı'
UNION ALL SELECT 'vw_regional_office_performance', 'Takım Performansı', 'Bölgesel ofis performansı'
UNION ALL SELECT 'vw_sales_by_account', 'Müşteri Analizi', 'Hesap bazında satış'
UNION ALL SELECT 'vw_sector_analysis', 'Müşteri Analizi', 'Sektör analizi'
UNION ALL SELECT 'vw_country_analysis', 'Müşteri Analizi', 'Ülke bazında analiz'
UNION ALL SELECT 'vw_company_age_analysis', 'Müşteri Analizi', 'Müşteri yaşına göre'
UNION ALL SELECT 'vw_customer_lifetime_value', 'Müşteri Analizi', 'Müşteri yaşam boyu değeri'
UNION ALL SELECT 'vw_sales_funnel', 'Pipeline Analizi', 'Satış hunisi'
UNION ALL SELECT 'vw_active_pipeline', 'Pipeline Analizi', 'Aktif pipeline değeri'
UNION ALL SELECT 'vw_conversion_by_stage', 'Pipeline Analizi', 'Aşamaya göre dönüşüm'
UNION ALL SELECT 'vw_opportunities_by_quarter_stage', 'Pipeline Analizi', 'Çeyrek-aşama dağılımı'
UNION ALL SELECT 'vw_sales_cycle_by_product', 'Zaman Analizi', 'Ürün bazında satış döngüsü'
UNION ALL SELECT 'vw_sales_cycle_by_sector', 'Zaman Analizi', 'Sektör bazında satış döngüsü'
UNION ALL SELECT 'vw_sales_cycle_by_office', 'Zaman Analizi', 'Ofis bazında satış döngüsü'
UNION ALL SELECT 'vw_year_over_year_growth', 'Zaman Analizi', 'Yıllık büyüme analizi'
UNION ALL SELECT 'vw_quarter_over_quarter_growth', 'Zaman Analizi', 'Çeyreklik büyüme analizi'
UNION ALL SELECT 'vw_sales_productivity', 'Gelişmiş Analiz', 'Satış üretkenliği'
UNION ALL SELECT 'vw_performance_categories', 'Gelişmiş Analiz', 'Performans kategorileri'
UNION ALL SELECT 'vw_best_segments', 'Gelişmiş Analiz', 'En iyi segmentler'
UNION ALL SELECT 'vw_executive_summary', 'Dashboard', 'Yönetici özet dashboard'
UNION ALL SELECT 'vw_kpi_summary', 'Dashboard', 'KPI özet tablosu'
UNION ALL SELECT 'vw_master_kpi_dashboard', 'Dashboard', 'Master KPI dashboard'
UNION ALL SELECT 'vw_customer_segmentation', 'Müşteri Analizi', 'RFM benzeri segmentasyon'
UNION ALL SELECT 'vw_customer_churn_risk', 'Müşteri Analizi', 'Churn riski analizi'
UNION ALL SELECT 'vw_cross_sell_opportunities', 'Satış Fırsatları', 'Cross-sell ve up-sell fırsatları'
UNION ALL SELECT 'vw_forecast_accuracy', 'Tahmin & Planlama', 'Satış tahmin doğruluğu'
UNION ALL SELECT 'vw_customer_acquisition_metrics', 'Müşteri Analizi', 'Müşteri kazanma maliyeti (CAC)'
UNION ALL SELECT 'vw_customer_retention', 'Müşteri Analizi', 'Müşteri tutma oranı'
UNION ALL SELECT 'vw_sales_efficiency_ratio', 'Performans', 'Satış verimliliği oranı'
UNION ALL SELECT 'vw_sales_velocity', 'Performans', 'Satış hızı metrikleri'
UNION ALL SELECT 'vw_revenue_concentration', 'Finansal Analiz', 'Gelir konsantrasyonu (Pareto)'
UNION ALL SELECT 'vw_product_penetration', 'Ürün Analizi', 'Ürün penetrasyon oranı'
UNION ALL SELECT 'vw_sales_momentum', 'Trend Analizi', 'Satış momentum analizi'
UNION ALL SELECT 'vw_quota_attainment', 'Performans', 'Kota başarı oranı'
UNION ALL SELECT 'vw_win_loss_analysis', 'Satış Analizi', 'Detaylı kazanma/kaybetme analizi'
UNION ALL SELECT 'vw_revenue_quality', 'Finansal Analiz', 'Gelir kalitesi metrikleri'
UNION ALL SELECT 'vw_market_share_by_region', 'Pazar Analizi', 'Bölgesel pazar payı'
UNION ALL SELECT 'vw_all_views_catalog', 'Meta', 'Tüm VIEWların kataloğu';

-- ============================================
-- KULLANIM KILAVUZU
-- ============================================

/*
✅ TÜM 48 VIEW BAŞARIYLA OLUŞTURULDU!

📊 KULLANIM ÖRNEKLERİ:
-------------------

-- 1. Tüm metrikleri görmek için:
SELECT * FROM vw_master_kpi_dashboard;

-- 2. En iyi satış temsilcilerini görmek için:
SELECT * FROM vw_top_sales_agents;

-- 3. Müşteri segmentasyonunu görmek için:
SELECT * FROM vw_customer_segmentation;

-- 4. Aylık satış trendini görmek için:
SELECT * FROM vw_monthly_sales_trend ORDER BY close_year DESC, close_month DESC;

-- 5. Churn riski yüksek müşterileri görmek için:
SELECT * FROM vw_customer_churn_risk WHERE churn_risk_level = 'High Risk';

-- 6. Cross-sell fırsatlarını görmek için:
SELECT * FROM vw_cross_sell_opportunities WHERE cross_sell_potential = 'High Cross-Sell Potential';

-- 7. Tüm VIEW'ları listelemek için:
SELECT * FROM vw_all_views_catalog ORDER BY category, view_name;

🎯 POWER BI İÇİN:
--------------
1. Power BI'da "Get Data" > "SQL Server" seçin
2. Bu VIEW'lardan istediğinizi import edin
3. Her VIEW bir tablo olarak görünecektir
4. Direkt olarak görselleştirme yapabilirsiniz

📁 KATEGORİLER (48 VIEW):
-----------
• Temel Metrikler (4 VIEW)
• Ürün Analizi (5 VIEW)
• Takım Performansı (5 VIEW)
• Müşteri Analizi (8 VIEW)
• Pipeline Analizi (4 VIEW)
• Zaman Analizi (5 VIEW)
• Gelişmiş Analiz (3 VIEW)
• Dashboard (3 VIEW)
• Satış Fırsatları (1 VIEW)
• Tahmin & Planlama (1 VIEW)
• Performans (3 VIEW)
• Finansal Analiz (2 VIEW)
• Trend Analizi (1 VIEW)
• Satış Analizi (1 VIEW)
• Pazar Analizi (1 VIEW)
• Meta (1 VIEW)

⚙️ TEKNİK NOTLAR:
-------
✓ Boolean alanlar TRUE/FALSE olarak kullanılıyor
✓ CREATE OR REPLACE kaldırıldı - sıfırdan oluşturma için
✓ Tüm JOIN'ler optimize edilmiş
✓ NULLIF ile sıfıra bölme hataları önlendi
✓ Yüzde hesaplamaları * 100.0 ile (decimal hassasiyet)
*/