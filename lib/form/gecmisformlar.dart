import 'package:flutter/material.dart';
import '../databaseHelper.dart';
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
      appBar: AppBar(
        title: Text('Geçmiş Formlar'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
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
                  return Center(child: Text('Hiç form bulunamadı.'));
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