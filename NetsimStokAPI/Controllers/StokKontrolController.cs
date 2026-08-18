using Microsoft.AspNetCore.Mvc;
using NetsimStokAPI.Data;
using Microsoft.AspNetCore.Authorization;

namespace NetsimStokAPI.Controllers;

[Authorize]                                 // [ApiController]'ın üstüne
[ApiController]
[Route("api/[controller]")]
public class StokKontrolController : ControllerBase
{
    private readonly IStokKontrolRepository _repo;

    public StokKontrolController(IStokKontrolRepository repo)
    {
        _repo = repo;
    }

    // GET /api/StokKontrol            -> tüm liste
    // GET /api/StokKontrol?ad=vida    -> "vida" geçen stoklar
    [HttpGet]
    public async Task<IActionResult> GetListe([FromQuery] string? ad, [FromQuery] int limit = 500)
    {
        var liste = await _repo.GetStokListesiAsync(ad, limit);
        return Ok(liste);
    }

    // GET /api/StokKontrol/12/detay -> "Stok Detayı" sekmesi
    [HttpGet("{stokNo:int}/detay")]
    public async Task<IActionResult> GetDetay(int stokNo)
    {
        var detay = await _repo.GetStokGenelDetayAsync(stokNo);
        if (detay is null) return NotFound();
        return Ok(detay);
    }

    // GET /api/StokKontrol/12/durum -> "Stok Durumu" sekmesi
    [HttpGet("{stokNo:int}/durum")]
    public async Task<IActionResult> GetDurum(int stokNo)
    {
        var durum = await _repo.GetStokDurumuAsync(stokNo);
        return Ok(durum ?? new { });
    }

    // GET /api/StokKontrol/12/konumlar -> "Konumlar" sekmesi
    [HttpGet("{stokNo:int}/konumlar")]
    public async Task<IActionResult> GetKonumlar(int stokNo)
    {
        var konumlar = await _repo.GetStokKonumlariAsync(stokNo);
        return Ok(konumlar);
    }

    // GET /api/StokKontrol/12/hareketler -> "Stok Hareketleri" sekmesi
    [HttpGet("{stokNo:int}/hareketler")]
    public async Task<IActionResult> GetHareketler(int stokNo, [FromQuery] int first = 100)
    {
        var hareketler = await _repo.GetStokHareketleriAsync(stokNo, first);
        return Ok(hareketler);
    }

    // GET /api/StokKontrol/12/alissatis -> "Alış-Satış Hareketleri" sekmesi
    [HttpGet("{stokNo:int}/alissatis")]
    public async Task<IActionResult> GetAlisSatis(int stokNo, [FromQuery] int first = 100)
    {
        var kayitlar = await _repo.GetAlisSatisHareketleriAsync(stokNo, first);
        return Ok(kayitlar);
    }

    // GET /api/StokKontrol/12/uyumlu -> "Uyumlu Stoklar" sekmesi
    [HttpGet("{stokNo:int}/uyumlu")]
    public async Task<IActionResult> GetUyumlu(int stokNo)
    {
        var uyumlular = await _repo.GetUyumluStoklarAsync(stokNo);
        return Ok(uyumlular);
    }

    // GET /api/StokKontrol/12/limit -> stok limit (asgari/normal/azami)
    [HttpGet("{stokNo:int}/limit")]
    public async Task<IActionResult> GetLimit(int stokNo)
    {
        var limit = await _repo.GetStokLimitAsync(stokNo);
        if (limit is null) return NotFound();
        return Ok(limit);
    }

    // GET /api/StokKontrol/12/birimler -> stoğun birimleri + çevrilmiş miktarlar
    [HttpGet("{stokNo:int}/birimler")]
    public async Task<IActionResult> GetBirimler(int stokNo)
    {
        var birimler = await _repo.GetStokBirimleriAsync(stokNo);
        return Ok(birimler);
    }

    // GET /api/StokKontrol/barkod/8690123456789
[HttpGet("barkod/{kod}")]
public async Task<IActionResult> GetByBarkod(string kod)
{
    var stok = await _repo.GetStokByBarkodAsync(kod);
    if (stok is null) return NotFound();
    return Ok(stok);
}
}