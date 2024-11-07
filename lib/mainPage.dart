import 'package:flutter/material.dart';
import 'formModel3.dart';
import 'formolustur.dart';
import 'gecmisformlar.dart';
import 'package:permission_handler/permission_handler.dart';

class Anasayfa extends StatefulWidget {
  const Anasayfa({super.key});

  @override
  _AnasayfaState createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) {
      // İzin verildiyse, burada dosya işlemlerini veya diğer asenkron işlemleri başlatabilirsiniz.
    });
  }

  Future<void> requestPermissions() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      print("İzin verildi");
    } else if (status.isDenied) {
      print("İzin reddedildi");
    } else if (status.isPermanentlyDenied) {
      print("İzin kalıcı olarak reddedildi. Ayarlar ekranına yönlendirebilirsiniz.");
      openAppSettings(); // Ayarlar ekranını açabiliriz
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/wallpaper.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.lightGreen.withOpacity(0.3), // Opaklığı artırdık
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  // FormOlustur sayfasına geçiş
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FormOlustur(form: FormModel3(), id: 0),
                    ),
                  );
                },
                icon: Icon(Icons.add_circle, color: Colors.black), // İkon eklendi
                label: const Text(
                  'Form Oluştur',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.2,
                    vertical: screenHeight * 0.02,
                  ),
                  backgroundColor: Colors.greenAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 10, // Gölgeler eklendi
                ),
              ),
              SizedBox(height: screenHeight * 0.1),
              ElevatedButton.icon(
                onPressed: () {
                  // GecmisFormlar sayfasına geçiş
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GecmisFormlar()),
                  );
                },
                icon: Icon(Icons.history, color: Colors.white), // İkon eklendi
                label: const Text(
                  'Geçmiş Formlar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.2,
                    vertical: screenHeight * 0.02,
                  ),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 10, // Gölgeler eklendi
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
