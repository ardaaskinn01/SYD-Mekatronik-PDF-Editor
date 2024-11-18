import 'package:flutter/material.dart';
import 'mainPage.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Anasayfa(),
      builder: (context, widget) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0), // Yakınlaştırmayı kapatma
          child: widget!,
        );
      },
    );
  }
}

/*
veritabanı revize edilecek.
projeprofil ekranına aşama sistemi getirilip görsel-belge-not-malzemeler oraya aktarılacak.
aşama sayfası oluşturulacak
aşamada görsel belge notlar malzemeler önizlenip onlara özel ekranlar altta dörtlü olarak oluşturulacak
foto eklerken kamera seçeneği çıkacak
projeyi tamamla butonu eklenip butona basıldığında proje tamamlanan projelere aktarılacak
 */