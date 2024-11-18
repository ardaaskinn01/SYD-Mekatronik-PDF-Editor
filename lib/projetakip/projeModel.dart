class ProjeModel {
  String? id;
  String projeIsmi;
  String musteriIsmi;
  String projeAciklama;
  DateTime? baslangicTarihi;
  bool isFinish;

  ProjeModel({
    this.id,
    required this.projeIsmi,
    required this.musteriIsmi,
    required this.projeAciklama,
    this.baslangicTarihi,
    this.isFinish = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id ?? '',
      'projeIsmi': projeIsmi,
      'musteriIsmi': musteriIsmi,
      'projeAciklama': projeAciklama,
      'baslangicTarihi': baslangicTarihi?.toIso8601String() ?? '',
      'isFinish': isFinish ? 1 : 0,
    };
  }

  factory ProjeModel.fromMap(Map<String, dynamic> map) {
    return ProjeModel(
      id: map['id'] ?? '',
      projeIsmi: map['projeIsmi'] ?? 'Bilinmeyen Proje',
      musteriIsmi: map['musteriIsmi'] ?? 'Bilinmeyen Müşteri',
      projeAciklama: map['projeAciklama'] ?? '',
      baslangicTarihi: map['baslangicTarihi'] != null && map['baslangicTarihi'].isNotEmpty
          ? DateTime.parse(map['baslangicTarihi'])
          : null,
      isFinish: map['isFinish'] == 1,
    );
  }
}
