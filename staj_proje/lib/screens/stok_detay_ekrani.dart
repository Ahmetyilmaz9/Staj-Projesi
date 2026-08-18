import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/tahmin_service.dart';
import 'tahmin_ekrani.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';

class StokDetayEkrani extends StatefulWidget {
  final int stokNo;
  final String stokAdi;
  final String stokKodu;

  const StokDetayEkrani({
    super.key,
    required this.stokNo,
    required this.stokAdi,
    required this.stokKodu,
  });

  @override
  State<StokDetayEkrani> createState() => _StokDetayEkraniState();
}

class _StokDetayEkraniState extends State<StokDetayEkrani>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late final TabController _tab;
  late Future<_DetaySayfaVerisi> _future;

  Map<String, dynamic>? _secilenBirim;
  List<Map<String, dynamic>> _birimler = const [];

  double _talepCarpani = 1.0;
  OneriSonucu? _oneriGuncel;
  bool _oneriYukleniyor = false;
  bool _senaryoAcik = false;
  int _hareketSekmesi = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _future = _tumVeriyiYukle();
    // Birim seçici AppBar'da olduğu için veriyi ayrıca state'e alıyoruz.
    _future
        .then((v) {
          if (mounted) setState(() => _birimler = v.birimler);
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- veri

  Future<_DetaySayfaVerisi> _tumVeriyiYukle() async {
    final sonuclar = await Future.wait([
      _api.getDurum(widget.stokNo).catchError((_) => null),
      _api.getDetay(widget.stokNo).catchError((_) => null),
      _api
          .getKonumlar(widget.stokNo)
          .catchError((_) => <Map<String, dynamic>>[]),
      _api
          .getHareketler(widget.stokNo)
          .catchError((_) => <Map<String, dynamic>>[]),
      _api
          .getAlisSatis(widget.stokNo)
          .catchError((_) => <Map<String, dynamic>>[]),
      _api.getUyumlu(widget.stokNo).catchError((_) => <Map<String, dynamic>>[]),
      _api.getLimit(widget.stokNo).catchError((_) => null),
      _api
          .getBirimler(widget.stokNo)
          .catchError((_) => <Map<String, dynamic>>[]),
    ]);

    final durum = sonuclar[0] as Map<String, dynamic>?;
    final limit = sonuclar[6] as Map<String, dynamic>?;

    OneriSonucu? oneri;
    if (limit != null) {
      try {
        oneri = await TahminService().getOneri(
          mevcut: ((durum?['MIKTAR'] ?? 0) as num).toDouble(),
          asgari: ((limit['ASGARI'] ?? 0) as num).toDouble(),
          normal: ((limit['NORMAL'] ?? 0) as num).toDouble(),
          stokNo: widget.stokNo,
        );
      } catch (_) {}
    }

    return _DetaySayfaVerisi(
      durum: durum,
      detay: sonuclar[1] as Map<String, dynamic>?,
      konumlar: sonuclar[2] as List<Map<String, dynamic>>,
      hareketler: sonuclar[3] as List<Map<String, dynamic>>,
      alisSatis: sonuclar[4] as List<Map<String, dynamic>>,
      uyumlu: sonuclar[5] as List<Map<String, dynamic>>,
      limit: limit,
      birimler: sonuclar[7] as List<Map<String, dynamic>>,
      oneri: oneri,
    );
  }

  Future<void> _senaryoGuncelle(double carpan, _DetaySayfaVerisi v) async {
    setState(() {
      _talepCarpani = carpan;
      _oneriYukleniyor = true;
    });
    try {
      final yeni = await TahminService().getOneri(
        mevcut: ((v.durum?['MIKTAR'] ?? 0) as num).toDouble(),
        asgari: ((v.limit?['ASGARI'] ?? 0) as num).toDouble(),
        normal: ((v.limit?['NORMAL'] ?? 0) as num).toDouble(),
        stokNo: widget.stokNo,
        talepCarpani: carpan,
      );
      if (mounted) {
        setState(() {
          _oneriGuncel = yeni;
          _oneriYukleniyor = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _oneriYukleniyor = false);
    }
  }

  // ---------------------------------------------------------------- birim

  double get _katsayi {
    final k = _secilenBirim?['KATSAYI'];
    final d = (k is num) ? k.toDouble() : 1.0;
    return d == 0 ? 1.0 : d;
  }

  String get _birimEtiketi => _secilenBirim?['BIRIM']?.toString() ?? '';

  String get _aktifBirimAdi {
    if (_secilenBirim != null) return _birimEtiketi;
    for (final b in _birimler) {
      if (b['TEMEL_BIRIM_MI'] == true) return b['BIRIM']?.toString() ?? '';
    }
    return '';
  }

  String _birimliFmt(dynamic v) {
    if (v == null) return '-';
    if (v is num) {
      final c = v / _katsayi;
      final s = c.toStringAsFixed(c % 1 == 0 ? 0 : 2);
      return _birimEtiketi.isEmpty ? s : '$s $_birimEtiketi';
    }
    return v.toString();
  }

  Widget _birimSecici() {
    if (_birimler.isEmpty) return const SizedBox.shrink();
    final ad = _aktifBirimAdi;
    return PopupMenuButton<Map<String, dynamic>>(
      tooltip: 'Birim seç',
      onSelected: (b) => setState(() => _secilenBirim = b),
      itemBuilder: (_) => [
        for (final b in _birimler)
          PopupMenuItem<Map<String, dynamic>>(
            value: b,
            height: 40,
            child: Row(
              children: [
                Icon(
                  (_secilenBirim != null
                          ? _secilenBirim!['BIRIM'] == b['BIRIM']
                          : b['TEMEL_BIRIM_MI'] == true)
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(b['BIRIM']?.toString() ?? '-'),
                const SizedBox(width: 14),
                Text(
                  _fmt(b['CEVRILMIS_MIKTAR']),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ad.isEmpty ? 'Birim' : ad,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'stok-${widget.stokKodu}',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  widget.stokAdi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            Text(
              widget.stokKodu,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
        actions: [_birimSecici()],
      ),
      body: FutureBuilder<_DetaySayfaVerisi>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(
              child: Text(
                'Veri alınamadı.',
                style: TextStyle(color: AppColors.inkMuted),
              ),
            );
          }
          final v = snap.data!;
          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(
                child: FadeSlideIn(index: 0, child: _ozetKarti(v)),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SabitTabBar(
                  TabBar(
                    controller: _tab,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.inkMuted,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelPadding: EdgeInsets.zero,
                    labelStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 12.5),
                    tabs: [
                      const Tab(height: 40, text: 'Özet'),
                      Tab(height: 40, text: 'Konum (${v.konumlar.length})'),
                      Tab(
                        height: 40,
                        text:
                            'Hareket (${v.hareketler.length + v.alisSatis.length})',
                      ),
                      Tab(height: 40, text: 'Uyumlu (${v.uyumlu.length})'),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tab,
              children: [
                _ozetSekmesi(v),
                _konumSekmesi(v.konumlar),
                _hareketSekmesiIcerik(v),
                _uyumluSekmesi(v.uyumlu),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------ özet kartı

  ({String etiket, Color renk, IconData ikon, double ratio}) _durumBilgisi(
    Map<String, dynamic>? limit,
    num miktar,
  ) {
    if (limit == null) {
      return (
        etiket: 'LİMİT TANIMSIZ',
        renk: AppColors.info,
        ikon: Icons.info_outline_rounded,
        ratio: 0,
      );
    }
    final asgari = (limit['ASGARI'] ?? 0) as num;
    final normal = (limit['NORMAL'] ?? 0) as num;
    final azami = (limit['AZAMI'] ?? 0) as num;

    if (azami > 0 && miktar > azami) {
      return (
        etiket: 'AZAMİ ÜSTÜ',
        renk: AppColors.info,
        ikon: Icons.trending_up_rounded,
        ratio: 1,
      );
    }
    if (miktar <= asgari) {
      return (
        etiket: 'KRİTİK SEVİYE',
        renk: AppColors.danger,
        ikon: Icons.warning_amber_rounded,
        ratio: asgari <= 0 ? 0 : (miktar / asgari).clamp(0, 1).toDouble(),
      );
    }
    if (normal > 0 && miktar < normal) {
      return (
        etiket: 'DÜŞÜK STOK',
        renk: AppColors.warning,
        ikon: Icons.info_outline_rounded,
        ratio: (miktar / normal).clamp(0, 1).toDouble(),
      );
    }
    return (
      etiket: 'NORMAL',
      renk: AppColors.success,
      ikon: Icons.check_circle_outline_rounded,
      ratio: azami > 0 ? (miktar / azami).clamp(0, 1).toDouble() : 1,
    );
  }

  Widget _ozetKarti(_DetaySayfaVerisi v) {
    final miktar = (v.durum?['MIKTAR'] ?? 0) as num;
    final d = _durumBilgisi(v.limit, miktar);
    final o = _oneriGuncel ?? v.oneri;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
      decoration: BoxDecoration(
        color: d.renk.withOpacity(0.07),
        border: Border.all(color: d.renk.withOpacity(0.28)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(d.ikon, color: d.renk, size: 18),
              const SizedBox(width: 6),
              Text(
                d.etiket,
                style: TextStyle(
                  color: d.renk,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                _birimliFmt(miktar),
                style: TextStyle(
                  color: d.renk,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  fontSize: 15,
                ),
              ),
            ],
          ),
          if (v.limit != null) ...[
            const SizedBox(height: 8),
            AnimatedGauge(ratio: d.ratio, color: d.renk),
            const SizedBox(height: 7),
            Row(
              children: [
                _esik('ASG', v.limit!['ASGARI'], AppColors.danger),
                _esik('NRM', v.limit!['NORMAL'], AppColors.success),
                _esik('AZM', v.limit!['AZAMI'], AppColors.info),
              ],
            ),
          ],
          if (o != null) ...[
            const Divider(height: 16, color: AppColors.line),
            _oneriSatiri(o, v),
            if (_senaryoAcik) _senaryoPaneli(o, v),
          ],
        ],
      ),
    );
  }

  Widget _esik(String etiket, dynamic deger, Color renk) => Expanded(
    child: Row(
      children: [
        Text(
          etiket,
          style: const TextStyle(fontSize: 9.5, color: AppColors.inkMuted),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _birimliFmt(deger),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: renk,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _oneriSatiri(OneriSonucu o, _DetaySayfaVerisi v) {
    final tukenecek = o.kritikTarih != null;
    final renk = tukenecek ? AppColors.warning : AppColors.success;
    return InkWell(
      onTap: () => setState(() => _senaryoAcik = !_senaryoAcik),
      child: Row(
        children: [
          Icon(
            tukenecek
                ? Icons.schedule_rounded
                : Icons.check_circle_outline_rounded,
            size: 16,
            color: renk,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              tukenecek
                  ? '${o.kalanGun} günde tükenir · öneri ${_birimliFmt(o.onerilenSiparis)}'
                  : '90 gün yeterli · dönem sonu ${_birimliFmt(o.donemSonuStok)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_oneriYukleniyor)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: 'Tahmini gör',
            icon: Icon(Icons.show_chart_rounded, size: 18, color: renk),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TahminEkrani(
                  stokNo: widget.stokNo,
                  baslik: widget.stokAdi,
                  talepCarpani: _talepCarpani,
                ),
              ),
            ),
          ),
          Icon(
            _senaryoAcik ? Icons.expand_less : Icons.expand_more,
            size: 18,
            color: AppColors.inkMuted,
          ),
        ],
      ),
    );
  }

  Widget _senaryoPaneli(OneriSonucu o, _DetaySayfaVerisi v) {
    final renk = o.kritikTarih != null ? AppColors.warning : AppColors.success;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 32,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: renk,
              thumbColor: renk,
              trackHeight: 3,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(
              value: _talepCarpani,
              min: 0.5,
              max: 1.5,
              divisions: 20,
              label: '${((_talepCarpani - 1) * 100).round()}%',
              onChanged: (deger) => setState(() => _talepCarpani = deger),
              onChangeEnd: (deger) => _senaryoGuncelle(deger, v),
            ),
          ),
        ),
        Row(
          children: [
            _oneriHucre(
              'Talep senaryosu',
              '${_talepCarpani >= 1 ? '+' : ''}${((_talepCarpani - 1) * 100).round()}%',
            ),
            _oneriHucre('Tahmini talep', _birimliFmt(o.toplamTalep)),
            _oneriHucre('Dönem sonu', _birimliFmt(o.donemSonuStok)),
            _oneriHucre('Öneri', _birimliFmt(o.onerilenSiparis), renk: renk),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          '* Tahmin, demo amaçlı sentetik satış geçmişine dayanır.',
          style: TextStyle(fontSize: 9.5, color: AppColors.inkMuted),
        ),
      ],
    );
  }

  Widget _oneriHucre(String etiket, String deger, {Color? renk}) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiket.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 8.5,
            color: AppColors.inkMuted,
            letterSpacing: 0.3,
          ),
        ),
        Text(
          deger,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            color: renk ?? AppColors.ink,
          ),
        ),
      ],
    ),
  );

  // ------------------------------------------------------------ sekmeler

  Widget _ozetSekmesi(_DetaySayfaVerisi v) {
    final d = v.durum;
    final det = v.detay;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
      children: [
        if (d != null)
          _izgara('Stok Durumu', [
            ('Rezerv', _birimliFmt(d['REZERV_MIKTAR'])),
            ('Alış sipariş', _birimliFmt(d['ALIS_SIPARIS_MIKTAR'])),
            ('Satış sipariş', _birimliFmt(d['SATIS_SIPARIS_MIKTAR'])),
            ('Çeki sayısı', _fmt(d['CEKI_SAYISI'])),
          ], mono: true),
        if (det != null)
          _izgara('Stok Detayı', [
            ('Stok kodu', _fmt(det['STOK_KODU'])),
            ('Birim', _fmt(det['BIRIM1'])),
            ('Stok tipi', _fmt(det['STOK_TIP_ADI'])),
            ('Marka', _fmt(det['MARKA_ADI'])),
            ('Üretici kodu', _fmt(det['URETICI_KODU'])),
            ('Menşei', _fmt(det['MENSEI'])),
            ('Sorumluluk alanı', _fmt(det['SORUMLULUK_ALANI_ADI'])),
            ('Genel ad', _fmt(det['STOK_ADI_GENEL'])),
          ]),
        if (d == null && det == null) _bos('Bilgi bulunamadı.'),
      ],
    );
  }

  Widget _izgara(
    String baslik,
    List<(String, String)> ogeler, {
    bool mono = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _kucukBaslik(baslik),
        LayoutBuilder(
          builder: (_, c) {
            final w = (c.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in ogeler)
                  SizedBox(width: w, child: _hucre(o.$1, o.$2, mono)),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _hucre(String etiket, String deger, bool mono) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          etiket.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.inkMuted,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          deger,
          maxLines: mono ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: mono ? 'monospace' : null,
          ),
        ),
      ],
    ),
  );

  Widget _konumSekmesi(List<Map<String, dynamic>> liste) {
    if (liste.isEmpty) return _bos('Depo bilgisi yok.');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 24),
      itemCount: liste.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.line),
      itemBuilder: (_, i) {
        final k = liste[i];
        final durum = k['LIMIT_DURUMU']?.toString() ?? 'YOK';
        final kaynak = k['LIMIT_KAYNAGI']?.toString();
        final renk = AppTheme.statusColor(durum);
        final uyari = durum == 'KRITIK' || durum == 'UYARI';
        return _satir(
          solCizgi: uyari ? renk : null,
          baslik: k['STOK_YERI_ADI']?.toString() ?? '-',
          alt: k['ASGARI'] != null
              ? 'Asgari ${_birimliFmt(k['ASGARI'])}'
                    '${kaynak == 'DEPO' ? ' · depoya özel' : ''}'
              : null,
          rozet: uyari
              ? StatusChip(
                  durum: durum,
                  label: durum == 'KRITIK' ? 'KRİTİK' : 'AZ',
                )
              : null,
          sag: _birimliFmt(k['MIKTAR']),
          sagRenk: uyari ? renk : null,
        );
      },
    );
  }

  Widget _hareketSekmesiIcerik(_DetaySayfaVerisi v) {
    final liste = _hareketSekmesi == 0 ? v.hareketler : v.alisSatis;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 24),
      itemCount: liste.isEmpty ? 2 : liste.length + 1,
      itemBuilder: (_, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Row(
              children: [
                _miniSekme('Stok', 0, v.hareketler.length),
                const SizedBox(width: 8),
                _miniSekme('Alış-Satış', 1, v.alisSatis.length),
              ],
            ),
          );
        }
        if (liste.isEmpty) return _bos('Kayıt yok.');
        final e = liste[i - 1];
        final ust = i > 1
            ? const Divider(height: 1, color: AppColors.line)
            : const SizedBox.shrink();

        if (_hareketSekmesi == 0) {
          final mx = (e['MX_MIKTAR'] ?? 0) as num;
          return Column(
            children: [
              ust,
              _satir(
                baslik: e['A_ISLEM_KODU']?.toString() ?? '-',
                alt:
                    '${_tarih(e['TARIH'])} · ${e['CARI_ADI'] ?? e['STOK_YERI_ADI'] ?? '-'}',
                sag: '${mx >= 0 ? '+' : ''}${_birimliFmt(mx)}',
                sagRenk: mx >= 0 ? AppColors.success : AppColors.danger,
              ),
            ],
          );
        }
        return Column(
          children: [
            ust,
            _satir(
              baslik:
                  e['A_ISLEM_ADI']?.toString() ??
                  e['A_ISLEM_KODU']?.toString() ??
                  '-',
              alt: '${_tarih(e['A_TARIH'])} · ${e['CARI_ADI'] ?? '-'}',
              sag: _birimliFmt(e['MIKTAR']),
              sagAlt: '₺${_fmt(e['BIRIM_FIYAT_KDV'])}',
            ),
          ],
        );
      },
    );
  }

  Widget _miniSekme(String etiket, int deger, int adet) {
    final secili = _hareketSekmesi == deger;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _hareketSekmesi = deger),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: secili ? AppColors.primarySoft : Colors.transparent,
          border: Border.all(
            color: secili ? AppColors.primary : AppColors.line,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$etiket · $adet',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: secili ? AppColors.primary : AppColors.inkMuted,
          ),
        ),
      ),
    );
  }

  Widget _uyumluSekmesi(List<Map<String, dynamic>> liste) {
    if (liste.isEmpty) return _bos('Uyumlu stok yok.');
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 24),
      itemCount: liste.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppColors.line),
      itemBuilder: (_, i) {
        final u = liste[i];
        return _satir(
          baslik: u['STOK_ADI']?.toString() ?? '-',
          alt: u['STOK_KODU']?.toString() ?? '-',
          sag: u['VARYANT_ADI']?.toString() ?? '',
          sagRenk: AppColors.inkMuted,
        );
      },
    );
  }

  // ------------------------------------------------------------ parçalar

  Widget _kucukBaslik(String metin) => Padding(
    padding: const EdgeInsets.only(bottom: 6, left: 2),
    child: Text(
      metin.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: AppColors.inkMuted,
      ),
    ),
  );

  Widget _bos(String mesaj) => Padding(
    padding: const EdgeInsets.all(20),
    child: Text(
      mesaj,
      style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
    ),
  );

  /// Yoğun liste satırı — ListTile yerine (~46 px, ListTile ~68 px).
  Widget _satir({
    required String baslik,
    String? alt,
    required String sag,
    String? sagAlt,
    Color? sagRenk,
    Widget? rozet,
    Color? solCizgi,
    VoidCallback? onTap,
  }) {
    final ic = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        baslik,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (rozet != null) ...[const SizedBox(width: 6), rozet],
                  ],
                ),
                if (alt != null)
                  Text(
                    alt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sag,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: sagRenk ?? AppColors.ink,
                ),
              ),
              if (sagAlt != null)
                Text(
                  sagAlt,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.inkMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    final govde = solCizgi == null
        ? ic
        : Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: solCizgi, width: 3)),
            ),
            child: ic,
          );

    return onTap == null ? govde : InkWell(onTap: onTap, child: govde);
  }
}

