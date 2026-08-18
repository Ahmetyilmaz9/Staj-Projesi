import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class TahminNoktasi {
  final DateTime tarih;
  final double tahmin;
  final double alt;
  final double ust;
  final double? gercek; // geçmişse değer, gelecekse null

  TahminNoktasi({
    required this.tarih,
    required this.tahmin,
    required this.alt,
    required this.ust,
    required this.gercek,
  });

  factory TahminNoktasi.fromJson(Map<String, dynamic> j) {
    return TahminNoktasi(
      tarih: DateTime.parse(j['tarih']),
      tahmin: (j['tahmin'] as num).toDouble(),
      alt: (j['alt'] as num).toDouble(),
      ust: (j['ust'] as num).toDouble(),
      gercek: j['gercek'] == null ? null : (j['gercek'] as num).toDouble(),
    );
  }
}

class TahminSonucu {
  final int gecmisGun;
  final int gelecekGun;
  final List<TahminNoktasi> veri;

  TahminSonucu({
    required this.gecmisGun,
    required this.gelecekGun,
    required this.veri,
  });
}

class DogrulukSonucu {
  final double? mape;
  final double mae;
  final double kapsama;
  final int testGun;
  final int egitimGun;
  final double ortalamaGercek;

  DogrulukSonucu({
    required this.mape,
    required this.mae,
    required this.kapsama,
    required this.testGun,
    required this.egitimGun,
    required this.ortalamaGercek,
  });

  factory DogrulukSonucu.fromJson(Map<String, dynamic> j) => DogrulukSonucu(
    mape: j['mape'] == null ? null : (j['mape'] as num).toDouble(),
    mae: (j['mae'] as num).toDouble(),
    kapsama: (j['kapsama'] as num).toDouble(),
    testGun: j['test_gun'] as int,
    egitimGun: j['egitim_gun'] as int,
    ortalamaGercek: (j['ortalama_gercek'] as num).toDouble(),
  );
}

class TahminService {
  // Python FastAPI servisi (uvicorn port 8000)
  static const String baseUrl = Config.tahminApi;

  Future<TahminSonucu> getTahmin({int gelecekGun = 90, int stokNo = 0}) async {
    final uri = Uri.parse(
      '$baseUrl/tahmin?gelecek_gun=$gelecekGun&stok_no=$stokNo',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Tahmin servisi hatası (${res.statusCode})');
    }
    final decoded =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final veri = (decoded['veri'] as List)
        .map((e) => TahminNoktasi.fromJson(e as Map<String, dynamic>))
        .toList();
    return TahminSonucu(
      gecmisGun: decoded['gecmis_gun'] as int,
      gelecekGun: decoded['gelecek_gun'] as int,
      veri: veri,
    );
  }

  Future<OneriSonucu> getOneri({
    required double mevcut,
    double asgari = 0,
    double normal = 0,
    int gelecekGun = 90,
    int stokNo = 0,
    double talepCarpani = 1.0,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/oneri?mevcut=$mevcut&asgari=$asgari&normal=$normal'
      '&gelecek_gun=$gelecekGun&stok_no=$stokNo&talep_carpani=$talepCarpani',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Öneri servisi hatası (${res.statusCode})');
    }
    return OneriSonucu.fromJson(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }

  Future<DogrulukSonucu> getDogruluk({int stokNo = 0, int testGun = 90}) async {
    final uri = Uri.parse(
      '$baseUrl/dogruluk?stok_no=$stokNo&test_gun=$testGun',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Doğruluk servisi hatası (${res.statusCode})');
    }
    return DogrulukSonucu.fromJson(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }
}

class OneriSonucu {
  final double mevcut;
  final double asgari;
  final double normal;
  final double toplamTalep;
  final double donemSonuStok;
  final double onerilenSiparis;
  final String? kritikTarih; // null = ufuk içinde limite düşmüyor
  final int? kalanGun;

  OneriSonucu({
    required this.mevcut,
    required this.asgari,
    required this.normal,
    required this.toplamTalep,
    required this.donemSonuStok,
    required this.onerilenSiparis,
    required this.kritikTarih,
    required this.kalanGun,
  });

  factory OneriSonucu.fromJson(Map<String, dynamic> j) => OneriSonucu(
    mevcut: (j['mevcut'] as num).toDouble(),
    asgari: (j['asgari'] as num).toDouble(),
    normal: (j['normal'] as num).toDouble(),
    toplamTalep: (j['toplam_tahmini_talep'] as num).toDouble(),
    donemSonuStok: (j['donem_sonu_stok'] as num).toDouble(),
    onerilenSiparis: (j['onerilen_siparis'] as num).toDouble(),
    kritikTarih: j['kritik_tarih'] as String?,
    kalanGun: j['kalan_gun'] as int?,
  );
}
