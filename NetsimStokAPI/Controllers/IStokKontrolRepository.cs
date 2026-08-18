namespace NetsimStokAPI.Data;

public interface IStokKontrolRepository
{
    Task<IEnumerable<dynamic>> GetStokListesiAsync(string? ad = null, int limit = 500);
    Task<IEnumerable<dynamic>> GetStokKonumlariAsync(int stokNo);
    Task<dynamic?> GetStokGenelDetayAsync(int stokNo);
    Task<dynamic?> GetStokDurumuAsync(int stokNo);
    Task<dynamic?> GetStokLimitAsync(int stokNo);
    Task<IEnumerable<dynamic>> GetStokHareketleriAsync(int stokNo, int first = 100);
    Task<IEnumerable<dynamic>> GetAlisSatisHareketleriAsync(int stokNo, int first = 100);
    Task<IEnumerable<dynamic>> GetUyumluStoklarAsync(int stokNo);
    Task<IEnumerable<dynamic>> GetStokBirimleriAsync(int stokNo);
    Task<dynamic?> GetStokByBarkodAsync(string barkod);
}