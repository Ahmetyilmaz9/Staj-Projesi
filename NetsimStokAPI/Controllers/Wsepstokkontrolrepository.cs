using System.Text.Json;

namespace NetsimStokAPI.Data;

/// <summary>
/// Veriyi Netsim WSEP uç noktalarından çeker (doğrudan veritabanı bağlantısı yok).
/// Uç noktalar parametresiz olduğu için filtreleme burada, bellekte yapılır.
/// </summary>
public class WsepStokKontrolRepository : IStokKontrolRepository
{
    private readonly WsepClient _client;

    public WsepStokKontrolRepository(WsepClient client)
    {
        _client = client;
    }

    public async Task<IEnumerable<dynamic>> GetStokListesiAsync(string? ad = null, int limit = 500)
{
    var tumu = await _client.GetAsync("StokKontrolListe");
    var limitler = await LimitSozlugu();

    // Konum verisini BIR kez çek, stok bazında grupla (depo bazlı kontrol için)
    var konumTumu = await _client.GetAsync("StokKontrolKonum");
    var depoMiktarlari = konumTumu
        .GroupBy(r => r.GetInt("STOK_NO"))
        .ToDictionary(g => g.Key, g => g.Select(r => r.GetDouble("MIKTAR")).ToList());

    IEnumerable<Dictionary<string, JsonElement>> sorgu = tumu;

    if (!string.IsNullOrWhiteSpace(ad))
    {
        var kultur = new System.Globalization.CultureInfo("tr-TR");
        var aranan = ad.Trim().ToUpper(kultur);
        sorgu = sorgu.Where(r =>
            (r.GetString("STOK_ADI") ?? "").ToUpper(kultur).Contains(aranan)
            || (r.GetString("STOK_KODU") ?? "").ToUpper(kultur).Contains(aranan));
    }

    var sonuc = new List<Dictionary<string, object?>>();
    foreach (var r in sorgu.Take(limit))
    {
        var stokNo = r.GetInt("STOK_NO");
        var miktar = r.GetDouble("MIKTAR");

        var satir = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
        foreach (var kv in r) satir[kv.Key] = JsonToObject(kv.Value);

        if (limitler.TryGetValue(stokNo, out var lim))
        {
            satir["ASGARI"] = lim.Asgari;
            satir["NORMAL"] = lim.Normal;
            satir["AZAMI"] = lim.Azami;

            // 1) Toplam bazlı durum (eski davranış)
            var durum = DurumHesapla(miktar, lim);

            // 2) Depo bazlı kontrol: herhangi bir depoda daha kötü durum varsa onu al
            if (depoMiktarlari.TryGetValue(stokNo, out var depolar))
            {
                foreach (var depoMiktar in depolar)
                {
                    var depoDurum = DurumHesapla(depoMiktar, lim);
                    if (DurumSiddeti(depoDurum) > DurumSiddeti(durum))
                        durum = depoDurum;
                }
            }

            satir["LIMIT_DURUMU"] = durum;
        }
        else
        {
            satir["LIMIT_DURUMU"] = "YOK";
        }

        sonuc.Add(satir);
    }

    return sonuc;
}

/// <summary>Durum etiketlerinin ciddiyet sırası (büyük = daha kötü/öncelikli).</summary>
private static int DurumSiddeti(string durum) => durum switch
{
    "KRITIK" => 3,
    "UYARI" => 2,
    "FAZLA" => 1,
    "NORMAL" => 0,
    _ => -1
};

    public async Task<dynamic?> GetStokGenelDetayAsync(int stokNo)
    {
        // Liste uç noktası detay alanlarını da taşıyor, ayrı bir istek gerekmiyor.
        var tumu = await _client.GetAsync("StokKontrolListe");
        return tumu.FirstOrDefault(r => r.GetInt("STOK_NO") == stokNo);
    }

    public async Task<dynamic?> GetStokLimitAsync(int stokNo)
    {
        var limitler = await LimitSozlugu();
        if (!limitler.TryGetValue(stokNo, out var lim)) return null;
        return new Dictionary<string, object?>
        {
            ["STOK_NO"] = stokNo,
            ["ASGARI"] = lim.Asgari,
            ["NORMAL"] = lim.Normal,
            ["AZAMI"] = lim.Azami,
        };
    }

