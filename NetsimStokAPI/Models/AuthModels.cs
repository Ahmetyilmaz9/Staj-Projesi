namespace NetsimStokAPI.Models;

public class LoginIstek
{
    public string KullaniciAdi { get; set; } = "";
    public string Sifre { get; set; } = "";
}

public class LoginYanit
{
    public string Token { get; set; } = "";
    public DateTime GecerlilikSonu { get; set; }
    public string KullaniciAdi { get; set; } = "";
}