// -------------------------------------------------------------- yardımcılar

class _SabitTabBar extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _SabitTabBar(this.tabBar);

  @override
  double get minExtent => 40;
  @override
  double get maxExtent => 40;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: AppColors.bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 39, child: tabBar),
          const Divider(height: 1, color: AppColors.line),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SabitTabBar old) => old.tabBar != tabBar;
}

class _DetaySayfaVerisi {
  final Map<String, dynamic>? durum;
  final Map<String, dynamic>? detay;
  final List<Map<String, dynamic>> konumlar;
  final List<Map<String, dynamic>> hareketler;
  final List<Map<String, dynamic>> alisSatis;
  final List<Map<String, dynamic>> uyumlu;
  final Map<String, dynamic>? limit;
  final List<Map<String, dynamic>> birimler;
  final OneriSonucu? oneri;

  _DetaySayfaVerisi({
    required this.durum,
    required this.detay,
    required this.konumlar,
    required this.hareketler,
    required this.alisSatis,
    required this.uyumlu,
    required this.limit,
    required this.birimler,
    required this.oneri,
  });
}

String _fmt(dynamic v) {
  if (v == null) return '-';
  if (v is num) return v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
  return v.toString();
}

String _tarih(dynamic v) {
  if (v == null) return '-';
  final s = v.toString();
  final dt = DateTime.tryParse(s);
  if (dt == null) return s;
  return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}
