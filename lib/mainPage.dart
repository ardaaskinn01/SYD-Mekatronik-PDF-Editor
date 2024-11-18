import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:pdf_editor/projetakip/ProjeGoreviModel.dart';
import 'databaseHelper.dart';
import 'package:pdf_editor/form/formModel.dart';
import 'form/formModel3.dart';
import 'package:pdf_editor/form/formolustur.dart';
import 'form/gecmisformlar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf_editor/projetakip/projelerim.dart';
import 'package:pdf_editor/projetakip/projeEkle.dart';

class Anasayfa extends StatefulWidget {
  const Anasayfa({super.key});

  @override
  _AnasayfaState createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  @override
  void initState() {
    super.initState();
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
    try {
      bool isAccept = await requestPermissions();
      if (isAccept) {
        final directory = await getExternalStorageDirectory();
        final directoryPath = '${directory!.path}/SYD MEKATRONİK';
        final sydFolder = Directory(directoryPath);

        // SYD MEKATRONİK klasörünü kontrol et ve yoksa oluştur
        if (!await sydFolder.exists()) {
          await sydFolder.create(recursive: true);
          _showSnackBar(
              "Dahili Depolama üzerindeki SYD MEKATRONİK klasörü oluşturuldu.");
        }

        // Veritabanındaki formları listeleme
        final dbForms = await _getFormsByMusteri(); // Veritabanındaki formlar

        for (var form in dbForms) {
          await _downloadForm(form); // Her bir formu indir
        }

        _showSnackBar("Tüm formlar başarıyla indirildi.");
      }
      else {
        _showSnackBar("İzin hatası:");
      }
    } catch (e) {
      _showSnackBar("Yedekleme hatası: $e");
    }
  }

  Future<void> _downloadForm(FormModel form) async {
    final directoryPath =
        '/storage/emulated/0/SYD MEKATRONİK/${form.musteriAdSoyad}';
    final sydFolder = Directory(directoryPath);

    if (!await sydFolder.exists()) {
      await sydFolder.create(recursive: true);
    }

    final filePath = '${sydFolder.path}/${form.num}.pdf';
    final file = File(filePath);
    final originalFile = File(form.pdfFilePath);

    await file.writeAsBytes(await originalFile.readAsBytes());
  }

  Future<List<FormModel>> _getFormsByMusteri() async {
    final DatabaseHelper dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps =
    await db.query('forms_2'); // Veritabanından sorgu

    // Listede `FormModel` nesnelerini oluşturma
    return List.generate(maps.length, (i) {
      return FormModel(
        num: maps[i]['num'],
        pdfFilePath: maps[i]['pdfFilePath'],
        musteriAdSoyad: maps[i]['musteriAdSoyad'],
        tarih: maps[i]['tarih'],
      );
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan görüntüsü
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/wallpaper.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.lightGreen.withOpacity(0.3),
            ),
          ),
          Column(
            children: [
              // Üst grup: Form oluştur, Geçmiş formlar ve Yedekle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start, // Butonları üst kısma yerleştiriyoruz
                  children: [
                    SizedBox(height: screenHeight * 0.2),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FormOlustur(form: FormModel3(), id: 0),
                          ),
                        );
                      },
                      icon: Icon(Icons.add_circle, color: Colors.black),
                      label: const Text(
                        'Form Oluştur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.12,
                          vertical: screenHeight * 0.015,
                        ),
                        backgroundColor: Colors.greenAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 10,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => GecmisFormlar()),
                        );
                      },
                      icon: Icon(Icons.history, color: Colors.white),
                      label: const Text(
                        'Geçmiş Formlar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.12,
                          vertical: screenHeight * 0.015,
                        ),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 10,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _yedekle();
                      },
                      icon: Icon(Icons.backup, color: Colors.yellow),
                      label: const Text(
                        'Yedekle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.yellow,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.12,
                          vertical: screenHeight * 0.015,
                        ),
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 10,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.15), // Butonlar ile görevler arasındaki boşluk
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Projelerim()),
                        );
                      },
                      icon: Icon(Icons.folder, color: Colors.white),
                      label: const Text(
                        'Projelerim',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.12,
                          vertical: screenHeight * 0.015,
                        ),
                        backgroundColor: Colors.purpleAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 10,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ProjeEkle()),
                        );
                      },
                      icon: Icon(Icons.add_box, color: Colors.white),
                      label: const Text(
                        'Proje Ekle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.12,
                          vertical: screenHeight * 0.015,
                        ),
                        backgroundColor: Colors.pinkAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        elevation: 10,
                      ),
                    ),
                  ],
                ),
              ),


            ],
          ),
        ],
      ),
    );
  }
}
