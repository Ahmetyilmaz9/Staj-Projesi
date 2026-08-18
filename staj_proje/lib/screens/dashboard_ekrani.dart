import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import 'stok_detay_ekrani.dart';
import '../services/auth_service.dart';
import 'login_ekrani.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';

class DashboardEkrani extends StatefulWidget {
  const DashboardEkrani({super.key});

  @override
  State<DashboardEkrani> createState() => _DashboardEkraniState();
}

class _DashboardEkraniState extends State<DashboardEkrani> {
  final _api = ApiService();
  late Future<_DashboardVerisi> _future;

  @override
  void initState() {
    super.initState();
    _future = _yukle();
  }

  Future<_DashboardVerisi> _yukle() async {
    final liste = await _api.getStokListesi();
    liste.removeWhere((s) => (s['STOK_NO'] ?? 0) == 0);
    return _DashboardVerisi.hesapla(liste);
  }

  Future<void> _yenile() async {
    setState(() => _future = _yukle());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<_DashboardVerisi>(
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
                'Veri alınamadı. API çalışıyor mu?',
                style: TextStyle(color: AppColors.inkMuted),
              ),
            );
          }
          final v = snap.data!;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _yenile,
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppColors.bg,
                  pinned: true,
                  elevation: 0,
                  title: const Text('Genel Bakış'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _yenile,
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_rounded),
                      tooltip: 'Çıkış (${AuthService().kullaniciAdi ?? ''})',
                      onPressed: () {
                        AuthService().cikis();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginEkrani(),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FadeSlideIn(index: 0, child: _kpiIzgarasi(v)),
                      const SizedBox(height: 20),
                      FadeSlideIn(index: 1, child: _grafikKarti(v)),
                      const SizedBox(height: 20),
                      FadeSlideIn(index: 2, child: _kritikListesi(v)),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kpiIzgarasi(_DashboardVerisi v) {
    final kartlar = [
      _KpiVeri(
        'Toplam Kalem',
        v.toplam.toDouble(),
        AppColors.ink,
        Icons.inventory_2_outlined,
      ),
      _KpiVeri(
        'Kritik',
        v.kritik.toDouble(),
        AppColors.danger,
        Icons.warning_amber_rounded,
      ),
      _KpiVeri(
        'Düşük Stok',
        v.uyari.toDouble(),
        AppColors.warning,
        Icons.trending_down,
      ),
      _KpiVeri(
        'Negatif Stok',
        v.negatif.toDouble(),
        const Color(0xFF7A2E8F),
        Icons.remove_circle_outline,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final genislik = (c.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kartlar
              .map((k) => SizedBox(width: genislik, child: _kpiKarti(k)))
              .toList(),
        );
      },
    );
  }

  Widget _kpiKarti(_KpiVeri k) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: k.renk.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(k.ikon, color: k.renk, size: 18),
          ),
          const SizedBox(height: 14),
          AnimatedCounterText(
            value: k.deger,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: k.renk,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            k.etiket.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.inkMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grafikKarti(_DashboardVerisi v) {
    final dilimler = [
      ('Kritik', v.kritik, AppColors.danger),
      ('Düşük', v.uyari, AppColors.warning),
      ('Normal', v.normal, AppColors.success),
      ('Limitsiz', v.limitsiz, AppColors.inkMuted),
    ].where((d) => d.$2 > 0).toList();

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Durum Dağılımı'),
          if (dilimler.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Gösterilecek veri yok.',
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: Row(
                children: [
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, _) => PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 42,
                          sections: dilimler
                              .map(
                                (d) => PieChartSectionData(
                                  value: d.$2 * t,
                                  color: d.$3,
                                  title: '${d.$2}',
                                  radius: 44,
                                  titleStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dilimler.map((d) => _lejant(d.$1, d.$3)).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _lejant(String etiket, Color renk) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: renk,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            etiket,
            style: const TextStyle(fontSize: 13, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _kritikListesi(_DashboardVerisi v) {
    if (v.enKritikler.isEmpty) {
      return SoftCard(
        child: const Center(
          child: Text(
            'Kritik stok yok. Her şey yolunda.',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('En Kritik Ürünler'),
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < v.enKritikler.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.line),
                Builder(
                  builder: (_) {
                    final s = v.enKritikler[i];
                    final miktar = (s['MIKTAR'] ?? 0) as num;
                    final stokNo = s['STOK_NO'] ?? 0;
                    final kod = s['STOK_KODU']?.toString() ?? '-';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      title: Text(
                        s['STOK_ADI']?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        kod,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                      trailing: Text(
                        miktar.toStringAsFixed(miktar % 1 == 0 ? 0 : 2),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: AppColors.danger,
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
                              stokAdi: s['STOK_ADI']?.toString() ?? '',
                              stokKodu: kod,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardVerisi {
  final int toplam, kritik, uyari, normal, limitsiz, negatif;
  final List<Map<String, dynamic>> enKritikler;

  _DashboardVerisi({
    required this.toplam,
    required this.kritik,
    required this.uyari,
    required this.normal,
    required this.limitsiz,
    required this.negatif,
    required this.enKritikler,
  });

  factory _DashboardVerisi.hesapla(List<Map<String, dynamic>> liste) {
    int kritik = 0, uyari = 0, normal = 0, limitsiz = 0, negatif = 0;
    for (final s in liste) {
      final d = s['LIMIT_DURUMU']?.toString() ?? 'YOK';
      final m = (s['MIKTAR'] ?? 0) as num;
      if (m < 0) negatif++;
      switch (d) {
        case 'KRITIK':
          kritik++;
          break;
        case 'UYARI':
          uyari++;
          break;
        case 'NORMAL':
          normal++;
          break;
        case 'FAZLA':
          normal++;
          break;
        default:
          limitsiz++;
      }
    }

    final kritikler = liste.where((s) => s['LIMIT_DURUMU'] == 'KRITIK').toList()
      ..sort(
        (a, b) =>
            ((a['MIKTAR'] ?? 0) as num).compareTo((b['MIKTAR'] ?? 0) as num),
      );

    return _DashboardVerisi(
      toplam: liste.length,
      kritik: kritik,
      uyari: uyari,
      normal: normal,
      limitsiz: limitsiz,
      negatif: negatif,
      enKritikler: kritikler.take(5).toList(),
    );
  }
}

class _KpiVeri {
  final String etiket;
  final double deger;
  final Color renk;
  final IconData ikon;
  _KpiVeri(this.etiket, this.deger, this.renk, this.ikon);
}
