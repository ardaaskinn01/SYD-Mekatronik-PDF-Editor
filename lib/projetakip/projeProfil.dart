import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_editor/projetakip/projeModel.dart';
import 'ProjeGoreviModel.dart';
import '../databaseHelper.dart';
import 'asama.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class ProjeProfil extends StatefulWidget {
  final ProjeModel proje;

  const ProjeProfil({Key? key, required this.proje}) : super(key: key);

  @override
  _ProjeProfilState createState() => _ProjeProfilState();
}

class _ProjeProfilState extends State<ProjeProfil> {
  late ProjeModel proje;
  List<ProjeGoreviModel> projeGorevleri = [];

  @override
  void initState() {
    super.initState();
    proje = widget.proje;
    _loadProjeGorevleri();
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
      // İzin kontrolü
      if (isAccept) {
        final directoryPath =
            '/storage/emulated/0/SYD MEKATRONİK/${proje.musteriIsmi}/${proje
            .projeIsmi}';
        final sydFolder = Directory(directoryPath);

        // Veritabanındaki formları listeleme
        final asamalar = projeGorevleri; // Veritabanındaki formlar

        for (var asama in asamalar) {
          await _createDirectory(asama, sydFolder); // Her bir formu indir
        }
      }
      else {
        _showSnackBar("İzin hatası:");
      }
    } catch (e) {
      _showSnackBar("Yedekleme hatası: $e");
    }
  }

  Future<void> _createDirectory(ProjeGoreviModel asama, Directory sydFolder) async {
    try {

      final projeFolderPath3 = '${sydFolder.path}/${asama.gorevAdi}';
      final projeFolder3 = Directory(projeFolderPath3);

      if (!await projeFolder3.exists()) {
        await projeFolder3.create(recursive: true);
        _showSnackBar("${asama.gorevAdi} için klasör oluşturuldu.");
      }
    } catch (e) {
      _showSnackBar("${asama.gorevAdi} için klasör oluşturulamadı: $e");
    }
  }

    void _showSnackBar(String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

  // Proje görevlerini veritabanından yükleme
  void _loadProjeGorevleri() async {
    final gorevler = await DatabaseHelper().getProjeGorevleri(proje.id);
    setState(() {
      projeGorevleri = gorevler;
    });
    _yedekle();
  }

  String formatDateTurkish(DateTime? date) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${date!.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          proje.projeIsmi,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Başlangıç: ${formatDateTurkish(proje.baslangicTarihi)}',
                  style: TextStyle(fontSize: 12, color: Colors.black),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(
              title: "Proje Sahibi Firma",
              content: proje.musteriIsmi,
              icon: Icons.person,
              backgroundColor: Colors.blue.shade50,
            ),
            SizedBox(height: 10),
            _buildInfoCard(
              title: "Proje Açıklaması",
              content: proje.projeAciklama,
              icon: Icons.description,
              backgroundColor: Colors.green.shade50,
            ),
            SizedBox(height: 16),
            _buildSectionTitle("Aşamalar"),
            _buildTaskList(),
            if (!proje.isFinish) // Butonu gizlemek için kontrol
              ElevatedButton.icon(
                onPressed: () {
                  final gorevAdi = 'Aşama ${projeGorevleri.length + 1}';
                  final currentDate = DateTime.now();
                  final gorev = ProjeGoreviModel(
                    id: DateTime.now().toString(),
                    projeId: proje.id!,
                    gorevAdi: gorevAdi,
                    eklemeTarihi: currentDate,
                  );

                  setState(() {
                    projeGorevleri.add(gorev); // Yeni görev ekleniyor
                  });

                  // Görevi veritabanına ekliyoruz
                  DatabaseHelper().insertProjeGorevi(proje.id, gorev);

                  // Sayfayı yenileyerek yeni görevi göstermek için
                  _loadProjeGorevleri();
                },
                icon: Icon(Icons.add, color: Colors.black),
                label: Text(
                  'Aşama Ekle',
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content, required IconData icon, Color? backgroundColor}) {
    return Card(
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueGrey, size: 40),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 8),
                  Text(
                    content,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.teal),
      ),
    );
  }

  void silGorev(int index) async {
    final gorevId = projeGorevleri[index].id!;

    // Kullanıcıya onay sormak için bir pop-up dialog göster
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Aşama Sil'),
          content: Text('Bu aşamayı silmek istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Silme işlemi iptal edilir
              },
              child: Text('Hayır'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Silme işlemi onaylanır
              },
              child: Text('Evet'),
            ),
          ],
        );
      },
    );

    // Eğer kullanıcı "Evet" derse, silme işlemini gerçekleştir
    if (confirmDelete ?? false) {
      // Veritabanından silme
      await DatabaseHelper().deleteGorev(gorevId);

      // Görevi listeden ve veritabanından sil
      setState(() {
        projeGorevleri.removeAt(index);
      });

      // Aşama numaralarını yeniden düzenle
      for (int i = 0; i < projeGorevleri.length; i++) {
        projeGorevleri[i].gorevAdi = 'Aşama ${i + 1}'; // Numara sıfırlanır
        await DatabaseHelper().updateProjeGorevi(projeGorevleri[i]); // Güncelleme işlemi
      }

      // Sayfayı yenileyerek görev listesini güncelle
      _loadProjeGorevleri();
    }
  }


  Widget _buildTaskList() {
    return FutureBuilder<List<ProjeGoreviModel>>(
      future: DatabaseHelper().getProjeGorevleri(proje.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final gorevler = snapshot.data ?? [];
        gorevler.sort((a, b) => a.eklemeTarihi.compareTo(b.eklemeTarihi));

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: gorevler.length,
          itemBuilder: (context, index) {
            final gorev = gorevler[index];
            final formattedDate = formatDateTurkish(gorev.eklemeTarihi);

            return Card(
              margin: EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const Icon(
                  Icons.task,
                  color: Colors.orange,
                ),
                title: Text(
                  gorev.gorevAdi,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text('Eklenme Tarihi: $formattedDate'),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    silGorev(index); // Görev silme işlemi
                  },
                ),
                onTap: () {
                  // Görev tıklandığında 'Asama' ekranına git
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Asama(gorev: gorev, proje: widget.proje),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
