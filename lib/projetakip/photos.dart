import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

import '../databaseHelper.dart';

class PhotosPage extends StatefulWidget {
  final String asamaId;

  PhotosPage({required this.asamaId});

  @override
  _PhotosPageState createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  Map<String, List<String>> imagePaths = {};

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'asama_${widget.asamaId}_${DateTime.now().toIso8601String()}.jpg';
        final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');

        final db = await DatabaseHelper().database;
        final eklemeTarihi = DateTime.now().toIso8601String();

        await db.insert('gorsel', {
          'asamaId': widget.asamaId,
          'gorsel': savedImage.path,
          'eklemeTarihi': eklemeTarihi,
        });

        _loadPhotos();
      }
    } catch (e) {
      print("Hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fotoğraf eklerken bir hata oluştu: $e")),
      );
    }
  }

  Future<void> _deletePhoto(String path) async {
    try {
      final db = await DatabaseHelper().database;

      await db.delete(
        'gorsel',
        where: 'gorsel = ?',
        whereArgs: [path],
      );

      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }

      setState(() {
        imagePaths = {};
      });
      _loadPhotos();
    } catch (e) {
      print("Hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fotoğraf silinirken bir hata oluştu: $e")),
      );
    }
  }

  Future<void> _loadPhotos() async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db.query('gorsel', where: 'asamaId = ?', whereArgs: [widget.asamaId]);

      Map<String, List<String>> groupedPhotos = {};
      for (var photo in result) {
        final String photoPath = photo['gorsel'] as String;
        final String eklemeTarihi = photo['eklemeTarihi'] as String;

        final date = DateTime.parse(eklemeTarihi);
        final weekOfYear = DateFormat("yyyy-MM-dd").format(date);

        if (!groupedPhotos.containsKey(weekOfYear)) {
          groupedPhotos[weekOfYear] = [];
        }

        groupedPhotos[weekOfYear]?.add(photoPath);
      }

      setState(() {
        imagePaths = groupedPhotos;
      });
    } catch (e) {
      print("Hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fotoğraflar yüklenirken bir hata oluştu: $e")),
      );
    }
  }

  Future<void> _showAddPhotoDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text("Kamera"),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text("Galeri"),
              onTap: () {
                Navigator.pop(context);
                _addPhoto(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteConfirmationDialog(String path) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Fotoğrafı Sil"),
          content: Text("Bu fotoğrafı silmek istiyor musunuz?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("İptal"),
            ),
            TextButton(
              onPressed: () {
                _deletePhoto(path);
                Navigator.pop(context);
              },
              child: Text("Sil"),
            ),
          ],
        );
      },
    );
  }

  void _showPreview(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text("Önizleme")),
          body: Center(
            child: Image.file(File(path)),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: Text("Fotoğraflar")),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                final group = imagePaths.keys.toList()[index];
                final photos = imagePaths[group]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(2, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        group,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, idx) {
                        return GestureDetector(
                          onTap: () => _showPreview(photos[idx]),
                          onLongPress: () => _showDeleteConfirmationDialog(photos[idx]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.file(
                              File(photos[idx]),
                              fit: BoxFit.cover,
                              width: screenWidth / 3 - 16,
                              height: screenWidth / 3 - 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                backgroundColor: Colors.green,
              ),
              onPressed: _showAddPhotoDialog,
              icon: Icon(Icons.add_a_photo, size: 27.0),
              label: Text("Fotoğraf Ekle", style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          ),
        ],
      ),
    );
  }
}
