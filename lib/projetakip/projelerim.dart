import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf_editor/databaseHelper.dart';
import 'package:pdf_editor/projetakip/projeModel.dart';
import 'projeNakit.dart';
import 'projeProfil.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class Projelerim extends StatefulWidget {
  final int initialTabIndex;

  Projelerim({this.initialTabIndex = 0});
  @override
  _ProjelerimState createState() => _ProjelerimState();
}

class _ProjelerimState extends State<Projelerim>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<ProjeModel> _devamEdenProjeler = [];
  List<ProjeModel> _tamamlananProjeler = [];
  List<ProjeModel> _tumProjeler = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _fetchProjeler();
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
      return false;
    }
  }

  Future<void> _yedekle() async {
    try {
      bool isAccept = await requestPermissions();
      if (isAccept) {
        const directoryPath = '/storage/emulated/0/SYD MEKATRONİK';
        final sydFolder = Directory(directoryPath);


        // SYD MEKATRONİK klasörünü kontrol et ve yoksa oluştur
        if (!await sydFolder.exists()) {
          await sydFolder.create(recursive: true);
          _showSnackBar(
              "Dahili Depolama üzerindeki SYD MEKATRONİK klasörü oluşturuldu.");
        }

        // Veritabanındaki formları listeleme
        final projeler = _tumProjeler; // Veritabanındaki formlar

        for (var proje in projeler) {
          await _createDirectory(proje, sydFolder); // Her bir formu indir
        }
      } else {
        _showSnackBar("İzin Yok");
      }
    } catch (e) {
      _showSnackBar("Yedekleme hatası: $e");
    }
  }

  Future<void> _createDirectory(ProjeModel proje, Directory sydFolder) async {
    try {
      final projeMusteriName = _sanitizeFileName(proje.musteriIsmi);
      // Proje adına uygun alt klasör oluştur
      final projeFolderName = _sanitizeFileName(proje.projeIsmi);
      final projeFolderPath2 = '${sydFolder.path}/$projeMusteriName/$projeFolderName';
      final projeFolder2 = Directory(projeFolderPath2);

      if (!await projeFolder2.exists()) {
        await projeFolder2.create(recursive: true);
        _showSnackBar("${proje.projeIsmi} klasörü, ${proje.musteriIsmi} klasörü içinde oluşturuldu.");
      }
    } catch (e) {
      _showSnackBar("${proje.projeIsmi} ve ${proje.musteriIsmi} için klasör oluşturulamadı: $e");
    }
  }

// Dosya adlarını güvenli hale getirmek için uygunsuz karakterleri kaldırır
  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  Future<void> _fetchProjeler() async {
    final projeler = await _dbHelper.getProjeler();
    setState(() {
      _tumProjeler = projeler;
      _devamEdenProjeler =
          projeler.where((proje) => !proje.isFinish).toList();
      _tamamlananProjeler =
          projeler.where((proje) => proje.isFinish).toList();
    });
    _yedekle();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projelerim'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Devam Edenler'),
            const Tab(text: 'Tamamlananlar'),
          ],
        ),
      ),
      body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProjeList(_devamEdenProjeler),
              _buildProjeList(_tamamlananProjeler),
            ],
          ),
        ),
    );
  }

  Widget _buildProjeList(List<ProjeModel> projeler) {
    return projeler.isEmpty
        ? Center(
      child: Text(
        'Henüz bu kategoride projeniz yok',
        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
      ),
    )
        : ListView.builder(
      itemCount: projeler.length,
      itemBuilder: (context, index) {
        final proje = projeler[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjeProfil(proje: proje),
              ),
            );
          },
          onLongPress: () {
            _showOptionsDialog(proje);
          },
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: Colors.greenAccent[200],
            color: Colors.white.withOpacity(0.8),
            child: Container(
              margin: const EdgeInsets.all(8.0),
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder,
                        color: Colors.teal[700],
                        size: 28,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          proje.projeIsmi,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 5),
                      FutureBuilder<String>(
                        future: formattedText(proje),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text(
                              'Yükleniyor...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return const Text(
                              'Hata!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            );
                          } else {
                            return Text(
                              snapshot.data ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    proje.musteriIsmi,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 35),
                  Text(
                    proje.isFinish == false
                        ? "Devam Ediyor"
                        : "Tamamlandı",
                    style: TextStyle(
                      fontSize: 15,
                      color: proje.isFinish == false
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOptionsDialog(ProjeModel proje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("İşlem Seçin"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red, size: 32),
                  title: const Text('Projeyi Sil'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showDeleteConfirmationDialog(proje);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(
                    proje.isFinish ? Icons.replay : Icons.check_circle,
                    color: proje.isFinish ? Colors.blue : Colors.green,
                    size: 32,
                  ),
                  title: Text(
                      proje.isFinish ? 'Projeye Devam Et' : 'Projeyi Bitir'),
                  onTap: () {
                    if (proje.isFinish) {
                      _devamEttirProje(proje);
                    } else {
                      _bitirProje(proje);
                    }
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.cancel, color: Colors.grey, size: 32),
                  title: const Text('İptal'),
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(ProjeModel proje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Emin misiniz?"),
          content: const Text("Bu projeyi silmek istediğinizden emin misiniz?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Kapatma işlemi
              },
              child: const Text("Hayır"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Kapatma işlemi
                await _silProje(proje.id!);  // Projeyi silme işlemi
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proje silindi.')),
                );
              },
              child: const Text("Evet"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _silProje(String projeId) async {
    await _dbHelper.deleteProje(projeId);
    _fetchProjeler();
  }

  Future<void> _bitirProje(ProjeModel proje) async {
    try {
      await _dbHelper.updateProje(proje, {'isFinish': 1});
      _fetchProjeler();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proje bitirilemedi: $e')),
      );
    }
  }

  Future<void> _devamEttirProje(ProjeModel proje) async {
    try {
      await _dbHelper.updateProje(proje, {'isFinish': 0});
      _fetchProjeler();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Proje devam ettirilemedi: $e')),
      );
    }
  }
}

Future<String> formattedText(ProjeModel proje) async {
  final formattedDate = DateFormat('dd.MM.yyyy').format(proje.baslangicTarihi!);
  return formattedDate;
}
