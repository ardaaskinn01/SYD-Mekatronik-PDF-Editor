import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf_editor/projetakip/projeModel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import '../databaseHelper.dart'; // Veritabanı yolu için
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'ProjeGoreviModel.dart';

class BelgePage extends StatefulWidget {
  final String asamaId;
  final ProjeGoreviModel gorev;
  final ProjeModel proje;

  BelgePage({required this.asamaId, required this.gorev, required this.proje});

  @override
  _BelgePageState createState() => _BelgePageState();
}

class _BelgePageState extends State<BelgePage> {
  late Database _db;
  List<Map<String, dynamic>> _belgeler = [];

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
        for (var belge in _belgeler) {
          await _downloadNote(belge['belge']); // Her belgeyi indir
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

      // Fotoğrafın ekleme tarihini sorgula
      final result = await db.query(
        'belge2',
        columns: ['belgeYolu'],
        where: 'belge = ?',
        whereArgs: [belge],
      );

      if (result.isEmpty) {
        _showSnackBar("Belge veritabanında bulunamadı: $belge");
        return;
      }

      // Ekleme tarihini formatla
      final belgeYolu = result.first['belgeYolu'];

      // Görev klasörü oluşturma
      final gorevFolderPath =
          '${sydFolder.path}/${widget.proje.musteriIsmi}/${widget.proje.projeIsmi}/${widget.gorev.gorevAdi}/Belgeler';
      final gorevFolder = Directory(gorevFolderPath);

      if (!await gorevFolder.exists()) {
        await gorevFolder.create(recursive: true);
      }

      // Dosya yolu
      final filePath = '${gorevFolder.path}/$belge';
      final fotoFile = File(belgeYolu.toString());
      print(fotoFile.existsSync());
      if (await fotoFile.exists()) {
        await fotoFile.copy(filePath);
      } else {
        _showSnackBar("Belge bulunamadı: $belge");
      }
    } catch (e) {
      _showSnackBar("Belge kaydedilemedi: $e");
    }
  }



  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Veritabanını başlatma
  Future<void> _initializeDatabase() async {
    _db = await DatabaseHelper().database;
    _loadDocuments();
  }

  // Belgeleri yükleme
  Future<void> _loadDocuments() async {
    final documents = await _db.query(
      'belge2',
      where: 'asamaId = ?',
      whereArgs: [widget.asamaId],
      orderBy: 'eklemeTarihi ASC',
    );
    setState(() {
      _belgeler = documents;
    });
    _yedekle();
  }

  // Yeni belge ekleme
  Future<void> _addDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      String fileName = result.files.single.name;
      String filePath = result.files.single.path!;

      final newDocument = {
        'id': DateTime.now().toString(),
        'asamaId': widget.asamaId,
        'belge': fileName,
        'belgeYolu': filePath,
        'eklemeTarihi': DateTime.now().toIso8601String(),
      };

      await _db.insert('belge2', newDocument);
      _loadDocuments();
    }
  }

  // Belgeyi aç
  void _openDocument(String filePath) {
    OpenFile.open(filePath);
  }

  // Belge silme onayı gösterme
  Future<void> _confirmDeleteDocument(String id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Silme Onayı'),
          content: Text('Bu belgeyi silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Silme işlemi yapılacak
                _deleteDocument(id);
                Navigator.of(context).pop(); // Dialog'u kapat
              },
              child: Text('Evet', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog'u kapat
              },
              child: Text('Hayır'),
            ),
          ],
        );
      },
    );
  }

  // Belge silme
  Future<void> _deleteDocument(String id) async {
    await _db.delete(
      'belge2',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Belgeler"),
      ),
      body: Column(
        children: [
          // Tablo
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text('Belge', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  DataColumn(
                    label: Container(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text('Sil', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
                rows: _belgeler.map((belge) {
                  return DataRow(
                    cells: [
                      DataCell(Text(belge['eklemeTarihi'].substring(0, 10))),
                      DataCell(
                        GestureDetector(
                          onTap: () => _openDocument(belge['belgeYolu']),
                          child: Text(belge['belge']),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteDocument(belge['id']),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          // Belge Ekleme Butonu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _addDocument,
              icon: Icon(Icons.upload_file, size: 24, color: Colors.white),
              label: Text("Belge Ekle", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
