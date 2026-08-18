import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'stok_detay_ekrani.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';

class StokListeEkrani extends StatefulWidget {
  const StokListeEkrani({super.key});

  @override
  State<StokListeEkrani> createState() => _StokListeEkraniState();
}

class _StokListeEkraniState extends State<StokListeEkrani> {
  final _api = ApiService();
  final _aramaController = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _stoklar = [];
  bool _yukleniyor = true; // ilk açılış: tam ekran spinner
  bool _aramaYukleniyor = false; // arama: liste kalsın, ince çubuk çıksın
  String? _hata;
  bool _sadeceKritik = false;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _aramaController.dispose();
    super.dispose();
  }

  Future<void> _yukle({String? ad, bool sessiz = false}) async {
    setState(() {
      if (sessiz) {
        _aramaYukleniyor = true;
      } else {
        _yukleniyor = true;
      }
      _hata = null;
    });
    try {
      final liste = await _api.getStokListesi(ad: ad);
      liste.removeWhere((s) => (s['STOK_NO'] ?? 0) == 0);
      if (!mounted) return;
      setState(() {
        _stoklar = liste;
        _yukleniyor = false;
        _aramaYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = 'Liste yüklenemedi. API çalışıyor mu?';
        _yukleniyor = false;
        _aramaYukleniyor = false;
      });
    }
  }

  // 350 ms debounce: her harfte istek atılmasını engeller — performans için kalıyor.
  void _aramaDegisti(String deger) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _yukle(ad: deger.trim(), sessiz: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gosterilen = _sadeceKritik
        ? _stoklar.where((s) {
            final d = s['LIMIT_DURUMU']?.toString();
            return d == 'KRITIK' || d == 'UYARI';
          }).toList()
        : _stoklar;

    final kritikSayisi = _stoklar
        .where((s) => s['LIMIT_DURUMU'] == 'KRITIK')
        .length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Stok Kontrol')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _aramaController,
                  onChanged: _aramaDegisti,
                  decoration: const InputDecoration(
                    hintText: 'Ürün adına göre ara...',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ),
                SizedBox(
                  height: 2,
                  child: _aramaYukleniyor
                      ? const LinearProgressIndicator(
                          minHeight: 2,
                          color: AppColors.primary,
                          backgroundColor: Colors.transparent,
                        )
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: Text(
                        kritikSayisi > 0
                            ? 'Sadece kritik ($kritikSayisi)'
                            : 'Sadece kritik',
                      ),
                      selected: _sadeceKritik,
                      onSelected: (v) => setState(() => _sadeceKritik = v),
                      backgroundColor: AppColors.surfaceAlt,
                      selectedColor: AppColors.danger,
                      labelStyle: TextStyle(
                        color: _sadeceKritik
                            ? Colors.white
                            : AppColors.inkMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      checkmarkColor: Colors.white,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _govde(gosterilen)),
        ],
      ),
    );
  }

  Widget _govde(List<Map<String, dynamic>> gosterilen) {
    if (_yukleniyor) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_hata != null) {
      return Center(
        child: Text(_hata!, style: const TextStyle(color: AppColors.inkMuted)),
      );
    }
    if (gosterilen.isEmpty) {
      return const Center(
        child: Text(
          'Eşleşen ürün bulunamadı.',
          style: TextStyle(color: AppColors.inkMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: gosterilen.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = gosterilen[i];
        final stokNo = s['STOK_NO'] ?? 0;
        final kod = s['STOK_KODU']?.toString() ?? '';
        final ad = s['STOK_ADI']?.toString() ?? '';
        final birim = s['BIRIM1']?.toString() ?? '';
        final miktar = (s['MIKTAR'] ?? 0) as num;
        final durum = s['LIMIT_DURUMU']?.toString() ?? 'YOK';
        final renk = AppTheme.statusColor(durum);
        final uyariVar =
            durum == 'KRITIK' || durum == 'UYARI' || durum == 'FAZLA';

        return SoftCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 2,
            ),
            tileColor: _durumArkaPlan(durum, renk),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: uyariVar
                  ? BorderSide(color: renk.withOpacity(0.35))
                  : BorderSide.none,
            ),
            title: Row(
              children: [
                Flexible(
                  child: Hero(
                    tag: 'stok-$kod',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        ad,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: durum == 'KRITIK' ? renk : null,
                        ),
                      ),
                    ),
                  ),
                ),
                if (durum != 'YOK' && durum != 'NORMAL') ...[
                  const SizedBox(width: 8),
                  StatusChip(
                    durum: durum,
                    label: durum == 'KRITIK'
                        ? 'KRİTİK'
                        : durum == 'UYARI'
                        ? 'AZ'
                        : durum,
                  ),
                ],
              ],
            ),
            subtitle: Text(
              '$kod  ·  $birim',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppColors.inkMuted,
              ),
            ),
            trailing: Text(
              miktar.toStringAsFixed(miktar % 1 == 0 ? 0 : 2),
              style: TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: renk,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StokDetayEkrani(
                    stokNo: stokNo is int
                        ? stokNo
                        : int.tryParse('$stokNo') ?? 0,
                    stokAdi: ad,
                    stokKodu: kod,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Satır arka planı — kritik en belirgin, normal/limitsiz nötr kalır.
  Color _durumArkaPlan(String durum, Color renk) {
    switch (durum) {
      case 'KRITIK':
        return renk.withOpacity(0.14);
      case 'UYARI':
        return renk.withOpacity(0.09);
      case 'FAZLA':
        return renk.withOpacity(0.07);
      default:
        return Colors.transparent; // NORMAL ve YOK: kart beyaz kalsın
    }
  }
}
