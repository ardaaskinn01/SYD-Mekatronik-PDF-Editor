class FormModel {
  final String num; // ID'yi String olarak tutalım
  final String pdfFilePath;
  final String musteriAdSoyad;
  final String tarih;

  FormModel({required this.num, required this.pdfFilePath, required this.musteriAdSoyad, required this.tarih});

  // FormModel nesnesini veritabanına kaydetmek için map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'num': num,
      'pdfFilePath': pdfFilePath,
      'musteriAdSoyad': musteriAdSoyad,
      'tarih': tarih,
    };
  }
}