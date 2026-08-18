class Config {
  static const String sunucu = '10.11.11.77'; // ← kendi IP'n

  static const String stokApi = 'http://$sunucu:5175/api/StokKontrol';
  static const String authApi = 'http://$sunucu:5175/api/auth';
  static const String tahminApi = 'http://$sunucu:8000';
}
