import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'stok_detay_ekrani.dart';

class BarkodEkrani extends StatefulWidget {
  const BarkodEkrani({super.key});

  @override
  State<BarkodEkrani> createState() => _BarkodEkraniState();
}

class _BarkodEkraniState extends State<BarkodEkrani>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _controller = MobileScannerController();
  final _beep = AudioPlayer();
  final _hata = AudioPlayer();

  bool _isleniyor = false;
  String? _mesaj;

  // Aynı barkodun peş peşe tetiklenmesini engellemek için
  String? _sonKod;
  DateTime _sonOkuma = DateTime.fromMillisecondsSinceEpoch(0);
  static const _bekleme = Duration(seconds: 2);

  late final AnimationController _scanC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    // Sesleri önden yükle ki ilk okumada gecikme olmasın
    _beep
      ..setReleaseMode(ReleaseMode.stop)
      ..setVolume(1.0)
      ..setSource(AssetSource('sounds/beep.mp3'));
    _hata
      ..setReleaseMode(ReleaseMode.stop)
      ..setVolume(1.0)
      ..setSource(AssetSource('sounds/error.mp3'));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanC.dispose();
    _beep.dispose();
    _hata.dispose();
    super.dispose();
  }

  Future<void> _barkodOkundu(BarcodeCapture capture) async {
    if (_isleniyor) return;

    final kod = capture.barcodes.firstOrNull?.rawValue;
    if (kod == null || kod.isEmpty) return;

    // Aynı kod kısa süre içinde tekrar geldiyse yok say
    final simdi = DateTime.now();
    if (kod == _sonKod && simdi.difference(_sonOkuma) < _bekleme) return;
    _sonKod = kod;
    _sonOkuma = simdi;

    // Anında geri bildirim: sorgu sonucunu beklemeden
    unawaited(_beep.play(AssetSource('sounds/beep.mp3')));
    HapticFeedback.mediumImpact();

    setState(() {
      _isleniyor = true;
      _mesaj = 'Aranıyor: $kod';
    });

    try {
      final stok = await _api.getStokByBarkod(kod);
      if (!mounted) return;

      if (stok == null) {
        unawaited(_hata.play(AssetSource('sounds/error.mp3')));
        setState(() {
          _mesaj = 'Barkod eşleşmedi: $kod';
          _isleniyor = false;
        });
        return;
      }

      final stokNo = stok['STOK_NO'];
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StokDetayEkrani(
            stokNo: stokNo is int ? stokNo : int.tryParse('$stokNo') ?? 0,
            stokAdi: stok['STOK_ADI']?.toString() ?? '',
            stokKodu: stok['STOK_KODU']?.toString() ?? '',
          ),
        ),
      );

      if (mounted) {
        // Detaydan dönerken kamera hâlâ aynı barkoda bakıyor olabilir:
        // bekleme süresini yeniden başlat
        _sonOkuma = DateTime.now();
        setState(() {
          _isleniyor = false;
          _mesaj = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      unawaited(_hata.play(AssetSource('sounds/error.mp3')));
      setState(() {
        _mesaj = 'Hata: $e';
        _isleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Barkod Tara', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(controller: _controller, onDetect: _barkodOkundu),
                Container(color: Colors.black.withOpacity(0.35)),
                Center(
                  child: ClipPath(
                    clipper: _HoleClipper(),
                    child: Container(color: Colors.black.withOpacity(0.001)),
                  ),
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Stack(
                      children: [
                        _kose(Alignment.topLeft),
                        _kose(Alignment.topRight),
                        _kose(Alignment.bottomLeft),
                        _kose(Alignment.bottomRight),
                        AnimatedBuilder(
                          animation: _scanC,
                          builder: (context, _) => Align(
                            alignment: Alignment(0, -1 + 2 * _scanC.value),
                            child: Container(
                              height: 2,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.primary.withOpacity(0.9),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.7),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                _mesaj ?? 'Kamerayı barkoda tutun',
                key: ValueKey(_mesaj),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF9AA0AD)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kose(Alignment a) {
    final isTop = a.y < 0;
    final isLeft = a.x < 0;
    return Align(
      alignment: a,
      child: Container(
        width: 26,
        height: 26,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppColors.primary, width: 3)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _HoleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) =>
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}