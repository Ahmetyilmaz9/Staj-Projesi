namespace NetsimStokAPI.Models
{
    // Netsim FastAPI'sinden gelen ham yanıtın şekli
    public class NetsimResponse
    {
        public bool result { get; set; }
        public Dictionary<string, object>? metadata { get; set; }
        public List<List<object>>? dataset { get; set; }
    }

    // Flutter'a göndereceğimiz temiz stok verisi
    public class StokDto
    {
        public int StokNo { get; set; }
        public string StokKodu { get; set; } = "";
        public string StokAdi { get; set; } = "";
        public double MevcutMiktar { get; set; }
    }

    public class StokDetayDto
    {
        public int StokNo { get; set; }
        public string StokKodu { get; set; } = "";
        public string StokAdi { get; set; } = "";
        public string StokAdiGenel { get; set; } = "";
        public string MarkaAdi { get; set; } = "";
        public string StokTipAdi { get; set; } = "";
        public string Birim { get; set; } = "";
        public double ToplamMiktar { get; set; }
    }

    public class DepoDagilimDto
    {
        public int StokYeriNo { get; set; }
        public string StokYeriKodu { get; set; } = "";
        public string StokYeriAdi { get; set; } = "";
        public double Miktar { get; set; }
    }
}