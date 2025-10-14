import pandas as pd
import numpy as np
from sqlalchemy import create_engine
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

# PostgreSQL Bağlantısı
engine = create_engine("postgresql://postgres:admin@localhost:6543/Data Source")

# Tabloları Yükle
accounts = pd.read_sql("SELECT * FROM public.accounts", engine)
sales_pipeline = pd.read_sql("SELECT * FROM public.sales_pipeline", engine)
products = pd.read_sql("SELECT * FROM public.products", engine)
sales_teams = pd.read_sql("SELECT * FROM public.sales_teams", engine)

# Tarih kolonlarını datetime'a çevir
sales_pipeline['engage_date'] = pd.to_datetime(sales_pipeline['engage_date'])
sales_pipeline['close_date'] = pd.to_datetime(sales_pipeline['close_date'])
accounts['year_established'] = pd.to_numeric(accounts['year_established'], errors='coerce')

print("="*80)
print("CRM VERİ ANALİZİ SONUÇLARI")
print("="*80)

# ============================================================================
# 1. RFM ANALİZİ (Recency, Frequency, Monetary)
# ============================================================================
print("\n📊 1. RFM ANALİZİ")
print("-"*80)

# Won olan satışları filtrele
won_deals = sales_pipeline[sales_pipeline['is_won'] == 1].copy()

# Her hesap için RFM metrikleri
current_date = pd.Timestamp.now()
rfm = won_deals.groupby('account_id').agg({
    'close_date': lambda x: (current_date - x.max()).days,  # Recency
    'opportunity_id': 'count',  # Frequency
    'close_value': 'sum'  # Monetary
}).reset_index()

rfm.columns = ['account_id', 'recency', 'frequency', 'monetary']

# RFM Skorlama (1-5 arası) - Güvenli skor hesaplama
def safe_qcut(series, q, labels, reverse=False):
    try:
        if reverse:
            return pd.qcut(series, q, labels=labels, duplicates='drop')
        else:
            return pd.qcut(series.rank(method='first'), q, labels=labels, duplicates='drop')
    except:
        # Eğer qcut başarısız olursa, percentile bazlı skorlama yap
        if reverse:
            bins = [-np.inf, *np.percentile(series, [20, 40, 60, 80]), np.inf]
        else:
            bins = [-np.inf, *np.percentile(series, [20, 40, 60, 80]), np.inf]
        return pd.cut(series, bins=bins, labels=labels[:len(bins)-1], include_lowest=True)

rfm['r_score'] = safe_qcut(rfm['recency'], 5, [5,4,3,2,1], reverse=True)
rfm['f_score'] = safe_qcut(rfm['frequency'], 5, [1,2,3,4,5])
rfm['m_score'] = safe_qcut(rfm['monetary'], 5, [1,2,3,4,5])

rfm['rfm_score'] = rfm['r_score'].astype(str) + rfm['f_score'].astype(str) + rfm['m_score'].astype(str)

# Segmentasyon
def rfm_segment(row):
    score = int(row['r_score']) + int(row['f_score']) + int(row['m_score'])
    if score >= 13:
        return 'Champions'
    elif score >= 10:
        return 'Loyal Customers'
    elif score >= 7:
        return 'Potential Loyalists'
    elif score >= 5:
        return 'At Risk'
    else:
        return 'Lost'

rfm['segment'] = rfm.apply(rfm_segment, axis=1)

print(f"✅ Toplam Analiz Edilen Müşteri: {len(rfm)}")
print(f"\nSegment Dağılımı:")
print(rfm['segment'].value_counts())
print(f"\nOrtalama RFM Metrikleri:")
print(f"  • Recency (Son alışverişten itibaren gün): {rfm['recency'].mean():.0f}")
print(f"  • Frequency (Alışveriş sayısı): {rfm['frequency'].mean():.1f}")
print(f"  • Monetary (Toplam değer): ${rfm['monetary'].mean():,.2f}")

# ============================================================================
# 2. CHURN ANALİZİ (Müşteri Kaybı)
# ============================================================================
print("\n\n📊 2. CHURN ANALİZİ")
print("-"*80)

# Son 180 gün içinde alışveriş yapmayan müşteriler churn olarak kabul edilir
churn_threshold_days = 180
rfm['is_churned'] = rfm['recency'] > churn_threshold_days

