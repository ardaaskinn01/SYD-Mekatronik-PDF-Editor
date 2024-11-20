import 'package:flutter/material.dart';
import 'package:pdf_editor/projetakip/projeModel.dart';
import 'ProjeGoreviModel.dart';
import '../databaseHelper.dart';
import 'asama.dart';
import 'package:intl/intl.dart';

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

  // Proje görevlerini veritabanından yükleme
  void _loadProjeGorevleri() async {
    final gorevler = await DatabaseHelper().getProjeGorevleri(proje.id);
    setState(() {
      projeGorevleri = gorevler;
    });
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

    // Veritabanından silme
    await DatabaseHelper().deleteGorev(gorevId);

    // Görevi listeden ve veritabanından sil
    setState((){
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
                      builder: (context) => Asama(gorev: gorev),
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
