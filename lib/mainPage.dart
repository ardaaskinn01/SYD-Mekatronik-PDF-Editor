import 'package:flutter/material.dart';
import 'form/formModel3.dart';
import 'package:pdf_editor/form/formolustur.dart';
import 'form/gecmisformlar.dart';
import 'package:pdf_editor/projetakip/projelerim.dart';
import 'package:pdf_editor/projetakip/projeEkle.dart';
import 'package:pdf_editor/projetakip/pinSetupScreen.dart';

class Anasayfa extends StatefulWidget {
  const Anasayfa({super.key});

  @override
  _AnasayfaState createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.8;
    final buttonHeight = 60.0;
    final buttonSpacing = 20.0;

    return Scaffold(
      backgroundColor: Colors.white10.withOpacity(0.22),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 50), // Logonun üst boşluğu
            // Logo
            Container(
              width: double.infinity, // Yatayda tam genişlik
              child: Image.asset(
                'assets/images/logo1.jpeg', // Logonuzun dosya yolu
                fit: BoxFit.cover, // Resmin genişliği düzgün şekilde kaplamasını sağlar
              ),
            ),
            SizedBox(height: 70), // Logonun alt boşluğu
// Logo ile butonlar arasındaki mesafe

            // Butonlar
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  buildButton(
                    label: "Teknik Servis Formu Oluştur",
                    color: Colors.lightGreen,
                    icon: Icons.add_circle,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FormOlustur(form: FormModel3(), id: 0),
                        ),
                      );
                    },
                    width: buttonWidth,
                    height: buttonHeight,
                  ),
                  SizedBox(height: buttonSpacing),
                  buildButton(
                    label: "Düzenlenmiş Teknik Servis Formları",
                    color: Colors.blueAccent,
                    icon: Icons.history,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GecmisFormlar()),
                      );
                    },
                    width: buttonWidth,
                    height: buttonHeight,
                  ),
                  SizedBox(height: buttonSpacing),
                  buildButton(
                    label: "Proje Ekle",
                    color: Colors.pinkAccent,
                    icon: Icons.add_box,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProjeEkle()),
                      );
                    },
                    width: buttonWidth,
                    height: buttonHeight,
                  ),
                  SizedBox(height: buttonSpacing),
                  buildButton(
                    label: "Devam Eden Projeler",
                    color: Colors.blueAccent,
                    icon: Icons.folder_open,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Projelerim(initialTabIndex: 0),
                        ),
                      );
                    },
                    width: buttonWidth,
                    height: buttonHeight,
                  ),
                  SizedBox(height: buttonSpacing),
                  buildButton(
                    label: "Tamamlanan Projeler",
                    color: Colors.green,
                    icon: Icons.check_circle,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Projelerim(initialTabIndex: 1),
                        ),
                      );
                    },
                    width: buttonWidth,
                    height: buttonHeight,
                  ),
                  SizedBox(height: buttonSpacing),
                  buildButton(
                    label: "Bakiye Kontrol Sayfası",
                    color: Colors.orange,
                    icon: Icons.attach_money,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PinSetupScreen(),
                        ),
                      );
                    },
                    width: buttonWidth,
                    height: buttonHeight,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
    required double width,
    required double height,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          elevation: 10,
        ),
      ),
    );
  }
}
