import 'package:flutter/material.dart';
import 'package:pdf_editor/databaseHelper.dart';
import 'package:pdf_editor/projetakip/projeModel.dart';
import 'projeProfil.dart';
import 'package:intl/intl.dart';

class Projelerim extends StatefulWidget {
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
    _tabController = TabController(length: 3, vsync: this);
    _fetchProjeler();
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
  }

  Widget _buildProjeGrid(List<ProjeModel> projeler) {
    return projeler.isEmpty
        ? Center(
            child: Text(
              'Henüz bu kategoride projeniz yok',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          )
        : GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2, // Kartların daha küçük görünmesi için artırıldı
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
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
            elevation: 12,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: Colors.teal[200],
            child: Padding(
              padding: const EdgeInsets.all(5.0), // Daha kompakt bir görünüm için azaltıldı
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Yatayda ortalama
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Yatayda ortalama
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
                            fontSize: 14, // Daha küçük yazı boyutu
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
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text(
                              'Yükleniyor...', // Veriyi beklerken gösterilecek yazı
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            );
                          } else if (snapshot.hasError) {
                            return const Text(
                              'Hata!', // Hata durumunda gösterilecek yazı
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            );
                          } else {
                            return Text(
                              snapshot.data ?? '', // Veriyi başarıyla aldıysa göster
                              style: const TextStyle(
                                fontSize: 12,
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
                      fontSize: 12, // Daha küçük yazı boyutu
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center, // Metni yatayda ortalama
                  ),
                  const SizedBox(height: 35),
                  Text(
                    proje.isFinish == false ? "Devam Ediyor" : "Tamamlandı", // Durum yazısı
                    style: TextStyle(
                      fontSize: 14,
                      color: proje.isFinish == false ? Colors.orange : Colors.green, // Renk duruma göre
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center, // Metni yatayda ortalama
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
                  leading:
                      const Icon(Icons.delete, color: Colors.red, size: 32),
                  title: const Text('Projeyi Sil'),
                  onTap: () {
                    _silProje(proje.id!);
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.check_circle,
                      color: Colors.green, size: 32),
                  title: const Text('Projeyi Bitir'),
                  onTap: () {
                    _bitirProje(proje);
                    Navigator.of(context).pop();
                  },
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.cancel, color: Colors.grey, size: 32),
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
            const Tab(text: 'Nakit Akışı'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProjeGrid(_devamEdenProjeler),
          _buildProjeGrid(_tamamlananProjeler),
          _buildProjeGrid(_tumProjeler),
        ],
      ),
    );
  }
}

Future<String> formattedText(ProjeModel proje) async {
  final formattedDate = DateFormat('dd.MM.yyyy').format(proje.baslangicTarihi!);
  return formattedDate;
}
