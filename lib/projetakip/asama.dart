import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf_editor/projetakip/projeModel.dart';
import '../databaseHelper.dart';
import 'NotModel.dart';
import 'ProjeGoreviModel.dart';
import 'photos.dart'; // Fotoğrafların gösterileceği sayfa
import 'belge.dart'; // Belgelerin gösterileceği sayfa
import 'malzeme.dart'; // Malzemelerin gösterileceği sayfa
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class Asama extends StatefulWidget {
  final ProjeGoreviModel gorev;
  final ProjeModel proje;

  Asama({required this.gorev, required this.proje});

  @override
  _AsamaState createState() => _AsamaState();
}

class _AsamaState extends State<Asama> {
  List<NotModel> notlar = [];
  late String projeIsmi;
  late String musteriIsmi;

  @override
  void initState() {
    super.initState();
    _fetchNotes();

    // Yedekleme işlemini bir sonraki frame'de başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _yedekle();
    });
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
        for (var not in notlar) {
          await _downloadNote(not); // Her bir formu indir
        }
      }
      else {
        _showSnackBar("İzin hatası:");
      }
    } catch (e) {
      _showSnackBar("Yedekleme hatası: $e");
    }
  }

  Future<void> _downloadNote(NotModel not) async {
    try {
      // Ana klasör
      final directoryPath = '/storage/emulated/0/SYD MEKATRONİK';
      final sydFolder = Directory(directoryPath);

      // Proje için alt klasör oluşturma
      final projeFolderPath =
          '${sydFolder.path}/${widget.proje.musteriIsmi}/${widget.proje.projeIsmi}/${widget.gorev.gorevAdi}/Notlar';
      final projeFolder = Directory(projeFolderPath);

      if (!await projeFolder.exists()) {
        await projeFolder.create(recursive: true);
      }

      // Tek bir dosyada notları birleştirme
      final filePath = '${projeFolder.path}/notlar.txt';
      final file = File(filePath);

      // Tüm notları bir String'e birleştirme
      final allNotesContent = notlar.map((not) {
        final eklemeTarih = eklemeTarihi(not.eklemeTarihi);
        return "Tarih: $eklemeTarih\nNot: ${not.note}\n---\n";
      }).join("\n");

      // Dosyaya yazma
      await file.writeAsString(allNotesContent);

    } catch (e) {
      _showSnackBar("Notlar kaydedilemedi: $e");
    }
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addNot(String noteText) async {
    if (noteText.isEmpty) return;

    final newNot = NotModel(
      id: DateTime.now().toIso8601String(),
      asamaId: widget.gorev.id!,
      note: noteText,
      eklemeTarihi: DateTime.now().toIso8601String(),
    );

    await DatabaseHelper().insertNot(newNot);

    setState(() {
      notlar.add(newNot);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Not başarıyla eklendi!")),
    );
  }

  Future<void> _fetchNotes() async {
    final db = DatabaseHelper();
    final List<Map<String, dynamic>> notesMap =
    await (await db.database).query('note', where: 'asamaId = ?', whereArgs: [widget.gorev.id]);

    setState(() {
      notlar = notesMap.map((note) => NotModel.fromMap(note)).toList();
    });
  }

  void _showDeleteDialog(BuildContext context, NotModel note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Notu Silmek İstiyor Musunuz?"),
        content: Text("Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Hayır"),
          ),
          TextButton(
            onPressed: () async {
              final db = DatabaseHelper();
              await db.deleteNote(note.id);

              setState(() {
                notlar.remove(note);
              });

              Navigator.pop(context);
            },
            child: Text("Evet"),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final TextEditingController _popupController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Not Ekle"),
        content: TextField(
          controller: _popupController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: "Not Girin",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal"),
          ),
          TextButton(
            onPressed: () {
              final noteText = _popupController.text;
              _addNot(noteText);
              Navigator.pop(context);
            },
            child: Text("Ekle"),
          ),
        ],
      ),
    );
  }

  void _showPhotosPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotosPage(asamaId: widget.gorev.id!, gorev: widget.gorev, proje: widget.proje),
      ),
    );
  }

  String eklemeTarihi(String tarih) {
    try {
      final DateTime parsedDate = DateTime.parse(tarih);
      final DateFormat formatter = DateFormat('dd.MM.yyyy');
      return formatter.format(parsedDate);
    } catch (e) {
      // Tarihi parse edemezse, "Geçersiz tarih" döndür
      return "Geçersiz tarih";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gorev.gorevAdi),
      ),
      body: Column(
        children: [
          // Not Listesi
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: notlar.length,
                      itemBuilder: (context, index) {
                        final note = notlar[index];
                        return ListTile(
                          title: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: "${eklemeTarihi(note.eklemeTarihi)}: ",
                                  style: const TextStyle(fontWeight: FontWeight.normal),
                                ),
                                TextSpan(
                                  text: note.note,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          onLongPress: () => _showDeleteDialog(context, note),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _showAddNoteDialog(context),
                    child: Text("Not Ekle"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      elevation: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fotoğraflar ve Butonlar
          Expanded(
            flex: 1,
            child: Row(
              children: [
                // Fotoğraf Ekleme
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showPhotosPage(context),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 30),
                        SizedBox(height: 5),
                        Text("Fotoğraf Ekle", style: TextStyle(fontSize: 17)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BelgePage(asamaId: widget.gorev.id!,  gorev: widget.gorev, proje: widget.proje),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.attach_file, size: 30),
                        SizedBox(height: 5),
                        Text("Belge Ekle", style: TextStyle(fontSize: 17)),
                      ],
                    ),
                  ),
                ),

                // Malzeme Ekleme
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MalzemePage(asamaId: widget.gorev.id!, gorev: widget.gorev, proje: widget.proje),
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list, size: 30),
                        SizedBox(height: 5),
                        Text("Malzeme Ekle", style: TextStyle(fontSize: 17)),
                      ],
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