import 'package:flutter/material.dart';
import 'package:pdf_editor/databaseHelper.dart';
import 'package:pdf_editor/main.dart';
import 'package:pdf_editor/projetakip/projeModel.dart';
import 'projeNakit.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyConverter {
  static Future<double> convertToTRY(double amount, String currency) async {
    String apiKey = 'a03fbae025e061d1beda3e8d';
    String url = 'https://v6.exchangerate-api.com/v6/$apiKey/latest/$currency';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        if (!data.containsKey('conversion_rates') || !data['conversion_rates'].containsKey('TRY')) {
          throw Exception('Döviz kuru verisi eksik veya hatalı');
        }
        if (data.containsKey('conversion_rates') && data['conversion_rates'].containsKey('TRY')) {
          double rate = (data['conversion_rates']['TRY'] as num).toDouble();
          return amount * rate;
        } else {
          throw Exception('Döviz kuru verisi eksik veya hatalı');
        }
      } else {
        throw Exception('Döviz kuru API isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(content: Text('Döviz kuru API hatası: $e')),
        );
      }
      throw Exception('API isteği hatası: $e');
    }
  }
}

class BakiyeKontrolSayfasi extends StatefulWidget {
  @override
  _BakiyeKontrolSayfasiState createState() => _BakiyeKontrolSayfasiState();
}

