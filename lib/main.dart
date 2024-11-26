import 'package:flutter/material.dart';
import 'mainPage.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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