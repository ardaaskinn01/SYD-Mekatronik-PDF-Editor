import 'package:flutter/material.dart';
import '../databaseHelper.dart';
import 'NotModel.dart';
import 'ProjeGoreviModel.dart';
import 'photos.dart'; // Fotoğrafların gösterileceği sayfa
import 'belge.dart'; // Belgelerin gösterileceği sayfa
import 'malzeme.dart'; // Malzemelerin gösterileceği sayfa
import 'package:intl/intl.dart';

class Asama extends StatefulWidget {
  final ProjeGoreviModel gorev;

  Asama({required this.gorev});

  @override
  _AsamaState createState() => _AsamaState();
}

class _AsamaState extends State<Asama> {
  List<NotModel> notlar = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
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
        builder: (context) => PhotosPage(asamaId: widget.gorev.id!),
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
                          builder: (context) => BelgePage(asamaId: widget.gorev.id!),
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
                          builder: (context) => MalzemePage(gorevId: widget.gorev.id!),
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