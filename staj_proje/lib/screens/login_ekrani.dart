import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'ana_kabuk.dart';
import '../theme/app_theme.dart';

class LoginEkrani extends StatefulWidget {
  const LoginEkrani({super.key});

  @override
  State<LoginEkrani> createState() => _LoginEkraniState();
}

class _LoginEkraniState extends State<LoginEkrani>
    with SingleTickerProviderStateMixin {
  final _kullaniciController = TextEditingController();
  final _sifreController = TextEditingController();
  bool _yukleniyor = false;
  String? _hata;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _kullaniciController.dispose();
    _sifreController.dispose();
    _c.dispose();
    super.dispose();
  }

  Future<void> _girisYap() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });
    try {
      await AuthService().login(
        _kullaniciController.text.trim(),
        _sifreController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, anim, __) =>
              FadeTransition(opacity: anim, child: const AnaKabuk()),
        ),
      );
    } catch (e) {
      setState(() {
        _hata = e.toString().replaceFirst('Exception: ', '');
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF12141C), Color(0xFF2A2350), Color(0xFF4F46E5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: Container(
                  width: 380,
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.6, end: 1),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.elasticOut,
                          builder: (context, s, child) =>
                              Transform.scale(scale: s, child: child),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Column(
                          children: [
                            Text(
                              'Netsim Stok Takip',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Hesabınla giriş yap',
                              style: TextStyle(
                                color: Color(0xFFB8BCC8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _kullaniciController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _alanStili(
                          'Kullanıcı adı',
                          Icons.person_outline,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _sifreController,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        onSubmitted: (_) => _girisYap(),
                        decoration: _alanStili('Şifre', Icons.lock_outline),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        child: _hata != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(
                                  _hata!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFFF8A80),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : const SizedBox(width: double.infinity, height: 0),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _yukleniyor ? null : _girisYap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _yukleniyor
                                ? const SizedBox(
                                    key: ValueKey('l'),
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Giriş Yap',
                                    key: ValueKey('t'),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _alanStili(String hint, IconData ikon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF8388A0)),
      prefixIcon: Icon(ikon, color: const Color(0xFFB8BCC8)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