churn_rate = (rfm['is_churned'].sum() / len(rfm)) * 100
active_customers = len(rfm[~rfm['is_churned']])
churned_customers = len(rfm[rfm['is_churned']])

print(f"✅ Churn Oranı: {churn_rate:.2f}%")
print(f"  • Aktif Müşteri: {active_customers}")
print(f"  • Kayıp Müşteri: {churned_customers}")
print(f"  • Churn Eşik Değeri: {churn_threshold_days} gün")

# Churn risk faktörleri
churn_analysis = rfm.groupby('is_churned').agg({
    'frequency': 'mean',
    'monetary': 'mean',
    'recency': 'mean'
})
print(f"\nChurn Risk Faktörleri:")
print(churn_analysis)

# ============================================================================
# 3. CLV (Customer Lifetime Value)
# ============================================================================
print("\n\n📊 3. CLV (Customer Lifetime Value)")
print("-"*80)

# Basitleştirilmiş CLV: Ortalama alışveriş değeri * Alışveriş sıklığı * Müşteri ömrü
avg_purchase_value = rfm['monetary'] / rfm['frequency']
purchase_frequency = rfm['frequency']
customer_lifespan_years = 3  # Varsayılan müşteri ömrü

rfm['clv'] = avg_purchase_value * purchase_frequency * customer_lifespan_years

print(f"✅ Ortalama CLV: ${rfm['clv'].mean():,.2f}")
print(f"  • En yüksek CLV: ${rfm['clv'].max():,.2f}")
print(f"  • En düşük CLV: ${rfm['clv'].min():,.2f}")
print(f"  • Medyan CLV: ${rfm['clv'].median():,.2f}")

print(f"\nCLV Segmentasyonu:")
rfm['clv_segment'] = pd.qcut(rfm['clv'], 4, labels=['Low', 'Medium', 'High', 'Very High'], duplicates='drop')
print(rfm['clv_segment'].value_counts())

# ============================================================================
# 4. ARPU (Average Revenue Per User)
# ============================================================================
print("\n\n📊 4. ARPU (Average Revenue Per User)")
print("-"*80)

total_revenue = won_deals['close_value'].sum()
total_customers = accounts['account_id'].nunique()
arpu = total_revenue / total_customers

print(f"✅ ARPU: ${arpu:,.2f}")
print(f"  • Toplam Gelir: ${total_revenue:,.2f}")
print(f"  • Toplam Müşteri: {total_customers}")

# Aylık ARPU trendi
won_deals['close_month'] = won_deals['close_date'].dt.to_period('M')
monthly_arpu = won_deals.groupby('close_month').agg({
    'close_value': 'sum',
    'account_id': 'nunique'
}).reset_index()
monthly_arpu['arpu'] = monthly_arpu['close_value'] / monthly_arpu['account_id']

print(f"\nSon 5 Ayın ARPU Trendi:")
print(monthly_arpu.tail())

# ============================================================================
# 5. COHORT ANALİZİ
# ============================================================================
print("\n\n📊 5. COHORT ANALİZİ")
print("-"*80)

# İlk alışveriş tarihine göre cohort oluştur
first_purchase = won_deals.groupby('account_id')['close_date'].min().reset_index()
first_purchase.columns = ['account_id', 'cohort_date']
first_purchase['cohort'] = first_purchase['cohort_date'].dt.to_period('M')

# Won deals ile birleştir
cohort_data = won_deals.merge(first_purchase[['account_id', 'cohort']], on='account_id')
cohort_data['order_period'] = cohort_data['close_date'].dt.to_period('M')

# Cohort'tan bu yana geçen ay sayısı
cohort_data['period_number'] = (cohort_data['order_period'] - cohort_data['cohort']).apply(lambda x: x.n)

# Cohort analizi tablosu
cohort_counts = cohort_data.groupby(['cohort', 'period_number'])['account_id'].nunique().reset_index()
cohort_pivot = cohort_counts.pivot(index='cohort', columns='period_number', values='account_id')

print(f"✅ Cohort Tablosu Oluşturuldu")
print(f"  • Toplam Cohort: {len(cohort_pivot)}")
print(f"\nİlk 5 Cohort'un İlk 6 Ayı:")
print(cohort_pivot.iloc[:5, :6])

# ============================================================================
# 6. CONVERSION RATE (Dönüşüm Oranı)
# ============================================================================
print("\n\n📊 6. CONVERSION RATE (Dönüşüm Oranı)")
print("-"*80)

