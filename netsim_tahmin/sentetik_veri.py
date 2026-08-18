import numpy as np
import pandas as pd
import holidays as hol   # üste


def sentetik_satis_uret(
    baslangic="2024-01-01",
    gun_sayisi=730,
    taban=50,
    trend_egimi=0.03,
    haftalik_genlik=12,
    yillik_genlik=20,
    gurultu_std=6,
    tatil_dusus_orani=0.45,   # ← yeni: bayram günü satış ~%45 düşer
    seed=42,
):
    """Prophet'in beklediği formatta (ds, y) gerçekçi satış serisi üretir."""
    rng = np.random.default_rng(seed)
    tarihler = pd.date_range(start=baslangic, periods=gun_sayisi, freq="D")

    t = np.arange(gun_sayisi)

    trend = taban + trend_egimi * t

    hafta_gunu = tarihler.dayofweek
    haftalik = np.where(hafta_gunu >= 5, -haftalik_genlik, haftalik_genlik * 0.4)

    yillik = yillik_genlik * np.sin(2 * np.pi * (tarihler.dayofyear / 365.25))

    gurultu = rng.normal(0, gurultu_std, gun_sayisi)

    # 5) Resmi tatil etkisi: TR tatillerinde satış belirgin düşer
    yillar = range(tarihler[0].year, tarihler[-1].year + 2)
    tr_tatiller = hol.Turkey(years=yillar)
    tatil_maskesi = np.array([d.date() in tr_tatiller for d in tarihler])
    tatil_etkisi = np.where(tatil_maskesi, -tatil_dusus_orani * trend, 0)

    y = trend + haftalik + yillik + gurultu + tatil_etkisi
    y = np.clip(y, 0, None).round().astype(int)

    return pd.DataFrame({"ds": tarihler, "y": y})

def stok_serisi_uret(stok_no: int, gun_sayisi: int = 730) -> pd.DataFrame:
    """
    Her stok için deterministik ama kendine özgü bir satış serisi üretir.
    stok_no seed olarak kullanıldığından aynı stok her zaman aynı seriyi alır
    (cache ve tekrarlanabilirlik için önemli), ama stoklar birbirinden farklıdır:
    kimi büyür, kimi küçülür, kimi dalgalıdır.
    """
    p = np.random.default_rng(stok_no)  # parametre üreteci (stok'a özgü)
    return sentetik_satis_uret(
        gun_sayisi=gun_sayisi,
        taban=p.uniform(20, 120),          # ürünün satış hacmi
        trend_egimi=p.uniform(-0.03, 0.06), # kimi düşüşte, kimi büyümede
        haftalik_genlik=p.uniform(4, 18),
        yillik_genlik=p.uniform(5, 30),
        gurultu_std=p.uniform(3, 10),
        seed=stok_no,                       # gürültü de stok'a özgü
    )


if __name__ == "__main__":
    df = sentetik_satis_uret()
    print(df.head(10))
    print(f"\nToplam {len(df)} gün, ortalama günlük satış: {df['y'].mean():.1f}")
    print(f"Min: {df['y'].min()}, Max: {df['y'].max()}")

    # CSV olarak kaydet (istersen incelersin)
    df.to_csv("sentetik_satis.csv", index=False)
    print("\nsentetik_satis.csv kaydedildi.")