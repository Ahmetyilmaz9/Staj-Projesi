import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/tahmin_service.dart';
import '../theme/app_theme.dart';
import '../widgets/fx.dart';

class TahminEkrani extends StatefulWidget {
  final int stokNo;
  final String? baslik;
  final double talepCarpani;
  const TahminEkrani({
    super.key,
    this.stokNo = 0,
    this.baslik,
    this.talepCarpani = 1.0,
  });

  @override
  State<TahminEkrani> createState() => _TahminEkraniState();
}

class _TahminEkraniState extends State<TahminEkrani> {
  final _service = TahminService();
  late Future<TahminSonucu> _future;
  late Future<DogrulukSonucu> _dogrulukFuture;
  int _gelecekGun = 90;
  late double _talepCarpani;

  @override
  void initState() {
    super.initState();
    _talepCarpani = widget.talepCarpani;
    _future = _service.getTahmin(
      gelecekGun: _gelecekGun,
      stokNo: widget.stokNo,
    );
    _dogrulukFuture = _service.getDogruluk(stokNo: widget.stokNo);
  }

  void _yenile(int gun) {
    setState(() {
      _gelecekGun = gun;
      _future = _service.getTahmin(gelecekGun: gun, stokNo: widget.stokNo);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          widget.baslik == null ? 'Talep Tahmini' : 'Tahmin · ${widget.baslik}',
        ),
      ),
      body: FutureBuilder<TahminSonucu>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text(
                    'Model eğitiliyor...',
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                ],
              ),
            );
          }
          if (snap.hasError || !snap.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tahmin alınamadı.\nPython servisi (port 8000) çalışıyor mu?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.inkMuted),
                ),
              ),
            );
          }
          final s = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FadeSlideIn(index: 0, child: _ufukSecici()),
              const SizedBox(height: 16),
              FadeSlideIn(index: 1, child: _senaryoSecici()),
              const SizedBox(height: 16),
              FadeSlideIn(index: 2, child: _grafikKarti(s)),
              const SizedBox(height: 16),
              FadeSlideIn(index: 3, child: _dogrulukKarti()),
              const SizedBox(height: 16),
              FadeSlideIn(index: 4, child: _ozetKarti(s)),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _senaryoSecici() {
    final yuzde = ((_talepCarpani - 1) * 100).round();
    return SoftCard(
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              'Talep senaryosu: ${yuzde >= 0 ? '+' : ''}$yuzde%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: _talepCarpani,
              min: 0.5,
              max: 1.5,
              divisions: 20,
              label: '$yuzde%',
              onChanged: (d) => setState(() => _talepCarpani = d),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ufukSecici() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [30, 90, 180].map((gun) {
          final secili = _gelecekGun == gun;
          return Expanded(
            child: GestureDetector(
              onTap: () => _yenile(gun),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: secili ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$gun gün',
                  style: TextStyle(
                    color: secili ? Colors.white : AppColors.inkMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _grafikKarti(TahminSonucu s) {
    if (s.veri.isEmpty) return const SizedBox();
    const gecmisGoster = 120;
    final baslangicIdx = (s.gecmisGun - gecmisGoster) < 0
        ? 0
        : (s.gecmisGun - gecmisGoster);
    final veri = s.veri.sublist(baslangicIdx);
    final sinirX = (s.gecmisGun - baslangicIdx).toDouble();

    final gercekSpots = <FlSpot>[];
    final tahminSpots = <FlSpot>[];
    final altSpots = <FlSpot>[];
    final ustSpots = <FlSpot>[];

    for (int i = 0; i < veri.length; i++) {
      final n = veri[i];
      final x = i.toDouble();
      final c = (n.gercek == null) ? _talepCarpani : 1.0;
      if (n.gercek != null) gercekSpots.add(FlSpot(x, n.gercek!));
      tahminSpots.add(FlSpot(x, n.tahmin * c));
      altSpots.add(FlSpot(x, n.alt * c));
      ustSpots.add(FlSpot(x, n.ust * c));
    }

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Satış Tahmini'),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Siyah: geçmiş gerçek · Mor: tahmin · Bant: %90 güven',
              style: TextStyle(fontSize: 11, color: AppColors.inkMuted),
            ),
          ),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                minY: 0,
                lineTouchData: const LineTouchData(enabled: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: AppColors.line, strokeWidth: 1),
                ),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  verticalLines: [
                    VerticalLine(
                      x: sinirX,
                      color: AppColors.warning,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: ustSpots,
                    isCurved: true,
                    color: Colors.transparent,
                    barWidth: 0,
                    dotData: const FlDotData(show: false),
                    aboveBarData: BarAreaData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.12),
                      applyCutOffY: true,
                      cutOffY: 0,
                    ),
                  ),
                  LineChartBarData(
                    spots: altSpots,
                    isCurved: true,
                    color: Colors.transparent,
                    barWidth: 0,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: true, color: Colors.white),
                  ),
                  LineChartBarData(
                    spots: tahminSpots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: gercekSpots,
                    isCurved: false,
                    color: Colors.transparent,
                    barWidth: 0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                            radius: 1.6,
                            color: AppColors.ink,
                            strokeWidth: 0,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozetKarti(TahminSonucu s) {
    final gelecek = s.veri.where((n) => n.gercek == null).toList();
    if (gelecek.isEmpty) return const SizedBox();
    final ortalama =
        gelecek.map((n) => n.tahmin * _talepCarpani).reduce((a, b) => a + b) /
        gelecek.length;
    final ilk = gelecek.first.tahmin * _talepCarpani;
    final son = gelecek.last.tahmin * _talepCarpani;
    final degisim = ilk == 0 ? 0.0 : ((son - ilk) / ilk * 100);

    return SoftCard(
      child: Row(
        children: [
          _ozetHucre('Ortalama Talep', ortalama, AppColors.ink),
          _ozetHucre('Dönem Sonu', son, AppColors.success),
          _ozetHucreYuzde(
            'Değişim',
            degisim,
            degisim >= 0 ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _ozetHucre(String etiket, double deger, Color renk) {
    return Expanded(
      child: Column(
        children: [
          AnimatedCounterText(
            value: deger,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: renk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiket.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.inkMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozetHucreYuzde(String etiket, double deger, Color renk) {
    return Expanded(
      child: Column(
        children: [
          AnimatedCounterText(
            value: deger,
            decimals: 1,
            suffix: '%',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              color: renk,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            etiket.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.inkMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dogrulukKarti() {
    return FutureBuilder<DogrulukSonucu>(
      future: _dogrulukFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SoftCard(
            child: Center(
              child: Text(
                'Doğruluk hesaplanıyor...',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),
            ),
          );
        }
        if (snap.hasError) {
          return SoftCard(
            child: Text(
              'Doğruluk alınamadı: ${snap.error}',
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          );
        }
        if (!snap.hasData) return const SizedBox();
        final d = snap.data!;
        final renk = d.mape == null
            ? AppColors.inkMuted
            : d.mape! < 10
            ? AppColors.success
            : d.mape! < 20
            ? AppColors.warning
            : AppColors.danger;

        return SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fact_check_outlined, size: 18, color: renk),
                  const SizedBox(width: 8),
                  const Text(
                    'MODEL DOĞRULUĞU (BACKTEST)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Son ${d.testGun} gün eğitimden saklandı; model ${d.egitimGun} günle eğitilip o dönemi tahmin etti.',
                style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ozetHucreYuzde('Ort. Sapma (MAPE)', d.mape ?? 0, renk),
                  _ozetHucre('Ort. Hata (MAE)', d.mae, AppColors.ink),
                  _ozetHucreYuzde('Bant Kapsama', d.kapsama, AppColors.info),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
