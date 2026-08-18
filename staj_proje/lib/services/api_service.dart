import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'config.dart';

/// ASP.NET Core API'sine bağlanan servis katmanı.
/// dotnet run çıktısındaki adresi buraya yaz (http, https değil).
class ApiService {
  static const String baseUrl = Config.stokApi;

  /// Stok listesi. [ad] verilirse ada göre filtreler.
  Future<List<Map<String, dynamic>>> getStokListesi({String? ad}) async {
    final uri = (ad == null || ad.isEmpty)
        ? Uri.parse(baseUrl)
        : Uri.parse('$baseUrl?ad=${Uri.encodeQueryComponent(ad)}');
    return _getList(uri);
  }

  Future<Map<String, dynamic>?> getDetay(int stokNo) async {
    return _getSingle(Uri.parse('$baseUrl/$stokNo/detay'));
  }

  Future<Map<String, dynamic>?> getDurum(int stokNo) async {
    return _getSingle(Uri.parse('$baseUrl/$stokNo/durum'));
  }

  Future<Map<String, dynamic>?> getLimit(int stokNo) async {
    return _getSingle(Uri.parse('$baseUrl/$stokNo/limit'));
  }

  Future<List<Map<String, dynamic>>> getKonumlar(int stokNo) async {
    return _getList(Uri.parse('$baseUrl/$stokNo/konumlar'));
  }

  Future<List<Map<String, dynamic>>> getHareketler(int stokNo) async {
    return _getList(Uri.parse('$baseUrl/$stokNo/hareketler'));
  }

  Future<List<Map<String, dynamic>>> getAlisSatis(int stokNo) async {
    return _getList(Uri.parse('$baseUrl/$stokNo/alissatis'));
  }

  Future<List<Map<String, dynamic>>> getUyumlu(int stokNo) async {
    return _getList(Uri.parse('$baseUrl/$stokNo/uyumlu'));
  }

  // --- yardımcılar ---

  Future<List<Map<String, dynamic>>> _getList(Uri uri) async {
    final res = await http.get(uri, headers: AuthService().headers);
    if (res.statusCode == 401) {
      throw YetkiHatasi();
    }
    if (res.statusCode != 200) {
      throw Exception('İstek başarısız (${res.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>?> _getSingle(Uri uri) async {
    final res = await http.get(uri, headers: AuthService().headers);
    if (res.statusCode == 401) {
      throw YetkiHatasi();
    }
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception('İstek başarısız (${res.statusCode})');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    if (decoded is Map<String, dynamic>) {
      return decoded.isEmpty ? null : decoded;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getBirimler(int stokNo) async {
    return _getList(Uri.parse('$baseUrl/$stokNo/birimler'));
  }

  Future<Map<String, dynamic>?> getStokByBarkod(String barkod) async {
    return _getSingle(
      Uri.parse('$baseUrl/barkod/${Uri.encodeComponent(barkod)}'),
    );
  }
}

class YetkiHatasi implements Exception {
  @override
  String toString() => 'Oturum geçersiz. Lütfen tekrar giriş yapın.';
}
