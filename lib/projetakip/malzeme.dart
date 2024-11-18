import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart'; // Dosya seçici için import
import 'package:open_file/open_file.dart';

import '../databaseHelper.dart';

class MalzemePage extends StatefulWidget {
  final String gorevId; // Görev ID'si

  MalzemePage({required this.gorevId});

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

  Future<void> _initializeDatabase() async {
    _db = await DatabaseHelper().database; // DatabaseHelper kullanımı
    _loadMaterials();
  }

  // Malzemeleri yükleme
  Future<void> _loadMaterials() async {
    final materials = await _db.query(
      'malzeme',
      where: 'asamaId = ?',
      whereArgs: [widget.gorevId],
      orderBy: 'eklemeTarihi ASC',
    );
    setState(() {
      _malzemeler = materials;
    });
  }

  Future<void> _addMaterial({String? metin, String? filePath}) async {
    final newMaterial = {
      'id': DateTime.now().toString(),
      'asamaid': widget.gorevId,
      'malzeme': metin ?? 'Yeni Malzeme', // Eğer metin null ise, 'Yeni Malzeme' kullan
      'metin': metin ?? null,  // Eğer metin boş ise null atıyoruz
      'belgeYolu': filePath ?? null,  // Eğer dosya yolu boş ise null atıyoruz
      'eklemeTarihi': DateTime.now().toIso8601String(),
    };

    await _db.insert('malzeme', newMaterial);
    _loadMaterials(); // Güncellenmiş listeyi yükle
  }

  Future<void> _addMaterialWithFile() async {
    // Dosya seçme
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      // Dosya seçildi
      String fileName = result.files.single.name;
      String filePath = result.files.single.path!;

      // Yeni malzeme ekleme (dosya ile)
      await _addMaterial(metin: fileName, filePath: filePath);
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



  Future<void> _showAddTextDialog() async {
    final TextEditingController _textController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Metin Ekle"),
          content: TextField(
            controller: _textController,
            decoration: InputDecoration(hintText: "Metin girin"),
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
                  _addMaterial(metin: metin);
                }
                Navigator.pop(context);
              },
              child: Text("Ekle"),
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
                ],
                rows: _malzemeler.map((malzeme) {
                  return DataRow(
                    cells: [
                      DataCell(Text(malzeme['eklemeTarihi'].substring(0, 10))),
                      DataCell(
                        GestureDetector(
                          onTap: () {
                            if (malzeme['belgeYolu'] != null) {
                              _openDocument(malzeme['belgeYolu']); // Belge yolu null değilse aç
                            } else {
                              print('Metin: ${malzeme['malzeme']}'); // Eğer belge yolu null ise, metni göster
                            }
                          },
                          child: Text(malzeme['malzeme'] ?? 'Belirtilmedi'), // Null değer kontrolü
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMaterial(malzeme['id']),
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
                  onPressed: () => _addMaterialWithFile(),
                  icon: Icon(Icons.add, size: 20, color: Colors.white),
                  label: Text("Malzeme Ekle", style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddTextDialog(),
                  icon: Icon(Icons.text_fields, size: 20, color: Colors.white),
                  label: Text("Metin Ekle", style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
