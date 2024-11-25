import 'dart:io';

import 'package:flutter/material.dart';
import '../databaseHelper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'formModel.dart';
import 'musteriFormlariScreen.dart'; // Müşteri formlarının listelendiği yeni ekran

class GecmisFormlar extends StatefulWidget {
  @override
  _GecmisFormlarState createState() => _GecmisFormlarState();
}

class _GecmisFormlarState extends State<GecmisFormlar> {
  late Future<List<FormModel>> futureForms;
  List<FormModel> allForms = [];
  List<FormModel> filteredForms = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureForms = DatabaseHelper().getForms(); // Veritabanından formları çek
    futureForms.then((forms) {
      setState(() {
        allForms = forms;
        filteredForms = allForms;
      });
    });
    searchController.addListener(_onSearchChanged);
    _yedekle();
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
        final directoryPath = '/storage/emulated/0/SYD MEKATRONİK';
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
      } else {
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
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredForms = allForms.where((form) {
        return form.musteriAdSoyad.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white12.withOpacity(0.9), // Optional for some transparency
      appBar: AppBar(
        title: Text('Geçmiş Formlar'),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/logo2.jpeg'),
            fit: BoxFit.contain,  // Use cover to fill the screen, can adjust as needed
            colorFilter: ColorFilter.mode(
              Colors.grey.withOpacity(0.5), // Adjust opacity as needed
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Müşteri adı ara',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<FormModel>>(
                future: futureForms,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return SafeArea(child: Text('Hiç form bulunamadı.', style: TextStyle(color: Colors.red),));
                  } else {
                    final groupedForms = _groupFormsByCustomer(filteredForms);

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      itemCount: groupedForms.keys.length,
                      itemBuilder: (context, index) {
                        final musteriAdSoyad = groupedForms.keys.elementAt(index);
                        final forms = groupedForms[musteriAdSoyad]!;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              leading: Icon(
                                Icons.folder,
                                color: Colors.teal,
                                size: 36,
                              ),
                              title: Text(
                                musteriAdSoyad,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                '${forms.length} form',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.teal,
                                size: 20,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MusteriFormlariScreen(musteriAdSoyad: musteriAdSoyad, forms: forms),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<FormModel>> _groupFormsByCustomer(List<FormModel> forms) {
    Map<String, List<FormModel>> groupedForms = {};

    for (var form in forms) {
      if (!groupedForms.containsKey(form.musteriAdSoyad)) {
        groupedForms[form.musteriAdSoyad] = [];
      }
      groupedForms[form.musteriAdSoyad]!.add(form);
    }

    return groupedForms;
  }
}
