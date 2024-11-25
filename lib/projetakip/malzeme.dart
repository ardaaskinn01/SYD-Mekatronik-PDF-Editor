import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:pdf_editor/projetakip/projeModel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart'; // Dosya seçici için import
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import '../databaseHelper.dart';
import 'ProjeGoreviModel.dart';

class MalzemePage extends StatefulWidget {
  final String asamaId;
  final ProjeGoreviModel gorev;
  final ProjeModel proje;

  MalzemePage({required this.asamaId, required this.gorev, required this.proje});

  @override
  _MalzemePageState createState() => _MalzemePageState();
}

class _MalzemePageState extends State<MalzemePage> {
  late Database _db;
  List<Map<String, dynamic>> _malzemeler = []; // Malzeme listesi

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<bool> requestPermissions() async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
      var status2 = await Permission.accessMediaLocation.status;
      if (!status2.isGranted) {
        await Permission.accessMediaLocation.request();
      }
      var status3 = await Permission.manageExternalStorage.status;
      if (!status3.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      if (status.isGranted || status2.isGranted || status3.isGranted) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _showSnackBar("İzin almak için yetki yok. $e");
      return false;
    }
  }

  Future<void> _yedekle() async {
    bool isAccept = await requestPermissions();
    try {
      if (isAccept) {
        for (var malzeme in _malzemeler) {
            await _downloadNote(malzeme['malzeme']);
        }
      } else {
        _showSnackBar("İzin hatası: Gerekli izinler alınamadı.");
      }
    } catch (e) {
      _showSnackBar("Yedekleme hatası: $e");
    }
  }

  Future<void> _downloadNote(String belge) async {
    try {
      // Veritabanını al
      final db = await DatabaseHelper().database;

      // Ana klasör
      final directoryPath = '/storage/emulated/0/SYD MEKATRONİK';
      final sydFolder = Directory(directoryPath);

      final result2 = await db.query(
        'malzeme',
        columns: ['metin'],
        where: 'malzeme = ?',
        whereArgs: [belge],
      );

      if (result2.first['metin'] != "metinyok") {
        _saveText(belge);
      } else {
        final result = await db.query(
          'malzeme',
          columns: ['belgeYolu'],
          where: 'malzeme = ?',
          whereArgs: [belge],
        );

        if (result.isEmpty) {
          _showSnackBar("Malzeme veritabanında bulunamadı: $belge");
          return;
        }

        // Ekleme tarihini formatla
        final belgeYolu = result.first['belgeYolu'];

        // Görev klasörü oluşturma
        final gorevFolderPath =
            '${sydFolder.path}/${widget.proje.musteriIsmi}/${widget.proje.projeIsmi}/${widget.gorev.gorevAdi}/Malzemeler';
        final gorevFolder = Directory(gorevFolderPath);

        if (!await gorevFolder.exists()) {
          await gorevFolder.create(recursive: true);
        }

        final filePath = '${gorevFolder.path}/$belge';
        final fotoFile = File(belgeYolu.toString());
        if (await fotoFile.exists()) {
          await fotoFile.copy(filePath);
        } else {
          _showSnackBar("Belge bulunamadı: $belge");
        }
      }

    } catch (e) {
      _showSnackBar("Belge kaydedilemedi: $e");
    }
  }

  Future<void> _saveText(String metin) async {
    try {
      // Veritabanını al
      final db = await DatabaseHelper().database;

      final result = await db.query(
        'malzeme',
        columns: ['eklemeTarihi'],
        where: 'metin = ?',
        whereArgs: [metin],
      );

      if (result.isEmpty) {
        _showSnackBar("Ekleme tarihi veritabanında bulunamadı: $metin");
        return;
      }

      // Ekleme tarihini formatla
      final eklemeTarihiRaw = result.first['eklemeTarihi'] as String;
      final eklemeTarihi = DateFormat('yyyyMMdd_HHmmss')
          .format(DateTime.parse(eklemeTarihiRaw));

      // Metni dosyaya kaydet
      final textFile = File('/storage/emulated/0/SYD MEKATRONİK/${widget.proje.musteriIsmi}/${widget.proje.projeIsmi}/${widget.gorev.gorevAdi}/Malzemeler/$eklemeTarihi.txt');
      await textFile.writeAsString(metin);

    } catch (e) {
      _showSnackBar("Metin kaydedilemedi: $e");
    }
  }



  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _initializeDatabase() async {
    _db = await DatabaseHelper().database; // DatabaseHelper kullanımı
    _loadMaterials();
  }

  // Malzemeleri yükleme
  Future<void> _loadMaterials() async {
    final materials = await _db.query(
      'malzeme',
      where: 'asamaId = ?',
      whereArgs: [widget.asamaId],
      orderBy: 'eklemeTarihi ASC',
    );
    setState(() {
      _malzemeler = materials;
    });
    _yedekle();
  }

  // Metin ekleme
  Future<void> _addTextMaterial(String metin) async {
    final newMaterial = {
      'id': DateTime.now().toString(),
      'asamaid': widget.asamaId,
      'malzeme': metin,
      'metin': metin,
      'belgeYolu': null,
      'eklemeTarihi': DateTime.now().toIso8601String(),
    };
    await _db.insert('malzeme', newMaterial);
    _loadMaterials();
  }

  // Belge ekleme
  Future<void> _addFileMaterial() async {
    // Dosya seçme
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      // Dosya seçildi
      String fileName = result.files.single.name;
      String filePath = result.files.single.path!;

      // Yeni malzeme ekleme (dosya ile)
      final newMaterial = {
        'id': DateTime.now().toString(),
        'asamaid': widget.asamaId,
        'malzeme': fileName,
        'metin': "metinyok",
        'belgeYolu': filePath,
        'eklemeTarihi': DateTime.now().toIso8601String(),
      };

      await _db.insert('malzeme', newMaterial);
      _loadMaterials(); // Güncellenmiş listeyi yükle
    }
  }

  void _openDocument(String filePath) {
    // Belgeyi aç
    OpenFile.open(filePath);
  }

  // Malzeme silme
  Future<void> _deleteMaterial(String id) async {
    await _db.delete(
      'malzeme',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadMaterials(); // Güncellenmiş listeyi yükle
  }

  // Malzeme metnini düzenleme
  Future<void> _editMaterial(String id, String currentText) async {
    final TextEditingController _textController = TextEditingController(text: currentText);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Malzeme Düzenle"),
          content: TextField(
            controller: _textController,
            decoration: InputDecoration(hintText: "Metin girin"),
            maxLength: 18, // Maksimum uzunluk 25 karakter
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                final metin = _textController.text.trim();
                if (metin.isNotEmpty) {
                  _updateMaterial(id, metin); // Malzemeyi güncelle
                }
                Navigator.pop(context);
              },
              child: Text("Güncelle"),
            ),
          ],
        );
      },
    );
    _yedekle();
  }

  // Malzeme güncelleme
  Future<void> _updateMaterial(String id, String metin) async {
    await _db.update(
      'malzeme',
      {'malzeme': metin},
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadMaterials(); // Güncellenmiş listeyi yükle
  }

  // Malzeme silme işlemi için onay dialog'ı gösterme
  Future<void> _showDeleteConfirmationDialog(String id) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Silme Onayı"),
          content: Text("Bu malzemeyi silmek istediğinizden emin misiniz?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // İptal, dialog'ı kapat
              },
              child: Text("İptal"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Dialog'ı kapat
                _deleteMaterial(id); // Malzemeyi sil
              },
              child: Text("Evet"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Malzemeler"),
      ),
      body: Column(
        children: [
          // Tablo
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Yatay kaydırma için
              child: DataTable(
                columnSpacing: 16.0,
                dataRowHeight: 56.0,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                columns: [
                  DataColumn(
                    label: Container(
                      child: Text('Eklenme T.', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      child: Text('Malzeme', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text('Sil', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text('Düzenle', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                rows: _malzemeler.map((malzeme) {
                  String displayedText = malzeme['malzeme'];
                  if (displayedText.length > 18) {
                    displayedText = displayedText.substring(0, 18) + '...'; // 25 karakterle sınırlama
                  }

                  return DataRow(
                    cells: [
                      DataCell(Text(malzeme['eklemeTarihi'].substring(0, 10))),
                      DataCell(
                        GestureDetector(
                          onTap: () {
                            if (malzeme['belgeYolu'] != null) {
                              _openDocument(malzeme['belgeYolu']); // Belge yolu null değilse aç
                            }
                          },
                          child: Text(displayedText), // Sınırlı uzunluktaki metni göster
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmationDialog(malzeme['id']), // Silme onayı için popup'ı göster
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editMaterial(malzeme['id'], malzeme['malzeme']), // Düzenleme popup'ını göster
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          // Malzeme Ekleme Butonları
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _addTextMaterial('Yeni Metin'); // Metin ekleme
                  },
                  icon: Icon(Icons.text_fields, size: 20, color: Colors.white),
                  label: Text("Metin Ekle", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(120, 40),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addFileMaterial,
                  icon: Icon(Icons.attach_file, size: 20, color: Colors.white),
                  label: Text("Belge Ekle", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: Size(120, 40),
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