    public async Task<IEnumerable<dynamic>> GetStokKonumlariAsync(int stokNo)
{
    var tumu = await _client.GetAsync("StokKontrolKonum");
    var konumlar = tumu.Where(r => r.GetInt("STOK_NO") == stokNo).ToList();

    var limitler = await LimitSozlugu(); // genel (sınıf) limit — tek kaynak

    var sonuc = new List<Dictionary<string, object?>>();
    foreach (var r in konumlar)
    {
        var satir = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
        foreach (var kv in r) satir[kv.Key] = JsonToObject(kv.Value);

        var miktar = r.GetDouble("MIKTAR");

        // Genel limit her depoya ayni sekilde uygulanir (mentor açıklaması)
        if (limitler.TryGetValue(stokNo, out var lim))
        {
            satir["ASGARI"] = lim.Asgari;
            satir["NORMAL"] = lim.Normal;
            satir["AZAMI"] = lim.Azami;
            satir["LIMIT_DURUMU"] = DurumHesapla(miktar, lim);
        }
        else
        {
            satir["LIMIT_DURUMU"] = "YOK";
        }

        sonuc.Add(satir);
    }
    return sonuc;
    }
    public async Task<dynamic?> GetStokDurumuAsync(int stokNo)
    {
        var tumu = await _client.GetAsync("StokKontrolDurum");
        return tumu.FirstOrDefault(r => r.GetInt("STOK_NO") == stokNo);
    }

    public async Task<IEnumerable<dynamic>> GetStokHareketleriAsync(int stokNo, int first = 100)
    {
        var tumu = await _client.GetAsync("StokKontrolHareket");
        return tumu.Where(r => r.GetInt("STOK_NO") == stokNo)
                   .Take(first)
                   .Cast<dynamic>()
                   .ToList();
    }

    public async Task<IEnumerable<dynamic>> GetAlisSatisHareketleriAsync(int stokNo, int first = 100)
    {
        var tumu = await _client.GetAsync("StokKontrolAlisSatis");
        return tumu.Where(r => r.GetInt("STOK_NO") == stokNo)
                   .Take(first)
                   .Cast<dynamic>()
                   .ToList();
    }

    public async Task<IEnumerable<dynamic>> GetUyumluStoklarAsync(int stokNo)
    {
        var tumu = await _client.GetAsync("StokKontrolUyumlu");
        return tumu.Where(r => r.GetInt("ANA_STOK_NO") == stokNo).Cast<dynamic>().ToList();
    }

    /// <summary>
    /// Stoğun birimlerini ve çarpanlarını döndürür. Ayrıca her birime,
    /// mevcut miktarın o birim cinsinden karşılığını (CEVRILMIS_MIKTAR) ekler.
    /// Netsim mantığı: miktar Birim1 (çarpan=1, en küçük sıra) cinsinden tutulur.
    /// Bir birimin miktarı = Birim1_miktar / o_birimin_katsayisi.
    /// (Açıklamadaki örnek: Adet -> Kg çevriminde miktar × 0.001; yani Birim1'e
    ///  giderken çarpılıyorsa, Birim1'den o birime dönerken bölünür.)
    /// </summary>
    public async Task<IEnumerable<dynamic>> GetStokBirimleriAsync(int stokNo)
    {
        var tumBirimler = await _client.GetAsync("StokKontrolBirim");
        var birimler = tumBirimler.Where(r => r.GetInt("STOK_NO") == stokNo).ToList();
        if (birimler.Count == 0) return new List<dynamic>();

        // Mevcut miktarı (Birim1 cinsinden) durum endpoint'inden al.
        var durumTumu = await _client.GetAsync("StokKontrolDurum");
        var durum = durumTumu.FirstOrDefault(r => r.GetInt("STOK_NO") == stokNo);
        var birim1Miktar = durum?.GetDouble("MIKTAR") ?? 0;

        var sonuc = new List<Dictionary<string, object?>>();
        foreach (var b in birimler)
        {
            var birimAdi = b.GetString("BIRIM") ?? "";
            var katsayiVar = b.TryGetValue("KATSAYI", out var kEl) && kEl.ValueKind == JsonValueKind.Number;
            var katsayi = katsayiVar ? kEl.GetDouble() : 1.0;
            if (katsayi == 0) katsayi = 1.0; // sıfıra bölme koruması

            // Birim1 cinsindeki miktarı bu birime çevir.
            var cevrilmis = birim1Miktar / katsayi;

            sonuc.Add(new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase)
            {
                ["STOK_NO"] = stokNo,
                ["BIRIM"] = birimAdi,
                ["KATSAYI"] = katsayi,
                ["SIRA_NO"] = b.GetInt("SIRA_NO"),
                ["CEVRILMIS_MIKTAR"] = cevrilmis,
                ["TEMEL_BIRIM_MI"] = katsayi == 1.0,
                ["TAKIP_BIRIM1_DEN"] = (b.GetString("DURUM_TAKIBI_BIRIM1_DEN") ?? "H") == "E",
                ["BIRIM1_E_DONUSUR"] = (b.GetString("BIRIM1_E_DONUSUR") ?? "H") == "E",
            });
        }

