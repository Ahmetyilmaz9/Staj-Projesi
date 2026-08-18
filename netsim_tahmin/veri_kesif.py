import requests
import pandas as pd

# ASP.NET Core middleware'inden hareket verisi çekeceğiz.
# Önce hangi endpoint'in ham hareketleri (tarih + miktar) verdiğini kullanalım.
# StokKontrolHareket tüm stokların hareketlerini taşıyor.

BASE = "http://localhost:5175/api/StokKontrol"  # kendi portunu yaz

# Tüm stokların listesini al (hangi stokta en çok hareket var görelim)
liste = requests.get(BASE).json()
print(f"Toplam stok kalemi: {len(liste)}")

# Örnek: en çok hareketi olan birkaç stoğu bulmak için
# her stoğun hareketlerini çekip sayalım (küçük veri, sorun olmaz)
hareket_sayilari = []
for s in liste:
    stok_no = s.get("STOK_NO")
    if not stok_no or stok_no <= 0:
        continue
    hareketler = requests.get(f"{BASE}/{stok_no}/hareketler").json()
    if len(hareketler) > 0:
        hareket_sayilari.append((stok_no, s.get("STOK_ADI"), len(hareketler)))

# En çok hareketli ilk 10
hareket_sayilari.sort(key=lambda x: x[2], reverse=True)
print("\nEn çok hareketli stoklar:")
for stok_no, ad, sayi in hareket_sayilari[:10]:
    print(f"  [{stok_no}] {ad}: {sayi} hareket")