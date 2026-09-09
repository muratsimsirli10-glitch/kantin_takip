import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const KantinUygulamasi());
}

class KantinUygulamasi extends StatefulWidget {
  const KantinUygulamasi({super.key});

  @override
  State<KantinUygulamasi> createState() => _KantinUygulamasiState();
}

class _KantinUygulamasiState extends State<KantinUygulamasi> {
  ThemeMode _themeMode = ThemeMode.light;

  void _temaDegistir() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kantin Defteri',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: AnaSayfa(
        onTemaDegistir: _temaDegistir,
        isDark: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  final VoidCallback onTemaDegistir;
  final bool isDark;

  const AnaSayfa({
    super.key,
    required this.onTemaDegistir,
    required this.isDark,
  });

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final TextEditingController _kisiController = TextEditingController();

  Map<String, double> _urunler = {
    'GOFRET': 15.0,
    'BİSKREM': 23.0,
    'ETİ BURÇAK SÜTLÜ': 37.0,
    'SAKLIKÖY': 32.0,
    'ÇİZİVİÇ': 18.0,
    'BENİMO': 33.0,
    'ZEYTİNLİ': 24.0,
    'ÇOKONAT': 32.0,
    'BROWNİ': 25.0,
    'HALLEY': 30.0,
    'DİDO': 25.0,
    'ALBENİ': 18.0,
    'SADE SODA': 12.0,
    'MEYVELİ SODA': 13.0,
    'GAZOZ': 20.0,
    'PEPSİ 2.5 LT': 82.0,
    'NESKAFE': 10.0,
    'MEYVE SUYU': 14.0,
  };

  List<String> _kayitliKisiler = [];
  final Map<String, int> _secilenUrunAdetleri = {};
  List<Map<String, dynamic>> _fisler = [];

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();

    final urunlerJson = prefs.getString('kantin_urunler');
    if (urunlerJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(urunlerJson);
        _urunler = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {}
    }

    final kisilerList = prefs.getStringList('kantin_kisiler');
    if (kisilerList != null) {
      _kayitliKisiler = List<String>.from(kisilerList)..sort();
    }

    final fislerJson = prefs.getString('kantin_fisler');
    if (fislerJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(fislerJson);
        _fisler = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (_) {}
    }

