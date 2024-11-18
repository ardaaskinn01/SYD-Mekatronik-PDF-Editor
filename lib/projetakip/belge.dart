import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart'; // Dosya seçici için import
import 'package:open_file/open_file.dart';

import '../databaseHelper.dart'; // Veritabanı yolu için

class BelgePage extends StatefulWidget {
  final String asamaId; // Asama ID'si

  BelgePage({required this.asamaId});

  @override
  _BelgePageState createState() => _BelgePageState();
}

class _BelgePageState extends State<BelgePage> {
  late Database _db;
  List<Map<String, dynamic>> _belgeler = []; // Belgeler listesi

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  // Veritabanını başlatma
  Future<void> _initializeDatabase() async {
    _db = await DatabaseHelper().database; // DatabaseHelper kullanımı
    _loadDocuments(); // Mevcut belgeleri yükle
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
  }

  // Yeni belge ekleme
  Future<void> _addDocument() async {
    // Dosya seçme
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      // Dosya seçildi
      String fileName = result.files.single.name;
      String filePath = result.files.single.path!;

      // Yeni belge ekleme
      final newDocument = {
        'id': DateTime.now().toString(),
        'asamaId': widget.asamaId,
        'belge': fileName,
        'belgeYolu': filePath,
        'eklemeTarihi': DateTime.now().toIso8601String(),
      };

      await _db.insert('belge2', newDocument);
      _loadDocuments(); // Güncellenmiş listeyi yükle
    }
  }

  // Belge silme
  Future<void> _deleteDocument(String id) async {
    await _db.delete(
      'belge2',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadDocuments(); // Güncellenmiş listeyi yükle
  }

  void _openDocument(String filePath) {
    // Belgeyi aç
    OpenFile.open(filePath);
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
                          onTap: () => _openDocument(belge['belgeYolu']), // Hücreye tıklandığında belgeyi aç
                          child: Text(belge['belge']),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteDocument(belge['id']),
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
