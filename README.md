# Netsim ERP Stok Takip Sistemi

Netsim N4 ERP sisteminin stok modülü üzerine kurulu, çok katmanlı bir stok takip ve talep tahmini uygulaması. Stok kartlarını, depo bazlı miktarları, hareketleri ve limit durumlarını web ve mobil arayüzden izlenebilir hale getirir; buna ek olarak Prophet tabanlı bir talep tahmini ve sipariş önerisi katmanı sunar.

> Staj projesi olarak geliştirilmiştir.

## Mimari

```
Netsim N4 (Firebird)
        │  WSEP / FastAPI uç noktaları (HTTP)
        ▼
ASP.NET Core 9 Web API  ──────►  Flutter (Web + Android)
   JWT · önbellek · DTO              ▲
                                     │
Python FastAPI + Prophet ────────────┘
   talep tahmini · sipariş önerisi
```

Uygulama ERP veritabanına doğrudan bağlanmaz; Netsim'in kendi web servis altyapısı (WSEP) üzerinden veri çeker. Böylece ERP'nin iş mantığı ve yetkilendirme katmanı devrede kalır.

| Katman | Teknoloji | Görevi |
|---|---|---|
| Veri kaynağı | Netsim N4 / Firebird | SQL sorgularının REST uç noktası olarak yayınlanması |
| Ara katman | ASP.NET Core 9 | Ham ERP verisinin DTO'lara dönüştürülmesi, iş kuralları, JWT, önbellek |
| Tahmin servisi | Python · FastAPI · Prophet | Zaman serisi tahmini, doğruluk ölçümü, sipariş önerisi |
| İstemci | Flutter | Arayüz, grafikler, barkod okuma |

## Özellikler

**Stok takibi**
- Genel bakış ekranı: KPI kartları, durum dağılımı grafiği, en kritik ürünler
- Canlı arama ve kritik stok filtresi
- Depo bazlı miktar dağılımı ve limit uyarıları (asgari/normal/azami)
- Çoklu birim desteği — birim katsayıları ve takip birimi bayrağı dikkate alınarak dönüşüm
- Barkod tarama ile doğrudan ürün detayına erişim (Android)

**Talep tahmini**
- Prophet ile günlük tahmin: trend, haftalık/yıllık mevsimsellik ve Türkiye resmi tatilleri
- Geriye dönük test (backtest) ile model doğruluğu: MAPE, MAE, güven aralığı kapsaması
- Mevcut stok ve limitlerle birleşen tükenme tarihi ve önerilen sipariş miktarı
- "Talep %X artarsa" senaryo analizi

## Kurulum

### Gereksinimler
- Docker Desktop
- Çalışan bir Netsim N4 kurulumu (varsayılan: `http://localhost:82/crud/`)
- Flutter SDK (web derlemesi için)

### 1. Netsim uç noktalarını tanımlayın

Netsim Sistem Yöneticisi → Tanımlar → Web FastAPI Uç Noktaları altında aşağıdaki uç noktaları oluşturup onaylayın:

`StokKontrolListe`, `StokKontrolDurum`, `StokKontrolKonum`, `StokKontrolHareket`, `StokKontrolAlisSatis`, `StokKontrolUyumlu`, `StokKontrolLimit`, `StokKontrolBirim`, `StokKontrolBarkod`

> Uç nokta tanımları veritabanının içinde saklanır; farklı bir veritabanına geçildiğinde yeniden oluşturulmaları gerekir.

### 2. Yapılandırma

`NetsimStokAPI/appsettings.json` içindeki JWT anahtarını doldurun (en az 32 karakter):

```json
"Jwt": {
    "Key": "BURAYA-EN-AZ-32-KARAKTERLIK-GIZLI-ANAHTAR-YAZIN"
}
```

### 3. Flutter web derlemesi

```bash
cd staj_proje
flutter build web
```

### 4. Çalıştırma

```bash
docker compose up --build
```

| Servis | Adres |
|---|---|
| Web arayüzü | http://localhost:8080 |
| ASP.NET Core API | http://localhost:5175 |
| Tahmin servisi | http://localhost:8000 |

Demo giriş bilgileri: `ahmet` / `1234`

### Mobil için

Telefon ve bilgisayar aynı ağda olmalı; `staj_proje/lib/services/config.dart` içindeki adresleri bilgisayarın yerel IP'siyle değiştirin.

## Notlar

**Tahmin verisi.** Test ortamındaki gerçek hareket verisi zaman serisi tahmini için yeterli yoğunlukta olmadığından, modelin çalışmasını gösterebilmek amacıyla gerçekçi desenler (trend, mevsimsellik, tatil etkisi, gürültü) taşıyan sentetik satış geçmişi üretilmektedir. Veri kaynağı katmanı ayrıştırıldığı için, yeterli gerçek veri oluştuğunda aynı akış değiştirilmeden kullanılabilir.

**Filtreleme.** Netsim WSEP uç noktaları parametresiz çalıştığından, stok bazlı filtreleme ASP.NET Core katmanında bellekte yapılır. Tekrarlanan istekleri azaltmak için kısa süreli önbellek kullanılır.

## Kullanılan teknolojiler

C# · ASP.NET Core 9 · Python · FastAPI · Prophet · pandas · Flutter · Dart · Firebird SQL · JWT · Docker · nginx