        // Sıra numarasına göre sırala (Birim1 en başta olsun).
        sonuc.Sort((a, b) => ((int)(a["SIRA_NO"] ?? 0)).CompareTo((int)(b["SIRA_NO"] ?? 0)));
        return sonuc;
    }

    // --- Limit yardımcıları ---

    private record LimitBilgi(double Asgari, double Normal, double Azami);

    /// <summary>
    /// StokKontrolLimit uç noktasını çekip stok no -> limit sözlüğü üretir.
    /// Bir stok için birden çok satır varsa (ZAMAN kolonu nedeniyle) en yüksek
    /// ASGARI/NORMAL/AZAMI değerlerini değil, ilk gelen satırı esas alır -
    /// veri görülünce netleştirilecek.
    /// </summary>
    private async Task<Dictionary<int, LimitBilgi>> LimitSozlugu()
    {
        var sozluk = new Dictionary<int, LimitBilgi>();
        try
        {
            var limitSatirlari = await _client.GetAsync("StokKontrolLimit");
            foreach (var r in limitSatirlari)
            {
                var stokNo = r.GetInt("STOK_NO");
                if (stokNo == 0) continue;
                if (!sozluk.ContainsKey(stokNo))
                {
                    sozluk[stokNo] = new LimitBilgi(
                        r.GetDouble("ASGARI"),
                        r.GetDouble("NORMAL"),
                        r.GetDouble("AZAMI"));
                }
            }
        }
        catch
        {
            // Limit endpoint'i yoksa veya boşsa sessizce geç - limitsiz çalışır.
        }
        return sozluk;
    }
    
    /// <summary>
    /// Mevcut miktarı limit eşikleriyle karşılaştırıp durum etiketi üretir.
    /// KRITIK  = mevcut <= asgari (kırmızı)
    /// UYARI   = asgari < mevcut < normal (turuncu)
    /// NORMAL  = mevcut >= normal (yeşil)
    /// FAZLA   = azami tanımlıysa ve mevcut > azami (mavi/uyarı)
    /// </summary>
    private static string DurumHesapla(double miktar, LimitBilgi lim)
    {
        if (lim.Azami > 0 && miktar > lim.Azami) return "FAZLA";
        if (miktar <= lim.Asgari) return "KRITIK";
        if (lim.Normal > 0 && miktar < lim.Normal) return "UYARI";
        return "NORMAL";
    }

    private static object? JsonToObject(JsonElement e) => e.ValueKind switch
    {
        JsonValueKind.Number => e.TryGetInt64(out var l) ? l : e.GetDouble(),
        JsonValueKind.String => e.GetString(),
        JsonValueKind.True => true,
        JsonValueKind.False => false,
        JsonValueKind.Null => null,
        _ => e.ToString()
    };

    public async Task<dynamic?> GetStokByBarkodAsync(string barkod)
{
    var barkodlar = await _client.GetAsync("StokKontrolBarkod");
    var eslesme = barkodlar.FirstOrDefault(r =>
        string.Equals(r.GetString("BARKOD")?.Trim(), barkod.Trim(),
                      StringComparison.OrdinalIgnoreCase));
    if (eslesme is null) return null;

    // Barkod bulundu — stoğun liste satırını (ad, kod, durum vs.) döndür
    var stokNo = eslesme.GetInt("STOK_NO");
    var liste = await _client.GetAsync("StokKontrolListe");
    var stok = liste.FirstOrDefault(r => r.GetInt("STOK_NO") == stokNo);
    if (stok is null) return null;

    var satir = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
    foreach (var kv in stok) satir[kv.Key] = JsonToObject(kv.Value);
    satir["BARKOD"] = barkod;
    return satir;
}
}