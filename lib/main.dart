import 'package:flutter/material.dart';
import 'mainPage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  navigatorKey: navigatorKey;
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

class GlobalBackground extends StatelessWidget {
  final Widget child;

  const GlobalBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/logo2.jpeg'),
          fit: BoxFit.scaleDown, // Arka planın ekranı tamamen kaplaması için
          colorFilter: ColorFilter.mode(
            Colors.grey.withOpacity(0.2),
            BlendMode.darken,// Karıştırma modu (daha koyu yapmak için)
          ),
        ),
      ),
      child: SafeArea(
        child: child, // Ekranın içerik kısmı
      ),
    );
  }
}