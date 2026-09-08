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
  String _seciliKisi = '';

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
    'DİDO': 25.0,
    'SADE SODA': 12.0,
    'GAZOZ': 20.0,
    'NESKAFE': 10.0,
  };

  List<String> _kayitliKisiler = [];
  final List<Map<String, dynamic>> _sepet = [];
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
      final Map<String, dynamic> decoded = jsonDecode(urunlerJson);
      _urunler = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    final kisilerList = prefs.getStringList('kantin_kisiler');
    if (kisilerList != null) {
      _kayitliKisiler = List<String>.from(kisilerList)..sort();
    }

    final fislerJson = prefs.getString('kantin_fisler');
    if (fislerJson != null) {
      final List<dynamic> decoded = jsonDecode(fislerJson);
      _fisler = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
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
      if (_seciliKisi == kisi) {
        _seciliKisi = '';
        _kisiController.clear();
      }
    });
    _verileriKaydet();
  }

  void _sepeteEkle(String urunAdi, double fiyat) {
    setState(() {
      final index = _sepet.indexWhere((item) => item['ad'] == urunAdi);
      if (index != -1) {
        _sepet[index]['adet'] += 1;
      } else {
        _sepet.add({
          'ad': urunAdi,
          'fiyat': fiyat,
          'adet': 1,
        });
      }
    });
  }

  double get _sepetToplami {
    double toplam = 0;
    for (var item in _sepet) {
      toplam += (item['fiyat'] as double) * (item['adet'] as int);
    }
    return toplam;
  }

  void _satisiTamamla() {
    // Hem değişkenden hem controller'dan kontrol ediyoruz
    String kisi = _seciliKisi.trim().toUpperCase();
    if (kisi.isEmpty) {
      kisi = _kisiController.text.trim().toUpperCase();
    }

    if (kisi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir kişi adı seçin veya yazın!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_sepet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sepet boş! Lütfen ürün seçin.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _kisiEkle(kisi);

    final now = DateTime.now();
    final tarihStr =
        "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')} - ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    final yeniFis = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'kisi': kisi,
      'tarih': tarihStr,
      'urunler': _sepet
          .map((item) => {
                'ad': item['ad'],
                'fiyat': item['fiyat'],
                'adet': item['adet'],
              })
          .toList(),
      'toplam': _sepetToplami,
    };

    setState(() {
      _fisler.insert(0, yeniFis);
      _sepet.clear();
      _seciliKisi = '';
      _kisiController.clear();
    });

    _verileriKaydet();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$kisi için satış başarıyla kaydedildi.'),
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
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onTemaDegistir,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Kişi Dökümleri ve Hesaplar',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KisiListesiDokumSayfasi(
                    fisler: _fisler,
                    urunler: _urunler,
                    onFislerGuncellendi: (guncelFisler) {
                      setState(() {
                        _fisler = List<Map<String, dynamic>>.from(guncelFisler);
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
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Ürün Listesi'),
              subtitle: Text('${_urunler.length} ürün'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UrunlerSayfasi(
                      urunler: _urunler,
                      onUrunDuzenle: _urunGuncelleSilDiyalogu,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // KİŞİ SEÇİMİ VE BUTONLAR
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceVariant
                  .withOpacity(0.35),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _kisiController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Kişi Adı',
                          hintText: 'Örn: ALİŞAN',
                          prefixIcon: const Icon(Icons.person),
                          suffixIcon: _kisiController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _kisiController.clear();
                                      _seciliKisi = '';
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _seciliKisi = val.trim().toUpperCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Yeni Kişi Ekle',
                      onPressed: () {
                        final c = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Yeni Kişi Ekle'),
                            content: TextField(
                              controller: c,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'Kişi Adı',
                                hintText: 'Örn: MEHMET',
                              ),
                              autofocus: true,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('İptal'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final isim = c.text.trim().toUpperCase();
                                  if (isim.isNotEmpty) {
                                    _kisiEkle(isim);
                                    setState(() {
                                      _seciliKisi = isim;
                                      _kisiController.text = isim;
                                    });
                                    Navigator.pop(ctx);
                                  }
                                },
                                child: const Text('Ekle'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add),
                    ),
                  ],
                ),

                // KİŞİ ÇİPLERİ / BUTONLARI
                if (_kayitliKisiler.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _kayitliKisiler.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final kisi = _kayitliKisiler[index];
                        final seciliMi = (_seciliKisi == kisi) ||
                            (_kisiController.text.trim().toUpperCase() == kisi);

                        return ChoiceChip(
                          avatar: Icon(
                            Icons.person,
                            size: 16,
                            color: seciliMi
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            kisi,
                            style: TextStyle(
                              fontWeight:
                                  seciliMi ? FontWeight.bold : FontWeight.w500,
                              color: seciliMi
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : null,
                            ),
                          ),
                          selected: seciliMi,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _seciliKisi = kisi;
                                _kisiController.text = kisi;
                              } else {
                                _seciliKisi = '';
                                _kisiController.clear();
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ÜRÜNLER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ürünler (Fiyat için basılı tutun):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                TextButton.icon(
                  onPressed: _yeniUrunDiyalogu,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ürün Ekle'),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _urunler.entries.map((entry) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _sepeteEkle(entry.key, entry.value),
                    onLongPress: () =>
                        _urunGuncelleSilDiyalogu(entry.key, entry.value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Text(
                        '${entry.key} (${entry.value.toStringAsFixed(0)} ₺)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // SEPET
          if (_sepet.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceVariant
                    .withOpacity(0.5),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, -2),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sepet (${_sepet.fold<int>(0, (prev, e) => prev + (e['adet'] as int))} Adet)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _sepet.clear()),
                        child: const Text('Temizle',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _sepet.length,
                      itemBuilder: (context, index) {
                        final item = _sepet[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item['ad']} x${item['adet']}'),
                              Text(
                                '${((item['fiyat'] as double) * (item['adet'] as int)).toStringAsFixed(0)} ₺',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Toplam Tutar:',
                              style: TextStyle(fontSize: 12)),
                          Text(
                            '${_sepetToplami.toStringAsFixed(0)} ₺',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: _satisiTamamla,
                        icon: const Icon(Icons.check),
                        label: const Text(
                          'SATIŞI TAMAMLA',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
// KİŞİ BAZLI DÖKÜM LİSTESİ SAYFASI
// -------------------------------------------------------------
class KisiListesiDokumSayfasi extends StatefulWidget {
  final List<Map<String, dynamic>> fisler;
  final Map<String, double> urunler;
  final Function(List<Map<String, dynamic>>) onFislerGuncellendi;
  final VoidCallback onTemizle;

  const KisiListesiDokumSayfasi({
    super.key,
    required this.fisler,
    required this.urunler,
    required this.onFislerGuncellendi,
    required this.onTemizle,
  });

  @override
  State<KisiListesiDokumSayfasi> createState() =>
      _KisiListesiDokumSayfasiState();
}

class _KisiListesiDokumSayfasiState extends State<KisiListesiDokumSayfasi> {
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
        title: const Text('Hesap Dökümleri'),
        actions: [
          if (widget.fisler.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Tüm Dönemi Sıfırla (Ay Başı)',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Tüm Dönemi Sıfırla'),
                    content: const Text(
                      'Tüm satış ve borç geçmişi silinecektir. Yeni döneme başlamak için emin misiniz?',
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
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: Colors.teal.withOpacity(0.12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dönem Toplam Satış:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
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
                Expanded(
                  child: ListView.separated(
                    itemCount: kisiler.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final kisi = kisiler[index];
                      final borc = toplamlar[kisi] ?? 0;
                      return ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(
                          kisi,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${borc.toStringAsFixed(0)} TL',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey),
                          ],
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KisiDetayDokumSayfasi(
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
              ],
            ),
    );
  }
}

// -------------------------------------------------------------
// BİR KİŞİNİN AYRINTILI DÖKÜM SAYFASI (FİŞLER & DÜZENLE/SİL)
// -------------------------------------------------------------
class KisiDetayDokumSayfasi extends StatefulWidget {
  final String kisi;
  final List<Map<String, dynamic>> fisler;
  final Map<String, double> urunler;
  final Function(List<Map<String, dynamic>>) onFislerGuncellendi;

  const KisiDetayDokumSayfasi({
    super.key,
    required this.kisi,
    required this.fisler,
    required this.urunler,
    required this.onFislerGuncellendi,
  });

  @override
  State<KisiDetayDokumSayfasi> createState() => _KisiDetayDokumSayfasiState();
}

class _KisiDetayDokumSayfasiState extends State<KisiDetayDokumSayfasi> {
  List<Map<String, dynamic>> get _kisiFisleri {
    return widget.fisler
        .where((f) => f['kisi'] == widget.kisi)
        .toList();
  }

  double get _kisiToplamBorc {
    return _kisiFisleri.fold<double>(
        0, (prev, f) => prev + (f['toplam'] as num).toDouble());
  }

  void _fisDuzenleDiyalogu(Map<String, dynamic> fis) {
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
                        'Fiş Düzenle (${fis['tarih']})',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever,
                            color: Colors.red),
                        tooltip: 'Tüm Fişi Sil',
                        onPressed: () {
                          setState(() {
                            widget.fisler.removeWhere(
                                (item) => item['id'] == fis['id']);
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
                                // ADET AZALT
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
                                      _hesaplaVeKaydetFis(fis);
                                    });
                                    setState(() {});
                                    if (urunlerList.isEmpty) {
                                      Navigator.pop(ctx);
                                    }
                                  },
                                ),
                                Text(
                                  '${u['adet']}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                // ADET ARTIR
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    setModalState(() {
                                      u['adet'] += 1;
                                      fis['urunler'] = urunlerList;
                                      _hesaplaVeKaydetFis(fis);
                                    });
                                    setState(() {});
                                  },
                                ),
                                // BAŞKA ÜRÜNLE DEĞİŞTİR
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.swap_horiz,
                                      color: Colors.teal),
                                  tooltip: 'Ürünü Değiştir',
                                  onSelected: (yeniUrunAdi) {
                                    final yeniFiyat =
                                        widget.urunler[yeniUrunAdi] ??
                                            (u['fiyat'] as num).toDouble();
                                    setModalState(() {
                                      u['ad'] = yeniUrunAdi;
                                      u['fiyat'] = yeniFiyat;
                                      fis['urunler'] = urunlerList;
                                      _hesaplaVeKaydetFis(fis);
                                    });
                                    setState(() {});
                                  },
                                  itemBuilder: (context) {
                                    return widget.urunler.keys.map((prod) {
                                      return PopupMenuItem<String>(
                                        value: prod,
                                        child: Text(
                                          '$prod (${widget.urunler[prod]?.toStringAsFixed(0)} ₺)',
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                                // BU ÜRÜNÜ SİL
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () {
                                    setModalState(() {
                                      urunlerList.removeAt(idx);
                                      fis['urunler'] = urunlerList;
                                      _hesaplaVeKaydetFis(fis);
                                    });
                                    setState(() {});
                                    if (urunlerList.isEmpty) {
                                      Navigator.pop(ctx);
                                    }
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
                        'Güncel Fiş Toplamı: ${(fis['toplam'] as num).toStringAsFixed(0)} TL',
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

  void _hesaplaVeKaydetFis(Map<String, dynamic> fis) {
    final urunlerList =
        (fis['urunler'] as List).cast<Map<String, dynamic>>();
    if (urunlerList.isEmpty) {
      widget.fisler.removeWhere((item) => item['id'] == fis['id']);
    } else {
      double toplam = 0;
      for (var u in urunlerList) {
        toplam += (u['fiyat'] as num).toDouble() * (u['adet'] as num).toInt();
      }
      fis['toplam'] = toplam;
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
            color: Colors.teal.withOpacity(0.15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toplam Borç:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_kisiToplamBorc.toStringAsFixed(0)} TL',
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
                ? const Center(child: Text('Bu kişiye ait kayıtlı fiş kalmadı.'))
                : ListView.separated(
                    itemCount: fisler.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final fis = fisler[index];
                      final urunlerList = (fis['urunler'] as List)
                          .cast<Map<String, dynamic>>();

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: const Icon(Icons.shopping_bag_outlined),
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
                              tooltip: 'Düzenle / Sil',
                              onPressed: () => _fisDuzenleDiyalogu(fis),
                            ),
                          ],
                        ),
                        onTap: () => _fisDuzenleDiyalogu(fis),
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
// KAYITLI KİŞİLER SAYFASI
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
          ? const Center(
              child: Text(
                'Kayıtlı kişi bulunmuyor.\nSağ üstteki (+) butonundan ekleyebilirsiniz.',
                textAlign: TextAlign.center,
              ),
            )
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

// -------------------------------------------------------------
// ÜRÜNLER SAYFASI
// -------------------------------------------------------------
class UrunlerSayfasi extends StatelessWidget {
  final Map<String, double> urunler;
  final Function(String, double) onUrunDuzenle;

  const UrunlerSayfasi({
    super.key,
    required this.urunler,
    required this.onUrunDuzenle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ürünler')),
      body: ListView.separated(
        itemCount: urunler.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final urun = urunler.keys.elementAt(index);
          final fiyat = urunler[urun]!;
          return ListTile(
            title:
                Text(urun, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Text(
              '${fiyat.toStringAsFixed(0)} ₺',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onTap: () => onUrunDuzenle(urun, fiyat),
          );
        },
      ),
    );
  }
}