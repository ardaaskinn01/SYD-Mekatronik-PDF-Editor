import 'package:flutter/material.dart';
import 'package:pdf_editor/databaseHelper.dart';
import 'package:pdf_editor/main.dart';
import 'package:pdf_editor/projetakip/projeModel.dart';
import 'projeNakit.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
    return FutureBuilder<List<Map<String, dynamic>>>( // Fetch payments from DB
      future: _fetchOdemeler(),
      builder: (context, snapshot) {

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('Henüz ödeme bulunmuyor.'));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        var payments = snapshot.data!;
        Map<String, List<Map<String, dynamic>>> groupedPayments = {};

        // Group payments by year and month
        for (var payment in payments) {
          String yearMonth = payment['eklemeTarihi'].substring(0, 7);
          if (groupedPayments[yearMonth] == null) {
            groupedPayments[yearMonth] = [];
          }
          groupedPayments[yearMonth]!.add(payment);
        }

        // ListView to display grouped payments
        return ListView.builder(
          itemCount: groupedPayments.keys.length,
          itemBuilder: (context, index) {
            String key = groupedPayments.keys.elementAt(index);
            List<Map<String, dynamic>> paymentsForMonth = groupedPayments[key]!;

            return FutureBuilder<double>(
              // Call the async method for total amount calculation
              future: _calculateTotalAmount(paymentsForMonth),
              builder: (context, amountSnapshot) {
                if (amountSnapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  );
                }

                if (!amountSnapshot.hasData) {
                  return Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text("Hata oluştu."),
                      subtitle: Text("Ödeme verisi alınamadı."),
                    ),
                  );
                }

                double totalAmount = amountSnapshot.data!;
                String formattedDate = _formatDate(key);

                return Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(
                      "$formattedDate",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text("Toplam Ödeme: ${totalAmount.toStringAsFixed(2)} ₺"),
                    trailing: Icon(
                      Icons.attach_money,
                      color: Colors.orange,
                      size: 30,
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

// Async method to calculate total amount for a list of payments
  Future<double> _calculateTotalAmount(List<Map<String, dynamic>> paymentsForMonth) async {
    double totalAmount = 0.0;
    for (var payment in paymentsForMonth) {
      try {
        double amount = double.tryParse(payment['miktar'] ?? '') ?? 0.0;
        String currency = payment['birim'];
        double amountInTRY = await CurrencyConverter.convertToTRY(amount, currency);
        totalAmount += amountInTRY;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${e.toString()}")),
        );
      }
    }
    return totalAmount;
  }


  // Ödemeleri veritabanından çekme
  Future<List<Map<String, dynamic>>> _fetchOdemeler() async {
    final db = await _dbHelper.database;
    return await db.query('para5');
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
            title: Text('Bakiye Kontrol'),
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
