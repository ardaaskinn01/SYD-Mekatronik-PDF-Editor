import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf_editor/projetakip/ProjeGoreviModel.dart';
import 'package:pdf_editor/projetakip/projeModel.dart';
import 'package:share_plus/share_plus.dart'; // SharePlus kütüphanesini ekleyin
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../databaseHelper.dart';

class PhotosPage extends StatefulWidget {
  final String asamaId;
  final ProjeGoreviModel gorev;
  final ProjeModel proje;

  PhotosPage({required this.asamaId, required this.gorev, required this.proje});

  @override
  _PhotosPageState createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  Map<String, List<String>> imagePaths = {};
  Set<String> selectedPhotos = {};
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
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
        for (var entry in imagePaths.entries) {
          for (var foto in entry.value) {
            await _downloadNote(foto); // Her fotoğrafı indir
          }
        }
      } else {
        _showSnackBar("İzin hatası: Gerekli izinler alınamadı.");
      }
    } catch (e) {
      _showSnackBar("Yedekleme hatası: $e");
    }
  }

  Future<void> _downloadNote(String foto) async {
    try {
      // Veritabanını al
      final db = await DatabaseHelper().database;

      // Fotoğrafın ekleme tarihini sorgula
      final result = await db.query(
        'gorsel',
        columns: ['eklemeTarihi'],
        where: 'gorsel = ?',
        whereArgs: [foto],
      );

      if (result.isEmpty) {
        _showSnackBar("Ekleme tarihi veritabanında bulunamadı: $foto");
        return;
      }

      // Ekleme tarihini formatla
      final eklemeTarihiRaw = result.first['eklemeTarihi'] as String;
      final eklemeTarihi =
      DateFormat('yyyyMMdd_HHmmss').format(DateTime.parse(eklemeTarihiRaw));

      // Ana klasör
      final directoryPath = '/storage/emulated/0/SYD MEKATRONİK';
      final sydFolder = Directory(directoryPath);

      // Görev klasörü oluşturma
      final gorevFolderPath =
          '${sydFolder.path}/${widget.proje.musteriIsmi}/${widget.proje
          .projeIsmi}/${widget.gorev.gorevAdi}/Fotoğraflar';
      final gorevFolder = Directory(gorevFolderPath);

      if (!await gorevFolder.exists()) {
        await gorevFolder.create(recursive: true);
      }

      // Dosya yolu
      final filePath = '${gorevFolder.path}/$eklemeTarihi.jpg';

      // Fotoğrafı al ve kaydet
      final fotoFile = File(foto);
      if (await fotoFile.exists()) {
        await fotoFile.copy(filePath);
      } else {
        _showSnackBar("Fotoğraf bulunamadı: $foto");
      }
    } catch (e) {
      _showSnackBar("Fotoğraf kaydedilemedi: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'asama_${widget.asamaId}_${DateTime.now().toIso8601String()}.jpg';
        final savedImage =
        await File(pickedFile.path).copy('${appDir.path}/$fileName');

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

  Future<void> _addPhotos() async {
    try {
      final picker = ImagePicker();
      final pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();

        for (var pickedFile in pickedFiles) {
          final fileName =
              'asama_${widget.asamaId}_${DateTime.now().toIso8601String()}.jpg';
          final savedImage =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');

          final db = await DatabaseHelper().database;
          final eklemeTarihi = DateTime.now().toIso8601String();

          await db.insert('gorsel', {
            'asamaId': widget.asamaId,
            'gorsel': savedImage.path,
            'eklemeTarihi': eklemeTarihi,
          });
        }
        _loadPhotos();
      }
    } catch (e) {
      print("Hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fotoğraflar eklerken bir hata oluştu: $e")),
      );
    }
  }


  Future<void> _loadPhotos() async {
    try {
      final db = await DatabaseHelper().database;
      final result = await db
          .query('gorsel', where: 'asamaId = ?', whereArgs: [widget.asamaId]);

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
    _yedekle();
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
                _addPhotos();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteSelectedPhotos() async {
    try {
      final db = await DatabaseHelper().database;
      for (String path in selectedPhotos) {
        await db.delete(
          'gorsel',
          where: 'gorsel = ?',
          whereArgs: [path],
        );
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      setState(() {
        selectedPhotos.clear(); // Seçilen fotoğrafları temizle
      });
      _loadPhotos(); // Fotoğrafları yenile

    } catch (e) {
      print("Hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fotoğraflar silinirken bir hata oluştu: $e")),
      );
    }
  }

  // Paylaşma işlemi
  Future<void> _shareSelectedPhotos() async {
    try {
      final xFiles = selectedPhotos.map((path) => XFile(path)).toList();
      await Share.shareXFiles(xFiles);
    } catch (e) {
      print("Paylaşırken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Fotoğraflar paylaşılırken bir hata oluştu: $e")),
      );
    }
  }

  void _showPreview(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            Scaffold(
              appBar: AppBar(title: Text("Önizleme")),
              body: Center(
                child: Image.file(File(path)),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Scaffold(
      appBar: AppBar(title: Text("Fotoğraflar")),
      body: GestureDetector(
        onTap: () {
          // Boş bir alana tıklandığında seçim modunu kapat
          if (_isSelecting) {
            setState(() {
              _isSelecting = false;
            });
          }
        },
        child: Column(
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
                            onTap: () {
                              if (_isSelecting) {
                                setState(() {
                                  if (selectedPhotos.contains(photos[idx])) {
                                    selectedPhotos.remove(photos[idx]);
                                  } else {
                                    selectedPhotos.add(photos[idx]);
                                  }
                                });
                              } else {
                                _showPreview(photos[idx]);
                              }
                            },
                            onLongPress: () {
                              setState(() {
                                _isSelecting = true;
                              });
                            },
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(
                                    File(photos[idx]),
                                    fit: BoxFit.cover,
                                    width: screenWidth / 3 - 16,
                                    height: screenWidth / 3 - 16,
                                  ),
                                ),
                                if (_isSelecting)
                                  Positioned(
                                    top: 8.0,
                                    right: 8.0,
                                    child: Checkbox(
                                      value: selectedPhotos.contains(
                                          photos[idx]),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            selectedPhotos.add(photos[idx]);
                                          } else {
                                            selectedPhotos.remove(photos[idx]);
                                          }
                                        });
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
            // Seçim modunda olan butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: selectedPhotos.isEmpty
                      ? null
                      : () {
                    _deleteSelectedPhotos();
                    setState(() {
                      _isSelecting = false;
                    });
                  },
                  child: Text("Seçilenleri Sil"),
                ),
                ElevatedButton(
                  onPressed: selectedPhotos.isEmpty
                      ? null
                      : () {
                    _shareSelectedPhotos();
                    setState(() {
                      _isSelecting = false;
                    });
                  },
                  child: Text("Seçilenleri Paylaş"),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPhotoDialog,
        child: Icon(Icons.add_a_photo),
      ),
    );
  }
}