total_opportunities = len(sales_pipeline)
won_opportunities = len(won_deals)
conversion_rate = (won_opportunities / total_opportunities) * 100

print(f"✅ Genel Dönüşüm Oranı: {conversion_rate:.2f}%")
print(f"  • Toplam Fırsat: {total_opportunities}")
print(f"  • Kazanılan Fırsat: {won_opportunities}")
print(f"  • Kaybedilen Fırsat: {sales_pipeline['is_lost'].sum()}")

# Deal stage'e göre dönüşüm oranı
stage_conversion = sales_pipeline.groupby('deal_stage').agg({
    'opportunity_id': 'count',
    'is_won': 'sum'
}).reset_index()
stage_conversion['conversion_rate'] = (stage_conversion['is_won'] / stage_conversion['opportunity_id']) * 100
stage_conversion = stage_conversion.sort_values('conversion_rate', ascending=False)

print(f"\nDeal Stage'e Göre Dönüşüm Oranları:")
print(stage_conversion[['deal_stage', 'conversion_rate']].to_string(index=False))

# Agent'a göre dönüşüm oranı
agent_conversion = sales_pipeline.groupby('agent_id').agg({
    'opportunity_id': 'count',
    'is_won': 'sum'
}).reset_index()
agent_conversion['conversion_rate'] = (agent_conversion['is_won'] / agent_conversion['opportunity_id']) * 100
agent_conversion = agent_conversion.sort_values('conversion_rate', ascending=False)

print(f"\nEn İyi 5 Agent Dönüşüm Oranları:")
print(agent_conversion.head()[['agent_id', 'conversion_rate']].to_string(index=False))

# ============================================================================
# 7. RETENTION RATE (Elde Tutma Oranı)
# ============================================================================
print("\n\n📊 7. RETENTION RATE (Elde Tutma Oranı)")
print("-"*80)

# Aylık retention hesaplama
retention_data = cohort_pivot.divide(cohort_pivot[0], axis=0) * 100

print(f"✅ Retention Rate (Yüzde Olarak):")
print(f"\nİlk 5 Cohort'un İlk 6 Ayı:")
print(retention_data.iloc[:5, :6].round(1))

avg_retention_month_1 = retention_data[1].mean() if 1 in retention_data.columns else 0
avg_retention_month_3 = retention_data[3].mean() if 3 in retention_data.columns else 0

print(f"\nOrtalama Retention Oranları:")
print(f"  • 1. Ay: {avg_retention_month_1:.1f}%")
print(f"  • 3. Ay: {avg_retention_month_3:.1f}%")

# ============================================================================
# 8. CORRELATION ANALİZİ (İlişki Analizi)
# ============================================================================
print("\n\n📊 8. CORRELATION ANALİZİ")
print("-"*80)

# Sayısal kolonları seç
numeric_accounts = accounts.select_dtypes(include=[np.number])
numeric_pipeline = sales_pipeline.select_dtypes(include=[np.number])

# Account verileri ile satış değeri korelasyonu
account_sales = won_deals.groupby('account_id')['close_value'].sum().reset_index()
account_merged = accounts.merge(account_sales, on='account_id', how='inner')

correlation_features = ['employees', 'revenue', 'year_established', 'close_value']
available_features = [f for f in correlation_features if f in account_merged.columns]

if len(available_features) > 1:
    corr_matrix = account_merged[available_features].corr()
    
    print(f"✅ Korelasyon Matrisi:")
    print(corr_matrix.round(3))
    
    print(f"\nÖnemli Korelasyonlar (close_value ile):")
    if 'close_value' in corr_matrix:
        close_value_corr = corr_matrix['close_value'].drop('close_value').sort_values(ascending=False)
        print(close_value_corr)

# ============================================================================
# 9. REGRESSION ANALİZİ (Revenue Tahmini)
# ============================================================================
print("\n\n📊 9. REGRESSION ANALİZİ")
print("-"*80)

