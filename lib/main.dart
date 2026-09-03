import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KantinApp());
}

class KantinApp extends StatefulWidget {
  const KantinApp({super.key});

  @override
  State<KantinApp> createState() => _KantinAppState();
}

class _KantinAppState extends State<KantinApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _temaYukle();
  }

  Future<void> _temaYukle() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_theme') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
      prefs.setBool('is_dark_theme', _themeMode == ThemeMode.dark);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kantin Defteri',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: AnaSayfa(
        isDark: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class Urun {
  String ad;
  double fiyat;
  Urun(this.ad, this.fiyat);

  Map<String, dynamic> toJson() => {'ad': ad, 'fiyat': fiyat};
  factory Urun.fromJson(Map<String, dynamic> json) =>
      Urun(json['ad'], (json['fiyat'] as num).toDouble());
}

class SepetElemani {
  final Urun urun;
  int adet;
  SepetElemani({required this.urun, this.adet = 1});

  double get toplamTutar => urun.fiyat * adet;

  Map<String, dynamic> toJson() => {'urun': urun.toJson(), 'adet': adet};
  factory SepetElemani.fromJson(Map<String, dynamic> json) => SepetElemani(
        urun: Urun.fromJson(json['urun']),
        adet: json['adet'],
      );
}

class Satis {
  final String isci;
  final List<SepetElemani> urunler;
  final double toplamTutar;
  final DateTime tarih;

  Satis({
    required this.isci,
    required this.urunler,
    required this.toplamTutar,
    required this.tarih,
  });

  Map<String, dynamic> toJson() => {
        'isci': isci,
        'urunler': urunler.map((e) => e.toJson()).toList(),
        'toplamTutar': toplamTutar,
        'tarih': tarih.toIso8601String(),
      };

  factory Satis.fromJson(Map<String, dynamic> json) => Satis(
        isci: json['isci'],
        urunler: (json['urunler'] as List)
            .map((e) => SepetElemani.fromJson(e))
            .toList(),
        toplamTutar: (json['toplamTutar'] as num).toDouble(),
        tarih: DateTime.parse(json['tarih']),
      );
}

