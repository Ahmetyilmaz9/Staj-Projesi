using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;

namespace NetsimStokAPI.Data;

/// <summary>
/// Netsim WSEP (FastAPI) uç noktalarından veri çeker.
/// Uç noktalar parametresiz olduğu için tüm tabloyu döndürür; filtreleme
/// bu uygulamanın içinde yapılır. Her istekte tüm tabloyu tekrar çekmemek
/// için kısa süreli bellek cache'i kullanılır.
///
/// WSEP yanıt formatı:
///   {
///     "result": true,
///     "metadata": { "STOK_NO": {"type":"INTEGER"}, "STOK_ADI": {...}, ... },
///     "dataset": [ [0, "-- --", ...], [7, "00007", ...] ]
///   }
/// dataset satırları İSİMSİZ dizidir; sütun adları metadata'nın anahtar
/// sırasından alınır ve her satır isimli sözlüğe çevrilir.
/// </summary>
public class WsepClient
{
    private readonly HttpClient _http;
    private readonly IMemoryCache _cache;
    private static readonly TimeSpan CacheSuresi = TimeSpan.FromSeconds(30);

    public WsepClient(HttpClient http, IMemoryCache cache)
    {
        _http = http;
        _cache = cache;
    }

    public async Task<List<Dictionary<string, JsonElement>>> GetAsync(string endpointCode)
    {
        var cacheKey = "wsep:" + endpointCode;

        if (_cache.TryGetValue(cacheKey, out List<Dictionary<string, JsonElement>>? cached) && cached is not null)
            return cached;

        var response = await _http.GetAsync($"FastAPI/{endpointCode}");
        if (!response.IsSuccessStatusCode)
        {
            var hata = await response.Content.ReadAsStringAsync();
            throw new HttpRequestException($"WSEP '{endpointCode}' {(int)response.StatusCode} dondu: {hata}");
        }

        var json = await response.Content.ReadAsStringAsync();
        var rows = Parse(json);

        _cache.Set(cacheKey, rows, CacheSuresi);
        return rows;
    }

    private static List<Dictionary<string, JsonElement>> Parse(string json)
    {
        var sonuc = new List<Dictionary<string, JsonElement>>();

        using var doc = JsonDocument.Parse(json);
        var root = doc.RootElement;

        if (root.ValueKind != JsonValueKind.Object) return sonuc;

        // metadata anahtarlarının SIRASI = dataset satırlarındaki sütun sırası
        if (!root.TryGetProperty("metadata", out var metadata) || metadata.ValueKind != JsonValueKind.Object)
            return sonuc;
        if (!root.TryGetProperty("dataset", out var dataset) || dataset.ValueKind != JsonValueKind.Array)
            return sonuc;

        var sutunAdlari = metadata.EnumerateObject().Select(p => p.Name.ToUpperInvariant()).ToArray();

        foreach (var satir in dataset.EnumerateArray())
        {
            if (satir.ValueKind != JsonValueKind.Array) continue;

            var dict = new Dictionary<string, JsonElement>(StringComparer.OrdinalIgnoreCase);
            int i = 0;
            foreach (var hucre in satir.EnumerateArray())
            {
                if (i < sutunAdlari.Length)
                    dict[sutunAdlari[i]] = hucre.Clone();
                i++;
            }
            sonuc.Add(dict);
        }

        return sonuc;
    }
}

/// <summary>
/// Satır sözlüğünden güvenli değer okuma yardımcıları.
/// </summary>
public static class RowExtensions
{
    public static int GetInt(this Dictionary<string, JsonElement> row, string alan)
    {
        if (!row.TryGetValue(alan, out var v)) return 0;
        return v.ValueKind switch
        {
            JsonValueKind.Number => v.TryGetInt32(out var i) ? i : (int)v.GetDouble(),
            JsonValueKind.String => int.TryParse(v.GetString(), out var i) ? i : 0,
            _ => 0
        };
    }

    public static double GetDouble(this Dictionary<string, JsonElement> row, string alan)
    {
        if (!row.TryGetValue(alan, out var v)) return 0;
        return v.ValueKind switch
        {
            JsonValueKind.Number => v.GetDouble(),
            JsonValueKind.String => double.TryParse(v.GetString(), out var d) ? d : 0,
            _ => 0
        };
    }

    public static string? GetString(this Dictionary<string, JsonElement> row, string alan)
    {
        if (!row.TryGetValue(alan, out var v)) return null;
        return v.ValueKind switch
        {
            JsonValueKind.String => v.GetString(),
            JsonValueKind.Null => null,
            _ => v.ToString()
        };
    }
}