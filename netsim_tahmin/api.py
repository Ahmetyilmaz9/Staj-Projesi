from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import pandas as pd
from prophet import Prophet
from sentetik_veri import sentetik_satis_uret, stok_serisi_uret
import numpy as np

app = FastAPI(title="Netsim Talep Tahmin Servisi")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Basit tahmin cache'i: veri sentetik/sabit olduğu için model bir kez eğitilir ---
_cache: dict[tuple[int, int], pd.DataFrame] = {}
_seri_cache: dict[int, pd.DataFrame] = {}
_dogruluk_cache: dict[tuple[int, int], dict] = {}

def model_olustur() -> Prophet:
    model = Prophet(
        yearly_seasonality=True,
        weekly_seasonality=True,
        daily_seasonality=False,
        interval_width=0.90,
    )
    model.add_country_holidays(country_name="TR")
    return model


@app.get("/dogruluk")
def dogruluk(stok_no: int = 0, test_gun: int = 90):
    if test_gun < 14 or test_gun > 180:
        raise HTTPException(400, "test_gun 14-180 arasında olmalı")

    anahtar = (stok_no, test_gun)
    if anahtar in _dogruluk_cache:
        return _dogruluk_cache[anahtar]

    df = seri_al(stok_no)
    if len(df) <= test_gun + 90:
        raise HTTPException(400, "Backtest için seri çok kısa")

    egitim = df.iloc[:-test_gun]
    test = df.iloc[-test_gun:].reset_index(drop=True)

    model = model_olustur()
    model.fit(egitim)
    future = model.make_future_dataframe(periods=test_gun)
    tahminler = model.predict(future).tail(test_gun).reset_index(drop=True)

    gercek = test["y"].to_numpy(dtype=float)
    yhat = tahminler["yhat"].to_numpy()
    alt = tahminler["yhat_lower"].to_numpy()
    ust = tahminler["yhat_upper"].to_numpy()

    hata = gercek - yhat
    mae = float(np.mean(np.abs(hata)))

    # MAPE: sıfır satışlı günleri bölme hatasına karşı dışarıda bırak
    maske = gercek > 0
    mape = float(np.mean(np.abs(hata[maske]) / gercek[maske]) * 100) if maske.any() else None

    kapsama = float(np.mean((gercek >= alt) & (gercek <= ust)) * 100)

    sonuc = {
        "stok_no": stok_no,
        "test_gun": test_gun,
        "egitim_gun": len(egitim),
        "mape": round(mape, 1) if mape is not None else None,
        "mae": round(mae, 1),
        "kapsama": round(kapsama, 1),          # hedef ~90 (interval_width=0.90)
        "ortalama_gercek": round(float(np.mean(gercek)), 1),
    }
    _dogruluk_cache[anahtar] = sonuc
    return sonuc



def seri_al(stok_no: int) -> pd.DataFrame:
    """stok_no=0 → genel/toplam seri; >0 → stoğa özgü seri."""
    if stok_no not in _seri_cache:
        _seri_cache[stok_no] = (
            sentetik_satis_uret() if stok_no == 0 else stok_serisi_uret(stok_no)
        )
    return _seri_cache[stok_no]


def tahmin_al(stok_no: int, gelecek_gun: int) -> pd.DataFrame:
    anahtar = (stok_no, gelecek_gun)
    if anahtar in _cache:
        return _cache[anahtar]
    df = seri_al(stok_no)
    model = model_olustur()
    model.fit(df)
    future = model.make_future_dataframe(periods=gelecek_gun)
    forecast = model.predict(future)
    _cache[anahtar] = forecast
    return forecast


@app.get("/tahmin")
def tahmin(gelecek_gun: int = 90, stok_no: int = 0):
    if gelecek_gun < 1 or gelecek_gun > 365:
        raise HTTPException(400, "gelecek_gun 1-365 arasında olmalı")

    df = seri_al(stok_no)
    forecast = tahmin_al(stok_no, gelecek_gun)
    gercek = {row["ds"].strftime("%Y-%m-%d"): int(row["y"]) for _, row in df.iterrows()}

    sonuc = []
    for _, row in forecast.iterrows():
        tarih = row["ds"].strftime("%Y-%m-%d")
        sonuc.append({
            "tarih": tarih,
            "tahmin": round(row["yhat"], 1),
            "alt": round(row["yhat_lower"], 1),
            "ust": round(row["yhat_upper"], 1),
            "gercek": gercek.get(tarih),
        })

    return {"gecmis_gun": len(df), "gelecek_gun": gelecek_gun, "veri": sonuc}


@app.get("/oneri")
def oneri(mevcut: float, asgari: float = 0, normal: float = 0,
          gelecek_gun: int = 90, stok_no: int = 0,
          talep_carpani: float = 1.0):
    if gelecek_gun < 1 or gelecek_gun > 365:
        raise HTTPException(400, "gelecek_gun 1-365 arasında olmalı")
    if talep_carpani < 0.5 or talep_carpani > 2.0:
        raise HTTPException(400, "talep_carpani 0.5-2.0 arasında olmalı")

    forecast = tahmin_al(stok_no, gelecek_gun)
    gelecek = forecast.tail(gelecek_gun)

    kalan = mevcut
    kritik_tarih = None
    kalan_gun = None
    toplam_talep = 0.0

    for i, (_, row) in enumerate(gelecek.iterrows()):
        gunluk = max(row["yhat"], 0) * talep_carpani     # ← senaryo çarpanı
        toplam_talep += gunluk
        kalan -= gunluk
        if kritik_tarih is None and kalan < asgari:
            kritik_tarih = row["ds"].strftime("%Y-%m-%d")
            kalan_gun = i + 1

    hedef = normal if normal > 0 else asgari
    onerilen = max(0.0, toplam_talep + hedef - mevcut)

    return {
        "mevcut": mevcut,
        "asgari": asgari,
        "normal": normal,
        "ufuk_gun": gelecek_gun,
        "talep_carpani": talep_carpani,                  # ← yanıtta da dönsün
        "toplam_tahmini_talep": round(toplam_talep, 1),
        "kritik_tarih": kritik_tarih,
        "kalan_gun": kalan_gun,
        "donem_sonu_stok": round(kalan, 1),
        "onerilen_siparis": round(onerilen, 1),
    }


@app.get("/")
def kok():
    return {"mesaj": "Netsim Talep Tahmin Servisi çalışıyor. /tahmin ve /oneri kullanılabilir."}