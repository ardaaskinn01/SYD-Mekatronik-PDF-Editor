import 'package:flutter/material.dart';
import 'package:pdf_editor/databaseHelper.dart';
import 'package:pdf_editor/projetakip/projeModel.dart';

class ProjeEkle extends StatefulWidget {
  @override
  _ProjeEkleState createState() => _ProjeEkleState();
}

class _ProjeEkleState extends State<ProjeEkle> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _projeIsmiController = TextEditingController();
  final TextEditingController _musteriIsmiController = TextEditingController();
  final TextEditingController _projeAciklamaController =
  TextEditingController();
  DateTime? _baslangicTarihi;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
          _baslangicTarihi = selectedDate;
      });
    }
  }

  Future<void> _saveProje() async {
    if (_formKey.currentState!.validate()) {
      if (_baslangicTarihi == null) {
        _showErrorDialog('Lütfen başlangıç tarihini seçin.');
        return;
      }

      try {
        final yeniProje = ProjeModel(
          id: DateTime.now().toString(),
          projeIsmi: _projeIsmiController.text,
          musteriIsmi: _musteriIsmiController.text,
          projeAciklama: _projeAciklamaController.text,
          baslangicTarihi: _baslangicTarihi,
          isFinish: false,
        );

        await _dbHelper.insertProje(yeniProje);
        Navigator.pop(context);
      } catch (e) {
        _showErrorDialog('Proje kaydedilirken bir hata oluştu: $e');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  String formatDateTurkish(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proje Ekle'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Proje Bilgileri",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildTextField(
                controller: _projeIsmiController,
                label: 'Proje İsmi',
                hintText: 'Proje İsmini Girin',
              ),
              _buildTextField(
                controller: _musteriIsmiController,
                label: 'Proje Sahibi Firma',
                hintText: 'Proje Sahibi Firmayı Girin',
              ),
              _buildTextField(
                controller: _projeAciklamaController,
                label: 'Proje Açıklaması',
                hintText: 'Proje Açıklamasını Girin',
                maxLines: 3,
              ),
              const SizedBox(height: 15),
              const Text(
                "Proje Tarihi",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildDatePicker(
                label: _baslangicTarihi == null
                    ? 'Başlangıç Tarihi Seç'
                    : 'Başlangıç Tarihi: ${formatDateTurkish(_baslangicTarihi!)}',
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 150),
              Center(
                child: ElevatedButton(
                  onPressed: _saveProje,
                  child: const Text('Kaydet', style: TextStyle(fontSize: 16, color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: Colors.teal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Lütfen $label girin';
          }
          return null;
        },
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildDatePicker(
      {required String label, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ListTile(
        title: Text(label),
        trailing: const Icon(Icons.calendar_today, color: Colors.teal),
        onTap: onTap,
      ),
    );
  }
}