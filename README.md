# 📊 CRM_Data_Analysis_for_Sales with Python, SQL, PowerBI & Excel

🚀 **Amaç:** Şirketin CRM verilerini **SQL** ile modelleyip, **Python** ile analiz ederek ve **Power BI** ile görselleştirerek satış süreçlerine ilişkin **eyleme dönük içgörüler** üretmek.

---
## 🗂 Repository Structure

| No | Filename | Description |
|---|---|---|
| 1️⃣ | `1.Business_Understanding.txt` | Business goals & key analytical questions |
| 2️⃣ | `2.Data_Understanding.ipynb` | Exploratory data analysis, data quality checks |
| 3️⃣ | `3.Data_Preparation.ipynb` | Data cleaning, feature engineering, transformations |
| 4️⃣ | `4.Database_Modeling.ipynb` | ER diagram, table relationships, normalization |
| 5️⃣ | `5.Sales_Performance_Analytics_KPIs.sql` | SQL scripts to compute sales metrics & KPIs |
| 6️⃣ | `6.CRM_Analysis.py` | Python-based modeling, insights, predictions |


## 📑 İçindekiler
1. 🎯 [Proje Hedefleri](#-proje-hedefleri)  
2. 🗄️ [Dataset Hakkında](#%EF%B8%8F-veri-kaynakları)  
3. 🛠️ [Veri Modeli & Şema](#%EF%B8%8F-veri-modeli--şema)  
4. 🔄 [ETL Süreci](#-etl-süreci)  
5. 🧹 [Veri Temizleme](#-veri-temizleme)  
6. 🔍 [Keşifsel Veri Analizi (EDA)](#-keşifsel-veri-analizi-eda)  
7. 📈 [Analiz Metodolojisi](#-analiz-metodolojisi)  
8. 📊 [Dashboard & Görselleştirme](#-dashboard--görselleştirme)    
9. 🧰 [Teknoloji Yığını](#-teknoloji-yığını)  

---

## 🎯 Proje Hedefleri
- Satış performansını çok boyutlu analiz etmek  
- Kazanılan ve kaybedilen fırsatları modelleyerek satış sürecini anlamak  
- Ürün, müşteri ve bölge bazında satış trendlerini belirlemek  
- Satış ekibi performansını ölçen KPI’ları geliştirmek  
- Müşteri davranışlarını analiz ederek veri odaklı stratejiler oluşturmak  

---

## 🗄️ Dataset Hakkında

Bu veri seti, kurgusal bir şirketin CRM (Müşteri İlişkileri Yönetimi) sisteminden alınan müşteri etkileşimleri, satış aktiviteleri ve fırsat verilerini içermektedir. Veri seti; veri bilimcilerin ve analistlerin satış sürecini anlamalarına, eğilimleri ve kalıpları belirlemelerine ve satış performansını iyileştirmek için öngörüsel modeller oluşturmalarına yardımcı olmak amacıyla tasarlanmıştır.

  🎯 Geliştirilecek Beceriler

- Veri Görselleştirme (Data Visualization)
- Satış Analitiği (Sales Analytics)
- Müşteri İlişkileri Yönetimi (CRM) Analizi
---

## 🛠️ Veri Modeli & Şema
**Kullanılan tablolar:**
- `accounts` → Müşteri/şirket bilgileri (sektör, gelir, çalışan sayısı vb.)  
- `sales_pipeline` → Satış fırsatları (aşama, kapanış değeri, tarih, kazanma durumu)  
- `sales_teams` → Satış ekibi & temsilci yapısı  
- `products` → Ürün kataloğu (fiyat, seri, ürün tipi vb.)

🔗 **İlişkiler:**
- sales_pipeline → accounts (`account_id`)  
- sales_pipeline → products (`product_id`)  
- sales_pipeline → sales_teams (`agent_id`)

📘 **ER Diyagramı:**
<div align="center">
  <img src="https://github.com/can-uncu/CRM_Data_Analysis_for_Sales/blob/main/erd_diagram.jpg" alt="ER Diagram" width="1000"/>
</div>

---

## 🔄 ETL Süreci
1. **Extract (Veri Çekme):**  
   - Satış, ürün, müşteri ve ekip verileri **CSV dosyalarından** alındı.  
   - Veriler **Python (Pandas DataFrame)** kullanılarak içeri aktarıldı.

2. **Transform (Dönüştürme):**  
   - Gereksiz sütunlar kaldırıldı  
   - Eksik ve hatalı değerler temizlendi  
   - Veri tipleri dönüştürüldü  
   - Hesaplanmış alanlar eklendi  
   - Kategorik değişkenler normalize edildi (ör. bölge adları, ürün sınıfları)

3. **Load (Yükleme):**  
   - Temizlenmiş veriler **CSV dosyası** olarak dışa aktarıldı  
   - Bu temiz CSV’ler **PostgreSQL veritabanına import edilerek** tablo yapısına uygun şekilde yüklendi  
   - Ardından PostgreSQL veritabanı **Power BI**’a bağlanarak dashboard oluşturuldu  

---

## 🧹 Veri Temizleme (Data Cleaning)

- ✅ Eksik değerlerin doldurulması (*Missing Value Imputation*)  
- ✅ Aykırı değerlerin temizlenmesi (*Outlier Detection*)  
- ✅ Kategorik verilerin kodlanması (*Encoding*)  
- ✅ Tarih formatlarının standardizasyonu (*Date Formatting*)  
- ✅ Sayısal verilerin ölçeklenmesi (*Scaling / Normalization*)  
- ✅ Veri kalitesi kontrolü (*Data Quality Check*)  


---

## 🔍 Keşifsel Veri Analizi (EDA)
- 📌 Satışların ürün, sektör, bölge ve ekip bazında dağılımı  
- 📌 Kapanış değerleri (close_value) ve kazanma oranlarının incelenmesi  
- 📌 Müşteri büyüklüğüne göre fırsat hacimleri  
- 📌 Fırsatların kapanış süresi ve aşama analizleri  
- 📌 Zaman bazlı (çeyrek/yıl) satış trendleri  

---

## 📈 Analiz Metodolojisi
- **Temel KPI’lar:**  
  - 💰 Toplam Satış Değeri  
  - 📈 Kazanma Oranı (Win Rate)  
  - 📦 Ortalama Fırsat Değeri  
  - 🕓 Ortalama Kapanış Süresi  

- **Segment Analizi:**  
  - 👩‍💼 Satış Temsilcisi Bazında Performans  
  - 🏭 Sektör ve Ürün Bazlı Satışlar  
  - 🌍 Bölgesel Satış Kırılımları  

- **Trend Analizi:**  
  - 📅 Yıllık ve Çeyreklik Satış Trendleri  
  - 🔁 Tekrarlayan Müşteri Oranı  

---

## 📊 Dashboard & Görselleştirme
✨ Power BI’da oluşturulan dashboard şu analizleri sunar:  
- 📊 Satış performansı KPI kartları (gelir, oran, hacim)  
- 📈 Fırsat kazanma/kaybetme oranı trendi  
- 🧭 Satış temsilcisi bazlı performans sıralaması  
- 🏭 Ürün ve sektör bazlı satış karşılaştırmaları  
- ⏱️ Zaman serisi grafikleri (çeyrek ve yıllık karşılaştırmalar)

## 🧰 Teknoloji Yığını
| Kategori | Araç / Kütüphane |
|-----------|------------------|
| 🗄️ Veritabanı | PostgreSQL |
| 🐍 Programlama | Python (Pandas, NumPy, Matplotlib, Seaborn) |
| 📊 Görselleştirme | Power BI |
| 📋 Veri Hazırlama | Jupyter Notebook |
| 🧮 Sorgulama | SQL |
| 🧰 Diğer | Excel / CSV (ara veri depolama) |

---


## 👨‍💻 Hazırlayan
**Emrecan Uncu**  
🔗 [LinkedIn Profilim](https://www.linkedin.com/in/emrecan-uncu/)  
💻 [GitHub Hesabım](https://github.com/can-uncu)  






