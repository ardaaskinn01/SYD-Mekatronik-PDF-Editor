import 'dart:convert';
import 'dart:typed_data'; // Uint8List için gerekli import

class FormModel3 {
  String num;
  String? adSoyad;
  String? adSoyad2;
  String? adres;
  String? mail;
  String? telefon;
  String? yetkili;
  String? musteriYetkili;
  String? islemKisaTanim;
  String? islemDetay;
  String? malzeme;
  String? iscilik;
  String? toplam;
  bool montajChecked;
  bool bakimChecked;
  bool tamirChecked;
  bool revizyonChecked;
  bool projeSureciChecked;
  bool odemeNakitChecked;
  bool odemeFaturaChecked;
  bool odemeCekChecked;
  bool odemeKartChecked;
  Uint8List musteriImza; // Uint8List tipine güncellendi
  Uint8List yetkiliImza; // Uint8List tipine güncellendi

  FormModel3({
    this.num = '',
    this.adSoyad = '',
    this.adSoyad2 = '',
    this.adres = '',
    this.telefon = '',
    this.yetkili = '',
    this.musteriYetkili = '',
    this.islemKisaTanim = '',
    this.mail = '',
    this.malzeme = '',
    this.iscilik = '',
    this.toplam = '',
    this.islemDetay = '',
    Uint8List? musteriImza, // nullable parametre
    Uint8List? yetkiliImza,// Varsayılan olarak boş Uint8List
    this.montajChecked = false,
    this.bakimChecked = false,
    this.tamirChecked = false,
    this.revizyonChecked = false,
    this.projeSureciChecked = false,
    this.odemeNakitChecked = false,
    this.odemeFaturaChecked = false,
    this.odemeCekChecked = false,
    this.odemeKartChecked = false,
  })  : musteriImza = musteriImza ?? Uint8List(0), // Varsayılan değeri burada veriyoruz
        yetkiliImza = yetkiliImza ?? Uint8List(0); // Varsayılan değeri burada veriyoruz


  // Veritabanı için JSON formatına çevirme
  Map<String, dynamic> toMap() {
    return {
      'num': num,
      'adSoyad': adSoyad,
      'adSoyad2': adSoyad2,
      'adres': adres,
      'mail': mail,
      'telefon': telefon,
      'yetkili': yetkili,
      'musteriYetkili': musteriYetkili,
      'islemKisaTanim': islemKisaTanim,
      'islemDetay': islemDetay,
      'malzeme': malzeme,
      'iscilik': iscilik,
      'toplam': toplam,
      'montajChecked': montajChecked,
      'bakimChecked': bakimChecked,
      'tamirChecked': tamirChecked,
      'revizyonChecked': revizyonChecked,
      'projeSureciChecked': projeSureciChecked,
      'odemeNakitChecked': odemeNakitChecked,
      'odemeFaturaChecked': odemeFaturaChecked,
      'odemeCekChecked': odemeCekChecked,
      'odemeKartChecked': odemeKartChecked,
      'musteriImza': base64Encode(musteriImza),
      'yetkiliImza': base64Encode(yetkiliImza),
    };
  }
}