class _BakiyeKontrolSayfasiState extends State<BakiyeKontrolSayfasi> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<ProjeModel> _projeler = [];
  int _selectedIndex = 0; // 0: Bakiye Kontrol, 1: Aylık Kazanç

  static const List<String> _turkceAylar = [
    "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
  ];

  @override
  void initState() {
    super.initState();
    _fetchProjeler();
  }

  Future<void> _fetchProjeler() async {
    final projeler = await _dbHelper.getProjeler();
    setState(() {
      _projeler = projeler;
    });
  }

  // "Aylık Kazanç" ekranı
  Widget _buildAylikKazancScreen() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchOdemeler(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Henüz ödeme bulunmuyor.'));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        var payments = snapshot.data ?? [];
        Map<String, Map<String, List<Map<String, dynamic>>>> groupedPayments = {};

        // Yıl-Ay bazında ve isForm durumuna göre gruplama
        for (var payment in payments) {
          String yearMonth = payment['eklemeTarihi'].substring(0, 7);
          int isForm = payment['isForm'] ?? 0;

          if (!groupedPayments.containsKey(yearMonth)) {
            groupedPayments[yearMonth] = {'form': [], 'form2': [], 'proje': []};
          }

          if (isForm == 1) {
            groupedPayments[yearMonth]!['form']!.add(payment);
          }
          else if (isForm == 2) {
            groupedPayments[yearMonth]!['form2']!.add(payment);
          } else {
            groupedPayments[yearMonth]!['proje']!.add(payment);
          }
        }

        return ListView.builder(
          itemCount: groupedPayments.keys.length,
          itemBuilder: (context, index) {
            String key = groupedPayments.keys.elementAt(index);
            var paymentsForMonth = groupedPayments[key]!;

            return FutureBuilder<Map<String, Map<String, double>>>(
              future: _calculateGroupedAmountsDetailed(paymentsForMonth),
              builder: (context, amountSnapshot) {
                if (amountSnapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    elevation: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(title: Text("Yükleniyor...")),
                  );
                }

                if (!amountSnapshot.hasData) {
                  return Card(
                    elevation: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(title: Text("Hata oluştu.")),
                  );
                }

                var amounts = amountSnapshot.data!;
                String formattedDate = _formatDate(key);

                return Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text("Form Ücretleri (TRY): ${amounts['form']!['TRY']?.toStringAsFixed(2)} ₺"),
                        SizedBox(height: 8),
                        Text("Proje Ücretleri (USD): ${amounts['proje']!['USD']?.toStringAsFixed(2)} USD"),
                        Text("Proje Ücretleri (EUR): ${amounts['proje']!['EUR']?.toStringAsFixed(2)} EUR"),
                        Text("Proje Ücretleri (TRY): ${amounts['proje']!['TRY']?.toStringAsFixed(2)} ₺"),
                        SizedBox(height: 8),
                        Text("Proje Malzeme Ücretleri (TRY): ${amounts['form2']!['TRY']?.toStringAsFixed(2)} ₺"),
                        SizedBox(height: 8),
                        Divider(thickness: 1),
                        FutureBuilder<double>(
                          future: _calculateTotalInTRY(amounts),
                          builder: (context, totalSnapshot) {
                            if (totalSnapshot.connectionState == ConnectionState.waiting) {
                              return Text("Toplam Ücret: Yükleniyor...");
                            }
                            return Text(
                              "Toplam Ücret: ${totalSnapshot.data?.toStringAsFixed(2)} ₺",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

// Ödeme miktarlarını detaylı (TRY, USD, EUR) hesaplama
  Future<Map<String, Map<String, double>>> _calculateGroupedAmountsDetailed(
      Map<String, List<Map<String, dynamic>>> groupedPayments) async {
    Map<String, double> formAmounts = {'USD': 0.0, 'EUR': 0.0, 'TRY': 0.0};
    Map<String, double> projeAmounts = {'USD': 0.0, 'EUR': 0.0, 'TRY': 0.0};
    Map<String, double> form2Amounts = {'USD': 0.0, 'EUR': 0.0, 'TRY': 0.0};

    for (var payment in groupedPayments['form']!) {
      double amount = double.tryParse(payment['miktar'] ?? '') ?? 0.0;
      String currency = payment['birim'] ?? 'TRY';
      formAmounts[currency] = (formAmounts[currency] ?? 0) + amount;
    }

    for (var payment in groupedPayments['form2']!) {
      double amount = double.tryParse(payment['miktar'] ?? '') ?? 0.0;
      String currency = payment['birim'] ?? 'TRY';
      form2Amounts[currency] = (form2Amounts[currency] ?? 0) + amount;
    }

    for (var payment in groupedPayments['proje']!) {
      double amount = double.tryParse(payment['miktar'] ?? '') ?? 0.0;
      String currency = payment['birim'] ?? 'TRY';
      projeAmounts[currency] = (projeAmounts[currency] ?? 0) + amount;
    }

    return {'form': formAmounts, "form2": form2Amounts, 'proje': projeAmounts};
  }

// Detaylı verileri toplam TRY'ye çevirme
  Future<double> _calculateTotalInTRY(Map<String, Map<String, double>> amounts) async {
    double total = 0.0;

    for (var category in amounts.keys) {
      for (var currency in amounts[category]!.keys) {
        double amount = amounts[category]![currency]!;
        total += await CurrencyConverter.convertToTRY(amount, currency);
      }
    }

    return total;
  }


// Tek bir ödemeyi TRY'ye çevirme

  Future<bool> getFormStatus(String kaynakId) async {
    final db = await _dbHelper.database;

    // 'forms_2' tablosunda kaynakId'ye göre sorgu
    List<Map<String, dynamic>> results = await db.query(
      'forms_2',
      where: 'num = ?',
      whereArgs: [kaynakId], // Kaynak ID'yi sorguya dahil et
    );

    if (results.isEmpty) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> getFormStatus2(String kaynakId) async {
    final db = await _dbHelper.database;

    // 'forms_2' tablosunda kaynakId'ye göre sorgu
    List<Map<String, dynamic>> results = await db.query(
      'projeler4',
      where: 'id = ?',
      whereArgs: [kaynakId], // Kaynak ID'yi sorguya dahil et
    );

    if (results.isEmpty) {
      return true;
    } else {
      return false;
    }
  }


  Future<List<Map<String, dynamic>>> _fetchOdemeler() async {
    final db = await _dbHelper.database;
    final odemeler2 = await db.query('para9', where: 'isForm = ?', whereArgs: [0]);
    final odemeler = await db.query('para9', where: 'isForm = ?', whereArgs: [1]);
    for (var odeme in odemeler) {
      // 'kaynakId' değerini doğru türde almak için 'toString()' kullanıyoruz
      String kaynakId = odeme['kaynakId'].toString();

      // getFormStatus fonksiyonunu çağırırken doğru türü sağlıyoruz
      bool odemeId = await getFormStatus(kaynakId);

      if (odemeId == true) {
        await _dbHelper.silOdeme2(kaynakId);
      }
    }
    for (var odeme in odemeler2) {
      // 'kaynakId' değerini doğru türde almak için 'toString()' kullanıyoruz
      String kaynakId = odeme['kaynakId'].toString();

      // getFormStatus fonksiyonunu çağırırken doğru türü sağlıyoruz
      bool odemeId = await getFormStatus2(kaynakId);

      if (odemeId == true) {
        await _dbHelper.silOdeme2(kaynakId);
      }
    }
    final payments = await db.query('para9');
    return payments;
  }


  // Tarih formatını Türkçe yapmak için
  String _formatDate(String yearMonth) {
    DateTime date = DateTime.parse("$yearMonth-01");
    int monthIndex = date.month - 1;  // Ayları sıfırdan başlatmak için
    String formattedDate = "${_turkceAylar[monthIndex]} ${date.year}";
    return formattedDate; // Türkçe ay ismi ile yıl
  }

  // Drawer menu
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          ListTile(
            title: Text('Proje Ödemeleri'),
            onTap: () {
              setState(() {
                _selectedIndex = 0;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Aylık Kazanç'),
            onTap: () {
              setState(() {
                _selectedIndex = 1;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nakit Akışı"),
      ),
      drawer: _buildDrawer(), // Drawer ekliyoruz
      body: _selectedIndex == 0 ? _buildBakiyeKontrolScreen() : _buildAylikKazancScreen(),
    );
  }

  // Bakiye Kontrol ekranı
  Widget _buildBakiyeKontrolScreen() {
    return _projeler.isEmpty
        ? Center(
      child: Text(
        'Henüz kayıtlı proje yok.',
        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
      ),
    )
        : ListView.builder(
      itemCount: _projeler.length,
      itemBuilder: (context, index) {
        final proje = _projeler[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            title: Text(
              proje.projeIsmi,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Müşteri: ${proje.musteriIsmi}"),
                Text("Durum: ${proje.isFinish ? 'Tamamlandı' : 'Devam Ediyor'}"),
              ],
            ),
            trailing: Icon(
              Icons.attach_money,
              color: Colors.orange,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjeNakit(projeId: proje.id!),
                ),
              );
            },
          ),
        );
      },
    );
  }
}