    setState(() {});
  }

  Future<void> _verileriKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kantin_urunler', jsonEncode(_urunler));
    await prefs.setStringList('kantin_kisiler', _kayitliKisiler);
    await prefs.setString('kantin_fisler', jsonEncode(_fisler));
  }

  void _kisiEkle(String kisi) {
    final temizKisi = kisi.trim().toUpperCase();
    if (temizKisi.isNotEmpty && !_kayitliKisiler.contains(temizKisi)) {
      setState(() {
        _kayitliKisiler.add(temizKisi);
        _kayitliKisiler.sort();
      });
      _verileriKaydet();
    }
  }

  void _kisiSil(String kisi) {
    setState(() {
      _kayitliKisiler.remove(kisi);
      if (_kisiController.text.trim().toUpperCase() == kisi) {
        _kisiController.clear();
      }
    });
    _verileriKaydet();
  }

  void _uruneTiklandi(String urun) {
    setState(() {
      _secilenUrunAdetleri[urun] = (_secilenUrunAdetleri[urun] ?? 0) + 1;
    });
  }

  void _adetAzalt(String urun) {
    setState(() {
      if ((_secilenUrunAdetleri[urun] ?? 0) > 1) {
        _secilenUrunAdetleri[urun] = _secilenUrunAdetleri[urun]! - 1;
      } else {
        _secilenUrunAdetleri.remove(urun);
      }
    });
  }

  void _adetArtir(String urun) {
    setState(() {
      _secilenUrunAdetleri[urun] = (_secilenUrunAdetleri[urun] ?? 0) + 1;
    });
  }

  // YANLIŞ SEÇİLEN ÜRÜNÜ LİSTEDEN TAMAMEN KALDIRIR
  void _urunSil(String urun) {
    setState(() {
      _secilenUrunAdetleri.remove(urun);
    });
  }

  // YANLIŞ SEÇİLEN ÜRÜNÜ, ADEDİNİ KORUYARAK DOĞRU ÜRÜNLE DEĞİŞTİRİR
  void _urunDegistir(String eskiUrun, String yeniUrun) {
    if (eskiUrun == yeniUrun) return;
    setState(() {
      final adet = _secilenUrunAdetleri[eskiUrun] ?? 1;
      _secilenUrunAdetleri.remove(eskiUrun);
      _secilenUrunAdetleri[yeniUrun] =
          (_secilenUrunAdetleri[yeniUrun] ?? 0) + adet;
    });
  }

  double get _toplamTutar {
    double top = 0;
    _secilenUrunAdetleri.forEach((urun, adet) {
      final f = _urunler[urun] ?? 0;
      top += f * adet;
    });
    return top;
  }

  void _satisiKaydet() {
    // DOĞRUDAN CONTROLLER'DAN ALIYORUZ: ASLA BOŞ ALGILAMAZ!
    final kisi = _kisiController.text.trim().toUpperCase();

    if (kisi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir isim yazın!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_secilenUrunAdetleri.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen en az bir ürün seçin!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _kisiEkle(kisi);

    final now = DateTime.now();
    final tarihStr =
        "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final List<Map<String, dynamic>> urunlerDetay = [];
    _secilenUrunAdetleri.forEach((urun, adet) {
      urunlerDetay.add({
        'ad': urun,
        'adet': adet,
        'fiyat': _urunler[urun] ?? 0.0,
      });
    });

    final yeniFis = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'kisi': kisi,
      'tarih': tarihStr,
      'urunler': urunlerDetay,
      'toplam': _toplamTutar,
    };

    setState(() {
      _fisler.insert(0, yeniFis);
      _secilenUrunAdetleri.clear();
      _kisiController.clear();
    });

    _verileriKaydet();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$kisi için satış kaydedildi!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _yeniUrunDiyalogu() {
    final adController = TextEditingController();
    final fiyatController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Ürün Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adController,
              decoration: const InputDecoration(labelText: 'Ürün Adı'),
              textCapitalization: TextCapitalization.characters,
            ),
            TextField(
              controller: fiyatController,
              decoration: const InputDecoration(labelText: 'Fiyat (₺)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              final ad = adController.text.trim().toUpperCase();
              final fiyat =
                  double.tryParse(fiyatController.text.replaceAll(',', '.'));
              if (ad.isNotEmpty && fiyat != null && fiyat > 0) {
                setState(() {
                  _urunler[ad] = fiyat;
                });
                _verileriKaydet();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _urunGuncelleSilDiyalogu(String urunAdi, double mevcutFiyat) {
    final fiyatController =
        TextEditingController(text: mevcutFiyat.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(urunAdi),
        content: TextField(
          controller: fiyatController,
          decoration: const InputDecoration(labelText: 'Fiyatı Düzenle (₺)'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _urunler.remove(urunAdi);
                _secilenUrunAdetleri.remove(urunAdi);
              });
              _verileriKaydet();
              Navigator.pop(ctx);
            },
            child: const Text('Ürünü Sil', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              final yeniFiyat =
                  double.tryParse(fiyatController.text.replaceAll(',', '.'));
              if (yeniFiyat != null && yeniFiyat > 0) {
                setState(() {
                  _urunler[urunAdi] = yeniFiyat;
                });
                _verileriKaydet();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kantin Defteri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode_outlined),
            onPressed: widget.onTemaDegistir,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Ay Sonu Muhasebe & Dökümler',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AySonuMuhasebeSayfasi(
                    fisler: _fisler,
                    urunler: _urunler,
                    onFislerGuncellendi: (yeniFisler) {
                      setState(() {
                        _fisler = List<Map<String, dynamic>>.from(yeniFisler);
                      });
                      _verileriKaydet();
                    },
                    onTemizle: () {
                      setState(() {
                        _fisler.clear();
                      });
                      _verileriKaydet();
                    },
                  ),
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.storefront,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Kantin Yönetimi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Kayıtlı Kişiler'),
              subtitle: Text('${_kayitliKisiler.length} kişi kayıtlı'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KisilerSayfasi(
                      kayitliKisiler: _kayitliKisiler,
                      onKisiSil: _kisiSil,
                      onKisiEkle: _kisiEkle,
                    ),
                  ),
                );
                setState(() {});
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KİŞİ ADI GİRİŞ ALANI
              TextField(
                controller: _kisiController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Kişi Adı',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: _kisiController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _kisiController.clear();
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),

              // KİŞİ BUTONLARI (KAYITLI KİŞİLER)
              if (_kayitliKisiler.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _kayitliKisiler.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final isim = _kayitliKisiler[idx];
                      final secili =
                          _kisiController.text.trim().toUpperCase() == isim;
                      return ActionChip(
                        label: Text(
                          isim,
                          style: TextStyle(
                            fontWeight:
                                secili ? FontWeight.bold : FontWeight.normal,
                            color: secili ? Colors.white : null,
                          ),
                        ),
                        backgroundColor: secili ? Colors.teal : null,
                        onPressed: () {
                          setState(() {
                            _kisiController.text = isim;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // ÜRÜNLER BAŞLIĞI & BUTONLAR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ürünler (Fiyat için basılı tutun):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  InkWell(
                    onTap: _yeniUrunDiyalogu,
                    child: const Row(
                      children: [
                        Icon(Icons.add, color: Colors.teal, size: 18),
                        Text(
                          'Ürün Ekle',
                          style: TextStyle(
                            color: Colors.teal,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ÜRÜN ÇİPLERİ / KARTLARI
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _urunler.entries.map((entry) {
                  final urunAdi = entry.key;
                  final fiyat = entry.value;
                  final seciliAdet = _secilenUrunAdetleri[urunAdi] ?? 0;
                  final seciliMi = seciliAdet > 0;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _uruneTiklandi(urunAdi),
                    onLongPress: () =>
                        _urunGuncelleSilDiyalogu(urunAdi, fiyat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: seciliMi
                            ? Colors.teal.shade200.withOpacity(0.4)
                            : Colors.grey.shade100,
                        border: Border.all(
                          color: seciliMi
                              ? Colors.teal
                              : Colors.grey.shade400,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (seciliMi) ...[
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: Colors.teal,
                              child: Text(
                                '$seciliAdet',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '$urunAdi (${fiyat.toStringAsFixed(0)} ₺)',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // SEÇİLEN ÜRÜNLER LİSTESİ
              if (_secilenUrunAdetleri.isNotEmpty) ...[
                const Text(
                  'Seçilen Ürünler:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ..._secilenUrunAdetleri.entries.map((e) {
                  final urun = e.key;
                  final adet = e.value;
                  final fiyat = _urunler[urun] ?? 0.0;
                  final satirToplami = fiyat * adet;

                  // İKİ SATIRLI KART: 1) ürün adı + satır toplamı
                  //                   2) adet kontrolleri + değiştir/sil
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. SATIR: Ürün adı + satır toplamı
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$urun (${fiyat.toStringAsFixed(0)} ₺)',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '${satirToplami.toStringAsFixed(0)} ₺',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 2. SATIR: Adet kontrolleri + Değiştir/Sil
                        Row(
                          children: [
                            InkWell(
                              onTap: () => _adetAzalt(urun),
                              child: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red, size: 22),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                '$adet',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                            InkWell(
                              onTap: () => _adetArtir(urun),
                              child: const Icon(Icons.add_circle_outline,
                                  color: Colors.teal, size: 22),
                            ),
                            const Spacer(),
                            // YANLIŞ ÜRÜNÜ DOĞRUSUYLA DEĞİŞTİR
                            InkWell(
                              onTap: () async {
                                final yeniUrun = await showMenu<String>(
                                  context: context,
                                  position: RelativeRect.fromLTRB(
                                      1000, 100, 0, 0),
                                  items: _urunler.keys
                                      .where((p) => p != urun)
                                      .map((prod) => PopupMenuItem<String>(
                                            value: prod,
                                            child: Text(
                                                '$prod (${_urunler[prod]?.toStringAsFixed(0)} ₺)'),
                                          ))
                                      .toList(),
                                );
                                if (yeniUrun != null) {
                                  _urunDegistir(urun, yeniUrun);
                                }
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.swap_horiz,
                                    color: Colors.teal, size: 20),
                              ),
                            ),
                            // ÜRÜNÜ KOMPLE SİL
                            InkWell(
                              onTap: () => _urunSil(urun),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.delete_outline,
                                    color: Colors.red, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),

                // KAYDET BUTONU
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _satisiKaydet,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(
                      'KAYDET (Toplam: ${_toplamTutar.toStringAsFixed(0)} TL)',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // SON KAYDEDİLENLER BÖLÜMÜ
              const Text(
                'Son Kaydedilenler',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_fisler.isEmpty)
                const Text('Henüz kaydedilmiş bir fiş yok.')
              else
                ..._fisler.take(3).map((f) {
                  final List uList = f['urunler'] ?? [];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.receipt, color: Colors.teal),
                      title: Text(
                        "${f['kisi']} - ${(f['toplam'] as num).toStringAsFixed(0)} TL",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${f['tarih']} (${uList.length} çeşit ürün)",
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// AY SONU MUHASEBE SAYFASI
// -------------------------------------------------------------
class AySonuMuhasebeSayfasi extends StatefulWidget {
  final List<Map<String, dynamic>> fisler;
  final Map<String, double> urunler;
  final Function(List<Map<String, dynamic>>) onFislerGuncellendi;
  final VoidCallback onTemizle;

  const AySonuMuhasebeSayfasi({
    super.key,
    required this.fisler,
    required this.urunler,
    required this.onFislerGuncellendi,
    required this.onTemizle,
  });

  @override
  State<AySonuMuhasebeSayfasi> createState() => _AySonuMuhasebeSayfasiState();
}

class _AySonuMuhasebeSayfasiState extends State<AySonuMuhasebeSayfasi> {
  Map<String, double> get _kisiToplamlari {
    final Map<String, double> map = {};
    for (var f in widget.fisler) {
      final kisi = f['kisi'] as String;
      final toplam = (f['toplam'] as num).toDouble();
      map[kisi] = (map[kisi] ?? 0) + toplam;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final toplamlar = _kisiToplamlari;
    final kisiler = toplamlar.keys.toList()..sort();
    final genelToplam =
        toplamlar.values.fold<double>(0, (prev, val) => prev + val);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ay Sonu Muhasebe'),
        actions: [
          if (widget.fisler.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Tüm Dönemi Sıfırla',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Tüm Dönemi Sıfırla'),
                    content: const Text(
                      'Tüm satışlar silinecektir. Emin misiniz?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('İptal'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          widget.onTemizle();
                          setState(() {});
                          Navigator.pop(ctx);
                        },
                        child: const Text('Evet, Sıfırla'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: kisiler.isEmpty
          ? const Center(child: Text('Henüz satış kaydı bulunmuyor.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: kisiler.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final kisi = kisiler[index];
                      final borc = toplamlar[kisi] ?? 0;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          foregroundColor: Colors.teal.shade900,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          kisi,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: const Text(
                          'Detay dökümü gör →',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Text(
                          '${borc.toStringAsFixed(0)} TL',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetayDokumSayfasi(
                                kisi: kisi,
                                fisler: widget.fisler,
                                urunler: widget.urunler,
                                onFislerGuncellendi: (yeniFisler) {
                                  widget.onFislerGuncellendi(yeniFisler);
                                  setState(() {});
                                },
                              ),
                            ),
                          );
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: Colors.teal.shade100.withOpacity(0.5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'GENEL TOPLAM:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        '${genelToplam.toStringAsFixed(0)} TL',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// -------------------------------------------------------------
// KİŞİ DETAY DÖKÜM SAYFASI (ÜRÜN DEĞİŞTİR / ADET / SİL)
// -------------------------------------------------------------
class DetayDokumSayfasi extends StatefulWidget {
  final String kisi;
  final List<Map<String, dynamic>> fisler;
  final Map<String, double> urunler;
  final Function(List<Map<String, dynamic>>) onFislerGuncellendi;

  const DetayDokumSayfasi({
    super.key,
    required this.kisi,
    required this.fisler,
    required this.urunler,
    required this.onFislerGuncellendi,
  });

  @override
  State<DetayDokumSayfasi> createState() => _DetayDokumSayfasiState();
}

class _DetayDokumSayfasiState extends State<DetayDokumSayfasi> {
  List<Map<String, dynamic>> get _kisiFisleri {
    return widget.fisler.where((f) => f['kisi'] == widget.kisi).toList();
  }

  double get _toplamBorc {
    return _kisiFisleri.fold<double>(
        0, (prev, f) => prev + (f['toplam'] as num).toDouble());
  }

  void _fisDuzenleModal(Map<String, dynamic> fis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final urunlerList = (fis['urunler'] as List)
                .map((item) => Map<String, dynamic>.from(item))
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fişi Düzenle (${fis['tarih']})',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: 'Tüm Fişi Sil',
                        onPressed: () {
                          setState(() {
                            widget.fisler
                                .removeWhere((item) => item['id'] == fis['id']);
                          });
                          widget.onFislerGuncellendi(widget.fisler);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: urunlerList.length,
                      itemBuilder: (context, idx) {
                        final u = urunlerList[idx];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u['ad'],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Birim: ${(u['fiyat'] as num).toStringAsFixed(0)} ₺  |  Toplam: ${((u['fiyat'] as num) * (u['adet'] as num)).toStringAsFixed(0)} ₺',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                // Adet Azalt
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    setModalState(() {
                                      if ((u['adet'] as int) > 1) {
                                        u['adet'] -= 1;
                                      } else {
                                        urunlerList.removeAt(idx);
                                      }
                                      fis['urunler'] = urunlerList;
                                      _hesaplaVeKaydet(fis);
                                    });
                                    setState(() {});
                                    if (urunlerList.isEmpty) Navigator.pop(ctx);
                                  },
                                ),
                                Text(
                                  '${u['adet']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                // Adet Artır
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    setModalState(() {
                                      u['adet'] += 1;
                                      fis['urunler'] = urunlerList;
                                      _hesaplaVeKaydet(fis);
                                    });
                                    setState(() {});
                                  },
                                ),
                                // Başka Ürünle Değiştir
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.swap_horiz,
                                      color: Colors.teal),
                                  tooltip: 'Ürünü Değiştir',
                                  onSelected: (yeniUrun) {
                                    final yeniFiyat =
                                        widget.urunler[yeniUrun] ??
                                            (u['fiyat'] as num).toDouble();
                                    setModalState(() {
                                      u['ad'] = yeniUrun;
                                      u['fiyat'] = yeniFiyat;
                                      fis['urunler'] = urunlerList;
                                      _hesaplaVeKaydet(fis);
                                    });
                                    setState(() {});
                                  },
                                  itemBuilder: (context) {
                                    return widget.urunler.keys.map((prod) {
                                      return PopupMenuItem<String>(
                                        value: prod,
                                        child: Text(
                                            '$prod (${widget.urunler[prod]?.toStringAsFixed(0)} ₺)'),
                                      );
                                    }).toList();
                                  },
                                ),
                                // Ürünü Sil
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    setModalState(() {
                                      urunlerList.removeAt(idx);
                                      fis['urunler'] = urunlerList;
                                      _hesaplaVeKaydet(fis);
                                    });
                                    setState(() {});
                                    if (urunlerList.isEmpty) Navigator.pop(ctx);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Güncel Fiş: ${(fis['toplam'] as num).toStringAsFixed(0)} TL',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Tamam'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _hesaplaVeKaydet(Map<String, dynamic> fis) {
    final urunlerList = (fis['urunler'] as List).cast<Map<String, dynamic>>();
    if (urunlerList.isEmpty) {
      widget.fisler.removeWhere((item) => item['id'] == fis['id']);
    } else {
      double top = 0;
      for (var u in urunlerList) {
        top += (u['fiyat'] as num).toDouble() * (u['adet'] as num).toInt();
      }
      fis['toplam'] = top;
    }
    widget.onFislerGuncellendi(widget.fisler);
  }

  @override
  Widget build(BuildContext context) {
    final fisler = _kisiFisleri;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.kisi} - Döküm'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Colors.teal.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toplam Borç:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_toplamBorc.toStringAsFixed(0)} TL',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: fisler.isEmpty
                ? const Center(child: Text('Bu kişiye ait fiş kalmadı.'))
                : ListView.separated(
                    itemCount: fisler.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final fis = fisler[index];
                      final urunlerList = (fis['urunler'] as List)
                          .cast<Map<String, dynamic>>();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.teal),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...urunlerList.map((u) => Text(
                                  "${u['adet']}x ${u['ad']} (${(u['fiyat'] as num).toStringAsFixed(0)} ₺)",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                )),
                            const SizedBox(height: 4),
                            Text(
                              "Tarih: ${fis['tarih']}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(fis['toplam'] as num).toStringAsFixed(0)} ₺',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note,
                                  color: Colors.teal),
                              tooltip: 'Düzenle / Değiştir / Sil',
                              onPressed: () => _fisDuzenleModal(fis),
                            ),
                          ],
                        ),
                        onTap: () => _fisDuzenleModal(fis),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// KAYITLI KİŞİLER YÖNETİM SAYFASI
// -------------------------------------------------------------
class KisilerSayfasi extends StatefulWidget {
  final List<String> kayitliKisiler;
  final Function(String) onKisiSil;
  final Function(String) onKisiEkle;

  const KisilerSayfasi({
    super.key,
    required this.kayitliKisiler,
    required this.onKisiSil,
    required this.onKisiEkle,
  });

  @override
  State<KisilerSayfasi> createState() => _KisilerSayfasiState();
}

class _KisilerSayfasiState extends State<KisilerSayfasi> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıtlı Kişiler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Kişi Ekle',
            onPressed: () {
              final controller = TextEditingController();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Yeni Kişi Ekle'),
                  content: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(labelText: 'Kişi Adı'),
                    autofocus: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('İptal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final isim = controller.text.trim().toUpperCase();
                        if (isim.isNotEmpty) {
                          widget.onKisiEkle(isim);
                          setState(() {});
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Ekle'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: widget.kayitliKisiler.isEmpty
          ? const Center(child: Text('Kayıtlı kişi bulunmuyor.'))
          : ListView.separated(
              itemCount: widget.kayitliKisiler.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final isim = widget.kayitliKisiler[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(isim,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      widget.onKisiSil(isim);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}
