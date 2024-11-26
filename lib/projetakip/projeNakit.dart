import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf_editor/databaseHelper.dart';
import 'package:uuid/uuid.dart';

class ProjeNakit extends StatefulWidget {
  final String projeId;
  ProjeNakit({required this.projeId});

  @override
  _ProjeNakitState createState() => _ProjeNakitState();
}

class _ProjeNakitState extends State<ProjeNakit> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _odemeListesi = [];
  final Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _fetchOdemeler();
  }

  Future<void> _fetchOdemeler() async {
    final odemeler = await _dbHelper.getOdemelerByProjeId(widget.projeId);
    setState(() {
      _odemeListesi = odemeler;
    });
  }

  void _openOdemePopup({Map<String, dynamic>? odeme}) {
    final TextEditingController miktarController = TextEditingController(
      text: odeme?['miktar'] ?? '',
    );
    String seciliBirim = odeme?['birim'] ?? 'TRY';
    DateTime? seciliTarih = odeme?['eklemeTarihi'] != null
        ? DateTime.parse(odeme!['eklemeTarihi'])
        : null;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(odeme == null ? 'Ödeme Ekle' : 'Ödemeyi Düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: miktarController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Miktar',
                    hintText: 'Ödeme miktarını girin',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: seciliBirim,
                  items: ['TRY', 'USD', 'EUR'].map((birim) {
                    return DropdownMenuItem(
                      value: birim,
                      child: Text(birim),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      seciliBirim = value!;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Para Birimi'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final now = DateTime.now();
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    setState(() {
                      seciliTarih = pickedDate ?? now;
                    });
                  },
                  child: Text(seciliTarih == null
                      ? 'Ödeme Tarihini Seç'
                      : 'Seçilen Tarih: ${DateFormat("dd MMMM yyyy").format(seciliTarih!)}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final yeniOdeme = {
                  'id': odeme?['id'] ?? _uuid.v4(),
                  'kaynakId': widget.projeId,
                  'miktar': miktarController.text,
                  'birim': seciliBirim,
                  'eklemeTarihi': seciliTarih?.toIso8601String() ??
                      DateTime.now().toIso8601String(),
                  'isForm': 0,
                };

                if (odeme == null) {
                  await _dbHelper.insertOdeme(yeniOdeme);
                } else {
                  await _dbHelper.updateOdeme(yeniOdeme);
                }
                await _fetchOdemeler();
                Navigator.pop(context, 'updated'); // Geri dönüş sonucu
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> odeme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ödemeyi Sil'),
          content: const Text('Bu ödemeyi silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _dbHelper.silOdeme(odeme['id']);
                await _fetchOdemeler();
                Navigator.of(context).pop();
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  static const List<String> _turkceAylar = [
    "Ocak",
    "Şubat",
    "Mart",
    "Nisan",
    "Mayıs",
    "Haziran",
    "Temmuz",
    "Ağustos",
    "Eylül",
    "Ekim",
    "Kasım",
    "Aralık",
  ];

// Tarih biçimlendirme fonksiyonu
  String formatTurkceTarih(DateTime tarih) {
    final gun = tarih.day.toString().padLeft(2, '0');
    final ay = _turkceAylar[tarih.month - 1];
    final yil = tarih.year.toString();
    return "$gun $ay $yil";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
    title: const Text('Nakit Akışı'),
    ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              _openOdemePopup();
            },
            child: const Text('Ödeme Ekle'),
          ),
          Expanded(
            child: _odemeListesi.isEmpty
                ? const Center(child: Text('Henüz ödeme eklenmedi'))
                : ListView.builder(
              itemCount: _odemeListesi.length,
              itemBuilder: (context, index) {
                final odeme = _odemeListesi[index];

                // Türkçe tarih formatı
                final eklemeTarihi = formatTurkceTarih(
                  DateTime.parse(odeme['eklemeTarihi']),
                );

                return GestureDetector(
                  onLongPress: () => _showDeleteConfirmation(odeme),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. Ödeme',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tarih: $eklemeTarihi',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${odeme['miktar']} ${odeme['birim']}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blueAccent),
                                onPressed: () {
                                  _openOdemePopup(odeme: odeme);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
