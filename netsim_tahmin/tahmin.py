import pandas as pd
from prophet import Prophet
from sentetik_veri import sentetik_satis_uret


def model_egit_ve_tahmin(df: pd.DataFrame, gelecek_gun: int = 90):
    """
    Verilen (ds, y) serisiyle Prophet modeli eğitir ve
    gelecek_gun kadar ileriye tahmin üretir.
    """
    model = Prophet(
        yearly_seasonality=True,
        weekly_seasonality=True,
        daily_seasonality=False,
        interval_width=0.90,          # %90 güven aralığı
    )
    model.fit(df)

    # Gelecek tarihleri oluştur (geçmiş + gelecek)
    future = model.make_future_dataframe(periods=gelecek_gun)
    forecast = model.predict(future)

    return model, forecast


if __name__ == "__main__":
    # 1) Sentetik veriyi üret
    df = sentetik_satis_uret()
    print(f"Eğitim verisi: {len(df)} gün")

    # 2) Modeli eğit ve 90 gün ileriye tahmin et
    model, forecast = model_egit_ve_tahmin(df, gelecek_gun=90)

    # 3) Tahmin sonuçlarının son kısmına bakalım (gelecek günler)
    sonuc = forecast[["ds", "yhat", "yhat_lower", "yhat_upper"]].tail(10)
    print("\nSon 10 günün tahmini:")
    print(sonuc.to_string(index=False))

    # 4) Bileşenleri görselleştir (opsiyonel — grafik penceresi açar)
    fig1 = model.plot(forecast)
    fig1.suptitle("Satış Tahmini (Geçmiş + Gelecek)")
    fig2 = model.plot_components(forecast)

    import matplotlib.pyplot as plt
    plt.show()