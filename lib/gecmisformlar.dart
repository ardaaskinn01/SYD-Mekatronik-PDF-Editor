import 'package:flutter/material.dart';
import 'databaseHelper.dart';
import 'formModel.dart';
import 'musteriFormlariScreen.dart'; // Müşteri formlarının listelendiği yeni ekran

class GecmisFormlar extends StatefulWidget {
  @override
  _GecmisFormlarState createState() => _GecmisFormlarState();
}

class _GecmisFormlarState extends State<GecmisFormlar> {
  late Future<List<FormModel>> futureForms;

  @override
  void initState() {
    super.initState();
    futureForms = DatabaseHelper().getForms(); // Veritabanından formları çek
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Geçmiş Formlar'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<List<FormModel>>(
        future: futureForms,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Hiç form bulunamadı.'));
          } else {
            // Formları müşteriye göre grupla
            final groupedForms = _groupFormsByCustomer(snapshot.data!);

            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16), // Kartlar arasında boşluk
              itemCount: groupedForms.keys.length,
              itemBuilder: (context, index) {
                final musteriAdSoyad = groupedForms.keys.elementAt(index);
                final forms = groupedForms[musteriAdSoyad]!;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0), // Kartların arasındaki boşluk
                  child: Card(
                    elevation: 5, // Kartın gölgesi
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Kart köşelerini yuvarla
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10), // İçerik padding
                      leading: Icon(
                        Icons.folder,
                        color: Colors.teal, // Klasör ikonu
                        size: 36,
                      ),
                      title: Text(
                        musteriAdSoyad,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ), // Müşteri adı "klasör" olarak gösterilir
                      subtitle: Text(
                        '${forms.length} form',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ), // Müşterinin kaç formu olduğunu göster
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.teal,
                        size: 20,
                      ), // Sağda yön ok ikonu
                      onTap: () {
                        // Müşteri ismine tıklandığında o müşterinin formlarını listeleyen sayfaya git
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
    );
  }

  // Formları müşteri adına göre grupla
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