class AnaSayfa extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const AnaSayfa({super.key, required this.isDark, required this.onToggleTheme});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  List<Urun> _urunler = [];
  final Set<String> _kayitliIsciler = {};
  final TextEditingController _isciController = TextEditingController();
  final Map<String, SepetElemani> _sepet = {};
  List<Satis> _satislar = [];
  bool _yukleniyor = true;

  final List<Urun> _varsayilanUrunler = [
    Urun('GOFRET', 15),
    Urun('BİSKREM', 23),
    Urun('ETİ BURÇAK SÜTLÜ', 37),
    Urun('SAKLIKÖY', 32),
    Urun('ÇİZİVİÇ', 18),
    Urun('BENİMO', 33),
    Urun('ZEYTİNLİ', 24),
    Urun('ÇOKONAT', 32),
    Urun('BROWNİ', 25),
    Urun('HALLEY', 30),
    Urun('DİDO', 25),
    Urun('ALBENİ', 18),
    Urun('SADE SODA', 12),
    Urun('MEYVELİ SODA', 13),
    Urun('GAZOZ', 20),
    Urun('PEPSİ 2.5 LT', 82),
    Urun('NESKAFE', 10),
    Urun('MEYVE SUYU', 14),
  ];

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();

    final urunlerJson = prefs.getString('yerel_urunler');
    if (urunlerJson != null) {
      final List decoded = jsonDecode(urunlerJson);
      _urunler = decoded.map((e) => Urun.fromJson(e)).toList();
    } else {
      _urunler = List.from(_varsayilanUrunler);
    }

    final iscilerList = prefs.getStringList('yerel_isciler');
    if (iscilerList != null) {
      _kayitliIsciler.addAll(iscilerList);
    }

    final satislarJson = prefs.getString('yerel_satislar');
    if (satislarJson != null) {
      final List decoded = jsonDecode(satislarJson);
      _satislar = decoded.map((e) => Satis.fromJson(e)).toList();
    }

    setState(() {
      _yukleniyor = false;
    });
  }

  Future<void> _urunleriKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_urunler.map((e) => e.toJson()).toList());
    await prefs.setString('yerel_urunler', data);
  }

  Future<void> _iscileriKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('yerel_isciler', _kayitliIsciler.toList());
  }

  Future<void> _satislariKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_satislar.map((e) => e.toJson()).toList());
    await prefs.setString('yerel_satislar', data);
  }

  double get _sepetToplamTutar {
    return _sepet.values.fold(0.0, (sum, item) => sum + item.toplamTutar);
  }

  void _urunuSepeteEkle(Urun urun) {
    setState(() {
      if (_sepet.containsKey(urun.ad)) {
        _sepet[urun.ad]!.adet++;
      } else {
        _sepet[urun.ad] = SepetElemani(urun: urun, adet: 1);
      }
    });
  }

  void _urunuSepettenAzalt(String urunAdi) {
    setState(() {
      if (_sepet.containsKey(urunAdi)) {
        if (_sepet[urunAdi]!.adet > 1) {
          _sepet[urunAdi]!.adet--;
        } else {
          _sepet.remove(urunAdi);
        }
      }
    });
  }

  void _satisiTamamla() {
    final isciAdi = _isciController.text.trim().toUpperCase();
    if (isciAdi.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir isim yazın!'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_sepet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen en az bir ürün seçin!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final yeniSatis = Satis(
      isci: isciAdi,
      urunler: _sepet.values.map((e) => SepetElemani(urun: e.urun, adet: e.adet)).toList(),
      toplamTutar: _sepetToplamTutar,
      tarih: DateTime.now(),
    );

    setState(() {
      _kayitliIsciler.add(isciAdi);
      _satislar.insert(0, yeniSatis);
      _sepet.clear();
      _isciController.clear();
    });

    _iscileriKaydet();
    _satislariKaydet();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$isciAdi için kaydedildi (${yeniSatis.toplamTutar.toStringAsFixed(0)} TL)'),
        backgroundColor: Colors.teal,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _yeniUrunEkleDialog([Urun? mevcutUrun]) {
    final adController = TextEditingController(text: mevcutUrun?.ad ?? '');
    final fiyatController = TextEditingController(
        text: mevcutUrun != null ? mevcutUrun.fiyat.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(mevcutUrun == null ? 'Yeni Ürün Ekle' : 'Ürün / Fiyat Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: adController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Ürün Adı',
                hintText: 'Örn: ÇİKOLATA',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fiyatController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Fiyat (TL)',
                hintText: 'Örn: 25',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (mevcutUrun != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                setState(() {
                  _urunler.remove(mevcutUrun);
                  _sepet.remove(mevcutUrun.ad);
                });
                _urunleriKaydet();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${mevcutUrun.ad} silindi.')),
                );
              },
              child: const Text('Sil'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final ad = adController.text.trim().toUpperCase();
              final fiyat = double.tryParse(fiyatController.text.trim().replaceAll(',', '.'));

              if (ad.isEmpty || fiyat == null || fiyat <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lütfen geçerli ürün adı ve fiyatı girin!'), backgroundColor: Colors.redAccent),
                );
                return;
              }

              setState(() {
                if (mevcutUrun != null) {
                  mevcutUrun.ad = ad;
                  mevcutUrun.fiyat = fiyat;
                } else {
                  _urunler.add(Urun(ad, fiyat));
                }
              });

              _urunleriKaydet();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(mevcutUrun == null ? '$ad eklendi.' : '$ad güncellendi.'), backgroundColor: Colors.teal),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kantin Defteri', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            tooltip: 'Yeni Ürün Ekle',
            onPressed: () => _yeniUrunEkleDialog(),
          ),
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Koyu / Açık Tema',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Ay Sonu Muhasebe',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OzetSayfasi(
                    satislar: _satislar,
                    onVeriGuncellendi: _satislariKaydet,
                  ),
                ),
              );
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
                color: widget.isDark ? Colors.grey.shade900 : Colors.teal.shade700,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.storefront, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Kantin Menüsü', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2),
              title: const Text('Ürün Listesi & Fiyatlar'),
              subtitle: Text('${_urunler.length} kayıtlı ürün'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UrunlerSayfasi(
                      urunler: _urunler,
                      onUrunDuzenle: (u) => _yeniUrunEkleDialog(u),
                      onYeniUrun: () => _yeniUrunEkleDialog(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Kişi Listesi'),
              subtitle: Text('${_kayitliIsciler.length} kişi kayıtlı'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KisilerSayfasi(
                      kayitliIsciler: _kayitliIsciler,
                      onKisiSil: (kisi) {
                        setState(() => _kayitliIsciler.remove(kisi));
                        _iscileriKaydet();
                      },
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.calculate),
              title: const Text('Ay Sonu Muhasebe'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OzetSayfasi(
                      satislar: _satislar,
                      onVeriGuncellendi: _satislariKaydet,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue val) {
                if (val.text.isEmpty) return const Iterable<String>.empty();
                return _kayitliIsciler.where((item) =>
                    item.toLowerCase().contains(val.text.toLowerCase()));
              },
              onSelected: (String secim) {
                _isciController.text = secim;
              },
              fieldViewBuilder: (ctx, controller, focusNode, onEditingComplete) {
                _isciController.text = controller.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Kişi Adı',
                    hintText: 'Örn: AHMET',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ürünler (Fiyat için basılı tutun):',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ürün Ekle'),
                  onPressed: () => _yeniUrunEkleDialog(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _urunler.map((u) {
                final sepettekiAdet = _sepet[u.ad]?.adet ?? 0;
                final eklendiMi = sepettekiAdet > 0;
                return GestureDetector(
                  onLongPress: () => _yeniUrunEkleDialog(u),
                  child: ActionChip(
                    avatar: eklendiMi
                        ? CircleAvatar(
                            backgroundColor: Colors.teal,
                            child: Text('$sepettekiAdet', style: const TextStyle(color: Colors.white, fontSize: 11)),
                          )
                        : null,
                    label: Text('${u.ad} (${u.fiyat.toInt()} ₺)'),
                    backgroundColor: eklendiMi ? Colors.teal.withOpacity(0.25) : null,
                    onPressed: () => _urunuSepeteEkle(u),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            if (_sepet.isNotEmpty) ...[
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Seçilen Ürünler:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._sepet.values.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Expanded(child: Text('${item.urun.ad} (${item.urun.fiyat.toInt()} ₺)')),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                                  onPressed: () => _urunuSepettenAzalt(item.urun.ad),
                                ),
                                Text('${item.adet}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.teal),
                                  onPressed: () => _urunuSepeteEkle(item.urun),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    '${item.toplamTutar.toInt()} ₺',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _satisiTamamla,
                icon: const Icon(Icons.check_circle),
                label: Text(
                  _sepet.isEmpty
                      ? 'KAYDET'
                      : 'KAYDET (Toplam: ${_sepetToplamTutar.toStringAsFixed(0)} TL)',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Son Kaydedilenler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            _satislar.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Henüz işlem kaydedilmedi.'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _satislar.length > 5 ? 5 : _satislar.length,
                    itemBuilder: (context, index) {
                      final s = _satislar[index];
                      final urunDetay = s.urunler.map((e) => '${e.adet}x ${e.urun.ad}').join(', ');
                      return ListTile(
                        dense: true,
                        leading: const CircleAvatar(child: Icon(Icons.receipt, size: 18)),
                        title: Text(s.isci, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(urunDetay),
                        trailing: Text(
                          '${s.toplamTutar.toStringAsFixed(0)} ₺',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.teal),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class UrunlerSayfasi extends StatelessWidget {
  final List<Urun> urunler;
  final Function(Urun) onUrunDuzenle;
  final VoidCallback onYeniUrun;

  const UrunlerSayfasi({
    super.key,
    required this.urunler,
    required this.onUrunDuzenle,
    required this.onYeniUrun,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürün ve Fiyat Listesi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Ürün Ekle',
            onPressed: onYeniUrun,
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: urunler.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final u = urunler[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(u.ad, style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${u.fiyat.toStringAsFixed(0)} TL',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 8),
                const Icon(Icons.edit, size: 18, color: Colors.teal),
              ],
            ),
            onTap: () => onUrunDuzenle(u),
          );
        },
      ),
    );
  }
}

class KisilerSayfasi extends StatelessWidget {
  final Set<String> kayitliIsciler;
  final Function(String) onKisiSil;

  const KisilerSayfasi({super.key, required this.kayitliIsciler, required this.onKisiSil});

  @override
  Widget build(BuildContext context) {
    final liste = kayitliIsciler.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıtlı Kişiler')),
      body: liste.isEmpty
          ? const Center(child: Text('Kayıtlı kişi bulunmuyor.'))
          : ListView.separated(
              itemCount: liste.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final isim = liste[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(isim, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => onKisiSil(isim),
                  ),
                );
              },
            ),
    );
  }
}

class OzetSayfasi extends StatelessWidget {
  final List<Satis> satislar;
  final VoidCallback onVeriGuncellendi;

  const OzetSayfasi({
    super.key,
    required this.satislar,
    required this.onVeriGuncellendi,
  });

  void _excelKopyalamaDialogu(BuildContext context) {
    if (satislar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktarılacak satış verisi yok!')),
      );
      return;
    }

    final csvBuffer = StringBuffer();
    csvBuffer.writeln('Kişi\tÜrün Detayı\tTutar (TL)\tTarih Saat');

    for (var s in satislar) {
      final urunDetayi = s.urunler.map((e) => '${e.adet}x ${e.urun.ad}').join(' + ');
      final tarihStr = '${s.tarih.day.toString().padLeft(2, '0')}.${s.tarih.month.toString().padLeft(2, '0')} ${s.tarih.hour.toString().padLeft(2, '0')}:${s.tarih.minute.toString().padLeft(2, '0')}';
      csvBuffer.writeln('${s.isci}\t$urunDetayi\t${s.toplamTutar.toStringAsFixed(0)}\t$tarihStr');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excel / Tablo Dökümü'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Metni kopyalayıp Excel veya Google E-Tablolar içine yapıştırabilirsiniz:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                height: 150,
                color: Colors.grey.withOpacity(0.15),
                child: SingleChildScrollView(
                  child: SelectableText(csvBuffer.toString()),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Panoya Kopyala'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: csvBuffer.toString()));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kopyalandı! Excel\'e doğrudan yapıştırabilirsiniz.')),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, double> kisiToplamlari = {};
    for (var s in satislar) {
      kisiToplamlari[s.isci] = (kisiToplamlari[s.isci] ?? 0) + s.toplamTutar;
    }

    final siralama = kisiToplamlari.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final genelToplam = kisiToplamlari.values.fold(0.0, (sum, val) => sum + val);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ay Sonu Muhasebe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_view),
            tooltip: 'Excel Dökümü Al',
            onPressed: () => _excelKopyalamaDialogu(context),
          ),
        ],
      ),
      body: satislar.isEmpty
          ? const Center(child: Text('Henüz satış verisi bulunmuyor.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    itemCount: siralama.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = siralama[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(item.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Detay dökümü gör ➔', style: TextStyle(fontSize: 12)),
                        trailing: Text(
                          '${item.value.toStringAsFixed(0)} TL',
                          style: const TextStyle(fontSize: 16, color: Colors.teal, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          final kisiSatislar = satislar.where((s) => s.isci == item.key).toList();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => KisiDetaySayfasi(
                                isciAdi: item.key,
                                satislar: kisiSatislar,
                                toplamBorc: item.value,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.teal.withOpacity(0.15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GENEL TOPLAM:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        '${genelToplam.toStringAsFixed(0)} TL',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class KisiDetaySayfasi extends StatelessWidget {
  final String isciAdi;
  final List<Satis> satislar;
  final double toplamBorc;

  const KisiDetaySayfasi({
    super.key,
    required this.isciAdi,
    required this.satislar,
    required this.toplamBorc,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$isciAdi - Döküm'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Toplam Borç:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${toplamBorc.toStringAsFixed(0)} TL', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: satislar.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = satislar[index];
                final tarihStr = '${s.tarih.day.toString().padLeft(2, '0')}.${s.tarih.month.toString().padLeft(2, '0')} - ${s.tarih.hour.toString().padLeft(2, '0')}:${s.tarih.minute.toString().padLeft(2, '0')}';
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.shopping_bag_outlined)),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: s.urunler
                        .map((u) => Text('${u.adet}x ${u.urun.ad} (${(u.urun.fiyat * u.adet).toInt()} ₺)'))
                        .toList(),
                  ),
                  subtitle: Text('Tarih: $tarihStr'),
                  trailing: Text(
                    '${s.toplamTutar.toStringAsFixed(0)} ₺',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}