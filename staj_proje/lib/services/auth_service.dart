import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

/// Oturum durumunu uygulama genelinde tutan basit singleton.
/// (Web demo için bellekte tutmak yeterli; kalıcılık istersek
/// shared_preferences eklenebilir.)
class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  static const String baseUrl = Config.authApi;

  String? _token;
  String? _kullaniciAdi;

  String? get token => _token;
  String? get kullaniciAdi => _kullaniciAdi;
  bool get girisYapildi => _token != null;

  Future<void> login(String kullaniciAdi, String sifre) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'kullaniciAdi': kullaniciAdi, 'sifre': sifre}),
    );

    // API'den gelen ham JSON cevabını konsola yazdır
    print('----- LOGIN API CEVABI -----');
    print(res.body);
    print('----------------------------');

    if (res.statusCode == 401) {
      throw Exception('Kullanıcı adı veya şifre hatalı');
    }
    if (res.statusCode != 200) {
      throw Exception('Giriş başarısız (${res.statusCode})');
    }
    final j = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    _token = j['token'] as String;
    _kullaniciAdi = j['kullaniciAdi'] as String?;
  }

  void cikis() {
    _token = null;
    _kullaniciAdi = null;
  }

  /// Korumalı isteklerde kullanılacak header seti.
  Map<String, String> get headers => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
}
