class FormModel2 {
  final String adSoyad;
  final String mail;
  final String telefon;
  final String adres;

  FormModel2({
    required this.adSoyad,
    required this.mail,
    required this.telefon,
    required this.adres,
  });

  // JSON'a dönüştürme işlemleri için
  Map<String, dynamic> toJson() => {
    'adSoyad': adSoyad,
    'mail': mail,
    'telefon': telefon,
    'adres': adres,
  };

  // JSON'dan FormModel oluşturma
  factory FormModel2.fromJson(Map<String, dynamic> json) {
    return FormModel2(
      adSoyad: json['adSoyad'],
      mail: json['mail'],
      telefon: json['telefon'],
      adres: json['adres'],
    );
  }
}
