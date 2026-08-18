import 'package:flutter/material.dart';
import 'package:staj_proje/screens/barkod_ekrani.dart';
import 'package:staj_proje/screens/tahmin_ekrani.dart';
import 'dashboard_ekrani.dart';
import 'stok_liste_ekrani.dart';
import '../theme/app_theme.dart';

class AnaKabuk extends StatefulWidget {
  const AnaKabuk({super.key});

  @override
  State<AnaKabuk> createState() => _AnaKabukState();
}

class _AnaKabukState extends State<AnaKabuk> {
  int _index = 0;

  final _sayfalar = const [
    DashboardEkrani(),
    StokListeEkrani(),
    TahminEkrani(),
    BarkodEkrani(),
  ];

  final _items = const [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Genel Bakış'),
    (Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Stok'),
    (Icons.trending_up_outlined, Icons.trending_up_rounded, 'Tahmin'),
    (Icons.qr_code_scanner_outlined, Icons.qr_code_scanner_rounded, 'Tara'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: IndexedStack(index: _index, children: _sayfalar),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.navBg,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final secili = i == _index;
              final it = _items[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _index = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: secili ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          secili ? it.$2 : it.$1,
                          color: secili
                              ? Colors.white
                              : const Color(0xFF9AA0AD),
                          size: 22,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: secili
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    it.$3,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              : const SizedBox(height: 0),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
