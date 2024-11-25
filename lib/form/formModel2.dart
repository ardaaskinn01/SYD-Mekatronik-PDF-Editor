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

  Map<String, dynamic> toMap() {
    return {
      'adSoyad': adSoyad,
      'email': mail,
      'telefon': telefon,
      'adres': adres,
    };
  }

  static FormModel2 fromMap(Map<String, dynamic> map) {
    return FormModel2(
      adSoyad: map['adSoyad'],
      mail: map['email'],
      telefon: map['telefon'],
      adres: map['adres'],
    );
  }
}