if 'employees' in account_merged.columns and 'revenue' in account_merged.columns:
    # NaN değerleri temizle
    regression_data = account_merged[['employees', 'revenue', 'close_value']].dropna()
    
    if len(regression_data) > 10:
        # Linear Regression (employees -> close_value)
        slope, intercept, r_value, p_value, std_err = stats.linregress(
            regression_data['employees'], 
            regression_data['close_value']
        )
        
        print(f"✅ Çalışan Sayısı vs Satış Değeri Regresyonu:")
        print(f"  • R-squared: {r_value**2:.3f}")
        print(f"  • Slope (Eğim): {slope:.2f}")
        print(f"  • P-value: {p_value:.4f}")
        print(f"  • İstatistiksel Anlamlılık: {'Evet' if p_value < 0.05 else 'Hayır'}")
        
        # Revenue vs close_value
        slope2, intercept2, r_value2, p_value2, std_err2 = stats.linregress(
            regression_data['revenue'], 
            regression_data['close_value']
        )
        
        print(f"\n  Account Revenue vs Satış Değeri Regresyonu:")
        print(f"  • R-squared: {r_value2**2:.3f}")
        print(f"  • Slope (Eğim): {slope2:.4f}")
        print(f"  • P-value: {p_value2:.4f}")

# ============================================================================
# 10. ROI ANALİZİ (Return on Investment)
# ============================================================================
print("\n\n📊 10. ROI ANALİZİ")
print("-"*80)

# Ürün bazlı ROI (sales_price vs close_value)
product_sales = won_deals.merge(products, on='product_id', how='left')

if 'sales_price' in product_sales.columns:
    roi_analysis = product_sales.groupby('product').agg({
        'sales_price': 'sum',
        'close_value': 'sum'
    }).reset_index()
    
    roi_analysis['roi'] = ((roi_analysis['close_value'] - roi_analysis['sales_price']) / 
                           roi_analysis['sales_price'] * 100)
    roi_analysis = roi_analysis.sort_values('roi', ascending=False)
    
    print(f"✅ Ürün Bazlı ROI Analizi:")
    print(roi_analysis.to_string(index=False))
    
    avg_roi = roi_analysis['roi'].mean()
    print(f"\nOrtalama ROI: {avg_roi:.2f}%")

# ============================================================================
# 11. SEGMENTATION (Müşteri Segmentasyonu)
# ============================================================================
print("\n\n📊 11. CUSTOMER SEGMENTATION")
print("-"*80)

# Sector bazlı segmentasyon
if 'sector' in accounts.columns:
    sector_performance = accounts.merge(
        won_deals.groupby('account_id')['close_value'].sum().reset_index(),
        on='account_id',
        how='left'
    )
    
    sector_stats = sector_performance.groupby('sector').agg({
        'account_id': 'count',
        'close_value': ['sum', 'mean']
    }).round(2)
    
    sector_stats.columns = ['Customer_Count', 'Total_Revenue', 'Avg_Revenue']
    sector_stats = sector_stats.sort_values('Total_Revenue', ascending=False)
    
    print(f"✅ Sektör Bazlı Segmentasyon:")
    print(sector_stats)

# Company size segmentasyonu
if 'employees' in accounts.columns:
    accounts['company_size'] = pd.cut(
        accounts['employees'],
        bins=[0, 50, 200, 1000, float('inf')],
        labels=['Small', 'Medium', 'Large', 'Enterprise']
    )
    
    size_performance = accounts.merge(
        won_deals.groupby('account_id')['close_value'].sum().reset_index(),
        on='account_id',
        how='left'
    )
    
    size_stats = size_performance.groupby('company_size').agg({
        'account_id': 'count',
        'close_value': ['sum', 'mean']
    }).round(2)
    
    print(f"\n✅ Şirket Büyüklüğü Bazlı Segmentasyon:")
    print(size_stats)

# ============================================================================
# 12. SALES TEAM PERFORMANCE
# ============================================================================
print("\n\n📊 12. SALES TEAM PERFORMANCE")
print("-"*80)

team_performance = sales_pipeline.merge(sales_teams, on='agent_id', how='left')

team_stats = team_performance.groupby('manager').agg({
    'opportunity_id': 'count',
    'close_value': 'sum',
    'is_won': 'sum'
}).reset_index()

team_stats['conversion_rate'] = (team_stats['is_won'] / team_stats['opportunity_id'] * 100).round(2)
team_stats['avg_deal_size'] = (team_stats['close_value'] / team_stats['is_won']).round(2)
team_stats = team_stats.sort_values('close_value', ascending=False)

print(f"✅ Manager Bazlı Performans:")
print(team_stats.to_string(index=False))

print("\n" + "="*80)
print("ANALİZ TAMAMLANDI!")
print("="*80)