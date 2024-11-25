import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_editor/projetakip/pinSetupScreen.dart';
import 'form/formModel3.dart';
import 'package:pdf_editor/form/formolustur.dart';
import 'form/gecmisformlar.dart';
import 'package:pdf_editor/projetakip/projelerim.dart';
import 'package:pdf_editor/projetakip/projeEkle.dart';

import 'main.dart';

class Anasayfa extends StatefulWidget {
  const Anasayfa({super.key});

  @override
  _AnasayfaState createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GlobalBackground(
      child: Scaffold(
        backgroundColor: Colors.white10.withOpacity(0.22),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Column(
              children: [
                // Üst grup: Form oluştur, Geçmiş formlar ve Yedekle
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // Butonları üst kısma yerleştiriyoruz
                    children: [
                      SizedBox(height: screenHeight * 0.07),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FormOlustur(form: FormModel3(), id: 0),
                            ),
                          );
                        },
                        icon: Icon(Icons.add_circle, color: Colors.black),
                        label: const Text(
                          'Teknik Servis Formu Oluştur',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.12,
                            vertical: screenHeight * 0.02,
                          ),
                          backgroundColor: Colors.greenAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          elevation: 10,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => GecmisFormlar()),
                          );
                        },
                        icon: Icon(Icons.history, color: Colors.white),
                        label: const Text(
                          'Düzenlenmiş Teknik Servis Formları',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.12,
                            vertical: screenHeight * 0.02,
                          ),
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          elevation: 10,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.37),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProjeEkle()),
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
                      SizedBox(height: screenHeight * 0.02),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Projelerim(initialTabIndex: 0),
                            ),
                          );
                        },
                        icon: Icon(Icons.folder_open, color: Colors.white),
                        label: const Text(
                          'Devam Eden Projeler',
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
                      SizedBox(height: screenHeight * 0.02),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Projelerim(initialTabIndex: 1),
                            ),
                          );
                        },
                        icon: Icon(Icons.check_circle, color: Colors.white),
                        label: const Text(
                          'Tamamlanan Projeler',
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
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          elevation: 10,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PinSetupScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.attach_money, color: Colors.white),
                        label: const Text(
                          'Bakiye Kontrol Sayfası',
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
                          backgroundColor: Colors.orange,
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
      ),
    );
  }
}
