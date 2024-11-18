class ProjeGoreviModel {
  String? id;
  final String projeId;
  String gorevAdi;
  final DateTime eklemeTarihi;
  ProjeGoreviModel({this.id, required this.projeId, required this.gorevAdi, required this.eklemeTarihi});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projeId': projeId,
      'gorevAdi': gorevAdi,
      'eklemeTarihi': eklemeTarihi.toIso8601String(),
    };
  }

  factory ProjeGoreviModel.fromMap(Map<String, dynamic> map) {
    return ProjeGoreviModel(
      id: map['id'],
      projeId: map['projeId'],
      gorevAdi: map['gorevAdi'],
      eklemeTarihi: DateTime.parse(map['eklemeTarihi']),
    );
  }

  int get remainingDays {
    final today = DateTime.now();
    final difference = eklemeTarihi.difference(today).inDays;
    return difference >= 0 ? difference : 0; // 0 gün kaldı veya geçmiş ise sıfır döndür.
  }
}
