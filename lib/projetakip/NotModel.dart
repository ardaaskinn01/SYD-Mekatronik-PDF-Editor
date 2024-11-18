class NotModel {
  String id;
  String asamaId;
  String note;
  String eklemeTarihi;

  NotModel({
    required this.id,
    required this.asamaId,
    required this.note,
    required this.eklemeTarihi,
  });

  factory NotModel.fromMap(Map<String, dynamic> map) {
    return NotModel(
      id: map['id'],
      asamaId: map['asamaId'],
      note: map['note'],
      eklemeTarihi: map['eklemeTarihi'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'asamaId': asamaId,
      'note': note,
      'eklemeTarihi': eklemeTarihi,
    };
  }
}
